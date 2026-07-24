*** Variables ***
# 坐标系统页；优先使用唯一 resource-id，按钮无 id 时使用类名 + 精确文本，未使用 XPath。
&{CoordinateSystem}
# 返回按钮：稳定 content-desc“返回”。
...    BACK_BUTTON=accessibility_id=返回
# 坐标系统名称输入框：稳定且唯一的 resource-id。
...    NAME_INPUT=id=com.sinognss.sm.free:id/coordinate_name_text
# 常用坐标系入口：稳定且唯一的 resource-id。
...    COORDINATE_STORE=id=com.sinognss.sm.free:id/tv_coordinate_store
# 源椭球区域：稳定且唯一的 resource-id。
...    SOURCE_ELLIPSOID=id=com.sinognss.sm.free:id/rl_source_ellipsoid
# 源椭球名称：稳定且唯一的 resource-id。
...    SOURCE_ELLIPSOID_NAME=id=com.sinognss.sm.free:id/tv_source_ellipsoid_name
# 目标椭球区域：稳定且唯一的 resource-id。
...    TARGET_ELLIPSOID=id=com.sinognss.sm.free:id/rl_ellipsoid
# 目标椭球名称：稳定且唯一的 resource-id。
...    TARGET_ELLIPSOID_NAME=id=com.sinognss.sm.free:id/tv_ellipsoid_name
# 投影区域：稳定且唯一的 resource-id。
...    PROJECTION=id=com.sinognss.sm.free:id/rl_projection
# 投影名称：稳定且唯一的 resource-id。
...    PROJECTION_NAME=id=com.sinognss.sm.free:id/tv_projection_name
# 七参数/三参数区域：稳定且唯一的 resource-id。
...    SEVEN_PARAMETER=id=com.sinognss.sm.free:id/rl_seven_param
# 七参数/三参数当前值：稳定且唯一的 resource-id。
...    SEVEN_PARAMETER_VALUE=id=com.sinognss.sm.free:id/tv_seven_param
# 平面校正区域：稳定且唯一的 resource-id。
...    PLANE_CORRECTION=id=com.sinognss.sm.free:id/rl_plane_correction
# 平面校正当前值：稳定且唯一的 resource-id。
...    PLANE_CORRECTION_VALUE=id=com.sinognss.sm.free:id/tv_plane_correction
# 高程拟合区域：稳定且唯一的 resource-id。
...    ELEVATION_FITTING=id=com.sinognss.sm.free:id/rl_elevation_fitting
# 高程拟合当前值：稳定且唯一的 resource-id。
...    ELEVATION_FITTING_VALUE=id=com.sinognss.sm.free:id/tv_elevation_fitting
# 大地水准面模型区域：稳定且唯一的 resource-id。
...    GEOID_MODEL=id=com.sinognss.sm.free:id/rl_egm
# 大地水准面模型当前值：稳定且唯一的 resource-id。
...    GEOID_MODEL_VALUE=id=com.sinognss.sm.free:id/tv_egm_mode
# 平面格网模型区域：稳定且唯一的 resource-id。
...    GRID_MODEL=id=com.sinognss.sm.free:id/rl_grid
# 平面格网模型当前值：稳定且唯一的 resource-id。
...    GRID_MODEL_VALUE=id=com.sinognss.sm.free:id/tv_grid
# 平移参数区域：稳定且唯一的 resource-id。
...    SHIFT_PARAMETER=id=com.sinognss.sm.free:id/rl_shift_para
# 平移参数当前值：稳定且唯一的 resource-id。
...    SHIFT_PARAMETER_VALUE=id=com.sinognss.sm.free:id/tv_shift_para
# 确认按钮：实机没有 resource-id/content-desc，使用 Button 类名 + 精确文本。
...    CONFIRM_BUTTON=android=new UiSelector().className("android.widget.Button").text("确认")
