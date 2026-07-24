*** Variables ***
# 设备主导航页；入口共享 tv_title，使用 resource-id + 精确文本，未使用 XPath。
&{EquipmentHome}
# 当前设备名称：稳定且唯一的 resource-id，文本随连接设备变化。
...    DEVICE_NAME=id=com.sinognss.sm.free:id/device_name
# 接收机固件版本：稳定且唯一的 resource-id。
...    RECEIVER_VERSION=id=com.sinognss.sm.free:id/version_txt
# 添加设备：稳定且唯一的 resource-id。
...    ADD_DEVICE=id=com.sinognss.sm.free:id/add_device
# 连接设备入口：共享 resource-id，使用精确中文文案区分。
...    CONNECT_DEVICE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("连接设备")
# 司南万象入口：此入口会直接启动工作模式，调用前应确认允许改变接收机状态。
...    SINOWANXIANG=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("司南万象")
# 移动站入口：此入口会直接启动移动站，调用前应确认允许改变接收机状态。
...    ROVER_MODE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("移动站")
# 基准站入口：此入口会直接启动基准站，调用前应确认允许改变接收机状态。
...    BASE_MODE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("基准站")
# 设备信息入口：共享 resource-id，使用精确中文文案区分。
...    DEVICE_INFORMATION=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("设备信息")
# 位置信息入口：共享 resource-id，使用精确中文文案区分。
...    POSITION_INFORMATION=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("位置信息")
# 注册信息入口：共享 resource-id，使用精确中文文案区分。
...    REGISTRATION_INFORMATION=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("注册信息")
# 设备更多入口：共享 resource-id，使用精确中文文案区分。
...    MORE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("更多")
