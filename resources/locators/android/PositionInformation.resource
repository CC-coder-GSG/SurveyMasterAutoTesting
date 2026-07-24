*** Variables ***
# 位置信息页；所有动态结果均通过唯一 resource-id 定位，无 XPath。
&{PositionInformation}
# 返回按钮：稳定 content-desc“返回”。
...    BACK_BUTTON=accessibility_id=返回
# 定位状态：稳定且唯一的 resource-id。
...    SOLUTION_STATUS=id=com.sinognss.sm.free:id/tv_solution_status
# 卫星时间：稳定且唯一的 resource-id。
...    SATELLITE_TIME=id=com.sinognss.sm.free:id/tv_satellite_time
# 北坐标：稳定且唯一的 resource-id。
...    NORTH=id=com.sinognss.sm.free:id/tv_x
# 东坐标：稳定且唯一的 resource-id。
...    EAST=id=com.sinognss.sm.free:id/tv_y
# 高程：稳定且唯一的 resource-id。
...    HEIGHT=id=com.sinognss.sm.free:id/tv_z
# 差分延迟：稳定且唯一的 resource-id。
...    DIFFERENTIAL_DELAY=id=com.sinognss.sm.free:id/tv_diff_delayed
# PDOP：稳定且唯一的 resource-id。
...    PDOP=id=com.sinognss.sm.free:id/tv_pdop
# HDOP：稳定且唯一的 resource-id。
...    HDOP=id=com.sinognss.sm.free:id/tv_hdop
# VDOP：稳定且唯一的 resource-id。
...    VDOP=id=com.sinognss.sm.free:id/tv_vdop
# TDOP：稳定且唯一的 resource-id。
...    TDOP=id=com.sinognss.sm.free:id/tv_tdop
# GDOP：稳定且唯一的 resource-id。
...    GDOP=id=com.sinognss.sm.free:id/tv_gdop
# RMS：稳定且唯一的 resource-id。
...    RMS=id=com.sinognss.sm.free:id/tv_rms
# HRMS：稳定且唯一的 resource-id。
...    HRMS=id=com.sinognss.sm.free:id/tv_hrms
# VRMS：稳定且唯一的 resource-id。
...    VRMS=id=com.sinognss.sm.free:id/tv_vrms
# 倾斜补偿状态：稳定且唯一的 resource-id。
...    TILT_CORRECTION=id=com.sinognss.sm.free:id/tv_tilt_corrected
# 高程异常值：稳定且唯一的 resource-id。
...    HEIGHT_ANOMALY=id=com.sinognss.sm.free:id/tv_height_anomaly
