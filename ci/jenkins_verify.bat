@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================
rem Jenkins verify runner (FINAL STABLE)
rem - No "goto" inside (...) blocks
rem - ENCRYPTION-SAFE device check: do not parse adb devices output
rem - ADB calls via PowerShell Start-Process + timeout + exitcode
rem - Appium: start with PID recorded, stop by killing process tree
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

rem ---- Files ----
set "APPIUM_LOG=%OUTDIR%\appium.log"
set "APPIUM_PID_FILE=%OUTDIR%\appium.pid"
set "ARGFILE=%OUTDIR%\robot_args.txt"

echo [INFO] ===== START jenkins_verify.bat =====
echo [INFO] BAT=%BAT%
echo [INFO] OUTDIR=%OUTDIR%
echo [INFO] ADB_EXE=%ADB_EXE%
echo [INFO] DEVICE_ID=%DEVICE_ID%
echo [INFO] APPIUM_PORT=%APPIUM_PORT%

pushd "%ROOT%" || ( echo [ERROR] Cannot cd to project root. & exit /b 1 )

if not exist "%OUTDIR%" mkdir "%OUTDIR%"

rem ---- Python check ----
echo [INFO] ===== PYTHON CHECK =====
"%PY_EXE%" -V || ( set "ROBOT_RC=1" & goto finally )

rem ---- Python deps ----
echo [INFO] ===== PYTHON DEPS CHECK =====
call :check_pip_pkg robotframework
if errorlevel 1 ( set "ROBOT_RC=10" & goto finally )

call :check_pip_pkg robotframework-appiumlibrary
if errorlevel 1 ( set "ROBOT_RC=10" & goto finally )

call :check_pip_pkg pyyaml
if errorlevel 1 ( set "ROBOT_RC=10" & goto finally )

rem ---- Env check ----
echo [INFO] ===== ENV CHECK =====
where node >nul 2>&1
if errorlevel 1 ( echo [ERROR] node not found in PATH. & set "ROBOT_RC=2" & goto finally )
node -v

where npm >nul 2>&1
if errorlevel 1 ( echo [ERROR] npm not found in PATH. & set "ROBOT_RC=2" & goto finally )
call npm -v >nul 2>&1
if errorlevel 1 ( echo [ERROR] npm failed to run. & set "ROBOT_RC=2" & goto finally )

rem ---- Locate appium.cmd ----
set "APPIUM_CMD=%NPM_BIN%\appium.cmd"
if not exist "%APPIUM_CMD%" (
  for /f "delims=" %%p in ('where appium 2^>nul') do set "APPIUM_CMD=%%p"
)

if not exist "%APPIUM_CMD%" (
  echo [ERROR] appium command not found.
  echo [HINT] Run: npm i -g appium
  set "ROBOT_RC=2"
  goto finally
)

rem ---- Device check (ENCRYPTION-SAFE) ----
echo [INFO] ===== CHECK DEVICE (encryption-safe) =====
if not exist "%ADB_EXE%" (
  echo [ERROR] adb.exe not found at: %ADB_EXE%
  set "ROBOT_RC=3"
  goto finally
)

rem Restart adb in a safe way (avoid daemon banner breaking wrapper)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$adb='%ADB_EXE%';" ^
  "try{ $p=Start-Process -FilePath $adb -ArgumentList @('kill-server') -NoNewWindow -PassThru; $p.WaitForExit(10)|Out-Null }catch{}" ^
  "$p=Start-Process -FilePath $adb -ArgumentList @('start-server') -NoNewWindow -PassThru;" ^
  "if($p.WaitForExit(15)){ exit $p.ExitCode } else { try{$p.Kill()}catch{}; exit 124 }" >nul 2>&1

if errorlevel 124 (
  echo [ERROR] adb start-server timeout (15s)
  set "ROBOT_RC=3"
  goto finally
)

rem 1) wait-for-device (20s timeout)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$adb='%ADB_EXE%'; $id='%DEVICE_ID%';" ^
  "$p=Start-Process -FilePath $adb -ArgumentList @('-s',$id,'wait-for-device') -NoNewWindow -PassThru;" ^
  "if($p.WaitForExit(20)){ exit $p.ExitCode } else { try{$p.Kill()}catch{}; exit 124 }" >nul 2>&1

if errorlevel 124 (
  echo [ERROR] adb wait-for-device timeout (20s): %DEVICE_ID%
  set "ROBOT_RC=3"
  goto finally
)

