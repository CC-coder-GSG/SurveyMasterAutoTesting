*** Settings ***
Library    AppiumLibrary
Resource   wait.resource
Resource   assert.resource

*** Variables ***
${DEFAULT_TIMEOUT}    10s
${CLICK_RETRIES}      2
${RETRY_INTERVAL}     300ms

*** Keywords ***
Tap
    [Arguments]    ${locator}    ${timeout}=${DEFAULT_TIMEOUT}
    # 1. 确保元素真正可见
    Wait Visible    ${locator}    ${timeout}
    # 2. 直接点击（相信 Appium 的判断）
    Click Element    ${locator}

Input
# 输入，防止输入框没出来就输入 → 失败、输入框里有旧内容 → 影响用例稳定、有些输入框必须先点击获取焦点才能输入
    [Arguments]    ${locator}    ${text}    ${timeout}=${DEFAULT_TIMEOUT}
    Wait Visible    ${locator}    ${timeout}
    # 清空不一定每个版本都有同名 keyword，所以用 Ignore Error 兼容
    Run Keyword And Ignore Error    Clear Text    ${locator}
    Click Element    ${locator}
    Input Text       ${locator}    ${text}

Tap By Text Contains
# 按“文字包含”点击（uiautomator 快速定位），适用情况：没有 id 的控件、临时验证、快速写用例、弹窗按钮/菜单项很适合（“确定/取消/同意/下一步”）
    [Arguments]    ${text}
    ${loc}=    Set Variable    android=new UiSelector().textContains("${text}")
    Tap    ${loc}

Android Scroll Into View By Text Contains
# 滚动直到某个文字出现，并返回定位器，解决问题：元素在列表/滚动页下方，看不到也点不到、用 UiScrollable 自动滚动定位，比手写 swipe 可靠
    [Arguments]    ${text}
    ${loc}=    Set Variable    android=new UiScrollable(new UiSelector().scrollable(true)).scrollIntoView(new UiSelector().textContains("${text}"))
    RETURN    ${loc}

Scroll To And Tap Text Contains
# 滚动到文字出现后点击（组合动作）
    [Arguments]    ${text}
    ${loc}=    Android Scroll Into View By Text Contains    ${text}
    Tap    ${loc}

Click Clear Button For Input
# 使用xpath定位并点击输入框的清除按钮 /清除按钮无Id
    [Arguments]    ${input_id}
    ${xpath}=    Set Variable    //*[@resource-id="${input_id}"]/preceding-sibling::android.widget.ImageView
    Wait Until Element Is Visible    xpath=${xpath}    5s
    Click Element    xpath=${xpath}
