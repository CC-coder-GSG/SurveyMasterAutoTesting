*** Settings ***
Resource    ../pages/Project/CloudService.resource



*** Keywords ***
#登录云服务流程
Login Cloud Service
    [Arguments]    ${username}    ${password}

    Open Project Page
    Enter Cloud Service Page
    Select Username
    Clear User Name
    Input Username    ${username}
    Input Password      ${password}
    Select Password
    Click Login

