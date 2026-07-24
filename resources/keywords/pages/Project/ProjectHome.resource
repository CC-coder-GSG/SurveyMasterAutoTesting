*** Settings ***
Documentation    项目主页只读校验；验证项目管理和坐标系统等核心入口。
Resource    ../../../locators/android/ProjectHome.resource
Resource    ../../common/assert.resource
Resource    ../../common/wait.resource

*** Keywords ***
Project Home Should Be Ready
    [Documentation]    等待项目主页加载，并校验两个核心项目入口。
    Wait Visible    ${ProjectHome.PROJECT_MANAGEMENT}
    Should Be Visible    ${ProjectHome.COORDINATE_SYSTEM}
