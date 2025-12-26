*** Settings ***
Resource    ../pages/GuideActivity.resource
Resource    ../pages/Project.resource

*** Keywords ***
# 创建一个新项目并删除
Create A New Project
    ProjectManagement Button Click
    Tap New Project
    Enter Project Name    project_name=AutoTestingProject
    Tap Project Create Confirm Button
    ProjectManagement Button Click
    Wait Project List
    Scroll To And Tap Text Contains    text=AutoTestingProject
    Tap Delete Project Button
    Tap Confirm Popup Confirm Button

