# Robot Framework + Appium 新人培训手册

> 适用项目：测量大师（SurveyMaster）Android UI 自动化测试  
> 适用对象：第一次接触 Robot Framework、Appium 或移动端 UI 自动化的测试与开发人员  
> 建议培训时长：90～120 分钟（讲解 60～75 分钟，实操 30～45 分钟）  
> 文档基线：以当前仓库的代码和依赖版本为准

## 1. 培训目标

完成本次培训后，学员应当能够：

1. 用自己的话说明 Robot Framework、Appium、AppiumLibrary 和 UiAutomator2 各自负责什么；
2. 看懂一个基础的 `.robot` 测试用例和 `.resource` 资源文件；
3. 理解本项目 `tests → flows → pages → common/locators` 的分层结构；
4. 在 Android 真机上启动 Appium，并运行现有冒烟用例；
5. 知道如何定位元素、等待页面、添加断言和查看测试报告；
6. 遇到失败时，能判断问题大致发生在哪一层。

## 2. 先用一句话认识整套技术

- **Robot Framework**：负责描述“测试要做什么”、组织用例、执行步骤并生成报告。
- **AppiumLibrary**：把 Robot Framework 中的 `Click Element`、`Input Text` 等关键字转换成 Appium 客户端请求。
- **Appium Server**：接收自动化请求，并把请求交给对应平台的驱动。
- **UiAutomator2 Driver**：把 Appium 命令转换成 Android 设备真正能执行的操作。
- **ADB**：连接和管理 Android 设备，也为部分底层能力提供支持。
- **测量大师 App**：被测试的对象，包名为 `com.sinognss.sm.free`。

可以把它们类比成一个团队：

| 角色 | 类比 | 在本项目中的职责 |
| --- | --- | --- |
| Robot Framework | 测试导演 | 安排场景、步骤和验收标准 |
| AppiumLibrary | 翻译 | 把 Robot 关键字翻译成 Appium 调用 |
| Appium Server | 调度中心 | 接收请求、维护会话、分发命令 |
| UiAutomator2 | Android 操作员 | 在手机上查找控件、点击、输入和读取状态 |
| 测量大师 App | 被验收的产品 | 接收真实 UI 操作并呈现结果 |

一次点击的完整链路如下：

```text
测试用例
  ↓ 调用业务关键字
flows（跨页面流程）
  ↓ 调用页面关键字
pages（单页面动作）
  ↓ 调用 common，并引用 locator
AppiumLibrary
  ↓ WebDriver HTTP 请求
Appium Server
  ↓ 选择 automationName=UiAutomator2
UiAutomator2 Driver + ADB
  ↓
Android 真机上的测量大师 App
```

这条链路也是排错地图：上层负责业务表达，下层负责真正操作设备。

## 3. Robot Framework 入门

### 3.1 Robot Framework 是什么

Robot Framework 是一个开源、通用、与具体应用技术解耦的自动化框架。它采用容易阅读的表格化语法，通过“关键字”组织测试。框架核心负责读取测试数据、执行用例、生成日志和报告；具体怎样操作被测系统，由 SeleniumLibrary、AppiumLibrary 等扩展库完成。

Robot Framework 不只是“录制点击”的工具。它更像一个测试执行平台，负责：

- 测试套件和测试用例的组织；
- setup、teardown 和标签管理；
- 变量、条件、循环和用户关键字；
- 断言结果统计；
- 生成 `output.xml`、`log.html` 和 `report.html`。

### 3.2 关键字驱动是什么

关键字可以理解为“带名字、可重复调用的测试动作”。

例如：

```robotframework
Open Tools Tab
Tools Home Should Be Ready
```

新人不需要先知道底层坐标或 HTTP 请求，只需要理解：

- `Open Tools Tab`：进入工具页；
- `Tools Home Should Be Ready`：验证工具页已经正常加载。

这些业务关键字内部还可以调用更底层的关键字：

```robotframework
Open Tools Tab
    Tap    ${Home.TOOLS_TAB}
```

这里：

