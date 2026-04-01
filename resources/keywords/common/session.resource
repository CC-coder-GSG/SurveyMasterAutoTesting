*** Settings ***
Library         AppiumLibrary
Library         OperatingSystem
Variables       ../../variables/env_test.yaml


*** Keywords ***
Open SurveyMaster App
    [Documentation]    启动 APP，并在启动前通过 ADB 静默授予所有所需权限，避免系统权限弹窗
    # Runtime 权限：等价于用户点击”允许”，完全静默
    Run    adb -s ${UDID} shell pm grant ${APP_PACKAGE} android.permission.ACCESS_FINE_LOCATION
    Run    adb -s ${UDID} shell pm grant ${APP_PACKAGE} android.permission.ACCESS_COARSE_LOCATION
    Run    adb -s ${UDID} shell pm grant ${APP_PACKAGE} android.permission.BLUETOOTH_CONNECT
    Run    adb -s ${UDID} shell pm grant ${APP_PACKAGE} android.permission.BLUETOOTH_SCAN
    Run    adb -s ${UDID} shell pm grant ${APP_PACKAGE} android.permission.CAMERA
    Run    adb -s ${UDID} shell pm grant ${APP_PACKAGE} android.permission.POST_NOTIFICATIONS
    Run    adb -s ${UDID} shell pm grant ${APP_PACKAGE} android.permission.READ_PHONE_STATE
    Run    adb -s ${UDID} shell pm grant ${APP_PACKAGE} android.permission.READ_MEDIA_IMAGES
    Run    adb -s ${UDID} shell pm grant ${APP_PACKAGE} android.permission.READ_MEDIA_VIDEO
    Run    adb -s ${UDID} shell pm grant ${APP_PACKAGE} android.permission.READ_MEDIA_AUDIO
    # 特殊 AppOps 权限：无法通过 pm grant 授予，需要 appops
    Run    adb -s ${UDID} shell appops set ${APP_PACKAGE} MANAGE_EXTERNAL_STORAGE allow
    Run    adb -s ${UDID} shell appops set ${APP_PACKAGE} SYSTEM_ALERT_WINDOW allow
    Run    adb -s ${UDID} shell appops set ${APP_PACKAGE} WRITE_SETTINGS allow
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
    ...    implicitWaitTimeout=${0}
    ...    ignoreHiddenApiPolicyError=${IGNORE_HIDDEN_API_POLICY_ERROR}
    ...    skipDeviceInitialization=${SKIP_DEVICE_INITIALIZATION}

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
