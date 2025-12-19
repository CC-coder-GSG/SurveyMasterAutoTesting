*** Settings ***
Resource   ../resources/keywords/common/wait.resource
Resource   ../resources/keywords/common/assert.resource
Resource   ../resources/keywords/common/session.resource
Suite Setup     Open SurveyMaster App
Suite Teardown  Close SurveyMaster App