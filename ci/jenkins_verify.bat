@echo off
setlocal EnableExtensions

REM 脚本所在目录
set "SCRIPT_DIR=%~dp0"
REM 项目根目录（ci 的上一级）
set "PROJECT_ROOT=%SCRIPT_DIR%.."
cd /d "%PROJECT_ROOT%"

REM Jenkins 里有 WORKSPACE；本地运行时没有的话就用当前目录
if not defined WORKSPACE set "WORKSPACE=%CD%"


REM =========================================================
REM  Jenkins - RobotFramework + Appium (Windows) Verify Script
REM  目标：
REM   1) 确认 node/appium/adb 可用
REM   2) 启动 Appium 到 127.0.0.1:4723
REM   3) 创建 venv + 安装 requirements.txt
REM   4) 执行一个 sanity 用例
REM   5) 结束后清理占用 4723 端口的进程
REM =========================================================

REM ---- 0) 基本路径（按你机器情况改）----
set "ANDROID_HOME=D:\android-sdk"
set "NODE_HOME=C:\Program Files\nodejs"

REM 重要：这里写 Administrator 的 npm 全局目录（如果 Jenkins 服务不是 Administrator 运行，要换成对应账号）
set "NPM_BIN=C:\Users\Administrator\AppData\Roaming\npm"
set "APPIUM_CMD=%NPM_BIN%\appium.cmd"

REM powershell 绝对路径（避免 Jenkins 环境 PATH 不完整导致找不到 powershell）
set "POWERSHELL_EXE=C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"

REM Appium 参数
set "APPIUM_HOST=127.0.0.1"
set "APPIUM_PORT=4723"
set "APPIUM_URL=http://%APPIUM_HOST%:%APPIUM_PORT%"
set "APPIUM_LOG=%WORKSPACE%\appium.log"
REM 设备ID（adb devices 里看到的那串）
set "DEVICE_ID=4e83cae7"

REM 你要跑的用例（可改成 tests 或某个 suite）
set "RF_SUITE=tests\smoke\_sanity_open_app.robot"
set "RF_OUTPUT_DIR=results"

REM ---- 1) 修复 Jenkins 环境 PATH（确保 where/chcp/taskkill/netstat/powershell/adb/node/appium 都能找到）----
set "PATH=%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\build-tools\35.0.1;%NODE_HOME%;%NPM_BIN%;C:\Windows\System32;C:\Windows;C:\Windows\System32\WindowsPowerShell\v1.0;%PATH%"

REM 编码
chcp 65001 >nul

echo ====== WHOAMI ======
whoami
echo.

echo ====== WORKSPACE ======
echo WORKSPACE=%WORKSPACE%
echo.

echo ====== ENV CHECK ======
echo ANDROID_HOME=%ANDROID_HOME%
echo NODE_HOME=%NODE_HOME%
echo NPM_BIN=%NPM_BIN%
echo APPIUM_CMD=%APPIUM_CMD%
echo PATH=%PATH%
echo.

echo ====== TOOL LOCATIONS ======
"C:\Windows\System32\where.exe" adb
"C:\Windows\System32\where.exe" node
"C:\Windows\System32\where.exe" powershell
"C:\Windows\System32\where.exe" appium
echo.

echo ====== TOOL VERSIONS ======
adb version
node -v
call "%APPIUM_CMD%" -v
echo.

REM ---- 2) 先清理 4723 端口（防止上一次残留）----
echo ====== CLEAN PORT %APPIUM_PORT% (if occupied) ======
for /f %%P in ('"%POWERSHELL_EXE%" -NoProfile -Command "(Get-NetTCPConnection -LocalPort %APPIUM_PORT% -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty OwningProcess)"') do set "OLD_PID=%%P"
if not "%OLD_PID%"=="" (
  echo Port %APPIUM_PORT% is used by PID=%OLD_PID%, killing...
  taskkill /F /PID %OLD_PID% >nul 2>&1
) else (
  echo Port %APPIUM_PORT% is free.
)
echo.

REM ---- 3) 启动 Appium（后台）----
echo ====== START APPIUM ======
if exist "%APPIUM_LOG%" del /f /q "%APPIUM_LOG%" >nul 2>&1

