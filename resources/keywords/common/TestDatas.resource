*** Settings ***
Library    ../../Librarys/GenerateRandom3DCoordinates.py

*** Keywords ***
Generate Two Points Test Data
    [Documentation]    生成两点计算测试数据（含理论结果）
    ${case}=    Generate Two Points Case
    [Return]    ${case}
