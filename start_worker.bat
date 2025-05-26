@echo off
cd %~dp0
set RAILS_ENV=production
start cmd /min /c "ruby bin\delayed_job run"
