*** Variables ***
# 测量大师 v4.0.4.0（com.sinognss.sm.free）项目管理定位资源。
# 2026-07-15 在 Android 实机 SD30360267 上通过 Appium/UiAutomator2 核实。
# 策略优先级：resource-id > Android UiSelector；本文件未使用 XPath。
&{Project}

# ===== 通用导航 =====
# 返回按钮：无 resource-id，仅有稳定 content-desc“返回”；使用 UiAutomator 描述定位。
...    BACK_BUTTON=android=new UiSelector().description("返回")

# ===== 项目管理列表 =====
# 页面根容器：稳定 resource-id；用于判断项目管理类原生页面已加载。
...    PAGE_ROOT=id=com.sinognss.sm.free:id/root_container
# 更多按钮容器：稳定 resource-id；比内部文本“更多”更快且不受文案变化影响。
...    MORE_BUTTON=id=com.sinognss.sm.free:id/layout_more
# 搜索框容器：稳定 resource-id；用于等待搜索区域加载。
...    SEARCH_VIEW=id=com.sinognss.sm.free:id/sv_search
# 搜索项目输入框：稳定 resource-id，且是真正可输入的 AutoCompleteTextView。
...    SEARCH_SEARCHBOX=id=com.sinognss.sm.free:id/search_src_text
# 项目列表标题：稳定 resource-id；用于校验列表区域。
...    PROJECT_LIST_TITLE=id=com.sinognss.sm.free:id/tv_task_list
# 项目列表：稳定 resource-id；替代原先指向云服务遮罩层的 dl_cloud。
...    PROJECT_LIST=id=com.sinognss.sm.free:id/lv_task
# 云服务遮罩/控制区域：稳定 resource-id；仅在需要等待云层状态时使用。
...    CLOUD_LAYER=id=com.sinognss.sm.free:id/dl_cloud
# 排序字段按钮：稳定 resource-id，当前文案可为“名称”或“日期”。
...    SORT_BY_BUTTON=id=com.sinognss.sm.free:id/tv_sort_by
# 排序方向按钮：稳定 resource-id；避免按坐标点击排序箭头。
...    SORT_ORDER_BUTTON=id=com.sinognss.sm.free:id/iv_sort
# 新建项目按钮：实机无 resource-id/content-desc；使用类名 + 精确文本的 UiAutomator。
...    NEW_PROJECT_BUTTON=android=new UiSelector().className("android.widget.Button").text("新建")
# 动态项目名称：同页多个项目共享 tv_task_name，追加项目名文本约束。
...    PROJECT_NAME_BOX=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_task_name").text("\${project_name}")
# 当前项目标识：稳定 resource-id；仅当前项目行出现。
...    CURRENT_PROJECT_BADGE=id=com.sinognss.sm.free:id/tv_current_task
# 列表项坐标系：稳定 resource-id；列表中可能有多个，按需配合 instance 使用。
...    PROJECT_COORDINATE=id=com.sinognss.sm.free:id/tv_coordinate
# 列表项创建时间：稳定 resource-id；列表中可能有多个，按需配合 instance 使用。
...    PROJECT_CREATE_TIME=id=com.sinognss.sm.free:id/tv_create_time
# 列表项详情图标：稳定 resource-id；列表中可能有多个。
...    PROJECT_DETAIL_INDICATOR=id=com.sinognss.sm.free:id/tv_detail

# ===== 项目管理弹出菜单与排序菜单 =====
# “回收站”菜单：菜单项只共享 android:id/title，无独立业务 id；用 UiAutomator 叠加文本区分。
...    RECYCLE_BIN_MENU=android=new UiSelector().resourceId("android:id/title").text("回收站")
# “导入”菜单：菜单项只共享 android:id/title，无独立业务 id；用 UiAutomator 叠加文本区分。
...    IMPORT_MENU=android=new UiSelector().resourceId("android:id/title").text("导入")
# “名称”排序项：菜单项只共享 android:id/title；用 UiAutomator 叠加文本区分。
...    SORT_BY_NAME_MENU=android=new UiSelector().resourceId("android:id/title").text("名称")
# “日期”排序项：菜单项只共享 android:id/title；用 UiAutomator 叠加文本区分。
...    SORT_BY_DATE_MENU=android=new UiSelector().resourceId("android:id/title").text("日期")

