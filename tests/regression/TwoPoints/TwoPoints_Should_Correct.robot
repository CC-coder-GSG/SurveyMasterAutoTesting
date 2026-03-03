*** Settings ***
Resource    ../../../resources/keywords/flows/CalculateTwoPointsFlow.resource
Resource    ../../../resources/keywords/common/flow_helper.resource
Resource    ../../../resources/keywords/common/teardown.resource

*** Test Cases ***
TwoPoints Should Correct
    [Documentation]    测试工具-两点计算功能是否正确
    ${case}=        Prepare TwoPoints Case Flow

    Calculate Two Points Flow    ${case}

    ${actual}=      TwoPoints Get Actual Result Flow
    ${expected}=    TwoPoints Calc Expected Result Flow    ${case}
    ${testdata}=    Set Variable    ${case}
    
    TwoPoints Verify Result Flow
    ...    ${actual}
    ...    ${expected}
    ...    ${tolerance}
    ...    ${testdata}