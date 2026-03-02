*** Settings ***
Library    AppiumLibrary

*** Variables ***
&{Popups}
# 确认窗口的弹窗，确认按钮
...    CONFRIM_POPUP_CONFRIM=id=com.sinognss.sm.free:id/btn_positive
# 确认窗口的弹窗，取消按钮、知道了按钮
...    CONFRIM_POPUP_CANCEL=id=com.sinognss.sm.free:id/btn_negative
# 重启中的弹窗
...    Restart_POPUP=id=android:id/message
# 连接设备弹窗，“连接设备”文本
...    Connect_Device=id=com.sinognss.sm.free:id/tv_title
# 连接设备弹窗，加载图标
...    Connect_Loading_Icon=id=com.sinognss.sm.free:id/progress
# 连接设备弹窗，“自动连接中...”文本
...    Connect_Text_zidonglianjie=id=com.sinognss.sm.free:id/message
# 连接设备弹窗，取消按钮
...    Connect_Cancel_Button=id=com.sinognss.sm.free:id/btn_negative
# 连接失败弹窗，“连接失败”文本
...    Connect_Fail_Text=id=com.sinognss.sm.free:id/tv_title