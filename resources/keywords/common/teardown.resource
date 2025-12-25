*** Settings ***
# 这里导入“强制回主页/引导页”的关键字所在 resource
Resource    flow_helper.resource

*** Keywords ***
Global Test Teardown
    # 失败才截图（这个关键字应该只在 Test Teardown 用） :contentReference[oaicite:2]{index=2}
    Run Keyword If Test Failed    Run Keyword And Ignore Error    Capture Page Screenshot
    # 无论成功失败都尽量复位；复位失败也别影响收尾
    Run Keyword And Ignore Error    Force Jump To Guide Page
