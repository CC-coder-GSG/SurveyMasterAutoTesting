*** Settings ***
Resource   ../resources/locators/android/Datum.resource
Resource    ../resources/keywords/common/actions.resource

*** Keywords ***
# 点击常用坐标系按钮
Tap Common Coordinate Button
    Tap    ${Datum}[COMMON_COORDINATE_BUTTON]
# 点击目标椭球按钮
Tap Target Ellipsoid Button
    Tap    ${Datum}[TARGET_ELLIPSOID_BUTTON]
# 点击投影按钮
Tap Projection Button
    Tap    ${Datum}[PROJECTION_BUTTON]
# 点击七参数按钮
Tap Seven Parameters Button
    Tap    ${Datum}[SEVEN_PARAMETERS_BUTTON]
# 点击平面校正按钮
Tap HRMS Button
    Tap    ${Datum}[HRMS_BUTTON]
# 点击高程拟合按钮
Tap VRMS Button
    Tap    ${Datum}[VRMS_BUTTON]
# 点击大地水准面按钮
Tap Geoid Model Button
    Tap    ${Datum}[GEOID_MODEL_BUTTON]
# 点击平面格网模型按钮
Tap Grid Correction Button
    Tap    ${Datum}[GRID_CORRECTION_BUTTON]
# 点击平移参数按钮
Tap Translation Parameters Button
    Tap    ${Datum}[TRANSLATION_PARAMETERS_BUTTON]
# 点击确认按钮
Tap Confirm Button
    Tap    ${Datum}[CONFIRM_BUTTON]

# 点击打开七参数开关
Tap Use Seven Parameters Button
    Tap   ${Datum}[USE_SEVEN_PARAMETERS_BUTTON]   
# 输入DX
Enter Seven Parameters DX
    [Arguments]    ${DX}
    Input    ${Datum}[Seven Parameters_DX_INPUT_BOX]    ${DX}
# 输入DY
Enter Seven Parameters DY
    [Arguments]    ${DY}
    Input    ${Datum}[Seven Parameters_DY_INPUT_BOX]    ${DY}    
# 输入DZ
Enter Seven Parameters DZ
    [Arguments]    ${DZ}
    Input    ${Datum}[Seven Parameters_DZ_INPUT_BOX]    ${DZ}
# 输入RX
Enter Seven Parameters RX
    [Arguments]    ${RX}
    Input    ${Datum}[Seven Parameters_RX_INPUT_BOX]    ${RX} 
# 输入RY
Enter Seven Parameters RY
    [Arguments]    ${RY}
    Input    ${Datum}[Seven Parameters_RY_INPUT_BOX]    ${RY} 
# 输入RZ
Enter Seven Parameters RZ
    [Arguments]    ${RZ}
    Input    ${Datum}[Seven Parameters_RZ_INPUT_BOX]    ${RZ} 
# 输入K
Enter Seven Parameters K
    [Arguments]    ${K}
    Input    ${Datum}[Seven Parameters_K_INPUT_BOX]    ${K}                      
# 点击确认修改按钮
Tap Seven Parameters Confirm Button
    Tap    ${Datum}[SEVEN_PARAMETERS_CONFIRM_BUTTON]
    