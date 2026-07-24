*** Settings ***
Documentation    测量大师核心主导航冒烟测试。
...    前置：Jenkins 已安装待测 APK，并由父套件建立 Appium 会话。
...    目的：验证项目、设备、测量、工具四个主模块可进入且核心入口可见。
...    期望：四个主模块加载成功，最后可回到项目主页；测试不写入业务数据。
Resource    ../../resources/keywords/flows/MainNavigationSmoke.resource
Resource    ../../resources/keywords/common/teardown.resource
Test Tags    smoke    core_navigation    read_only

*** Test Cases ***
Core Navigation Should Be Available
    [Documentation]    Given 首次启动已处理；When 巡检四个主导航；Then 项目主页仍可正常使用。
    Given Prepare Core Navigation Smoke
    When Browse All Core Navigation Tabs
    Then Return To Project Home
