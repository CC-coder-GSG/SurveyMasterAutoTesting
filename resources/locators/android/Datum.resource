*** Variables ***
# 坐标系统页面定位资源
&{Datum}
# 常用坐标系按钮
...    COMMON_COORDINATE_BUTTON=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_coordinate_store")
# 目标椭球按钮
...    TARGET_ELLIPSOID_BUTTON=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_ellipsoid_name")
# 投影按钮
...    PROJECTION_BUTTON=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_projection_name")
# 七参数按钮
...    SEVEN_PARAMETERS_BUTTON=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_seven_param")
# 平面校正按钮
...    H.RMS_BUTTON=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_plane_correction")
# 高程拟合按钮
...    V.RMS_BUTTON=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_elevation_fitting")
# 大地水准面按钮
...    GEOID_MODEL_BUTTON=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_egm_mode")
# 平面格网模型按钮
...    GRID_CORRECTION_BUTTON=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_grid")
# 平移参数按钮
...    TRANSLATION_PARAMETERS_BUTTON=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_shift_para")
# 确认按钮
...    CONFIRM_BUTTON=android=new UiSelector().text("确认")

# 七参数打开按钮
...    USE_SEVEN_PARAMETERS_BUTTON=android=new UiSelector().resourceId("com.sinognss.sm.free:id/sw_seven_param")
# DX输入框
...   Seven Parameters_DX_INPUT_BOX=id=com.sinognss.sm.free:id/shiftX_txt
# DY输入框
...   Seven Parameters_DY_INPUT_BOX=id=com.sinognss.sm.free:id/shiftY_txt
# DZ输入框
...   Seven Parameters_DZ_INPUT_BOX=id=com.sinognss.sm.free:id/shiftZ_txt
# RX输入框
...   Seven Parameters_RX_INPUT_BOX=id=com.sinognss.sm.free:id/revolveX_txt
# RY输入框
...   Seven Parameters_RY_INPUT_BOX=id=com.sinognss.sm.free:id/revolveY_txt
# RZ输入框
...   Seven Parameters_RZ_INPUT_BOX=id=com.sinognss.sm.free:id/revolveZ_txt
# K输入框
...   Seven Parameters_K_INPUT_BOX=id=com.sinognss.sm.free:id/scaleAdjust_txt
# 确认修改按钮
...    SEVEN_PARAMETERS_CONFIRM_BUTTON=android=new UiSelector().resourceId("com.sinognss.sm.free:id/btn_confirm")

