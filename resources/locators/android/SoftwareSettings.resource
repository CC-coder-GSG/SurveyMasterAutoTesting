*** Variables ***
# 软件设置页；入口和开关均有稳定 resource-id，无 XPath。
&{SoftwareSettings}
# 返回按钮：稳定 content-desc“返回”。
...    BACK_BUTTON=accessibility_id=返回
# 显示设置入口：稳定且唯一的 resource-id。
...    DISPLAY_SETTINGS=id=com.sinognss.sm.free:id/rl_display_setting
# 单位和小数位入口：稳定且唯一的 resource-id。
...    UNIT_SETTINGS=id=com.sinognss.sm.free:id/rl_unit
# 多语言入口：稳定且唯一的 resource-id。
...    LANGUAGE_SETTINGS=id=com.sinognss.sm.free:id/rl_language
# 测量放样入口：稳定且唯一的 resource-id。
...    SURVEY_STAKE_SETTINGS=id=com.sinognss.sm.free:id/rl_survey_stake
# 键盘快捷键入口：稳定且唯一的 resource-id。
...    SHORTCUT_KEY_SETTINGS=id=com.sinognss.sm.free:id/rl_shortcut_key
# 项目设置入口：稳定且唯一的 resource-id。
...    PROJECT_SETTINGS=id=com.sinognss.sm.free:id/cv_task_setting
# 屏幕方向入口：稳定且唯一的 resource-id。
...    SCREEN_ORIENTATION=id=com.sinognss.sm.free:id/rl_screen_orientation
# 界面风格入口：稳定且唯一的 resource-id。
...    UI_STYLE=id=com.sinognss.sm.free:id/rl_theme_ui_style
# 坐标顺序入口：稳定且唯一的 resource-id。
...    COORDINATE_ORDER=id=com.sinognss.sm.free:id/rl_display
# BD 模式开关：稳定且唯一的 resource-id；点击会改变设置状态。
...    BEIDOU_MODE_SWITCH=id=com.sinognss.sm.free:id/switch_beidou_demo_mode
# CAD 3.5 开关：稳定且唯一的 resource-id；点击会改变设置状态。
...    CAD_VERSION_SWITCH=id=com.sinognss.sm.free:id/switch_cad_version
# 主界面显示坐标开关：稳定且唯一的 resource-id；点击会改变设置状态。
...    MAIN_POSITION_SWITCH=id=com.sinognss.sm.free:id/switch_card_position
