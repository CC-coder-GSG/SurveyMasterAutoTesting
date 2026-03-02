*** Settings ***
Library    AppiumLibrary
Library    OperatingSystem
Variables  ../../variables/env_test.yaml

*** Keywords ***
Open SurveyMaster App
    [Documentation]    启动 APP，并在启动前强制赋予“管理所有文件”权限
    Run    adb -s ${UDID} shell appops set ${APP_PACKAGE} MANAGE_EXTERNAL_STORAGE allow
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

Handle All Files Access Permission If Needed
    [Documentation]    所有文件访问权限 / 授予所有文件的管理权限
    ${onPage}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element
    ...    android=new UiSelector().textContains("所有文件")
    ...    2s

    IF    ${onPage}
        Log    [PERM] On MANAGE_EXTERNAL_STORAGE page
        # ② 优先点 Switch（通用）
        ${hasSwitch}=    Run Keyword And Return Status
        ...    Page Should Contain Element
        ...    android=new UiSelector().className("android.widget.Switch")

        IF    ${hasSwitch}
            Click Element    android=new UiSelector().className("android.widget.Switch")
        ELSE
            # ③ 有些 ROM switch 不是 Switch 类，兜底用“可点击”的控件
            #    尽量点右侧那个（通常是第一个可点击开关控件）
            Click Element    android=new UiSelector().clickable(true).classNameMatches(".*(Switch|CheckBox|Button).*")
        END

        Sleep    1s
        Press Keycode    4
        Sleep    1s
    END

Open App And Handle Permissions
    Open SurveyMaster App
    Handle All Files Access Permission If Needed