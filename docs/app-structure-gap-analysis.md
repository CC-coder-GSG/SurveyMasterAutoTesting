# 测量大师 App 结构观察与脚本库补充建议

## 1. 分析范围

本次通过 Appium MCP 连接真机观察测量大师 App 页面结构，并对照当前自动化测试脚本库进行缺口分析。

观察环境：

- 设备 UDID：`ABBT6R6115001196`
- 设备型号：HONOR `AAK-AN00`
- Android 版本：16，API 36
- App 包名：`com.sinognss.sm.free`
- App 版本：`v4.0.4.0(40400030)`
- 当前网络：Wi-Fi 与移动网络均已连接
- 当前蓝牙：开启

本次只做页面结构观察和入口级浏览，未执行会创建、删除、连接设备、测量采集等会改变业务状态的操作。

## 2. App 主体结构

App 首页底部有 4 个主导航：

- 项目
- 设备
- 测量
- 工具

顶部公共区域包含：

- 返回按钮：`content-desc=返回`
- 标题区域：常见为 `com.sinognss.sm.free:id/tv_middle`
- 扫码连接：`com.sinognss.sm.free:id/qr_scan`，`content-desc=扫码连接`
- 连接提示：`com.sinognss.sm.free:id/tv_connect_hint`，文本为“点击此处连接设备”
- 底部导航容器：`com.sinognss.sm.free:id/nav_bar`
- 主功能宫格：`com.sinognss.sm.free:id/gv_func`
- App 版本号：`com.sinognss.sm.free:id/tv_version`

建议补充：

- 增加 `resources/locators/android/Home.resource` 或 `Main.resource`。
- 增加首页/主导航页面关键字，例如：
  - `Home Page Should Be Ready`
  - `Tap Bottom Project`
  - `Tap Bottom Equipment`
  - `Tap Bottom Measure`
  - `Tap Bottom Tools`
  - `App Version Should Be Visible`
- 当前 `GuideActivity.resource` 承担了过多首页导航职责，建议逐步拆成 `Home.resource`，避免“GuideActivity”命名与实际首页职责不一致。

## 3. 项目模块

### 3.1 项目首页入口

项目页功能入口包括：

- 项目管理
- 坐标系统
- 坐标点库
- 参数计算
- 数据导入
- 数据导出
- 基站平移
- 代码管理
- 更多

这些入口在页面上主要表现为：

- 宫格容器：`com.sinognss.sm.free:id/gv_func`
- 宫格项：`com.sinognss.sm.free:id/item`
- 标题文本：`com.sinognss.sm.free:id/tv_title`

现状：

- 当前脚本主要覆盖“项目管理 -> 新建项目 -> 删除项目”。
- 坐标系统、坐标点库、参数计算、数据导入/导出、基站平移、代码管理还没有形成独立页面资源和用例。

建议补充：

- 建立 `resources/locators/android/HomeProject.resource` 或按业务拆分对应 locator。
- 先补入口可达性用例，不急于覆盖深层业务：
  - 项目页所有入口可见。
  - 点击入口后能进入正确标题页。
  - 返回后仍回到项目页。

### 3.2 项目管理页

观察到的稳定控件：

- 标题：文本“项目管理”
- 更多按钮：`com.sinognss.sm.free:id/layout_more`
- 项目管理主容器：`com.sinognss.sm.free:id/dl_cloud`
- 搜索容器：`com.sinognss.sm.free:id/sv_search`
- 搜索输入框：`com.sinognss.sm.free:id/search_src_text`
- 项目列表标题：`com.sinognss.sm.free:id/tv_task_list`
- 排序文本：`com.sinognss.sm.free:id/tv_sort_by`
- 排序图标：`com.sinognss.sm.free:id/iv_sort`
- 项目列表：`com.sinognss.sm.free:id/lv_task`
- 列表滑动菜单容器：`com.sinognss.sm.free:id/layout_swipe_menu`
- 项目名称：`com.sinognss.sm.free:id/tv_task_name`
- 当前项目标识：`com.sinognss.sm.free:id/tv_current_task`
- 坐标系：`com.sinognss.sm.free:id/tv_coordinate`
- 项目详情：`com.sinognss.sm.free:id/tv_detail`
- 创建时间：`com.sinognss.sm.free:id/tv_create_time`
- 新建按钮：文本“新建”

当前脚本已有：

- `Project.PROJECT_LIST=id=com.sinognss.sm.free:id/dl_cloud`
- `Project.SEARCH_SEARCHBOX=id=com.sinognss.sm.free:id/search_bar`
- `Project.PROJECT_NAME_BOX=android=new UiSelector().text("${project_name}")`
- `Project.NEW_PROJECT_BUTTON=android=new UiSelector().text("新建")`

