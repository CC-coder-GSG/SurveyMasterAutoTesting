@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

rem ============================================================
rem  Jenkins verify (Windows): Appium + Robot Framework
rem  Fix 2026-01-15 (v13):
rem    - Fix false "Appium timeout": Appium becomes ready right at timeout
rem      (log shows listener started, while our netstat check missed it).
rem    - Wait longer + use TWO readiness signals:
rem        1) appium.log contains "listener started on http://127.0.0.1:4723"
rem        2) netstat shows :4723 LISTENING (no pipes, no regex dependency)
rem    - Remove "pip install ..." auto-install (often fails in CI/offline).
rem    - Put robot console log into autotest\results and sync to WORKSPACE\results.
rem ============================================================

set "CI_DIR=%~dp0"
cd /d "%CI_DIR%\.."
set "AUTOTEST_DIR=%CD%"

if not defined WORKSPACE set "WORKSPACE=%AUTOTEST_DIR%"

rem ---- 0) Node.js PATH (user confirmed) ----
if exist "C:\Program Files\nodejs\node.exe" (
  set "PATH=C:\Program Files\nodejs;%PATH%"
)

rem ---- 1) Inputs ----
if not defined DEVICE_ID (
  echo [ERROR] DEVICE_ID is not set.
  exit /b 2
)

if not defined ANDROID_HOME set "ANDROID_HOME=D:\android-sdk"
set "ADB_CMD=%ANDROID_HOME%\platform-tools\adb.exe"

if not defined NPM_BIN set "NPM_BIN=%APPDATA%\npm"
if not defined APPIUM_CMD set "APPIUM_CMD=%NPM_BIN%\appium.cmd"
if not defined APPIUM_PORT set "APPIUM_PORT=4723"

rem Ensure npm bin in PATH (so appium.cmd can find node_modules shims if needed)
set "PATH=%NPM_BIN%;%PATH%"

set "APPIUM_LOG=%WORKSPACE%\appium.log"
set "APPIUM_ERR_LOG=%WORKSPACE%\appium.err.log"
set "APPIUM_PID_FILE=%WORKSPACE%\appium.pid"

set "RF_OUTPUT_DIR=results"
set "RESULTS_DST=%WORKSPACE%\results"
set "ROBOT_CONSOLE_LOG=%RF_OUTPUT_DIR%\robot_console.log"
set "NETSTAT_TMP=%WORKSPACE%\_netstat_check.txt"
set "PORT_LINES=%WORKSPACE%\_port_%APPIUM_PORT%_lines.txt"

set "PYTHONUTF8=1"
set "PYTHONIOENCODING=utf-8"

echo.
echo ====== ENV CHECK ======
where node >nul 2>&1
if errorlevel 1 (
  echo [ERROR] node not found. PATH=%PATH%
  exit /b 2
)
for /f "delims=" %%p in ('where node') do echo [INFO] node: %%p
node -v

if not exist "%APPIUM_CMD%" (
  echo [ERROR] appium.cmd not found: "%APPIUM_CMD%"
  exit /b 2
)
call "%APPIUM_CMD%" -v
if errorlevel 1 (
  echo [ERROR] Appium CLI failed to run (check node/npm/env).
  exit /b 2
)
echo [DBG] ENV CHECK OK, continue.

rem ---- 2) Clean results ----
if exist "%RF_OUTPUT_DIR%" rmdir /s /q "%RF_OUTPUT_DIR%"
mkdir "%RF_OUTPUT_DIR%" >nul 2>&1
if exist "%RESULTS_DST%" rmdir /s /q "%RESULTS_DST%"
mkdir "%RESULTS_DST%" >nul 2>&1
if exist "%ROBOT_CONSOLE_LOG%" del /f /q "%ROBOT_CONSOLE_LOG%" >nul 2>&1

rem ---- 3) Tool checks ----
if not exist "%ADB_CMD%" (
  echo [ERROR] ADB not found: "%ADB_CMD%"
  exit /b 2
)