# ===== 项目列表右滑操作 =====
# 侧滑行容器：稳定 resource-id；多行时按目标项目行或 instance 进一步限定。
...    SWIPE_MENU_ROW=id=com.sinognss.sm.free:id/layout_swipe_menu
# 删除动作：四个动作共享 tv_function_title，使用 resource-id + 精确文本稳定区分。
...    DELETE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_function_title").text("删除")
# 上传动作：四个动作共享 tv_function_title，使用 resource-id + 精确文本稳定区分。
...    UPLOAD=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_function_title").text("上传")
# 分享动作：四个动作共享 tv_function_title，使用 resource-id + 精确文本稳定区分。
...    SHARE=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_function_title").text("分享")
# 属性动作：四个动作共享 tv_function_title，使用 resource-id + 精确文本稳定区分。
...    ATTRIBUTES=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_function_title").text("属性")
# 兼容旧变量名拼写；新代码请使用 ATTRIBUTES。
...    ATTRUBITES=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_function_title").text("属性")
# 打开项目：项目行没有单独“打开”按钮，点击动态项目名称即可进入；替代旧的错误 instance(3)。
...    OPEN=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_task_name").text("\${project_name}")

# ===== 创建项目 =====
# 项目名称标签：稳定 resource-id；用于校验创建项目表单。
...    PROJECT_NAME_LABEL=id=com.sinognss.sm.free:id/name_lbl
# 项目名称输入框：稳定 resource-id。
...    PROJECT_NAME_INPUT_BOX=id=com.sinognss.sm.free:id/name_txt
# 创建者标签：稳定 resource-id。
...    PROJECT_CREATOR_LABEL=id=com.sinognss.sm.free:id/operator_lbl
# 项目创建者输入框：稳定 resource-id。
...    PROJECT_CREATOR_INPUT_BOX=id=com.sinognss.sm.free:id/operator_txt
# 备注标签：稳定 resource-id。
...    PROJECT_REMARK_LABEL=id=com.sinognss.sm.free:id/desc_lbl
# 项目备注输入框：稳定 resource-id。
...    PROJECT_REMARK_INPUT_BOX=id=com.sinognss.sm.free:id/description_txt
# 复用项目说明：稳定 resource-id。
...    REUSE_PROJECT_LABEL=id=com.sinognss.sm.free:id/tv_apply_task
# 复用项目开关：稳定 resource-id。
...    REUSE_PROJECT_SWITCH=id=com.sinognss.sm.free:id/switch_apply_task
# 坐标系选择框：稳定 resource-id；点击进入常用坐标系列表。
...    COORDINATE_SELECTOR=id=com.sinognss.sm.free:id/ft_coordinate
# 代码模板选择框：稳定 resource-id；点击进入代码模板列表。
...    CODE_TEMPLATE_SELECTOR=id=com.sinognss.sm.free:id/ft_code_template
# 投影摘要：稳定 resource-id。
...    PROJECTION_SUMMARY=id=com.sinognss.sm.free:id/tv_projection
# 中央子午线摘要：稳定 resource-id。
...    CENTRAL_MERIDIAN_SUMMARY=id=com.sinognss.sm.free:id/tv_central_meridian
# 中央子午线提示：稳定 resource-id；未连接设备时显示原因。
...    CENTRAL_MERIDIAN_HINT=id=com.sinognss.sm.free:id/tv_central_meridian_hint
# 创建确认按钮：实机无 resource-id/content-desc；使用类名 + 精确文本的 UiAutomator。
...    PROJECT_CREATE_CONFIRM_BUTTON=android=new UiSelector().className("android.widget.Button").text("确认")

