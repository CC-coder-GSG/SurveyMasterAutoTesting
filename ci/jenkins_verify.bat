@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

REM =========================================================
REM  Jenkins - RobotFramework + Appium (Windows) Verify Script
REM  gentle-fix v3:
REM    1) 只保留一次端口清理（不用 PowerShell，避免引号坑）
REM    2) Robot 一定带执行目标（默认 tests）
REM    3) results 同步到 WORKSPACE\results，方便归档/通知解析
REM =========================================================

REM ---- 1) 目录与环境 ----
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%.."
set "PROJECT_DIR=%CD%"

REM WORKSPACE fallback (when running locally)
if not defined WORKSPACE (
  for %%I in ("%PROJECT_DIR%\..") do set "WORKSPACE=%%~fI"
)
if not defined BUILD_NUMBER set "BUILD_NUMBER=0"


REM Jenkins 通常会注入 WORKSPACE，这里只做兜底
if not defined WORKSPACE set "WORKSPACE=%PROJECT_DIR%"

REM ANDROID_HOME
if not defined ANDROID_HOME set "ANDROID_HOME=D:\android-sdk"
set "ADB_CMD=%ANDROID_HOME%\platform-tools\adb.exe"

REM Appium
if not defined NPM_BIN set "NPM_BIN=C:\Users\Administrator\AppData\Roaming\npm"
set "APPIUM_CMD=%NPM_BIN%\appium.cmd"
if not defined APPIUM_PORT set "APPIUM_PORT=4723"

REM Ensure npm global bin is on PATH (for appium.cmd)
set "PATH=%NPM_BIN%;%PATH%"

REM Optional: if you installed Node.js somewhere else, set NODEJS_HOME to that folder (containing node.exe)
if defined NODEJS_HOME set "PATH=%NODEJS_HOME%;%PATH%"

REM Try common Node.js install paths if node not found
where node >nul 2>&1
if errorlevel 1 (
  if exist "C:\Program Files\nodejs\node.exe" set "PATH=C:\Program Files\nodejs;%PATH%"
  if exist "C:\Program Files (x86)\nodejs\node.exe" set "PATH=C:\Program Files (x86)\nodejs;%PATH%"
)


REM Robot 输出与测试目录（在 autotest 根目录下）
set "RF_OUTPUT_DIR=results"
set "RF_TEST_PATH=tests"

REM Jenkins 可以传 RF_ARGS（建议只传选项，不要带 tests）
if not defined RF_ARGS set "RF_ARGS=--suite CreateNewProject"

REM python/robot 执行器选择：优先用 venv（如果存在）
set "PYTHON_EXE=python"
if exist ".venv\Scripts\python.exe" set "PYTHON_EXE=.venv\Scripts\python.exe"

where robot >nul 2>&1
if %ERRORLEVEL% equ 0 (
  set "ROBOT_EXEC=robot"
) else (
  set "ROBOT_EXEC=%PYTHON_EXE% -m robot"
)

REM ---- 2) 清理旧结果（避免读到上次残留 output.xml）----
if exist "%RF_OUTPUT_DIR%" (
  echo [INFO] Cleaning old "%RF_OUTPUT_DIR%" ...
  rmdir /s /q "%RF_OUTPUT_DIR%"
)
mkdir "%RF_OUTPUT_DIR%"

REM WORKSPACE\results 也清一下，避免企业微信解析到旧 output.xml
if exist "%WORKSPACE%\results" (
  echo [INFO] Cleaning old "%WORKSPACE%\results" ...
  rmdir /s /q "%WORKSPACE%\results"
)
mkdir "%WORKSPACE%\results"

REM ---- 3) 工具检查 ----
echo [INFO] Checking ADB: "%ADB_CMD%"
if not exist "%ADB_CMD%" (
  echo [ERROR] ADB not found: "%ADB_CMD%"
  exit /b 1
)

echo [INFO] Checking Appium: "%APPIUM_CMD%"
if not exist "%APPIUM_CMD%" (
  echo [ERROR] appium.cmd not found: "%APPIUM_CMD%"
  exit /b 1
)
REM ---- Versions (debug) ----
where node >nul 2>&1 || (echo [ERROR] node not found in PATH. Install Node.js or fix PATH. & exit /b 2)
for /f "delims=" %%v in ('node -v 2^>^&1') do echo [INFO] Node=%%v
for /f "delims=" %%v in ('cmd /c ""%APPIUM_CMD%" -v" 2^>^&1') do echo [INFO] Appium=%%v


