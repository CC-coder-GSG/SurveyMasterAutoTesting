*** Settings ***
Resource    ../pages/Equipment/LuoWang.resource

*** Keywords ***
# 点击底部设备按钮并点击司南万象功能按钮
Tap SinoWanXiang Button First
    Equipment_Bottom Button Click
    Tap SinoWanXiang Button