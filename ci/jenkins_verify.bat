@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
set "PYTHONUTF8=1"
set "PYTHONIOENCODING=utf-8"

rem ============================================================
rem Jenkins verify runner (FINAL STABLE VERSION)
rem - Encryption-safe: DO NOT parse "adb devices" table
rem - DO NOT use PowerShell redirection to nul (can break on encrypted env)
rem - Start/Stop Appium safely
rem - Robot returns real exit code (NO --nostatusrc)
rem - Output to %WORKSPACE%\results
rem ============================================================

rem ---- Force Python 3.14 ----
set "PY_HOME=C:\Python314"
set "PY_EXE=%PY_HOME%\python.exe"
set "PY_SCRIPTS=%PY_HOME%\Scripts"
set "PATH=%PY_HOME%;%PY_SCRIPTS%;%PATH%"

rem ---- Locate NodeJS and npm bin ----
set "NODE_EXE="
if defined NODE_HOME if exist "%NODE_HOME%\node.exe" set "NODE_EXE=%NODE_HOME%\node.exe"
if not defined NODE_EXE if defined NVM_SYMLINK if exist "%NVM_SYMLINK%\node.exe" set "NODE_EXE=%NVM_SYMLINK%\node.exe"
if not defined NODE_EXE if defined NVM_HOME (
  for /f "delims=" %%p in ('where /r "%NVM_HOME%" node.exe 2^>nul') do (
    if not defined NODE_EXE set "NODE_EXE=%%p"
  )
)
for /f "delims=" %%p in ('where node.exe 2^>nul') do (
  if not defined NODE_EXE set "NODE_EXE=%%p"
)
if not defined NODE_EXE if exist "C:\nvm4w\nodejs\node.exe" set "NODE_EXE=C:\nvm4w\nodejs\node.exe"
if not defined NODE_EXE if exist "D:\dddddddddddddddddd\nodejs\node.exe" set "NODE_EXE=D:\dddddddddddddddddd\nodejs\node.exe"
if not defined NODE_EXE if exist "C:\Program Files\nodejs\node.exe" set "NODE_EXE=C:\Program Files\nodejs\node.exe"
if defined NODE_EXE for %%p in ("%NODE_EXE%") do set "NODE_HOME=%%~dpp"
set "NPM_BIN=%APPDATA%\npm"
set "PATH=%NODE_HOME%;%NPM_BIN%;%PATH%"

rem ---- Project root (autotest) ----
set "ROOT=%~dp0.."
set "BAT=%~f0"

rem ---- WORKSPACE results dir (preferred) ----
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

pushd "%ROOT%" || (echo [ERROR] Cannot cd to project root. & exit /b 1)

if not exist "%OUTDIR%" mkdir "%OUTDIR%"

rem ---- Python check ----
echo [INFO] ===== PYTHON CHECK =====
"%PY_EXE%" -V || (popd & exit /b 1)

rem ---- Python deps check ----
echo [INFO] ===== PYTHON DEPS CHECK =====
call :check_pip_pkg robotframework || (set "ROBOT_RC=10" & goto :finally)
call :check_pip_pkg robotframework-appiumlibrary || (set "ROBOT_RC=10" & goto :finally)
call :check_pip_pkg pyyaml || (set "ROBOT_RC=10" & goto :finally)

rem ---- Env check ----
echo [INFO] ===== ENV CHECK =====
if not defined NODE_EXE (
  echo [ERROR] node.exe not found in PATH or known installation paths.
  set "ROBOT_RC=2"
  goto :finally
)
echo [INFO] NODE_EXE=%NODE_EXE%
"%NODE_EXE%" -v
where npm >nul 2>&1 || (echo [ERROR] npm not found in PATH. & set "ROBOT_RC=2" & goto :finally)
call npm -v >nul 2>&1 || (echo [ERROR] npm failed to run. & set "ROBOT_RC=2" & goto :finally)

