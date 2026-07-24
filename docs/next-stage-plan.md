# SurveyMaster 自动化测试项目下一阶段规划

## 1. 背景与当前判断

当前仓库已经具备自动化测试项目的基本骨架，技术栈以 Robot Framework、AppiumLibrary、Android UiAutomator2 为主，目录已按 `tests`、`resources`、`ci`、`docs` 拆分，并且已经开始沉淀分层规范、公共关键字、页面关键字、业务流程和 Jenkins 执行脚本。

从代码状态看，项目仍处于启动阶段，已经从“单个脚本验证可行性”进入“框架雏形可运行”的阶段。下一阶段不建议推倒重来，而应围绕“稳定可重复执行、统一配置、形成核心用例资产、接入 CI 可观测闭环”进行建设。

## 2. 已有基础

### 2.1 工程结构已初步成型

当前主要目录职责如下：

- `tests/`：测试用例目录，已区分 `smoke` 和 `regression`。
- `resources/keywords/common/`：公共原子关键字，例如点击、输入、等待、断言、启动、复位。
- `resources/keywords/pages/`：页面层关键字，例如项目页、设备页、引导页。
- `resources/keywords/flows/`：业务流程层关键字，例如创建项目、连接设备、司南万象连接。
- `resources/locators/android/`：Android 定位器集中管理目录。
- `ci/`：Jenkins 执行、Appium 启停、企业微信通知相关脚本。
- `docs/`：已有编码规约文档。

这说明团队已经具备了比较正确的分层意识，后续重点应是让这套分层真正稳定落地。

### 2.2 核心公共能力已有雏形

已有能力包括：

- App 启动与权限处理：`Open SurveyMaster App`、`Open App And Handle Permissions`。
- 测试后复位：`Global Test Teardown`、`Restart App To Home`。
- 原子操作：`Tap`、`Input`、`Wait Visible`、`Wait Gone`。
- 文本滚动查找：`Android Scroll Into View By Text Contains`、`Scroll To And Tap Text Contains`。
- 页面与流程关键字：项目创建、连接设备、司南万象连接流程等。

这些能力可以作为下一阶段继续扩展的基础。

### 2.3 CI 能力已有较高起点

`ci/jenkins_verify.bat` 已包含：

- Python、Node、npm、Appium、ADB 检查。
- 指定设备在线检查。
- Appium 启动、端口等待、状态检查和停止。
- Robot 执行。
- 结果目录输出。

`ci/ci_piplines` 已覆盖：

- APK 获取与安装。
- 自动测试仓库拉取。
- 本地环境配置生成。
- Robot 自动化执行。
- 结果归档。

`ci/wecom_notify.ps1` 和 GitHub Actions 已有企业微信通知能力。

这说明下一阶段可以把 CI 从“能跑”推进到“稳定、可诊断、可按标签选择执行”。

## 3. 当前主要问题

### 3.1 配置来源还不统一

仓库中已经有 `resources/variables/env_test.yaml`，但仍存在多处硬编码：

- `tests/smoke/_sanity_open_app.robot` 中硬编码了 `UDID`、包名、Activity 和 Appium 地址。
- `resources/keywords/common/flow_helper.resource` 中再次定义了 `${APP_PACKAGE}`。
- `ci/jenkins_verify.bat` 中写死了 Python 路径、Android SDK 默认路径、默认设备 ID。
- `ci/ci_piplines` 中又生成了一份 `env_test.yaml`。

风险：

- 本地、Jenkins、不同设备之间行为不一致。
- 设备切换、包名切换、测试环境切换成本高。
- 排查失败时无法快速判断实际使用了哪套配置。

### 3.2 用例层仍混入底层操作

部分用例仍直接使用：

- `Sleep`
- `Press Keycode`
- `Page Should Contain Element`
- 裸定位器，例如 `id=com.sinognss.sm.free:id/nav_bar`

这与 `docs/conventions.md` 中定义的分层目标不完全一致。下一阶段应将这些操作逐步下沉到 `common`、`pages` 或 `flows`，让 `tests` 只表达业务意图和断言。

### 3.3 等待策略还不够稳定

当前代码中仍有固定等待，例如：

- 打开 App 后 `Sleep 3s`
- 蓝牙搜索前 `Sleep 20s`
- 连接流程中 `Sleep 2s`
- 弹窗处理后 `Sleep 1s/3s`

固定等待会造成两个问题：

- 设备慢时仍然失败。
- 设备快时浪费大量执行时间。

下一阶段应把固定等待替换为“条件等待”，例如等待页面元素出现、弹窗消失、状态文本变化、设备列表出现、按钮可点击等。

