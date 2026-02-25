*** Settings ***
Library    Collections
Library    String


*** Variables ***
${PASS_SYMBOL}    ✅
${FAIL_SYMBOL}    ❌


*** Keywords ***

# 主入口：校验所有字段
#
# ${actual}           页面读取结果字典
# ${expected}         Python理论结果字典
# ${tolerance_table}  整张容差配置表（来自yaml）
#
# tolerance_table 结构：
# {
#   horizontal: {type: float, tol: 0.01},
#   azimuth:    {type: angle, tol: 1.0}
# }
Verify Two Points Result
    [Documentation]   遍历所有字段进行断言比较实际读取结果和理论计算结果
    ...                任一失败最终 FAIL，但会跑完全部字段
    [Arguments]    ${actual}    ${expected}    ${tolerance_table}   ${testdata}

    ${failures}=    Create List

    ${start}=    Get From Dictionary    ${testdata}    start
    ${end}=      Get From Dictionary    ${testdata}    end

    Log    =========================================================    level=WARN

    Log    ================= Input Coordinate Data =================    level=WARN

    Log    起点 ${start["name"]} | N=${start["n"]} E=${start["e"]} Z=${start["z"]}    level=WARN
    Log    终点 ${end["name"]} | N=${end["n"]} E=${end["e"]} Z=${end["z"]}    level=WARN

    Log    =============== Two Points Detail Result ===============    level=WARN
    FOR    ${key}    IN    @{expected.keys()}

        # 安全保护：防止 tolerance 缺字段直接崩
        Dictionary Should Contain Key    ${tolerance_table}    ${key}

        ${field_cfg}=    Get From Dictionary    ${tolerance_table}    ${key}
        ${a}=    Get From Dictionary    ${actual}      ${key}
        ${e}=    Get From Dictionary    ${expected}    ${key}

        Verify Single Field
        ...    ${key}
        ...    ${a}
        ...    ${e}
        ...    ${field_cfg}
        ...    ${failures}

    END
    
    ${count}=    Get Length    ${failures}

    Log    ================= Two Points Verify Result =================    level=WARN

    IF    ${count} > 0
        Log    ${FAIL_SYMBOL} FAIL (${count} items)    level=WARN
        Fail    ${failures}
    ELSE
        Log    ${PASS_SYMBOL} PASS ALL    level=WARN
    END
    Log    =========================================================    level=WARN

# 命名说明：
#   tolerance_table → 整张表
#   field_cfg       → 当前字段配置
#   limit           → 真正参与计算的容差值
Verify Single Field
    [Documentation]    单字段校验 + 日志展示（无论PASS/FAIL都打印详细信息）
    [Arguments]    ${field}    ${actual}    ${expected}    ${field_cfg}    ${failures}

    ${type}=     Get From Dictionary    ${field_cfg}    type
    ${limit}=    Get From Dictionary    ${field_cfg}    tol

    # ========= 先统一转成数值 =========
    ${a_norm}=    Normalize By Type    ${type}    ${actual}
    ${e_norm}=    Normalize By Type    ${type}    ${expected}

    ${diff}=    Evaluate    abs(${a_norm}-${e_norm})

    ${status}=    Run Keyword And Return Status
    ...    Verify By Type    ${type}    ${actual}    ${expected}    ${limit}

    # ========= 日志（始终打印） =========
    IF    ${status}
        Log
        ...    ${PASS_SYMBOL} ${field} | raw=${actual} | actual=${a_norm} | expected=${e_norm} | diff=${diff} | tol=${limit}
        ...    level=WARN
    ELSE
        Log
        ...    ${FAIL_SYMBOL} ${field} | raw=${actual} | actual=${a_norm} | expected=${e_norm} | diff=${diff} | tol=${limit}
        ...    level=WARN

        Append To List
        ...    ${failures}
        ...    ${FAIL_SYMBOL} ${field} | actual=${actual} expected=${expected} tol=${limit}
    END

Verify By Type
    [Documentation]    根据类型选择验证方法    浮点数、百分比、比例、角度
    [Arguments]    ${type}    ${actual}    ${expected}    ${limit}

    Run Keyword If    '${type}'=='float'
    ...    Verify Float With Tolerance    ${actual}    ${expected}    ${limit}
    ...    ELSE IF    '${type}'=='percent'
    ...    Verify Percent With Tolerance    ${actual}    ${expected}    ${limit}
    ...    ELSE IF    '${type}'=='ratio'
    ...    Verify Ratio With Tolerance    ${actual}    ${expected}    ${limit}
    ...    ELSE IF    '${type}'=='angle'
    ...    Verify Angle With Tolerance    ${actual}    ${expected}    ${limit}
    ...    ELSE
    ...    Fail    不支持类型: ${type}


Verify Float With Tolerance
    [Documentation]    验证浮点数，将UI字符串统一清洗后去掉单位后比较，允许误差范围
    [Arguments]    ${actual}    ${expected}    ${limit}
    ${a}=    Normalize Float    ${actual}
    ${e}=    Normalize Float    ${expected}
    ${diff}=    Evaluate    abs(${a}-${e})
    IF    ${diff} > ${limit}
        Fail    diff=${diff} > tol=${limit}
    END

