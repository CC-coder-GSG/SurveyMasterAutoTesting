# 设备信息界面相关操作流程
*** Settings ***
Resource    ../../keywords/pages/Equipment/EquipmentInformation.resource
Resource    ../../keywords/pages/GuideActivity.resource



*** Keywords ***
# 寻找重启界面进行深度重启
Deep Restart
# 流程：点击设备信息按钮，滑动寻找重启界面，点击深度重启按钮，等待重启中按钮消失
    EquipmentInformation Button Click
    Scroll To Restart and Tap
    Tap Deep Restart Button
