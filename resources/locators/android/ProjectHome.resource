*** Variables ***
# 项目主导航页入口；宫格项共享 tv_title，使用 resource-id + 精确文本，未使用 XPath。
&{ProjectHome}
# 项目管理入口：共享 resource-id，使用精确中文文案区分。
...    PROJECT_MANAGEMENT=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("项目管理")
# 坐标系统入口：共享 resource-id，使用精确中文文案区分。
...    COORDINATE_SYSTEM=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("坐标系统")
# 坐标点库入口：共享 resource-id，使用精确中文文案区分。
...    POINT_STORE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("坐标点库")
# 参数计算入口：共享 resource-id，使用精确中文文案区分。
...    PARAMETER_CALCULATION=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("参数计算")
# 数据导入入口：共享 resource-id，使用精确中文文案区分。
...    DATA_IMPORT=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("数据导入")
# 数据导出入口：共享 resource-id，使用精确中文文案区分。
...    DATA_EXPORT=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("数据导出")
# 基站平移入口：共享 resource-id，使用精确中文文案区分。
...    BASE_STATION_TRANSLATION=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("基站平移")
# 代码管理入口：共享 resource-id，使用精确中文文案区分。
...    CODE_MANAGEMENT=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("代码管理")
# 云服务入口：共享 resource-id，使用精确中文文案区分。
...    CLOUD_SERVICE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("云服务")
# 软件设置入口：共享 resource-id，使用精确中文文案区分。
...    SOFTWARE_SETTINGS=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("软件设置")
# 更多入口：共享 resource-id，使用精确中文文案区分。
...    MORE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("更多")
