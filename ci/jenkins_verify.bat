@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================
rem Jenkins verify runner (FINAL STABLE)
rem - No PowerShell device check (encryption-safe)
rem - Only uses: adb get-state (ASCII)
rem - Starts appium, runs robot with robot_args.txt
rem ============================================================

rem ---- Force Python 3.14 ----
set "PY_HOME=C:\Python314"
set "PY_EXE=%PY_HOME%\python.exe"
set "PY_SCRIPTS=%PY_HOME%\Scripts"
set "PATH=%PY_HOME%;%PY_SCRIPTS%;%PATH%"

rem ---- Force NodeJS and npm bin ----
set "NODE_HOME=C:\Program Files\nodejs"
set "NPM_BIN=%APPDATA%\npm"
set "PATH=%NODE_HOME%;%NPM_BIN%;%PATH%"

rem ---- Project root (autotest) ----
set "ROOT=%~dp0.."
set "BAT=%~f0"

rem ---- WORKSPACE results dir ----
if not "%WORKSPACE%"=="" (
  set "OUTDIR=%WORKSPACE%\results"
) else (
  set "OUTDIR=%ROOT%\..\results"
)

rem ---- ADB ----
if "%ANDROID_HOME%"=="" set "ANDROID_HOME=D:\android-sdk"
set "ADB_EXE=%ANDROID_HOME%\platform-tools\adb.exe"

rem ---- Defaults ----
if "%APPIUM_PORT%"=="" set "APPIUM_PORT=4723"
if "%DEVICE_ID%"=="" set "DEVICE_ID=4e83cae7"
set "ROBOT_RC=0"

echo [INFO] ===== START jenkins_verify.bat =====
echo [INFO] BAT=%BAT%
echo [INFO] ROOT=%ROOT%
echo [INFO] WORKSPACE=%WORKSPACE%
echo [INFO] OUTDIR=%OUTDIR%
echo [INFO] ANDROID_HOME=%ANDROID_HOME%
echo [INFO] ADB_EXE=%ADB_EXE%
echo [INFO] DEVICE_ID=%DEVICE_ID%
echo [INFO] APPIUM_PORT=%APPIUM_PORT%

pushd "%ROOT%" || (echo [ERROR] Cannot cd to project root.& exit /b 1)

if not exist "%OUTDIR%" mkdir "%OUTDIR%"

echo [INFO] ===== PYTHON CHECK =====
"%PY_EXE%" -V || (popd & exit /b 1)

echo [INFO] ===== ENV CHECK =====
where node >nul 2>&1 || (echo [ERROR] node not found.& set "ROBOT_RC=2" & goto :finally)
node -v

where npm >nul 2>&1 || (echo [ERROR] npm not found.& set "ROBOT_RC=2" & goto :finally)
call npm -v >nul 2>&1 || (echo [ERROR] npm failed.& set "ROBOT_RC=2" & goto :finally)

set "APPIUM_CMD=%NPM_BIN%\appium.cmd"
if not exist "%APPIUM_CMD%" (
  for /f "delims=" %%p in ('where appium 2^>nul') do set "APPIUM_CMD=%%p"
)
if not exist "%APPIUM_CMD%" (
  echo [ERROR] appium command not found.
  set "ROBOT_RC=2"
  goto :finally
)

echo [INFO] ===== CHECK DEVICE (ASCII get-state only) =====
if not exist "%ADB_EXE%" (
  echo [ERROR] adb.exe not found: %ADB_EXE%
  set "ROBOT_RC=3"
  goto :finally
)

"%ADB_EXE%" kill-server 1>nul 2>nul
"%ADB_EXE%" start-server 1>nul 2>nul

rem wait up to 30s for device state
set "STATE="
for /l %%i in (1,1,30) do (
  for /f "delims=" %%S in ('"%ADB_EXE%" -s %DEVICE_ID% get-state 2^>nul') do set "STATE=%%S"
  if /i "!STATE!"=="device" goto :device_ok
  ping 127.0.0.1 -n 2 >nul
)
echo [ERROR] Device not ready after 30s. get-state="!STATE!"
set "ROBOT_RC=3"
goto :finally

:device_ok
echo [OK] Device is ready: %DEVICE_ID%

echo [INFO] ===== CLEAN PORT %APPIUM_PORT% =====
call :kill_port %APPIUM_PORT%

echo [INFO] ===== START APPIUM =====
set "APPIUM_LOG=%OUTDIR%\appium.log"
start "appium" /b cmd /c "call ""%APPIUM_CMD%"" --address 127.0.0.1 --port %APPIUM_PORT% --log-level info --local-timezone 1> ""%APPIUM_LOG%"" 2>&1"
timeout /t 3 /nobreak >nul

call :wait_port %APPIUM_PORT% 90
if errorlevel 1 (
  echo [ERROR] Appium not ready on port %APPIUM_PORT%
  set "ROBOT_RC=4"
  goto :finally
)
echo [OK] Appium is ready.

echo [INFO] ===== RUN ROBOT =====
set "ARGFILE=%OUTDIR%\robot_args.txt"
if not exist "%ARGFILE%" (
  echo [ERROR] robot_args.txt not found: %ARGFILE%
  set "ROBOT_RC=5"
  goto :finally
)

"%PY_EXE%" -m robot -A "%ARGFILE%"
set "ROBOT_RC=%ERRORLEVEL%"

:finally
echo [INFO] ===== STOP APPIUM =====
call :kill_port %APPIUM_PORT%

echo [INFO] ===== END jenkins_verify.bat ROBOT_RC=%ROBOT_RC% =====
popd
exit /b %ROBOT_RC%

:kill_port
set "PORT=%~1"
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /r /c:":%PORT% " 2^>nul') do (
  taskkill /F /PID %%p >nul 2>&1
)
exit /b 0

:wait_port
set "PORT=%~1"
set "SECONDS=%~2"
for /l %%i in (1,1,%SECONDS%) do (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "try{ $c = New-Object Net.Sockets.TcpClient('127.0.0.1',%PORT%); $c.Close(); exit 0 } catch { exit 1 }" >nul 2>&1
  if not errorlevel 1 exit /b 0
  timeout /t 1 /nobreak >nul
)
exit /b 1
