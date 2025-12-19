*** Settings ***
Resource    ../../locators/android/Project.resource
Resource    ../common/actions.resource


*** Keywords ***
Tap More Button
# 点击更多按钮
    Tap    ${Project.MORE_BUTTON}