*** Variables ***
# 测量主页全部入口（含上滑后可见入口）；共享 tv_title，未使用 XPath。
&{Measure}
# 点测量入口：共享 resource-id，使用精确文案区分。
...    POINT_SURVEY=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("点测量")
# 点放样入口：共享 resource-id，使用精确文案区分。
...    POINT_STAKE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("点放样")
# CAD 入口：共享 resource-id，使用精确文案区分。
...    CAD=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("CAD")
# 光伏放样入口：共享 resource-id，使用精确文案区分。
...    PHOTOVOLTAIC_STAKE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("光伏放样")
# 线放样入口：共享 resource-id，使用精确文案区分。
...    LINE_STAKE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("线放样")
# 边坡放样入口：共享 resource-id，使用精确文案区分。
...    SLOPE_STAKE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("边坡放样")
# 道路放样入口：共享 resource-id，使用精确文案区分。
...    ROAD_STAKE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("道路放样")
# 面放样入口：共享 resource-id，使用精确文案区分。
...    SURFACE_STAKE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("面放样")
# 道路管理入口：共享 resource-id，使用精确文案区分。
...    ROAD_MANAGEMENT=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("道路管理")
# 塔基放样入口：共享 resource-id，使用精确文案区分。
...    TOWER_FOUNDATION_STAKE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("塔基放样")
# 基坑开挖线放样入口：共享 resource-id，使用精确文案区分。
...    FOUNDATION_PIT_STAKE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("基坑开挖线放样")
# 挖机作业入口：共享 resource-id，使用精确文案区分。
...    EXCAVATOR_OPERATION=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("挖机作业")
# 铁路测量入口：需上滑后可见；共享 resource-id，使用精确文案区分。
...    RAILWAY_SURVEY=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("铁路测量")
# 海洋测量入口：需上滑后可见；共享 resource-id，使用精确文案区分。
...    MARINE_SURVEY=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("海洋测量")
# 更多入口：需上滑后可见；共享 resource-id，使用精确文案区分。
...    MORE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_title").text("更多")
