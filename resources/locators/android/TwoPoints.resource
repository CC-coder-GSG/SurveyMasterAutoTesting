*** Variables ***
# 两点测量页面定位资源
&{TwoPoints}
# 起点
...    START_POINT_NAME_INPUT_BOX= android=new UiSelector().resourceId("com.sinognss.sm.free:id/ll_name")\.childSelector(new UiSelector().text("起点"))\.fromParent(new UiSelector().resourceId("com.sinognss.sm.free:id/et_point_name"))
...    START_N_INPUT_BOX= android=new UiSelector().resourceId("com.sinognss.sm.free:id/cov_start_point")\.childSelector(new UiSelector().resourceId("com.sinognss.sm.free:id/ll_start_point")\.childSelector(new UiSelector().className("android.widget.LinearLayout")\.childSelector(new UiSelector().resourceId("com.sinognss.sm.free:id/et_x"))))
...    START_E_INPUT_BOX= android=new UiSelector().resourceId("com.sinognss.sm.free:id/cov_start_point")\.childSelector(new UiSelector().resourceId("com.sinognss.sm.free:id/ll_start_point")\.childSelector(new UiSelector().className("android.widget.LinearLayout")\.childSelector(new UiSelector().resourceId("com.sinognss.sm.free:id/et_y"))))
...    START_Z_INPUT_BOX= android=new UiSelector().resourceId("com.sinognss.sm.free:id/cov_start_point")\.childSelector(new UiSelector().resourceId("com.sinognss.sm.free:id/ll_start_point")\.childSelector(new UiSelector().className("android.widget.LinearLayout")\.childSelector(new UiSelector().resourceId("com.sinognss.sm.free:id/et_h"))))
# 终点
...    END_POINT_NAME_INPUT_BOX= android=new UiSelector().resourceId("com.sinognss.sm.free:id/ll_name")\.childSelector(new UiSelector().text("终点"))\.fromParent(new UiSelector().resourceId("com.sinognss.sm.free:id/et_point_name"))
...    END_N_INPUT_BOX= android=new UiSelector().resourceId("com.sinognss.sm.free:id/cov_end_point")\.childSelector(new UiSelector().resourceId("com.sinognss.sm.free:id/ll_start_point")\.childSelector(new UiSelector().className("android.widget.LinearLayout")\.childSelector(new UiSelector().resourceId("com.sinognss.sm.free:id/et_x"))))
...    END_E_INPUT_BOX= android=new UiSelector().resourceId("com.sinognss.sm.free:id/cov_end_point")\.childSelector(new UiSelector().resourceId("com.sinognss.sm.free:id/ll_start_point")\.childSelector(new UiSelector().className("android.widget.LinearLayout")\.childSelector(new UiSelector().resourceId("com.sinognss.sm.free:id/et_y"))))
...    END_Z_INPUT_BOX= android=new UiSelector().resourceId("com.sinognss.sm.free:id/cov_end_point")\.childSelector(new UiSelector().resourceId("com.sinognss.sm.free:id/ll_start_point")\.childSelector(new UiSelector().className("android.widget.LinearLayout")\.childSelector(new UiSelector().resourceId("com.sinognss.sm.free:id/et_h"))))
# 计算按钮
...    CALCULATE_BUTTON=com.sinognss.sm.free:id/btn_calc
# 计算结果
       # 方位角
...    RESULT_AZIMUTH=id=com.sinognss.sm.free:id/txt_azimuth
       # 水平距离
...    RESULT_HORIZONTAL=id=com.sinognss.sm.free:id/txt_horz_distance
       # 斜距
...    RESULT_SLOPE_DIST=id=com.sinognss.sm.free:id/txt_slope_distance
       # 垂直垂距
...    RESULT_VERTICAL=id=com.sinognss.sm.free:id/txt_vertical_distance
       # Δh
...    RESULT_DH=id=com.sinognss.sm.free:id/txt_dh
       # 坡比（比率）
...    RESULT_SLOPE_RATIO=id=com.sinognss.sm.free:id/txt_slope_ratio
       # 坡度（百分比）
...    RESULT_SLOPE_PERCENT=id=com.sinognss.sm.free:id/slope_ratio_txt
       # 坡度（角度）
...    RESULT_SLOPE_ANGLE=id=com.sinognss.sm.free:id/txt_slope
       # 偏北
...    RESULT_NORTH=id=com.sinognss.sm.free:id/txt_partial_north
       # 偏东
...    RESULT_EAST=id=com.sinognss.sm.free:id/txt_partial_east