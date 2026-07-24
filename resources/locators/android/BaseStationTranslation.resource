*** Variables ***
# 基站平移页；输入、结果和选点动作均有稳定 resource-id，无 XPath。
&{BaseStationTranslation}
# 返回按钮：稳定 content-desc“返回”。
...    BACK_BUTTON=accessibility_id=返回
# 已知点北坐标输入框：稳定且唯一的 resource-id。
...    TARGET_NORTH_INPUT=id=com.sinognss.sm.free:id/target_x_txt
# 已知点东坐标输入框：稳定且唯一的 resource-id。
...    TARGET_EAST_INPUT=id=com.sinognss.sm.free:id/target_y_txt
# 已知点高程输入框：稳定且唯一的 resource-id。
...    TARGET_HEIGHT_INPUT=id=com.sinognss.sm.free:id/target_z_txt
# 库选入口：稳定且唯一的 resource-id。
...    SELECT_FROM_LIBRARY=id=com.sinognss.sm.free:id/layout_library_point
# 图选入口：稳定且唯一的 resource-id。
...    SELECT_FROM_MAP=id=com.sinognss.sm.free:id/layout_map_point
# 测量入口：稳定且唯一的 resource-id，调用会进入实测流程。
...    SURVEY_POINT=id=com.sinognss.sm.free:id/layout_survey_point
# 当前点北坐标：稳定且唯一的 resource-id。
...    CURRENT_NORTH=id=com.sinognss.sm.free:id/current_x_txt
# 当前点东坐标：稳定且唯一的 resource-id。
...    CURRENT_EAST=id=com.sinognss.sm.free:id/current_y_txt
# 当前点高程：稳定且唯一的 resource-id。
...    CURRENT_HEIGHT=id=com.sinognss.sm.free:id/current_z_txt
# 北方向平移结果：稳定且唯一的 resource-id。
...    DELTA_NORTH=id=com.sinognss.sm.free:id/dx_txt
# 东方向平移结果：稳定且唯一的 resource-id。
...    DELTA_EAST=id=com.sinognss.sm.free:id/dy_txt
# 高程平移结果：稳定且唯一的 resource-id。
...    DELTA_HEIGHT=id=com.sinognss.sm.free:id/dh_txt
# 计算按钮：稳定且唯一的 resource-id。
...    CALCULATE_BUTTON=id=com.sinognss.sm.free:id/action_calc
# 应用按钮：实机没有 resource-id/content-desc，使用 Button 类名 + 精确文本。
...    APPLY_BUTTON=android=new UiSelector().className("android.widget.Button").text("应用")
