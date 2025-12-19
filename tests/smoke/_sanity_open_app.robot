*** Settings ***
Library    AppiumLibrary

*** Variables ***
${REMOTE_URL}    http://127.0.0.1:4723
${UDID}          4e83cae7
${APP_PKG}       com.sinognss.sm.free
${APP_ACT}       com.sinognss.sm.guide.ui.GuideActivity

*** Test Cases ***
Sanity - Open App
    Open Application    ${REMOTE_URL}
    ...    platformName=Android
    ...    automationName=UiAutomator2
    ...    udid=${UDID}
    ...    appPackage=${APP_PKG}
    ...    appActivity=${APP_ACT}
    ...    noReset=true
    Sleep    3s
    Close Application
