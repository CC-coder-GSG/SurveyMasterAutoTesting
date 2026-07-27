*** Variables ***
# 首次启动流程定位器；用于处理安装后的隐私协议和界面风格确认。
&{Startup}
# 隐私协议确认按钮：业务弹窗使用稳定且唯一的 resource-id。
...    PRIVACY_AGREEMENT_CONFIRM=id=com.sinognss.sm.free:id/btn_positive
# 界面风格保存按钮：实机未暴露业务 resource-id，使用已验证的精确文案区分。
...    STYLE_SAVE_BUTTON=android=new UiSelector().text("保存")
# Android 运行时权限“使用应用时允许”：系统权限控制器的稳定 resource-id。
...    RUNTIME_PERMISSION_ALLOW_WHILE_USING=id=com.android.permissioncontroller:id/permission_allow_foreground_only_button
