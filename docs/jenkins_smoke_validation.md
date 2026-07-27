# 测量大师 Jenkins 冒烟测试验证记录

## 验证目标

- 按项目分层规则新增核心主导航冒烟用例。
- 验证 Jenkins `SurveyMaster-RF-Test` 从 APK 获取、安装、代码检出、Appium 启动、Robot 执行到报告发布的完整链路。
- 修复 Jenkins 流水线中文注释乱码，并记录排查过程中发现的问题。

## 冒烟用例

入口用例：`tests/smoke/CoreNavigationSmoke.robot`

用例覆盖测量大师启动后的核心主导航，包括项目、设备、工具和我的页面。实现遵循现有分层：

- 元素定位位于 `resources/locators/android/`。
- 点击、等待等原子操作复用 `resources/keywords/common/`。
- 页面行为位于 `resources/keywords/pages/`。
- 跨页面业务流程位于 `resources/keywords/flows/MainNavigationSmoke.resource`。
- 首次安装时的隐私协议、所有文件访问权限和 Android 运行时权限由启动页关键字统一处理。

本地静态验证命令：

```powershell
python -m robot --dryrun --output NONE --log NONE --report NONE --suite Tests.smoke.CoreNavigationSmoke tests
```

结果：`1 test, 1 passed, 0 failed`。

## Jenkins 参数

| 参数 | 值 |
| --- | --- |
| JOB_NAME | `s4040` |
| PACKAGE | `56 | #56SinognssRelease_free.42(40400042)Release` |
| APK_PATH | `result/2607271107/com.sinognss.sm.free_Sinognss_40400042_4.0.4.0_shield.apk` |
| TEST_ROBOTS | `tests/smoke/CoreNavigationSmoke.robot` |
| TEST_BRANCH | `main` |
| DEVICE_ID | `SD13640032` |
| PLATFORM_VERSION | `12` |
| AUTOMATION_NAME | `UiAutomator2` |

上游 `s4040` 最新构建 #57 没有可复制的 APK，因此按“最新可用制品”选择了 #56。

## 最终结果

- Jenkins 构建：[#175](http://192.168.2.229:8080/job/SurveyMaster-RF-Test/175/)
- 状态：`SUCCESS`
- 总耗时：232 秒
- Robot 结果：`1 test, 1 passed, 0 failed`
- APK 获取、卸载与安装、测试仓库检出、Appium 会话、Robot 报告归档与发布均成功。
- 控制台中的中文用例名和流水线输出正常显示，未再出现乱码。

## 问题与处理记录

| 问题 | 影响 | 处理 |
| --- | --- | --- |
| Jenkins 内联流水线中的中文注释编码异常 | 配置页注释出现乱码 | 统一以 UTF-8 保存 `ci/ci_piplines`，并以 UTF-8 更新 Jenkins Job XML；回读配置确认无乱码标记。 |
| 流水线参数缺少校验，Robot 文件选择不稳定 | 空值或错误路径可能在较晚阶段才失败 | 增加参数校验、规范化 `TEST_ROBOTS` 路径并从 `tests` 根目录选择套件。 |
| Jenkins 服务环境找不到 Node.js/Appium，且全局 Appium 驱动依赖不兼容 | Appium 无法启动或加载 UiAutomator2 | 兼容常见 Node.js/NVM 路径，在工作区固定 Appium `2.19.0` 和 UiAutomator2 `4.1.5`。 |
| ADB/Appium 后台进程被 Jenkins durable task 跟踪，ADB 工作目录锁定测试目录 | 阶段卡住、检出目录无法清理 | 隔离后台进程 cookie，调整工作目录，并在阶段结束和 `post` 中显式停止 ADB。 |
| Jenkins 配置中的设备标识已失效 | APK 安装阶段找不到目标设备 | 在流水线中检查在线设备并输出诊断；本次使用实际在线设备 `SD13640032`。 |
| Appium Settings 辅助包状态异常 | UiAutomator2 会话创建失败 | 会话前重置 `io.appium.settings`，恢复设备初始化并传递必要能力。 |
| 首次安装包含隐私协议、所有文件访问及多种运行时权限页面 | 应用无法进入主界面，导航断言失败 | 在启动页层新增可选页面处理，分别支持“使用应用时允许”和通用“允许”按钮。 |
| 上游最新构建 #57 没有 APK 制品 | Copy Artifact 无法使用最新构建 | 选择最新存在目标 APK 的构建 #56，并在本记录中注明。 |
| #174 通过 API 触发时使用了旧参数名 | 参数回退到占位值，未进入测试阶段 | 按 Job 当前参数名 `JOB_NAME`、`TEST_ROBOTS`、`DEVICE_ID` 重新触发 #175。 |

排查构建集中在 #156 至 #174；这些失败分别暴露了脚本审批、设备、Node.js/Appium、ADB 生命周期和首次启动权限问题。所有阻断项修复后，#175 完整通过。
