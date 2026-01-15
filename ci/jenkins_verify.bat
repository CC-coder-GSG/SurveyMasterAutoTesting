@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

rem ============================================================
rem  Jenkins verify (Windows): Appium + Robot Framework
rem  Fix 2026-01-15 (v10 - robust):
rem    1) Force-add Node.js (C:\Program Files\nodejs) to PATH
rem    2) Start Appium and wait by /status (DO NOT fail on "launcher PID died")
rem    3) After Appium is ready, overwrite pidfile with LISTENING PID (real server PID)
rem    4) Run Robot with safer arg order + capture console to robot_console.log
rem    5) Print useful tails on failure (appium.log/appium.err.log/robot_console.log)
rem ============================================================

set "CI_DIR=%~dp0"
cd /d "%CI_DIR%\.."
set "AUTOTEST_DIR=%CD%"

if not defined WORKSPACE set "WORKSPACE=%AUTOTEST_DIR%"

rem ---- Node.js PATH injection (user confirmed) ----
if exist "C:\Program Files\nodejs\node.exe" (
  set "PATH=C:\Program Files\nodejs;%PATH%"
)

echo.
echo ====== CHECK NODE / APPIUM ======
echo [INFO] Checking Node.js.
where node >nul 2>&1
if errorlevel 1 (
  echo [ERROR] node not found in PATH.
  echo [INFO] Current PATH: %PATH%
  exit /b 2
)
for /f "delims=" %%p in ('where node') do echo [INFO] node at: %%p
for /f "delims=" %%v in ('node -v 2^>nul') do echo [INFO] Node version: %%v

if not defined NPM_BIN set "NPM_BIN=%APPDATA%\npm"
set "PATH=%NPM_BIN%;%PATH%"
if not defined APPIUM_CMD set "APPIUM_CMD=%NPM_BIN%\appium.cmd"
if not defined APPIUM_PORT set "APPIUM_PORT=4723"

if not exist "%APPIUM_CMD%" (
  echo [ERROR] appium.cmd not found: "%APPIUM_CMD%"
  echo [INFO] Hint: npm i -g appium ^& appium --version
  exit /b 2
)

echo [INFO] Checking Appium version.
for /f "delims=" %%v in ('"%APPIUM_CMD%" --version 2^>nul') do echo [INFO] Appium version: %%v

rem ---- Required env ----
if not defined DEVICE_ID (
  echo [ERROR] DEVICE_ID is not set.
  exit /b 2
)

if not defined ANDROID_HOME set "ANDROID_HOME=D:\android-sdk"
set "ADB_CMD=%ANDROID_HOME%\platform-tools\adb.exe"
if not exist "%ADB_CMD%" (
  echo [ERROR] ADB not found: "%ADB_CMD%"
  exit /b 2
)

set "APPIUM_LOG=%WORKSPACE%\appium.log"
set "APPIUM_ERR_LOG=%WORKSPACE%\appium.err.log"
set "APPIUM_PID_FILE=%WORKSPACE%\appium.pid"
set "ROBOT_CONSOLE_LOG=%WORKSPACE%\robot_console.log"

set "RF_OUTPUT_DIR=results"
set "RESULTS_DST=%WORKSPACE%\results"

rem ---- Clean results ----
if exist "%RF_OUTPUT_DIR%" rmdir /s /q "%RF_OUTPUT_DIR%"
mkdir "%RF_OUTPUT_DIR%" >nul 2>&1
if exist "%RESULTS_DST%" rmdir /s /q "%RESULTS_DST%"
mkdir "%RESULTS_DST%" >nul 2>&1

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

rem Kill by pidfile first (best-effort)
if exist "%APPIUM_PID_FILE%" (
  for /f "usebackq delims=" %%p in ("%APPIUM_PID_FILE%") do (
    if not "%%p"=="" (
      taskkill /F /PID %%p >nul 2>&1
    )
  )
  del /f /q "%APPIUM_PID_FILE%" >nul 2>&1
)

rem Kill any LISTENING process on the port
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "try { $c = Get-NetTCPConnection -LocalPort %APPIUM_PORT% -State Listen -ErrorAction Stop; foreach($x in $c){ Stop-Process -Id $x.OwningProcess -Force -ErrorAction SilentlyContinue } } catch { }"

echo.
echo ====== START APPIUM ======
if exist "%APPIUM_LOG%" del /f /q "%APPIUM_LOG%" >nul 2>&1
if exist "%APPIUM_ERR_LOG%" del /f /q "%APPIUM_ERR_LOG%" >nul 2>&1

rem IMPORTANT: Appium 3 may spawn a child (node) and the "launcher PID" can exit quickly.
rem So we DO NOT fail fast on "launcher PID died". We only rely on /status readiness.

powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$log='%APPIUM_LOG%'; $err='%APPIUM_ERR_LOG%'; $pidFile='%APPIUM_PID_FILE%';" ^
  "$cmd=('\"%APPIUM_CMD%\" --address 127.0.0.1 --port %APPIUM_PORT% --log-level info');" ^
  "$p=Start-Process -FilePath 'cmd.exe' -ArgumentList @('/c', $cmd) -WindowStyle Hidden -RedirectStandardOutput $log -RedirectStandardError $err -PassThru;" ^
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
  powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
    "try { Invoke-RestMethod -Uri 'http://127.0.0.1:%APPIUM_PORT%/status' -Method Get -TimeoutSec 1 ^| Out-Null; exit 0 } catch { exit 1 }"
  if !errorlevel! EQU 0 (
    set "APPIUM_UP=1"
    goto :APPIUM_OK
  )
  ping -n 2 127.0.0.1 >nul
)

echo [ERROR] Appium failed to become ready on %APPIUM_PORT% (Timeout).
goto :SHOW_APPIUM_LOGS_FAIL

:APPIUM_OK
echo [OK] Appium is ready.

rem Overwrite PID file with the real LISTENING PID (so STOP works reliably)
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "try { $c = Get-NetTCPConnection -LocalPort %APPIUM_PORT% -State Listen -ErrorAction Stop ^| Select-Object -First 1; if($c){ $c.OwningProcess ^| Out-File -Encoding ascii '%APPIUM_PID_FILE%'; Write-Host ('[INFO] Appium listen PID=' + $c.OwningProcess) } } catch { }"

echo.
echo ====== RUN ROBOT ======
if not defined RF_TEST_PATH set "RF_TEST_PATH=tests"
if not defined RF_ARGS set "RF_ARGS=--suite CreateNewProject"

if not exist "%RF_TEST_PATH%" (
  echo [ERROR] RF_TEST_PATH not found: "%RF_TEST_PATH%"
  dir /b
  goto :FAIL
)

rem Detect if RF_ARGS already contains the datasource path, to avoid "tests tests"
set "RF_DATASOURCE=%RF_TEST_PATH%"
echo %RF_ARGS% | findstr /I "%RF_TEST_PATH%" >nul && set "RF_DATASOURCE="

where python >nul 2>&1 || (echo [ERROR] python not found in PATH & goto :FAIL)

echo [INFO] Checking RobotFramework install...
python -c "import robot; print('RobotFramework', robot.__version__)" >nul 2>&1
if errorlevel 1 (
  echo [ERROR] RobotFramework not installed for this python.
  echo [INFO] Hint: pip install -r requirements.txt
  goto :FAIL
)

if exist "%ROBOT_CONSOLE_LOG%" del /f /q "%ROBOT_CONSOLE_LOG%" >nul 2>&1

echo [INFO] Robot cmd:
echo        python -m robot --outputdir "%RF_OUTPUT_DIR%" %RF_ARGS% %RF_DATASOURCE%

python -m robot --outputdir "%RF_OUTPUT_DIR%" %RF_ARGS% %RF_DATASOURCE% > "%ROBOT_CONSOLE_LOG%" 2>&1
set "RF_EXIT=%ERRORLEVEL%"

if not "%RF_EXIT%"=="0" (
  echo [ERROR] Robot failed with exit code %RF_EXIT%.
  echo [ERROR] Robot console log (tail 200):
  powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "if(Test-Path '%ROBOT_CONSOLE_LOG%'){ Get-Content -Tail 200 '%ROBOT_CONSOLE_LOG%' }"
)

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
if exist "%APPIUM_LOG%" (
    powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "Get-Content -Tail 120 '%APPIUM_LOG%'"
) else (
    echo [WARN] appium.log not found
)

echo [ERROR] Appium logs (tail 120) - stderr:
if exist "%APPIUM_ERR_LOG%" (
    powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "Get-Content -Tail 120 '%APPIUM_ERR_LOG%'"
) else (
    echo [WARN] appium.err.log not found
)

echo [INFO] netstat snapshot:
netstat -ano | findstr /R /C:":%APPIUM_PORT% .*LISTENING"

goto :FAIL

:STOP_APPIUM
rem Try PID file first
if exist "%APPIUM_PID_FILE%" (
  for /f "usebackq delims=" %%p in ("%APPIUM_PID_FILE%") do (
    if not "%%p"=="" (
      taskkill /F /PID %%p >nul 2>&1
    )
  )
  del /f /q "%APPIUM_PID_FILE%" >nul 2>&1
)

rem Fallback: kill by port (in case pidfile had launcher pid only)
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "try { $c = Get-NetTCPConnection -LocalPort %APPIUM_PORT% -State Listen -ErrorAction Stop; foreach($x in $c){ Stop-Process -Id $x.OwningProcess -Force -ErrorAction SilentlyContinue } } catch { }"

exit /b 0

:FAIL
call :STOP_APPIUM
exit /b 255