### 3.4 测试数据和设备数据还未产品化管理

当前可见的固定数据包括：

- 项目名：`AutoTestingProject`
- 蓝牙设备名：`T61S00167`
- Jenkins 默认设备：`4e83cae7`
- 本地变量设备：`SP84650578`

风险：

- 多人、多设备并发执行时容易互相污染。
- 项目创建、删除失败后会影响后续用例。
- 蓝牙设备绑定固定值，不利于扩展设备池。

### 3.5 用例资产规模偏小，覆盖面还处在起步阶段

当前测试用例主要集中在：

- 冒烟启动。
- 创建新项目。
- 司南万象连接稳定性压测。

这说明当前自动化更偏框架验证和少量核心流程验证，还没有形成稳定的冒烟集、主流程回归集、专项稳定性集。

### 3.6 质量门禁还不完整

仓库已有 `.gitignore` 和规约文档，但还缺少自动化质量门禁，例如：

- Robot 语法检查。
- Robocop 规则。
- 用例标签规范检查。
- 禁止在 `tests` 直接写裸定位器。
- 禁止新增无说明的 `Sleep`。
- PR 前最小可运行验证。

下一阶段应先做轻量门禁，避免框架继续扩展后维护成本快速上升。

## 4. 下一阶段总体目标

建议下一阶段目标定义为：

> 建立一套可在本地和 Jenkins 稳定运行的 SurveyMaster Android UI 自动化基础框架，并沉淀第一批可维护、可重复执行、可诊断的核心业务用例。

具体目标：

- 配置统一：本地与 CI 使用同一套变量机制。
- 分层落地：用例层不直接写定位器和底层操作。
- 稳定性提升：减少固定 `Sleep`，核心流程具备失败截图、日志、复位能力。
- 覆盖核心路径：形成稳定冒烟集和核心回归集。
- CI 闭环：支持按 suite/tag/文件选择执行，产出结果、日志、截图和通知。
- 规范可检查：建立轻量代码检查和 PR 自检机制。

## 5. 建议里程碑

### 里程碑 1：框架基线收敛

周期建议：1-2 周。

目标：

- 让项目在一台指定设备上可稳定执行冒烟集。
- 统一本地和 Jenkins 的配置入口。
- 固化最小运行命令和故障排查路径。

重点任务：

- 统一 `env_test.yaml` 变量结构，补充 `env.example.yaml`，提交模板但不提交个人设备配置。
- 改造 `_sanity_open_app.robot`，使用 `Open App And Handle Permissions`，移除硬编码变量。
- 将 `flow_helper.resource` 中的 `${APP_PACKAGE}` 改为来自变量文件。
- 整理 README，明确本地运行步骤、Jenkins 运行步骤、设备准备步骤。
- 根目录历史运行产物不纳入版本管理，确认 `.gitignore` 已覆盖 `output.xml`、`log.html`、`report.html`、`results/`、`output/`。

交付物：

- `resources/variables/env.example.yaml`
- 更新后的 README。
- 一个稳定可执行的 smoke suite。

验收标准：

- 本地执行 `python -m robot -d results --suite smoke tests` 或约定命令可通过。
- Jenkins 能用指定设备跑通同一套冒烟用例。
- 报告中可看到启动、权限处理、复位和失败截图。

### 里程碑 2：关键字层稳定性治理

周期建议：2-3 周。

目标：

- 让公共关键字、页面关键字、流程关键字边界清晰。
- 降低 UI 等待导致的偶发失败。

重点任务：

- 盘点并替换高风险 `Sleep`：
  - 蓝牙搜索改为等待设备列表出现或目标设备出现。
  - 弹窗处理改为等待弹窗出现/消失。
  - App 启动改为等待首页关键元素。
- 把用例层中的 `Press Keycode`、裸定位器、底层断言迁移到页面/流程关键字。
- 为常见页面增加页面就绪关键字，例如：
  - `Project Page Should Be Ready`
  - `Equipment Page Should Be Ready`
  - `Connect Device Page Should Be Ready`
- 统一失败处理：
  - 失败截图命名包含用例名和时间。
  - 必要时采集当前 Activity、页面 XML 或 Appium log。
- 清理无实际价值的示例关键字，例如仅用于演示的 `Say Hello`，或移动到示例目录。

交付物：

- 稳定的 `common` 关键字集合。
- 每个核心页面至少一个页面就绪关键字。
- 更新后的分层示例用例。

验收标准：