- `Open Tools Tab` 是项目自己定义的页面关键字；
- `Tap` 是项目封装的通用动作；
- `${Home.TOOLS_TAB}` 是工具页签的定位器变量；
- `Tap` 内部最终调用 AppiumLibrary 的 `Click Element`。

这就是“高层关键字组合低层关键字”。AppiumLibrary 官方也建议使用易读、易维护的高层业务关键字包装底层操作关键字。

### 3.3 Robot 文件的四个常用区块

Robot Framework 的文件通常由以下区块组成。列与列之间使用**两个或更多空格**分隔，本项目统一使用 4 个空格。

```robotframework
*** Settings ***
Documentation    示例套件
Library          AppiumLibrary
Resource         ../resources/example.resource

*** Variables ***
${TIMEOUT}        10s
${PROJECT_NAME}   自动化测试项目

*** Test Cases ***
工具页应当可以打开
    Open Tools Tab
    Tools Home Should Be Ready

*** Keywords ***
Open And Check Tools
    Open Tools Tab
    Tools Home Should Be Ready
```

| 区块 | 用途 | 本项目常见内容 |
| --- | --- | --- |
| `*** Settings ***` | 导入库和资源，设置文档、标签及前后置 | `Library`、`Resource`、`Suite Setup`、`Test Tags` |
| `*** Variables ***` | 定义可复用数据 | 超时、文本、定位器字典 |
| `*** Test Cases ***` | 定义可执行测试 | Given / When / Then 业务步骤 |
| `*** Keywords ***` | 定义项目自己的关键字 | 页面动作、业务流程、通用能力 |

资源文件通常使用 `.resource` 后缀，测试套件通常使用 `.robot` 后缀。两者语法相同，但职责不同：`.robot` 放可执行测试，`.resource` 放供其他文件复用的变量和关键字。

### 3.4 常见变量

```robotframework
${NAME}       测量大师          # 标量：一个值
@{TABS}       项目    设备    测量    工具    # 列表：一组值
&{DEVICE}     platform=Android    udid=xxx   # 字典：键值对
```

本项目的定位器大量使用字典：

```robotframework
&{Home}
...    BOTTOM_NAVIGATION=id=com.sinognss.sm.free:id/nav_bar
...    BACK_BUTTON=accessibility_id=返回
```

引用时写成 `${Home.BOTTOM_NAVIGATION}`。Robot Framework 的 `${变量名}` 标量语法会把变量替换为其实际值。

### 3.5 Library、Resource 和 Variables 的区别

```robotframework
Library    AppiumLibrary
Resource   ../common/actions.resource
Variables  ../../variables/env_test.yaml
```

- `Library`：导入 Python 测试库，获得它提供的关键字；
- `Resource`：导入另一个 Robot 资源文件，复用其中的关键字和变量；
- `Variables`：导入变量文件，本项目用 YAML 保存设备和会话配置。

### 3.6 Setup、Teardown 和断言

- **Setup**：测试前准备，例如打开 App、处理权限、准备数据；
- **Teardown**：测试后收尾，例如失败截图、恢复状态、关闭会话；
- **断言**：比较实际结果和预期结果，是判断用例通过或失败的依据。

本项目在 [`tests/__init__.robot`](../tests/__init__.robot) 中统一定义：

```robotframework
Suite Setup     Open App And Handle Permissions
Suite Teardown  Close SurveyMaster App
Test Teardown   Global Test Teardown
```

目录中的 `__init__.robot` 是套件初始化文件。执行 `tests` 目录时，它会为子套件建立和关闭 Appium 会话。因此，运行普通用例时应把 `tests` 作为测试源，再用 `--suite` 或标签筛选；直接执行某个文件可能绕过父套件初始化。

每条测试至少要有一个有业务意义的断言。“所有点击都没有报错”不等于“功能正确”。例如，进入工具页后应验证工具页的稳定标志元素可见。

### 3.7 Given / When / Then

本项目使用接近自然语言的 Given / When / Then 风格：

