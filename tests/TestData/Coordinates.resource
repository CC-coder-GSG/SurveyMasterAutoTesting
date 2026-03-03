*** Settings ***
Library    Collections
Library    ../../scripts/PythonLibrarys/RandomCoordinates.py
Variables  ../../tests/regression/TwoPoints/TwoPoints.yaml

*** Keywords ***
Get Two Points Test Data
    Log    ${fixed_points}
    [Documentation]    优先读取 YAML 中的固定点数据若数据缺失或结构非法，则自动回退至随机生成

    ${use_file}=    Set Variable    ${True}

    TRY
        # ==============================
        # 一、固定数据读取与结构验证
        # ==============================

        ${start}=    Get From Dictionary    ${fixed_points}    start
        ${end}=      Get From Dictionary    ${fixed_points}    end

        # 结构完整性校验（字段必须存在）
        Get From Dictionary    ${start}    n
        Get From Dictionary    ${start}    e
        Get From Dictionary    ${start}    z

        Get From Dictionary    ${end}      n
        Get From Dictionary    ${end}      e
        Get From Dictionary    ${end}      z

        # 构建统一返回结构
        ${points}=    Create Dictionary
        ...    start=${start}
        ...    end=${end}

        Log    使用 YAML 固定数据    INFO

    EXCEPT
        # ==============================
        # 二、异常回退机制
        # ==============================

        Log    固定数据不可用，启用随机生成数据进行计算    WARN
        ${use_file}=    Set Variable    ${False}
    END

    # ==============================
    # 三、随机数据生成（回退路径）
    # ==============================

    IF    not ${use_file}
        ${points}=    Generate Two Points
    END

    # ==============================
    # 四、统一出口
    # ==============================

    RETURN    ${points}