- `tests` 下不再直接出现裸 `id=`、`android=`、`xpath=` 定位器。
- 新增 `Sleep` 必须有注释说明原因，且优先有替代条件等待。
- 创建项目流程连续执行 5 次无环境污染。

### 里程碑 3：第一批核心用例资产建设

周期建议：3-5 周。

目标：

- 形成可用于每日验证的冒烟集。
- 形成可用于版本验证的核心回归集。
- 将稳定性压测与普通回归分离。

建议用例分层：

- 冒烟集：
  - App 启动并进入项目首页。
  - 创建项目并删除项目。
  - 进入设备页。
  - 进入连接设备页。
- 核心回归集：
  - 新建项目：必填、可选字段、删除清理。
  - 项目列表：搜索、打开、更多操作入口。
  - 设备连接：已连接、未连接、连接失败处理。
  - 司南万象：进入页面、状态展示、数据获取成功/失败判断。
- 专项稳定性集：
  - 蓝牙连接循环。
  - 司南万象连接循环。
  - App 重启恢复。

重点任务：

- 为用例补充 `[Documentation]` 和 `[Tags]`。
- 建立标签规范，例如：
  - `smoke`
  - `regression`
  - `project`
  - `equipment`
  - `stability`
  - `requires_device`
  - `destructive`
- 测试数据集中管理：
  - 项目名使用时间戳或构建号前缀。
  - 蓝牙目标设备从变量文件读取。
  - 清理失败时保留日志并尽量恢复。
- 稳定性压测参数化：
  - 循环次数从变量读取。
  - 失败阈值从变量读取。
  - 每轮结果输出结构化日志。

交付物：

- `tests/smoke/` 可作为每日构建入口。
- `tests/regression/` 覆盖第一批核心业务。
- `tests/stability/` 或独立标签承载长时间压测。
- 测试数据变量文件或数据目录。

验收标准：

- 冒烟集执行时间控制在 5-10 分钟内。
- 核心回归集可以按标签选择执行。
- 稳定性压测不会阻塞普通冒烟和回归。

### 里程碑 4：CI 与可观测性完善

周期建议：2-4 周，可与里程碑 2、3 并行。

目标：

- Jenkins 不只是执行脚本，而是成为可诊断的测试平台入口。

重点任务：

- 将 `ci/jenkins_verify.bat` 中的环境路径改成 Jenkins 参数或节点环境变量，减少硬编码。
- 支持以下执行方式：
  - 按标签执行：`--include smoke`
  - 按 suite 执行：`--suite CreateNewProject`
  - 按文件清单执行：使用 `robot_args.txt`
- 归档关键产物：
  - `output.xml`
  - `log.html`
  - `report.html`
  - Appium log
  - 失败截图
  - 可选 logcat
- 企业微信通知中补充：
  - 执行标签/suite。
  - 设备 ID。
  - APK 版本或构建号。
  - 失败用例列表摘要。
- 为 Jenkins 增加并发控制策略：
  - 同一设备同一时间只允许一个任务占用。
  - 长时间稳定性测试使用独立节点或独立标签。

交付物：

- 参数化 Jenkins Job。
- 清晰的结果归档结构。
- 失败通知中可直接定位到报告和日志。

验收标准：

- 任意一次失败都能在 10 分钟内定位到失败步骤、截图和 Appium 日志。
- Jenkins 可按设备、标签、suite 选择执行。
- 通知内容能区分启动失败、安装失败、测试失败、通知失败。

## 6. 推荐任务优先级

### P0：必须先做

- 统一配置入口，避免本地、CI、脚本多套变量。
- 改造冒烟用例，形成稳定的最小验证集。
- 清理用例层裸定位器和关键硬编码。
- 替换关键路径上的固定等待。
- 补充 README 的本地运行和 Jenkins 运行说明。

### P1：下一批推进

- 补齐页面就绪关键字。
- 建立标签规范并改造现有用例。
- 新增第一批项目管理、设备连接核心回归用例。
- Jenkins 参数化执行 suite/tag。
- 企业微信通知增加设备、APK、失败摘要。

### P2：成熟化建设

- 引入 Robocop 或自定义静态检查。
- 增加 PR 检查，阻止新增裸定位器和无说明 `Sleep`。
- 建立设备池和设备占用机制。
- 增加 logcat 自动采集。
- 建立失败分类统计，例如环境问题、设备问题、产品缺陷、脚本问题。

## 7. 下一阶段建议目录调整

建议逐步形成以下结构：

