*** Settings ***
Resource    ../pages/GuideActivity.resource
Resource    ../pages/Project/Datum.resource

*** Keywords ***
# 输入七参数
Input Seven Parameters
    COORD_Buttom Button Click
    Tap Seven Parameters Button
    Tap Use Seven Parameters Button
    Wait Until Page Contains Element    ${Datum}[Seven Parameters_DX_INPUT_BOX]
    Enter Seven Parameters DX    DX=10.2
    Enter Seven Parameters DY    DY=11.3
    Enter Seven Parameters DZ    DZ=12.4
    Enter Seven Parameters RX    RX=13.5
    Enter Seven Parameters RY    RY=14.6
    Enter Seven Parameters RZ    RZ=15.7
    Enter Seven Parameters K    K=1.1
    Tap Seven Parameters Confirm Button
    Tap Confirm Button
   
    #Page Should Contain Text    当前项目坐标系已变更！    timeout=10s
    COORD_Buttom Button Click
    Tap Seven Parameters Button
    Wait Until Page Contains Element    ${Datum}[Seven Parameters_DX_INPUT_BOX]
    # 验证输入框包含修改后的值
    ${k_value}    Get Text    ${Datum}[Seven Parameters_K_INPUT_BOX]
    #Should Contain    ${k_value}    1.1    msg=K值未包含修改后的1.1,七参数可能未保存
    Should Be Equal    ${k_value}    1.100000000000    msg=K值未包含修改后的1.1,七参数可能未保存