*** Settings ***
Resource    ../../locators/android/GuideActivity.resource
Resource    ../common/actions.resource


*** Keywords ***
ProjectManagement Button Click
# 点击项目管理按钮
    Tap    ${GuideActivity.PROJECT_MANAGEMENT_BUTTON}

ProjectManagement_Buttom Button Click
# 底部项目按钮点击
    Tap    ${GuideActivity.PROJECT_PAGE_BUTTON}

Equipment_Bottom Button Click
# 底部设备按钮点击
    Tap    ${GuideActivity.EQUIPMENT_PAGE_BUTTON}

Fix Status Get
# 获取当前固定状态
    Get Text    ${GuideActivity.Fix_Status}

EquipmentInformation Button Click
# 点击设备信息按钮
    Tap    ${GuideActivity.Equipment_BUTTON}
