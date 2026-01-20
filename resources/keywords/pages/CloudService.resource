*** Settings ***
Library    AppiumLibrary
Resource    ../../locators/android/CloudService.resource
Resource    ../common/actions.resource
Resource    ../common/wait.resource

*** Keywords ***
打开项目页面
    Wait Visible    ${BTN_PROJECT}  
    Tap    ${BTN_PROJECT}

进入云服务
    Wait Visible    ${BTN_CLOUD_SERVICE}    10s
    Click Element                     ${BTN_CLOUD_SERVICE}

选择用户名
    Wait Visible    ${BTN_USER_SELECT}    10s
    Click Element                     ${BTN_USER_SELECT}

清除用户名
    Click Clear Button For Input    com.sinognss.sm.free:id/txt_username

输入用户名
    [Arguments]    ${username}
    Wait Until Element Is Visible    ${INPUT_USERNAME}
    Input Text                       ${INPUT_USERNAME}    ${username}

输入密码
    [Arguments]    ${password}
    Wait Until Element Is Visible    ${INPUT_PASSWORD}
    Input Text    ${INPUT_PASSWORD}    ${password}
    # 隐藏键盘，防止遮挡登录按钮
    # Hide Keyboard 

点击登录
    # 第一优先：ID 直接点击
    ${id_exist}=    Run Keyword And Return Status
    ...    Wait Until Element Is Visible    ${BTN_LOGIN}    5s
    IF    ${id_exist}
        Click Element    ${BTN_LOGIN}
    ELSE
        # 第二优先：滚动查找含“登录”的文本
        ${scroll_result}=    Run Keyword And Return Status
        ...    Scroll To And Tap Text Contains    登录
        IF    not ${scroll_result}
            # 第三优先：Tap 元素（即使被软键盘遮挡也可以）
            Tap    ${BTN_LOGIN}
        END
    END

验证登录成功
    # 等待一段时间让登录完成
    Sleep    3s
    # 使用滚动查找的方式验证登录成功，从可能的多个元素中找一个即可
    ${success_found}=    Set Variable    ${False}
    # 尝试查找常见成功标志
    FOR    ${expected_text}    IN    公告    项目    云服务    用户    我的
        ${result}=    Run Keyword And Return Status    Android Scroll Into View By Text Contains    ${expected_text}
        IF    ${result}
            # 找到元素后，执行Tap操作确认元素可交互
            ${locator}=    Android Scroll Into View By Text Contains    ${expected_text}
            Tap    ${locator}
            Log    找到"${expected_text}"文本，验证登录成功
            ${success_found}=    Set Variable    ${True}
            BREAK
        END
    END
    # 如果以上都没有找到，抛出异常
    IF    ${success_found} == ${False}
        Fail    未能找到登录成功后的任何标志元素
    END