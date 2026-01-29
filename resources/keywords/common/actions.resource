*** Settings ***
Library    AppiumLibrary
Resource   wait.resource
Resource   assert.resource

*** Variables ***
${DEFAULT_TIMEOUT}    20s
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

*** Keywords ***
Android Scroll Into View By Text Contains
    [Documentation]    滚动查找文本（全能版）。
    ...    
    ...    [参数 container_locator 支持三种情况]:
    ...    1. 不传 (默认): 也就是 ${EMPTY}，会在全屏寻找第一个可滚动的区域。
    ...    2. RF 标准写法: id=com.xxx:id/list，会自动转换为 resourceId。
    ...    3. 原生 Java 写法: new UiSelector().resourceId("...")，直接透传。
    [Arguments]    ${text}    ${container_locator}=${EMPTY}
    
    # 1. 情况 A: 用户没有传定位器 -> 默认全屏寻找可滚动的元素
    IF    '${container_locator}' == '${EMPTY}'
        ${selector_java}=    Set Variable    new UiSelector().scrollable(true)
    
    # 2. 情况 B: 用户传入了原生 Java 选择器 -> 直接使用
    # 使用 Python 表达式 $var.strip().startswith(...) 更加稳健
    ELSE IF    $container_locator.strip().startswith('new UiSelector')
        ${selector_java}=    Set Variable    ${container_locator}
        
    # 3. 情况 C: 用户传入了 RF 标准 id=xxx -> 翻译成 Java 的 resourceId("xxx")
    ELSE IF    $container_locator.startswith('id=')
        ${clean_id}=    Set Variable    ${container_locator}[3:]
        ${selector_java}=    Set Variable    new UiSelector().resourceId("${clean_id}")
        
    # 4. 情况 D: 格式不支持 (比如传入了 xpath 或纯字符串) -> 报错提示
    ELSE
        Fail    错误: 滚动定位器格式不正确。仅支持 'id=...' 或 'new UiSelector()...'，或者留空。你传入的是: ${container_locator}
    END
    
    # 5. 组装最终命令
    # .instance(0) 确保在有多个匹配时默认取第一个，防止报错
    ${loc}=    Set Variable    android=new UiScrollable(${selector_java}.instance(0)).setMaxSearchSwipes(10).scrollIntoView(new UiSelector().textContains("${text}"))
    
    RETURN    ${loc}

Scroll To And Tap Text Contains
    [Arguments]    ${text}    ${container_locator}=${EMPTY}
    ${loc}=    Android Scroll Into View By Text Contains    ${text}    ${container_locator}
    Wait Until Element Is Visible    ${loc}    timeout=5s
    Click Element    ${loc}