主要缺口：

- 搜索输入框目前使用 `search_bar`，但实际可输入控件是 `search_src_text`。
- 项目列表断言只等 `dl_cloud`，没有断言 `lv_task`、`tv_task_name`、`tv_current_task`。
- 新建/删除流程缺少“创建成功后项目出现在列表中”和“删除后项目不再存在”的强断言。
- 项目排序、搜索、更多菜单、打开项目、项目详情还没有覆盖。

建议补充 locator：

```robot
...    PROJECT_MANAGEMENT_TITLE=android=new UiSelector().text("项目管理")
...    PROJECT_MORE_BUTTON=id=com.sinognss.sm.free:id/layout_more
...    PROJECT_SEARCH_INPUT=id=com.sinognss.sm.free:id/search_src_text
...    PROJECT_LIST_VIEW=id=com.sinognss.sm.free:id/lv_task
...    PROJECT_TASK_NAME=id=com.sinognss.sm.free:id/tv_task_name
...    PROJECT_CURRENT_BADGE=id=com.sinognss.sm.free:id/tv_current_task
...    PROJECT_COORDINATE_TEXT=id=com.sinognss.sm.free:id/tv_coordinate
...    PROJECT_CREATE_TIME=id=com.sinognss.sm.free:id/tv_create_time
...    PROJECT_SORT_TEXT=id=com.sinognss.sm.free:id/tv_sort_by
...    PROJECT_SORT_ICON=id=com.sinognss.sm.free:id/iv_sort
```

建议补充用例：

- 项目管理页可打开并展示项目列表。
- 搜索项目名称后列表展示匹配结果。
- 创建项目后列表中出现该项目。
- 删除项目后列表中不再出现该项目。
- 当前项目应显示“当前”标识。
- 排序按钮可点击并保持页面稳定。

### 3.3 创建项目表单

观察到的稳定控件：

- 标题：文本“创建项目”
- 名称标签：`com.sinognss.sm.free:id/name_lbl`
- 名称输入框：`com.sinognss.sm.free:id/name_txt`
- 创建者标签：`com.sinognss.sm.free:id/operator_lbl`
- 创建者输入框：`com.sinognss.sm.free:id/operator_txt`
- 备注标签：`com.sinognss.sm.free:id/desc_lbl`
- 备注输入框：`com.sinognss.sm.free:id/description_txt`
- 复用项目文本：`com.sinognss.sm.free:id/tv_apply_task`
- 复用项目开关：`com.sinognss.sm.free:id/switch_apply_task`
- 坐标系标签：`com.sinognss.sm.free:id/coordinate_lbl`
- 坐标系选择：`com.sinognss.sm.free:id/ft_coordinate`
- 代码模板标签：`com.sinognss.sm.free:id/code_template_lbl`
- 代码模板选择：`com.sinognss.sm.free:id/ft_code_template`
- 投影信息：`com.sinognss.sm.free:id/tv_projection`
- 中央子午线：`com.sinognss.sm.free:id/tv_central_meridian`
- 未连接设备提示：`com.sinognss.sm.free:id/tv_central_meridian_hint`
- 确认按钮：文本“确认”

当前脚本已有名称、创建者、备注和确认按钮定位，但未覆盖复用项目、坐标系、代码模板、投影信息、未连接设备提示。

建议补充：

- 新建项目表单默认值断言。
- 未连接设备时提示“未连接设备，无法获取中央子午线”。
- 坐标系默认值为 `CGCS2000`。
- 项目名使用动态前缀，例如 `AUTO_${BUILD_NUMBER}_${timestamp}`，避免固定 `AutoTestingProject` 污染环境。

## 4. 设备模块

### 4.1 设备页入口

设备页顶部状态：

- 设备名称/连接状态：`com.sinognss.sm.free:id/device_name`，当前为“未连接”
- 版本信息：`com.sinognss.sm.free:id/version_txt`

设备页功能入口包括：

- 连接设备
- 司南万象
- 移动站
- 基准站
- 设备信息
- 位置信息
- 注册信息
- 更多
- 添加设备：`com.sinognss.sm.free:id/add_device`

现状：

- 当前脚本已有连接设备、司南万象、设备信息的部分资源。
- 移动站、基准站、位置信息、注册信息、添加设备还没有形成用例资产。

建议补充：

- 新增 `EquipmentHome.resource`，集中维护设备页入口和连接状态。
- 用例先覆盖：
  - 设备页可打开。
  - 未连接状态可识别。
  - 各入口可见。
  - 添加设备入口可见。

### 4.2 连接设备页

观察到的稳定控件：

