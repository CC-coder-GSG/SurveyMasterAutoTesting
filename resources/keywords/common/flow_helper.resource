*** Settings ***
Library    AppiumLibrary
# 如果您想复用 assert.resource 里的逻辑，也可以引入，但直接写更简单
# Resource   assert.resource

*** Variables ***
${APP_PACKAGE}        com.sinognss.sm.free
${TARGET_ACTIVITY}    com.sinognss.sm.guide.ui.GuideActivity

*** Keywords ***
Force Jump To Guide Page
    [Documentation]    底层关键字：强制跳转回主页
    Start Activity    ${APP_PACKAGE}    ${TARGET_ACTIVITY}
    Wait Activity     ${TARGET_ACTIVITY}    5s

Run And Reset
    [Arguments]    ${flow_keyword}    @{args}
    [Documentation]    封装器：运行传入的业务流程关键字。如果失败先截图，最后强制复位。
    
    # 运行原本的业务流程
    Run Keyword    ${flow_keyword}    @{args}
    
    # 【修改重点】使用 Run Keywords 串联两个操作
    # 1. 如果测试失败，立即截图 (保留现场)
    # 2. AND (注意是大写)
    # 3. 无论成功失败，都执行复位
    [Teardown]    Run Keywords    Run Keyword If Test Failed    Capture Page Screenshot    AND    Force Jump To Guide Page