```text
SurveyMasterAutoTesting/
├── ci/
├── docs/
│   ├── conventions.md
│   └── next-stage-plan.md
├── resources/
│   ├── keywords/
│   │   ├── common/
│   │   ├── flows/
│   │   └── pages/
│   ├── locators/
│   │   └── android/
│   └── variables/
│       ├── env.example.yaml
│       └── test_data.example.yaml
├── tests/
│   ├── smoke/
│   ├── regression/
│   └── stability/
├── scripts/
├── README.md
└── requirements.txt
```

其中：

- `env.example.yaml` 保存环境配置模板。
- `test_data.example.yaml` 保存测试数据模板。
- 真实设备配置和个人测试数据不提交到仓库。
- 长时间压测建议从 `regression` 中拆出，避免影响常规回归效率。

## 8. 近期可直接拆分的任务清单

### 框架与配置

- 新增 `resources/variables/env.example.yaml`。
- 将 `_sanity_open_app.robot` 改为复用公共启动关键字。
- 删除或迁移重复定义的 `${APP_PACKAGE}`。
- README 增加本地环境准备、启动 Appium、运行 smoke、查看报告说明。
- 明确 Python 版本建议，当前 README 写 Python 3.8+，CI 脚本强制 Python 3.14，需要统一。

### 稳定性治理

- 替换 `tests/regression/NewProject/LuoWangConnectFail.robot` 中的固定等待。
- 将底部导航判断封装为页面关键字。
- 将蓝牙目标设备名 `T61S00167` 移到变量文件。
- 将项目名 `AutoTestingProject` 改为可追踪的动态名称。
- 为创建项目流程补充创建成功断言和删除成功断言。

### 用例资产

- 为现有用例补充 `[Documentation]`、`[Tags]`。
- 新增 `smoke` 标签。
- 新增项目页基础冒烟用例。
- 新增设备页基础冒烟用例。
- 将稳定性循环用例标记为 `stability`，默认 CI 不执行。

### CI

- Jenkins 支持按 `ROBOT_INCLUDE_TAGS` 或 `ROBOT_SUITE` 参数执行。
- 归档 Appium log 和失败截图。
- 企业微信通知增加失败用例摘要。
- 将默认 `DEVICE_ID` 从脚本中移除，改为 Jenkins 参数必填或节点配置。

### 质量门禁

- 增加一个轻量检查脚本，扫描：
  - `tests/` 中是否出现裸定位器。
  - `tests/` 中是否出现未注释的 `Sleep`。
  - 用例是否缺少 `[Documentation]`。
  - 用例是否缺少 `[Tags]`。
- 在 PR 或 Jenkins 中先以 warning 方式运行，稳定后再改为阻断。

## 9. 风险与应对

### 9.1 移动端 UI 自动化天然不稳定

应对：

- 用条件等待替换固定等待。
- 每个流程执行前后做环境复位。
- 失败时保留截图、Appium log、必要时保留 logcat。

### 9.2 设备和外设依赖强

应对：

- 设备 ID、蓝牙目标设备、外设名称全部变量化。
- 稳定性测试和普通回归分开执行。
- Jenkins 做设备占用控制。

### 9.3 用例扩展后维护成本上升

应对：

- 严格保持 `tests -> flows -> pages -> locators/common` 的分层。
- 定位器集中维护。
- PR 检查阻止用例层直接写定位器。

### 9.4 CI 环境与本地环境不一致

应对：

- 统一变量模板。
- README 明确依赖版本和运行命令。
- Jenkins 输出最终使用的关键配置，但避免输出敏感信息。

## 10. 建议衡量指标

下一阶段可以用以下指标判断项目是否进入稳定建设期：

- 冒烟集通过率：连续 5 次本地/CI 执行通过率达到 90% 以上。
- 用例规模：形成 5-10 条稳定冒烟/核心回归用例。
- 失败可诊断性：失败报告中至少包含截图、失败关键字、设备 ID、Appium log。
- 分层合规：`tests/` 中不直接出现裸定位器。
- 配置合规：设备 ID、包名、Appium 地址不在用例中硬编码。
- 执行效率：冒烟集控制在 10 分钟以内，稳定性集单独执行。

## 11. 建议结论

下一阶段的核心不是快速堆大量用例，而是先把框架基线、配置、等待、复位、日志和 CI 闭环打稳。只要这些基础能力稳定，后续扩展项目管理、设备连接、测量、工具等业务模块时，维护成本会明显降低。

推荐执行顺序：

1. 先统一配置和冒烟入口。
2. 再治理关键字层稳定性。
3. 然后沉淀第一批核心用例。
4. 最后把 CI 做成按标签、按设备、按构建可追踪的执行入口。