REM 用 start /B 后台启动；用 appium.cmd 的绝对路径，避免 Jenkins 环境找不到 appium
start "" /B cmd /c ""%APPIUM_CMD%" --address %APPIUM_HOST% --port %APPIUM_PORT% --log "%APPIUM_LOG%""

REM ---- 4) 等待 Appium 就绪（最多 30 秒）----
echo ====== WAIT APPIUM READY ======
"%POWERSHELL_EXE%" -NoProfile -Command ^
  "$u='%APPIUM_URL%/status';" ^
  "for($i=0;$i -lt 30;$i++){" ^
  "  try { $r = Invoke-WebRequest -UseBasicParsing $u -TimeoutSec 2; if($r.StatusCode -ge 200){ exit 0 } }" ^
  "  catch { Start-Sleep -Seconds 1 }" ^
  "}; exit 1"

if errorlevel 1 (
  echo.
  echo [ERROR] Appium did not become ready. Dumping last log lines:
  if exist "%APPIUM_LOG%" (
    "%POWERSHELL_EXE%" -NoProfile -Command "Get-Content -Path '%APPIUM_LOG%' -Tail 120"
  ) else (
    echo [WARN] appium.log not found
  )
  exit /b 1
)

echo Appium is ready: %APPIUM_URL%
echo.

REM ---- 4.1) 跑用例前清空 logcat ----
adb -s %DEVICE_ID% logcat -c


REM ---- 5) 创建 venv + 安装依赖 ----
echo ====== PYTHON VENV + DEPENDENCIES ======
if not exist ".venv\Scripts\python.exe" (
  python -m venv .venv
)
call ".venv\Scripts\activate.bat"

python -V
python -m pip install -U pip
python -m pip install -r requirements.txt
echo.

REM ---- 6) 执行 RF 用例 ----
echo ====== RUN ROBOT ======
if exist "%RF_OUTPUT_DIR%" rmdir /s /q "%RF_OUTPUT_DIR%"
python -m robot -d "%RF_OUTPUT_DIR%" "%RF_SUITE%"
set "RF_EXIT=%ERRORLEVEL%"
echo Robot exit code=%RF_EXIT%
echo.

REM ---- 6.1) 失败时导出 logcat（便于排查）----
if not "%RF_EXIT%"=="0" (
  echo ====== EXPORT LOGCAT (FAILED) ======
  adb -s %DEVICE_ID% logcat -d -v time -b all -t 3000 > "%WORKSPACE%\logcat_%BUILD_NUMBER%.txt"
  echo Saved: %WORKSPACE%\logcat_%BUILD_NUMBER%.txt
  echo.
)


REM ---- 7) 结束后清理 Appium（按端口杀）----
echo ====== STOP APPIUM (kill by port %APPIUM_PORT%) ======
set "OLD_PID="
for /f %%P in ('"%POWERSHELL_EXE%" -NoProfile -Command "(Get-NetTCPConnection -LocalPort %APPIUM_PORT% -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty OwningProcess)"') do set "OLD_PID=%%P"
if not "%OLD_PID%"=="" (
  echo Killing PID=%OLD_PID%
  taskkill /F /PID %OLD_PID% >nul 2>&1
) else (
  echo No listening process on %APPIUM_PORT%
)
echo.

REM ---- 8) 企业微信群通知（带概览）----
REM Webhook 通过 Jenkins 凭据注入到环境变量 WECHAT_WEBHOOK，仓库里不要写 key
if defined WECHAT_WEBHOOK (
  powershell -NoProfile -ExecutionPolicy Bypass ^
    -File "ci\wecom_notify.ps1" ^
    -Webhook "%WECHAT_WEBHOOK%" ^
    -BuildUrl "%BUILD_URL%" ^
    -OutputXml "%WORKSPACE%\results\output.xml" ^
    -JobName "%JOB_NAME%" ^
    -BuildNumber "%BUILD_NUMBER%" ^
    -ExitCode %RF_EXIT%
) else (
  echo [WARN] WECHAT_WEBHOOK not set, skip WeCom notify.
)


exit /b %RF_EXIT%