```robotframework
*** Test Cases ***
Core Navigation Should Be Available
    Given Prepare Core Navigation Smoke
    When Browse All Core Navigation Tabs
    Then Return To Project Home
```

- `Given`：准备前置状态；
- `When`：执行被测试的行为；
- `Then`：验证结果。

它们主要帮助人阅读，不会自动产生测试逻辑。Robot Framework 在匹配关键字时可忽略开头的 `Given`、`When`、`Then`、`And`、`But` 前缀，所以这里实际调用的是 `Prepare Core Navigation Smoke` 等用户关键字。

### 3.8 标签和选择性执行

标签用于表达测试类型、依赖和风险。本项目常见标签包括：

| 标签 | 含义 |
| --- | --- |
| `smoke` | 快速检查核心功能 |
| `regression` | 较完整的业务回归 |
| `read_only` | 不写入业务数据 |
| `hardware` | 依赖或操作外部接收机 |
| `network` | 依赖网络或云端服务 |
| `stability` | 循环或长时间稳定性测试 |

例如，只运行安全的冒烟用例：

```powershell
python -m robot -d results --include smoke --exclude hardware --exclude network tests
```

标签不是备注，而是 CI 和本地运行时选择测试范围的重要接口。

## 4. Appium 入门

### 4.1 Appium 是什么

Appium 是一个开源的 UI 自动化项目和生态。它以 W3C WebDriver 协议为基础，用统一接口连接不同平台的自动化能力。Appium 的主要组成包括：

- **Core**：提供服务器和核心 API；
- **Drivers**：实现特定平台的自动化，例如 Android 的 UiAutomator2；
- **Clients**：在 Python、Java、JavaScript 等语言中发送 Appium 请求；
- **Plugins**：可选地扩展或改变 Appium 功能。

Appium 本身不负责测试用例组织和断言；它负责“自动化操作”。本项目由 Robot Framework 负责测试管理，由 Appium 完成移动端 UI 操作。

### 4.2 为什么还需要 UiAutomator2

Appium Core 不直接知道怎样点击 Android 控件。驱动是平台适配器：

```text
通用 WebDriver 命令 → UiAutomator2 Driver → Android UiAutomator2 / ADB → 手机
```

本项目使用：

```text
platformName = Android
automationName = UiAutomator2
```

`automationName` 告诉 Appium 本次会话应该选择哪个驱动。没有安装 UiAutomator2，Appium 即使能启动，也无法建立本项目的 Android 自动化会话。

### 4.3 Appium 是客户端—服务器结构

Appium Server 是一个持续运行的 HTTP 服务。测试端把“查找元素”“点击元素”等请求发给它，它再调用驱动操作手机。

```text
Robot / AppiumLibrary（客户端）
              ↓ HTTP
      Appium Server :4723
              ↓
       UiAutomator2 Driver
              ↓
          Android 设备
```

因此，执行测试前至少要确认三件事：

1. Appium Server 已启动，地址和端口正确；
2. UiAutomator2 Driver 已安装；
3. Android 设备能被 `adb devices` 识别。

### 4.4 Session 和 Capabilities

**Session（会话）**可以理解为测试代码与某台设备上某个 App 之间的一次控制连接。`Open Application` 创建会话，`Close Application` 关闭会话。

创建会话时需要传入 **Capabilities（会话能力参数）**，告诉 Appium“要控制什么”。本项目在 [`session.resource`](../resources/keywords/common/session.resource) 中使用的主要参数如下：

| 参数 | 作用 | 示例含义 |
| --- | --- | --- |
| `platformName` | 目标平台 | `Android` |
| `automationName` | 使用的 Appium 驱动 | `UiAutomator2` |
| `udid` | 指定目标设备 | 来自 `adb devices` |
| `appPackage` | Android 应用包名 | `com.sinognss.sm.free` |
| `appActivity` | 启动入口 Activity | 测量大师启动页 |
| `appWaitActivity` | 允许等待的 Activity | 本项目使用 `*` |
| `noReset` | 是否保留应用数据和状态 | 本项目默认 `true` |
| `autoGrantPermissions` | 是否自动授予可授予权限 | 本项目默认 `true` |
| `newCommandTimeout` | 多久没有新命令后关闭会话 | 本项目默认 120 秒 |

