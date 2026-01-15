@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

rem ============================================================
rem  Jenkins verify (Windows): Appium + Robot Framework
rem  Fix 2026-01-15 (v8):
rem    - Root cause (latest log): "Fail fast if Appium dies" is too strict.
rem      Your launcher PID (cmd/appium.cmd wrapper) may exit quickly even if
rem      the real node process keeps running OR before the port check happens.
rem    - Solution:
rem        1) Start Appium (stdout/stderr split)
rem        2) Wait for /status or port LISTEN
rem        3) Record REAL PID by the listening port (4723)
rem        4) Stop by REAL PID (port owner) instead of launcher PID
rem    - Also: force Node + npm bin into PATH, avoid `timeout` (Jenkins stdin issue)
rem ============================================================

set "CI_DIR=%~dp0"
cd /d "%CI_DIR%\.."
set "AUTOTEST_DIR=%CD%"

if not defined WORKSPACE set "WORKSPACE=%AUTOTEST_DIR%"

rem ---- 0) FORCE PATH (Node + npm bin) ----
set "NODE_HOME=C:\Program Files\nodejs"
if not exist "%NODE_HOME%\node.exe" (
  echo [ERROR] node.exe not found under: "%NODE_HOME%"
  exit /b 2
)

if not defined NPM_BIN set "NPM_BIN=%APPDATA%\npm"
set "PATH=%NODE_HOME%;%NPM_BIN%;%PATH%"

echo [INFO] Checking Node.js...
where node
node -v

rem ---- 1) Required inputs ----
if not defined DEVICE_ID (
  echo [ERROR] DEVICE_ID is not set.
  exit /b 2
)

if not defined ANDROID_HOME set "ANDROID_HOME=D:\android-sdk"
set "ADB_CMD=%ANDROID_HOME%\platform-tools\adb.exe"

if not defined APPIUM_CMD set "APPIUM_CMD=%NPM_BIN%\appium.cmd"
if not defined APPIUM_PORT set "APPIUM_PORT=4723"

set "APPIUM_LOG=%WORKSPACE%\appium.log"
set "APPIUM_ERR_LOG=%WORKSPACE%\appium.err.log"
set "APPIUM_LAUNCHER_PID_FILE=%WORKSPACE%\appium.launcher.pid"
set "APPIUM_PID_FILE=%WORKSPACE%\appium.pid"

set "RF_OUTPUT_DIR=results"
set "RESULTS_DST=%WORKSPACE%\results"

rem ---- 2) Clean results ----
if exist "%RF_OUTPUT_DIR%" rmdir /s /q "%RF_OUTPUT_DIR%"
mkdir "%RF_OUTPUT_DIR%" >nul 2>&1

if exist "%RESULTS_DST%" rmdir /s /q "%RESULTS_DST%"
mkdir "%RESULTS_DST%" >nul 2>&1

rem ---- 3) Tool checks ----
if not exist "%ADB_CMD%" ( echo [ERROR] ADB not found: "%ADB_CMD%" & exit /b 2 )
if not exist "%APPIUM_CMD%" ( echo [ERROR] appium.cmd not found: "%APPIUM_CMD%" & exit /b 2 )

echo [INFO] Checking Appium version...
call "%APPIUM_CMD%" --version
if errorlevel 1 (
  echo [ERROR] Appium CLI failed. Try running "%APPIUM_CMD% --version" in a cmd window.
  exit /b 2
)

echo.
echo ====== CHECK DEVICE ======
"%ADB_CMD%" start-server >nul 2>&1

set "DEV_OK=0"
for /l %%i in (1,1,15) do (
  powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
    "$s = (& '%ADB_CMD%' -s '%DEVICE_ID%' get-state 2^>$null) -join ''; if($s.Trim() -eq 'device'){ exit 0 } else { exit 1 }"
  if !errorlevel! EQU 0 (
    set "DEV_OK=1"
    goto :DEVICE_OK
  )
  rem sleep ~1s without `timeout`
  ping -n 2 127.0.0.1 >nul
)

echo [ERROR] Device "%DEVICE_ID%" not ready.
"%ADB_CMD%" devices
exit /b 3

:DEVICE_OK
echo [OK] Device "%DEVICE_ID%" is online.

echo.
echo ====== CLEAN PORT %APPIUM_PORT% ======

rem kill previous by PID files
call :STOP_APPIUM >nul 2>&1

rem kill previous by listening port
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "try { $c = Get-NetTCPConnection -LocalPort %APPIUM_PORT% -State Listen -ErrorAction Stop; foreach($x in $c){ Stop-Process -Id $x.OwningProcess -Force -ErrorAction SilentlyContinue } } catch { }"

