@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

rem ============================================================
rem  Jenkins verify (Windows): Appium + Robot Framework
rem  方案A版本（不依赖日志文件，只用端口判断 Appium 状态）
rem  特点：
rem    - 不再写入/读取 appium.log / appium.err.log（避免加密干扰）
rem    - 仅通过 netstat 检测 4723 端口是否 LISTENING
rem    - 仍然支持 DEVICE_ID、RF_ARGS、RF_TEST_PATH 等参数
rem ============================================================

rem ---- 基本路径 ----
set "CI_DIR=%~dp0"
cd /d "%CI_DIR%\.."
set "AUTOTEST_DIR=%CD%"

if not defined WORKSPACE set "WORKSPACE=%AUTOTEST_DIR%"

rem ---- 输入参数与默认值 ----
if not defined DEVICE_ID (
  echo [ERROR] DEVICE_ID is not set.
  exit /b 2
)

if not defined ANDROID_HOME set "ANDROID_HOME=D:\android-sdk"
set "ADB_CMD=%ANDROID_HOME%\platform-tools\adb.exe"

if not defined NPM_BIN set "NPM_BIN=%APPDATA%\npm"
if not defined APPIUM_CMD set "APPIUM_CMD=%NPM_BIN%\appium.cmd"
if not defined APPIUM_PORT set "APPIUM_PORT=4723"

rem PATH：确保 npm bin 和 node 在 PATH 中
set "PATH=%NPM_BIN%;%PATH%"
if exist "C:\Program Files\nodejs\node.exe" set "PATH=C:\Program Files\nodejs;%PATH%"

rem 结果与临时文件路径
set "RESULTS_DST=%WORKSPACE%\results"
set "RF_OUTPUT_DIR=%AUTOTEST_DIR%\results"
set "ROBOT_CONSOLE_LOG=%RESULTS_DST%\robot_console.log"
set "NETSTAT_TMP=%WORKSPACE%\_netstat_check.txt"
set "APPIUM_PID_FILE=%WORKSPACE%\appium.pid"

set "PYTHONUTF8=1"
set "PYTHONIOENCODING=utf-8"

rem ---- 准备结果目录 ----
if exist "%RF_OUTPUT_DIR%" rmdir /s /q "%RF_OUTPUT_DIR%"
mkdir "%RF_OUTPUT_DIR%" >nul 2>&1

if not exist "%RESULTS_DST%" mkdir "%RESULTS_DST%" >nul 2>&1
if exist "%ROBOT_CONSOLE_LOG%" del /f /q "%ROBOT_CONSOLE_LOG%" >nul 2>&1

rem ---- 工具检查 ----
echo [INFO] ===== ENV CHECK =====
where node >nul 2>&1 || (echo [ERROR] node not found in PATH & exit /b 2)
node -v

if not exist "%ADB_CMD%" (
  echo [ERROR] ADB not found: "%ADB_CMD%"
  exit /b 2
)
if not exist "%APPIUM_CMD%" (
  echo [ERROR] appium.cmd not found: "%APPIUM_CMD%"
  exit /b 2
)

rem 仅用于确认 appium CLI 存在（输出乱码也无所谓）
call "%APPIUM_CMD%" -v
if errorlevel 1 (
  echo [ERROR] Appium CLI failed ^(check node/npm/appium installation^).
  exit /b 2
)

rem ---- 检查设备在线 ----
echo [INFO] ===== CHECK DEVICE =====
"%ADB_CMD%" start-server >nul 2>&1

set "DEV_OK=0"
for /l %%i in (1,1,20) do (
  powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
    "$s=((& '%ADB_CMD%' -s '%DEVICE_ID%' get-state 2^>$null) -join '').Trim(); if($s -eq 'device'){exit 0}else{exit 1}"
  if !errorlevel! EQU 0 (
    set "DEV_OK=1"
    goto :DEVICE_OK
  )
  ping -n 2 127.0.0.1 >nul
)
echo [ERROR] Device "%DEVICE_ID%" not ready.
"%ADB_CMD%" devices
exit /b 3

:DEVICE_OK
echo [OK] Device "%DEVICE_ID%" is online.

rem ---- 清理旧 Appium 进程 ----
echo [INFO] ===== CLEAN PORT %APPIUM_PORT% =====
call :STOP_APPIUM >nul 2>&1

rem 按端口杀掉可能占用 4723 的进程（最好努力）
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "try{Get-NetTCPConnection -LocalPort %APPIUM_PORT% -State Listen -ErrorAction Stop ^| %%{Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue}}catch{}" >nul 2>&1

rem ---- 启动 Appium ----
echo [INFO] ===== START APPIUM =====
if exist "%APPIUM_PID_FILE%" del /f /q "%APPIUM_PID_FILE%" >nul 2>&1

set "APPIUM_ARGS=--address 127.0.0.1 --port %APPIUM_PORT% --log-level info --local-timezone"
echo [INFO] Launch: "%APPIUM_CMD%" %APPIUM_ARGS%

rem 关键：不再重定向日志，避免加密干扰
start "" /min "%APPIUM_CMD%" %APPIUM_ARGS%

