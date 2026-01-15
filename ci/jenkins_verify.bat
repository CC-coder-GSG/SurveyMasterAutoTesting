@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

rem ============================================================
rem  Jenkins verify (Windows): Appium + Robot Framework
rem  v17 (2026-01-15) - Appium START FIX (no missing logs)
rem
rem  Why v16 failed:
rem    - Jenkins log shows Appium waited 240s then timed out, and
rem      appium.log / appium.err.log were NOT created at all.
rem      That usually means the Appium process never launched.
rem
rem  What v17 changes:
rem    1) Start Appium via `start /b cmd /c` with explicit stdout/stderr
rem       redirection (this reliably creates log files).
rem    2) Create empty log files BEFORE starting, so "not found" can't happen.
rem    3) If not ready, dump last lines of logs for diagnosis.
rem    4) Wait signal: log listener line OR netstat LISTENING.
rem    5) Kill Appium: kill process tree (/T) by PID + kill by port fallback.
rem ============================================================

set "CI_DIR=%~dp0"
cd /d "%CI_DIR%\.."
set "AUTOTEST_DIR=%CD%"

if not defined WORKSPACE set "WORKSPACE=%AUTOTEST_DIR%"

rem ---- Inputs ----
if not defined DEVICE_ID (
  echo [ERROR] DEVICE_ID is not set.
  exit /b 2
)

if not defined ANDROID_HOME set "ANDROID_HOME=D:\android-sdk"
set "ADB_CMD=%ANDROID_HOME%\platform-tools\adb.exe"

if not defined NPM_BIN set "NPM_BIN=%APPDATA%\npm"
if not defined APPIUM_CMD set "APPIUM_CMD=%NPM_BIN%\appium.cmd"
if not defined APPIUM_PORT set "APPIUM_PORT=4723"

rem PATH: npm bin + node
set "PATH=%NPM_BIN%;%PATH%"
if exist "C:\Program Files\nodejs\node.exe" set "PATH=C:\Program Files\nodejs;%PATH%"

rem Logs/dirs
set "RESULTS_DST=%WORKSPACE%\results"
set "RF_OUTPUT_DIR=%AUTOTEST_DIR%\results"
set "ROBOT_CONSOLE_LOG=%RESULTS_DST%\robot_console.log"

set "APPIUM_LOG=%WORKSPACE%\appium.log"
set "APPIUM_ERR_LOG=%WORKSPACE%\appium.err.log"
set "APPIUM_PID_FILE=%WORKSPACE%\appium.pid"
set "NETSTAT_TMP=%WORKSPACE%\_netstat_check.txt"

set "PYTHONUTF8=1"
set "PYTHONIOENCODING=utf-8"

rem ---- Prepare dirs ----
if exist "%RF_OUTPUT_DIR%" rmdir /s /q "%RF_OUTPUT_DIR%"
mkdir "%RF_OUTPUT_DIR%" >nul 2>&1

if not exist "%RESULTS_DST%" mkdir "%RESULTS_DST%" >nul 2>&1
if exist "%ROBOT_CONSOLE_LOG%" del /f /q "%ROBOT_CONSOLE_LOG%" >nul 2>&1

rem ---- Env checks ----
echo [INFO] ===== ENV CHECK =====
where node >nul 2>&1 || (echo [ERROR] node not found in PATH & exit /b 2)
node -v

if not exist "%ADB_CMD%" ( echo [ERROR] ADB not found: "%ADB_CMD%" & exit /b 2 )
if not exist "%APPIUM_CMD%" ( echo [ERROR] appium.cmd not found: "%APPIUM_CMD%" & exit /b 2 )

rem IMPORTANT: appium.cmd is *.cmd, MUST CALL
call "%APPIUM_CMD%" -v
if errorlevel 1 (
  echo [ERROR] Appium CLI failed ^(check node/npm/appium installation^).
  exit /b 2
)
echo [INFO] ENV OK.

rem ---- Device online ----
echo [INFO] ===== CHECK DEVICE =====
"%ADB_CMD%" start-server >nul 2>&1

