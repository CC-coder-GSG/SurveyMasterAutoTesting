@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

rem ============================================================
rem  Jenkins verify (Windows): Appium + Robot Framework
rem  Fix 2026-01-15 (v11):
rem    - Root cause from logs: Appium is LISTENING on 4723 but the HTTP /status probe never succeeds.
rem      So we switch readiness to "port LISTEN" (most reliable), and ONLY treat /status as optional.
rem    - Also fix PID mismatch: the LISTENING PID is node.exe (child), while we previously saved cmd.exe PID.
rem      We now save launcher PID separately and overwrite main PID with the port-owning PID once LISTENING.
rem ============================================================

set "CI_DIR=%~dp0"
cd /d "%CI_DIR%\.."
set "AUTOTEST_DIR=%CD%"

if not defined WORKSPACE set "WORKSPACE=%AUTOTEST_DIR%"

rem ---- 0) Optional: ensure Node.js is in PATH (you confirmed location) ----
if exist "C:\Program Files\nodejs\node.exe" (
  set "PATH=C:\Program Files\nodejs;%PATH%"
)

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

set "PATH=%NPM_BIN%;%PATH%"

set "APPIUM_LOG=%WORKSPACE%\appium.log"
set "APPIUM_ERR_LOG=%WORKSPACE%\appium.err.log"

rem launcher pid = cmd.exe / appium.cmd wrapper
set "APPIUM_LAUNCHER_PID_FILE=%WORKSPACE%\appium.launcher.pid"
rem main pid = real owning pid of port (node.exe)
set "APPIUM_PID_FILE=%WORKSPACE%\appium.pid"

set "RF_OUTPUT_DIR=results"
set "RESULTS_DST=%WORKSPACE%\results"

rem ---- 2) Clean results dirs ----
if exist "%RF_OUTPUT_DIR%" rmdir /s /q "%RF_OUTPUT_DIR%"
mkdir "%RF_OUTPUT_DIR%" >nul 2>&1
if exist "%RESULTS_DST%" rmdir /s /q "%RESULTS_DST%"
mkdir "%RESULTS_DST%" >nul 2>&1

rem ---- 3) Tool checks ----
if not exist "%ADB_CMD%" (
  echo [ERROR] ADB not found: "%ADB_CMD%"
  exit /b 2
)
if not exist "%APPIUM_CMD%" (
  echo [ERROR] appium.cmd not found: "%APPIUM_CMD%"
  exit /b 2
)

echo.
echo ====== ENV CHECK ======
where node >nul 2>&1 && (node -v) || (echo [WARN] node not found in PATH)
where npm  >nul 2>&1 && (npm -v)  || (echo [WARN] npm not found in PATH)

echo [INFO] Checking Appium version.
call "%APPIUM_CMD%" -v

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

rem kill any process owning the port (best-effort)
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "try { $c = Get-NetTCPConnection -LocalPort %APPIUM_PORT% -State Listen -ErrorAction Stop; foreach($x in $c){ Stop-Process -Id $x.OwningProcess -Force -ErrorAction SilentlyContinue } } catch { }"

echo.
echo ====== START APPIUM ======
if exist "%APPIUM_LOG%" del /f /q "%APPIUM_LOG%" >nul 2>&1
if exist "%APPIUM_ERR_LOG%" del /f /q "%APPIUM_ERR_LOG%" >nul 2>&1
if exist "%APPIUM_LAUNCHER_PID_FILE%" del /f /q "%APPIUM_LAUNCHER_PID_FILE%" >nul 2>&1
if exist "%APPIUM_PID_FILE%" del /f /q "%APPIUM_PID_FILE%" >nul 2>&1

rem NOTE: keep stdout/stderr split (avoid file lock / redirect conflicts)
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$log=$env:APPIUM_LOG; $err=$env:APPIUM_ERR_LOG; $launcherPidFile=$env:APPIUM_LAUNCHER_PID_FILE;" ^
  "$cmd=('\"'+$env:APPIUM_CMD+'\" --address 127.0.0.1 --port '+$env:APPIUM_PORT+' --log-level info --local-timezone');" ^
  "$p=Start-Process -FilePath 'cmd.exe' -ArgumentList @('/c', $cmd) -WindowStyle Hidden -RedirectStandardOutput $log -RedirectStandardError $err -PassThru;" ^
  "$p.Id | Out-File -Encoding ascii $launcherPidFile;" ^
  "Write-Host ('[INFO] Appium launcher PID=' + $p.Id);"

if errorlevel 1 (
  echo [ERROR] Failed to launch Appium process.
  goto :SHOW_APPIUM_LOGS_FAIL
)

echo.
echo ====== WAIT APPIUM READY ======
set "APPIUM_UP=0"
for /l %%i in (1,1,60) do (

  rem 1) Fail fast if launcher died
  powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
    "$pidVal = (Get-Content -Path $env:APPIUM_LAUNCHER_PID_FILE -ErrorAction SilentlyContinue | Select-Object -First 1);" ^
    "if(-not $pidVal){ exit 100 }" ^
    "$pidVal=$pidVal.Trim();" ^
    "try { $pid=[int]$pidVal } catch { exit 100 }" ^
    "if(-not (Get-Process -Id $pid -ErrorAction SilentlyContinue)){ exit 100 } else { exit 0 }"
  if !errorlevel! EQU 100 (
    echo [ERROR] Appium launcher died unexpectedly!
    goto :SHOW_APPIUM_LOGS_FAIL
  )

  rem 2) PRIMARY READY CHECK: port is LISTENING
  powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
    "$c = Get-NetTCPConnection -LocalPort %APPIUM_PORT% -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1;" ^
    "if($c) { $c.OwningProcess | Out-File -Encoding ascii $env:APPIUM_PID_FILE; exit 0 } else { exit 1 }"
  if !errorlevel! EQU 0 (
    set "APPIUM_UP=1"
    goto :APPIUM_OK
  )

  ping -n 2 127.0.0.1 >nul
)

echo [ERROR] Appium did not start listening on %APPIUM_PORT% (Timeout).
goto :SHOW_APPIUM_LOGS_FAIL

:APPIUM_OK
echo [OK] Appium is listening on %APPIUM_PORT%.
echo [INFO] Appium PID (port owner):
type "%APPIUM_PID_FILE%" 2>nul

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
netstat -ano | findstr /R /C:":%APPIUM_PORT% .*LISTENING" || echo [INFO] no LISTEN found

goto :FAIL

:STOP_APPIUM
rem 1) kill port owner pid
if exist "%APPIUM_PID_FILE%" (
  for /f "usebackq delims=" %%p in ("%APPIUM_PID_FILE%") do (
    if not "%%p"=="" taskkill /F /PID %%p >nul 2>&1
  )
  del /f /q "%APPIUM_PID_FILE%" >nul 2>&1
)

rem 2) kill launcher pid (wrapper)
if exist "%APPIUM_LAUNCHER_PID_FILE%" (
  for /f "usebackq delims=" %%p in ("%APPIUM_LAUNCHER_PID_FILE%") do (
    if not "%%p"=="" taskkill /F /PID %%p >nul 2>&1
  )
  del /f /q "%APPIUM_LAUNCHER_PID_FILE%" >nul 2>&1
)

rem 3) extra safety: kill any remaining listener on port
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "try { $c = Get-NetTCPConnection -LocalPort %APPIUM_PORT% -State Listen -ErrorAction Stop; foreach($x in $c){ Stop-Process -Id $x.OwningProcess -Force -ErrorAction SilentlyContinue } } catch { }"

exit /b 0

:FAIL
call :STOP_APPIUM
exit /b 255