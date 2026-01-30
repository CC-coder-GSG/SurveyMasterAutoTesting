@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================
rem Jenkins verify runner (FINAL)
rem - encryption-safe: DO NOT parse adb text in bat
rem - avoid long powershell -Command with ^ continuations (causes exit 255)
rem ============================================================

set "PY_HOME=C:\Python314"
set "PY_EXE=%PY_HOME%\python.exe"
set "PY_SCRIPTS=%PY_HOME%\Scripts"
set "PATH=%PY_HOME%;%PY_SCRIPTS%;%PATH%"

set "NODE_HOME=C:\Program Files\nodejs"
set "NPM_BIN=%APPDATA%\npm"
set "PATH=%NODE_HOME%;%NPM_BIN%;%PATH%"

set "ROOT=%~dp0.."
set "BAT=%~f0"

if not "%WORKSPACE%"=="" (
  set "OUTDIR=%WORKSPACE%\results"
) else (
  set "OUTDIR=%ROOT%\..\results"
)

if "%ANDROID_HOME%"=="" set "ANDROID_HOME=D:\android-sdk"
set "ADB_EXE=%ANDROID_HOME%\platform-tools\adb.exe"

if "%APPIUM_PORT%"=="" set "APPIUM_PORT=4723"
if "%DEVICE_ID%"=="" set "DEVICE_ID=4e83cae7"
set "ROBOT_RC=0"

echo [INFO] ===== START jenkins_verify.bat =====
echo [INFO] BAT=%BAT%
echo [INFO] OUTDIR=%OUTDIR%
echo [INFO] ANDROID_HOME=%ANDROID_HOME%
echo [INFO] ADB_EXE=%ADB_EXE%
echo [INFO] DEVICE_ID=%DEVICE_ID%
echo [INFO] APPIUM_PORT=%APPIUM_PORT%

pushd "%ROOT%" || (echo [ERROR] Cannot cd to project root. & exit /b 1)
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

echo [INFO] ===== PYTHON CHECK =====
"%PY_EXE%" -V || (set "ROBOT_RC=1" & goto :finally)

echo [INFO] ===== PYTHON DEPS CHECK =====
call :check_pip_pkg robotframework || (set "ROBOT_RC=10" & goto :finally)
call :check_pip_pkg robotframework-appiumlibrary || (set "ROBOT_RC=10" & goto :finally)
call :check_pip_pkg pyyaml || (set "ROBOT_RC=10" & goto :finally)

echo [INFO] ===== ENV CHECK =====
where node >nul 2>&1 || (echo [ERROR] node not found. & set "ROBOT_RC=2" & goto :finally)
node -v
where npm >nul 2>&1 || (echo [ERROR] npm not found. & set "ROBOT_RC=2" & goto :finally)
call npm -v >nul 2>&1 || (echo [ERROR] npm failed. & set "ROBOT_RC=2" & goto :finally)

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

echo [INFO] ===== CHECK DEVICE (encryption-safe) =====
if not exist "%ADB_EXE%" (
  echo [ERROR] adb.exe not found: %ADB_EXE%
  set "ROBOT_RC=3"
  goto :finally
)

rem --- write temp ps1 (avoid cmd-line quoting issues) ---
set "PS_CHECK=%TEMP%\jenkins_adb_check_%RANDOM%.ps1"
> "%PS_CHECK%" (
  echo param([string]$Adb,[string]$Id)
  echo $ErrorActionPreference = 'Stop'
  echo if([string]::IsNullOrWhiteSpace($Adb) -or -not (Test-Path $Adb)) { exit 3 }
  echo if([string]::IsNullOrWhiteSpace($Id)) { exit 3 }
  echo ^
  echo # start-server via cmd.exe to swallow stderr
  echo $cmd = 'cmd.exe'
  echo Start-Process -FilePath $cmd -ArgumentList @('/c', ('""{0}"" kill-server 1^>nul 2^>nul' -f $Adb)) -NoNewWindow -Wait ^| Out-Null
  echo Start-Process -FilePath $cmd -ArgumentList @('/c', ('""{0}"" start-server 1^>nul 2^>nul' -f $Adb)) -NoNewWindow -Wait ^| Out-Null
  echo Start-Sleep -Seconds 1
  echo ^
  echo # wait-for-device (timeout 30s)
  echo $p = Start-Process -FilePath $Adb -ArgumentList @('-s',$Id,'wait-for-device') -NoNewWindow -PassThru
  echo if(-not $p.WaitForExit(30000)) { try{$p.Kill()}catch{}; exit 124 }
  echo ^
  echo # get-state
  echo $p2 = Start-Process -FilePath $Adb -ArgumentList @('-s',$Id,'get-state') -NoNewWindow -PassThru -RedirectStandardOutput (Join-Path $env:TEMP ('adb_state_'+$Id+'.txt'))
  echo if(-not $p2.WaitForExit(15000)) { try{$p2.Kill()}catch{}; exit 124 }
  echo $s = (Get-Content (Join-Path $env:TEMP ('adb_state_'+$Id+'.txt')) -ErrorAction SilentlyContinue ^| Select-Object -First 1)
  echo $s = ($s + '').Trim()
  echo if($s -ieq 'device') { exit 0 } else { exit 3 }
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_CHECK%" -Adb "%ADB_EXE%" -Id "%DEVICE_ID%"
set "PS_RC=%ERRORLEVEL%"
del /f /q "%PS_CHECK%" >nul 2>&1

if "%PS_RC%"=="124" (
  echo [ERROR] adb wait/get-state timeout: %DEVICE_ID%
  set "ROBOT_RC=3"
  goto :finally
)
if not "%PS_RC%"=="0" (
  echo [ERROR] device not ready (offline/unauthorized/not found): %DEVICE_ID%
  set "ROBOT_RC=3"
  goto :finally
)

echo [OK] Device "%DEVICE_ID%" is online (device).

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
if exist "%ARGFILE%" (
  "%PY_EXE%" -m robot -A "%ARGFILE%"
) else (
  if "%SUITE%"=="" set "SUITE=LuoWangConnectFail"
  if "%TEST_ROOT%"=="" set "TEST_ROOT=tests"
  "%PY_EXE%" -m robot --nostatusrc --outputdir "%OUTDIR%" --suite %SUITE% %TEST_ROOT%
)
set "ROBOT_RC=%ERRORLEVEL%"

:finally
echo [INFO] ===== STOP APPIUM =====
call :stop_appium %APPIUM_PORT%

echo [INFO] ===== END jenkins_verify.bat ROBOT_RC=%ROBOT_RC% =====
popd
exit /b %ROBOT_RC%

:check_pip_pkg
set "PKG=%~1"
"%PY_EXE%" -m pip show "%PKG%" >nul 2>&1
if errorlevel 1 exit /b 1
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
for /l %%i in (1,1,%SECONDS%) do (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "try{ $c = New-Object Net.Sockets.TcpClient('127.0.0.1',%PORT%); $c.Close(); exit 0 } catch { exit 1 }" >nul 2>&1
  if not errorlevel 1 exit /b 0
  timeout /t 1 /nobreak >nul
)
exit /b 1

:stop_appium
set "PORT=%~1"
call :kill_port %PORT%
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ps = Get-CimInstance Win32_Process -Filter ""Name='node.exe'"" | Where-Object { $_.CommandLine -match 'appium' };" ^
  "foreach($p in $ps){ try{ Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue }catch{} }" >nul 2>&1
exit /b 0
