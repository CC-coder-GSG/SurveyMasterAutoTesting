*** Variables ***
# 两点测量页面定位资源
&{TwoPoints}
# 开始点名称输入框
...    START_POINT_NAME_INPUT_BOX=new UiSelector().resourceId("com.sinognss.sm.free:id/et_point_name").instance(0)
# 开始点N坐标输入框
...    START_N_INPUT_BOX=new UiSelector().resourceId("com.sinognss.sm.free:id/et_x").instance(0)  
# 开始点E坐标输入框
...    START_E_INPUT_BOX=new UiSelector().resourceId("com.sinognss.sm.free:id/et_y").instance(0)
# 开始点Z坐标输入框
...    START_Z_INPUT_BOX=new UiSelector().resourceId("com.sinognss.sm.free:id/et_z").instance(0)
# 结束点名称输入框
...    END_POINT_NAME_INPUT_BOX=new UiSelector().resourceId("com.sinognss.sm.free:id/et_point_name").instance(1)  
# 结束点N坐标输入框
...    END_N_INPUT_BOX=new UiSelector().resourceId("com.sinognss.sm.free:id/et_x").instance(1)  
# 结束点E坐标输入框
...    END_E_INPUT_BOX=new UiSelector().resourceId("com.sinognss.sm.free:id/et_y").instance(1)
# 结束点Z坐标输入框
...    END_Z_INPUT_BOX=new UiSelector().resourceId("com.sinognss.sm.free:id/et_z").instance(1)
# 计算按钮
...    CALCULATE_BUTTON=com.sinognss.sm.free:id/btn_calc