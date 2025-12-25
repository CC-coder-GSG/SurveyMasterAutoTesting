*** Settings ***
Library    AppiumLibrary
# 如果您想复用 assert.resource 里的逻辑，也可以引入，但直接写更简单
# Resource   assert.resource

*** Variables ***
${APP_PACKAGE}        com.sinognss.sm.free
${TARGET_ACTIVITY}    com.sinognss.sm.guide.ui.GuideActivity

*** Keywords ***
Force Jump To Guide Page
    [Documentation]    底层关键字：强制跳转回引导页
    Run Keyword And Ignore Error    Start Activity    ${APP_PACKAGE}    ${TARGET_ACTIVITY}
    Run Keyword And Ignore Error    Wait Activity     ${TARGET_ACTIVITY}    5s


Run And Reset
    [Arguments]    ${flow_keyword}    @{args}
    # 1) 执行流程，但不要让失败直接中断后续清理
    ${status}    ${msg}=    Run Keyword And Ignore Error    ${flow_keyword}    @{args}

    # 2) 失败才截图（截图失败也不要挡住“强制返回”）
    Run Keyword If    '${status}' == 'FAIL'    Run Keyword And Ignore Error    Capture Page Screenshot

    # 3) 无论成功失败都强制返回引导页（失败也别影响收尾）
    Run Keyword And Ignore Error    Force Jump To Guide Page

    # 4) 把原始失败抛回去，让用例最终仍是 FAIL
    Run Keyword If    '${status}' == 'FAIL'    Fail    ${msg}
