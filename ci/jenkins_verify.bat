@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

rem ============================================================
rem  Jenkins verify (Windows): Appium + Robot Framework
rem  Fix 2026-01-15 (v15 - SYNTAX & DETECTION FIX):
rem    1. FIX: Replaced 'echo.' with 'echo' to prevent ". was unexpected" crash.
rem    2. FIX: Use 'call' for npm/appium (Prevent early exit).
rem    3. ROBUST: Use PowerShell to read netstat file (Handles encoding/spaces).
rem    4. SAFETY: No pipes, no network calls from PowerShell (Safe execution).
rem ============================================================

set "CI_DIR=%~dp0"
cd /d "%CI_DIR%\.."
set "AUTOTEST_DIR=%CD%"

if not defined WORKSPACE set "WORKSPACE=%AUTOTEST_DIR%"

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

set "PATH=%NPM_BIN%;%PATH%"
if exist "C:\Program Files\nodejs\node.exe" set "PATH=C:\Program Files\nodejs;%PATH%"

set "APPIUM_LOG=%WORKSPACE%\appium.log"
set "APPIUM_ERR_LOG=%WORKSPACE%\appium.err.log"
set "APPIUM_PID_FILE=%WORKSPACE%\appium.pid"
set "RF_OUTPUT_DIR=results"
set "RESULTS_DST=%WORKSPACE%\results"
set "ROBOT_CONSOLE_LOG=%WORKSPACE%\robot_console.log"
set "NETSTAT_TMP=%WORKSPACE%\_netstat_check.txt"

set "PYTHONUTF8=1"
set "PYTHONIOENCODING=utf-8"

rem ---- 2) Clean ----
if exist "%RF_OUTPUT_DIR%" rmdir /s /q "%RF_OUTPUT_DIR%"
mkdir "%RF_OUTPUT_DIR%" >nul 2>&1
if exist "%RESULTS_DST%" rmdir /s /q "%RESULTS_DST%"
mkdir "%RESULTS_DST%" >nul 2>&1
if exist "%ROBOT_CONSOLE_LOG%" del /f /q "%ROBOT_CONSOLE_LOG%" >nul 2>&1

rem ---- 3) Environment Checks ----
echo ==========================================
echo [INFO] Checking Environment...
where node >nul 2>&1 && node -v || echo [WARN] node not found in PATH

echo [INFO] Checking Appium version...
call "%APPIUM_CMD%" -v
if errorlevel 1 (
    echo [ERROR] Appium CLI failed.
    exit /b 2
)

echo ==========================================
echo [INFO] Checking Device...
"%ADB_CMD%" start-server >nul 2>&1
set "DEV_OK=0"
for /l %%i in (1,1,12) do (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=(& '%ADB_CMD%' -s '%DEVICE_ID%' get-state 2>$null); if($s -like '*device*'){exit 0}else{exit 1}"
    if !errorlevel! EQU 0 (
        set "DEV_OK=1"
        goto :DEVICE_OK
    )
    ping -n 2 127.0.0.1 >nul
)
echo [ERROR] Device "%DEVICE_ID%" not ready.
exit /b 3

:DEVICE_OK
echo [OK] Device "%DEVICE_ID%" is online.

echo ==========================================
echo [INFO] Cleaning Port %APPIUM_PORT%...
call :STOP_APPIUM >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $c = Get-NetTCPConnection -LocalPort %APPIUM_PORT% -State Listen -ErrorAction Stop; foreach($x in $c){ Stop-Process -Id $x.OwningProcess -Force -ErrorAction SilentlyContinue } } catch { }"

echo ==========================================
echo [INFO] Starting Appium...
if exist "%APPIUM_LOG%" del /f /q "%APPIUM_LOG%" >nul 2>&1
if exist "%APPIUM_ERR_LOG%" del /f /q "%APPIUM_ERR_LOG%" >nul 2>&1
if exist "%APPIUM_PID_FILE%" del /f /q "%APPIUM_PID_FILE%" >nul 2>&1

