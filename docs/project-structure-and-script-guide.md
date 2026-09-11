# SurveyMaster 自动化测试项目结构与脚本编写指南

## 1. 文档目的

本文基于当前 `SurveyMasterAutoTesting` 代码库整理，用于帮助开发、测试和维护人员快速理解：

- 项目的技术栈、总体架构和执行链路；
- 每个目录及关键文件的职责；
- 新增定位器、页面关键字、业务流程和测试用例时的分层规则；
- 脚本稳定性、测试数据、断言、日志、清理和 CI 方面的约定；
- 当前仓库中需要逐步收敛的历史写法。

本文是详细项目手册；已有的 `docs/conventions.md` 可继续作为日常编码规约速查表。

## 2. 项目概览

本项目用于对测量大师 Android App 进行 UI 自动化测试，核心技术栈如下：

| 组件 | 当前用途 |
| --- | --- |
| Python | Robot Framework 运行环境 |
| Robot Framework `7.4` | 测试编排、关键字管理、报告生成 |
| AppiumLibrary `3.2.1` | Robot Framework 与 Appium 的集成层 |
| Appium 2 | Android 自动化服务；Jenkins 当前固定为 `2.19.0` |
| UiAutomator2 | Android UI 驱动；Jenkins 当前固定为 `4.1.5` |
| ADB | 设备检测、APK 安装、权限和进程操作 |
| PyYAML | 加载 `env_test.yaml` 环境变量 |
| Jenkins | APK 获取、设备安装、测试执行、报告归档 |
| GitHub Actions | Push、PR、合并事件的企业微信通知 |

当前代码规模约为：

- 4 条实际测试用例；
- 7 个 common 公共资源文件；
- 15 个 pages 页面资源或说明文件；
- 5 个 flows 流程资源文件；
- 27 个 Android locator 文件；
- 3 个 Jenkins/通知脚本。

项目已经具备可运行的分层骨架，但 locator 的覆盖广度明显高于 page 和 test 层，后续主要工作是把已采集的页面元素逐步转化成可复用页面关键字和稳定业务用例。

## 3. 总体架构

### 3.1 分层关系

```text
测试用例 tests
    │  表达业务目标、前置条件和断言
    ▼
业务流程 flows
    │  编排多个页面的操作顺序
    ▼
页面对象 pages
    │  封装单个页面内的行为和页面就绪判断
    ├───────────────┐
    ▼               ▼
公共能力 common     定位器 locators
    │               │
    └───────┬───────┘
            ▼
       AppiumLibrary
            ▼
        Appium Server
            ▼
       Android 真机/App
```

依赖方向应始终自上而下：

- `tests` 可以调用 `flows`，必要时也可调用页面层的只读校验关键字；
- `flows` 调用 `pages`，不直接操作元素；
- `pages` 调用 `common`，并引用 `locators`；
- `common` 只提供通用动作、等待、断言、会话和清理能力；
- `locators` 只保存定位表达式，不编写业务操作。

禁止形成反向依赖，例如 locator 引用 page、common 引用具体业务 flow，或 flow 直接写 Appium 定位表达式。

### 3.2 一条用例的执行链路

以核心导航冒烟用例为例：

```text
Robot 加载 tests/__init__.robot
  → Suite Setup 建立 Appium 会话并处理权限
  → CoreNavigationSmoke.robot 表达 Given/When/Then
  → MainNavigationSmoke.resource 编排四个模块
  → Home/ProjectHome/EquipmentHome 等 page 关键字
  → common 中的 Tap、Wait Visible、Should Be Visible
  → android locator
  → Appium 操作真机
  → Test Teardown 失败截图并重启回主页
  → Suite Teardown 关闭 Appium 会话
  → 生成 output.xml、log.html、report.html
```

## 4. 项目目录总览

以下树形结构省略了 `.git`、缓存和历史运行产物：

```text
SurveyMasterAutoTesting/
├── .github/
│   └── workflows/
│       └── wecom_notify.yml
├── ci/
│   ├── ci_piplines
│   ├── jenkins_verify.bat
│   └── wecom_notify.ps1
├── docs/
├── resources/
│   ├── keywords/
│   │   ├── common/
│   │   ├── flows/
│   │   ├── pages/
│   │   │   ├── Equipment/
│   │   │   ├── Measure/
│   │   │   ├── Project/
│   │   │   └── Tools/
│   │   └── app_common.resource
│   ├── locators/
│   │   └── android/
│   └── variables/
│       └── env_test.yaml
├── scripts/
│   ├── start_appium.bat
│   └── stop_appium.bat
├── tests/
│   ├── __init__.robot
│   ├── smoke/
│   └── regression/
├── .gitignore
├── README.md
└── requirements.txt
```

## 5. 根目录文件

### 5.1 `README.md`

项目入口说明，当前包含技术栈、前置依赖、基本运行命令和目录简介。README 应保持简短，适合首次进入仓库的人员快速完成环境准备；详细规则放在 `docs/` 中。

