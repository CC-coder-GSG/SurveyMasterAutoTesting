*** Settings ***
Library    AppiumLibrary

*** Variables ***
${DEFAULT_TIMEOUT}    10s
${POLL_INTERVAL}      300ms

*** Keywords ***
Wait Visible
    [Arguments]    ${locator}    ${timeout}=${DEFAULT_TIMEOUT}
    Wait Until Element Is Visible    ${locator}    ${timeout}

Wait Gone
    [Arguments]    ${locator}    ${timeout}=${DEFAULT_TIMEOUT}
    Wait Until Page Does Not Contain Element    ${locator}    ${timeout}

Wait Page Stable
    [Arguments]    ${seconds}=0.3
    Sleep    ${seconds}

# 等待所属控件的文本与期待值对应一致
Wait Until Element Text Equals
    [Arguments]    ${locator}    ${expected}    ${timeout}=10s    ${interval}=500ms
    Wait Until Keyword Succeeds    ${timeout}    ${interval}
    ...    Element Text Should Be    ${locator}    ${expected}

Element Text Should Be
    [Arguments]    ${locator}    ${expected}
    ${text}=    Get Text    ${locator}
    Should Be Equal As Strings    ${text}    ${expected}

# 等待所属控件的文本与期待值对应一致（正则表达式）
Wait Until Element Text Matches Regexp
    [Arguments]    ${locator}    ${pattern}    ${timeout}=10s    ${interval}=500ms
    Wait Until Keyword Succeeds    ${timeout}    ${interval}
    ...    Element Text Should Match Regexp    ${locator}    ${pattern}

Element Text Should Match Regexp
    [Arguments]    ${locator}    ${pattern}
    ${text}=    Get Text    ${locator}
    Should Match Regexp    ${text}    ${pattern}