- 标题：文本“连接设备”
- 接收机 tab：`com.sinognss.sm.free:id/button_receiver`
- 外设 tab：`com.sinognss.sm.free:id/button_peripheral`
- 设备类型标签：`com.sinognss.sm.free:id/device_type_txt`
- 设备类型下拉：`com.sinognss.sm.free:id/device_type_spinner`
- 当前设备类型：文本 `RTK`
- 连接方式标签：`com.sinognss.sm.free:id/connect_type_txt`
- 连接方式下拉：`com.sinognss.sm.free:id/connect_type_spinner`
- 当前连接方式：文本 `蓝牙`
- 扫码图标：`com.sinognss.sm.free:id/iv_qr_device`
- 目标设备：`com.sinognss.sm.free:id/tv_target_device`，当前为 `N82L01002`
- 蓝牙连接说明：`com.sinognss.sm.free:id/tv_bt_connect_desc`
- 连接按钮：`com.sinognss.sm.free:id/connect_btn`

当前脚本已有：

- `Connect_Device_Button=id=com.sinognss.sm.free:id/connect_btn`
- `Target_Device=id=com.sinognss.sm.free:id/tv_target_device`
- `Disconnect_Button=android=new UiSelector().text("断开")`

主要缺口：

- 缺少接收机/外设 tab 定位。
- 缺少设备类型、连接方式下拉定位。
- 缺少扫码入口定位。
- 缺少目标设备文本断言。
- 脚本中蓝牙目标设备名写死为 `T61S00167`，但当前设备页面显示目标设备为 `N82L01002`，环境数据不一致。
- `Wait Search And Connect Bluetooth Device` 中固定 `Sleep 20s`，建议替换为等待目标设备列表/目标设备文本出现。

建议补充 locator：

```robot
...    RECEIVER_TAB=id=com.sinognss.sm.free:id/button_receiver
...    PERIPHERAL_TAB=id=com.sinognss.sm.free:id/button_peripheral
...    DEVICE_TYPE_SPINNER=id=com.sinognss.sm.free:id/device_type_spinner
...    CONNECT_TYPE_SPINNER=id=com.sinognss.sm.free:id/connect_type_spinner
...    QR_DEVICE_BUTTON=id=com.sinognss.sm.free:id/iv_qr_device
...    TARGET_DEVICE_TEXT=id=com.sinognss.sm.free:id/tv_target_device
...    BLUETOOTH_DESC=id=com.sinognss.sm.free:id/tv_bt_connect_desc
...    CONNECT_BUTTON=id=com.sinognss.sm.free:id/connect_btn
```

建议补充用例：

- 打开连接设备页，断言默认设备类型为 `RTK`。
- 打开连接设备页，断言默认连接方式为 `蓝牙`。
- 目标设备名称应从变量读取并与页面展示一致。
- 接收机/外设 tab 可切换。
- 连接按钮可见且可点击状态正确。
- 未连接状态下返回设备页后仍显示“未连接”。

## 5. 测量模块

测量页入口包括：

- 点测量
- 激光交会
- 点放样
- CAD
- 光伏放样
- 线放样
- 边坡放样
- 道路放样
- 面放样
- 道路管理
- 塔基放样
- 基坑开挖线放样
- 挖机作业
- 铁路测量
- 海洋测量
- 更多

现状：

- `resources/keywords/pages/Measure/README.md` 存在，但没有具体页面资源。
- 当前没有测量模块用例。

建议优先级：

1. 先做入口可达性和未连接设备提示，不做真实测量。
2. 优先覆盖点测量、点放样、CAD、道路管理这类核心入口。
3. 后续再根据设备连接状态增加真实测量流程。

建议补充：

- `resources/locators/android/Measure.resource`
- `resources/keywords/pages/Measure/MeasureHome.resource`
- `tests/smoke/measure_entry_smoke.robot`

建议用例：

- 测量页入口全部可见。
- 点测量入口可打开并返回。
- 点放样入口可打开并返回。
- 未连接设备时进入测量功能应出现明确提示或阻断状态。
- CAD 入口可打开并展示页面标题。

## 6. 工具模块

工具页入口包括：

- 天正云转换
- CAD云瘦身
- 底图校正
- 面积计算
- 土方计算
- 角度转换
- 两点计算
- 点线距离
- 偏心点
- 偏转角
- 算旋转点
- 算交汇点
- 算等分角
- 划分线
- 测点平均值
- 激光测距
- 更多

现状：

- `resources/keywords/pages/Tools/README.md` 存在，但没有具体页面资源。
- 当前没有工具模块用例。

建议优先级：

1. 优先覆盖纯计算工具，减少对设备连接、网络、外设的依赖。
2. 首批建议选择：
   - 角度转换
   - 两点计算
   - 点线距离
   - 面积计算
3. 云转换、CAD 云瘦身等可能依赖网络或文件，应放到第二批。