# ===== 创建项目 - 常用坐标系 =====
# 常用坐标系列表：稳定 resource-id。
...    COORDINATE_LIST=id=com.sinognss.sm.free:id/lv_user_coordinate
# 动态坐标系名称：列表项文本使用稳定 text id，追加名称约束。
...    COORDINATE_BY_NAME=android=new UiSelector().resourceId("com.sinognss.sm.free:id/text").text("\${coordinate_name}")
# 坐标系确认按钮：稳定 resource-id。
...    COORDINATE_CONFIRM_BUTTON=id=com.sinognss.sm.free:id/btn_confirm

# ===== 创建项目 - 代码模板 =====
# 代码模板列表：稳定 resource-id。
...    CODE_TEMPLATE_LIST=id=com.sinognss.sm.free:id/lv_code_set
# 动态代码模板名称：稳定 resource-id + 模板名文本。
...    CODE_TEMPLATE_BY_NAME=android=new UiSelector().resourceId("com.sinognss.sm.free:id/tv_code_name").text("\${template_name}")
# 模板更新时间：稳定 resource-id。
...    CODE_TEMPLATE_TIME=id=com.sinognss.sm.free:id/tv_code_time
# 模板单选按钮：稳定 resource-id；多模板时应先按模板名称确定目标行。
...    CODE_TEMPLATE_RADIO=id=com.sinognss.sm.free:id/rb_select_code
# 添加模板按钮：实机无 resource-id/content-desc；使用类名 + 精确文本的 UiAutomator。
...    CODE_TEMPLATE_ADD_BUTTON=android=new UiSelector().className("android.widget.Button").text("添加")
# 代码模板确认按钮：实机无 resource-id/content-desc；使用类名 + 精确文本的 UiAutomator。
...    CODE_TEMPLATE_CONFIRM_BUTTON=android=new UiSelector().className("android.widget.Button").text("确定")

# ===== 回收站 =====
# 回收站更多按钮复用 layout_more 的稳定 resource-id。
...    RECYCLE_BIN_MORE_BUTTON=id=com.sinognss.sm.free:id/layout_more
# 清空菜单仅有通用 android:id/title；使用 UiAutomator 叠加精确文本，避免位置型定位。
...    RECYCLE_BIN_CLEAR_MENU=android=new UiSelector().resourceId("android:id/title").text("清空")

# ===== 导入项目文件选择器 =====
# 文件选择分页容器：稳定 resource-id。
...    IMPORT_VIEW_PAGER=id=com.sinognss.sm.free:id/view_pager_file_exporter
# 外部/内部存储列表：稳定 resource-id。
...    IMPORT_STORAGE_LIST=id=com.sinognss.sm.free:id/cv_external_storage
# 存储名称：稳定 resource-id，当前实机文本为“内部存储”。
...    IMPORT_STORAGE_TITLE=id=com.sinognss.sm.free:id/tv_title
# 自定义文件入口：稳定 resource-id。
...    IMPORT_CUSTOM_FILE_BUTTON=id=com.sinognss.sm.free:id/custom_file
# 文件路径面包屑列表：稳定 resource-id。
...    IMPORT_PATH_LIST=id=com.sinognss.sm.free:id/rv_file_path
# 父目录行：稳定 resource-id。
...    IMPORT_PARENT_DIRECTORY=id=com.sinognss.sm.free:id/rl_item
# 动态文件/目录名称：稳定 name id，追加名称文本约束。
...    IMPORT_FILE_BY_NAME=android=new UiSelector().resourceId("com.sinognss.sm.free:id/name").text("\${file_name}")
# 空文件提示：稳定 resource-id。
...    IMPORT_EMPTY_MESSAGE=id=com.sinognss.sm.free:id/tv_empty_message
# 文件类型：稳定 resource-id。
...    IMPORT_FILE_TYPE=id=com.sinognss.sm.free:id/tv_file_type
# 导入确认按钮：稳定 resource-id。
...    IMPORT_CONFIRM_BUTTON=id=com.sinognss.sm.free:id/btn_confirm

