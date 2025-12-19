*** Settings ***
Resource    ../pages/GuideActivity.resource
Resource    ../pages/Project.resource

*** Keywords ***
Create A New Project
    ProjectManagement Button Click
    Tap More Button
