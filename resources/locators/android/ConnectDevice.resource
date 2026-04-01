*** Variables ***
# 连接设备界面定位
&{ConnectDevice}
# 连接按钮
...                 Connect_Device_Button=id=com.sinognss.sm.free:id/connect_btn
# 目标设备
...                 Target_Device=id=com.sinognss.sm.free:id/tv_target_device
# 断开按钮（设备已连接时显示）
...                 Disconnect_Button=android=new UiSelector().text("断开")