rem Launch Appium (Launcher)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$log=$env:APPIUM_LOG; $err=$env:APPIUM_ERR_LOG;" ^
  "$args=@('--address','127.0.0.1','--port',$env:APPIUM_PORT,'--log-level','info','--local-timezone');" ^
  "$p=Start-Process -FilePath $env:APPIUM_CMD -ArgumentList $args -WindowStyle Hidden -RedirectStandardOutput $log -RedirectStandardError $err -PassThru;" ^
  "Write-Host ('[INFO] Appium launcher started');"

if errorlevel 1 (
    echo [ERROR] Failed to launch Appium.
    goto :SHOW_APPIUM_LOGS_FAIL
)

echo ==========================================
echo [INFO] Waiting for Appium on port %APPIUM_PORT%...
set "APPIUM_UP=0"
for /l %%i in (1,1,60) do (
    rem 1. Dump netstat to file (Safe CMD)
    netstat -ano > "%NETSTAT_TMP%"
    
    rem 2. Use PowerShell to READ file (Robust Wildcard Match)
    rem We verify if the file contains the port AND "LISTENING"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Get-Content $env:NETSTAT_TMP | Where-Object { $_ -like '*:%APPIUM_PORT%*LISTENING*' }) { exit 0 } else { exit 1 }"
    
    if !errorlevel! EQU 0 (
        set "APPIUM_UP=1"
        goto :APPIUM_OK
    )
    ping -n 2 127.0.0.1 >nul
)

echo [ERROR] Appium timeout. Port %APPIUM_PORT% was not detected in netstat output.
echo [DEBUG] Content of %NETSTAT_TMP%:
if exist "%NETSTAT_TMP%" type "%NETSTAT_TMP%"
goto :SHOW_APPIUM_LOGS_FAIL

:APPIUM_OK
echo [OK] Appium is ready on port %APPIUM_PORT%.

rem Find REAL PID using PowerShell parsing (Safe)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$line = Get-Content $env:NETSTAT_TMP | Where-Object { $_ -like '*:%APPIUM_PORT%*LISTENING*' } | Select-Object -First 1; if($line){ $parts=$line.Trim() -split '\s+'; $pidVal=$parts[-1]; $pidVal | Out-File -Encoding ascii $env:APPIUM_PID_FILE; Write-Host ('[INFO] Appium Service PID=' + $pidVal) }"

echo ==========================================
echo [INFO] Running Robot Framework...
if not defined RF_TEST_PATH set "RF_TEST_PATH=tests"
if not defined RF_ARGS set "RF_ARGS=--suite CreateNewProject"

rem Auto-Install (Use CALL)
echo [INFO] Ensuring dependencies...
call pip install robotframework Appium-Python-Client robotframework-appiumlibrary >nul 2>&1

rem Run Robot
echo [INFO] CMD: python -m robot --outputdir "%RF_OUTPUT_DIR%" %RF_ARGS% "%RF_TEST_PATH%"
python -m robot --outputdir "%RF_OUTPUT_DIR%" %RF_ARGS% "%RF_TEST_PATH%" >> "%ROBOT_CONSOLE_LOG%" 2>&1
set "RF_EXIT=%ERRORLEVEL%"

if not "%RF_EXIT%"=="0" (
    echo [ERROR] Robot tests failed with exit code %RF_EXIT%.
    if exist "%ROBOT_CONSOLE_LOG%" type "%ROBOT_CONSOLE_LOG%"
)

echo ==========================================
echo [INFO] Syncing Results...
if exist "%RF_OUTPUT_DIR%\output.xml" (
    robocopy "%RF_OUTPUT_DIR%" "%RESULTS_DST%" /E /NFL /NDL /NJH /NJS /NC /NS >nul
) else (
    echo [WARN] output.xml not found.
)

call :STOP_APPIUM
exit /b %RF_EXIT%

:SHOW_APPIUM_LOGS_FAIL
echo [ERROR] ===== Appium stdout =====
if exist "%APPIUM_LOG%" ( powershell -NoProfile -Command "Get-Content -Tail 50 '%APPIUM_LOG%'" )
echo [ERROR] ===== Appium stderr =====
if exist "%APPIUM_ERR_LOG%" ( powershell -NoProfile -Command "Get-Content -Tail 50 '%APPIUM_ERR_LOG%'" )
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