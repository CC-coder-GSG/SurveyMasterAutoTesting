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
set "APPIUM_URL=http://%APPIUM_HOST%:%APPIUM_PORT%"
set "APPIUM_LOG=%WORKSPACE%\appium.log"

REM 设备ID（Jenkins 传 DEVICE_ID；没传就用默认）
if not defined DEVICE_ID set "DEVICE_ID=4e83cae7"

REM 你要跑的 Suite 名（Jenkins 可传 RF_SUITE；没传默认 CreateNewProject）
if not defined RF_SUITE set "RF_SUITE=CreateNewProject"
if not defined RF_ROOT  set "RF_ROOT=tests"
if not defined RF_OUTPUT_DIR set "RF_OUTPUT_DIR=results"

REM ---- 1) 修复 Jenkins 环境 PATH ----
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
echo DEVICE_ID=%DEVICE_ID%
echo RF_SUITE=%RF_SUITE%
echo RF_ROOT=%RF_ROOT%
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

REM ---- 2) 只保留一次：启动前清理 4723 端口 ----
echo ====== CLEAN PORT %APPIUM_PORT% (if occupied) ======
set "OLD_PID="
REM 关键修复：PowerShell 管道符 | 在 bat 的 for /f 命令替换里必须写成 ^|
for /f "delims=" %%P in ('"%POWERSHELL_EXE%" -NoProfile -Command "(Get-NetTCPConnection -LocalPort %APPIUM_PORT% -State Listen -ErrorAction SilentlyContinue ^| Select-Object -First 1 -ExpandProperty OwningProcess)"') do set "OLD_PID=%%P"
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
start "" /B cmd /c ""%APPIUM_CMD%" --address %APPIUM_HOST% --port %APPIUM_PORT% --log "%APPIUM_LOG%""


REM ---- 4) 等待 Appium 就绪（最多 30 秒）----
echo ====== WAIT APPIUM READY ======
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$u='%APPIUM_URL%/status'; for($i=0;$i -lt 30;$i++){ try{ $r=Invoke-WebRequest -UseBasicParsing $u -TimeoutSec 2; if($r.StatusCode -ge 200){ exit 0 } }catch{}; Start-Sleep -Seconds 1 }; exit 1"
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

REM 关键：用命令行变量覆盖 env_test.yaml 里的 UDID/DEVICE_NAME（避免写死跑错设备）
python -m robot -d "%RF_OUTPUT_DIR%" ^
  --variable DEVICE_NAME:%DEVICE_ID% ^
  --variable UDID:%DEVICE_ID% ^
  --suite "%RF_SUITE%" "%RF_ROOT%"

set "RF_EXIT=%ERRORLEVEL%"
echo Robot exit code=%RF_EXIT%
echo.

REM ---- 6.1) 失败时导出 logcat ----
if not "%RF_EXIT%"=="0" (
  echo ====== EXPORT LOGCAT (FAILED) ======
  adb -s %DEVICE_ID% logcat -d -v time -b all -t 3000 > "%WORKSPACE%\logcat_%BUILD_NUMBER%.txt"
  echo Saved: %WORKSPACE%\logcat_%BUILD_NUMBER%.txt
  echo.
)

REM ---- 7) 同步结果到 WORKSPACE\results（保证 wecom_notify.ps1 能读到 output.xml）----
echo ====== SYNC RESULTS TO %WORKSPACE%\results ======
if not exist "%WORKSPACE%\results" mkdir "%WORKSPACE%\results"
robocopy "%CD%\%RF_OUTPUT_DIR%" "%WORKSPACE%\results" /E /NFL /NDL /NJH /NJS /NC /NS >nul
set "RC=%ERRORLEVEL%"
if %RC% GEQ 8 (
  echo [WARN] robocopy sync results failed, code=%RC%
) else (
  echo [OK] Results synced to %WORKSPACE%\results
)
REM 清掉 robocopy 的 errorlevel（robocopy=1/2/3 在 Jenkins/脚本里经常被当失败）
cmd /c exit /b 0
echo.

REM ---- 8) 企业微信群通知 ----
if defined WECHAT_WEBHOOK (
  "%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass ^
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

REM ---- 9) 不再在 bat 里二次按端口杀 Appium（只保留一次端口清理）----
REM Jenkinsfile post 里你有 Stop-Process -Name node，会兜底清掉 Appium
exit /b %RF_EXIT%