Capabilities 配错时，最常见的结果是“Appium 已启动，但会话创建失败”。

### 4.5 元素定位器是什么

自动化脚本不能说“点右下角那个按钮”，而要用可重复识别的属性找到元素，这个描述就是 locator（定位器）。

本项目推荐优先级：

1. `accessibility_id`：语义清晰且通常稳定；
2. `id`：Android 的 `resource-id`，稳定且查找快；
3. `android=UiSelector(...)`：需要组合属性时使用；
4. `xpath`：最后选择，层级变化时容易失效，使用时要说明原因。

项目中的真实示例：

```robotframework
${Home.BACK_BUTTON}       accessibility_id=返回
${Home.FEATURE_GRID}      id=com.sinognss.sm.free:id/gv_func
${Home.TOOLS_TAB}         android=new UiSelector().resourceId("com.sinognss.sm.free:id/fixed_bottom_navigation_title").text("工具")
```

不要把屏幕绝对坐标当作常规定位方式。分辨率、横竖屏、系统缩放或页面布局变化都会让坐标失效。

### 4.6 等待比 Sleep 更重要

移动端页面加载时间会受设备性能、动画、蓝牙、网络等因素影响。

```robotframework
Sleep    5s
```

无论页面 0.5 秒还是 8 秒加载完成，这段代码都固定等待 5 秒：前者浪费时间，后者仍会失败。

更可靠的方式是等待一个明确条件：

```robotframework
Wait Visible    ${Home.BOTTOM_NAVIGATION}    30s
Should Be Visible    ${Home.TOOLS_TAB}
```

原则是：等待“页面已经达到什么状态”，而不是猜测“页面大概需要几秒”。

## 5. Robot Framework 与 Appium 如何配合

Robot Framework 本身不认识 Android；Appium 本身也不负责组织测试和生成 Robot 报告。AppiumLibrary 把二者连接起来。

下面是层次对应关系：

| 层次 | 示例 | 回答的问题 |
| --- | --- | --- |
| 测试意图 | `工具页应当可打开` | 要验证什么？ |
| 业务/页面关键字 | `Open Tools Tab` | 用户做什么？ |
| AppiumLibrary 关键字 | `Click Element` | 自动化执行什么动作？ |
| WebDriver 请求 | 查找并点击元素 | 客户端怎样告诉服务器？ |
| UiAutomator2 | Android 原生调用 | 手机怎样真正执行？ |

一个简化示例：

```robotframework
*** Settings ***
Library    AppiumLibrary

*** Test Cases ***
工具入口应当可点击
    Open Application    http://127.0.0.1:4723
    ...    platformName=Android
    ...    automationName=UiAutomator2
    ...    udid=${UDID}
    ...    appPackage=com.sinognss.sm.free
    ...    appActivity=${APP_ACTIVITY}
    Wait Until Element Is Visible    ${TOOLS_TAB}    20s
    Click Element    ${TOOLS_TAB}
    Page Should Contain Element      ${TOOLS_PAGE_MARKER}
    Close Application
```

这个单文件示例适合解释原理，但不应作为本项目新增用例的结构模板。本项目已经把会话、定位器、页面动作和业务流程拆分到各自目录中。

## 6. 测量大师项目结构

### 6.1 当前技术基线

| 组件 | 项目版本/要求 | 用途 |
| --- | --- | --- |
| Robot Framework | `7.4` | 用例编排、执行与报告 |
| AppiumLibrary | `3.2.1` | Robot Framework 的 Appium 适配库 |
| Appium | `2.19.0` | 移动端自动化服务器 |
| UiAutomator2 Driver | `4.1.5` | Android 自动化驱动 |
| PyYAML | `>=6.0` | 读取 YAML 环境变量 |
| ADB | 随 Android SDK 安装 | 连接设备、应用与权限管理 |

