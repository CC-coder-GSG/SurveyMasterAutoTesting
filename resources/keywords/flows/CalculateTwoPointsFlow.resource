*** Settings ***
Resource    ../pages/Tools/ToolsPage.resource
Resource    ../pages/Tools/TwoPointsPage.resource

*** Keywords ***
Calculate Two Points
    [Documentation]    输入两点点名及坐标，并计算的流程
    Tap Tools Button
    Tap Two Points Tool Button
    Input Start Point    P1    1000    1000    10
    Input End Point      P2    2000    2000    20
    Tap Calculate Button