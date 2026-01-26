*** Keywords ***
Assert Calculation Result Should Be Correct
    [Documentation]    根据指定的数据类型断言计算结果是否正确
    [Arguments]    ${actual}    ${expected}    ${type}    ${tolerance}=0.01
    Run Keyword If    '${type}' == 'float'      Assert Float With Tolerance    ${actual}    ${expected}    ${tolerance}
    ...    ELSE IF    '${type}' == 'percent'    Assert Percent With Tolerance  ${actual}    ${expected}    ${tolerance}
    ...    ELSE IF    '${type}' == 'ratio'      Assert Ratio Equal              ${actual}    ${expected}
    ...    ELSE IF    '${type}' == 'angle'      Assert Angle With Tolerance    ${actual}    ${expected}    ${tolerance}

# 浮点数断言
Assert Float With Tolerance
    [Arguments]    ${actual}    ${expected}    ${tolerance}=0.0
    Should Be True    ${abs(${actual}-${expected})} <= ${tolerance}    Expected ${expected}, but got ${actual} (within tolerance ${tolerance})

# 百分比断言，自动支持带%和小数格式
Assert Percent With Tolerance
    [Arguments]    ${actual}    ${expected}    ${tolerance}=0.01
    ${actual}=    Evaluate    float(str(${actual}).strip('%'))/100 if '%' in str(${actual}) else float(${actual})
    ${expected}=  Evaluate    float(str(${expected}).strip('%'))/100 if '%' in str(${expected}) else float(${expected})
    Should Be True    ${abs(${actual}-${expected})} <= ${tolerance}    Expected ${expected}, but got ${actual} (within tolerance ${tolerance})

# 比率断言，直接转换为浮点数比较
Assert Ratio Equal
    [Arguments]    ${actual}    ${expected}
    ${actual}=    Evaluate    float(${actual}.replace(':','/').replace('\\','/'))
    ${expected}=  Evaluate    float(${expected}.replace(':','/').replace('\\','/'))
    Should Be True    ${actual} == ${expected}    Expected ${expected}, but got ${actual}

# 角度断言，考虑360°周期
Assert Angle With Tolerance
    [Arguments]    ${actual}    ${expected}    ${tolerance}=1.0
    ${diff}=    Evaluate    min(abs(${actual}-${expected}), 360-abs(${actual}-${expected}))
    Should Be True    ${diff} <= ${tolerance}    Expected ${expected}°, but got ${actual}° (within tolerance ${tolerance}°)
