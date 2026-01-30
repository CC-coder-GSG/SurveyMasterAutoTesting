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
    [Arguments]    ${NAME_BOX}    ${N_BOX}    ${E_BOX}    ${Z_BOX}    &{point}
    Input Point Name    ${NAME_BOX}    ${point['name']}
    Input N             ${N_BOX}       ${point['n']}
    Input E             ${E_BOX}       ${point['e']}
    Input Z             ${Z_BOX}       ${point['z']}

Input Start Point
    [Arguments]    &{start}
    Input Point Information
    ...    ${TwoPoints.START_POINT_NAME_INPUT_BOX}
    ...    ${TwoPoints.START_N_INPUT_BOX}
    ...    ${TwoPoints.START_E_INPUT_BOX}
    ...    ${TwoPoints.START_Z_INPUT_BOX}
    ...    &{start}

Input End Point
    [Arguments]    &{end}
    Input Point Information
    ...    ${TwoPoints.END_POINT_NAME_INPUT_BOX}
    ...    ${TwoPoints.END_N_INPUT_BOX}
    ...    ${TwoPoints.END_E_INPUT_BOX}
    ...    ${TwoPoints.END_Z_INPUT_BOX}
    ...    &{end}

Tap Calculate Button
    Tap    ${TwoPoints.CALCULATE_BUTTON}

Get TwoPoints Result
    ${az}=    Get Text    ${TwoPoints.RESULT_AZIMUTH}
    ${hd}=    Get Text    ${TwoPoints.RESULT_HORIZONTAL}
    ${sd}=    Get Text    ${TwoPoints.RESULT_SLOPE_DIST}
    ${vt}=    Get Text    ${TwoPoints.RESULT_VERTICAL}
    ${dh}=    Get Text    ${TwoPoints.RESULT_DH}
    ${rt}=    Get Text    ${TwoPoints.RESULT_RATIO}
    ${pc}=    Get Text    ${TwoPoints.RESULT_PERCENT}
    ${dn}=    Get Text    ${TwoPoints.RESULT_NORTH}
    ${de}=    Get Text    ${TwoPoints.RESULT_EAST}

    &{res}=    Create Dictionary
    ...    azimuth=${az}
    ...    horizontal=${hd}
    ...    slope_dist=${sd}
    ...    vertical=${vt}
    ...    dh=${dh}
    ...    slope_ratio=${rt}
    ...    slope_percent=${pc}
    ...    north_offset=${dn}
    ...    east_offset=${de}

    [Return]    &{res}
