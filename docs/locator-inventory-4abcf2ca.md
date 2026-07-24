# R60 真机 UI 定位器采集记录

## 采集环境

- ADB 设备：`4abcf2ca`
- 型号 / 系统：R60 / Android 11（API 30）
- 包名：`com.sinognss.sm.free`
- App 版本：`v4.0.4.0(40400040)`
- 自动化：Appium 2.19.0 / UiAutomator2 4.1.5
- 会话策略：`noReset=true`，未清空 App 数据

## 定位器策略

本次按以下优先级整理：

1. 唯一且稳定的 `resource-id`，写作 `id=...`
2. 稳定的 `content-desc`，写作 `accessibility_id=...`
3. 多控件共享 id 时，使用 `android=new UiSelector().resourceId(...).text(...)`
4. 仅当动态值控件既共享 id、又没有文本/content-desc 可稳定区分时使用 XPath

仅 `EquipmentInformation.resource` 中设备名称、序列号和固件版本三个动态值使用 XPath。原因已逐项写在定位器上方：这些值都复用 `tv_value`，只能通过稳定的行标题和相邻关系区分。其余本次新增定位器均未使用 XPath。

## 已整理页面

- 公共首页与四个底部导航：`Home.resource`
- 项目首页及项目功能：`ProjectHome.resource`、`CoordinateSystem.resource`、`PointStore.resource`、`ParameterCalculation.resource`、`DataTransfer.resource`、`BaseStationTranslation.resource`、`CodeManagement.resource`、`SoftwareSettings.resource`、`CloudLogin.resource`、`ProjectMore.resource`
- 设备首页及设备功能：`EquipmentHome.resource`、`ConnectDevice.resource`、`EquipmentInformation.resource`、`PositionInformation.resource`、`RegistrationInformation.resource`、`EquipmentMore.resource`、`StationModePopup.resource`
- 测量入口和已观察页面：`Measure.resource`、`MeasureMap.resource`、`RoadManagement.resource`
- 工具入口和已观察计算页：`Tools.resource`、`ToolCalculations.resource`

`Project.resource` 已有较完整的项目管理/创建/回收站/导入/属性定位器，本次保留该文件的现有工作区修改，没有覆盖。

## 状态变更风险

以下入口不是普通页面导航，点击后会直接操作接收机或业务状态，定位器注释中已标明，不应放入只读 smoke 用例：

- 司南万象
- 移动站
- 基准站
- 重新定位
- 实测/测量按钮
- 软件设置中的开关
- 注册、保存、应用、导入、上传、删除等确认动作

## 覆盖边界

已采集当前账号、当前项目、当前接收机连接状态下可直接到达并安全读取的页面，以及测量/工具主页上滑后出现的入口。依赖登录、文件选择、特定项目数据、付费授权或会提交业务数据的后续页面未强行进入；这些页面出现后应继续沿用相同优先级补充定位器。
