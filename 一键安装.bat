@echo off
chcp 65001 >nul
title Claude Code Setup
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
if errorlevel 1 pause
