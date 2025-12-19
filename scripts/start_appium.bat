@echo off
REM Appium 2 常用；如果需要 /wd/hub，就把 env_local.yaml 的 APPIUM_SERVER 改成带 /wd/hub
appium --port 4723 --log-level info
