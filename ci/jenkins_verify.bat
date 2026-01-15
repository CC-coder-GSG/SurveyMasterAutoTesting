@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

rem ============================================================
rem  Jenkins verify (Windows): Appium + Robot Framework
rem  v12 (2026-01-15)
rem    - Fix: calling *.cmd/*.bat MUST use CALL, otherwise this script will end early
rem    - Avoid Jenkins "Input redirection is not supported": use PING for waits (no TIMEOUT)
rem    - Start Appium via cmd.exe /c and split stdout/stderr logs
rem    - Wait for Appium by netstat->file (no pipes), then capture REAL PID by port
rem    - Robot console log goes to: %WORKSPACE%\results\robot_console.log
rem ============================================================

set "CI_DIR=%~dp0"
cd /d "%CI_DIR%\.."
set "AUTOTEST_DIR=%CD%"

if not defined WORKSPACE set "WORKSPACE=%AUTOTEST_DIR%"

rem ---- 0) Node.js PATH (optional) ----
if exist "C:\Program Files\nodejs\node.exe" (
  set "PATH=C:\Program Files\nodejs;%PATH%"
)

rem ---- 1) Required inputs ----
if not defined DEVICE_ID (
  echo [ERROR] DEVICE_ID is not set.
  exit /b 2
)

if not defined ANDROID_HOME set "ANDROID_HOME=D:\android-sdk"
set "ADB_CMD=%ANDROID_HOME%\platform-tools\adb.exe"

if not defined NPM_BIN set "NPM_BIN=%APPDATA%\npm"
if not defined APPIUM_CMD set "APPIUM_CMD=%NPM_BIN%\appium.cmd"
if not defined APPIUM_PORT set "APPIUM_PORT=4723"

rem Ensure npm bin in PATH (for appium + node module scripts)
set "PATH=%NPM_BIN%;%PATH%"

set "APPIUM_LOG=%WORKSPACE%\appium.log"
set "APPIUM_ERR_LOG=%WORKSPACE%\appium.err.log"
set "APPIUM_PID_FILE=%WORKSPACE%\appium.pid"

set "RF_OUTPUT_DIR=results"
set "RESULTS_DST=%WORKSPACE%\results"
set "ROBOT_CONSOLE_LOG=%RESULTS_DST%\robot_console.log"
set "NETSTAT_TMP=%WORKSPACE%\_netstat_check.txt"

set "PYTHONUTF8=1"
set "PYTHONIOENCODING=utf-8"

rem ---- 2) Clean & prepare dirs ----
if exist "%RF_OUTPUT_DIR%" rmdir /s /q "%RF_OUTPUT_DIR%"
mkdir "%RF_OUTPUT_DIR%" >nul 2>&1

if not exist "%RESULTS_DST%" mkdir "%RESULTS_DST%" >nul 2>&1
if exist "%ROBOT_CONSOLE_LOG%" del /f /q "%ROBOT_CONSOLE_LOG%" >nul 2>&1

rem ---- 3) Tool checks ----
if not exist "%ADB_CMD%" ( echo [ERROR] ADB not found: "%ADB_CMD%" & exit /b 2 )
if not exist "%APPIUM_CMD%" ( echo [ERROR] appium.cmd not found: "%APPIUM_CMD%" & exit /b 2 )

echo.
echo ====== ENV CHECK ======
where node >nul 2>&1 || (echo [ERROR] node not found in PATH & exit /b 2)
node -v

rem IMPORTANT: appium.cmd is a *.cmd script. MUST use CALL or this script will end right here.
call "%APPIUM_CMD%" -v
if errorlevel 1 (
  echo [ERROR] Appium CLI failed.
  exit /b 2
)
echo [DBG] ENV CHECK OK, continue...

echo.
echo ====== CHECK DEVICE ======
"%ADB_CMD%" start-server >nul 2>&1

set "DEV_OK=0"
for /l %%i in (1,1,12) do (
  powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
    "$s = (& '%ADB_CMD%' -s '%DEVICE_ID%' get-state 2^>$null) -join ''; if($s.Trim() -eq 'device'){ exit 0 } else { exit 1 }"
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

echo.
echo ====== CLEAN PORT %APPIUM_PORT% ======
call :STOP_APPIUM >nul 2>&1

rem Best-effort: kill anything still listening on the port
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "try { $c = Get-NetTCPConnection -LocalPort %APPIUM_PORT% -State Listen -ErrorAction Stop; foreach($x in $c){ Stop-Process -Id $x.OwningProcess -Force -ErrorAction SilentlyContinue } } catch { }"

echo.
echo ====== START APPIUM ======
if exist "%APPIUM_LOG%" del /f /q "%APPIUM_LOG%" >nul 2>&1
if exist "%APPIUM_ERR_LOG%" del /f /q "%APPIUM_ERR_LOG%" >nul 2>&1
if exist "%APPIUM_PID_FILE%" del /f /q "%APPIUM_PID_FILE%" >nul 2>&1

rem NOTE:
rem appium.cmd may exit quickly after spawning the real node process.
rem So we do NOT treat "launcher PID exited" as failure.
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$log=$env:APPIUM_LOG; $err=$env:APPIUM_ERR_LOG;" ^
  "$cmd=('\"'+$env:APPIUM_CMD+'\" --address 127.0.0.1 --port '+$env:APPIUM_PORT+' --log-level info --local-timezone');" ^
  "$p=Start-Process -FilePath 'cmd.exe' -ArgumentList @('/c', $cmd) -WindowStyle Hidden -RedirectStandardOutput $log -RedirectStandardError $err -PassThru;" ^
  "Write-Host ('[INFO] Appium launcher PID=' + $p.Id);"

if errorlevel 1 (
  echo [ERROR] Failed to launch Appium.
  goto :SHOW_APPIUM_LOGS_FAIL
)

echo.
echo ====== WAIT APPIUM READY (port %APPIUM_PORT%) ======
set "APPIUM_UP=0"
for /l %%i in (1,1,60) do (
  netstat -ano > "%NETSTAT_TMP%"
  findstr /R /C:":%APPIUM_PORT% .*LISTENING" "%NETSTAT_TMP%" >nul
  if !errorlevel! EQU 0 (
    set "APPIUM_UP=1"
    goto :APPIUM_OK
  )
  ping -n 2 127.0.0.1 >nul
)

echo [ERROR] Appium timeout (port %APPIUM_PORT% never LISTENING).
goto :SHOW_APPIUM_LOGS_FAIL

:APPIUM_OK
echo [OK] Appium is LISTENING on %APPIUM_PORT%.

rem Capture REAL PID by parsing netstat output (avoid Get-NetTCPConnection dependency)
set "REAL_PID="
for /f "tokens=1,2,3,4,5" %%a in ('findstr /R /C:":%APPIUM_PORT% .*LISTENING" "%NETSTAT_TMP%"') do (
  set "REAL_PID=%%e"
  goto :GOT_PID
)

:GOT_PID
if not defined REAL_PID (
  echo [WARN] Could not parse Appium PID from netstat. Cleanup may be weaker.
) else (
  echo %REAL_PID%> "%APPIUM_PID_FILE%"
  echo [INFO] Appium service PID=%REAL_PID%
)

echo.
echo ====== RUN ROBOT ======
if not defined RF_TEST_PATH set "RF_TEST_PATH=tests"
if not defined RF_ARGS set "RF_ARGS=--suite CreateNewProject"

where python >nul 2>&1 || (echo [ERROR] python not found in PATH & goto :FAIL)

rem Prefer "python -m robot"; ensure it exists
python -m robot --version >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Robot Framework not available in this python env.
  echo         Try: python -m pip install robotframework robotframework-appiumlibrary Appium-Python-Client
  goto :FAIL
)

echo [INFO] Robot console log: "%ROBOT_CONSOLE_LOG%"
echo [INFO] CMD: python -m robot --outputdir "%RF_OUTPUT_DIR%" %RF_ARGS% "%RF_TEST_PATH%"
python -m robot --outputdir "%RF_OUTPUT_DIR%" %RF_ARGS% "%RF_TEST_PATH%" >> "%ROBOT_CONSOLE_LOG%" 2>&1
set "RF_EXIT=%ERRORLEVEL%"

if not "%RF_EXIT%"=="0" (
  echo [ERROR] Robot failed (exit=%RF_EXIT%). Printing last 120 lines of robot_console.log:
  powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
    "if(Test-Path '%ROBOT_CONSOLE_LOG%'){ Get-Content -Tail 120 '%ROBOT_CONSOLE_LOG%' }"
)

echo.
echo ====== SYNC RESULTS ======
if exist "%RF_OUTPUT_DIR%\output.xml" (
  robocopy "%RF_OUTPUT_DIR%" "%RESULTS_DST%" /E /NFL /NDL /NJH /NJS /NC /NS >nul
) else (
  echo [ERROR] output.xml not found under "%AUTOTEST_DIR%\%RF_OUTPUT_DIR%".
  echo         This usually means Robot did not really run or crashed early.
  set "RF_EXIT=10"
)

echo.
echo ====== STOP APPIUM ======
call :STOP_APPIUM
exit /b %RF_EXIT%

:SHOW_APPIUM_LOGS_FAIL
echo [ERROR] ===== Appium stdout (tail 80) =====
if exist "%APPIUM_LOG%" (
  powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "Get-Content -Tail 80 '%APPIUM_LOG%'"
) else (
  echo [WARN] appium.log not found
)

echo [ERROR] ===== Appium stderr (tail 80) =====
if exist "%APPIUM_ERR_LOG%" (
  powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "Get-Content -Tail 80 '%APPIUM_ERR_LOG%'"
) else (
  echo [WARN] appium.err.log not found
)
goto :FAIL

:STOP_APPIUM
if exist "%APPIUM_PID_FILE%" (
  for /f "usebackq delims=" %%p in ("%APPIUM_PID_FILE%") do (
    if not "%%p"=="" taskkill /F /PID %%p >nul 2>&1
  )
  del /f /q "%APPIUM_PID_FILE%" >nul 2>&1
)
exit /b 0

:FAIL
call :STOP_APPIUM
exit /b 255