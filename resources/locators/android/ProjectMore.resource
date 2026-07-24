*** Variables ***
# 项目页“更多”二级入口；共享 tv_title，使用 resource-id + 精确文本，无 XPath。
&{ProjectMore}
# 工程向导入口：共享 resource-id，使用精确文案区分。
...    PROJECT_WIZARD=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("工程向导")
# 地物管理入口：共享 resource-id，使用精确文案区分。
...    FEATURE_MANAGEMENT=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("地物管理")
# 面库入口：共享 resource-id，使用精确文案区分。
...    SURFACE_STORE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("面库")
# Rinex 转换入口：共享 resource-id，使用精确文案区分。
...    RINEX_CONVERSION=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("Rinex转换")
