*** Variables ***
# 功能界面定位
&{GuideActivity}
# 项目管理按钮定位
...    PROJECT_MANAGEMENT_BUTTON=android=new UiSelector().text("项目管理")
# 底部项目页面定位
...    PROJECT_PAGE_BUTTON=android=new UiSelector().text("项目")
# 底部设备页面定位
...    EQUIPMENT_PAGE_BUTTON=android=new UiSelector().text("设备")
# 底部工具页面定位
...    TOOLS_PAGES_BUTTON=android=new UiSelector().text("工具")
# resourceId("com.sinognss.sm.free:id/fixed_bottom_navigation_container").instance(3)
# 司南万象功能按钮
...    SinoWanXiang_BUTTON=android=new UiSelector().text("司南万象")
# 固定状态显示
...    Fix_Status=id=com.sinognss.sm.free:id/tv_solution_status
# 设备信息功能按钮
...    Equipment_BUTTON=android=new UiSelector().text("设备信息")
# 设备连接功能按钮
...    Device_Connect_BUTTON=android=new UiSelector().text("连接设备")