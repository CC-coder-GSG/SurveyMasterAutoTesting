# SurveyMaster 自动化测试

测量大师（SurveyMaster）Android App 的 UI 自动化测试项目。项目基于 Robot Framework、Appium 和 UiAutomator2，当前用于核心导航冒烟测试、项目业务回归测试，以及设备连接稳定性验证。

被测应用包名：`com.sinognss.sm.free`

## 技术栈

| 组件 | 用途 | 当前版本/要求 |
| --- | --- | --- |
| Python | Robot Framework 运行环境 | 3.8+（Jenkins 当前使用 3.14） |
| Robot Framework | 测试编排与报告生成 | 7.4 |
| AppiumLibrary | Robot Framework 的 Appium 适配层 | 3.2.1 |
| Appium | Android 自动化服务 | 2.x（CI 固定为 2.19.0） |
| UiAutomator2 | Android 自动化驱动 | CI 固定为 4.1.5 |
| ADB | 设备连接、权限及应用管理 | 随 Android SDK 安装 |

## 项目结构

```text
SurveyMasterAutoTesting/
├── tests/
│   ├── __init__.robot             # 公共 Suite Setup/Teardown
│   ├── smoke/                     # 快速、低依赖的冒烟测试
│   └── regression/                # 完整业务及稳定性回归测试
├── resources/
│   ├── keywords/
│   │   ├── common/                # 点击、等待、断言、会话等原子能力
│   │   ├── pages/                 # 单页面操作
│   │   └── flows/                 # 跨页面业务流程
│   ├── locators/android/          # Android 元素定位器
│   └── variables/env_test.yaml    # 本地设备与 Appium 配置（不提交）
├── scripts/                       # 本地 Appium 辅助脚本
├── ci/                            # Jenkins 流水线及通知脚本
├── docs/                          # 规范、计划和验证记录
├── requirements.txt
└── README.md
```

调用关系遵循：

```text
tests → flows → pages → common + locators → Appium → Android 设备
```

## 环境准备

运行前请准备：

- Windows 测试机；
- Python 3.8 或更高版本；
- Node.js 和 npm；
- Java JDK；
- Android SDK，并确保 `adb` 已加入 `PATH`；
- 已开启 USB 调试的 Android 真机；
- 已安装待测 SurveyMaster APK。

### 1. 安装 Python 依赖

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

### 2. 安装 Appium 和 Android 驱动

为尽量与 CI 保持一致，推荐使用以下版本：

```powershell
npm install --global appium@2.19.0
appium driver install uiautomator2@4.1.5
appium driver list --installed
```

### 3. 检查设备

```powershell
adb devices
```

设备状态应为 `device`。如果同时连接多台设备，必须在配置中填写目标设备的准确 UDID。

## 本地配置

新建 `resources/variables/env_test.yaml`。该文件已被 `.gitignore` 排除，请勿提交个人设备号或环境信息。

```yaml
APPIUM_SERVER: "http://127.0.0.1:4723"
PLATFORM_NAME: "Android"
PLATFORM_VERSION: "12"
AUTOMATION_NAME: "UiAutomator2"
DEVICE_NAME: "your-device-id"
UDID: "your-device-id"
APP_PACKAGE: "com.sinognss.sm.free"
APP_ACTIVITY: "com.sinognss.sm.guide.ui.GuideActivity"
APP_WAIT_ACTIVITY: "*"
NO_RESET: true
AUTO_GRANT_PERMISSIONS: true
NEW_COMMAND_TIMEOUT: 120
UNICODE_KEYBOARD: true
RESET_KEYBOARD: true
IGNORE_HIDDEN_API_POLICY_ERROR: true
SKIP_DEVICE_INITIALIZATION: false
```

`UDID` 可从 `adb devices` 获取；`PLATFORM_VERSION` 可通过下面的命令确认：

```powershell
adb -s your-device-id shell getprop ro.build.version.release
```

## 运行测试

### 1. 启动 Appium

```powershell
scripts\start_appium.bat
```

脚本默认监听 `127.0.0.1:4723`。测试结束后可在该终端按 `Ctrl+C` 停止服务。

### 2. 执行用例

推荐先做静态检查：

```powershell
python -m robot --dryrun --output NONE --log NONE --report NONE tests
```

执行核心导航冒烟测试：