rem ---- Use a pinned, workspace-local Appium core ----
rem The Jenkins global npm tree may drift or become internally incompatible.
set "APPIUM_VERSION=2.19.0"
set "UIAUTOMATOR2_VERSION=4.1.5"
if not "%WORKSPACE%"=="" (
  set "APPIUM_TOOLS_DIR=%WORKSPACE%\.ci-tools\appium-%APPIUM_VERSION%"
) else (
  set "APPIUM_TOOLS_DIR=%ROOT%\.ci-tools\appium-%APPIUM_VERSION%"
)
set "APPIUM_CMD=%APPIUM_TOOLS_DIR%\node_modules\.bin\appium.cmd"
set "APPIUM_HOME=%APPIUM_TOOLS_DIR%\home-uiautomator2-%UIAUTOMATOR2_VERSION%"
if not exist "%APPIUM_CMD%" (
  echo [INFO] Installing Appium %APPIUM_VERSION% into %APPIUM_TOOLS_DIR%
  call npm install --prefix "%APPIUM_TOOLS_DIR%" --no-audit --no-fund --omit=dev "appium@%APPIUM_VERSION%"
  if errorlevel 1 (
    echo [ERROR] Failed to install Appium %APPIUM_VERSION%.
    set "ROBOT_RC=2"
    goto :finally
  )
)
if not exist "%APPIUM_CMD%" (
  echo [ERROR] Pinned Appium command not found after installation: %APPIUM_CMD%
  set "ROBOT_RC=2"
  goto :finally
)
if not exist "%APPIUM_HOME%\node_modules\appium-uiautomator2-driver\package.json" (
  echo [INFO] Installing UiAutomator2 %UIAUTOMATOR2_VERSION% into %APPIUM_HOME%
  call "%APPIUM_CMD%" driver install "uiautomator2@%UIAUTOMATOR2_VERSION%"
  if errorlevel 1 (
    echo [ERROR] Failed to install UiAutomator2 %UIAUTOMATOR2_VERSION%.
    set "ROBOT_RC=2"
    goto :finally
  )
)

rem ---- Device check (encryption-safe) ----
echo [INFO] ===== CHECK DEVICE (encryption-safe) =====
if not exist "%ADB_EXE%" (
  echo [ERROR] adb.exe not found: %ADB_EXE%
  set "ROBOT_RC=3"
  goto :finally
)

rem start adb (swallow output using cmd.exe)
set "SAVED_JENKINS_SERVER_COOKIE=%JENKINS_SERVER_COOKIE%"
set "SAVED_JENKINS_NODE_COOKIE=%JENKINS_NODE_COOKIE%"
set "JENKINS_SERVER_COOKIE=surveymaster-adb-daemon"
set "JENKINS_NODE_COOKIE=surveymaster-adb-daemon"
pushd "%ANDROID_HOME%\platform-tools"
cmd /c ""%ADB_EXE%" kill-server 1>nul 2>nul"
cmd /c ""%ADB_EXE%" start-server 1>nul 2>nul"
popd
set "JENKINS_SERVER_COOKIE=%SAVED_JENKINS_SERVER_COOKIE%"
set "JENKINS_NODE_COOKIE=%SAVED_JENKINS_NODE_COOKIE%"
powershell -NoProfile -Command "Start-Sleep -Seconds 1"

rem wait-for-device (avoid parsing text)
"%ADB_EXE%" -s "%DEVICE_ID%" wait-for-device

rem get-state -> file -> read one line
"%ADB_EXE%" -s "%DEVICE_ID%" get-state > "%TEMP%\adb_state_%DEVICE_ID%.txt"
set "STATE="
set /p STATE=<"%TEMP%\adb_state_%DEVICE_ID%.txt"
if /i not "%STATE%"=="device" (
  echo [ERROR] Device %DEVICE_ID% not ready, state=%STATE%
  set "ROBOT_RC=3"
  goto :finally
)
echo [OK] Device "%DEVICE_ID%" is online (device).

rem Remove stale Appium Settings so the pinned UiAutomator2 driver installs its matching helper.
echo [INFO] ===== RESET APPIUM SETTINGS HELPER =====
"%ADB_EXE%" -s "%DEVICE_ID%" uninstall io.appium.settings >nul 2>&1

rem ---- Appium start ----
echo [INFO] ===== CLEAN PORT %APPIUM_PORT% =====
call :kill_port %APPIUM_PORT%

echo [INFO] ===== START APPIUM =====
set "APPIUM_LOG=%OUTDIR%\appium.log"
echo [INFO] APPIUM_CMD=%APPIUM_CMD%
echo [INFO] APPIUM_LOG=%APPIUM_LOG%
echo [INFO] ===== APPIUM VERSION =====
call "%APPIUM_CMD%" --version
if errorlevel 1 (
  echo [ERROR] Appium command failed before startup.
  set "ROBOT_RC=4"
  goto :finally
)

start "appium" /b cmd /c "call ""%APPIUM_CMD%"" --address 127.0.0.1 --port %APPIUM_PORT% --log-level info --local-timezone 1> ""%APPIUM_LOG%"" 2>&1"
powershell -NoProfile -Command "Start-Sleep -Seconds 2"

