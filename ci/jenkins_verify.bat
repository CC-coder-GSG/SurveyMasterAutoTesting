@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

rem ============================================================
rem  Jenkins verify (Windows): Appium + Robot Framework
rem  Fix 2026-01-15:
rem    - Avoid `start ... > log` (cmd start doesn't support redirection in Jenkins)
rem    - Start Appium via PowerShell Start-Process with stdout/stderr redirected
rem    - Remove problematic non-ASCII "comment" lines that were being executed
rem ============================================================

rem ---- 0) Paths (script is expected at: autotest\ci\jenkins_verify.bat) ----
set "CI_DIR=%~dp0"
cd /d "%CI_DIR%\.."
set "AUTOTEST_DIR=%CD%"

rem Jenkins normally injects WORKSPACE; fallback to current dir if missing
if not defined WORKSPACE set "WORKSPACE=%AUTOTEST_DIR%"

rem ---- 1) Inputs / defaults ----
if not defined DEVICE_ID (
  echo [ERROR] DEVICE_ID is not set. Jenkins should pass it via withEnv or stage env.
  exit /b 2
)

if not defined ANDROID_HOME set "ANDROID_HOME=D:\android-sdk"
set "ADB_CMD=%ANDROID_HOME%\platform-tools\adb.exe"

if not defined NPM_BIN set "NPM_BIN=%APPDATA%\npm"
if not defined APPIUM_CMD set "APPIUM_CMD=%NPM_BIN%\appium.cmd"
if not defined APPIUM_PORT set "APPIUM_PORT=4723"

set "APPIUM_LOG=%WORKSPACE%\appium.log"
set "APPIUM_PID_FILE=%WORKSPACE%\appium.pid"

rem Robot defaults (RF_ARGS should be "options only"; script will append tests path)
if not defined RF_TEST_PATH set "RF_TEST_PATH=tests"
if not defined RF_OUTPUT_DIR set "RF_OUTPUT_DIR=results"
if not defined RF_ARGS set "RF_ARGS=--suite CreateNewProject"

set "RESULTS_DST=%WORKSPACE%\results"

rem ---- 2) Clean old results ----
if exist "%RF_OUTPUT_DIR%" (
  echo [INFO] Cleaning old "%AUTOTEST_DIR%\%RF_OUTPUT_DIR%" ...
  rmdir /s /q "%RF_OUTPUT_DIR%"
)
mkdir "%RF_OUTPUT_DIR%" >nul 2>&1

if exist "%RESULTS_DST%" (
  echo [INFO] Cleaning old "%RESULTS_DST%" ...
  rmdir /s /q "%RESULTS_DST%"
)
mkdir "%RESULTS_DST%" >nul 2>&1

rem ---- 3) Tool checks ----
echo [INFO] Checking ADB: "%ADB_CMD%"
if not exist "%ADB_CMD%" (
  echo [ERROR] ADB not found: "%ADB_CMD%"
  exit /b 2
)

echo [INFO] Checking Appium: "%APPIUM_CMD%"
if not exist "%APPIUM_CMD%" (
  echo [ERROR] appium.cmd not found: "%APPIUM_CMD%"
  exit /b 2
)

rem ---- 4) Ensure device is online ----
echo.
echo ====== CHECK DEVICE ======
"%ADB_CMD%" start-server >nul 2>&1

set "DEV_OK=0"
for /l %%i in (1,1,10) do (
  for /f "usebackq delims=" %%L in (`"%ADB_CMD%" devices 2^>^&1`) do (
    echo %%L | findstr /R /C:"^%DEVICE_ID%[ ]\+device$" >nul && set "DEV_OK=1"
  )
  if "!DEV_OK!"=="1" goto :DEVICE_OK
  timeout /t 1 /nobreak >nul
)
echo [ERROR] Device "%DEVICE_ID%" not in 'device' state. Output:
"%ADB_CMD%" devices
exit /b 3

:DEVICE_OK
echo [OK] Device "%DEVICE_ID%" is online.

rem ---- 5) Clean port 4723 (kill listener) ----
echo.
echo ====== CLEAN PORT %APPIUM_PORT% (if occupied) ======

rem 5.1 kill previous Appium PID if we recorded it
if exist "%APPIUM_PID_FILE%" (
  for /f "usebackq delims=" %%p in ("%APPIUM_PID_FILE%") do (
    if not "%%p"=="" (
      taskkill /F /PID %%p >nul 2>&1
    )
  )
  del /f /q "%APPIUM_PID_FILE%" >nul 2>&1
)

rem 5.2 kill any process listening on the port
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /R /C:":%APPIUM_PORT% .*LISTENING"') do (
  taskkill /F /PID %%p >nul 2>&1
)

