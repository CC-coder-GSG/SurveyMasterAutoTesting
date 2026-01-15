@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

rem ============================================================
rem  Jenkins verify (Windows): Appium + Robot Framework
rem  Fix 2026-01-15 (v4):
rem    - Fix Start-Process error: stdout/stderr must be different files
rem    - Remove WAIT loop constructs that trigger "Input redirection is not supported"
rem      (no `for /f (...) in ('netstat | findstr')`, no command-substitution)
rem    - Use Test-NetConnection for port readiness (fallback to netstat without pipes)
rem ============================================================

rem ---- 0) Paths ----
set "CI_DIR=%~dp0"
cd /d "%CI_DIR%\.."
set "AUTOTEST_DIR=%CD%"

if not defined WORKSPACE set "WORKSPACE=%AUTOTEST_DIR%"

rem ---- 1) Inputs / defaults ----
if not defined DEVICE_ID (
  echo [ERROR] DEVICE_ID is not set.
  exit /b 2
)

if not defined ANDROID_HOME set "ANDROID_HOME=D:\android-sdk"
set "ADB_CMD=%ANDROID_HOME%\platform-tools\adb.exe"

if not defined NPM_BIN set "NPM_BIN=%APPDATA%\npm"
if not defined APPIUM_CMD set "APPIUM_CMD=%NPM_BIN%\appium.cmd"
if not defined APPIUM_PORT set "APPIUM_PORT=4723"

set "APPIUM_LOG=%WORKSPACE%\appium.log"
set "APPIUM_ERR_LOG=%WORKSPACE%\appium.err.log"
set "APPIUM_PID_FILE=%WORKSPACE%\appium.pid"

set "RF_OUTPUT_DIR=results"
set "RESULTS_DST=%WORKSPACE%\results"

rem ---- 2) Clean old results ----
if exist "%RF_OUTPUT_DIR%" rmdir /s /q "%RF_OUTPUT_DIR%"
mkdir "%RF_OUTPUT_DIR%" >nul 2>&1
if exist "%RESULTS_DST%" rmdir /s /q "%RESULTS_DST%"
mkdir "%RESULTS_DST%" >nul 2>&1

rem ---- 3) Tool checks ----
if not exist "%ADB_CMD%" ( echo [ERROR] ADB not found: "%ADB_CMD%" & exit /b 2 )
if not exist "%APPIUM_CMD%" ( echo [ERROR] appium.cmd not found: "%APPIUM_CMD%" & exit /b 2 )

