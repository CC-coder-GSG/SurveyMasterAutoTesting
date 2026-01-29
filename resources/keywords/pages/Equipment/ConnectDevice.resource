*** Settings ***
Resource    ../../../locators/android/ConnectDevice.resource
Resource    ../../../locators/android/Popups.resource
Resource    ../../pages/GuideActivity.resource

*** Keywords ***
Tap Target Device
    # 点击进入蓝牙连接界面
    Tap    ${ConnectDevice.Target_Device}

Wait Search And Connect Bluetooth Device
    [Arguments]    ${text}
    Sleep    20s   
    Scroll To And Tap Text Contains    ${text}