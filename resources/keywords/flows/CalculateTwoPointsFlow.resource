*** Settings ***
Resource    ../../../tests/TestData/Coordinates.resource
Resource    ../pages/GuideActivity.resource
Resource    ../pages/Tools/TwoPointsPage.resource
Resource    ../../../tests/regression/TwoPoints/Calc_twopoints.resource
Resource    ../../../tests/regression/TwoPoints/TwoPointsAssert.resource

*** Keywords ***
Prepare TwoPoints Case Flow
    [Documentation]    获取两点测试数据（文件优先，失败则随机）
    ${points}=    Get Two Points Test Data
    RETURN    ${points}


Calculate Two Points Flow
    [Documentation]    APP操作计算两点
    [Arguments]    ${case}

    Tap Tools Button
    Tap Two Points Tool Button

    ${start}=    Set Variable    ${case['start']}
    ${end}=      Set Variable    ${case['end']}

    Input Start Point
    ...    ${start['name']}    ${start['n']}    ${start['e']}    ${start['z']}

    Input End Point
    ...    ${end['name']}      ${end['n']}      ${end['e']}      ${end['z']}

    Tap Calculate Button


TwoPoints Get Actual Result Flow
    [Documentation]    从页面读取计算结果
    ${actual}=    Get TwoPoints Result
    RETURN    ${actual}


TwoPoints Calc Expected Result Flow
    [Documentation]    Python 计算理论结果
    [Arguments]    ${case}
    ${expected}=    Calculate Two Points Expected Result    ${case['start']}    ${case['end']}
    RETURN    ${expected}


TwoPoints Verify Result Flow
    [Documentation]    断言比较实际读取结果和期待理论结果
    [Arguments]    ${actual}    ${expected}    ${tolerance}    ${testdata}
    Verify Two Points Result    ${actual}    ${expected}   ${tolerance}    ${testdata}