rem Ensure npm bin in PATH (for appium's child process resolution)
set "PATH=%NPM_BIN%;%PATH%"

echo.
echo ====== CHECK DEVICE ======
"%ADB_CMD%" start-server >nul 2>&1

set "DEV_OK=0"
for /l %%i in (1,1,12) do (
  powershell -NoProfile -NonInteractive -Command ^
    "$s = (& '%ADB_CMD%' -s '%DEVICE_ID%' get-state 2^>$null) -join ''; if($s.Trim() -eq 'device'){ exit 0 } else { exit 1 }"
  if !errorlevel! EQU 0 (
    set "DEV_OK=1"
    goto :DEVICE_OK
  )
  timeout /t 1 /nobreak >nul
)

echo [ERROR] Device "%DEVICE_ID%" not ready. adb devices output:
"%ADB_CMD%" devices
exit /b 3

:DEVICE_OK
echo [OK] Device "%DEVICE_ID%" is online.

echo.
echo ====== CLEAN PORT %APPIUM_PORT% ======

rem Kill by PID file (if exists)
if exist "%APPIUM_PID_FILE%" (
  for /f "usebackq delims=" %%p in ("%APPIUM_PID_FILE%") do (
    if not "%%p"=="" taskkill /F /PID %%p >nul 2>&1
  )
  del /f /q "%APPIUM_PID_FILE%" >nul 2>&1
)

rem Kill listening process by port (PowerShell; no cmd pipes/redirection)
powershell -NoProfile -NonInteractive -Command ^
  "try { $c = Get-NetTCPConnection -LocalPort %APPIUM_PORT% -State Listen -ErrorAction Stop; foreach($x in $c){ Stop-Process -Id $x.OwningProcess -Force -ErrorAction SilentlyContinue } } catch { }"

echo.
echo ====== START APPIUM ======
if exist "%APPIUM_LOG%" del /f /q "%APPIUM_LOG%" >nul 2>&1
if exist "%APPIUM_ERR_LOG%" del /f /q "%APPIUM_ERR_LOG%" >nul 2>&1

rem IMPORTANT: RedirectStandardOutput and RedirectStandardError must be different files
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$log=$env:APPIUM_LOG; $err=$env:APPIUM_ERR_LOG; $pidFile=$env:APPIUM_PID_FILE;" ^
  "$cmd=('\"'+$env:APPIUM_CMD+'\" --address 127.0.0.1 --port '+$env:APPIUM_PORT+' --log-level info');" ^
  "$p=Start-Process -FilePath 'cmd.exe' -ArgumentList @('/c', $cmd) -WindowStyle Hidden -RedirectStandardOutput $log -RedirectStandardError $err -PassThru;" ^
  "$p.Id | Out-File -Encoding ascii $pidFile;" ^
  "Write-Host ('[INFO] Appium PID=' + $p.Id);"

if errorlevel 1 (
  echo [ERROR] Failed to launch Appium process.
  goto :SHOW_APPIUM_LOGS_FAIL
)

echo.
echo ====== WAIT APPIUM PORT ======
set "APPIUM_UP=0"
for /l %%i in (1,1,30) do (
  rem Use Test-NetConnection (no pipes)
  powershell -NoProfile -NonInteractive -Command ^
    "if (Test-NetConnection -ComputerName 127.0.0.1 -Port %APPIUM_PORT% -InformationLevel Quiet) { exit 0 } else { exit 1 }"
  if !errorlevel! EQU 0 (
    set "APPIUM_UP=1"
    goto :APPIUM_OK
  )

  rem Fallback: netstat without pipes (dump file then findstr)
  netstat -ano > "%WORKSPACE%\_netstat.txt"
  findstr /R /C:":%APPIUM_PORT% .*LISTENING" "%WORKSPACE%\_netstat.txt" >nul && (
    set "APPIUM_UP=1"
    goto :APPIUM_OK
  )

  timeout /t 1 /nobreak >nul
)

echo [ERROR] Appium failed to start on %APPIUM_PORT%.
goto :SHOW_APPIUM_LOGS_FAIL

:APPIUM_OK
echo [OK] Appium is ready.

echo.
echo ====== RUN ROBOT ======
if not defined RF_TEST_PATH set "RF_TEST_PATH=tests"
if not defined RF_ARGS set "RF_ARGS=--suite CreateNewProject"

where robot >nul 2>&1
if errorlevel 1 (
  where python >nul 2>&1 || (echo [ERROR] python not found in PATH & goto :FAIL)
  python -V
  python -m robot %RF_ARGS% --outputdir "%RF_OUTPUT_DIR%" "%RF_TEST_PATH%"
) else (
  robot --version
  robot %RF_ARGS% --outputdir "%RF_OUTPUT_DIR%" "%RF_TEST_PATH%"
)
set "RF_EXIT=%ERRORLEVEL%"

echo.
echo ====== SYNC RESULTS ======
if exist "%RF_OUTPUT_DIR%\output.xml" (
  robocopy "%RF_OUTPUT_DIR%" "%RESULTS_DST%" /E /NFL /NDL /NJH /NJS /NC /NS >nul
) else (
  echo [WARN] output.xml not found under "%AUTOTEST_DIR%\%RF_OUTPUT_DIR%"
)

echo.
echo ====== STOP APPIUM ======
call :STOP_APPIUM
exit /b %RF_EXIT%

:SHOW_APPIUM_LOGS_FAIL
echo [ERROR] Appium logs (tail 120) - stdout:
if exist "%APPIUM_LOG%" powershell -NoProfile -NonInteractive -Command "Get-Content -Tail 120 '%APPIUM_LOG%'" else echo [WARN] appium.log not found
echo [ERROR] Appium logs (tail 120) - stderr:
if exist "%APPIUM_ERR_LOG%" powershell -NoProfile -NonInteractive -Command "Get-Content -Tail 120 '%APPIUM_ERR_LOG%'" else echo [WARN] appium.err.log not found
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