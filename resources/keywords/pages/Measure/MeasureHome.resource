*** Settings ***
Documentation    测量主页只读校验；只检查入口，不启动测量业务。
Resource    ../../../locators/android/Measure.resource
Resource    ../../common/assert.resource
Resource    ../../common/wait.resource

*** Keywords ***
Measure Home Should Be Ready
    [Documentation]    等待测量主页加载，并校验点测量和点放样入口。
    Wait Visible    ${Measure.POINT_SURVEY}
    Should Be Visible    ${Measure.POINT_STAKE}