建议 README 长期至少包含：

- 支持的 Python、Appium、UiAutomator2 版本；
- 创建虚拟环境和安装依赖的方法；
- 配置本地设备变量的方法；
- 启动 Appium 和执行最小冒烟用例的命令；
- 常见失败的排查入口；
- 指向本指南和编码规约的链接。

### 5.2 `requirements.txt`

Python 依赖清单。当前固定：

```text
robotframework==7.4
robotframework-appiumlibrary==3.2.1
PyYAML>=6.0
```

新增 Python 库时应确认确实不能由 Robot/AppiumLibrary 或已有库完成，并固定可复现的版本范围。不要为了一个简单字符串处理引入大型依赖。

### 5.3 `.gitignore`

用于排除虚拟环境、Python 缓存、本地环境配置和部分 Robot 运行产物。`resources/variables/env_test.yaml` 被视为本地配置，不应把个人设备号提交到仓库。

当前根目录仍可见 `output.xml`、`log.html`、`report.html` 等历史产物，说明根目录产物规则还需后续补齐。新增执行命令必须统一通过 `-d results` 或其他输出目录写入报告，避免继续污染根目录。

## 6. `tests/`：测试用例层

### 6.1 目录职责

`tests/` 只负责描述测试场景和业务预期，不负责实现底层 UI 操作。

```text
tests/
├── __init__.robot
├── smoke/
│   ├── _sanity_open_app.robot
│   └── CoreNavigationSmoke.robot
└── regression/
    └── NewProject/
        ├── CreateNewProject.robot
        └── LuoWangConnectFail.robot
```

### 6.2 `tests/__init__.robot`

这是测试树的公共套件初始化文件，当前统一定义：

- `Suite Setup`：`Open App And Handle Permissions`；
- `Suite Teardown`：`Close SurveyMaster App`；
- `Test Teardown`：`Global Test Teardown`；
- 公共 wait、assert、session 和 teardown 资源导入。

新增普通用例时，应优先复用根套件提供的会话，不要在每个测试中重复执行 `Open Application` 和 `Close Application`。只有专门验证会话建立的独立 sanity 用例才可例外。

### 6.3 `tests/smoke/`

冒烟测试用于快速判断一个 APK 是否具备继续测试的基本条件，要求：

- 覆盖启动、核心导航和少量最关键业务；
- 时间短、依赖少、失败含义明确；
- 默认不依赖云服务和外部硬件，或通过标签显式声明；
- 尽量只读，写数据时必须可清理；
- 适合每次构建或每日频繁运行。

当前用例：

- `_sanity_open_app.robot`：独立建立 Appium 会话并打开/关闭 App；
- `CoreNavigationSmoke.robot`：只读巡检项目、设备、测量、工具四个核心模块。

### 6.4 `tests/regression/`

回归测试覆盖更完整的业务路径，允许执行耗时更长、步骤更多或需要特定测试数据的场景。当前包含：

- `CreateNewProject.robot`：创建新项目流程；
- `LuoWangConnectFail.robot`：司南万象连接稳定性循环。

建议后续按业务域组织，而不是无限堆叠在同一目录：

```text
tests/regression/
├── Project/
├── Equipment/
├── Measure/
├── Tools/
└── DataTransfer/
```

### 6.5 用例层规则

用例层允许：

- 使用 `[Documentation]` 描述目的、前置和期望；
- 使用 `[Tags]` 或文件级 `Test Tags` 声明测试分类和依赖；
- 调用 flow 关键字；
- 调用少量 page 层“页面应就绪”或业务断言关键字；
- 设置用例级 setup/teardown；
- 写清晰的 Given/When/Then 业务步骤。

用例层禁止：

- 直接出现 `id=...`、`xpath=...`、`android=new UiSelector()`；
- 直接使用 `Click Element`、`Input Text`、`Press Keycode` 等 Appium 原子操作；
- 使用 `Sleep` 驱动业务流程；
- 把几十行业务步骤直接复制进测试；
- 把设备号、包名、项目名、蓝牙名称等写死在测试中；
- 只执行动作而没有核心断言。

## 7. `resources/keywords/common/`：公共原子能力层

common 层不应知道“项目”“放样”“接收机配置”等具体业务，只提供可组合能力。

| 文件 | 当前职责 | 使用注意事项 |
| --- | --- | --- |
| `actions.resource` | `Tap`、`Input`、文本滚动查找和点击 | 点击/输入前统一等待；业务层不要直接重复实现 |
| `wait.resource` | 元素出现、消失、文本相等或正则匹配等待 | 优先条件等待；`Wait Page Stable` 只可作为短暂动画兜底 |
| `assert.resource` | 通用可见性断言、失败截图 | 这里只提供通用能力，不写业务结论 |
| `session.resource` | 加载 YAML、创建/关闭 Appium 会话、处理“所有文件访问”权限 | 环境能力只能从统一配置读取；权限处理要兼容不同 Android 版本 |
| `teardown.resource` | 每条测试结束后的失败截图和回主页 | 清理失败不应掩盖原始测试失败 |
| `flow_helper.resource` | 强制重启回主页、`Run And Reset` 包装 | 属于历史公共流程，后续应移除其中硬编码包名和裸定位器 |
| `PopupHandle.resource` | 历史隐私协议和界面风格处理 | 与新的 `Startup.resource` 能力重叠，新增代码优先使用 Startup 页面层 |

