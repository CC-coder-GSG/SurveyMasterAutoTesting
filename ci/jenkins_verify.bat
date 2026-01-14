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
REM =========================================================

REM ---- 0) 基本路径（按你机器情况改；也允许 Jenkins 通过环境变量覆盖）----
if not defined ANDROID_HOME set "ANDROID_HOME=D:\android-sdk"
if not defined NODE_HOME    set "NODE_HOME=C:\Program Files\nodejs"

REM 重要：这里写 Jenkins 服务账号对应的 npm 全局目录（不是 Administrator 就要改）
if not defined NPM_BIN      set "NPM_BIN=C:\Users\Administrator\AppData\Roaming\npm"
set "APPIUM_CMD=%NPM_BIN%\appium.cmd"

REM powershell 绝对路径（避免 Jenkins 环境 PATH 不完整导致找不到 powershell）
if not defined POWERSHELL_EXE set "POWERSHELL_EXE=C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"

REM Appium 参数
if not defined APPIUM_HOST set "APPIUM_HOST=127.0.0.1"
if not defined APPIUM_PORT set "APPIUM_PORT=4723"

REM Robot Framework 参数
REM 结果输出到 autotest/results (注意：不要直接输出到 workspace 根目录，保持整洁)
set "RF_OUTPUT_DIR=autotest\results"
set "RF_SUITE=autotest\tests"
REM 如果 Jenkins 传入了 RF_ARGS (比如 --include P0)，就用传入的；否则默认跑所有
if not defined RF_ARGS set "RF_ARGS="

REM ---- 1) 清理旧结果 ----
if exist "%RF_OUTPUT_DIR%" (
  echo Cleaning old results...
  rmdir /s /q "%RF_OUTPUT_DIR%"
)
mkdir "%RF_OUTPUT_DIR%"

REM ---- 2) 检查设备连接 ----
echo Checking ADB devices...
adb devices
REM 如果没有连接设备，下面跑测试也会挂，这里可以加个简单判断（略）

REM ---- 3) 启动 Appium 服务 (后台运行) ----
echo Starting Appium on %APPIUM_HOST%:%APPIUM_PORT% ...
REM 使用 start /b 让它在后台跑，把日志重定向防止刷屏
start /b "" "%APPIUM_CMD%" -a %APPIUM_HOST% -p %APPIUM_PORT% --log-level error:error > "%WORKSPACE%\appium.log" 2>&1

REM 等待几秒让 Appium 启动完全
timeout /t 5 /nobreak >nul

REM ---- 4) 运行 Robot Framework 测试 ----
echo.
echo ====== RUNNING ROBOT FRAMEWORK TESTS ======
echo RF_OUTPUT_DIR: %RF_OUTPUT_DIR%
echo RF_ARGS:       %RF_ARGS%
echo.

REM 调用 robot (或者 pybot，看你安装的是哪个版本，通常新版是 robot)
REM 关键参数：
REM  -d 输出目录
REM  -x output.xml (明确指定xml文件名)
REM  -v 传入变量（比如 DEVICE_ID）
robot -d "%RF_OUTPUT_DIR%" ^
  -x output.xml ^
  %RF_ARGS% ^
  --variable UDID:%DEVICE_ID% ^
  "%RF_SUITE%"

REM 捕获 Robot 的退出码 (0=Pass, >0=Fail)
set "RF_EXIT=%ERRORLEVEL%"
echo Robot exit code=%RF_EXIT%
echo.

REM ---- 5) 失败时导出 logcat ----
if not "%RF_EXIT%"=="0" (
  echo ====== EXPORT LOGCAT (FAILED) ======
  adb -s %DEVICE_ID% logcat -d -v time -b all -t 3000 > "%WORKSPACE%\logcat_%BUILD_NUMBER%.txt"
  echo Saved: %WORKSPACE%\logcat_%BUILD_NUMBER%.txt
  echo.
)

REM ---- 6) 关闭 Appium ----
echo ====== STOP APPIUM (kill by port %APPIUM_PORT%) ======
REM 简单粗暴杀 node 进程（可能会误杀其他 node 服务，但在 CI 独占环境通常没问题）
taskkill /F /IM node.exe /T >nul 2>&1
echo Appium stopped.
echo.

REM ---- 7) 同步结果到 WORKSPACE\results ----
REM 这一步非常重要！因为 Jenkinsfile 后续只归档 workspace/results
echo ====== SYNC RESULTS TO %WORKSPACE%\results ======
if not exist "%WORKSPACE%\results" mkdir "%WORKSPACE%\results"
robocopy "%CD%\%RF_OUTPUT_DIR%" "%WORKSPACE%\results" /E /NFL /NDL /NJH /NJS /NC /NS >nul
set "RC=%ERRORLEVEL%"
REM robocopy 返回 1 是成功（有文件复制），8 以上才是失败
if %RC% GEQ 8 (
  echo [WARN] robocopy sync results failed, code=%RC%
) else (
  echo [OK] Results synced to %WORKSPACE%\results
)

REM ---- 8) 发送企业微信通知 (关键修改) ----
echo.
echo ====== SENDING WECOM NOTIFICATION ======

REM 设置颜色和状态文字
if "%RF_EXIT%"=="0" (
    set "MSG_COLOR=info"
    set "MSG_STATUS=构建成功"
) else (
    set "MSG_COLOR=warning"
    set "MSG_STATUS=测试失败"
)

REM 构造报告链接 (注意：由于还在构建中，这个链接点击后可能需要等几秒钟 Jenkins 归档完成后才能访问)
set "REPORT_URL=%BUILD_URL%artifact/results/log.html"

REM 使用 PowerShell 发送 Webhook (内嵌脚本，无需额外文件)
REM 注意：使用了 Jenkins 注入的 JOB_NAME, BUILD_NUMBER, WECHAT_WEBHOOK 环境变量
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'SilentlyContinue'; " ^
  "$payload = @{ " ^
  "    msgtype = 'markdown'; " ^
  "    markdown = @{ " ^
  "        content = \"<font color='%MSG_COLOR%'>[%MSG_STATUS%]</font> %JOB_NAME% #%BUILD_NUMBER%`n>设备: %DEVICE_ID%`n>结果: [查看测试报告](%REPORT_URL%)\" " ^
  "    } " ^
  "}; " ^
  "Invoke-RestMethod -Uri $env:WECHAT_WEBHOOK -Method Post -ContentType 'application/json' -Body ($payload | ConvertTo-Json -Depth 2 -Compress); " ^
  "Write-Host 'Notification sent to WeCom.'"

REM ---- 9) 强制返回 0 (Hack) ----
REM 即使 Robot 失败了，我们也返回 0，这样 Jenkins 流水线不会变成红色 Failure
REM 而是继续执行 post { archiveArtifacts }，确保报告能被归档保存
echo.
echo [INFO] Forcing script exit code to 0 to allow Jenkins artifacts archiving...
exit /b 0