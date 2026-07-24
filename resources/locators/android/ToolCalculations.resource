*** Variables ***
# 已实机读取的纯计算工具页面；优先唯一 resource-id，按钮无 id 时使用类名 + 精确文本，未使用 XPath。
&{ToolCalculations}
# 通用返回按钮：稳定 content-desc“返回”。
...    BACK_BUTTON=accessibility_id=返回
# 通用计算按钮：角度转换/两点计算页面提供稳定且唯一的 resource-id。
...    CALCULATE_BUTTON=id=com.sinognss.sm.free:id/btn_calc
# 通用无 id 计算按钮：面积计算/点线距离页面使用 Button 类名 + 精确文本。
...    CALCULATE_BUTTON_BY_TEXT=android=new UiSelector().className("android.widget.Button").text("计算")
# 面积计算点列表：稳定且唯一的 resource-id。
...    AREA_POINT_LIST=id=com.sinognss.sm.free:id/rv
# 面积计算更多按钮：稳定且唯一的 resource-id。
...    AREA_MORE_BUTTON=id=com.sinognss.sm.free:id/layout_more
# 面积计算添加按钮：实机没有 resource-id/content-desc，使用 Button 类名 + 精确文本。
...    AREA_ADD_BUTTON=android=new UiSelector().className("android.widget.Button").text("添加")
# 面积计算预览按钮：实机没有 resource-id/content-desc，使用 Button 类名 + 精确文本。
...    AREA_PREVIEW_BUTTON=android=new UiSelector().className("android.widget.Button").text("预览")
# 角度格式下拉框：稳定且唯一的 resource-id。
...    ANGLE_FORMAT_SPINNER=id=com.sinognss.sm.free:id/sp_angle_format
# 角度输入框：稳定且唯一的 resource-id。
...    ANGLE_INPUT=id=com.sinognss.sm.free:id/et_angle
# 度分秒结果：稳定且唯一的 resource-id。
...    DMS_RESULT=id=com.sinognss.sm.free:id/tv_dms
# 度结果：稳定且唯一的 resource-id。
...    DEGREE_RESULT=id=com.sinognss.sm.free:id/tv_degree
# 弧度结果：稳定且唯一的 resource-id。
...    RADIAN_RESULT=id=com.sinognss.sm.free:id/tv_radian
# 百分度结果：稳定且唯一的 resource-id。
...    GRAD_RESULT=id=com.sinognss.sm.free:id/tv_grad
# 点选择表单点名输入框：稳定 resource-id；两点页面有多组，按页面上下文/instance 使用。
...    POINT_NAME_INPUT=id=com.sinognss.sm.free:id/et_point_name
# 点选择表单北坐标输入框：稳定 resource-id；两点页面有多组，按页面上下文/instance 使用。
...    NORTH_INPUT=id=com.sinognss.sm.free:id/et_x
# 点选择表单东坐标输入框：稳定 resource-id；两点页面有多组，按页面上下文/instance 使用。
...    EAST_INPUT=id=com.sinognss.sm.free:id/et_y
# 点选择表单高程输入框：稳定 resource-id；两点页面有多组，按页面上下文/instance 使用。
...    HEIGHT_INPUT=id=com.sinognss.sm.free:id/et_h
# 库选入口：稳定 resource-id；两点页面有多组，按页面上下文/instance 使用。
...    SELECT_FROM_LIBRARY=id=com.sinognss.sm.free:id/layout_library_point
# 图选入口：稳定 resource-id；两点页面有多组，按页面上下文/instance 使用。
...    SELECT_FROM_MAP=id=com.sinognss.sm.free:id/layout_map_point
# 测量入口：稳定 resource-id；点击会进入实测流程。
...    SURVEY_POINT=id=com.sinognss.sm.free:id/layout_survey_point
# 两点计算格网单选按钮：稳定且唯一的 resource-id。
...    GRID_RADIO=id=com.sinognss.sm.free:id/rbtn_grid
# 两点计算地面单选按钮：稳定且唯一的 resource-id。
...    GROUND_RADIO=id=com.sinognss.sm.free:id/rbtn_ground
# 两点计算方位角结果：稳定且唯一的 resource-id。
...    AZIMUTH_RESULT=id=com.sinognss.sm.free:id/txt_azimuth
# 点线距离清空按钮：稳定且唯一的 resource-id。
...    CLEAR_BUTTON=id=com.sinognss.sm.free:id/action_clear
# 点线距离示意图：稳定且唯一的 resource-id。
...    DISTANCE_GUIDE=id=com.sinognss.sm.free:id/iv_guide
