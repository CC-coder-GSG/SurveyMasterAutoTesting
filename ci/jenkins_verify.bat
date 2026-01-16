@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================
rem Jenkins-friendly runner:
rem - Force a specific Python (avoid mixed Python versions)
rem - No non-ASCII comments/echo
rem - No parentheses in echo text (avoid CMD parse issues in Jenkins wrapper)
rem ============================================================

rem ---- Force Python 3.14 ----
set "PY_HOME=C:\Python314"
set "PY_EXE=%PY_HOME%\python.exe"
set "PY_SCRIPTS=%PY_HOME%\Scripts"
set "PATH=%PY_HOME%;%PY_SCRIPTS%;%PATH%"

rem ---- Project root (autotest) ----
set "ROOT=%~dp0.."
pushd "%ROOT%" || (
  echo [ERROR] Cannot cd to project root.
  exit /b 1
)

echo [INFO] ===== PYTHON CHECK =====
echo [INFO] PY_EXE="%PY_EXE%"
"%PY_EXE%" -V || exit /b 1
"%PY_EXE%" -c "import sys; print('sys.executable=', sys.executable)" || exit /b 1

echo [INFO] ===== PYTHON DEPS CHECK =====
call :check_pip_pkg robotframework
call :check_pip_pkg robotframework-appiumlibrary
call :check_pip_pkg pyyaml

echo [INFO] ===== ENV CHECK =====
where node >nul 2>&1 || (
  echo [ERROR] node not found in PATH.
  exit /b 2
)
node -v

where npm >nul 2>&1 || (
  echo [ERROR] npm not found in PATH.
  exit /b 2
)
for /f "delims=" %%v in ('npm -v') do echo npm %%v

rem Try to locate appium.cmd
set "NPM_BIN=%APPDATA%\npm"
set "APPIUM_CMD=%NPM_BIN%\appium.cmd"
if not exist "%APPIUM_CMD%" (
  for /f "delims=" %%p in ('where appium 2^>nul') do set "APPIUM_CMD=%%p"
)

if not exist "%APPIUM_CMD%" (
  echo [ERROR] appium command not found.
  echo [HINT] Run: npm i -g appium
  exit /b 2
)

call "%APPIUM_CMD%" -v
if errorlevel 1 (
  echo [ERROR] Appium CLI failed. Check node/npm/appium installation.
  exit /b 2
)

echo [INFO] ===== CHECK DEVICE =====
if "%DEVICE_ID%"=="" set "DEVICE_ID=4e83cae7"
adb devices | findstr /i "%DEVICE_ID%" >nul 2>&1
if errorlevel 1 (
  echo [ERROR] DEVICE_ID not online: %DEVICE_ID%
  echo [HINT] Run: adb devices
  exit /b 3
)
echo [OK] Device "%DEVICE_ID%" is online.

set "APPIUM_PORT=4723"

echo [INFO] ===== CLEAN PORT %APPIUM_PORT% =====
call :kill_port %APPIUM_PORT%

echo [INFO] ===== START APPIUM =====
if not exist "%ROOT%\results" mkdir "%ROOT%\results"
set "APPIUM_LOG=%ROOT%\results\appium.log"

echo [INFO] Launch: "%APPIUM_CMD%" --address 127.0.0.1 --port %APPIUM_PORT%
start "appium" /b cmd /c "\"%APPIUM_CMD%\" --address 127.0.0.1 --port %APPIUM_PORT% --log-level info --local-timezone > \"%APPIUM_LOG%\" 2>&1"
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

echo [INFO] CMD: "%PY_EXE%" -m robot --outputdir "%OUTDIR%" --suite %SUITE% tests
"%PY_EXE%" -m robot --outputdir "%OUTDIR%" --suite %SUITE% tests
set "RC=%ERRORLEVEL%"

echo [INFO] ===== STOP APPIUM =====
call :kill_port %APPIUM_PORT%

popd
exit /b %RC%

:check_pip_pkg
set "PKG=%~1"
"%PY_EXE%" -m pip show "%PKG%" >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Python package not installed: %PKG%
  echo [HINT] Run: "%PY_EXE%" -m pip install %PKG%
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