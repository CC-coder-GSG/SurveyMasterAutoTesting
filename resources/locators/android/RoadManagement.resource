*** Variables ***
# 道路管理页；列表和云服务使用唯一 resource-id，按钮无 id 时使用类名 + 精确文本，无 XPath。
&{RoadManagement}
# 返回按钮：稳定 content-desc“返回”。
...    BACK_BUTTON=accessibility_id=返回
# 道路文件列表：稳定且唯一的 resource-id。
...    ROAD_LIST=id=com.sinognss.sm.free:id/lv_file
# 云服务入口：稳定且唯一的 resource-id。
...    CLOUD_SERVICE=id=com.sinognss.sm.free:id/dl_cloud
# 导入按钮：实机没有 resource-id/content-desc，使用 Button 类名 + 精确文本。
...    IMPORT_BUTTON=android=new UiSelector().className("android.widget.Button").text("导入")
# 新建按钮：实机没有 resource-id/content-desc，使用 Button 类名 + 精确文本。
...    CREATE_BUTTON=android=new UiSelector().className("android.widget.Button").text("新建")
