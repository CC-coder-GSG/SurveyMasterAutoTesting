*** Settings ***
Documentation    测量大师核心主导航冒烟流程；只读巡检项目、设备、测量和工具主页。
Resource    ../pages/Startup.resource
Resource    ../pages/Home.resource
Resource    ../pages/Project/ProjectHome.resource
Resource    ../pages/Equipment/EquipmentHome.resource
Resource    ../pages/Measure/MeasureHome.resource
Resource    ../pages/Tools/ToolsHome.resource

*** Keywords ***
Prepare Core Navigation Smoke
    [Documentation]    处理首次启动状态，并确认项目主页可用。
    Log    [SMOKE] 准备首次启动状态并检查主导航
    Handle First Launch Experience
    Main Navigation Should Be Ready
    Open Project Tab
    Project Home Should Be Ready

Browse All Core Navigation Tabs
    [Documentation]    依次只读巡检设备、测量和工具主页。
    Log    [SMOKE] 检查设备主页
    Open Equipment Tab
    Equipment Home Should Be Ready
    Log    [SMOKE] 检查测量主页
    Open Measure Tab
    Measure Home Should Be Ready
    Log    [SMOKE] 检查工具主页
    Open Tools Tab
    Tools Home Should Be Ready

Return To Project Home
    [Documentation]    返回项目主页并执行最终核心断言。
    Log    [SMOKE] 返回项目主页完成巡检
    Open Project Tab
    Project Home Should Be Ready
