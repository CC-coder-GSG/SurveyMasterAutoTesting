*** Settings ***
Library    ../../../scripts/PythonLibrarys/CalculateTwoPointsResult.py

*** Keywords ***
Calculate Two Points Expected Result
    [Documentation]    根据起终点坐标计算两点理论值
    [Arguments]    ${start}    ${end}
    ${expected}=  calculate_two_points    ${start}    ${end}    # 调用Python类中的方法
    Log    [EXPECTED] ${expected}
    RETURN    ${expected}