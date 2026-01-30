*** Settings ***
Resource    ../../locators/android/GuideActivity.resource
Resource    ../common/actions.resource


*** Keywords ***
ProjectManagement Button Click
# 点击项目管理按钮
    Tap    ${GuideActivity.PROJECT_MANAGEMENT_BUTTON}

ProjectManagement_Buttom Button Click
# 底部项目管理按钮点击
    Tap    ${GuideActivity.PROJECT_PAGE_BUTTON}

COORD_Buttom Button Click
# 坐标系统按钮点击
    Tap    ${GuideActivity.COORD_BUTTON}    