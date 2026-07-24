*** Variables ***
# 云服务登录页；所有交互控件均有稳定 resource-id，无 XPath。
&{CloudLogin}
# 返回按钮：稳定 content-desc“返回”。
...    BACK_BUTTON=accessibility_id=返回
# 用户名/手机号输入框：稳定且唯一的 resource-id。
...    USERNAME_INPUT=id=com.sinognss.sm.free:id/txt_username
# 密码输入框：稳定且唯一的 resource-id。
...    PASSWORD_INPUT=id=com.sinognss.sm.free:id/txt_password
# 密码显隐按钮：稳定且唯一的 resource-id。
...    PASSWORD_VISIBILITY=id=com.sinognss.sm.free:id/iv_control_pwd
# 登录按钮：稳定且唯一的 resource-id。
...    LOGIN_BUTTON=id=com.sinognss.sm.free:id/btn_login
# 忘记密码入口：稳定且唯一的 resource-id。
...    FORGOT_PASSWORD=id=com.sinognss.sm.free:id/txt_forget_pwd
# 注册入口：稳定且唯一的 resource-id。
...    REGISTER=id=com.sinognss.sm.free:id/tv_register
# 变更服务地址入口：稳定且唯一的 resource-id。
...    CHANGE_SERVER_ADDRESS=id=com.sinognss.sm.free:id/tv_change_service_address
# 欢迎文案：稳定且唯一的 resource-id，可用于页面就绪判断。
...    WELCOME_TEXT=id=com.sinognss.sm.free:id/tv_welcome
