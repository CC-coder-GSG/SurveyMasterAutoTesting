*** Settings ***
Documentation    主界面底部导航操作；所有点击均引用 Home 定位器和原子动作。
Resource    ../../locators/android/Home.resource
Resource    ../common/actions.resource
Resource    ../common/assert.resource
Resource    ../common/wait.resource

*** Keywords ***
Main Navigation Should Be Ready
    [Documentation]    校验主界面底部导航及四个核心入口均已加载。
    Wait Visible    ${Home.BOTTOM_NAVIGATION}    30s
    Should Be Visible    ${Home.PROJECT_TAB}
    Should Be Visible    ${Home.EQUIPMENT_TAB}
    Should Be Visible    ${Home.MEASURE_TAB}
    Should Be Visible    ${Home.TOOLS_TAB}

Open Project Tab
    [Documentation]    点击底部导航的“项目”入口。
    Tap    ${Home.PROJECT_TAB}

Open Equipment Tab
    [Documentation]    点击底部导航的“设备”入口。
    Tap    ${Home.EQUIPMENT_TAB}

Open Measure Tab
    [Documentation]    点击底部导航的“测量”入口。
    Tap    ${Home.MEASURE_TAB}

Open Tools Tab
    [Documentation]    点击底部导航的“工具”入口。
    Tap    ${Home.TOOLS_TAB}
