*** Settings ***
Library    AppiumLibrary
Resource    ../../locators/android/CloudService.resource
Resource    ../common/actions.resource

*** Keywords ***
Open Project Page    # 打开项目页面
    Wait Visible    ${BTN_PROJECT}  
    Tap    ${BTN_PROJECT}

Enter Cloud Service Page    # 进入云服务
    Wait Visible    ${BTN_CLOUD_SERVICE}
    Tap    ${BTN_CLOUD_SERVICE}

Select Username    # 选择用户名
    Wait Visible    ${BTN_USER_SELECT}
    Tap    ${BTN_USER_SELECT}

Clear User Name     # 清空用户名
    Click Clear Button For Input    com.sinognss.sm.free:id/txt_username

Input Username    # 输入用户名
    [Arguments]    ${username}
    Wait Until Element Is Visible    ${INPUT_USERNAME}
    Input Text                       ${INPUT_USERNAME}    ${username}

Input Password    # 输入密码
    [Arguments]    ${password}
    Wait Until Element Is Visible    ${INPUT_PASSWORD}
    Input Text    ${INPUT_PASSWORD}    ${password} 

Select Password    # 选择密码
    Wait Visible    ${BTN_PASSWORD_SELECT}
    Tap    ${BTN_PASSWORD_SELECT}

Click Login    # 点击登录
    Wait Visible    ${BTN_LOGIN}
    Tap    ${BTN_LOGIN}

Verify Login Success
    [Documentation]    登录成功断言：出现“退出登录”文本
    Wait Until Page Contains    退出登录    10s