rem ---- 4) Ensure device is online ----
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

rem ---- 5) Clean Appium ----
echo.
echo ====== CLEAN PORT %APPIUM_PORT% ======
call :STOP_APPIUM >nul 2>&1

powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "try { $c = Get-NetTCPConnection -LocalPort %APPIUM_PORT% -State Listen -ErrorAction Stop; foreach($x in $c){ Stop-Process -Id $x.OwningProcess -Force -ErrorAction SilentlyContinue } } catch { }"

rem ---- 6) Start Appium ----
echo.
echo ====== START APPIUM ======
if exist "%APPIUM_LOG%" del /f /q "%APPIUM_LOG%" >nul 2>&1
if exist "%APPIUM_ERR_LOG%" del /f /q "%APPIUM_ERR_LOG%" >nul 2>&1

rem Start Appium via cmd.exe so the PID we record is stable even if appium.cmd is a wrapper.
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$log=$env:APPIUM_LOG; $err=$env:APPIUM_ERR_LOG; $pidFile=$env:APPIUM_PID_FILE;" ^
  "$cmd='""'+$env:APPIUM_CMD+'"" --address 127.0.0.1 --port '+$env:APPIUM_PORT+' --log-level info --local-timezone';" ^
  "$p=Start-Process -FilePath 'cmd.exe' -ArgumentList @('/c', $cmd) -WindowStyle Hidden -RedirectStandardOutput $log -RedirectStandardError $err -PassThru;" ^
  "$p.Id | Out-File -Encoding ascii $pidFile;" ^
  "Write-Host ('[INFO] Appium cmd PID=' + $p.Id);"

if errorlevel 1 (
  echo [ERROR] Failed to launch Appium.
  goto :SHOW_APPIUM_LOGS_FAIL
)

rem ---- 7) Wait Appium ready (IMPORTANT FIX) ----
echo.
echo ====== WAIT APPIUM READY (port %APPIUM_PORT%) ======

set "APPIUM_UP=0"
rem Wait up to 180s (Appium/uiautomator2 first load can be slow)
for /l %%i in (1,1,180) do (

  rem Signal A: appium.log contains listener line (fastest, avoids netstat edge races)
  if exist "%APPIUM_LOG%" (
    findstr /C:"listener started on http://127.0.0.1:%APPIUM_PORT%" "%APPIUM_LOG%" >nul 2>&1
    if !errorlevel! EQU 0 (
      set "APPIUM_UP=1"
      goto :APPIUM_OK
    )
  )

  rem Signal B: netstat shows LISTENING on the port (NO pipes)
  netstat -ano > "%NETSTAT_TMP%" 2>nul
  findstr /C:":%APPIUM_PORT%" "%NETSTAT_TMP%" > "%PORT_LINES%" 2>nul
  findstr /C:"LISTENING" "%PORT_LINES%" >nul 2>&1
  if !errorlevel! EQU 0 (
    set "APPIUM_UP=1"
    goto :APPIUM_OK
  )

  ping -n 2 127.0.0.1 >nul
)

echo [ERROR] Appium timeout. (No listener line in log AND netstat never LISTENING)
goto :SHOW_APPIUM_LOGS_FAIL

:APPIUM_OK
echo [OK] Appium is ready on port %APPIUM_PORT%.

rem Try to capture real service PID by port (optional; STOP_APPIUM also kills by port)
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "try { $c = Get-NetTCPConnection -LocalPort %APPIUM_PORT% -State Listen -ErrorAction Stop | Select-Object -First 1; if($c){ $c.OwningProcess | Out-File -Encoding ascii $env:APPIUM_PID_FILE } } catch { }" >nul 2>&1

rem ---- 8) Run Robot Framework ----
echo.
echo ====== RUN ROBOT ======
if not defined RF_TEST_PATH set "RF_TEST_PATH=tests"
if not defined RF_ARGS set "RF_ARGS=--suite CreateNewProject"

