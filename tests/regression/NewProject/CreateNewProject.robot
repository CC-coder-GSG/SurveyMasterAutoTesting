*** Settings ***
Resource    ../../../resources/keywords/flows/newproject.resource
Resource    ../../../resources/keywords/common/flow_helper.resource
Resource    ../../../resources/keywords/common/teardown.resource

*** Test Cases ***
Create A New Project
    Run And Reset    Create A New Project