*** Settings ***
Library    AppiumLibrary
Variables  ../../variables/env_test.yaml

*** Keywords ***
Open SurveyMaster App
    Open Application
    ...    ${APPIUM_SERVER}
    ...    platformName=${PLATFORM_NAME}
    ...    automationName=${AUTOMATION_NAME}
    ...    deviceName=${DEVICE_NAME}
    ...    udid=${UDID}
    ...    appPackage=${APP_PACKAGE}
    ...    appActivity=${APP_ACTIVITY}
    ...    appWaitActivity=${APP_WAIT_ACTIVITY}
    ...    noReset=${NO_RESET}
    ...    autoGrantPermissions=${AUTO_GRANT_PERMISSIONS}
    ...    newCommandTimeout=${NEW_COMMAND_TIMEOUT}
    # 使用 Appium 自带的输入法，不弹出系统键盘
    ...    unicodeKeyboard=${True}
    # 测试结束后重置回系统默认输入法（避免测试完手机无法打字）
    ...    resetKeyboard=${True}

Close SurveyMaster App
    Close Application
