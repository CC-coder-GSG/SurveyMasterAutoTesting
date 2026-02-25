*** Settings ***
Resource    ../../../locators/android/TwoPoints.resource
Resource    ../../common/actions.resource

*** Keywords ***
Input Point Name
    [Arguments]    ${NAME_BOX}    ${name}
    Click Element    ${NAME_BOX}
    Input Text       ${NAME_BOX}    ${name}

Input N
    [Arguments]    ${N_BOX}    ${n}
    Click Element    ${N_BOX}
    Input Text       ${N_BOX}    ${n}

Input E
    [Arguments]    ${E_BOX}    ${e}
    Click Element    ${E_BOX}
    Input Text       ${E_BOX}    ${e}

Input Z
    [Arguments]    ${Z_BOX}    ${z}
    Click Element    ${Z_BOX}
    Input Text       ${Z_BOX}    ${z}

Input Point Information
    [Arguments]    ${NAME_BOX}    ${N_BOX}    ${E_BOX}    ${Z_BOX}
    ...    ${name}    ${n}    ${e}    ${z}

    Input Point Name    ${NAME_BOX}    ${name}
    Input N             ${N_BOX}       ${n}
    Input E             ${E_BOX}       ${e}
    Input Z             ${Z_BOX}       ${z}

Input Start Point
    [Arguments]    ${name}    ${n}    ${e}    ${z}
    Input Point Information
    ...    ${TwoPoints.START_POINT_NAME_INPUT_BOX}
    ...    ${TwoPoints.START_N_INPUT_BOX}
    ...    ${TwoPoints.START_E_INPUT_BOX}
    ...    ${TwoPoints.START_Z_INPUT_BOX}
    ...    ${name}    ${n}    ${e}    ${z}

Input End Point
    [Arguments]    ${name}    ${n}    ${e}    ${z}
    Input Point Information
    ...    ${TwoPoints.END_POINT_NAME_INPUT_BOX}
    ...    ${TwoPoints.END_N_INPUT_BOX}
    ...    ${TwoPoints.END_E_INPUT_BOX}
    ...    ${TwoPoints.END_Z_INPUT_BOX}
    ...    ${name}    ${n}    ${e}    ${z}

Tap Calculate Button
    Tap    ${TwoPoints.CALCULATE_BUTTON}

Get TwoPoints Result
    ${az}=    Scroll And Get Text    ${TwoPoints.RESULT_AZIMUTH}
    Log    az=${az}    
    ${hd}=    Scroll And Get Text    ${TwoPoints.RESULT_HORIZONTAL}
    Log    hd=${hd}
    ${sd}=    Scroll And Get Text    ${TwoPoints.RESULT_SLOPE_DIST}
    ${vt}=    Scroll And Get Text    ${TwoPoints.RESULT_VERTICAL}
    ${dh}=    Scroll And Get Text    ${TwoPoints.RESULT_DH}
    ${rt}=    Scroll And Get Text    ${TwoPoints.RESULT_SLOPE_RATIO}
    ${pc}=    Scroll And Get Text    ${TwoPoints.RESULT_SLOPE_PERCENT}
    ${sa}=    Scroll And Get Text    ${TwoPoints.RESULT_SLOPE_ANGLE}
    ${dn}=    Scroll And Get Text    ${TwoPoints.RESULT_NORTH}
    ${de}=    Scroll And Get Text    ${TwoPoints.RESULT_EAST}

    &{res}=    Create Dictionary
    ...    azimuth=${az}
    ...    horizontal=${hd}
    ...    slope_dist=${sd}
    ...    vertical=${vt}
    ...    dh=${dh}
    ...    slope_ratio=${rt}
    ...    slope_percent=${pc}
    ...    slope_angle=${sa}
    ...    north_offset=${dn}
    ...    east_offset=${de}

    RETURN    &{res}