> 注意：Appium 官网当前的“latest”文档可能展示 Appium 3。现有项目固定使用 Appium 2.19.0，培训实操和 CI 应保持项目版本，不要在未验证兼容性时直接升级。

### 6.2 目录职责

```text
SurveyMasterAutoTesting/
├── tests/                         # 可执行测试：业务目标和断言
│   ├── __init__.robot             # 公共 Suite Setup / Teardown
│   ├── smoke/                     # 快速、低依赖的冒烟测试
│   └── regression/                # 完整业务及稳定性回归
├── resources/
│   ├── keywords/
│   │   ├── common/                # 点击、输入、等待、断言、会话等原子能力
│   │   ├── pages/                 # 单个页面内的操作和页面校验
│   │   └── flows/                 # 跨页面的业务流程
│   ├── locators/android/          # Android 元素定位器
│   └── variables/env_test.yaml    # 本机/CI 环境配置，不提交个人配置
├── scripts/                       # Appium 启停辅助脚本
├── ci/                            # Jenkins 流水线与通知
├── docs/                          # 项目文档
└── requirements.txt               # Python 依赖版本
```

分层边界可以用四句话记住：

- `tests` 只说“验证什么”；
- `flows` 负责“完整业务怎样走”；
- `pages` 负责“这个页面怎样操作”；
- `common/locators` 提供“怎样点击、等待、断言，以及元素在哪里”。

### 6.3 从真实冒烟用例看执行过程

入口用例是 [`CoreNavigationSmoke.robot`](../tests/smoke/CoreNavigationSmoke.robot)：

```robotframework
*** Test Cases ***
Core Navigation Should Be Available
    Given Prepare Core Navigation Smoke
    When Browse All Core Navigation Tabs
    Then Return To Project Home
```

以“打开工具页”为例：

1. `CoreNavigationSmoke.robot` 调用 `Browse All Core Navigation Tabs`；
2. [`MainNavigationSmoke.resource`](../resources/keywords/flows/MainNavigationSmoke.resource) 编排项目、设备、测量和工具的巡检顺序；
3. [`Home.resource`](../resources/keywords/pages/Home.resource) 的 `Open Tools Tab` 调用通用 `Tap`；
4. 页面文件引用 [`locators/android/Home.resource`](../resources/locators/android/Home.resource) 中的 `${Home.TOOLS_TAB}`；
5. `Tap` 先等待元素可见，再调用 AppiumLibrary 的 `Click Element`；
6. Appium Server 把点击命令交给 UiAutomator2；
7. 后续页面关键字验证工具页的稳定元素，从而形成断言。

任何页面改版时，通常先修改 locator 或 page；业务路径变化时，通常修改 flow；验收目标变化时，才修改 test。这种分层能减少重复修改。

## 7. 第一次运行项目

### 7.1 准备环境

需要：

- Windows 测试机；
- Python 和项目虚拟环境；
- Node.js 与 npm；
- Java JDK；
- Android SDK，且 `adb` 可用；
- 开启 USB 调试的 Android 真机；
- 已安装待测测量大师 APK。

安装 Python 依赖：

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

安装与项目一致的 Appium 和驱动：

```powershell
npm install --global appium@2.19.0
appium driver install uiautomator2@4.1.5
appium driver list --installed
```

检查工具和设备：

```powershell
python --version
robot --version
appium --version
adb devices
```

`adb devices` 中目标设备的状态应为 `device`。若显示 `unauthorized`，需要解锁手机并确认 USB 调试授权。

### 7.2 创建本地环境配置

按项目 [`README.md`](../README.md) 的“本地配置”章节创建 `resources/variables/env_test.yaml`。示例：

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

设备号可通过 `adb devices` 获取。这个文件包含本机环境信息，已被 Git 忽略，不应提交个人设备号、账号、密码或 Token。

### 7.3 启动 Appium

在一个单独的终端运行：

```powershell
scripts\start_appium.bat
```

看到 Appium 监听 `127.0.0.1:4723` 后保持该终端运行。当前脚本使用 Appium 2 默认根路径，因此本项目地址是 `http://127.0.0.1:4723`，不需要额外添加 `/wd/hub`。

