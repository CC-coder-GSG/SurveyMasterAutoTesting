*** Variables ***
# 采集环境：R60 / Android 11 / com.sinognss.sm.free v4.0.4.0(40400040)。
# 定位策略：唯一 resource-id > accessibility id > resource-id + 精确文本 UiSelector；本文件未使用 XPath。
&{Home}
# 主页面根容器：稳定且唯一的 resource-id，用于页面就绪判断。
...    ROOT=id=com.sinognss.sm.free:id/root_container
# 顶部操作栏：稳定且唯一的 resource-id。
...    ACTION_BAR=id=com.sinognss.sm.free:id/actionbar1
# 返回按钮：无 resource-id，但有稳定 content-desc“返回”，优先使用 accessibility id。
...    BACK_BUTTON=accessibility_id=返回
# 当前项目名称：稳定且唯一的 resource-id，文本随当前项目变化。
...    CURRENT_PROJECT=id=com.sinognss.sm.free:id/tv_middle
# 扫码连接：稳定且唯一的 resource-id，比 content-desc 定位更直接。
...    QR_SCAN=id=com.sinognss.sm.free:id/qr_scan
# 主功能宫格：稳定且唯一的 resource-id。
...    FEATURE_GRID=id=com.sinognss.sm.free:id/gv_func
# 底部导航栏：稳定且唯一的 resource-id。
...    BOTTOM_NAVIGATION=id=com.sinognss.sm.free:id/nav_bar
# 项目导航项：四项共享 resource-id，使用 resource-id + 精确文本区分。
...    PROJECT_TAB=android=new UiSelector().resourceId("com.sinognss.sm.free:id/fixed_bottom_navigation_title").text("项目")
# 设备导航项：四项共享 resource-id，使用 resource-id + 精确文本区分。
...    EQUIPMENT_TAB=android=new UiSelector().resourceId("com.sinognss.sm.free:id/fixed_bottom_navigation_title").text("设备")
# 测量导航项：四项共享 resource-id，使用 resource-id + 精确文本区分。
...    MEASURE_TAB=android=new UiSelector().resourceId("com.sinognss.sm.free:id/fixed_bottom_navigation_title").text("测量")
# 工具导航项：四项共享 resource-id，使用 resource-id + 精确文本区分。
...    TOOLS_TAB=android=new UiSelector().resourceId("com.sinognss.sm.free:id/fixed_bottom_navigation_title").text("工具")
# 定位状态：稳定且唯一的 resource-id，值会随接收机状态变化。
...    SOLUTION_STATUS=id=com.sinognss.sm.free:id/tv_solution_status
# 差分延迟：稳定且唯一的 resource-id，值会实时变化。
...    DIFFERENTIAL_DELAY=id=com.sinognss.sm.free:id/tv_diff_delayed
# 水平精度：稳定且唯一的 resource-id，值会实时变化。
...    HORIZONTAL_ACCURACY=id=com.sinognss.sm.free:id/tv_diff_h
# 垂直精度：稳定且唯一的 resource-id，值会实时变化。
...    VERTICAL_ACCURACY=id=com.sinognss.sm.free:id/tv_diff_v
# 使用卫星数：稳定且唯一的 resource-id，值会实时变化。
...    USED_SATELLITES=id=com.sinognss.sm.free:id/tv_used_satellite
# 跟踪卫星数：稳定且唯一的 resource-id，值会实时变化。
...    TRACKED_SATELLITES=id=com.sinognss.sm.free:id/tv_tracked_satellite
# 纬度/北坐标值：稳定且唯一的 resource-id，值会实时变化。
...    POSITION_X=id=com.sinognss.sm.free:id/x_txt
# 经度/东坐标值：稳定且唯一的 resource-id，值会实时变化。
...    POSITION_Y=id=com.sinognss.sm.free:id/y_txt
# 高程值：稳定且唯一的 resource-id，值会实时变化。
...    POSITION_Z=id=com.sinognss.sm.free:id/z_txt
# App 版本号：稳定且唯一的 resource-id。
...    APP_VERSION=id=com.sinognss.sm.free:id/tv_version
# 接收机序列号：稳定且唯一的 resource-id，文本随设备变化。
...    RECEIVER_SERIAL=id=com.sinognss.sm.free:id/tv_serial_no
