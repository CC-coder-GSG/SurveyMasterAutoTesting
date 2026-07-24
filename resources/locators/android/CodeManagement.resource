*** Variables ***
# 代码管理页；唯一控件使用 resource-id，无 XPath。
&{CodeManagement}
# 返回按钮：稳定 content-desc“返回”。
...    BACK_BUTTON=accessibility_id=返回
# 代码分组选择框：稳定且唯一的 resource-id。
...    GROUP_SPINNER=id=com.sinognss.sm.free:id/spinner_code_group
# 代码分组名称：稳定且唯一的 resource-id。
...    GROUP_NAME=id=com.sinognss.sm.free:id/tv_code_group_name
# 分组管理入口：稳定且唯一的 resource-id。
...    GROUP_MANAGEMENT=id=com.sinognss.sm.free:id/ll_management
# 更多按钮：稳定且唯一的 resource-id。
...    MORE_BUTTON=id=com.sinognss.sm.free:id/layout_more
# 代码列表：稳定且唯一的 resource-id。
...    CODE_LIST=id=com.sinognss.sm.free:id/lv_code
# 添加按钮：实机没有 resource-id/content-desc，使用 Button 类名 + 精确文本。
...    ADD_BUTTON=android=new UiSelector().className("android.widget.Button").text("添加")
