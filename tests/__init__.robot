*** Settings ***
Resource   ../resources/keywords/common/wait.resource
Resource   ../resources/keywords/common/assert.resource
Resource   ../resources/keywords/common/session.resource
Resource   ../resources/keywords/common/teardown.resource

Suite Setup     Open App And Handle Permissions
Suite Teardown  Close SurveyMaster App
Test Teardown   Global Test Teardown