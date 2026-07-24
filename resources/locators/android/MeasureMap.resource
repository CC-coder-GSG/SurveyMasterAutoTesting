*** Variables ***
# 点测量、点放样、CAD 共用地图页面及其专属控件；全部使用稳定 resource-id，无 XPath。
&{MeasureMap}
# 地图根容器：稳定且唯一的 resource-id，用于页面就绪判断。
...    MAP_ROOT=id=com.sinognss.sm.free:id/map_root_view
# 地图画布容器：稳定且唯一的 resource-id。
...    MAP_FRAME=id=com.sinognss.sm.free:id/map_frame
# 地图返回按钮：稳定且唯一的 resource-id。
...    BACK_BUTTON=id=com.sinognss.sm.free:id/iv_back
# 定位状态：稳定且唯一的 resource-id。
...    SOLUTION_STATUS=id=com.sinognss.sm.free:id/tv_solution_status
# 差分延迟：稳定且唯一的 resource-id。
...    DIFFERENTIAL_DELAY=id=com.sinognss.sm.free:id/tv_diff_delayed
# 水平精度：稳定且唯一的 resource-id。
...    HORIZONTAL_ACCURACY=id=com.sinognss.sm.free:id/tv_diff_h
# 垂直精度：稳定且唯一的 resource-id。
...    VERTICAL_ACCURACY=id=com.sinognss.sm.free:id/tv_diff_v
# 使用卫星数：稳定且唯一的 resource-id。
...    USED_SATELLITES=id=com.sinognss.sm.free:id/tv_used_satellite
# 跟踪卫星数：稳定且唯一的 resource-id。
...    TRACKED_SATELLITES=id=com.sinognss.sm.free:id/tv_tracked_satellite
# 设置入口：稳定且唯一的 resource-id。
...    SETTINGS=id=com.sinognss.sm.free:id/rl_settings
# 更多入口：稳定且唯一的 resource-id。
...    MORE=id=com.sinognss.sm.free:id/rl_more
# 工具栏显隐入口：稳定且唯一的 resource-id。
...    TOOLBAR_VISIBILITY=id=com.sinognss.sm.free:id/rl_hide_or_show
# 卫星信息入口：稳定且唯一的 resource-id。
...    SATELLITE_INFO=id=com.sinognss.sm.free:id/rl_satellite
# 地图比例尺：稳定且唯一的 resource-id。
...    MAP_SCALE=id=com.sinognss.sm.free:id/scale_view
# 底部面板拖动柄：稳定且唯一的 resource-id。
...    BOTTOM_SHEET_HANDLE=id=com.sinognss.sm.free:id/bottom_sheet_handle
# 点名输入框：点放样/CAD 页面稳定且唯一的 resource-id。
...    POINT_NAME_INPUT=id=com.sinognss.sm.free:id/tvPointName
# 代码输入框：点放样/CAD 页面稳定且唯一的 resource-id。
...    CODE_INPUT=id=com.sinognss.sm.free:id/esp_code
# 天线高：点放样/CAD 页面稳定且唯一的 resource-id。
...    ANTENNA_HEIGHT=id=com.sinognss.sm.free:id/tv_antenna_height
# 测量控制器：点放样/CAD 页面稳定且唯一的 resource-id；点击内部测量动作会采集数据。
...    SURVEY_CONTROLLER=id=com.sinognss.sm.free:id/dl_survey
# 安全模式控制器：点放样/CAD 页面稳定且唯一的 resource-id。
...    SAFE_MODE=id=com.sinognss.sm.free:id/dl_safe_mode
# 点库入口：点放样页面稳定且唯一的 resource-id。
...    POINT_STORE=id=com.sinognss.sm.free:id/iv_point_store
# 上一个放样点：点放样页面稳定且唯一的 resource-id。
...    PREVIOUS_POINT=id=com.sinognss.sm.free:id/iv_pre
# 下一个放样点：点放样页面稳定且唯一的 resource-id。
...    NEXT_POINT=id=com.sinognss.sm.free:id/iv_next
# 放样点筛选：点放样页面稳定且唯一的 resource-id。
...    STAKE_POINT_FILTER=id=com.sinognss.sm.free:id/ll_stake_point_filter
# 最近点模式：点放样页面稳定且唯一的 resource-id。
...    NEAREST_POINT_MODE=id=com.sinognss.sm.free:id/tv_near
# CAD 状态栏：CAD 页面稳定且唯一的 resource-id。
...    CAD_STATUS_BAR=id=com.sinognss.sm.free:id/statusbar_cad