echo [INFO] ===== WAIT APPIUM READY =====
call :wait_port %APPIUM_PORT% 90
if errorlevel 1 (
  echo [ERROR] Appium not ready on port %APPIUM_PORT% within timeout.
  echo [HINT] Check log: %APPIUM_LOG%
  if exist "%APPIUM_LOG%" (
    echo [INFO] ===== APPIUM LOG BEGIN =====
    type "%APPIUM_LOG%"
    echo [INFO] ===== APPIUM LOG END =====
  )
  set "ROBOT_RC=4"
  goto :finally
)
echo [OK] Appium is ready on %APPIUM_PORT%.

echo [DEBUG] ===== NETSTAT %APPIUM_PORT% =====
netstat -ano | findstr ":%APPIUM_PORT%"

echo [DEBUG] ===== STATUS CHECK =====
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "try{(Invoke-RestMethod -Uri 'http://127.0.0.1:%APPIUM_PORT%/status' -TimeoutSec 2) | ConvertTo-Json -Compress}catch{Write-Host 'STATUS_FAIL'}"

rem ---- Run Robot ----
echo [INFO] ===== RUN ROBOT =====
set "ARGFILE=%OUTDIR%\robot_args.txt"

if not exist "%ARGFILE%" (
  echo [ERROR] Robot argument file not found: %ARGFILE%
  echo [HINT] The Jenkins pipeline must generate it from TEST_ROBOTS.
  set "ROBOT_RC=5"
  goto :finally
)

echo [INFO] Using argument file: %ARGFILE%
echo [INFO] ===== ARGFILE CONTENT BEGIN =====
type "%ARGFILE%"
echo [INFO] ===== ARGFILE CONTENT END =====

"%PY_EXE%" -m robot -A "%ARGFILE%"
set "ROBOT_RC=%ERRORLEVEL%"

:finally
echo [INFO] ===== STOP APPIUM =====
call :stop_appium %APPIUM_PORT%

echo [INFO] ===== STOP ADB =====
set "SAVED_JENKINS_SERVER_COOKIE=%JENKINS_SERVER_COOKIE%"
set "SAVED_JENKINS_NODE_COOKIE=%JENKINS_NODE_COOKIE%"
set "JENKINS_SERVER_COOKIE=surveymaster-adb-daemon"
set "JENKINS_NODE_COOKIE=surveymaster-adb-daemon"
pushd "%ANDROID_HOME%\platform-tools"
cmd /c ""%ADB_EXE%" kill-server 1>nul 2>nul"
popd
set "JENKINS_SERVER_COOKIE=%SAVED_JENKINS_SERVER_COOKIE%"
set "JENKINS_NODE_COOKIE=%SAVED_JENKINS_NODE_COOKIE%"

echo [INFO] ===== RESULT FILES IN OUTDIR =====
if exist "%OUTDIR%\output.xml" (
  echo [OK] output.xml exists: %OUTDIR%\output.xml
) else (
  echo [WARN] output.xml missing in: %OUTDIR%
)
dir /a /-c "%OUTDIR%"

echo [INFO] ===== END jenkins_verify.bat ROBOT_RC=%ROBOT_RC% =====
popd
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
  exit /b 1
)
exit /b 0

:kill_port
set "PORT=%~1"
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /r /c:":%PORT% " 2^>nul') do (
  taskkill /F /PID %%p >nul 2>&1
)
exit /b 0

:wait_port
set "PORT=%~1"
set "SECONDS=%~2"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$deadline = [DateTime]::UtcNow.AddSeconds(%SECONDS%);" ^
  "do {" ^
  "  try {" ^
  "    $c = New-Object Net.Sockets.TcpClient;" ^
  "    $ar = $c.BeginConnect('127.0.0.1', %PORT%, $null, $null);" ^
  "    if ($ar.AsyncWaitHandle.WaitOne(500) -and $c.Connected) { $c.EndConnect($ar); $c.Close(); exit 0 };" ^
  "    $c.Close();" ^
  "  } catch {};" ^
  "  Start-Sleep -Milliseconds 500;" ^
  "} while ([DateTime]::UtcNow -lt $deadline);" ^
  "exit 1" >nul 2>&1
exit /b %ERRORLEVEL%

:stop_appium
set "PORT=%~1"
call :kill_port %PORT%

rem Kill only node.exe processes that are running appium
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ps = Get-CimInstance Win32_Process -Filter ""Name='node.exe'"" | Where-Object { $_.CommandLine -match 'appium' };" ^
  "foreach($p in $ps){ try{ Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue }catch{} }" >nul 2>&1
exit /b 0
