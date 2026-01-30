@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================
rem Jenkins verify runner (WORKSPACE results + CALL-safe)
rem - Force Python 3.14
rem - CALL every .cmd/.bat invocation (npm/appium)
rem - Output reports to %WORKSPACE%\results
rem - Return non-zero on failures (Jenkinsfile catchError => UNSTABLE)
rem - Robust device state check (handles TAB/spaces)
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
call :check_pip_pkg robotframework || (popd & exit /b 10)
call :check_pip_pkg robotframework-appiumlibrary || (popd & exit /b 10)
call :check_pip_pkg pyyaml || (popd & exit /b 10)

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

rem ✅ Robust parse: handles TAB/spaces in adb output
set "OK_DEVICE="
for /f "tokens=1,2" %%a in ('"%ADB_EXE%" devices ^| findstr /i "%DEVICE_ID%"') do (
  if /i "%%a"=="%DEVICE_ID%" if /i "%%b"=="device" set "OK_DEVICE=1"
)
if not defined OK_DEVICE (
  echo [ERROR] DEVICE_ID not in device state: %DEVICE_ID%
  echo [HINT] Run: "%ADB_EXE%" devices
  popd
  exit /b 3
)

rem 双保险：get-state
set "STATE="
for /f "delims=" %%s in ('"%ADB_EXE%" -s %DEVICE_ID% get-state 2^>nul') do set "STATE=%%s"
if /i not "%STATE%"=="device" (
  echo [ERROR] get-state is "%STATE%", not ready.
  popd
  exit /b 3
)

echo [OK] Device "%DEVICE_ID%" is online (device).

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
  exit /b 4
)
echo [OK] Appium is ready on %APPIUM_PORT%.

echo [INFO] ===== RUN ROBOT =====
set "ARGFILE=%OUTDIR%\robot_args.txt"

if exist "%ARGFILE%" (
  echo [INFO] Using argument file: %ARGFILE%
  "%PY_EXE%" -m robot -A "%ARGFILE%"
) else (
  if "%SUITE%"=="" set "SUITE=LuoWangConnectFail"
  if "%TEST_ROOT%"=="" set "TEST_ROOT=tests"
  echo [INFO] CMD=%PY_EXE% -m robot --nostatusrc --outputdir "%OUTDIR%" --suite %SUITE% %TEST_ROOT%
  "%PY_EXE%" -m robot --nostatusrc --outputdir "%OUTDIR%" --suite %SUITE% %TEST_ROOT%
)
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

rem ✅ Return real exit code (Jenkinsfile catchError => UNSTABLE)
exit /b %ROBOT_RC%

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