echo.
echo ====== START APPIUM ======
if exist "%APPIUM_LOG%" del /f /q "%APPIUM_LOG%" >nul 2>&1
if exist "%APPIUM_ERR_LOG%" del /f /q "%APPIUM_ERR_LOG%" >nul 2>&1
if exist "%APPIUM_LAUNCHER_PID_FILE%" del /f /q "%APPIUM_LAUNCHER_PID_FILE%" >nul 2>&1
if exist "%APPIUM_PID_FILE%" del /f /q "%APPIUM_PID_FILE%" >nul 2>&1

rem Start Appium in background (stdout/stderr split)
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$log=$env:APPIUM_LOG; $err=$env:APPIUM_ERR_LOG; $pidFile=$env:APPIUM_LAUNCHER_PID_FILE;" ^
  "$args=@('--address','127.0.0.1','--port',$env:APPIUM_PORT,'--log-level','info','--local-timezone');" ^
  "$p=Start-Process -FilePath $env:APPIUM_CMD -ArgumentList $args -WindowStyle Hidden -RedirectStandardOutput $log -RedirectStandardError $err -PassThru;" ^
  "$p.Id | Out-File -Encoding ascii $pidFile;" ^
  "Write-Host ('[INFO] Appium launcher PID=' + $p.Id);"

if errorlevel 1 (
  echo [ERROR] Failed to launch Appium process.
  goto :SHOW_APPIUM_LOGS_FAIL
)

echo.
echo ====== WAIT APPIUM READY ======
set "APPIUM_UP=0"
for /l %%i in (1,1,60) do (

  rem 1) Prefer /status readiness (best signal)
  powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
    "try { $null = Invoke-RestMethod -Uri ('http://127.0.0.1:%APPIUM_PORT%/status') -TimeoutSec 2 -ErrorAction Stop; exit 0 } catch { exit 1 }"
  if !errorlevel! EQU 0 (
    set "APPIUM_UP=1"
    goto :APPIUM_OK
  )

  rem 2) Fallback: port LISTEN check
  powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
    "$c = Get-NetTCPConnection -LocalPort %APPIUM_PORT% -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1; if($c){ exit 0 } else { exit 1 }"
  if !errorlevel! EQU 0 (
    set "APPIUM_UP=1"
    goto :APPIUM_OK
  )

  ping -n 2 127.0.0.1 >nul
)

echo [ERROR] Appium did not become ready on %APPIUM_PORT% (Timeout).
goto :SHOW_APPIUM_LOGS_FAIL

:APPIUM_OK
echo [OK] Appium is ready.

rem Record REAL PID from the listening port (this is what we should kill later)
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "$c = Get-NetTCPConnection -LocalPort %APPIUM_PORT% -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1; if($c){ $c.OwningProcess | Out-File -Encoding ascii $env:APPIUM_PID_FILE; Write-Host ('[INFO] Appium listen PID=' + $c.OwningProcess) }"

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
echo [ERROR] ===== Appium stdout (tail 200) =====
if exist "%APPIUM_LOG%" (
  powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "Get-Content -Tail 200 '%APPIUM_LOG%'"
) else (
  echo [WARN] appium.log not found: "%APPIUM_LOG%"
)

echo [ERROR] ===== Appium stderr (tail 200) =====
if exist "%APPIUM_ERR_LOG%" (
  powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "Get-Content -Tail 200 '%APPIUM_ERR_LOG%'"
) else (
  echo [WARN] appium.err.log not found: "%APPIUM_ERR_LOG%"
)

echo [INFO] ===== netstat :%APPIUM_PORT% =====
netstat -ano | findstr /R /C:":%APPIUM_PORT% .*LISTENING"

goto :FAIL

:STOP_APPIUM
rem Prefer killing by REAL listen PID (port owner)
if exist "%APPIUM_PID_FILE%" (
  for /f "usebackq delims=" %%p in ("%APPIUM_PID_FILE%") do (
    if not "%%p"=="" taskkill /F /PID %%p >nul 2>&1
  )
  del /f /q "%APPIUM_PID_FILE%" >nul 2>&1
)

rem Also kill launcher PID if still present
if exist "%APPIUM_LAUNCHER_PID_FILE%" (
  for /f "usebackq delims=" %%p in ("%APPIUM_LAUNCHER_PID_FILE%") do (
    if not "%%p"=="" taskkill /F /PID %%p >nul 2>&1
  )
  del /f /q "%APPIUM_LAUNCHER_PID_FILE%" >nul 2>&1
)
exit /b 0

:FAIL
call :STOP_APPIUM
exit /b 255