公共关键字设计原则：

- 一个关键字只做一件事；
- 参数名称表达含义，如 `${locator}`、`${timeout}`、`${expected}`；
- 失败日志能说明操作对象、等待时间和实际结果；
- 默认值服务大多数页面，特殊超时由调用者显式传入；
- 不包含页面专属 locator；
- 不吞掉核心失败。`Run Keyword And Ignore Error` 只用于清理或确实可选的兼容分支。

`resources/keywords/app_common.resource` 当前只有示例 `Say Hello`，不属于正式框架能力。新增公共能力应放入职责明确的 common 文件，不建议继续扩展这个示例文件。

## 8. `resources/keywords/pages/`：页面对象层

### 8.1 页面层职责

一个 page 文件对应一个实际页面或边界清晰的页面组件。它负责：

- 导入本页 locator；
- 通过 common 执行点击、输入、等待和通用断言；
- 提供页面就绪判断；
- 提供本页面内部的操作；
- 读取页面状态并返回给 flow/test；
- 隐藏定位器和 Appium 细节。

页面层不负责：

- 编排多个页面组成完整业务；
- 创建 Appium 会话；
- 管理整个测试的数据准备和清理；
- 在关键字内部临时写 locator；
- 对其他模块页面进行大量跨层调用。

### 8.2 当前页面目录

#### 公共页面

| 文件 | 作用 |
| --- | --- |
| `Home.resource` | 首页底部四导航、主导航就绪判断 |
| `Startup.resource` | 首次启动隐私协议、界面风格和 Android 运行时权限处理 |
| `GuideActivity.resource` | 历史引导页及部分首页操作；建议逐步缩小职责 |

#### `pages/Project/`

| 文件 | 作用 |
| --- | --- |
| `ProjectHome.resource` | 项目主页就绪判断 |
| `Project.resource` | 项目管理、创建、删除等页面动作 |
| `README.md` | 项目页面层的占位或补充说明 |

#### `pages/Equipment/`

| 文件 | 作用 |
| --- | --- |
| `EquipmentHome.resource` | 设备主页就绪判断 |
| `ConnectDevice.resource` | 目标设备选择和蓝牙搜索连接页面动作 |
| `EquipmentInformation.resource` | 设备信息、重启等页面动作 |
| `LuoWang.resource` | 司南万象相关页面动作 |
| `README.md` | 设备模块说明 |

#### `pages/Measure/`

| 文件 | 作用 |
| --- | --- |
| `MeasureHome.resource` | 测量主页就绪判断，当前检查点测量和点放样入口 |
| `README.md` | 后续测量工作台页面对象规划 |

#### `pages/Tools/`

| 文件 | 作用 |
| --- | --- |
| `ToolsHome.resource` | 工具主页就绪判断，当前检查面积计算和角度转换入口 |
| `README.md` | 后续计算工具页面对象规划 |

目前坐标系统、点库、参数计算、数据传输、软件设置、测量地图和工具计算等已经有 locator，但还缺少对应 page 文件。新增测试时应先补页面层，不应直接从 test 引用这些 locator。

### 8.3 页面就绪关键字

每个重要页面至少提供一个稳定的就绪关键字，例如：

```robot
Coordinate System Page Should Be Ready
    [Documentation]    等待坐标系统页加载，并校验其核心只读区域。
    Wait Visible    ${CoordinateSystem.NAME_INPUT}
    Should Be Visible    ${CoordinateSystem.SOURCE_ELLIPSOID}
    Should Be Visible    ${CoordinateSystem.TARGET_ELLIPSOID}
    Should Be Visible    ${CoordinateSystem.PROJECTION}
```

就绪判断应选择 2～4 个能代表页面完整加载的稳定控件，不要只断言一个通用根容器，也不要把所有非关键元素全部断言一遍。

## 9. `resources/keywords/flows/`：业务流程层

flow 层将多个 page 动作组合成可复用业务流程。

| 文件 | 当前职责 |
| --- | --- |
| `MainNavigationSmoke.resource` | 准备首次启动状态、巡检四个主模块并返回项目主页 |
| `newproject.resource` | 创建项目的完整跨页面流程 |
| `ConnectDevice.resource` | 从页面入口进入连接设备及相关连接流程 |
| `EquipmentInformation.resource` | 进入设备信息并执行相关设备流程 |
| `WanXiangConnect.resource` | 司南万象连接流程 |

