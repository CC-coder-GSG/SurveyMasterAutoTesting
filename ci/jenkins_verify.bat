@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================
rem Jenkins verify runner (CALL-safe)
rem - Force Python 3.14
rem - Force Node path
rem - CALL every .cmd/.bat invocation (npm/appium/etc.)
rem - Use explicit adb.exe if possible
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

rem ---- ADB: prefer env ADB, else default path ----
set "ADB_EXE="
if not "%ADB%"=="" set "ADB_EXE=%ADB%"
if "%ADB_EXE%"=="" (
  if exist "D:\android-sdk\platform-tools\adb.exe" set "ADB_EXE=D:\android-sdk\platform-tools\adb.exe"
)

rem ---- Project root (autotest) ----
set "ROOT=%~dp0.."
pushd "%ROOT%" || (
  echo [ERROR] Cannot cd to project root.
  exit /b 1
)

echo [INFO] ===== START jenkins_verify.bat =====
echo [INFO] BAT=%~f0
echo [INFO] ROOT=%CD%

echo [INFO] ===== PYTHON CHECK =====
echo [INFO] PY_EXE="%PY_EXE%"
"%PY_EXE%" -V || exit /b 1
"%PY_EXE%" -c "import sys; print('sys.executable=', sys.executable)" || exit /b 1

echo [INFO] ===== PYTHON DEPS CHECK =====
call :check_pip_pkg robotframework
call :check_pip_pkg robotframework-appiumlibrary
call :check_pip_pkg pyyaml

echo [INFO] ===== ENV CHECK =====
where node || (echo [ERROR] node not found in PATH. & exit /b 2)
node -v

where npm || (echo [ERROR] npm not found in PATH. & exit /b 2)
rem IMPORTANT: npm is npm.cmd, always CALL it
call npm -v || (echo [ERROR] npm failed to run. & exit /b 2)

rem ---- Locate appium.cmd (also a .cmd, must CALL) ----
set "APPIUM_CMD=%NPM_BIN%\appium.cmd"
if not exist "%APPIUM_CMD%" (
  for /f "delims=" %%p in ('where appium 2^>nul') do set "APPIUM_CMD=%%p"
)

if not exist "%APPIUM_CMD%" (
  echo [ERROR] appium command not found.
  echo [HINT] Run: npm i -g appium
  exit /b 2
)

rem IMPORTANT: appium.cmd must be invoked with CALL
call "%APPIUM_CMD%" -v
if errorlevel 1 (
  echo [ERROR] Appium CLI failed. Check node/npm/appium installation.
  exit /b 2
)

echo [INFO] ===== CHECK DEVICE =====
if "%DEVICE_ID%"=="" (
  echo [ERROR] DEVICE_ID is empty. Please set DEVICE_ID in Jenkins parameters.
  exit /b 3
)

if "%ADB_EXE%"=="" (
  echo [ERROR] adb.exe not found. Set env ADB to full path.
  echo [HINT] Example: set ADB=D:\android-sdk\platform-tools\adb.exe
  exit /b 3
)

echo [INFO] ADB_EXE="%ADB_EXE%"
"%ADB_EXE%" start-server >nul 2>&1

"%ADB_EXE%" devices | findstr /i "%DEVICE_ID%" >nul 2>&1
if errorlevel 1 (
  echo [ERROR] DEVICE_ID not online: %DEVICE_ID%
  echo [HINT] Run: "%ADB_EXE%" devices
  exit /b 3
)
echo [OK] Device "%DEVICE_ID%" is online.

rem ---- Appium port ----
if "%APPIUM_PORT%"=="" set "APPIUM_PORT=4723"

echo [INFO] ===== CLEAN PORT %APPIUM_PORT% =====
call :kill_port %APPIUM_PORT%

echo [INFO] ===== START APPIUM =====
if not exist "%ROOT%\results" mkdir "%ROOT%\results"
set "APPIUM_LOG=%ROOT%\results\appium.log"

echo [INFO] Launch Appium on 127.0.0.1:%APPIUM_PORT%
echo [INFO] APPIUM_CMD="%APPIUM_CMD%"
echo [INFO] APPIUM_LOG="%APPIUM_LOG%"

rem IMPORTANT: start -> cmd /c -> CALL appium.cmd (keep CALL even in subshell)
start "appium" /b cmd /c "call ""%APPIUM_CMD%"" --address 127.0.0.1 --port %APPIUM_PORT% --log-level info --local-timezone 1> ""%APPIUM_LOG%"" 2>&1"
timeout /t 2 /nobreak >nul

echo [INFO] ===== WAIT APPIUM READY =====
call :wait_port %APPIUM_PORT% 60
if errorlevel 1 (
  echo [ERROR] Appium not ready on port %APPIUM_PORT% within timeout.
  echo [HINT] Check log: %APPIUM_LOG%
  exit /b 4
)
echo [OK] Appium is ready on %APPIUM_PORT%.

echo [INFO] ===== RUN ROBOT =====
set "OUTDIR=%ROOT%\results"
if "%SUITE%"=="" set "SUITE=CreateNewProject"
if "%TEST_ROOT%"=="" set "TEST_ROOT=tests"

echo [INFO] CMD: "%PY_EXE%" -m robot --outputdir "%OUTDIR%" --suite %SUITE% %TEST_ROOT%
"%PY_EXE%" -m robot --outputdir "%OUTDIR%" --suite %SUITE% %TEST_ROOT%
set "RC=%ERRORLEVEL%"

echo [INFO] ===== STOP APPIUM =====
call :kill_port %APPIUM_PORT%

echo [INFO] ===== END jenkins_verify.bat RC=%RC% =====
popd
exit /b %RC%

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