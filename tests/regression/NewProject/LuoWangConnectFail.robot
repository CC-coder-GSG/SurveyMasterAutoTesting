*** Settings ***
Resource    ../../../resources/keywords/common/flow_helper.resource
Resource    ../../../resources/keywords/common/teardown.resource
Resource    ../../../resources/keywords/flows/WanXiangConnect.resource
Resource    ../../../resources/keywords/flows/EquipmentInformation.resource
Resource    ../../../resources/keywords/flows/ConnectDevice.resource


*** Test Cases ***
LuoWang Connect Stability Test
    [Documentation]    接入司南万象压测：循环100次，累计3次断言失败则停止。
    
    # 1. 初始化失败计数器
    ${fail_count}    Set Variable    0
    
    # 2. 开始 100 次循环
    FOR    ${index}    IN RANGE    100
        Log    === 正在执行第 ${index + 1} 次循环 ===    console=yes
        
        # --- 步骤 1 & 2 ---
        Tap SinoWanXiang Button First
        Sleep    6s
        
        # --- 步骤 3: 核心断言 ---
        # 使用 Run Keyword And Return Status 捕获 "Wait WanXiang Get Data" 的执行结果
        # ${status} 只有两个值: True (成功) 或 False (失败)
        ${status}=    Run Keyword And Return Status    Wait WanXiang Get Data
        
        # 如果状态为 False，处理失败逻辑
        IF    '${status}' == 'False'
            # 计数器 +1
            ${fail_count}=    Evaluate    ${fail_count} + 1
            
            # 记录警告日志（会在报告中显示为黄色或高亮）
            Log    [警告] 第 ${index + 1} 次循环获取差分数据失败！当前累计失败次数: ${fail_count}    level=WARN
            
            # 截图保留现场 (建议加上这一步，方便排查为什么失败)
            Run Keyword And Ignore Error    Capture Page Screenshot
        ELSE
            Log    第 ${index + 1} 次循环数据获取成功。
        END
        
        # --- 检查是否达到退出条件 (累计 3 次) ---
        IF    ${fail_count} >= 3
            Log    累计失败次数已达 3 次，停止测试。    level=ERROR
            Fail    Test Aborted: Failure limit (3) reached.
        END

        # --- 步骤 4, 5, 6: 恢复环境 ---
        # 无论上面步骤3是成功还是失败，这些步骤都会执行，确保设备重启，为下一次循环做好准备
        Deep Restart
        Wait Connect Device Popup Disappear
        Wait Search for Sattlite
        
        # 循环缓冲
        Sleep    2s
    END

