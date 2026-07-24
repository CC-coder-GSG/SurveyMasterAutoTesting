*** Variables ***
# 注册信息页；优先使用唯一 resource-id，共享状态项用 resource-id + 精确文本，无 XPath。
&{RegistrationInformation}
# 返回按钮：稳定 content-desc“返回”。
...    BACK_BUTTON=accessibility_id=返回
# 注册码输入框：稳定且唯一的 resource-id。
...    LICENSE_KEY_INPUT=id=com.sinognss.sm.free:id/et_license_key
# 扫码获取注册码：稳定且唯一的 resource-id。
...    SCAN_LICENSE_BUTTON=id=com.sinognss.sm.free:id/btn_licence_qr
# 离线注册按钮：稳定且唯一的 resource-id。
...    REGISTER_BUTTON=id=com.sinognss.sm.free:id/btn_register
# 在线注册按钮：稳定且唯一的 resource-id。
...    ONLINE_REGISTER_BUTTON=id=com.sinognss.sm.free:id/btn_online_register
# 已注册功能标题：稳定且唯一的 resource-id，包含当前设备序列号。
...    REGISTERED_FEATURE_TITLE=id=com.sinognss.sm.free:id/title_fun
# 移动站功能项：tv_fun 复用，使用 resource-id + 精确文本区分。
...    ROVER_FEATURE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_fun").text("移动站")
# 基准站功能项：tv_fun 复用，使用 resource-id + 精确文本区分。
...    BASE_FEATURE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_fun").text("基准站")
# 司南万象功能项：tv_fun 复用，使用 resource-id + 精确文本区分。
...    SINOWANXIANG_FEATURE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_fun").text("司南万象")
# 北斗功能项：tv_fun 复用，使用 resource-id + 精确文本区分。
...    BEIDOU_FEATURE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_fun").text("北斗")
# PPP 功能项：tv_fun 复用，使用 resource-id + 精确文本区分。
...    PPP_FEATURE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_fun").text("PPP")
# 永久使用状态：tv_state 复用，使用 resource-id + 精确文本区分。
...    PERMANENT_STATE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_state").text("永久使用")
# 服务中状态：tv_state 复用，使用 resource-id + 精确文本区分。
...    IN_SERVICE_STATE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_state").text("服务中")