### 7.4 先做静态检查

```powershell
python -m robot --dryrun --output NONE --log NONE --report NONE tests
```

`--dryrun` 会检查 Robot 语法、资源导入和关键字是否存在，但不会真正点击手机。它不能证明 locator、设备连接或业务结果正确。

### 7.5 运行核心冒烟用例

```powershell
python -m robot -d results --suite Tests.smoke.CoreNavigationSmoke tests
```

推荐从 `tests` 根套件启动，以加载 `tests/__init__.robot` 中的公共会话和清理逻辑。

测试完成后打开：

- `results/report.html`：结果总览，先看哪些套件或用例失败；
- `results/log.html`：逐关键字执行详情，定位失败步骤；
- `results/output.xml`：机器可读的原始结果，供 Robot、Jenkins 等工具继续处理；
- 失败截图：查看失败时手机实际显示的页面。

## 8. 怎样新增一条用例

新增脚本建议按“业务目标 → locator → page → flow → test”的顺序进行。

### 第一步：写清楚业务目标

先回答：

- 前置状态是什么？
- 用户执行什么动作？
- 哪个可观察结果证明功能正确？
- 是否依赖网络、接收机、账号或已有数据？
- 测试产生的数据怎样清理？

例如：“从项目主页进入工具页后，坐标计算入口应可见。”

### 第二步：采集并集中保存 locator

在 `resources/locators/android/` 对应页面文件中添加定位器：

```robotframework
&{Tools}
...    COORDINATE_CALCULATION=id=com.sinognss.sm.free:id/coordinate_calculation
```

优先使用稳定且唯一的属性，并注释定位来源和风险。不要把 locator 直接散落在 test 或 flow 中。

### 第三步：在 page 层封装页面行为

```robotframework
Open Coordinate Calculation
    [Documentation]    在工具主页进入坐标计算。
    Tap    ${Tools.COORDINATE_CALCULATION}

Coordinate Calculation Entry Should Be Visible
    [Documentation]    验证工具主页的坐标计算入口可见。
    Should Be Visible    ${Tools.COORDINATE_CALCULATION}
```

### 第四步：需要跨页面时再写 flow

```robotframework
Open Coordinate Calculation From Project Home
    Open Tools Tab
    Tools Home Should Be Ready
    Open Coordinate Calculation
```

如果操作只发生在一个页面内，不必为了分层而强行创建 flow。

### 第五步：在 test 层表达验收目标

```robotframework
*** Settings ***
Resource    ../../resources/keywords/pages/Tools/ToolsHome.resource
Test Tags   smoke    read_only

*** Test Cases ***
Coordinate Calculation Entry Should Be Available
    [Documentation]    进入工具页后，坐标计算入口应可见。
    Open Tools Tab
    Tools Home Should Be Ready
    Coordinate Calculation Entry Should Be Visible
```

### 第六步：验证

1. 运行 dry-run；
2. 在目标真机上单独运行新套件；
3. 重复运行，确认不依赖上一次残留状态；
4. 运行相关 smoke，确认没有破坏现有路径；
5. 检查失败时是否有明确日志和截图。

## 9. 新人最容易踩的坑

### 9.1 把所有步骤都写在 test 中

问题：可读性差，相同页面改版时要修改很多用例。

正确思路：test 写业务目标，flow 编排流程，page 封装页面动作，locator 集中维护。

### 9.2 大量使用 Sleep

问题：设备快时浪费时间，设备慢时仍不稳定。

正确思路：等待元素可见、可点击、消失或文本达到预期。

### 9.3 只操作，不断言

问题：脚本走完不代表业务正确。

正确思路：每条用例至少验证一个核心业务结果。

### 9.4 使用易变文本或绝对坐标定位

问题：语言、分辨率、动态数据或页面布局变化都会导致失败。

正确思路：优先 `accessibility_id` 和唯一 `resource-id`；使用文本时确认它固定且唯一。

### 9.5 硬编码设备号和环境地址

