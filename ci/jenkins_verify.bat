@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

rem ============================================================
rem  Jenkins verify (Windows): Appium + Robot Framework
rem  v16 (2026-01-15) - Stable Jenkins Edition
rem    - ALWAYS use CALL for *.cmd/*.bat (prevents early exit)
rem    - Appium ready detection: dual-signal (appium.log + netstat LISTENING)
rem    - Longer wait (up to 240s) to avoid race condition
rem    - No "pip install" in CI (install once on agent)
rem    - Robot console log: %WORKSPACE%\results\robot_console.log
rem    - Stop Appium: kill process tree (/T) + kill by port fallback
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

rem ---- Tool checks ----
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

rem Kill any listener on the port (best effort)
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "try{Get-NetTCPConnection -LocalPort %APPIUM_PORT% -State Listen -ErrorAction Stop ^| %%{Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue}}catch{}" >nul 2>&1

rem ---- Start Appium ----
echo [INFO] ===== START APPIUM =====
if exist "%APPIUM_LOG%" del /f /q "%APPIUM_LOG%" >nul 2>&1
if exist "%APPIUM_ERR_LOG%" del /f /q "%APPIUM_ERR_LOG%" >nul 2>&1
if exist "%APPIUM_PID_FILE%" del /f /q "%APPIUM_PID_FILE%" >nul 2>&1

rem Start via cmd.exe so wrapper behavior is stable; DO NOT treat launcher exit as failure
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$log=$env:APPIUM_LOG; $err=$env:APPIUM_ERR_LOG; $pidFile=$env:APPIUM_PID_FILE;" ^
  "$cmd='""'+$env:APPIUM_CMD+'"" --address 127.0.0.1 --port '+$env:APPIUM_PORT+' --log-level info --local-timezone';" ^
  "$p=Start-Process -FilePath 'cmd.exe' -ArgumentList @('/c',$cmd) -WindowStyle Hidden -RedirectStandardOutput $log -RedirectStandardError $err -PassThru;" ^
  "$p.Id ^| Out-File -Encoding ascii $pidFile;" ^
  "Write-Host ('[INFO] Appium launcher PID=' + $p.Id);" >nul 2>&1

rem ---- Wait Appium ready ----
echo [INFO] ===== WAIT APPIUM READY (up to 240s) =====
set "APPIUM_UP=0"
for /l %%i in (1,1,240) do (
  rem Signal A: log contains listener line (race-proof)
  if exist "%APPIUM_LOG%" (
    findstr /C:"listener started on http://127.0.0.1:%APPIUM_PORT%" "%APPIUM_LOG%" >nul 2>&1
    if !errorlevel! EQU 0 (
      set "APPIUM_UP=1"
      goto :APPIUM_OK
    )
    findstr /C:"Appium REST http interface listener started" "%APPIUM_LOG%" >nul 2>&1
    if !errorlevel! EQU 0 (
      set "APPIUM_UP=1"
      goto :APPIUM_OK
    )
  )

  rem Signal B: netstat shows LISTENING (no pipe)
  netstat -ano > "%NETSTAT_TMP%" 2>nul
  findstr /R /C:":%APPIUM_PORT% .*LISTENING" "%NETSTAT_TMP%" >nul 2>&1
  if !errorlevel! EQU 0 (
    set "APPIUM_UP=1"
    goto :APPIUM_OK
  )

  ping -n 2 127.0.0.1 >nul
)

echo [ERROR] Appium timeout: port %APPIUM_PORT% not ready.
goto :SHOW_APPIUM_LOGS_FAIL

:APPIUM_OK
echo [OK] Appium is ready on %APPIUM_PORT%.

rem Record REAL service PID by port (for cleanup)
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "try{ $c=Get-NetTCPConnection -LocalPort %APPIUM_PORT% -State Listen -ErrorAction Stop ^| Select-Object -First 1; if($c){ $c.OwningProcess ^| Out-File -Encoding ascii $env:APPIUM_PID_FILE } }catch{}" >nul 2>&1

rem ---- Run Robot ----
echo [INFO] ===== RUN ROBOT =====
if not defined RF_TEST_PATH set "RF_TEST_PATH=tests"
if not defined RF_ARGS set "RF_ARGS=--suite CreateNewProject"

where python >nul 2>&1 || (echo [ERROR] python not found in PATH & goto :FAIL)

python -c "import robot; print(robot.__version__)" >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Robot Framework not installed in this Python.
  echo [HINT] Install once on agent: pip install robotframework robotframework-appiumlibrary Appium-Python-Client
  goto :FAIL
)

echo [INFO] Robot console log: "%ROBOT_CONSOLE_LOG%"
echo [INFO] CMD: python -m robot --outputdir "%RF_OUTPUT_DIR%" %RF_ARGS% "%RF_TEST_PATH%"
python -m robot --outputdir "%RF_OUTPUT_DIR%" %RF_ARGS% "%RF_TEST_PATH%" > "%ROBOT_CONSOLE_LOG%" 2>&1
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
if exist "%APPIUM_LOG%" (
  powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "Get-Content -Tail 120 '%APPIUM_LOG%'"
) else (
  echo [WARN] appium.log not found
)

echo [ERROR] ===== Appium stderr (tail 120) =====
if exist "%APPIUM_ERR_LOG%" (
  powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "Get-Content -Tail 120 '%APPIUM_ERR_LOG%'"
) else (
  echo [WARN] appium.err.log not found
)
goto :FAIL

:STOP_APPIUM
rem Kill by pid file (process tree)
if exist "%APPIUM_PID_FILE%" (
  for /f "usebackq delims=" %%p in ("%APPIUM_PID_FILE%") do (
    if not "%%p"=="" taskkill /F /T /PID %%p >nul 2>&1
  )
  del /f /q "%APPIUM_PID_FILE%" >nul 2>&1
)

rem Kill by port as fallback (covers wrapper PID mismatch)
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "try{Get-NetTCPConnection -LocalPort %APPIUM_PORT% -State Listen -ErrorAction Stop ^| %%{Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue}}catch{}" >nul 2>&1

exit /b 0

:FAIL
call :STOP_APPIUM >nul 2>&1
exit /b 255