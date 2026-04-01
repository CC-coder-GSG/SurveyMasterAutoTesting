*** Settings ***
Resource    ../../locators/android/Popups.resource
Resource    ../../locators/android/ConnectDevice.resource
Resource    ../pages/GuideActivity.resource
Resource    ../../keywords/pages/Equipment/ConnectDevice.resource


*** Keywords ***
Wait Connect Device Popup Disappear
    [Documentation]    等待连接设备的 loading 弹窗消失
    Wait Gone    ${Popups.Connect_Loading_Icon}

Connect A Device
    [Documentation]    连接一台指定蓝牙设备：进入设备页 → 打开连接界面 → 选择目标设备 → 等待蓝牙搜索并连接
    ...    若设备已连接（显示"断开"按钮），则先断开再重新连接，确保流程一致。
    Equipment Bottom Button Click
    DeviceConnect Button Click
    ${already_connected}=    Run Keyword And Return Status
    ...    Page Should Contain Element    ${ConnectDevice.Disconnect_Button}
    IF    '${already_connected}' == 'True'
        Log    检测到设备已连接，先断开再重新连接    console=yes
        Click Element    ${ConnectDevice.Disconnect_Button}
        Sleep    2s
    END
    Tap Target Device
    Wait Search And Connect Bluetooth Device    T61S00167