问题：脚本只能在一个人的电脑上运行，还可能泄露环境信息。

正确思路：使用 `env_test.yaml`、命令行变量或 CI 参数。

### 9.6 直接执行高风险回归用例

部分回归测试会写入项目数据，或依赖蓝牙接收机、网络甚至设备重启。不了解前置条件时，先执行带 `read_only` 的 smoke，不要直接运行全部测试。

### 9.7 只看最后一行报错

UI 自动化失败可能来自多层。应结合 `report.html`、`log.html`、失败截图和 Appium 服务日志，确认失败发生在用例、定位、会话、驱动还是设备层。

## 10. 分层排错指南

| 现象 | 优先检查 | 常见原因 |
| --- | --- | --- |
| Robot 提示找不到关键字 | Robot / 资源层 | `Resource` 路径错误、关键字拼写错误、资源未导入 |
| 找不到 `env_test.yaml` | 配置层 | 未创建本地变量文件、路径错误 |
| 无法连接 `127.0.0.1:4723` | Appium Server | Appium 未启动、端口不一致、进程已退出 |
| 无法创建 session | Capabilities / 驱动 | UiAutomator2 未安装、UDID/包名/Activity 错误、版本不兼容 |
| `adb devices` 无设备 | Android 连接层 | USB 调试未开启、未授权、数据线或驱动问题 |
| App 已启动但找不到元素 | locator / 页面状态 | 定位器失效、进入错误页面、权限弹窗遮挡、等待不足 |
| 偶发超时 | 稳定性层 | 固定 Sleep、网络/蓝牙波动、缺少页面就绪条件 |
| 输入中文异常 | 输入法 / capability | Unicode 输入法相关配置或设备输入法切换失败 |
| 本地通过、Jenkins 失败 | 环境 / 数据层 | 设备状态、依赖版本、权限、路径、测试数据或并发差异 |

推荐排查顺序：

```text
Robot 报告
  → 失败关键字和参数
  → 失败截图/页面状态
  → locator 是否仍然有效
  → Appium Server 日志
  → UiAutomator2 与 ADB
  → 真机状态、权限、网络和外部硬件
```

## 11. 建议培训安排

| 时间 | 内容 | 方式 |
| --- | --- | --- |
| 0～10 分钟 | 自动化目标、适用范围、整体调用链 | 讲解 |
| 10～30 分钟 | Robot Framework 语法、关键字、变量、setup/teardown、标签 | 讲解 + 代码阅读 |
| 30～50 分钟 | Appium 架构、session、capabilities、locator、等待 | 讲解 + 演示 |
| 50～70 分钟 | 本项目分层与核心冒烟用例执行链 | 代码走读 |
| 70～90 分钟 | 配置环境、dry-run、执行 smoke、查看报告 | 实操 |
| 90～110 分钟 | 添加一个只读断言或页面关键字 | 实操 |
| 110～120 分钟 | 常见问题和答疑 | 讨论 |

### 推荐实操任务

1. 找出 `${Home.TOOLS_TAB}` 从测试用例到实际点击所经过的全部文件；
2. 修改一个无业务影响的超时时间，运行 dry-run 并在 `log.html` 中找到对应关键字；
3. 为已有页面补充一个只读的“元素应可见”断言；
4. 故意把一个 locator 改错，观察 Robot 日志、截图和 Appium 日志分别提供了什么信息，然后恢复修改。

## 12. 课后自测

1. Robot Framework 和 Appium 的职责有什么区别？
2. AppiumLibrary 在两者之间起什么作用？
3. 为什么 Appium Server 启动成功后仍可能无法控制 Android？
4. `platformName`、`automationName` 和 `udid` 分别决定什么？
5. 为什么不建议在 test 文件中直接写 locator？
6. 为什么条件等待通常比 `Sleep` 稳定？
7. `tests/__init__.robot` 在本项目中做了什么？
8. 一条测试只有点击步骤、没有断言，为什么不完整？
9. 页面元素改名或 resource-id 变化时，通常应先修改哪一层？
10. 会操作真实接收机的用例应该使用什么标签，并在运行前确认什么？

