# Conventions / 编码规约（Robot Framework + Appium）

> 目的：让用例可读、可复用、可维护；让定位稳定；让 CI 上的失败可快速定位。

---

## 1. 分层边界
### 1.1 common（原子层）
**只做“单一原子动作”**，不包含业务语义，不跨页面、不拼流程。
- ✅ 允许：Click / Input / Swipe / Wait / Open App / Close App / Screenshot / Get Text / Assert 基础断言
- ❌ 禁止：出现“创建项目/导入工程/放样”这类业务词；一次关键字完成多步跨页面操作

**原子层关键字要“可复用、可组合、可定位问题”**：
- 失败时日志要能看出“点了哪个控件/输入了什么/等了多久”。

### 1.2 pages（页面层）
**只封装单个页面内的操作**：一个页面文件对应一个页面（或一个模块子页）。
- ✅ 允许：`点击新建按钮`、`输入项目名称`、`校验页面标题`（都在同一页面内）
- ❌ 禁止：跨页面跳转后的操作；把多个页面动作拼成完整业务

页面层必须通过 `locators/` 引用定位器，不允许在关键字里写裸定位表达式。

### 1.3 flows（流程层）
**只做“由多个页面操作拼装成可复用流程”**，例如“创建新项目流程”。
- ✅ 允许：按步骤调用多个页面关键字，形成完整流程
- ✅ 建议：流程关键字可提供少量参数（项目名、坐标源、模板等）
- ❌ 禁止：写底层定位或原子动作（应调用 pages/common）

### 1.4 tests（业务用例层）
**只写业务验证**：Given/When/Then 形式表达意图（先说明前提 → 再说明动作 → 最后说明期望）。
- ✅ 允许：调用 flows/pages，添加断言、标签、前后置
- ❌ 禁止：直接做 UI 原子操作；直接写定位器；复制粘贴长流程

---


## 2. 命名与文件组织

### 2.1 文件命名
- `resources/keywords/common/*.resource`：动词开头，表达“能力”，如 `tap.resource` `wait.resource` `assert.resource`
- `resources/keywords/pages/<PageName>.resource`：页面名清晰唯一，如 `ProjectListPage.resource`
- `resources/keywords/flows/<FlowName>.resource`：业务流程名，如 `CreateNewProjectFlow.resource`
- `tests/<type>/<feature>/<CaseName>.robot`：用例名表达“验证点”，如 `CreateProject_Should_Succeed.robot`

### 2.2 关键字命名（统一风格）
- 原子层：`Tap` / `Input Text` / `Wait Until Visible`（动词 + 宾语，可复用）
- 页面层：`ProjectListPage.Tap New`、`ProjectListPage.Input Name`（每个页面的事件需要写注释，哪个位置的哪个按钮做了哪个操作）
- 流程层：`Create New Project`、`Import Project From Template`（需要写注释，说明做了什么事情）
- 用例层：`[Documentation]` 写清楚目的、前置、期望结果


---

## 3. 定位器（locators）规约

### 3.1 定位器必须集中维护
- 所有定位器必须写在 `resources/locators/android/`（按页面拆分）
- pages/flows/tests **禁止**出现裸定位：例如 `id=...`、`android=...` 直接写在关键字里（除非临时调试且不能提交）

### 3.2 定位策略优先级（从高到低）
1. `accessibility_id`（最稳、最推荐）
2. `id`（资源 id 稳定时使用）
3. `android=UiSelector(...)`
4. `xpath`(使用Xpath必须注明原因)

### 3.3 每个定位器必须带注释
- 说明来源（控件文案/资源 id/页面区域）
- 说明稳定性风险（是否多语言、是否会变）
- 注明定位的按钮名称和控件类型，方便Ctrl+F定位

---


## 4. 等待与稳定性（禁止“睡眠驱动”）

### 4.1 禁止在 tests/pages/flows 里随意 `Sleep`
- `Sleep` 只能作为兜底，且必须写原因注释、时长不超过 2s
- 所有等待优先使用：`Wait Until Element Is Visible/Enabled`、`Wait Until Page Ready`

### 4.2 每次点击/输入前必须保证元素可交互

### 4.3 失败时必须能自动产出定位信息
- 失败截图（至少一张）
- 当前页面关键信息（activity/page title/关键控件存在性）

---


## 5. 断言（Assert）规约

### 5.1 断言必须写在 tests（或 pages 的“页面校验”关键字中）
- common 只提供通用断言能力（如 `Should Contain Text`），不包含业务判断

### 5.2 每个用例至少 1 个“核心断言”
- 不允许只有“跑完流程没报错”就算通过

---


## 6. 测试数据与配置

### 6.1 禁止硬编码环境参数
- 包名、设备 id、Appium 地址等必须来自变量文件/命令行参数/CI 参数
- 测试数据（项目名、点位等）建议集中到 `resources/variables/` 或 `tests/data/`

### 6.2 数据要可重复执行
- 产生的数据要可清理（或使用随机但可追踪的前缀）
- 同一用例重复跑不会互相污染

---


## 7. 日志与可观测性（CI 友好）

### 7.1 关键步骤必须有日志
- flows 中每个大步骤至少一条日志（例如：开始创建项目/选择模板/保存）
- 日志用“动作 + 关键参数”，避免无意义输出

### 7.2 失败自动增强信息
- 失败截图（命名包含用例名 + 时间）

---

## 8. 代码风格（Robot Framework）

- 统一使用 **4 空格缩进**
- 关键字参数命名清晰，避免 `${a}` `${b}` 这种
- 资源文件顶部写 `[Documentation]`：说明用途、依赖、示例调用
- 单个关键字不要过长：> 20 行要考虑拆分

---

## 9. 提交与评审（建议）

### 9.1 PR 自检清单（提交前必过）
- 是否遵守分层（tests 不写定位/原子操作）
- 是否新增/更新了 locators 注释
- 是否避免 Sleep（或说明原因）
- 用例是否可重复跑、是否可清理数据
- 是否添加必要 tags、文档、示例

### 9.2 变更原则
- 修改页面结构/控件：优先改 locators + pages，尽量不动 tests
- 流程变化：优先改 flows，不要在 tests 里堆步骤

---
