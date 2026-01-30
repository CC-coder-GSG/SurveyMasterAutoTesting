@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================
rem Jenkins verify runner (WORKSPACE results + CALL-safe)
rem - Force Python 3.14
rem - CALL every .cmd/.bat invocation (npm/appium)
rem - Output reports to %WORKSPACE%\results
rem - Return non-zero on failures (Jenkinsfile catchError => UNSTABLE)
rem - Robust device state check (handles TAB/spaces)
rem - Robust Appium stop (kill appium/node, not just port)
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

rem ---- Defaults ----
if "%APPIUM_PORT%"=="" set "APPIUM_PORT=4723"
set "ROBOT_RC=0"

echo [INFO] ===== START jenkins_verify.bat =====
echo [INFO] BAT=%BAT%
echo [INFO] ROOT=%ROOT%
echo [INFO] WORKSPACE=%WORKSPACE%
echo [INFO] OUTDIR=%OUTDIR%
echo [INFO] ANDROID_HOME=%ANDROID_HOME%
echo [INFO] ADB_EXE=%ADB_EXE%
echo [INFO] APPIUM_PORT=%APPIUM_PORT%

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
call :check_pip_pkg robotframework || (set "ROBOT_RC=10" & goto :finally)
call :check_pip_pkg robotframework-appiumlibrary || (set "ROBOT_RC=10" & goto :finally)
call :check_pip_pkg pyyaml || (set "ROBOT_RC=10" & goto :finally)

rem ---- Env check ----
echo [INFO] ===== ENV CHECK =====
where node || (echo [ERROR] node not found in PATH. & set "ROBOT_RC=2" & goto :finally)
node -v

where npm || (echo [ERROR] npm not found in PATH. & set "ROBOT_RC=2" & goto :finally)
call npm -v || (echo [ERROR] npm failed to run. & set "ROBOT_RC=2" & goto :finally)

rem ---- Locate appium.cmd ----
set "APPIUM_CMD=%NPM_BIN%\appium.cmd"
if not exist "%APPIUM_CMD%" (
  for /f "delims=" %%p in ('where appium 2^>nul') do set "APPIUM_CMD=%%p"
)

if not exist "%APPIUM_CMD%" (
  echo [ERROR] appium command not found.
  echo [HINT] Run: npm i -g appium
  set "ROBOT_RC=2"
  goto :finally
)

call "%APPIUM_CMD%" -v || (
  echo [ERROR] Appium CLI failed. Check node/npm/appium installation.
  set "ROBOT_RC=2"
  goto :finally
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
  set "ROBOT_RC=3"
  goto :finally
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
  set "ROBOT_RC=3"
  goto :finally
)

rem 双保险：get-state（加 timeout，防止偶发 adb 卡住）
set "STATE="
for /f "delims=" %%s in ('powershell -NoProfile -Command "$p=Start-Process -FilePath ''%ADB_EXE%'' -ArgumentList ''-s %DEVICE_ID% get-state'' -NoNewWindow -PassThru -RedirectStandardOutput (Join-Path $env:TEMP ''adb_state.txt''); if($p.WaitForExit(15)){ Get-Content (Join-Path $env:TEMP ''adb_state.txt'') } else { $p.Kill(); exit 124 }" 2^>nul') do set "STATE=%%s"
if "%STATE%"=="124" (
  echo [ERROR] adb get-state timeout.
  set "ROBOT_RC=3"
  goto :finally
)
if /i not "%STATE%"=="device" (
  echo [ERROR] get-state is "%STATE%", not ready.
  set "ROBOT_RC=3"
  goto :finally
)

echo [OK] Device "%DEVICE_ID%" is online (device).

rem ---- Appium start ----
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
call :wait_port %APPIUM_PORT% 90
if errorlevel 1 (
  echo [ERROR] Appium not ready on port %APPIUM_PORT% within timeout.
  echo [HINT] Check log: %APPIUM_LOG%
  set "ROBOT_RC=4"
  goto :finally
)
echo [OK] Appium is ready on %APPIUM_PORT%.

rem ---- Run Robot ----
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

:finally
echo [INFO] ===== STOP APPIUM =====
call :stop_appium %APPIUM_PORT%

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

:stop_appium
set "PORT=%~1"
rem 1) 先杀端口（能杀掉监听进程）
call :kill_port %PORT%

rem 2) 再补刀：杀 appium/node（避免残留导致下次启动异常）
for /f "tokens=2 delims=," %%p in ('tasklist /FI "IMAGENAME eq node.exe" /FO CSV ^| findstr /i "node.exe"') do (
  rem %%p like "1234"
  set "PID=%%~p"
  if not "!PID!"=="" (
    echo [INFO] Kill node.exe PID !PID!
    taskkill /F /PID !PID! >nul 2>&1
  )
)

exit /b 0