set "DEV_OK=0"
for /l %%i in (1,1,20) do (
  powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
    "$s=((& '%ADB_CMD%' -s '%DEVICE_ID%' get-state 2^>$null) -join '').Trim(); if($s -eq 'device'){exit 0}else{exit 1}"
  if !errorlevel! EQU 0 (
    set "DEV_OK=1"
    goto :DEVICE_OK
  )
  ping -n 2 127.0.0.1 >nul
)
echo [ERROR] Device "%DEVICE_ID%" not ready.
"%ADB_CMD%" devices
exit /b 3

:DEVICE_OK
echo [OK] Device "%DEVICE_ID%" is online.

rem ---- Clean Appium ----
echo [INFO] ===== CLEAN PORT %APPIUM_PORT% =====
call :STOP_APPIUM >nul 2>&1

rem Kill by port (best effort, no pipe)
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "try{Get-NetTCPConnection -LocalPort %APPIUM_PORT% -State Listen -ErrorAction Stop ^| %%{Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue}}catch{}" >nul 2>&1

rem ---- Start Appium ----
echo [INFO] ===== START APPIUM =====

if exist "%APPIUM_PID_FILE%" del /f /q "%APPIUM_PID_FILE%" >nul 2>&1

rem CRITICAL: create log files first so we will never see "log not found"
type nul > "%APPIUM_LOG%"
type nul > "%APPIUM_ERR_LOG%"

set "APPIUM_ARGS=--address 127.0.0.1 --port %APPIUM_PORT% --log-level info --local-timezone"
echo [INFO] Launch: "%APPIUM_CMD%" %APPIUM_ARGS%

rem CRITICAL: start in background + explicit redirection
rem (avoid Start-Process redirection issues in some agents)
start "" /b "%APPIUM_CMD%" %APPIUM_ARGS% 1>>"%APPIUM_LOG%" 2>>"%APPIUM_ERR_LOG%"

rem ---- Wait Appium ready ----
echo [INFO] ===== WAIT APPIUM READY (up to 240s) =====
set "APPIUM_UP=0"
for /l %%i in (1,1,240) do (
  rem Signal A: log contains listener line
  findstr /I /C:"listener started on http://127.0.0.1:%APPIUM_PORT%" "%APPIUM_LOG%" >nul 2>&1
  if !errorlevel! EQU 0 (
    set "APPIUM_UP=1"
    goto :APPIUM_OK
  )
  findstr /I /C:"Appium REST http interface listener started" "%APPIUM_LOG%" >nul 2>&1
  if !errorlevel! EQU 0 (
    set "APPIUM_UP=1"
    goto :APPIUM_OK
  )

  rem Signal B: netstat shows LISTENING
  netstat -ano > "%NETSTAT_TMP%" 2>nul
  findstr /R /C:":%APPIUM_PORT% .*LISTENING" "%NETSTAT_TMP%" >nul 2>&1
  if !errorlevel! EQU 0 (
    set "APPIUM_UP=1"
    goto :APPIUM_OK
  )

  rem Fail-fast: if stderr already has content, show and stop early
  for %%F in ("%APPIUM_ERR_LOG%") do if %%~zF GTR 0 (
    echo [ERROR] Appium stderr is not empty. Failing fast.
    goto :SHOW_APPIUM_LOGS_FAIL
  )

  ping -n 2 127.0.0.1 >nul
)

echo [ERROR] Appium timeout: port %APPIUM_PORT% not ready.
goto :SHOW_APPIUM_LOGS_FAIL

:APPIUM_OK
echo [OK] Appium is ready on %APPIUM_PORT%.

rem Record REAL service PID by port (netstat parsing)
netstat -ano > "%NETSTAT_TMP%" 2>nul
for /f "tokens=5" %%p in ('findstr /R /C:":%APPIUM_PORT% .*LISTENING" "%NETSTAT_TMP%"') do (
  echo %%p>"%APPIUM_PID_FILE%"
  echo [INFO] Appium Service PID=%%p
  goto :PID_DONE
)
:PID_DONE