```powershell
python -m robot -d results --suite Tests.smoke.CoreNavigationSmoke tests
```

执行带 `smoke` 标签、且不依赖硬件或网络的用例：

```powershell
python -m robot -d results --include smoke --exclude hardware --exclude network tests
```

执行全部测试：

```powershell
python -m robot -d results tests
```

> 注意：执行单个普通用例时，应从 `tests` 根目录通过 `--suite` 选择套件。这样才能加载 `tests/__init__.robot` 中统一定义的 Appium 会话和清理逻辑。

## 当前用例

| 用例 | 类型 | 说明 |
| --- | --- | --- |
| `tests/smoke/CoreNavigationSmoke.robot` | 冒烟 | 只读巡检项目、设备、测量和工具四个主模块；本地首选 |
| `tests/smoke/_sanity_open_app.robot` | 连通性检查 | 独立启动 App；文件名前缀为 `_`，默认测试发现会忽略，且当前含历史硬编码设备配置 |
| `tests/regression/NewProject/CreateNewProject.robot` | 回归 | 创建新项目，会写入业务数据 |
| `tests/regression/NewProject/LuoWangConnectFail.robot` | 稳定性 | 循环连接司南万象，依赖真实蓝牙设备、网络并包含设备重启操作 |

不要在不了解前置条件时直接执行全部测试，特别是涉及数据写入、外部硬件和设备重启的回归用例。

## 测试报告

指定 `-d results` 后，Robot Framework 会在 `results/` 下生成：

- `report.html`：测试结果总览；
- `log.html`：步骤日志与失败详情；
- `output.xml`：供 Robot Framework、Jenkins 或其他工具解析的原始结果；
- 失败截图：由全局 teardown 在失败时采集。

本地排查失败时，建议按 `report.html` → `log.html` → 失败截图 → Appium 控制台日志的顺序查看。

## 编写与维护约定

- `tests` 只描述业务目标、前置条件和断言，不直接写定位器或 Appium 原子操作；
- `flows` 负责组合跨页面业务流程；
- `pages` 只封装单个页面内的行为；
- `common` 提供通用点击、输入、等待、断言和会话能力；
- 所有 Android 定位器集中维护在 `resources/locators/android/`；
- 优先使用条件等待，避免用固定 `Sleep` 驱动流程；
- 每条用例至少包含一个核心断言，并保证失败时有可诊断信息；
- 本地运行始终指定输出目录，避免在仓库根目录生成报告文件。

详细规则请阅读：

- [项目结构与脚本编写指南](docs/project-structure-and-script-guide.md)
- [Robot Framework + Appium 编码规约](docs/conventions.md)
- [Jenkins 冒烟测试验证记录](docs/jenkins_smoke_validation.md)
- [下一阶段建设计划](docs/next-stage-plan.md)

## Jenkins 执行

Jenkins 流水线定义位于 `ci/ci_piplines`，执行器为 `ci/jenkins_verify.bat`。流水线会完成 APK 获取与安装、测试代码检出、本地配置生成、Appium 启停、指定 Robot 用例执行及报告归档。

CI 通过 `TEST_ROBOTS` 选择 `tests/` 下的用例文件，并通过 `DEVICE_ID`、`APP_PACKAGE`、`APP_ACTIVITY` 等参数生成本次构建专用的 `env_test.yaml`。修改流水线或执行器时，请同时参考 [Jenkins 冒烟测试验证记录](docs/jenkins_smoke_validation.md)。

## 常见问题

### Appium 无法创建会话

依次确认：Appium 已启动、UiAutomator2 已安装、配置端口一致、UDID 正确、设备状态为 `device`，且 APK 包名和 Activity 与当前安装包一致。

### 找不到 `env_test.yaml`

按“本地配置”章节创建该文件。它是本机或 CI 动态配置，不由 Git 跟踪。

### PowerShell 不允许激活虚拟环境

可以不激活虚拟环境，直接使用：

```powershell
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe -m robot -d results --suite Tests.smoke.CoreNavigationSmoke tests
```

### 用例能找到但没有建立 Appium 会话

不要直接把普通 `.robot` 文件作为唯一测试源执行；请以 `tests` 为测试源，并使用 `--suite` 筛选目标套件，以加载父级 `tests/__init__.robot`。