# ===== 项目详情 =====
# 项目名称值：稳定 resource-id。
...    DETAIL_PROJECT_NAME=id=com.sinognss.sm.free:id/tv_task_name
# 项目路径值：稳定 resource-id。
...    DETAIL_PROJECT_PATH=id=com.sinognss.sm.free:id/tv_task_path
# 代码集值：稳定 resource-id。
...    DETAIL_CODE_SET=id=com.sinognss.sm.free:id/tv_code_set
# 创建时间值：稳定 resource-id。
...    DETAIL_CREATE_TIME=id=com.sinognss.sm.free:id/tv_create_time
# 创建者值：稳定 resource-id。
...    DETAIL_OPERATOR=id=com.sinognss.sm.free:id/tv_operator
# 备注值：稳定 resource-id。
...    DETAIL_DESCRIPTION=id=com.sinognss.sm.free:id/tv_description
# 坐标系统值：稳定 resource-id。
...    DETAIL_COORDINATE_SYSTEM=id=com.sinognss.sm.free:id/tv_coordinate_system
# 坐标系分享码入口：稳定 resource-id。
...    DETAIL_COORDINATE_SHARE_CODE=id=com.sinognss.sm.free:id/iv_coordinate_share_code
# 坐标系二维码入口：稳定 resource-id。
...    DETAIL_COORDINATE_QR=id=com.sinognss.sm.free:id/iv_coordinate_qr
# 椭球名称：稳定 resource-id。
...    DETAIL_ELLIPSOID=id=com.sinognss.sm.free:id/tv_ellipsoid
# 长半轴：稳定 resource-id。
...    DETAIL_SEMI_MAJOR_AXIS=id=com.sinognss.sm.free:id/tv_semi_major_axis
# 扁率：稳定 resource-id。
...    DETAIL_FLATTENING=id=com.sinognss.sm.free:id/tv_flattening
# 投影名称：稳定 resource-id。
...    DETAIL_PROJECTION_NAME=id=com.sinognss.sm.free:id/tv_projection_name
# 修改项目属性按钮：稳定 resource-id。
...    MODIFY_PROJECT_BUTTON=id=com.sinognss.sm.free:id/btn_modify

# ===== 修改项目属性/当前项目坐标系 =====
# 常用坐标系入口：稳定 resource-id。
...    MODIFY_COORDINATE_STORE=id=com.sinognss.sm.free:id/tv_coordinate_store
# 坐标系统名称：稳定 resource-id；系统预置坐标系下可能不可编辑。
...    MODIFY_COORDINATE_NAME=id=com.sinognss.sm.free:id/coordinate_name_text
# 源椭球区域：稳定 resource-id；部分坐标系下可能 disabled。
...    MODIFY_SOURCE_ELLIPSOID=id=com.sinognss.sm.free:id/rl_source_ellipsoid
# 目标椭球区域：稳定 resource-id。
...    MODIFY_TARGET_ELLIPSOID=id=com.sinognss.sm.free:id/rl_ellipsoid
# 投影区域：稳定 resource-id。
...    MODIFY_PROJECTION=id=com.sinognss.sm.free:id/rl_projection
# 七参数/三参数区域：稳定 resource-id。
...    MODIFY_SEVEN_PARAM=id=com.sinognss.sm.free:id/rl_seven_param
# 平面校正区域：稳定 resource-id。
...    MODIFY_PLANE_CORRECTION=id=com.sinognss.sm.free:id/rl_plane_correction
# 高程拟合区域：稳定 resource-id。
...    MODIFY_ELEVATION_FITTING=id=com.sinognss.sm.free:id/rl_elevation_fitting
# 大地水准面模型区域：稳定 resource-id。
...    MODIFY_EGM=id=com.sinognss.sm.free:id/rl_egm
# 平面格网模型区域：稳定 resource-id。
...    MODIFY_GRID=id=com.sinognss.sm.free:id/rl_grid
# 平移参数区域：稳定 resource-id。
...    MODIFY_SHIFT_PARAM=id=com.sinognss.sm.free:id/rl_shift_para
# 修改属性确认按钮：实机无 resource-id/content-desc；使用类名 + 精确文本的 UiAutomator。
...    MODIFY_CONFIRM_BUTTON=android=new UiSelector().className("android.widget.Button").text("确认")
