*** Variables ***
# 项目管理页面定位资源
&{Project}
# 更多按钮
...    MORE_BUTTON=android=new UiSelector().text("更多")
# 搜索项目输入框
...    SEARCH_SEARCHBOX=id=com.sinognss.sm.free:id/search_bar
# 新建项目按钮
...    NEW_PROJECT_BUTTON=android=new UiSelector().text("新建")
# 项目按照名称寻找
...    PROJECT_NAME_BOX=android=new UiSelector().text("\${project_name}")
# 项目名称输入框
...    PROJECT_NAME_INPUT_BOX=id=com.sinognss.sm.free:id/name_txt
# 项目创建者输入框
...    PROJECT_CREATOR_INPUT_BOX=id=com.sinognss.sm.free:id/operator_txt
# 项目备注输入框
...    PROJECT_REMARK_INPUT_BOX=id=com.sinognss.sm.free:id/description_txt
# 项目创建确认按钮
...    PROJECT_CREATE_CONFIRM_BUTTON=android=new UiSelector().text("确认")
# 项目列表页面
...    PROJECT_LIST=id=com.sinognss.sm.free:id/dl_cloud
# 右滑列表属性按钮
...    ATTRUBITES=android=new UiSelector().resourceId("com.sinognss.sm.free:id/layout_function_container").instance(3)
# 右滑列表分享按钮
...    SHARE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/layout_function_container").instance(2)
# 右滑列表上传按钮
...    UPLOAD=android=new UiSelector().resourceId("com.sinognss.sm.free:id/layout_function_container").instance(1)
# 右滑列表删除按钮
...    DELETE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/layout_function_container").instance(0)
# 右滑列表打开按钮
...    OPEN=android=new UiSelector().resourceId("com.sinognss.sm.free:id/layout_function_container").instance(3)