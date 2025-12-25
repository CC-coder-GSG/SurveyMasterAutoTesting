*** Settings ***
Library    AppiumLibrary

*** Variables ***
${APP_PACKAGE}        com.sinognss.sm.free
# 这是真实的主页 Activity，用于等待验证，而不是用于跳转
${MAIN_ACTIVITY}      com.sinognss.sm.main.ui.MainActivity

*** Keywords ***
Restart App To Home
    [Documentation]    强力复位：直接杀掉 APP 并重启，确保回到主页
    ...    适用场景：MainActivity 不允许直接跳转，且 GuideActivity 无法复位时。
    
    # 1. 杀掉 APP 进程 (相当于 adb shell am force-stop)
    Terminate Application    ${APP_PACKAGE}
    
    # 2. 重新激活 APP (相当于点击桌面图标，会自动走 Guide -> Main 的流程)
    Activate Application     ${APP_PACKAGE}
    
    # 3. 等待真实的主页加载出来 (给它一点时间启动)
    Wait Until Page Contains Element    android=new UiSelector().text("项目")    10

Run And Reset
    [Arguments]    ${flow_keyword}    @{args}
    [Documentation]    封装器：运行业务流程 -> 失败截图 -> 重启复位
    
    # 运行原本的业务流程
    Run Keyword    ${flow_keyword}    @{args}
    
    # 【Teardown】
    # 1. 如果失败，先截图
    # 2. 无论成功失败，都执行重启复位 (Restart App To Home)
    [Teardown]    Run Keywords    Run Keyword If    '${KEYWORD STATUS}' == 'FAIL'    Capture Page Screenshot    AND    Restart App To Home
