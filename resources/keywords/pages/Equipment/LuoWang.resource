*** Settings ***
Resource    ../../common/actions.resource
Resource    ../../../locators/android/Popups.resource
Resource    ../../../locators/android/GuideActivity.resource
Resource    ../../../keywords/pages/GuideActivity.resource


*** Keywords ***
# 点击司南万象功能按钮
Tap SinoWanXiang Button
    Tap    ${GuideActivity.SinoWanXiang_BUTTON}

# 等待万象接入差分（判断逻辑为差分状态为浮动或者固定）
Wait WanXiang Get Data
    Wait Until Element Text Matches Regexp    ${GuideActivity.Fix_Status}    ^(固定|浮动)$    30s    1s

# 点击设备信息按钮
Tap EquipmentInformation Button
    EquipmentInformation Button Click

# 等待搜星完成（单点状态）
Wait Search for Sattlite
    Wait Visible    ${GuideActivity.Fix_Status}
    Wait Until Element Text Matches Regexp    ${GuideActivity.Fix_Status}    ^(单点)$    90s    1s