参考答案：

1. Robot 组织、执行和报告测试；Appium 操作移动端 UI；
2. 提供 Robot 关键字，并把它们转成 Appium 客户端请求；
3. 还可能缺少 UiAutomator2 驱动、设备连接或正确 capabilities；
4. 依次决定平台、驱动和具体设备；
5. 集中维护可以降低页面变化带来的修改成本；
6. 条件满足就继续，慢设备也可以在超时范围内等待；
7. 统一建立/关闭 Appium 会话，并执行测试清理；
8. 没有可验证的预期结果，不能证明功能正确；
9. locator 层，必要时再调整 page；
10. `hardware`，并确认设备、环境、授权及对现场的影响。

## 13. 术语速查

| 术语 | 简单解释 |
| --- | --- |
| Test Case | 一条有明确目标和预期结果的测试 |
| Test Suite | 一组测试；Robot 文件和目录都可形成套件 |
| Keyword | 可调用的测试动作或业务步骤 |
| Resource | 保存共享关键字和变量的 Robot 文件 |
| Library | 用 Python 等语言实现、向 Robot 提供关键字的扩展 |
| Locator | 用来唯一找到 UI 元素的描述 |
| Assertion | 比较实际结果和预期结果 |
| Setup / Teardown | 测试前准备 / 测试后清理 |
| Tag | 用于分类、筛选和标记依赖或风险的标签 |
| Session | 测试客户端与目标设备/App 的一次控制连接 |
| Capability | 创建 session 时描述目标和行为的参数 |
| Driver | 把通用 Appium 命令映射为平台实际操作的模块 |
| ADB | Android Debug Bridge，Android 设备连接和管理工具 |
| Smoke Test | 快速验证关键路径是否基本可用的冒烟测试 |
| Regression Test | 验证已有功能没有被新改动破坏的回归测试 |

## 14. 延伸阅读

### 官方资料

- [Robot Framework 官方入门指南](https://docs.robotframework.org/docs)
- [Robot Framework User Guide](https://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html)
- [Robot Framework：第一个测试](https://docs.robotframework.org/docs/getting_started/how_to_write_rf)
- [Robot Framework：项目结构示例](https://docs.robotframework.org/docs/examples/project_structure)
- [Appium 工作原理](https://appium.io/docs/en/3.0/intro/appium/)
- [Appium 组成概览](https://appium.io/docs/en/3.0/intro/)
- [Appium Driver 介绍](https://appium.io/docs/en/latest/intro/drivers/)
- [UiAutomator2 Driver 快速开始](https://appium.io/docs/en/3.0/quickstart/uiauto2-driver/)
- [Appium Session Capabilities](https://appium.io/docs/en/3.0/guides/caps/)
- [AppiumLibrary 项目与使用示例](https://github.com/serhatbolsu/robotframework-appiumlibrary)
- [AppiumLibrary 关键字文档](https://serhatbolsu.github.io/robotframework-appiumlibrary/AppiumLibrary.html)

### 本项目资料

- [项目 README](../README.md)：环境搭建、配置和运行命令；
- [项目结构与脚本编写指南](project-structure-and-script-guide.md)：完整目录职责和开发流程；
- [编码约定](conventions.md)：分层、locator、等待、断言和命名规则；
- [Jenkins 冒烟测试验证记录](jenkins_smoke_validation.md)：CI 执行方式与注意事项。

## 15. 总结

对新人来说，最重要的不是记住所有 AppiumLibrary 关键字，而是建立三个认识：

1. **职责分清**：Robot Framework 管测试，Appium 管移动端操作，AppiumLibrary 连接二者；
2. **分层编写**：`tests → flows → pages → common/locators`，上层表达业务，下层隐藏技术细节；
3. **结果可信**：使用稳定 locator、条件等待和明确断言，并保留报告、日志和失败截图。

能看懂核心冒烟用例的完整调用链、能在真机上独立运行它、能从报告中定位一次失败，就已经完成了从“知道工具名称”到“可以参与项目维护”的第一步。
