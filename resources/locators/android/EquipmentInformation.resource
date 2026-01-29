*** Variables ***
# 设备信息界面定位
&{EquipmentInformation}
# 进入重启界面
...    Restart=android=new UiSelector().className("android.view.ViewGroup").instance(8)
# 深度重启按钮
...    Deep_Restart=id=com.sinognss.sm.free:id/btn_freset