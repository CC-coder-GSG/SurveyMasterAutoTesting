*** Settings ***
Library    AppiumLibrary

*** Keywords ***
Fail With Screenshot
    [Arguments]    ${message}
    Capture Page Screenshot
    Fail    ${message}

Should Be Visible
    [Arguments]    ${locator}
    Page Should Contain Element    ${locator}

Teardown On Failure
    Run Keyword If Test Failed    Capture Page Screenshot
