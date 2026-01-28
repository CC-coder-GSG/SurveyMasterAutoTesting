*** Variables ***
# 两点测量页面定位资源
&{TwoPoints}
# 起点名称输入框
...    START_POINT_NAME_INPUT_BOX= android=new UiSelector().resourceId("com.sinognss.sm.free:id/ll_name")\.childSelector(new UiSelector().text("起点"))\.fromParent(new UiSelector().resourceId("com.sinognss.sm.free:id/et_point_name"))
# 开始点N坐标输入框
...    START_N_INPUT_BOX= android=new UiSelector().resourceId("com.sinognss.sm.free:id/cov_start_point")\.childSelector(new UiSelector().resourceId("com.sinognss.sm.free:id/ll_start_point")\.childSelector(new UiSelector().className("android.widget.LinearLayout")\.childSelector(new UiSelector().resourceId("com.sinognss.sm.free:id/et_x"))))
# 起点E坐标输入框
...    START_E_INPUT_BOX= android=new UiSelector().resourceId("com.sinognss.sm.free:id/cov_start_point")\.childSelector(new UiSelector().resourceId("com.sinognss.sm.free:id/ll_start_point")\.childSelector(new UiSelector().className("android.widget.LinearLayout")\.childSelector(new UiSelector().resourceId("com.sinognss.sm.free:id/et_y"))))
# 开始点Z坐标输入框
...    START_Z_INPUT_BOX= android=new UiSelector().resourceId("com.sinognss.sm.free:id/cov_start_point")\.childSelector(new UiSelector().resourceId("com.sinognss.sm.free:id/ll_start_point")\.childSelector(new UiSelector().className("android.widget.LinearLayout")\.childSelector(new UiSelector().resourceId("com.sinognss.sm.free:id/et_h"))))
# 结束点名称输入框
...    END_POINT_NAME_INPUT_BOX= android=new UiSelector().resourceId("com.sinognss.sm.free:id/ll_name")\.childSelector(new UiSelector().text("终点"))\.fromParent(new UiSelector().resourceId("com.sinognss.sm.free:id/et_point_name"))
# 结束点N坐标输入框
...    END_N_INPUT_BOX= android=new UiSelector().resourceId("com.sinognss.sm.free:id/cov_end_point")\.childSelector(new UiSelector().resourceId("com.sinognss.sm.free:id/ll_start_point")\.childSelector(new UiSelector().className("android.widget.LinearLayout")\.childSelector(new UiSelector().resourceId("com.sinognss.sm.free:id/et_x"))))
# 结束点E坐标输入框
...    END_E_INPUT_BOX= android=new UiSelector().resourceId("com.sinognss.sm.free:id/cov_end_point")\.childSelector(new UiSelector().resourceId("com.sinognss.sm.free:id/ll_start_point")\.childSelector(new UiSelector().className("android.widget.LinearLayout")\.childSelector(new UiSelector().resourceId("com.sinognss.sm.free:id/et_y"))))
# 结束点Z坐标输入框
...    END_Z_INPUT_BOX= android=new UiSelector().resourceId("com.sinognss.sm.free:id/cov_end_point")\.childSelector(new UiSelector().resourceId("com.sinognss.sm.free:id/ll_start_point")\.childSelector(new UiSelector().className("android.widget.LinearLayout")\.childSelector(new UiSelector().resourceId("com.sinognss.sm.free:id/et_h"))))
# 计算按钮
...    CALCULATE_BUTTON=com.sinognss.sm.free:id/btn_calc