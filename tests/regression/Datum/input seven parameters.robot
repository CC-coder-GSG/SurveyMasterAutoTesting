*** Settings ***
Resource    ../resources/keywords/flows/input seven parameters.resource
Resource    ../resources/keywords/common/flow_helper.resource
Resource    ../resources/keywords/common/teardown.resource

*** Test Cases ***
Input Seven Parameters
    Run And Reset    Input Seven Parameters