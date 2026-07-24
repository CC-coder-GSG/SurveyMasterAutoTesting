*** Settings ***
Documentation    设备主页只读校验；不连接设备、不改变接收机状态。
Resource    ../../../locators/android/EquipmentHome.resource
Resource    ../../common/assert.resource
Resource    ../../common/wait.resource

*** Keywords ***
Equipment Home Should Be Ready
    [Documentation]    等待设备主页加载，并校验连接设备和设备信息入口。
    Wait Visible    ${EquipmentHome.CONNECT_DEVICE}
    Should Be Visible    ${EquipmentHome.DEVICE_INFORMATION}
