@echo off
chcp 65001 >nul
title WinQuickArchiver - Install
echo ============================================
echo    WinQuickArchiver  -  Install
echo ============================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install.ps1"
echo.
pause