rem ---- 等待 Appium 就绪（仅靠 netstat） ----
echo [INFO] ===== WAIT APPIUM READY (up to 240s) =====
set "APPIUM_UP=0"
for /l %%i in (1,1,240) do (
  rem 检查端口是否处于 LISTENING 状态
  netstat -ano > "%NETSTAT_TMP%" 2>nul
  findstr /R /C:":%APPIUM_PORT% .*LISTENING" "%NETSTAT_TMP%" >nul 2>&1
  if !errorlevel! EQU 0 (
    set "APPIUM_UP=1"
    goto :APPIUM_OK
  )

  ping -n 2 127.0.0.1 >nul
)

echo [ERROR] Appium timeout: port %APPIUM_PORT% not ready.
if exist "%NETSTAT_TMP%" (
  echo [DEBUG] netstat snapshot:
  type "%NETSTAT_TMP%"
)
goto :FAIL

:APPIUM_OK
echo [OK] Appium is ready on %APPIUM_PORT%.

rem 通过 netstat 反查真正的 Appium PID，方便后面清理
netstat -ano > "%NETSTAT_TMP%" 2>nul
for /f "tokens=5" %%p in ('findstr /R /C:":%APPIUM_PORT% .*LISTENING" "%NETSTAT_TMP%"') do (
  echo %%p>"%APPIUM_PID_FILE%"
  echo [INFO] Appium Service PID=%%p
  goto :PID_DONE
)
:PID_DONE

rem ---- 运行 Robot Framework 用例 ----
echo [INFO] ===== RUN ROBOT =====
if not defined RF_TEST_PATH set "RF_TEST_PATH=tests"
if not defined RF_ARGS set "RF_ARGS=--suite CreateNewProject"

where python >nul 2>&1 || (echo [ERROR] python not found in PATH & goto :FAIL)
python -V

rem 检查 Robot Framework 是否安装
python -c "import robot; print(robot.__version__)" >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Robot Framework not installed in this Python.
  echo [HINT] 在服务器上运行一次：
  echo        pip install robotframework Appium-Python-Client robotframework-appiumlibrary
  goto :FAIL
)

echo [INFO] Robot console log: "%ROBOT_CONSOLE_LOG%"

rem 判断 RF_ARGS 里是否已经包含用例路径（例如 tests 或 *.robot）
set "RF_APPEND_PATH=1"
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "$a=$env:RF_ARGS; if($a -match '(^| )tests($| )' -or $a -match '\.robot' -or $a -match '[\\/]' ){ exit 0 } else { exit 1 }"
if !errorlevel! EQU 0 set "RF_APPEND_PATH=0"

if "%RF_APPEND_PATH%"=="1" (
  echo [INFO] CMD: python -m robot --outputdir "%RF_OUTPUT_DIR%" %RF_ARGS% "%RF_TEST_PATH%"
  python -m robot --outputdir "%RF_OUTPUT_DIR%" %RF_ARGS% "%RF_TEST_PATH%" > "%ROBOT_CONSOLE_LOG%" 2>&1
) else (
  echo [INFO] CMD: python -m robot --outputdir "%RF_OUTPUT_DIR%" %RF_ARGS%
  python -m robot --outputdir "%RF_OUTPUT_DIR%" %RF_ARGS% > "%ROBOT_CONSOLE_LOG%" 2>&1
)

set "RF_EXIT=%ERRORLEVEL%"

if not "%RF_EXIT%"=="0" (
  echo [ERROR] Robot failed (exit=%RF_EXIT%). Tail robot_console.log:
  powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
    "if(Test-Path '%ROBOT_CONSOLE_LOG%'){Get-Content -Tail 120 '%ROBOT_CONSOLE_LOG%'}"
)

rem ---- 同步结果到 Jenkins 工作区（results） ----
echo [INFO] ===== SYNC RESULTS =====
if exist "%RF_OUTPUT_DIR%\output.xml" (
  robocopy "%RF_OUTPUT_DIR%" "%RESULTS_DST%" /E /NFL /NDL /NJH /NJS /NC /NS >nul
) else (
  echo [WARN] output.xml not found under "%RF_OUTPUT_DIR%"
)

call :STOP_APPIUM >nul 2>&1
exit /b %RF_EXIT%

rem ============================================================
rem  停止 Appium：按 PID 杀进程树，再按端口兜底
rem ============================================================
:STOP_APPIUM
rem 1) PID 文件方式
if exist "%APPIUM_PID_FILE%" (
  for /f "usebackq delims=" %%p in ("%APPIUM_PID_FILE%") do (
    if not "%%p"=="" taskkill /F /T /PID %%p >nul 2>&1
  )
  del /f /q "%APPIUM_PID_FILE%" >nul 2>&1
)

rem 2) 端口兜底方式
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "try{Get-NetTCPConnection -LocalPort %APPIUM_PORT% -State Listen -ErrorAction Stop ^| %%{Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue}}catch{}" >nul 2>&1

exit /b 0

:FAIL
call :STOP_APPIUM >nul 2>&1
exit /b 255