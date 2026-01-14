@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM =========================================================
REM  Jenkins - RobotFramework + Appium (Windows) Verify Script
REM  修复版 v3（路径修复 + 去掉 -x output.xml）
REM =========================================================

REM ---- 1. 路径与环境配置 ----
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%.."

if not defined WORKSPACE set "WORKSPACE=%CD%"
if not defined ANDROID_HOME set "ANDROID_HOME=D:\android-sdk"
set "ADB_CMD=%ANDROID_HOME%\platform-tools\adb.exe"

if not defined NPM_BIN set "NPM_BIN=C:\Users\Administrator\AppData\Roaming\npm"
set "APPIUM_CMD=%NPM_BIN%\appium.cmd"
if not defined APPIUM_PORT set "APPIUM_PORT=4723"

set "POWERSHELL_EXE=C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"

REM 关键修复：你已经在 workspace\...\autotest 目录里了，不要再写 autotest\xxx
set "RF_OUTPUT_DIR=results"
set "RF_TEST_PATH=tests"

REM 如果 Jenkins 没传 RF_ARGS，给一个默认（Jenkins 里你一般传：--suite CreateNewProject tests）
if not defined RF_ARGS set "RF_ARGS=--suite CreateNewProject %RF_TEST_PATH%"

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

REM ---- 4. 启动 Appium（修正 start 引号，避免乱码/语法异常）----
echo [INFO] Starting Appium on port %APPIUM_PORT%...
start "AppiumServer" /MIN cmd /c "\"%APPIUM_CMD%\" -p %APPIUM_PORT% --log-level error > \"%WORKSPACE%\appium.log\" 2>&1"

timeout /t 10 /nobreak >nul

REM ---- 5. 运行 Robot Framework 测试 ----
echo.
echo ====== RUNNING ROBOT FRAMEWORK TESTS ======

where robot >nul 2>&1
if %ERRORLEVEL% equ 0 (
    set "ROBOT_EXEC=robot"
) else (
    echo [WARN] 'robot' command not found in PATH, trying 'python -m robot'...
    set "ROBOT_EXEC=python -m robot"
)

REM 关键修复：不要用 -x output.xml（那是 xUnit 导出，会影响统计解析）
echo Executing: %ROBOT_EXEC% -d "%RF_OUTPUT_DIR%" %RF_ARGS% --variable UDID:%DEVICE_ID%
%ROBOT_EXEC% -d "%RF_OUTPUT_DIR%" %RF_ARGS% --variable UDID:%DEVICE_ID%

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

REM ---- 8. 结果同步（把 autotest\results -> WORKSPACE\results）----
echo.
echo ====== SYNC RESULTS TO WORKSPACE ======
if not exist "%WORKSPACE%\results" mkdir "%WORKSPACE%\results"

robocopy "%CD%\%RF_OUTPUT_DIR%" "%WORKSPACE%\results" /E /NFL /NDL /NJH /NJS /NC /NS >nul
set "RC=%ERRORLEVEL%"
if %RC% GEQ 8 (
    echo [WARN] robocopy failed with code=%RC%
) else (
    echo [OK] Results synced.
)

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

"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command ^
  "$reportUrl = '%BUILD_URL%artifact/results/log.html'; " ^
  "$payload = @{ msgtype='markdown'; markdown=@{ content = \"<font color='%MSG_COLOR%'>[%MSG_STATUS%]</font> %JOB_NAME% #%BUILD_NUMBER%`n>设备: %DEVICE_ID%`n>结果: [查看测试报告]($reportUrl)\" } }; " ^
  "try { Invoke-RestMethod -Uri $env:WECHAT_WEBHOOK -Method Post -ContentType 'application/json' -Body ($payload | ConvertTo-Json -Depth 4 -Compress) } catch { Write-Host 'Notify Failed: ' $_ }"

REM 建议：让 Jenkins 状态真实反映测试结果（不要强制 exit 0）
exit /b %RF_EXIT%