Verify Percent With Tolerance
    [Documentation]    验证百分比，将UI字符串统一清洗去掉%后转为数字比较，允许误差范围
    [Arguments]    ${actual}    ${expected}    ${limit}
    ${a}=    Normalize Percent    ${actual}
    ${e}=    Normalize Percent    ${expected}
    ${diff}=    Evaluate    abs(${a}-${e})
    IF    ${diff} > ${limit}
        Fail    diff=${diff} > tol=${limit}
    END

Verify Ratio With Tolerance
    [Documentation]    验证比例，将UI字符串统一清洗后去掉:后转为数字比较，允许误差范围
    [Arguments]    ${actual}    ${expected}    ${limit}
    ${a}=    Normalize Ratio    ${actual}
    ${e}=    Normalize Ratio    ${expected}
    ${diff}=    Evaluate    abs(${a}-${e})
    IF    ${diff} > ${limit}
        Fail    diff=${diff} > tol=${limit}
    END

Verify Angle With Tolerance
    [Documentation]    验证角度，将UI字符串统一清洗后转为十进制度数字比较，允许误差范围（考虑360度循环）
    [Arguments]    ${actual}    ${expected}    ${limit}
    ${a}=    Normalize Angle    ${actual}
    ${e}=    Normalize Angle    ${expected}
    ${diff}=    Evaluate    min(abs(${a}-${e}), 360-abs(${a}-${e}))
    IF    ${diff} > ${limit}
        Fail    diff=${diff} > tol=${limit}
    END


# ===== Normalize 工具函数（统一清洗UI字符串）=====

# 去掉单位 米 / m
Normalize Float
    [Arguments]    ${value}

    ${v}=    Strip String    ${value}
    # 去除常见的单位和括号
    ${v}=    Replace String    ${v}    米    ${EMPTY}
    ${v}=    Replace String    ${v}    m    ${EMPTY}
    ${v}=    Replace String    ${v}    （    ${EMPTY}
    ${v}=    Replace String    ${v}    ）    ${EMPTY}
    ${v}=    Replace String    ${v}    (    ${EMPTY}
    ${v}=    Replace String    ${v}    )    ${EMPTY}
    
    # 使用正则表达式提取数字部分（包括小数点）
    ${num}=    Evaluate    float("${v}")
    RETURN    ${num}

# 12% → 0.12
Normalize Percent
    [Arguments]    ${value}

    ${v}=    Strip String    ${value}
    ${v}=    Replace String    ${v}    %    ${EMPTY}

    ${num}=    Evaluate    float("${v}")/100
    RETURN    ${num}

# 1:200 → 0.005
Normalize Ratio
    [Arguments]    ${value}
    ${v}=    Strip String    ${value}
    ${v}=    Replace String    ${v}    :    /
    ${result}=    Evaluate    ${v}
    RETURN    ${result}

# 支持两种：
# 10.35
# 178°20'01.951"
Normalize Angle
    [Arguments]    ${value}

    ${v}=    Strip String    ${value}
    ${v}=    Replace String    ${v}    (    ${EMPTY}
    ${v}=    Replace String    ${v}    )    ${EMPTY}
    Log    Processing angle value: ${v}

    # 检查是否包含度符号
    ${is_dms}=    Run Keyword And Return Status    Should Contain    ${v}    °

    IF    ${is_dms}
        # 处理 DMS 格式: 178°20'01.951"
        ${v}=    Replace String    ${v}    °    :
        ${v}=    Replace String    ${v}    '    :
        ${v}=    Replace String    ${v}    "    ${EMPTY}
        Log    After DMS processing: ${v}
        
        # 使用更安全的列表访问方式
        @{parts}=    Split String    ${v}    :
        ${len}=    Get Length    ${parts}
        Log    Parts length: ${len}
        
        # 确保有足够的部分
        Run Keyword If    ${len} < 3
        ...    Fail    Invalid DMS format: ${v}
        
        # 安全地获取各个部分
        ${degrees_part}=    Get From List    ${parts}    0
        ${minutes_part}=    Get From List    ${parts}    1
        ${seconds_part}=    Get From List    ${parts}    2
        
        Log    D:${degrees_part} M:${minutes_part} S:${seconds_part}
        ${decimal_degrees}=    Evaluate    round(float($degrees_part) + float($minutes_part)/60 + float($seconds_part)/3600, 6)
        Log    Converted to decimal: ${decimal_degrees}
        RETURN    ${decimal_degrees}
    ELSE
        # 直接返回十进制数值
        ${decimal_value}=    Evaluate    round(float("${v}"), 6)
        Log    Decimal value: ${decimal_value}
        RETURN    ${decimal_value}
    END

Normalize By Type
    [Documentation]    根据 type 统一转数值（只用于日志和diff显示）
    [Arguments]    ${type}    ${value}

    IF    '${type}'=='float'
        ${r}=    Normalize Float    ${value}
    ELSE IF    '${type}'=='percent'
        ${r}=    Normalize Percent    ${value}
    ELSE IF    '${type}'=='ratio'
        ${r}=    Normalize Ratio    ${value}
    ELSE IF    '${type}'=='angle'
        ${r}=    Normalize Angle    ${value}
    ELSE
        ${r}=    Set Variable    ${value}
    END

    RETURN    ${r}