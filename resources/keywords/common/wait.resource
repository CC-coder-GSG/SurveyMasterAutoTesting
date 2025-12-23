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
