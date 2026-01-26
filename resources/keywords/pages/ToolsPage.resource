*** Settings ***
Resource    ../../locators/android/Tools.resource
Resource    ../common/actions.resource


*** Keywords ***
Tap Tools Button
# 点击工具按钮
    [Documentation]    点击页面底部的“工具”按钮，进入工具页面
    Tap    ${Tools.TOOLS_PAGES_BUTTON}


Tap Two Points Tool Button
# 点击两点计算工具按钮
    [Documentation]    点击工具页面中的“两点计算”工具按钮，进入两点计算页面
    Tap    ${Tools.TWO_POINTS_TOOL_BUTTON}