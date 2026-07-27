*** Settings ***
Documentation    首次启动页面操作；只处理安装后可能出现的隐私协议和界面风格确认。
Resource    ../../locators/android/Startup.resource
Resource    ../common/actions.resource
Resource    ../common/session.resource
Resource    ../common/wait.resource

*** Keywords ***
Handle First Launch Experience
    [Documentation]    如果首次启动弹窗存在则确认；已初始化的安装会直接跳过。
    ${privacy_visible}=    Run Keyword And Return Status
    ...    Wait Visible
    ...    ${Startup.PRIVACY_AGREEMENT_CONFIRM}
    ...    15s
    IF    ${privacy_visible}
        Log    [STARTUP] 接受隐私协议
        Tap    ${Startup.PRIVACY_AGREEMENT_CONFIRM}
        Handle All Files Access Permission If Needed    15s
        Handle Runtime Permission Dialogs
        ${style_visible}=    Run Keyword And Return Status
        ...    Wait Visible
        ...    ${Startup.STYLE_SAVE_BUTTON}
        ...    20s
        IF    ${style_visible}
            Log    [STARTUP] 保存默认界面风格
            Tap    ${Startup.STYLE_SAVE_BUTTON}
        END
    END

Handle Runtime Permission Dialogs
    [Documentation]    处理首次启动时可能连续出现的 Android 运行时权限弹窗。
    FOR    ${index}    IN RANGE    5
        ${foreground_permission_visible}=    Run Keyword And Return Status
        ...    Wait Visible
        ...    ${Startup.RUNTIME_PERMISSION_ALLOW_WHILE_USING}
        ...    1.5s
        IF    ${foreground_permission_visible}
            Tap    ${Startup.RUNTIME_PERMISSION_ALLOW_WHILE_USING}
            Wait Page Stable    0.5
            CONTINUE
        END
        ${permission_visible}=    Run Keyword And Return Status
        ...    Wait Visible
        ...    ${Startup.RUNTIME_PERMISSION_ALLOW}
        ...    1.5s
        IF    ${permission_visible}
            Tap    ${Startup.RUNTIME_PERMISSION_ALLOW}
            Wait Page Stable    0.5
            CONTINUE
        END
        BREAK
    END
