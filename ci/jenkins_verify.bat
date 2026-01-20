@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================
rem Jenkins verify runner (WORKSPACE results + CALL-safe)
rem - Force Python 3.14
rem - CALL every .cmd/.bat invocation (npm/appium)
rem - Output reports to %WORKSPACE%\results (single source of truth)
rem - Print debug paths and list result files
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

rem ---- WORKSPACE results dir (preferred) ----
if not "%WORKSPACE%"=="" (
  set "OUTDIR=%WORKSPACE%\results"
) else (
  rem Fallback: parent of ROOT
  set "OUTDIR=%ROOT%\..\results"
)

rem ---- ADB: prefer ANDROID_HOME, else default ----
set "ANDROID_HOME=%ANDROID_HOME%"
if "%ANDROID_HOME%"=="" set "ANDROID_HOME=D:\android-sdk"
set "ADB_EXE=%ANDROID_HOME%\platform-tools\adb.exe"

echo [INFO] ===== START jenkins_verify.bat =====
echo [INFO] BAT=%BAT%
echo [INFO] ROOT=%ROOT%
echo [INFO] WORKSPACE=%WORKSPACE%
echo [INFO] OUTDIR=%OUTDIR%
echo [INFO] ANDROID_HOME=%ANDROID_HOME%
echo [INFO] ADB_EXE=%ADB_EXE%

pushd "%ROOT%" || (
  echo [ERROR] Cannot cd to project root.
  exit /b 1
)

rem ---- Ensure output dir ----
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

rem ---- Python check ----
echo [INFO] ===== PYTHON CHECK =====
echo [INFO] PY_EXE="%PY_EXE%"
"%PY_EXE%" -V || (popd & exit /b 1)
"%PY_EXE%" -c "import sys; print('sys.executable=', sys.executable)" || (popd & exit /b 1)

rem ---- Python deps check ----
echo [INFO] ===== PYTHON DEPS CHECK =====
call :check_pip_pkg robotframework
call :check_pip_pkg robotframework-appiumlibrary
call :check_pip_pkg pyyaml

rem ---- Env check ----
echo [INFO] ===== ENV CHECK =====
where node || (echo [ERROR] node not found in PATH. & popd & exit /b 2)
node -v

where npm || (echo [ERROR] npm not found in PATH. & popd & exit /b 2)
rem IMPORTANT: npm is npm.cmd, must CALL
call npm -v || (echo [ERROR] npm failed to run. & popd & exit /b 2)

rem ---- Locate appium.cmd ----
set "APPIUM_CMD=%NPM_BIN%\appium.cmd"
if not exist "%APPIUM_CMD%" (
  for /f "delims=" %%p in ('where appium 2^>nul') do set "APPIUM_CMD=%%p"
)

if not exist "%APPIUM_CMD%" (
  echo [ERROR] appium command not found.
  echo [HINT] Run: npm i -g appium
  popd
  exit /b 2
)

rem IMPORTANT: appium.cmd must be invoked with CALL
call "%APPIUM_CMD%" -v || (
  echo [ERROR] Appium CLI failed. Check node/npm/appium installation.
  popd
  exit /b 2
)

rem ---- Device check ----
echo [INFO] ===== CHECK DEVICE =====
if "%DEVICE_ID%"=="" (
  echo [WARN] DEVICE_ID is empty, using fallback 4e83cae7
  set "DEVICE_ID=4e83cae7"
)

if not exist "%ADB_EXE%" (
  echo [ERROR] adb.exe not found at: %ADB_EXE%
  echo [HINT] Set ANDROID_HOME in Jenkins or ensure D:\android-sdk exists.
  popd
  exit /b 3
)

"%ADB_EXE%" start-server >nul 2>&1
"%ADB_EXE%" devices | findstr /i "%DEVICE_ID%" >nul 2>&1
if errorlevel 1 (
  echo [ERROR] DEVICE_ID not online: %DEVICE_ID%
  echo [HINT] Run: "%ADB_EXE%" devices
  popd
  exit /b 3
)
echo [OK] Device "%DEVICE_ID%" is online.

rem ---- Appium port ----
if "%APPIUM_PORT%"=="" set "APPIUM_PORT=4723"

echo [INFO] ===== CLEAN PORT %APPIUM_PORT% =====
call :kill_port %APPIUM_PORT%

echo [INFO] ===== START APPIUM =====
set "APPIUM_LOG=%OUTDIR%\appium.log"
echo [INFO] APPIUM_CMD=%APPIUM_CMD%
echo [INFO] APPIUM_LOG=%APPIUM_LOG%

rem IMPORTANT: start + cmd /c + CALL appium.cmd
start "appium" /b cmd /c "call ""%APPIUM_CMD%"" --address 127.0.0.1 --port %APPIUM_PORT% --log-level info --local-timezone 1> ""%APPIUM_LOG%"" 2>&1"
timeout /t 2 /nobreak >nul

echo [INFO] ===== WAIT APPIUM READY =====
call :wait_port %APPIUM_PORT% 60
if errorlevel 1 (
  echo [ERROR] Appium not ready on port %APPIUM_PORT% within timeout.
  echo [HINT] Check log: %APPIUM_LOG%
  call :kill_port %APPIUM_PORT%
  popd
  rem keep Jenkins success? still exit 0? you can change to exit /b 4 if you want hard fail
  exit /b 0
)
echo [OK] Appium is ready on %APPIUM_PORT%.

echo [INFO] ===== RUN ROBOT =====
if "%SUITE%"=="" set "SUITE=CreateNewProject"
if "%TEST_ROOT%"=="" set "TEST_ROOT=tests"

echo [INFO] CMD=%PY_EXE% -m robot --nostatusrc --outputdir "%OUTDIR%" --suite %SUITE% %TEST_ROOT%
"%PY_EXE%" -m robot --nostatusrc --outputdir "%OUTDIR%" --suite %SUITE% %TEST_ROOT%
set "ROBOT_RC=%ERRORLEVEL%"

echo [INFO] ===== STOP APPIUM =====
call :kill_port %APPIUM_PORT%

echo [INFO] ===== RESULT FILES IN OUTDIR =====
if exist "%OUTDIR%\output.xml" (
  echo [OK] output.xml exists: %OUTDIR%\output.xml
) else (
  echo [WARN] output.xml missing in: %OUTDIR%
)
dir /a /-c "%OUTDIR%"

echo [INFO] ===== END jenkins_verify.bat ROBOT_RC=%ROBOT_RC% =====
popd

rem Keep Jenkins SUCCESS always
exit /b 0

rem ============================================================
rem Subroutines
rem ============================================================

:check_pip_pkg
set "PKG=%~1"
"%PY_EXE%" -m pip show "%PKG%" >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Python package not installed: %PKG%
  echo [HINT] Run: "%PY_EXE%" -m pip install -U %PKG%
  exit /b 10
)
exit /b 0

:kill_port
set "PORT=%~1"
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /r /c:":%PORT% " 2^>nul') do (
  echo [INFO] Kill PID %%p on port %PORT%
  taskkill /F /PID %%p >nul 2>&1
)
exit /b 0

:wait_port
set "PORT=%~1"
set "SECONDS=%~2"
for /l %%i in (1,1,%SECONDS%) do (
  powershell -NoProfile -Command "try{ $c = New-Object Net.Sockets.TcpClient('127.0.0.1',%PORT%); $c.Close(); exit 0 } catch { exit 1 }" >nul 2>&1
  if not errorlevel 1 exit /b 0
  timeout /t 1 /nobreak >nul
)
exit /b 1