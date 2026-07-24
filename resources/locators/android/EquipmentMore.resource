*** Variables ***
# 设备页“更多”二级入口；共享 tv_title，使用 resource-id + 精确文本，无 XPath。
&{EquipmentMore}
# 静态采集入口：共享 resource-id，使用精确文案区分。
...    STATIC_COLLECTION=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("静态采集")
# 天线设置入口：共享 resource-id，使用精确文案区分。
...    ANTENNA_SETTINGS=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("天线设置")
# 外挂数传入口：共享 resource-id，使用精确文案区分。
...    EXTERNAL_RADIO=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("外挂数传")
# 固件升级入口：共享 resource-id，使用精确文案区分。
...    FIRMWARE_UPGRADE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("固件升级")
# 高级设置入口：共享 resource-id，使用精确文案区分。
...    ADVANCED_SETTINGS=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("高级设置")
# SIM 卡充值入口：共享 resource-id，使用精确文案区分。
...    SIM_RECHARGE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("SIM卡充值")
# 电离层入口：共享 resource-id，使用精确文案区分。
...    IONOSPHERE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("电离层")
# 重新定位入口：该入口会改变接收机状态；共享 resource-id，使用精确文案区分。
...    RELOCATE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("重新定位")
