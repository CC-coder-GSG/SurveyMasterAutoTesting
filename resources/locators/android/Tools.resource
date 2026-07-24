*** Variables ***
# 工具主页全部入口（含上滑后可见入口）；共享 tv_title，未使用 XPath。
&{Tools}
# 天正云转换入口：共享 resource-id，使用精确文案区分。
...    T20_CLOUD_CONVERSION=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("天正云转换")
# CAD 云瘦身入口：共享 resource-id，使用精确文案区分。
...    CAD_CLOUD_OPTIMIZATION=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("CAD云瘦身")
# 底图校正入口：共享 resource-id，使用精确文案区分。
...    BASEMAP_CORRECTION=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("底图校正")
# 面积计算入口：共享 resource-id，使用精确文案区分。
...    AREA_CALCULATION=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("面积计算")
# 土方计算入口：共享 resource-id，使用精确文案区分。
...    EARTHWORK_CALCULATION=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("土方计算")
# 角度转换入口：共享 resource-id，使用精确文案区分。
...    ANGLE_CONVERSION=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("角度转换")
# 两点计算入口：共享 resource-id，使用精确文案区分。
...    TWO_POINT_CALCULATION=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("两点计算")
# 点线距离入口：共享 resource-id，使用精确文案区分。
...    POINT_LINE_DISTANCE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("点线距离")
# 偏心点入口：共享 resource-id，使用精确文案区分。
...    ECCENTRIC_POINT=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("偏心点")
# 偏转角入口：共享 resource-id，使用精确文案区分。
...    DEFLECTION_ANGLE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("偏转角")
# 算旋转点入口：共享 resource-id，使用精确文案区分。
...    ROTATED_POINT=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("算旋转点")
# 算交汇点入口：共享 resource-id，使用精确文案区分。
...    INTERSECTION_POINT=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("算交汇点")
# 算等分角入口：需上滑后可见；共享 resource-id，使用精确文案区分。
...    BISECT_ANGLE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("算等分角")
# 划分线入口：需上滑后可见；共享 resource-id，使用精确文案区分。
...    DIVIDE_LINE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("划分线")
# 测点平均值入口：需上滑后可见；共享 resource-id，使用精确文案区分。
...    AVERAGE_SURVEY_POINT=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("测点平均值")
# 激光测距入口：需上滑后可见；共享 resource-id，使用精确文案区分。
...    LASER_DISTANCE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("激光测距")
# 更多入口：需上滑后可见；共享 resource-id，使用精确文案区分。
...    MORE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("更多")
