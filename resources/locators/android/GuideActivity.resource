*** Variables ***
# 兼容旧页面关键字的主界面定位器；共享入口均使用 resource-id + 精确文本，未使用 XPath。
&{GuideActivity}
# 项目管理按钮：宫格标题共享 tv_title，使用 resource-id + 精确文本区分。
...    PROJECT_MANAGEMENT_BUTTON=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("项目管理")
# 底部项目页：四项共享标题 id，使用 resource-id + 精确文本区分。
...    PROJECT_PAGE_BUTTON=android=new UiSelector().resourceId("com.sinognss.sm.free:id/fixed_bottom_navigation_title").text("项目")
# 底部设备页：四项共享标题 id，使用 resource-id + 精确文本区分。
...    EQUIPMENT_PAGE_BUTTON=android=new UiSelector().resourceId("com.sinognss.sm.free:id/fixed_bottom_navigation_title").text("设备")
# 底部测量页：四项共享标题 id，使用 resource-id + 精确文本区分。
...    MEASURE_PAGE_BUTTON=android=new UiSelector().resourceId("com.sinognss.sm.free:id/fixed_bottom_navigation_title").text("测量")
# 底部工具页：四项共享标题 id，使用 resource-id + 精确文本区分。
...    TOOLS_PAGE_BUTTON=android=new UiSelector().resourceId("com.sinognss.sm.free:id/fixed_bottom_navigation_title").text("工具")
# 司南万象功能按钮：入口会直接启动工作模式；共享 tv_title，使用精确文本区分。
...    SinoWanXiang_BUTTON=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("司南万象")
# 固定/浮点/单点状态显示：稳定且唯一的 resource-id。
...    Fix_Status=id=com.sinognss.sm.free:id/tv_solution_status
# 设备信息功能按钮：共享 tv_title，使用 resource-id + 精确文本区分。
...    Equipment_BUTTON=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("设备信息")
# 设备连接功能按钮：共享 tv_title，使用 resource-id + 精确文本区分。
...    Device_Connect_BUTTON=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("连接设备")