rem ---- Run Robot ----
echo [INFO] ===== RUN ROBOT =====
if not defined RF_TEST_PATH set "RF_TEST_PATH=tests"
if not defined RF_ARGS set "RF_ARGS=--suite CreateNewProject"

where python >nul 2>&1 || (echo [ERROR] python not found in PATH & goto :FAIL)
python -V

rem Check Robot availability; try install ONCE only if missing
python -c "import robot; print(robot.__version__)" >nul 2>&1
if errorlevel 1 (
  echo [WARN] Robot Framework not installed, trying to install (one-time)...
  python -m pip --version >nul 2>&1 || (echo [ERROR] pip not available & goto :FAIL)
  python -m pip install -U robotframework robotframework-appiumlibrary Appium-Python-Client
  if errorlevel 1 (
    echo [ERROR] pip install failed. Please install deps on agent manually.
    goto :FAIL
  )
)

echo [INFO] Robot console log: "%ROBOT_CONSOLE_LOG%"

rem If RF_ARGS already contains a test path, don't append RF_TEST_PATH again
set "RF_APPEND_PATH=1"
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "$a=$env:RF_ARGS; if($a -match '(^| )tests($| )' -or $a -match '\.robot' -or $a -match '[\\/]' ){ exit 0 } else { exit 1 }"
if !errorlevel! EQU 0 set "RF_APPEND_PATH=0"

if "%RF_APPEND_PATH%"=="1" (
  echo [INFO] CMD: python -m robot --outputdir "%RF_OUTPUT_DIR%" %RF_ARGS% "%RF_TEST_PATH%"
  python -m robot --outputdir "%RF_OUTPUT_DIR%" %RF_ARGS% "%RF_TEST_PATH%" > "%ROBOT_CONSOLE_LOG%" 2>&1
) else (
  echo [INFO] CMD: python -m robot --outputdir "%RF_OUTPUT_DIR%" %RF_ARGS%
  python -m robot --outputdir "%RF_OUTPUT_DIR%" %RF_ARGS% > "%ROBOT_CONSOLE_LOG%" 2>&1
)

set "RF_EXIT=%ERRORLEVEL%"

if not "%RF_EXIT%"=="0" (
  echo [ERROR] Robot failed (exit=%RF_EXIT%). Tail robot_console.log:
  powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
    "if(Test-Path '%ROBOT_CONSOLE_LOG%'){Get-Content -Tail 120 '%ROBOT_CONSOLE_LOG%'}"
)

rem ---- Sync results to workspace/results ----
echo [INFO] ===== SYNC RESULTS =====
if exist "%RF_OUTPUT_DIR%\output.xml" (
  robocopy "%RF_OUTPUT_DIR%" "%RESULTS_DST%" /E /NFL /NDL /NJH /NJS /NC /NS >nul
) else (
  echo [WARN] output.xml not found under "%RF_OUTPUT_DIR%"
)

call :STOP_APPIUM >nul 2>&1
exit /b %RF_EXIT%

:SHOW_APPIUM_LOGS_FAIL
echo [ERROR] ===== Appium stdout (tail 120) =====
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "Get-Content -Tail 120 '%APPIUM_LOG%'"

echo [ERROR] ===== Appium stderr (tail 120) =====
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "Get-Content -Tail 120 '%APPIUM_ERR_LOG%'"
goto :FAIL

:STOP_APPIUM
rem Kill by pid file (process tree)
if exist "%APPIUM_PID_FILE%" (
  for /f "usebackq delims=" %%p in ("%APPIUM_PID_FILE%") do (
    if not "%%p"=="" taskkill /F /T /PID %%p >nul 2>&1
  )
  del /f /q "%APPIUM_PID_FILE%" >nul 2>&1
)

rem Kill by port as fallback
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "try{Get-NetTCPConnection -LocalPort %APPIUM_PORT% -State Listen -ErrorAction Stop ^| %%{Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue}}catch{}" >nul 2>&1

exit /b 0

:FAIL
call :STOP_APPIUM >nul 2>&1
exit /b 255