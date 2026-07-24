*** Variables ***
# 参数计算页；优先使用唯一 resource-id，无 XPath。
&{ParameterCalculation}
# 返回按钮：稳定 content-desc“返回”。
...    BACK_BUTTON=accessibility_id=返回
# 坐标转换方法选择框：稳定且唯一的 resource-id。
...    CONVERSION_METHOD=id=com.sinognss.sm.free:id/sp_conversion_method
# 高程拟合方法选择框：稳定且唯一的 resource-id。
...    ELEVATION_METHOD=id=com.sinognss.sm.free:id/sp_elevation_method
# 控制点列表：稳定且唯一的 resource-id。
...    POINT_LIST=id=com.sinognss.sm.free:id/rv
# 控制点表头：稳定且唯一的 resource-id。
...    CONTROL_POINT_HEADER=id=com.sinognss.sm.free:id/tv_control_point_name
# 测量点表头：稳定且唯一的 resource-id。
...    SURVEY_POINT_HEADER=id=com.sinognss.sm.free:id/tv_survey_point_name
# 匹配入口：稳定且唯一的 resource-id。
...    MATCH_BUTTON=id=com.sinognss.sm.free:id/tv_match
# 水平残差表头：稳定且唯一的 resource-id。
...    HORIZONTAL_RESIDUAL_HEADER=id=com.sinognss.sm.free:id/tv_horizontal_residual
# 垂直残差表头：稳定且唯一的 resource-id。
...    VERTICAL_RESIDUAL_HEADER=id=com.sinognss.sm.free:id/tv_vertical_residual
# 比例因子结果：稳定且唯一的 resource-id。
...    SCALE_FACTOR=id=com.sinognss.sm.free:id/tv_scale_factor
# 计算结果区域：稳定且唯一的 resource-id。
...    RESULT_PANEL=id=com.sinognss.sm.free:id/layout_calc_result
# 更多按钮：稳定且唯一的 resource-id。
...    MORE_BUTTON=id=com.sinognss.sm.free:id/layout_more
# 添加按钮：实机没有 resource-id/content-desc，使用 Button 类名 + 精确文本。
...    ADD_BUTTON=android=new UiSelector().className("android.widget.Button").text("添加")
# 应用按钮：实机没有 resource-id/content-desc，使用 Button 类名 + 精确文本。
...    APPLY_BUTTON=android=new UiSelector().className("android.widget.Button").text("应用")
