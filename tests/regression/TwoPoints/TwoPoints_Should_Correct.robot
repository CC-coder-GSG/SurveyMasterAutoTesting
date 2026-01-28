*** Settings ***
Resource    ../../../resources/keywords/flows/CalculateTwoPointsFlow.resource
Resource    ../../../resources/keywords/common/flow_helper.resource
Resource    ../../../resources/keywords/common/teardown.resource

*** Test Cases ***
TwoPoints_Should_Correct
    Run And Reset    Calculate Two Points