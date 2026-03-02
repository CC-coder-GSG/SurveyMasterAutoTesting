*** Settings ***
Resource    ../../locators/android/Popups.resource
Resource    ../../locators/android/ConnectDevice.resource
Resource    ../pages/GuideActivity.resource
Resource    ../../keywords/pages/Equipment/ConnectDevice.resource

*** Keywords ***
Wait Connect Device Popup Disappear
# 等待连接设备弹窗消失
    Wait Gone    ${Popups.Connect_Loading_Icon}

Connect A Device
# 连接一台指定设备
    Equipment_Bottom Button Click
    DeviceConnect Button Click
    Tap Target Device
    Wait Search And Connect Bluetooth Device    T61S00162