建议补充：

- `resources/locators/android/Tools.resource`
- `resources/keywords/pages/Tools/ToolsHome.resource`
- `tests/smoke/tools_entry_smoke.robot`
- `tests/regression/Tools/` 下增加纯计算工具表单校验用例。

建议用例：

- 工具页入口全部可见。
- 角度转换页面可打开。
- 两点计算页面可打开。
- 点线距离页面可打开。
- 输入非法数据时应出现提示。
- 输入基础有效数据时结果可计算。

## 7. 当前脚本库总体缺口

### 7.1 定位器覆盖不完整

已有定位器集中在项目创建和设备连接主路径，缺少：

- 首页/主导航定位器。
- 项目管理列表项详细定位器。
- 创建项目表单高级字段定位器。
- 设备页主页定位器。
- 连接设备页完整定位器。
- 测量模块定位器。
- 工具模块定位器。

### 7.2 页面就绪关键字不足

建议每个模块至少补一个页面就绪关键字：

- `Home Page Should Be Ready`
- `Project Management Page Should Be Ready`
- `Create Project Page Should Be Ready`
- `Equipment Home Page Should Be Ready`
- `Connect Device Page Should Be Ready`
- `Measure Home Page Should Be Ready`
- `Tools Home Page Should Be Ready`

### 7.3 测试数据仍需变量化

当前风险点：

- 连接设备脚本中目标设备名固定为 `T61S00167`。
- 当前真机页面显示目标设备为 `N82L01002`。
- 创建项目流程使用固定项目名 `AutoTestingProject`。

建议：

- 在变量文件中增加：

```yaml
TARGET_RECEIVER_NAME: "N82L01002"
AUTO_PROJECT_PREFIX: "AUTO"
STABILITY_LOOP_COUNT: 100
STABILITY_FAIL_THRESHOLD: 3
```

### 7.4 Smoke 覆盖应先补入口级用例

下一阶段的 smoke 不应只验证 App 能启动，应覆盖：

- App 启动进入首页。
- 四个底部导航可切换。
- 项目管理页可打开。
- 创建项目表单可打开。
- 设备页可打开。
- 连接设备页可打开。
- 测量页可打开。
- 工具页可打开。

这些用例不需要真实连接设备，稳定性会比深层业务流更高，适合作为 CI 每日入口。

## 8. 建议新增文件清单

建议新增或扩展以下文件：

```text
resources/locators/android/Home.resource
resources/locators/android/EquipmentHome.resource
resources/locators/android/Measure.resource
resources/locators/android/Tools.resource

resources/keywords/pages/Home.resource
resources/keywords/pages/Equipment/EquipmentHome.resource
resources/keywords/pages/Measure/MeasureHome.resource
resources/keywords/pages/Tools/ToolsHome.resource

tests/smoke/home_navigation_smoke.robot
tests/smoke/project_entry_smoke.robot
tests/smoke/equipment_entry_smoke.robot
tests/smoke/measure_entry_smoke.robot
tests/smoke/tools_entry_smoke.robot

tests/regression/Project/SearchProject.robot
tests/regression/Project/CreateProjectWithDefaults.robot
tests/regression/Equipment/ConnectDevicePageDefaults.robot
tests/regression/Tools/AngleConvert.robot
tests/regression/Tools/TwoPointCalculate.robot
```

## 9. 建议实施顺序

### 第一批：低风险结构补齐

- 新增首页和主导航定位器。
- 新增项目管理页详细定位器。
- 新增连接设备页完整定位器。
- 新增四个主导航入口 smoke。
- 将目标设备名和项目名前缀变量化。

### 第二批：当前主流程增强

- 创建项目流程增加成功/删除断言。
- 项目管理增加搜索用例。
- 连接设备页增加默认值断言。
- 替换连接设备流程里的固定 `Sleep 20s`。

### 第三批：模块扩展

- 测量模块先做入口和未连接提示。
- 工具模块先做纯计算工具。
- 设备模块补移动站、基准站、位置信息、注册信息入口级覆盖。

## 10. 结论

当前自动化脚本库的分层方向是正确的，但覆盖面还集中在少数业务路径。通过 MCP 真机观察可以确认，App 页面上有大量稳定资源 ID 可直接用于补强定位器和断言。

下一阶段最值得补的不是立即增加复杂业务流，而是：

1. 先补首页、项目、设备、测量、工具的入口级结构覆盖。
2. 再增强项目管理和连接设备这两个已有主流程。
3. 然后把测量和工具模块从 README 占位推进到可执行 smoke 用例。
4. 同步将设备名、项目名、循环次数等环境数据变量化。

这样可以较快把脚本库从“少量流程可跑”推进到“App 主结构可持续监控”的阶段。