flow 层规则：

- 只调用 page 或其他边界清晰的 flow；
- 不写 `id=`、XPath、UiSelector；
- 不直接使用 `Click Element`、`Input Text`；
- 每个主要业务阶段写一条“动作 + 参数”的日志；
- 参数只保留对业务有意义的数据，例如项目名、设备名、点名；
- 分支必须体现产品状态，例如“首次启动弹窗存在/不存在”，而不是用大量忽略错误掩盖问题；
- 一个 flow 应有明确入口状态和出口状态；
- flow 失败后由统一 teardown 恢复，不在每一步重复杀 App。

## 10. `resources/locators/android/`：Android 定位器层

### 10.1 目录职责

该目录集中存放 Android 页面元素定位表达式。当前按页面或模块拆成 27 个文件：

| 分类 | 文件 | 覆盖范围 |
| --- | --- | --- |
| 公共/启动 | `Home.resource`、`Startup.resource`、`GuideActivity.resource`、`Popups.resource` | 首页、四导航、首次启动、公共弹窗 |
| 项目 | `ProjectHome.resource`、`Project.resource`、`ProjectMore.resource` | 项目主页、项目管理、创建/详情/回收站、更多 |
| 坐标与数据 | `CoordinateSystem.resource`、`PointStore.resource`、`ParameterCalculation.resource`、`DataTransfer.resource`、`BaseStationTranslation.resource`、`CodeManagement.resource` | 坐标系统、点库、参数计算、导入导出、基站平移、代码管理 |
| 设置与云 | `SoftwareSettings.resource`、`CloudLogin.resource` | 软件设置、云登录 |
| 设备 | `EquipmentHome.resource`、`ConnectDevice.resource`、`EquipmentInformation.resource`、`PositionInformation.resource`、`RegistrationInformation.resource`、`EquipmentMore.resource`、`StationModePopup.resource` | 连接、设备详情、定位、注册、站模式弹窗 |
| 测量 | `Measure.resource`、`MeasureMap.resource`、`RoadManagement.resource` | 测量入口、测量工作台、道路管理 |
| 工具 | `Tools.resource`、`ToolCalculations.resource` | 工具入口及计算页面 |

### 10.2 定位策略优先级

从高到低选择：

1. `accessibility_id`：语义清晰且稳定时优先；
2. 唯一 `resource-id`：当前项目最常用的稳定策略；
3. `resource-id + 精确文本` 的 UiSelector：多个宫格项共享 ID 时使用；
4. 其他 UiSelector 条件组合；
5. XPath：仅在列表相邻关系等没有稳定替代方案时使用，并写明原因。

禁止使用：

- 绝对坐标点击；
- 深层绝对 XPath；
- 未说明原因的 `instance(n)`；
- 只依赖容易变化的文案，而页面实际存在稳定 resource-id；
- 把当前项目名、设备序列号、固件版本等动态值写入 locator。

### 10.3 locator 命名与注释

新文件推荐使用字典变量并采用统一大写名称：

```robot
*** Variables ***
&{AngleConversion}
# 角度输入框：页面内唯一 resource-id。
...    ANGLE_INPUT=id=com.sinognss.sm.free:id/et_angle
# 计算按钮：页面内唯一 resource-id。
...    CALCULATE_BUTTON=id=com.sinognss.sm.free:id/btn_calc
# 弧度结果：动态文本，只定位控件，不写死结果。
...    RADIAN_RESULT=id=com.sinognss.sm.free:id/tv_radian
```

规则：

- 字典名表达页面，键名表达控件语义；
- 使用 `UPPER_SNAKE_CASE`，避免继续新增 `Target_Device`、`Restart` 等混合风格；
- 每个定位器写来源、用途和必要的稳定性说明；
- 同一控件只定义一次，兼容旧名称时注明“兼容旧关键字”；
- 拼写必须检查。现有 `CONFRIM_*` 属于历史拼写，新代码使用正确的 `CONFIRM_*`，迁移时保留兼容期。

## 11. `resources/variables/`：环境与测试数据

`env_test.yaml` 当前保存 Appium 地址、平台、设备、包名、Activity 和 Appium capabilities。该文件已被 `.gitignore` 排除，适合本机或 CI 动态生成。

环境变量建议分为三类：

| 类型 | 示例 | 建议来源 |
| --- | --- | --- |
| 会话环境 | `APPIUM_SERVER`、`UDID`、`APP_PACKAGE`、`APP_ACTIVITY` | 本地 YAML、命令行或 CI 参数 |
| 设备/硬件数据 | 目标接收机名、连接方式 | 设备池配置或 CI 参数 |
| 业务测试数据 | 项目前缀、点名、输入坐标 | `tests/data/` 或专用测试数据 YAML |

规则：

