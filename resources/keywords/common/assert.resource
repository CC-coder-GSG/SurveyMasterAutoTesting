*** Settings ***
Library    AppiumLibrary
Library    Collections
...    # 用于字典操作
Resource    convert.resource

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


Assert Calculation Results Should Be Correct
# 断言多个计算结果是否正确  
    [Arguments]    ${actual_results}    ${expected_results}
    #定义关键字的参数，接收实际结果字典和预期结果字典
    FOR    ${key}    IN    @{expected_results.keys()}
    #遍历循环预期结果字典中的每一个键值对
        ${expected}=    Get From Dictionary    ${expected_results}    ${key}
        #从预期结果字典中获取当前键对应的值（包含value、type、tolerance等信息）
        ${actual}=      Get From Dictionary    ${actual_results}      ${key}
        #从实际结果字典中获取相同键的实际计算结果

        ${value}=       Get From Dictionary    ${expected}    value
        #从预期结果详情中提取具体的期望数值
        ${type}=        Get From Dictionary    ${expected}    type
        #从预期结果详情中提取计算结果类型
        ${tolerance}=   Get From Dictionary    ${expected}    tolerance    default=0.0001
        #从预期结果详情中提取计算结果误差范围，若无则使用默认值0.0001

        Assert Calculation Result Should Be Correct
        #断言计算结果是否正确
        ...    ${actual}
        ...    ${value}
        ...    ${type}
        ...    ${tolerance}
    END

