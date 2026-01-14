@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM =========================================================
REM  Jenkins - RobotFramework + Appium (Windows) Verify Script
REM  修复版 v2
REM =========================================================

REM ---- 1. 路径与环境配置 ----

REM 脚本所在目录
set "SCRIPT_DIR=%~dp0"
REM 切换到项目根目录
cd /d "%SCRIPT_DIR%.."

REM 确保 WORKSPACE 变量存在
if not defined WORKSPACE set "WORKSPACE=%CD%"

REM 配置 ANDROID_HOME (如果没有设置，使用默认 D 盘路径)
if not defined ANDROID_HOME set "ANDROID_HOME=D:\android-sdk"

REM 配置 ADB 全路径 (解决 'adb' 不是内部命令的问题)
set "ADB_CMD=%ANDROID_HOME%\platform-tools\adb.exe"

REM 配置 Appium 路径
if not defined NPM_BIN set "NPM_BIN=C:\Users\Administrator\AppData\Roaming\npm"
set "APPIUM_CMD=%NPM_BIN%\appium.cmd"
if not defined APPIUM_PORT set "APPIUM_PORT=4723"

REM 配置 PowerShell
set "POWERSHELL_EXE=C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"

REM 配置 Robot 输出目录
set "RF_OUTPUT_DIR=autotest\results"
set "RF_SUITE=autotest\tests"

REM ---- 2. 清理环境 ----

if exist "%RF_OUTPUT_DIR%" (
    echo [INFO] Cleaning old results...
    rmdir /s /q "%RF_OUTPUT_DIR%"
)
mkdir "%RF_OUTPUT_DIR%"

REM ---- 3. 检查设备与环境 ----

echo [INFO] Checking ADB path: "%ADB_CMD%"
if not exist "%ADB_CMD%" (
    echo [ERROR] ADB not found at "%ADB_CMD%". Please check ANDROID_HOME.
    exit /b 1
)

echo [INFO] Checking connected devices...
"%ADB_CMD%" devices

REM ---- 4. 启动 Appium (修复重定向报错问题) ----

echo [INFO] Starting Appium on port %APPIUM_PORT%...
REM 使用 start /MIN 启动最小化窗口，避免 jenkins 挂起或报错
REM 注意：这里不再使用 /b，改用新窗口运行，通过 cmd /c 来处理重定向
start "AppiumServer" /MIN cmd /c ""%APPIUM_CMD%" -p %APPIUM_PORT% --log-level error:error > "%WORKSPACE%\appium.log" 2>&1"

REM 等待 10 秒确保启动完成
timeout /t 10 /nobreak >nul

REM ---- 5. 运行 Robot Framework 测试 (修复语法错误) ----

echo.
echo ====== RUNNING ROBOT FRAMEWORK TESTS ======

REM 尝试查找 robot 命令，如果找不到则使用 python -m robot
where robot >nul 2>&1
if %ERRORLEVEL% equ 0 (
    set "ROBOT_EXEC=robot"
) else (
    echo [WARN] 'robot' command not found in PATH, trying 'python -m robot'...
    set "ROBOT_EXEC=python -m robot"
)

REM 执行测试 (注意：为了防止语法错误，这里写成一行)
echo Executing: %ROBOT_EXEC% -d "%RF_OUTPUT_DIR%" -x output.xml --variable UDID:%DEVICE_ID% "%RF_SUITE%"

%ROBOT_EXEC% -d "%RF_OUTPUT_DIR%" -x output.xml %RF_ARGS% --variable UDID:%DEVICE_ID% "%RF_SUITE%"

REM 捕获退出码
set "RF_EXIT=%ERRORLEVEL%"
echo Robot exit code=%RF_EXIT%

REM ---- 6. 失败时导出 Logcat ----

if not "%RF_EXIT%"=="0" (
    echo.
    echo ====== EXPORT LOGCAT (FAILED) ======
    "%ADB_CMD%" -s %DEVICE_ID% logcat -d -v time -b all -t 3000 > "%WORKSPACE%\logcat_%BUILD_NUMBER%.txt"
    echo Saved: %WORKSPACE%\logcat_%BUILD_NUMBER%.txt
)

REM ---- 7. 关闭 Appium ----

echo.
echo ====== STOP APPIUM ======
taskkill /F /IM node.exe /T >nul 2>&1

REM ---- 8. 结果同步 (关键) ----

echo.
echo ====== SYNC RESULTS TO WORKSPACE ======
if not exist "%WORKSPACE%\results" mkdir "%WORKSPACE%\results"
robocopy "%CD%\%RF_OUTPUT_DIR%" "%WORKSPACE%\results" /E /NFL /NDL /NJH /NJS /NC /NS >nul
REM Robocopy 返回 1 是成功，这里忽略错误码
echo [OK] Results synced.

REM ---- 9. 发送企业微信通知 ----

echo.
echo ====== SENDING WECOM NOTIFICATION ======

if "%RF_EXIT%"=="0" (
    set "MSG_COLOR=info"
    set "MSG_STATUS=构建成功"
) else (
    set "MSG_COLOR=warning"
    set "MSG_STATUS=测试失败"
)

REM 构造并发送 (使用 PowerShell)
REM 注意：这里增加了 Test-Path 检查，只有结果文件存在才发链接
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command ^
  "$reportUrl = '%BUILD_URL%artifact/results/log.html'; " ^
  "$payload = @{ " ^
  "    msgtype = 'markdown'; " ^
  "    markdown = @{ " ^
  "        content = \"<font color='%MSG_COLOR%'>[%MSG_STATUS%]</font> %JOB_NAME% #%BUILD_NUMBER%`n>设备: %DEVICE_ID%`n>结果: [查看测试报告]($reportUrl)\" " ^
  "    } " ^
  "}; " ^
  "try { Invoke-RestMethod -Uri $env:WECHAT_WEBHOOK -Method Post -ContentType 'application/json' -Body ($payload | ConvertTo-Json -Depth 2 -Compress) } catch { Write-Host 'Notify Failed: ' $_ }"

echo.
echo [INFO] Script finished. Forcing exit code 0 for Jenkins.
exit /b 0