- 测试文件不得重复定义环境变量；
- 包名和 UDID 只能有一个最终来源；
- CI 生成的 YAML 结构应与本地模板一致；
- 个人设备号和账号密钥不得提交；
- 建议增加可提交的 `env.example.yaml`，只包含字段和安全示例；
- 日志应输出实际使用的 UDID、包名、版本和 Appium 地址，但不得输出密码、Token 或 Webhook。

当前 `env_test.yaml`、sanity 用例、`flow_helper.resource` 和 Jenkins 默认值之间存在不同设备号或重复配置，新增脚本前应优先通过变量覆盖，不要复制这些硬编码写法。

## 12. `scripts/`：本地辅助脚本

| 文件 | 作用 | 当前状态 |
| --- | --- | --- |
| `start_appium.bat` | 在本机 4723 端口启动 Appium | 可用于本地开发 |
| `stop_appium.bat` | 计划用于停止 Appium | 当前为空文件，不能依赖它完成停止操作 |

本地辅助脚本只负责开发便利，不应承担业务测试逻辑。脚本需要：

- 输出明确的端口、日志路径和退出码；
- 只停止本项目启动的 Appium 进程，避免误杀其他 Node 进程；
- 与 YAML 的 Appium 地址保持一致；
- 失败时返回非零退出码。

## 13. `ci/`：Jenkins 与通知

### 13.1 `ci/ci_piplines`

Jenkins 声明式流水线，当前主要阶段为：

1. 展示本次参数；
2. 清理并准备工作区；
3. 从指定上游任务复制 APK；
4. 校验设备、卸载旧包并安装 APK；
5. 检出自动化测试仓库和指定分支；
6. 根据 Jenkins 参数生成本地 `env_test.yaml`；
7. 校验 `TEST_ROBOTS` 并生成 Robot argument file；
8. 发送开始通知；
9. 调用 `jenkins_verify.bat` 执行；
10. 在 `post` 阶段归档报告和日志。

流水线使用 `disableConcurrentBuilds()`，这是单设备 UI 自动化的重要保护，防止多个构建争用同一台设备。

### 13.2 `ci/jenkins_verify.bat`

Jenkins Windows 节点上的实际运行器，负责：

- 检查 Python 和 Python 包；
- 查找 Node/npm；
- 固定安装工作区级 Appium `2.19.0` 与 UiAutomator2 `4.1.5`；
- 检查指定 ADB 设备；
- 重置 Appium Settings 辅助包；
- 启动 Appium 并等待端口就绪；
- 通过 `robot_args.txt` 执行 Robot；
- 保留 Robot 原始退出码；
- 停止 Appium 和 ADB；
- 输出报告文件检查结果。

该脚本包含 Jenkins 节点特定的 Python、Android SDK 和默认设备路径。修改时必须同时考虑本地运行与 Jenkins 节点，不能直接把另一台机器的路径写入公共逻辑。

### 13.3 `ci/wecom_notify.ps1`

用于 Jenkins 构建开始、成功或失败等状态的企业微信通知。Webhook 应来自 Jenkins credentials，不得写入仓库。

## 14. `.github/`：仓库事件通知

`.github/workflows/wecom_notify.yml` 监听指定分支的 push，以及面向 main 的 PR 创建、重新打开、可评审和合并事件，并向企业微信发送通知。

它目前不是 Android UI 测试执行入口，主要承担协作通知。修改时注意：

- Webhook 只能从 GitHub Secret 读取；
- 不在日志打印密钥；
- PR 关闭但未合并时不发送“已合并”消息；
- 通知失败不应改变代码测试结果，除非团队明确将通知作为质量门禁。

## 15. `docs/`：项目文档

当前文档职责如下：

| 文档 | 作用 |
| --- | --- |
| `conventions.md` | Robot Framework 与 Appium 编码规约速查 |
| `test_plan.md` | 早期测试计划和任务说明 |
| `next-stage-plan.md` | 框架下一阶段建设规划 |
| `app-structure-gap-analysis.md` | App 页面结构观察及自动化缺口分析 |
| `locator-inventory-4abcf2ca.md` | R60 真机 locator 采集基线 |
| `jenkins_smoke_validation.md` | Jenkins 冒烟链路验证记录 |
| `smoke-automation-plan-SP81150709.md` | H55 设备下一批冒烟自动化规划 |
| `project-structure-and-script-guide.md` | 本文，项目结构和脚本编写总指南 |

文档中涉及设备、App 版本和页面结构时必须标注采集日期与环境，避免旧版本观察结果被误认为永久事实。

## 16. 新脚本的标准开发流程

### 第一步：确认用例价值和边界

编写前先回答：

- 这个场景是否已被现有用例覆盖？
- 它属于 smoke、regression、hardware、network 还是 stability？
- 是否会创建、修改或删除业务数据？
- 是否依赖接收机、网络、账号、授权或预置文件？
- 失败后如何恢复？
- 断言是什么，而不是“流程能跑完”吗？

### 第二步：观察页面并采集 locator

