*** Variables ***
# 坐标点库页；唯一控件使用 resource-id，无 XPath。
&{PointStore}
# 返回按钮：稳定 content-desc“返回”。
...    BACK_BUTTON=accessibility_id=返回
# 页面根容器：稳定且唯一的 resource-id。
...    ROOT=id=com.sinognss.sm.free:id/fragment_point_store
# 搜索输入框：稳定且唯一的 resource-id。
...    SEARCH_INPUT=id=com.sinognss.sm.free:id/edit_filter_name
# 点类型筛选：稳定且唯一的 resource-id。
...    POINT_TYPE_FILTER=id=com.sinognss.sm.free:id/tv_point_type
# 搜索字段筛选：稳定且唯一的 resource-id。
...    SEARCH_FIELD_FILTER=id=com.sinognss.sm.free:id/tv_string_type
# 更多按钮：稳定且唯一的 resource-id。
...    MORE_BUTTON=id=com.sinognss.sm.free:id/layout_more
# 云服务入口：稳定且唯一的 resource-id。
...    CLOUD_SERVICE=id=com.sinognss.sm.free:id/dl_cloud
# 点列表：稳定且唯一的 resource-id。
...    POINT_LIST=id=com.sinognss.sm.free:id/rv
# 点名列标题：稳定且唯一的 resource-id。
...    POINT_NAME_HEADER=id=com.sinognss.sm.free:id/point_name_txt
# 北坐标列标题：稳定且唯一的 resource-id。
...    NORTH_HEADER=id=com.sinognss.sm.free:id/x_txt
# 东坐标列标题：稳定且唯一的 resource-id。
...    EAST_HEADER=id=com.sinognss.sm.free:id/y_txt
# 导入按钮：实机没有 resource-id/content-desc，使用 Button 类名 + 精确文本。
...    IMPORT_BUTTON=android=new UiSelector().className("android.widget.Button").text("导入")
# 添加按钮：实机没有 resource-id/content-desc，使用 Button 类名 + 精确文本。
...    ADD_BUTTON=android=new UiSelector().className("android.widget.Button").text("添加")
