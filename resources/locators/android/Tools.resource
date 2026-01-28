*** Variables ***
# 工具页面定位资源
&{Tools}
# 页面底端工具按钮
...    TOOLS_PAGES_BUTTON=android=new UiSelector().resourceId("com.sinognss.sm.free:id/fixed_bottom_navigation_container").instance(3)


# 两点计算工具按钮
...    TWO_POINTS_TOOL_BUTTON=android=new UiSelector().className("android.view.ViewGroup").instance(8)