- 在明确的设备和 App 版本上采集 UI hierarchy；
- 优先寻找唯一 resource-id 或 accessibility id；
- 记录动态属性、共享 ID、多语言和不同连接状态的风险；
- locator 按页面写入 `resources/locators/android/`；
- 不在测试代码中用屏幕坐标试跑后直接提交。

### 第三步：实现 page 关键字

页面层至少应包含：

- `Page Should Be Ready`；
- 进入下一页面的点击动作；
- 必要的输入和清空动作；
- 业务状态读取；
- 返回或关闭当前页面的动作。

示例：

```robot
*** Settings ***
Documentation    角度转换页面操作，只封装本页行为。
Resource    ../../../locators/android/ToolCalculations.resource
Resource    ../../common/actions.resource
Resource    ../../common/wait.resource
Resource    ../../common/assert.resource

*** Keywords ***
Angle Conversion Page Should Be Ready
    [Documentation]    校验角度输入、计算按钮和核心结果区域已加载。
    Wait Visible    ${ToolCalculations.ANGLE_INPUT}
    Should Be Visible    ${ToolCalculations.CALCULATE_BUTTON}
    Should Be Visible    ${ToolCalculations.RADIAN_RESULT}

Enter Angle
    [Arguments]    ${angle}
    Input    ${ToolCalculations.ANGLE_INPUT}    ${angle}

Calculate Angle
    Tap    ${ToolCalculations.CALCULATE_BUTTON}
```

### 第四步：实现 flow

当场景跨多个页面时再增加 flow；仅在一个页面内完成的计算不需要为了“分层完整”强行建立无价值 flow。

```robot
*** Settings ***
Documentation    从工具主页进入角度转换并完成一次计算。
Resource    ../pages/Home.resource
Resource    ../pages/Tools/ToolsHome.resource
Resource    ../pages/Tools/AngleConversion.resource

*** Keywords ***
Calculate Angle From Tools Home
    [Arguments]    ${angle}
    Log    [CALC] 从工具主页执行角度转换，输入=${angle}
    Open Tools Tab
    Open Angle Conversion
    Angle Conversion Page Should Be Ready
    Enter Angle    ${angle}
    Calculate Angle
```

### 第五步：实现 test 和核心断言

```robot
*** Settings ***
Documentation    工具模块离线计算冒烟测试。
Resource    ../../resources/keywords/flows/AngleConversion.resource
Test Tags    smoke    offline    calculation

*** Test Cases ***
Angle Conversion Should Return Correct Values
    [Documentation]    Given App 已启动；When 将 180 度转换；Then 弧度和百分度结果正确。
    Given Prepare Angle Conversion
    When Calculate Angle From Tools Home    180
    Then Angle Results Should Be Equivalent To    180    3.1415926    200
```

断言可以封装为 page 层的业务可读关键字，但必须由 test 明确调用，不能隐藏到点击动作内部，使测试“做了什么判断”无法阅读。

### 第六步：静态和实机验证

至少执行：

1. Robot dry-run，检查资源路径、变量和关键字名称；
2. 目标用例单独运行；
3. 同一用例重复运行，验证状态可恢复；
4. 失败场景检查截图和日志；
5. 检查运行后项目、点库、设备和设置没有残留污染；
6. 再运行相关 smoke，确认没有破坏公共能力。

## 17. 脚本编写规则

### 17.1 文件与关键字命名

- 测试文件：表达验证目标，如 `AngleConversionSmoke.robot`；
- locator 文件：使用页面名，如 `CoordinateSystem.resource`；
- page 文件：使用页面名，如 `PointStore.resource`；
- flow 文件：表达流程，如 `CreateNewProject.resource`；
- 测试名：使用完整业务语义，如 `Angle Conversion Should Return Correct Values`；
- 关键字名：动词开头，避免 `Click1`、`Do It`、`Test Step` 等模糊名称；
- 参数：使用 `${project_name}`、`${target_device}`，不使用 `${a}`、`${temp1}`；
- 新文件统一使用一种命名风格，不再混用全小写和 CamelCase；建议文件名采用 PascalCase。

### 17.2 Robot 文件结构

推荐顺序：

```robot
*** Settings ***
*** Variables ***
*** Test Cases ***    # 仅 .robot 测试文件
*** Keywords ***      # 资源文件或确有局部关键字时
```

- 使用 4 个空格分隔 Robot 单元；
- 续行使用 `...` 并对齐；
- 文件顶部写 `Documentation`；
- 关键字写 `[Documentation]`，复杂关键字写清入口/出口状态；
- 单个关键字超过约 20 行时评估拆分；
- 不保留无效注释、调试代码和无用途占位关键字。

### 17.3 等待原则

优先等待业务条件：

- 页面唯一控件出现；
- 按钮可交互；
- 弹窗消失；
- 状态文本变为目标值；
- 列表出现目标设备或目标项目；
- Activity 或页面标题切换完成。

