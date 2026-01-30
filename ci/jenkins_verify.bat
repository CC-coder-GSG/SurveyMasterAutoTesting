@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================
rem Jenkins verify runner (FINAL)
rem - encryption-safe: do not parse adb text output
rem - robust adb: kill adb.exe + free 5037 + retry start-server
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

pushd "%ROOT%" || ( echo [ERROR] Cannot cd to project root. & exit /b 1 )
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

echo [INFO] ===== PYTHON CHECK =====
"%PY_EXE%" -V || ( set "ROBOT_RC=1" & goto :finally )

echo [INFO] ===== PYTHON DEPS CHECK =====
call :check_pip_pkg robotframework
if errorlevel 1 ( set "ROBOT_RC=10" & goto :finally )
call :check_pip_pkg robotframework-appiumlibrary
if errorlevel 1 ( set "ROBOT_RC=10" & goto :finally )
call :check_pip_pkg pyyaml
if errorlevel 1 ( set "ROBOT_RC=10" & goto :finally )

echo [INFO] ===== ENV CHECK =====
where node >nul 2>&1 || ( echo [ERROR] node not found & set "ROBOT_RC=2" & goto :finally )
node -v
where npm >nul 2>&1 || ( echo [ERROR] npm not found & set "ROBOT_RC=2" & goto :finally )
call npm -v >nul 2>&1 || ( echo [ERROR] npm failed & set "ROBOT_RC=2" & goto :finally )

set "APPIUM_CMD=%NPM_BIN%\appium.cmd"
if not exist "%APPIUM_CMD%" (
  for /f "delims=" %%p in ('where appium 2^>nul') do set "APPIUM_CMD=%%p"
)
if not exist "%APPIUM_CMD%" (
  echo [ERROR] appium command not found. Run: npm i -g appium
  set "ROBOT_RC=2"
  goto :finally hooking
)

echo [INFO] ===== CHECK DEVICE (encryption-safe) =====
if not exist "%ADB_EXE%" (
  echo [ERROR] adb.exe not found: %ADB_EXE%
  set "ROBOT_RC=3"
  goto :finally
)

call :adb_restart
if errorlevel 1 (
  echo [ERROR] adb restart failed.
  set "ROBOT_RC=3"
  goto :finally
)

rem wait-for-device (20s)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$adb='%ADB_EXE%'; $id='%DEVICE_ID%';" ^
  "$p = Start-Process -FilePath $adb -ArgumentList @('-s',$id,'wait-for-device') -NoNewWindow -PassThru -RedirectStandardOutput ($env:TEMP+'\\wf_out.txt') -RedirectStandardError ($env:TEMP+'\\wf_err.txt');" ^
  "if($p.WaitForExit(20000)){ exit $p.ExitCode } else { try{$p.Kill()}catch{}; exit 124 }" >nul 2>&1

if errorlevel 124 (
  echo [ERROR] adb wait-for-device timeout (20s): %DEVICE_ID%
  set "ROBOT_RC=3"
  goto :finally
)

rem get-state (10s) - check inside ps, do not parse in bat
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$adb='%ADB_EXE%'; $id='%DEVICE_ID%';" ^
  "$tmp = Join-Path $env:TEMP ('adb_state_'+$id+'.txt');" ^
  "$p = Start-Process -FilePath $adb -ArgumentList @('-s',$id,'get-state') -NoNewWindow -PassThru -RedirectStandardOutput $tmp -RedirectStandardError ($env:TEMP+'\\gs_err.txt');" ^
  "if(-not $p.WaitForExit(10000)){ try{$p.Kill()}catch{}; exit 124 }" ^
  "$s = (Get-Content $tmp -ErrorAction SilentlyContinue | Select-Object -First 1);" ^
  "if($null -eq $s){ exit 3 }" ^
  "$s = $s.Trim();" ^
  "if($s -ieq 'device'){ exit 0 } else { exit 3 }" >nul 2>&1

if errorlevel 124 (
  echo [ERROR] adb get-state timeout (10s): %DEVICE_ID%
  set "ROBOT_RC=3"
  goto :finally
)
if errorlevel 3 (
  echo [ERROR] device not in 'device' state (offline/unauthorized/not found): %DEVICE_ID%
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

echo [INFO] ===== WAIT APPIUM READY =====
call :wait_port %APPIUM_PORT% 90
if errorlevel 1 (
  echo [ERROR] Appium not ready on %APPIUM_PORT%.
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

echo [INFO] ===== RESULT FILES (exist check) =====
if exist "%OUTDIR%\output.xml" echo [OK] output.xml: %OUTDIR%\output.xml
dir /a /-c "%OUTDIR%" >nul 2>&1

echo [INFO] ===== END jenkins_verify.bat ROBOT_RC=%ROBOT_RC% =====
popd
exit /b %ROBOT_RC%

rem ================= Subroutines =================

:check_pip_pkg
set "PKG=%~1"
"%PY_EXE%" -m pip show "%PKG%" >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Python package not installed: %PKG%
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

:adb_restart
rem 1) kill any adb.exe
taskkill /F /IM adb.exe >nul 2>&1

rem 2) free port 5037 if occupied
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /r /c:":5037 " 2^>nul') do (
  taskkill /F /PID %%p >nul 2>&1
)

rem 3) try kill-server/start-server with retries
set "TRY=0"
:adb_retry
set /a TRY+=1
if %TRY% GTR 3 (
  echo [ERROR] adb start-server timeout after retries.
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$adb='%ADB_EXE%';" ^
  "$o=Join-Path $env:TEMP ('adb_o_'+(Get-Random)+'.txt');" ^
  "$e=Join-Path $env:TEMP ('adb_e_'+(Get-Random)+'.txt');" ^
  "try{ Start-Process -FilePath $adb -ArgumentList @('kill-server') -NoNewWindow -PassThru -RedirectStandardOutput $o -RedirectStandardError $e | Out-Null }catch{}" ^
  "Start-Sleep -Milliseconds 300;" ^
  "$p = Start-Process -FilePath $adb -ArgumentList @('start-server') -NoNewWindow -PassThru -RedirectStandardOutput $o -RedirectStandardError $e;" ^
  "if($p.WaitForExit(60000)){ exit $p.ExitCode } else { try{$p.Kill()}catch{}; exit 124 }" >nul 2>&1

if errorlevel 124 (
  echo [WARN] adb start-server timeout (60s), retry=%TRY%
  taskkill /F /IM adb.exe >nul 2>&1
  timeout /t 1 /nobreak >nul
  goto :adb_retry
)

exit /b 0