REM ---- 4) 一次端口清理（只杀占用 4723 的 PID）----
echo.
echo ====== CLEAN PORT %APPIUM_PORT% (if occupied) ======
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /R /C:":%APPIUM_PORT% .*LISTENING"') do (
  echo [INFO] Killing PID %%p on port %APPIUM_PORT% ...
  taskkill /F /PID %%p >nul 2>&1
)
echo [INFO] Port check done.

REM ---- 5) 启动 Appium ----
echo.
echo ====== START APPIUM ======
REM 关键：用 cmd /c 才能稳定处理重定向
start "AppiumServer" /MIN cmd /c ""%APPIUM_CMD%" -a 127.0.0.1 -p %APPIUM_PORT% --session-override --log-level error > "%WORKSPACE%\appium.log" 2>&1"

REM 等待端口监听（最多 30 秒）
set "APPIUM_READY="
for /l %%i in (1,1,30) do (
  netstat -ano | findstr /R /C:":%APPIUM_PORT% .*LISTENING" >nul && set "APPIUM_READY=1" && goto :APPIUM_OK
  timeout /t 1 /nobreak >nul
)
:APPIUM_OK
if not defined APPIUM_READY (
  echo [ERROR] Appium not listening on %APPIUM_PORT%. Check "%WORKSPACE%\appium.log"
  echo ------ appium.log (tail 80) ------
  powershell -NoProfile -Command "if (Test-Path \"%WORKSPACE%\\appium.log\") { Get-Content -Path \"%WORKSPACE%\\appium.log\" -Tail 80 } else { Write-Host \"[WARN] appium.log not found\" }"
  echo -------------------------------
  exit /b 2
)

REM ---- 6) 运行 Robot（保证至少有 1 个执行目标参数）----
echo.
echo ====== RUNNING ROBOT FRAMEWORK TESTS ======

REM 校验 tests 目录存在
if not exist "%RF_TEST_PATH%" (
  echo [ERROR] Robot test path not found: "%CD%\%RF_TEST_PATH%"
  echo [HINT] 当前目录=%CD%
  dir
  exit /b 2
)

REM 判断 RF_ARGS 里是否已经包含 tests（避免重复传两个目标）
set "HAS_TARGET=0"
for %%A in (%RF_ARGS%) do (
  if /I "%%~A"=="%RF_TEST_PATH%" set "HAS_TARGET=1"
)

set "TARGET_ARG="
if "%HAS_TARGET%"=="0" set "TARGET_ARG=%RF_TEST_PATH%"

echo Executing: %ROBOT_EXEC% -d "%RF_OUTPUT_DIR%" %RF_ARGS% --variable UDID:%DEVICE_ID% %TARGET_ARG%
%ROBOT_EXEC% -d "%RF_OUTPUT_DIR%" %RF_ARGS% --variable UDID:%DEVICE_ID% %TARGET_ARG%

set "RF_EXIT=%ERRORLEVEL%"
echo Robot exit code=%RF_EXIT%

REM ---- 7) 失败时导出 logcat ----
if not "%RF_EXIT%"=="0" (
  echo.
  echo ====== EXPORT LOGCAT (FAILED) ======
  "%ADB_CMD%" -s %DEVICE_ID% logcat -d -v time -b all -t 3000 > "%WORKSPACE%\logcat_%BUILD_NUMBER%.txt"
  echo Saved: %WORKSPACE%\logcat_%BUILD_NUMBER%.txt
)

REM ---- 8) 结果同步到 WORKSPACE\results ----
echo.
echo ====== SYNC RESULTS TO WORKSPACE ======
robocopy "%CD%\%RF_OUTPUT_DIR%" "%WORKSPACE%\results" /E /NFL /NDL /NJH /NJS /NC /NS >nul
set "RC=%ERRORLEVEL%"
if %RC% GEQ 8 (
  echo [WARN] robocopy failed with code %RC% (will continue)
) else (
  echo [OK] Results synced: "%WORKSPACE%\results"
)

REM ---- 9) 关闭 Appium（只杀占用端口的 PID）----
echo.
echo ====== STOP APPIUM ======
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /R /C:":%APPIUM_PORT% .*LISTENING"') do (
  taskkill /F /PID %%p >nul 2>&1
)

exit /b %RF_EXIT%