固定 `Sleep` 只能用于无法观察的短动画兜底，必须说明原因且一般不超过 2 秒。禁止用 `Sleep 20s` 代替等待蓝牙设备列表，也禁止在测试层到处增加 Sleep 解决偶发失败。

### 17.4 断言原则

每条用例至少包含一个与用例目的直接相关的核心断言：

- 页面类：标题、关键控件组合和页面状态；
- 计算类：实际数值与期望值，允许合理容差；
- 列表类：目标项出现/消失、数量变化或过滤结果；
- 创建类：创建后数据存在；
- 删除类：删除后数据不存在；
- 连接类：连接状态、设备名、差分状态，而不是仅检查弹窗关闭。

不要将“关键字没有抛错”当作唯一通过依据。动态值不要硬编码完整文案，可使用非空、正则、数值范围、前后快照或运行时基线。

### 17.5 测试数据原则

- 数据唯一：使用 `AUTO_${BUILD_NUMBER}_${timestamp}` 等可追踪前缀；
- 数据最小：只创建断言所需的最少数据；
- 数据可清理：teardown 能精确删除本用例创建的数据；
- 数据不共享：用例不依赖另一用例先执行；
- 数据可诊断：失败日志记录实际生成的数据名；
- 不删除非自动化前缀的数据；
- 清理时找不到目标数据应安全结束，不扩大删除范围。

### 17.6 状态与清理原则

- 每个测试明确入口状态和出口状态；
- 默认结束状态为项目主页；
- 写数据用例优先“精确删除所创建数据”，重启 App 只能恢复页面，不能替代业务数据清理；
- teardown 中先保留失败证据，再执行恢复；
- 恢复失败不覆盖原始错误；
- 不主动断开现场正在使用的接收机，除非用例有 `hardware` 标签并明确授权；
- 修改语言、方向、单位、快捷键等全局设置时，必须保存原值并在 teardown 恢复。

### 17.7 标签原则

建议采用：

| 标签 | 含义 |
| --- | --- |
| `smoke` | 快速核心检查 |
| `regression` | 完整业务回归 |
| `read_only` | 不写业务数据 |
| `offline` | 无网络依赖 |
| `hardware` | 依赖或操作接收机 |
| `network` | 依赖云端或网络 |
| `writes_project` | 会写项目数据 |
| `writes_point` | 会写点库或测量数据 |
| `stability` | 循环或长时间稳定性测试 |
| `destructive_config` | 会修改设备或授权配置 |

标签表达依赖和风险，使 CI 能安全选择，而不是只按目录猜测。

### 17.8 日志与失败证据

- flow 的关键步骤记录“动作 + 关键参数”；
- 不记录密码、Token、Webhook 和隐私数据；
- 失败至少保存截图；
- 推荐同时记录 page source、当前 Activity、UDID、App 版本、接收机连接状态；
- 截图名称包含测试名和时间；
- 超时日志应写出等待的业务条件，而不只是“element not found”。

## 18. 脚本设计原则

### 18.1 业务价值优先

自动化不是把所有按钮点击一遍。优先覆盖会阻断用户主要工作的路径：启动、项目、坐标、设备连接、测量、数据保存和关键计算。

### 18.2 确定性优先

同样的前置和输入应产生同样的结果。纯离线计算、只读页面和可逆查询比依赖实时网络、卫星和蓝牙广播的场景更适合放入高频 smoke。

### 18.3 独立和幂等

用例可以单独执行，重复执行结果一致，不依赖执行顺序。第一次失败留下的数据不应导致第二次必然失败。

### 18.4 可维护性优先于短期速度

 locator 只写一次，页面动作只封装一次。临时裸定位和坐标点击虽然写得快，但会把页面变化成本扩散到所有测试。

### 18.5 可观测性与可诊断性

失败必须能回答：在哪台设备、哪个 App 版本、哪个页面、执行了什么、输入是什么、实际状态是什么。不能只留下一个超时堆栈。

### 18.6 外部依赖显式化

硬件、网络、账号、授权、文件和定位状态必须通过标签、前置检查和配置明确表达。状态不满足时应给出清楚的 skip/失败原因，不能静默切换真实设备配置。

### 18.7 最小安全变更

只修改当前用例需要的状态；只清理自动化自己创建的数据；不在普通冒烟中执行注册、恢复出厂、深度重启、清空项目库等高风险操作。

## 19. 本地运行建议

### 19.1 环境准备

```powershell
python -m pip install -r requirements.txt
adb devices
scripts\start_appium.bat
```

运行前确认：

- `env_test.yaml` 中 UDID 与在线设备一致；
- 目标包已安装；
- Appium 地址与启动端口一致；
- 没有其他任务占用设备；
- 写数据或硬件用例的前置环境符合要求。

### 19.2 常用命令

全部测试：

```powershell
python -m robot -d results tests
```

单个冒烟文件：

```powershell
python -m robot -d results tests\smoke\CoreNavigationSmoke.robot
```

按标签执行：

```powershell
python -m robot -d results --include smoke --exclude hardware --exclude network tests
```

