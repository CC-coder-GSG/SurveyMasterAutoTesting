*** Settings ***
Library    AppiumLibrary

*** Variables ***
${APP_PACKAGE}        com.sinognss.sm.free
${TARGET_ACTIVITY}    com.sinognss.sm.guide.ui.GuideActivity

*** Keywords ***
Force Jump To Guide Page
    [Documentation]    底层关键字：强制跳转回主页
    # 强制启动主页 Activity，实现复位
    Start Activity    ${APP_PACKAGE}    ${TARGET_ACTIVITY}
    # 等待主页加载完成（防止跳转太慢）
    Wait Activity    ${TARGET_ACTIVITY}    5s

Run And Reset
    [Arguments]    ${flow_keyword}    @{args}
    [Documentation]    封装器：运行传入的业务流程关键字，无论成功失败，结束后都强制复位
    
    # 运行原本的业务流程
    Run Keyword    ${flow_keyword}    @{args}
    
    # 【关键】Teardown 保证无论上面成功还是失败，都会执行复位
    [Teardown]    Force Jump To Guide Page