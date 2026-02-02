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
    ...    unicodeKeyboard=${UNICODE_KEYBOARD}
    ...    resetKeyboard=${RESET_KEYBOARD}

Close SurveyMaster App
    Close Application
