@echo off
rem Wrapper so the preview tool's spawned process can find node/npm on PATH.
set "PATH=C:\Program Files\nodejs;%APPDATA%\npm;%PATH%"
npm --prefix "%~dp0..\frontend" start
