*** Settings ***
Library    AppiumLibrary
Resource    ../../resources/keywords/flows/cloud_login.resource

*** Variables ***
${REMOTE_URL}    http://127.0.0.1:4723
${UDID}          1302c4b2
${APP_PKG}       com.sinognss.sm.free
${APP_ACT}       com.sinognss.sm.guide.ui.GuideActivity
${USERNAME}      wangchao@sinognss.com
${PASSWORD}      147258

*** Test Cases ***
登录云服务冒烟测试
    Open Application    ${REMOTE_URL}
    ...    platformName=Android
    ...    automationName=UiAutomator2
    ...    udid=${UDID}
    ...    appPackage=${APP_PKG}
    ...    appActivity=${APP_ACT}
    ...    noReset=true

    Sleep    5s    # 等待状态刷新

    登录云服务流程    ${USERNAME}    ${PASSWORD}

    # 验证是否登录成功
    验证登录成功

    # 强制退出 App
    Terminate Application    ${APP_PKG}
