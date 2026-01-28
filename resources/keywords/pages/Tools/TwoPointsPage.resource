*** Settings ***
Resource    ../../../locators/android/TwoPoints.resource
Resource    ../../common/actions.resource

*** Keywords ***
Input Point Name
# 输入点名
    [Arguments]    ${POINT_NAME_INPUT_BOX}    ${point_name}
    Click Element    ${POINT_NAME_INPUT_BOX}
    Input Text    ${POINT_NAME_INPUT_BOX}    ${point_name}

Input N
# 输入N坐标
    [Arguments]     ${N_INPUT_BOX}    ${n}
    Click Element    ${N_INPUT_BOX}
    Input Text   ${N_INPUT_BOX}    ${n}
Input E
# 输入E坐标
    [Arguments]     ${E_INPUT_BOX}    ${e}
    Click Element    ${E_INPUT_BOX}
    Input Text   ${E_INPUT_BOX}    ${e}
Input Z
# 输入Z坐标
    [Arguments]     ${Z_INPUT_BOX}    ${z}
    Click Element    ${Z_INPUT_BOX}
    Input Text   ${Z_INPUT_BOX}    ${z}

Input Point Information
# 输入点信息（点名，N，E，Z）
    [Arguments]    ${POINT_NAME_INPUT_BOX}    ${N_INPUT_BOX}    ${E_INPUT_BOX}    ${Z_INPUT_BOX}    
    ...    ${point_name}    ${n}    ${e}    ${z}
    Input Point Name    ${POINT_NAME_INPUT_BOX}    ${point_name}
    Input N    ${N_INPUT_BOX}    ${n}
    Input E    ${E_INPUT_BOX}    ${e}
    Input Z    ${Z_INPUT_BOX}    ${z}

Input Start Point
# 输入起始点信息
    [Arguments]    ${name}    ${S_n}    ${S_e}    ${S_z}
    Input Point Information    
    ...    ${TwoPoints.START_POINT_NAME_INPUT_BOX}    
    ...    ${TwoPoints.START_N_INPUT_BOX}    
    ...    ${TwoPoints.START_E_INPUT_BOX}    
    ...    ${TwoPoints.START_Z_INPUT_BOX}    
    ...    ${name}    ${S_n}    ${S_e}    ${S_z}

Input End Point
# 输入终点信息
    [Arguments]    ${E_name}    ${E_n}    ${E_e}    ${E_z}
    Input Point Information    
    ...    ${TwoPoints.END_POINT_NAME_INPUT_BOX}    
    ...    ${TwoPoints.END_N_INPUT_BOX}    
    ...    ${TwoPoints.END_E_INPUT_BOX}    
    ...    ${TwoPoints.END_Z_INPUT_BOX}    
    ...    ${E_name}    ${E_n}    ${E_e}    ${E_z}

Tap Calculate Button
# 点击计算按钮
    Tap    ${TwoPoints.CALCULATE_BUTTON}


