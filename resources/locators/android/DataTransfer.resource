*** Variables ***
# 数据导入/导出格式选择页共用定位器；共享项通过 resource-id + 精确文本区分，无 XPath。
&{DataTransfer}
# 返回按钮：稳定 content-desc“返回”。
...    BACK_BUTTON=accessibility_id=返回
# 格式列表：稳定且唯一的 resource-id。
...    FORMAT_LIST=id=com.sinognss.sm.free:id/rv_file_format
# 添加自定义格式入口：稳定且唯一的 resource-id。
...    ADD_FORMAT=id=com.sinognss.sm.free:id/layout_add_format
# CASS 格式：格式项共享 item_txt，使用 resource-id + 精确文本区分。
...    CASS_FORMAT=android=new UiSelector().resourceId("com.sinognss.sm.free:id/item_txt").text("CASS(*.dat)")
# N/E/Z CSV 格式：格式项共享 item_txt，使用 resource-id + 精确文本区分。
...    NEZ_CSV_FORMAT=android=new UiSelector().resourceId("com.sinognss.sm.free:id/item_txt").text("名称,N,E,Z(*.csv)")
# 名称/代码/N/E/Z 格式：格式项共享 item_txt，使用 resource-id + 精确文本区分。
...    CODE_NEZ_FORMAT=android=new UiSelector().resourceId("com.sinognss.sm.free:id/item_txt").text("名称,代码,N,E,Z(*.txt*.csv*.xls*.xlsx)")
# DWG 2007 格式：仅导出页存在，使用共享 resource-id + 精确文本区分。
...    DWG_2007_FORMAT=android=new UiSelector().resourceId("com.sinognss.sm.free:id/item_txt").text("DWG文件(2007)(*.dwg)")
# DXF 2007 格式：仅导出页存在，使用共享 resource-id + 精确文本区分。
...    DXF_2007_FORMAT=android=new UiSelector().resourceId("com.sinognss.sm.free:id/item_txt").text("DXF文件(2007)(*.dxf)")
# PDF 预览图格式：仅导出页存在，使用共享 resource-id + 精确文本区分。
...    PREVIEW_MAP_PDF=android=new UiSelector().resourceId("com.sinognss.sm.free:id/item_txt").text("PreviewMap(*.pdf)")
# 下一步按钮：实机没有 resource-id/content-desc，使用 Button 类名 + 精确文本。
...    NEXT_BUTTON=android=new UiSelector().className("android.widget.Button").text("下一步")