rem ---- 6) Start Appium (PowerShell Start-Process with redirection) ----
echo.
echo ====== START APPIUM ======
if exist "%APPIUM_LOG%" del /f /q "%APPIUM_LOG%" >nul 2>&1

powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$log=$env:APPIUM_LOG; $pidFile=$env:APPIUM_PID_FILE;" ^
  "$cmd='\"'+$env:APPIUM_CMD+'\" --address 127.0.0.1 --port '+$env:APPIUM_PORT+' --log-level info';" ^
  "$p=Start-Process -FilePath 'cmd.exe' -ArgumentList @('/c', $cmd) -WindowStyle Hidden -RedirectStandardOutput $log -RedirectStandardError $log -PassThru;" ^
  "$p.Id | Out-File -Encoding ascii $pidFile;" ^
  "Write-Host ('[INFO] Appium PID=' + $p.Id);"

if errorlevel 1 (
  echo [ERROR] Failed to launch Appium process. See "%APPIUM_LOG%"
  goto :FAIL
)

rem ---- 7) Wait for port listening ----
set "APPIUM_UP=0"
set "APPIUM_LISTEN_PID="
for /l %%i in (1,1,30) do (
  for /f "tokens=1,2,3,4,5" %%a in ('netstat -ano ^| findstr /R /C:":%APPIUM_PORT% .*LISTENING"') do (
    set "APPIUM_UP=1"
    set "APPIUM_LISTEN_PID=%%e"
  )
  if "!APPIUM_UP!"=="1" goto :APPIUM_OK
  timeout /t 1 /nobreak >nul
)

echo [ERROR] Appium not listening on %APPIUM_PORT%.
echo [ERROR] Tail of appium.log:
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "if(Test-Path $env:APPIUM_LOG){Get-Content -Tail 120 $env:APPIUM_LOG} else {Write-Host '[WARN] appium.log not found'}"
goto :FAIL

:APPIUM_OK
echo [OK] Appium is listening on %APPIUM_PORT% (PID !APPIUM_LISTEN_PID!).

rem ---- 8) Run Robot Framework ----
echo.
echo ====== RUN ROBOT ======
echo [INFO] RF_ARGS=%RF_ARGS%
echo [INFO] RF_TEST_PATH=%RF_TEST_PATH%
echo [INFO] RF_OUTPUT_DIR=%RF_OUTPUT_DIR%

rem Prefer `robot`; fallback to `python -m robot`
where robot >nul 2>&1
if errorlevel 1 (
  echo [INFO] robot not found in PATH, fallback to "python -m robot"
  where python >nul 2>&1 || (echo [ERROR] python not found in PATH & goto :FAIL)
  python -m robot %RF_ARGS% --outputdir "%RF_OUTPUT_DIR%" "%RF_TEST_PATH%"
) else (
  robot %RF_ARGS% --outputdir "%RF_OUTPUT_DIR%" "%RF_TEST_PATH%"
)
set "RF_EXIT=%ERRORLEVEL%"
echo [INFO] Robot exit code=%RF_EXIT%

rem ---- 9) Sync results to WORKSPACE\results ----
echo.
echo ====== SYNC RESULTS ======
if exist "%RF_OUTPUT_DIR%\output.xml" (
  robocopy "%RF_OUTPUT_DIR%" "%RESULTS_DST%" /E /NFL /NDL /NJH /NJS /NC /NS >nul
  set "RC=%ERRORLEVEL%"
  if %RC% GEQ 8 (
    echo [WARN] robocopy failed with code %RC% (will continue)
  ) else (
    echo [OK] Results synced to "%RESULTS_DST%"
  )
) else (
  echo [WARN] output.xml not found under "%AUTOTEST_DIR%\%RF_OUTPUT_DIR%"
)

rem ---- 10) Stop Appium ----
echo.
echo ====== STOP APPIUM ======
if exist "%APPIUM_PID_FILE%" (
  for /f "usebackq delims=" %%p in ("%APPIUM_PID_FILE%") do (
    if not "%%p"=="" (
      taskkill /F /PID %%p >nul 2>&1
    )
  )
  del /f /q "%APPIUM_PID_FILE%" >nul 2>&1
) else (
  for /f "tokens=5" %%p in ('netstat -ano ^| findstr /R /C:":%APPIUM_PORT% .*LISTENING"') do (
    taskkill /F /PID %%p >nul 2>&1
  )
)

exit /b %RF_EXIT%

:FAIL
rem try to stop Appium if started
if exist "%APPIUM_PID_FILE%" (
  for /f "usebackq delims=" %%p in ("%APPIUM_PID_FILE%") do taskkill /F /PID %%p >nul 2>&1
  del /f /q "%APPIUM_PID_FILE%" >nul 2>&1
)
exit /b 255