where python >nul 2>&1
if errorlevel 1 (
  echo [ERROR] python not found in PATH.
  goto :FAIL
)

rem Ensure robot is installed (no auto-install in CI)
python -c "import robot; print(robot.__version__)" >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Robot Framework not installed in this Python.
  echo [HINT] Install once on agent: pip install robotframework robotframework-appiumlibrary Appium-Python-Client
  goto :FAIL
)

echo [INFO] CMD: python -m robot --outputdir "%RF_OUTPUT_DIR%" %RF_ARGS% "%RF_TEST_PATH%"
python -m robot --outputdir "%RF_OUTPUT_DIR%" %RF_ARGS% "%RF_TEST_PATH%" > "%ROBOT_CONSOLE_LOG%" 2>&1
set "RF_EXIT=%ERRORLEVEL%"

if not "%RF_EXIT%"=="0" (
  echo [ERROR] Robot failed with exit code %RF_EXIT%.
  echo [INFO] Tail robot_console.log:
  powershell -NoProfile -NonInteractive -Command "if(Test-Path '%ROBOT_CONSOLE_LOG%'){Get-Content -Tail 120 '%ROBOT_CONSOLE_LOG%'}"
)

rem ---- 9) Sync Results ----
echo.
echo ====== SYNC RESULTS ======
if exist "%RF_OUTPUT_DIR%\output.xml" (
  robocopy "%RF_OUTPUT_DIR%" "%RESULTS_DST%" /E /NFL /NDL /NJH /NJS /NC /NS >nul
) else (
  echo [WARN] output.xml not found under "%AUTOTEST_DIR%\%RF_OUTPUT_DIR%"
)

rem Also sync robot_console.log even if output.xml missing
if exist "%ROBOT_CONSOLE_LOG%" (
  copy /y "%ROBOT_CONSOLE_LOG%" "%RESULTS_DST%\robot_console.log" >nul 2>&1
)

echo.
echo ====== STOP APPIUM ======
call :STOP_APPIUM >nul 2>&1
exit /b %RF_EXIT%

:SHOW_APPIUM_LOGS_FAIL
echo [ERROR] ===== Appium stdout (tail 120) =====
if exist "%APPIUM_LOG%" (
  powershell -NoProfile -NonInteractive -Command "Get-Content -Tail 120 '%APPIUM_LOG%'"
) else (
  echo [WARN] appium.log not found
)

echo [ERROR] ===== Appium stderr (tail 120) =====
if exist "%APPIUM_ERR_LOG%" (
  powershell -NoProfile -NonInteractive -Command "Get-Content -Tail 120 '%APPIUM_ERR_LOG%'"
) else (
  echo [WARN] appium.err.log not found
)

echo [ERROR] ===== netstat snapshot =====
if exist "%PORT_LINES%" (
  type "%PORT_LINES%"
) else (
  if exist "%NETSTAT_TMP%" type "%NETSTAT_TMP%"
)

goto :FAIL

:STOP_APPIUM
rem 1) Kill by PID file if present
if exist "%APPIUM_PID_FILE%" (
  for /f "usebackq delims=" %%p in ("%APPIUM_PID_FILE%") do (
    if not "%%p"=="" (
      taskkill /F /T /PID %%p >nul 2>&1
    )
  )
  del /f /q "%APPIUM_PID_FILE%" >nul 2>&1
)

rem 2) Also kill by port (covers wrapper PID mismatch)
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "try { $c = Get-NetTCPConnection -LocalPort %APPIUM_PORT% -State Listen -ErrorAction Stop; foreach($x in $c){ Stop-Process -Id $x.OwningProcess -Force -ErrorAction SilentlyContinue } } catch { }" >nul 2>&1

exit /b 0

:FAIL
call :STOP_APPIUM >nul 2>&1
exit /b 255