*** Settings ***
Resource    ../pages/CloudService.resource



*** Keywords ***
登录云服务流程
    [Arguments]    ${username}    ${password}

    打开项目页面
    进入云服务
    选择用户名
    清除用户名
    输入用户名    ${username}
    输入密码      ${password}

    点击登录

