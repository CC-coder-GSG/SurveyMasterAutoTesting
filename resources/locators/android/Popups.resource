*** Settings ***
Library    AppiumLibrary

*** Variables ***
&{Popups}
# 确认窗口的弹窗，确认按钮
...    CONFRIM_POPUP_CONFRIM=id=com.sinognss.sm.free:id/btn_positive
# 确认窗口的弹窗，取消按钮
...    CONFRIM_POPUP_CANCEL=id=com.sinognss.sm.free:id/btn_negative