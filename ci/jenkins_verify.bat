@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM =========================================================
REM  Jenkins - RobotFramework + Appium (Windows) Verify Script
REM  gentle-fix：保证 robot 一定有 tests 目标参数
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

REM 在 autotest 根目录下，results / tests 就够了
set "RF_OUTPUT_DIR=results"
set "RF_TEST_PATH=tests"

REM ---- 2. 清理旧结果 ----
if exist "%RF_OUTPUT_DIR%" (
    echo [INFO] Cleaning old results...
    rmdir /s /q "%RF_OUTPUT_DIR%"
)
mkdir "%RF_OUTPUT_DIR%"

REM ---- 3. ADB 检查 ----
echo [INFO] Checking ADB path: "%ADB_CMD%"
if not exist "%ADB_CMD%" (
    echo [ERROR] ADB not found at "%ADB_CMD%". Please check ANDROID_HOME.
    exit /b 1
)

echo [INFO] Checking connected devices...
"%ADB_CMD%" devices

REM ---- 4. 启动 Appium ----
echo [INFO] Starting Appium on port %APPIUM_PORT%...
start "AppiumServer" /MIN cmd /c "\"%APPIUM_CMD%\" -p %APPIUM_PORT% --log-level error > \"%WORKSPACE%\appium.log\" 2>&1"
timeout /t 10 /nobreak >nul

REM ---- 5. 运行 Robot ----
echo.
echo ====== RUNNING ROBOT FRAMEWORK TESTS ======

where robot >nul 2>&1
if %ERRORLEVEL% equ 0 (
    set "ROBOT_EXEC=robot"
) else (
    echo [WARN] 'robot' command not found in PATH, trying 'python -m robot'...
    set "ROBOT_EXEC=python -m robot"
)

REM Jenkins 可能传 RF_ARGS（例如：--suite CreateNewProject tests）
REM 温柔兜底：如果没传，就给默认 suite；如果传了但不含 tests，就自动补上 tests
if not defined RF_ARGS (
    set "RF_ARGS=--suite CreateNewProject"
)

echo %RF_ARGS% | findstr /I /C:" %RF_TEST_PATH%" >nul
if errorlevel 1 (
    set "RF_ARGS=%RF_ARGS% %RF_TEST_PATH%"
)

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

REM ---- 7. 关闭 Appium（保持你原来的方式）----
echo.
echo ====== STOP APPIUM ======
taskkill /F /IM node.exe /T >nul 2>&1

exit /b %RF_EXIT%
