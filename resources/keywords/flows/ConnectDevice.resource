*** Settings ***
Resource    ../../locators/android/Popups.resource
Resource    ../../locators/android/ConnectDevice.resource
Resource    ../common/wait.resource

*** Keywords ***
Wait Connect Device Popup Disappear
# 等待连接设备弹窗消失
    Wait Gone    ${Popups.Connect_Loading_Icon}