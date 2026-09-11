*** Settings ***
Documentation    引入资源文件
Resource    ../../../resources/keywords/flows/newproject.resource
Resource    ../../../resources/keywords/common/flow_helper.resource
Resource    ../../../resources/keywords/common/teardown.resource


*** Test Cases ***
Create A New Project
    [Documentation]    用例：创建新项目
    Run And Reset    Create A New Project
