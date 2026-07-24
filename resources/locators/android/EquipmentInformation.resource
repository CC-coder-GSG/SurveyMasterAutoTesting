*** Variables ***
# 设备信息及其五个 Tab；优先使用 accessibility id/resource-id。
&{EquipmentInformation}
# 返回按钮：稳定 content-desc“返回”。
...    BACK_BUTTON=accessibility_id=返回
# 设备信息 Tab：无 resource-id，具有稳定 content-desc，使用 accessibility id。
...    DEVICE_INFO_TAB=accessibility_id=设备信息
# 定位 Tab：无 resource-id，具有稳定 content-desc，使用 accessibility id。
...    POSITION_TAB=accessibility_id=定位
# 星空图 Tab：无 resource-id，具有稳定 content-desc，使用 accessibility id。
...    SKY_PLOT_TAB=accessibility_id=星空图
# 星表 Tab：无 resource-id，具有稳定 content-desc，使用 accessibility id。
...    SATELLITE_TABLE_TAB=accessibility_id=星表
# 电离层/基站 Tab：未激活时 content-desc 为“电离层”。
...    IONOSPHERE_TAB=accessibility_id=电离层
# 电离层/基站 Tab：激活后的实机 content-desc 会变为“基站”。
...    BASE_TAB_ACTIVE=accessibility_id=基站
# 设备信息列表：稳定且唯一的 resource-id。
...    DEVICE_INFO_LIST=id=com.sinognss.sm.free:id/rv_device_info
# 所有设备属性名称集合：重复 resource-id，适合读取列表而非点击单行。
...    DEVICE_PROPERTY_NAMES=id=com.sinognss.sm.free:id/tv_name
# 所有设备属性值集合：重复 resource-id，适合读取列表而非点击单行。
...    DEVICE_PROPERTY_VALUES=id=com.sinognss.sm.free:id/tv_value
# 设备名称值：tv_value 在列表中重复且值动态变化，无 id/content-desc 可区分；只能按稳定行名寻找相邻值，故使用 XPath。
...    DEVICE_NAME_VALUE=xpath=//*[@resource-id="com.sinognss.sm.free:id/tv_name" and @text="设备名称"]/following-sibling::*[@resource-id="com.sinognss.sm.free:id/tv_value"]
# 序列号值：tv_value 在列表中重复且值动态变化，无 id/content-desc 可区分；只能按稳定行名寻找相邻值，故使用 XPath。
...    SERIAL_NUMBER_VALUE=xpath=//*[@resource-id="com.sinognss.sm.free:id/tv_name" and @text="序列号(SN)"]/following-sibling::*[@resource-id="com.sinognss.sm.free:id/tv_value"]
# 版本信息值：tv_value 在列表中重复且值动态变化，无 id/content-desc 可区分；只能按稳定行名寻找相邻值，故使用 XPath。
...    FIRMWARE_VERSION_VALUE=xpath=//*[@resource-id="com.sinognss.sm.free:id/tv_name" and @text="版本信息"]/following-sibling::*[@resource-id="com.sinognss.sm.free:id/tv_value"]
# 星空图画布：稳定且唯一的 resource-id。
...    SKY_PLOT=id=com.sinognss.sm.free:id/skyview
# GPS 星座开关：稳定且唯一的 resource-id。
...    GPS_CHECKBOX=id=com.sinognss.sm.free:id/cb_gps
# BDS 星座开关：稳定且唯一的 resource-id。
...    BDS_CHECKBOX=id=com.sinognss.sm.free:id/cb_bds
# GLONASS 星座开关：稳定且唯一的 resource-id。
...    GLONASS_CHECKBOX=id=com.sinognss.sm.free:id/cb_glonass
# GALILEO 星座开关：稳定且唯一的 resource-id。
...    GALILEO_CHECKBOX=id=com.sinognss.sm.free:id/cb_gal
# 星空图状态：稳定且唯一的 resource-id。
...    SKY_STATUS=id=com.sinognss.sm.free:id/tv_status
# 星空图卫星数：稳定且唯一的 resource-id。
...    SKY_SATELLITE_COUNT=id=com.sinognss.sm.free:id/tv_satellite_num
# 星空图 PDOP：稳定且唯一的 resource-id。
...    SKY_PDOP=id=com.sinognss.sm.free:id/tv_pdop
# 星表系统下拉框：稳定且唯一的 resource-id。
...    SATELLITE_SYSTEM_SPINNER=id=com.sinognss.sm.free:id/spinner_satellite_system
# 星表列表：稳定且唯一的 resource-id。
...    SATELLITE_LIST=id=com.sinognss.sm.free:id/lv_satellite_list
# 导航基站按钮：稳定且唯一的 resource-id。
...    NAVIGATE_TO_BASE=id=com.sinognss.sm.free:id/btn_nav_to_base
# 兼容旧关键字：进入重启界面；当前可见层级未暴露语义 id，保留原实例定位供已有用例使用。
...    Restart=android=new UiSelector().className("android.view.ViewGroup").instance(8)
# 兼容旧关键字：深度重启按钮，稳定且唯一的 resource-id。
...    Deep_Restart=id=com.sinognss.sm.free:id/btn_freset
# 兼容旧关键字：设备信息滑动列表，稳定且唯一的 resource-id。
...    Swipe_Container=id=com.sinognss.sm.free:id/rv_device_info
