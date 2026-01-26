*** Settings ***
Library    AppiumLibrary
Resource    ../../../resources/keywords/flows/cloud_login.resource
Variables   ../../../resources/variables/env_test.yaml

*** Variables ***
${USERNAME}      wangchao@sinognss.com
${PASSWORD}      147258

*** Test Cases ***
#登录云服务
Test_LoginCloud
    Open Application    ${APPIUM_SERVER}
    ...    platformName=Android
    ...    automationName=UiAutomator2
    ...    udid=${UDID}
    ...    appPackage=${APP_PACKAGE}
    ...    appActivity=${APP_ACTIVITY}
    ...    noReset=true

    #登录云服务流程
    Login Cloud Service    ${USERNAME}    ${PASSWORD}

    # 验证是否登录成功
    Verify Login Success

    # 强制退出 App
    # Terminate Application    ${APP_PACKAGE}
