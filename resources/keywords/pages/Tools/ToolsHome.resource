*** Settings ***
Documentation    工具主页只读校验；只检查入口，不修改项目或设备状态。
Resource    ../../../locators/android/Tools.resource
Resource    ../../common/assert.resource
Resource    ../../common/wait.resource

*** Keywords ***
Tools Home Should Be Ready
    [Documentation]    等待工具主页加载，并校验面积计算和角度转换入口。
    Wait Visible    ${Tools.AREA_CALCULATION}
    Should Be Visible    ${Tools.ANGLE_CONVERSION}
