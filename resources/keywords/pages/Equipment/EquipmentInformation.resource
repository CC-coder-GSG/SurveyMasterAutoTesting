*** Settings ***
Resource    ../../common/actions.resource
Resource    ../../../locators/android/Popups.resource
Resource    ../../../locators/android/EquipmentInformation.resource


*** Keywords ***
# 滚动界面并点击进入重启界面
Scroll To Restart and Tap
    Scroll To And Tap Text Contains    重启    ${EquipmentInformation.Swipe_Container}

# 点击深度重启按钮、等待重启弹窗消失
Tap Deep Restart Button
    Tap    ${EquipmentInformation.Deep_Restart}
    Tap    ${Popups.CONFRIM_POPUP_CONFRIM}
    Wait Gone   ${Popups.Restart_POPUP}    60s
