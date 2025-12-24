*** Settings ***
Resource    ../../locators/android/Project.resource
Resource    ../common/actions.resource
Resource    ../../locators/android/Popups.resource


*** Keywords ***
# 点击更多按钮
Tap More Button
    Tap    ${Project.MORE_BUTTON}
# 点击新建按钮
Tap New Project
    Tap    ${Project.NEW_PROJECT_BUTTON}
# 输入名称
Enter Project Name
    [Arguments]    ${project_name}
    Input    ${Project.PROJECT_NAME_INPUT_BOX}    ${project_name}
#输入创建者
Enter Project Creator
    [Arguments]    ${creator}
    Input    ${Project.PROJECT_CREATOR_INPUT_BOX}    ${creator}}
# 输入备注
Enter Project Remark
    [Arguments]    ${remark}
    Input    ${Project.PROJECT_REMARK_INPUT_BOX}    ${remark}
# 点击创建项目确认按钮
Tap Project Create Confirm Button
    Tap    ${Project.PROJECT_CREATE_CONFIRM_BUTTON}
# 等待项目列表页面加载完毕
Wait Project List
    Wait Visible    ${Project.PROJECT_LIST}
# 点击项目删除按钮
Tap Delete Project Button
    Tap    ${Project.DELETE}
# 删除项目时确认弹窗点击确认按钮
Tap Confirm Popup Confirm Button
    Tap    ${Popups.CONFRIM_POPUP_CONFRIM}