静态 dry-run：

```powershell
python -m robot --dryrun --output NONE --log NONE --report NONE tests
```

任何本地运行都应指定输出目录，避免在仓库根目录生成报告。

## 20. CI 编写与维护原则

- Jenkins 参数必须在真正安装或测试前完成非空和路径校验；
- 设备检查使用明确 UDID，不从多设备列表中猜测；
- APK 包名、安装包和 Appium 配置必须一致；
- Appium/UiAutomator2 版本固定，升级时单独验证；
- Robot 必须保留真实退出码，禁止为了发布报告强制返回成功；
- 无论成功失败都要关闭 Appium、释放端口和归档证据；
- 单台设备禁止并发构建；
- CI 生成的环境文件不能回写并提交到仓库；
- 选择测试文件时限制在 `tests/` 下，拒绝任意路径；
- 通知不输出凭据，报告链接和构建号应可追踪。

## 21. 当前仓库需注意的历史差异

以下是当前实现与目标规范之间的差异。它们不妨碍理解现有项目，但不应作为新增脚本模板复制：

1. `_sanity_open_app.robot` 硬编码 Appium 地址、设备号、包名和 Activity，并直接使用 `Sleep`；
2. `flow_helper.resource` 再次硬编码包名，并使用裸首页文本 locator；
3. `session.resource` 的特殊权限处理直接写 UiSelector，并包含固定等待；
4. `PopupHandle.resource` 与新的 `Startup.resource` 职责重叠，且直接写 locator；
5. `ConnectDevice.resource` 使用 `Sleep 20s` 等待蓝牙搜索，稳定性和执行时间都不理想；
6. `LuoWangConnectFail.robot` 在测试层包含循环、Sleep、截图等底层实现，应逐步下沉到 flow/common；
7. 文件和关键字存在 `newproject`、`Target_Device`、`Deep_Restart`、`CONFRIM` 等不统一命名；
8. `Popups.resource` 在 locator 层导入了 `AppiumLibrary`，纯 locator 文件原则上不需要 Library；
9. `app_common.resource` 仍是示例文件，`stop_appium.bat` 当前为空；
10. 大量 locator 已就绪，但对应 page、flow 和 test 尚未实现；
11. 根目录和部分输出目录中存在历史 Robot 报告，应统一输出位置并完善忽略规则；
12. 本地 YAML、sanity、公共关键字和 Jenkins 的默认设备配置来源尚未完全统一。

处理原则是渐进式收敛：新增代码严格遵守本指南；修改相关旧功能时顺手迁移；不要为了形式统一一次性重写所有可运行代码。

## 22. 提交前自检清单

### 结构与分层

- [ ] 测试只表达业务目的，没有裸 locator 和 Appium 原子操作；
- [ ] 跨页面步骤放在 flow，单页面动作放在 page；
- [ ] locator 集中在 `resources/locators/android/`；
- [ ] common 关键字不包含业务页面语义；
- [ ] 没有形成反向依赖或循环依赖。

### 稳定性

- [ ] 点击和输入前有条件等待；
- [ ] 没有新增无说明的 `Sleep`；
- [ ] 动态文本没有被当作固定常量断言；
- [ ] 硬件、网络和文件依赖已显式标注；
- [ ] 不使用屏幕绝对坐标。

### 数据与安全

- [ ] 测试数据唯一、可追踪、可精确清理；
- [ ] 用例重复运行不会污染环境；
- [ ] 未硬编码个人设备号、账号、密码或 Token；
- [ ] 不会删除非自动化创建的数据；
- [ ] 高风险设备操作不在默认 smoke 中。

### 断言与证据

- [ ] 每条用例至少有一个核心业务断言；
- [ ] 失败时有截图和足够日志；
- [ ] teardown 先保存证据再恢复；
- [ ] 清理错误不会覆盖原始错误；
- [ ] 日志包含关键输入，但不包含敏感信息。

### 验证与提交

- [ ] Robot dry-run 通过；
- [ ] 新用例单独执行通过；
- [ ] 新用例重复执行通过；
- [ ] 相关 smoke 未被破坏；
- [ ] 报告输出到指定目录；
- [ ] 新文件有 Documentation、标签和必要注释；
- [ ] 文档同步更新了新增目录、配置或运行方式。

## 23. 总结

本项目推荐长期坚持 `tests → flows → pages → common/locators` 的单向分层。测试用例关注业务结果，flow 负责跨页面编排，page 隐藏页面细节，common 提供稳定原子能力，locator 统一管理 Android 元素，变量文件隔离环境差异，CI 负责可重复执行和证据归档。

新增脚本时最重要的不是“尽快点通页面”，而是同时保证：业务断言明确、定位稳定、条件等待、数据可恢复、依赖可识别、失败可诊断。按照这一原则扩展，当前已采集的大量 locator 才能逐步沉淀为可靠的冒烟和回归测试资产。