rem 2) get-state (10s timeout)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$adb='%ADB_EXE%'; $id='%DEVICE_ID%'; $tmp=Join-Path $env:TEMP ('adb_state_'+$id+'.txt');" ^
  "try{ if(Test-Path $tmp){Remove-Item -Force $tmp -ErrorAction SilentlyContinue} }catch{}" ^
  "$p=Start-Process -FilePath $adb -ArgumentList @('-s',$id,'get-state') -NoNewWindow -PassThru -RedirectStandardOutput $tmp;" ^
  "if(-not $p.WaitForExit(10)){ try{$p.Kill()}catch{}; exit 124 }" ^
  "$s=(Get-Content $tmp -ErrorAction SilentlyContinue | Select-Object -First 1);" ^
  "if(($s -as [string]).Trim().ToLower() -eq 'device'){ exit 0 } else { exit 3 }" >nul 2>&1

if errorlevel 124 (
  echo [ERROR] adb get-state timeout (10s): %DEVICE_ID%
  set "ROBOT_RC=3"
  goto finally
)
if errorlevel 3 (
  echo [ERROR] device not in 'device' state (offline/unauthorized/not found): %DEVICE_ID%
  set "ROBOT_RC=3"
  goto finally
)

rem 3) sanity shell (exitcode only)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$adb='%ADB_EXE%'; $id='%DEVICE_ID%';" ^
  "$p=Start-Process -FilePath $adb -ArgumentList @('-s',$id,'shell','echo','ok') -NoNewWindow -PassThru;" ^
  "if($p.WaitForExit(10)){ exit $p.ExitCode } else { try{$p.Kill()}catch{}; exit 124 }" >nul 2>&1

if errorlevel 124 (
  echo [ERROR] adb shell timeout (10s): %DEVICE_ID%
  set "ROBOT_RC=3"
  goto finally
)
if errorlevel 1 (
  echo [ERROR] adb shell not available (unauthorized/offline?): %DEVICE_ID%
  set "ROBOT_RC=3"
  goto finally
)

echo [OK] Device "%DEVICE_ID%" is online (device).

rem ---- Stop any leftovers ----
call :stop_appium %APPIUM_PORT%

rem ---- Start Appium (record PID) ----
echo [INFO] ===== START APPIUM =====
if exist "%APPIUM_PID_FILE%" del /f /q "%APPIUM_PID_FILE%" >nul 2>&1
if exist "%APPIUM_LOG%" del /f /q "%APPIUM_LOG%" >nul 2>&1

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$cmd='cmd.exe';" ^
  "$args='/c call ""%APPIUM_CMD%"" --address 127.0.0.1 --port %APPIUM_PORT% --log-level info --local-timezone 1> ""%APPIUM_LOG%"" 2>&1';" ^
  "$p=Start-Process -FilePath $cmd -ArgumentList $args -WindowStyle Hidden -PassThru;" ^
  "Set-Content -Path '%APPIUM_PID_FILE%' -Value $p.Id -Encoding ASCII" >nul 2>&1

timeout /t 2 /nobreak >nul

call :wait_port %APPIUM_PORT% 90
if errorlevel 1 (
  echo [ERROR] Appium not ready on port %APPIUM_PORT% within timeout.
  echo [HINT] Check: %APPIUM_LOG%
  set "ROBOT_RC=4"
  goto finally
)
echo [OK] Appium is ready.

rem ---- Run Robot ----
echo [INFO] ===== RUN ROBOT =====
if exist "%ARGFILE%" (
  echo [INFO] Using argument file: %ARGFILE%
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
if exist "%OUTDIR%\output.xml" echo [INFO] output.xml OK
if exist "%OUTDIR%\report.html" echo [INFO] report.html OK
if exist "%OUTDIR%\log.html" echo [INFO] log.html OK
if exist "%OUTDIR%\appium.log" echo [INFO] appium.log OK

echo [INFO] ===== END jenkins_verify.bat ROBOT_RC=%ROBOT_RC% =====
popd
exit /b %ROBOT_RC%

rem ===========================
rem Subroutines
rem ===========================

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
  powershell -NoProfile -ExecutionPolicy Bypass -Command "try{ $c=New-Object Net.Sockets.TcpClient('127.0.0.1',%PORT%); $c.Close(); exit 0 } catch { exit 1 }" >nul 2>&1
  if not errorlevel 1 exit /b 0
  timeout /t 1 /nobreak >nul
)
exit /b 1

:stop_appium
set "PORT=%~1"

rem 1) kill by recorded PID tree
if exist "%APPIUM_PID_FILE%" (
  for /f "usebackq delims=" %%x in ("%APPIUM_PID_FILE%") do set "APPIUM_PID=%%x"
  if not "%APPIUM_PID%"=="" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
      "$pid=%APPIUM_PID%;" ^
      "try{ taskkill /PID $pid /T /F | Out-Null }catch{}" >nul 2>&1
  )
)

rem 2) kill port listener
call :kill_port %PORT%

rem 3) kill only node.exe processes running appium (safe)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ps=Get-CimInstance Win32_Process -Filter ""Name='node.exe'"" | Where-Object { $_.CommandLine -match 'appium' };" ^
  "foreach($p in $ps){ try{ Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue }catch{} }" >nul 2>&1

exit /b 0
