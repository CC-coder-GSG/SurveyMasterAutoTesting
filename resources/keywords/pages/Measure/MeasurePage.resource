*** Settings ***
Resource    ../../../locators/android/Measure.resource
Resource    ../../common/actions.resource

*** Keywords ***
 Tap Measure Button
     [Documentation]    点击页面底部的"测量"按钮，进入测量页面
     Tap    ${Measure.MEASURE_PAGES_BUTTON}