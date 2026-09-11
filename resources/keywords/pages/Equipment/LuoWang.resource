*** Settings ***
Documentation    司南万象接入稳定性测试关键字库
Resource    ../../common/actions.resource
Resource    ../../../locators/android/Popups.resource
Resource    ../../../locators/android/GuideActivity.resource
Resource    ../../../keywords/pages/GuideActivity.resource


*** Keywords ***
Tap SinoWanXiang Button
    [Documentation]    点击司南万象功能按钮，进入司南万象接入页面
    Tap    ${GuideActivity.SinoWanXiang_BUTTON}

Wait WanXiang Get Data
    [Documentation]    等待万象接入差分，判断逻辑为差分状态为浮动或者固定
    Wait Until Element Text Matches Regexp    ${GuideActivity.Fix_Status}    ^(固定|浮动)$    30s    1s

Tap EquipmentInformation Button
    [Documentation]    点击设备信息按钮，进入设备信息页面
    EquipmentInformation Button Click

Wait Search For Satellite
    [Documentation]    等待搜星完成，判断逻辑为差分状态为单点
    Wait Visible    ${GuideActivity.Fix_Status}
    Wait Until Element Text Matches Regexp    ${GuideActivity.Fix_Status}    ^(单点|固定|浮动)$    90s    1s
