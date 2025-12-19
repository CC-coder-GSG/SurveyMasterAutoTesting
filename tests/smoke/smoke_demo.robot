*** Settings ***
Resource    ../../resources/keywords/flows/auth.resource

*** Test Cases ***
Smoke Demo Login Flow
    Login As User    test01    123456
