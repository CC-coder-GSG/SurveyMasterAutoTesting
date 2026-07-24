*** Variables ***
# 司南万象/移动站/基准站启动状态弹窗；控件使用稳定 resource-id，无 XPath。
&{StationModePopup}
# 弹窗根面板：稳定且唯一的 resource-id。
...    PANEL=id=com.sinognss.sm.free:id/parentPanel
# 当前接收机序列号：稳定且唯一的 resource-id。
...    RECEIVER_SERIAL=id=com.sinognss.sm.free:id/tv_sn
# 启动步骤文本集合：重复 resource-id，用于读取全部状态。
...    STEP_TEXTS=id=com.sinognss.sm.free:id/tv_content
# 进度条：稳定且唯一的 resource-id，仅执行中出现。
...    PROGRESS=id=com.sinognss.sm.free:id/progress_bar_doing
# 启动结果：稳定且唯一的 resource-id，完成后出现。
...    RESULT=id=com.sinognss.sm.free:id/tv_result
# 自动关闭倒计时：稳定且唯一的 resource-id，完成后出现。
...    COUNTDOWN=id=com.sinognss.sm.free:id/tv_count
# 取消按钮：稳定且唯一的 resource-id。
...    CANCEL_BUTTON=id=com.sinognss.sm.free:id/btn_negative
# 确认按钮：稳定且唯一的 resource-id。
...    CONFIRM_BUTTON=id=com.sinognss.sm.free:id/btn_positive
