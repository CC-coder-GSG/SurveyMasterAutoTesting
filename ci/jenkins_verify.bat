@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

rem ============================================================
rem  Jenkins verify (Windows): Appium + Robot Framework
rem  v7.1:
rem   - Force add Node.js PATH: C:\Program Files\nodejs
rem   - Keep ping sleep (no TIMEOUT)
rem   - Suppress Test-NetConnection warnings
rem ============================================================

set "CI_DIR=%~dp0"
cd /d "%CI_DIR%\.."
set "AUTOTEST_DIR=%CD%"

if not defined WORKSPACE set "WORKSPACE=%AUTOTEST_DIR%"

rem ---- 1) CRITICAL FIX: INJECT NODE.JS PATH ----
set "PATH=C:\Program Files\nodejs;%PATH%"

echo [INFO] Checking Node.js...
where node
node -v
if errorlevel 1 (
  echo [ERROR] 'node' still not working after PATH injection.
  echo [INFO] PATH=%PATH%
  exit /b 2
)

rem ---- 2) Checks ----
if not defined DEVICE_ID (
  echo [ERROR] DEVICE_ID is not set.
  exit /b 2
)

if not defined ANDROID_HOME set "ANDROID_HOME=D:\android-sdk"
set "ADB_CMD=%ANDROID_HOME%\platform-tools\adb.exe"

if not defined NPM_BIN set "NPM_BIN=%APPDATA%\npm"
if not defined APPIUM_CMD set "APPIUM_CMD=%NPM_BIN%\appium.cmd"
if not defined APPIUM_PORT set "APPIUM_PORT=4723"

rem Ensure npm bin is also in PATH
set "PATH=%NPM_BIN%;%PATH%"

set "APPIUM_LOG=%WORKSPACE%\appium.log"
set "APPIUM_ERR_LOG=%WORKSPACE%\appium.err.log"
set "APPIUM_PID_FILE=%WORKSPACE%\appium.pid"
set "RF_OUTPUT_DIR=results"
set "RESULTS_DST=%WORKSPACE%\results"

rem ---- 3) Clean ----
if exist "%RF_OUTPUT_DIR%" rmdir /s /q "%RF_OUTPUT_DIR%"
mkdir "%RF_OUTPUT_DIR%" >nul 2>&1
if exist "%RESULTS_DST%" rmdir /s /q "%RESULTS_DST%"
mkdir "%RESULTS_DST%" >nul 2>&1

rem ---- 4) Tools ----
if not exist "%ADB_CMD%" ( echo [ERROR] ADB not found: "%ADB_CMD%" & exit /b 2 )
if not exist "%APPIUM_CMD%" ( echo [ERROR] appium.cmd not found: "%APPIUM_CMD%" & exit /b 2 )

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

if exist "%APPIUM_PID_FILE%" (
  for /f "usebackq delims=" %%p in ("%APPIUM_PID_FILE%") do (
    if not "%%p"=="" taskkill /F /PID %%p >nul 2>&1
  )
  del /f /q "%APPIUM_PID_FILE%" >nul 2>&1
)

powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "try { $c = Get-NetTCPConnection -LocalPort %APPIUM_PORT% -State Listen -ErrorAction Stop; foreach($x in $c){ Stop-Process -Id $x.OwningProcess -Force -ErrorAction SilentlyContinue } } catch { }"

echo.
echo ====== START APPIUM ======
if exist "%APPIUM_LOG%" del /f /q "%APPIUM_LOG%" >nul 2>&1
if exist "%APPIUM_ERR_LOG%" del /f /q "%APPIUM_ERR_LOG%" >nul 2>&1

powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$log=$env:APPIUM_LOG; $err=$env:APPIUM_ERR_LOG; $pidFile=$env:APPIUM_PID_FILE;" ^
  "$cmd=('\"'+$env:APPIUM_CMD+'\" --address 127.0.0.1 --port '+$env:APPIUM_PORT+' --log-level info --local-timezone');" ^
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
  powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
    "$pidVal=(Get-Content -Path $env:APPIUM_PID_FILE -ErrorAction SilentlyContinue | Select-Object -First 1); if(-not $pidVal){ exit 100 }; $pidVal=$pidVal.Trim(); try{$pid=[int]$pidVal}catch{exit 100}; if(-not (Get-Process -Id $pid -ErrorAction SilentlyContinue)){ exit 100 } else { exit 0 }"
  if !errorlevel! EQU 100 (
    echo [ERROR] Appium process died unexpectedly!
    goto :SHOW_APPIUM_LOGS_FAIL
  )

  powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
    "if (Test-NetConnection -ComputerName 127.0.0.1 -Port %APPIUM_PORT% -InformationLevel Quiet -WarningAction SilentlyContinue) { exit 0 } else { exit 1 }"
  if !errorlevel! EQU 0 (
    set "APPIUM_UP=1"
    goto :APPIUM_OK
  )

  netstat -ano > "%WORKSPACE%\_netstat.txt"
  findstr /R /C:":%APPIUM_PORT% .*LISTENING" "%WORKSPACE%\_netstat.txt" >nul && (
    set "APPIUM_UP=1"
    goto :APPIUM_OK
  )

  ping -n 2 127.0.0.1 >nul
)

echo [ERROR] Appium failed to start on %APPIUM_PORT% (Timeout).
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