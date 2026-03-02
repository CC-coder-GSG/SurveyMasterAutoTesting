*** Settings ***
Library    AppiumLibrary

*** Keywords ***
Handle Privacy Agreement
    [Documentation]    处理首次启动时的"温馨提示"隐私弹窗及界面风格界面
    ...    如果不出现则跳过，等待超时设为 20s 以适应不同性能手机
    Log    正在检查是否存在隐私协议弹窗...    console=yes
    
    # 1. 检测弹窗是否存在（不报错模式）
    ${is_popup_visible}=    Run Keyword And Return Status    Wait Until Page Contains Element    id=com.sinognss.sm.free:id/btn_positive    timeout=20s
    
    # 2. 根据检测结果决定是否点击
    IF    '${is_popup_visible}' == 'True'
        Log    检测到隐私弹窗，点击'同意并继续'
        Click Element    id=com.sinognss.sm.free:id/btn_positive
        # 必须等待弹窗动画消失，防止后续点击被遮挡
        Sleep    3s
        # 判断界面风格界面是否存在
        ${is_fengge_visable}=    Run Keyword And Return Status    Wait Until Page Contains Element    android=new UiSelector().text("保存")    timeout=20s
        IF    '${is_fengge_visable}' == 'True'
        Log    检测到界面风格界面，点击'保存'
        Click Element    android=new UiSelector().text("保存")
        # 必须等待弹窗动画消失，防止后续点击被遮挡
        Sleep    3s
        ELSE    
            Log    未检测到界面风格界面，继续执行后续步骤
        END
    ELSE
        Log    未检测到隐私弹窗，继续执行后续步骤
    END