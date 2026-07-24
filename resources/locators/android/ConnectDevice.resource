*** Variables ***
# 连接设备页；优先使用唯一 resource-id，未使用 XPath。
&{ConnectDevice}
# 返回按钮：稳定 content-desc“返回”。
...    BACK_BUTTON=accessibility_id=返回
# 接收机 Tab：稳定且唯一的 resource-id。
...    RECEIVER_TAB=id=com.sinognss.sm.free:id/button_receiver
# 外设 Tab：稳定且唯一的 resource-id。
...    PERIPHERAL_TAB=id=com.sinognss.sm.free:id/button_peripheral
# 设备类型标签：稳定且唯一的 resource-id。
...    DEVICE_TYPE_LABEL=id=com.sinognss.sm.free:id/device_type_txt
# 设备类型下拉框：稳定且唯一的 resource-id。
...    DEVICE_TYPE_SPINNER=id=com.sinognss.sm.free:id/device_type_spinner
# 连接方式标签：稳定且唯一的 resource-id。
...    CONNECT_TYPE_LABEL=id=com.sinognss.sm.free:id/connect_type_txt
# 连接方式下拉框：稳定且唯一的 resource-id。
...    CONNECT_TYPE_SPINNER=id=com.sinognss.sm.free:id/connect_type_spinner
# 扫码设备入口：稳定且唯一的 resource-id。
...    QR_DEVICE_BUTTON=id=com.sinognss.sm.free:id/iv_qr_device
# 目标设备名称：稳定且唯一的 resource-id，文本随选择变化。
...    TARGET_DEVICE_TEXT=id=com.sinognss.sm.free:id/tv_target_device
# 蓝牙连接说明：稳定且唯一的 resource-id。
...    BLUETOOTH_DESCRIPTION=id=com.sinognss.sm.free:id/tv_bt_connect_desc
# 连接/断开按钮：稳定且唯一的 resource-id，文本会按状态变化。
...    CONNECT_BUTTON=id=com.sinognss.sm.free:id/connect_btn
# RTK 当前类型文本：item_txt 可能复用，使用 resource-id + 精确文本区分。
...    RTK_TYPE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/item_txt").text("RTK")
# 蓝牙当前方式文本：item_txt 可能复用，使用 resource-id + 精确文本区分。
...    BLUETOOTH_TYPE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/item_txt").text("蓝牙")
# 兼容旧关键字：连接按钮，指向同一个稳定 resource-id。
...    Connect_Device_Button=id=com.sinognss.sm.free:id/connect_btn
# 兼容旧关键字：目标设备，指向同一个稳定 resource-id。
...    Target_Device=id=com.sinognss.sm.free:id/tv_target_device
# 兼容旧关键字：断开状态仍直接按唯一按钮 id 定位，由测试断言按钮文本。
...    Disconnect_Button=id=com.sinognss.sm.free:id/connect_btn
