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
        ${style_visible}=    Run Keyword And Return Status
        ...    Wait Visible
        ...    ${Startup.STYLE_SAVE_BUTTON}
        ...    20s
        IF    ${style_visible}
            Log    [STARTUP] 保存默认界面风格
            Tap    ${Startup.STYLE_SAVE_BUTTON}
        END
    END
