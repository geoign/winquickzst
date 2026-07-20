@echo off
chcp 65001 >nul
title WinQuickZst - Install
echo ============================================
echo    WinQuickZst  -  Install
echo ============================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install.ps1"
echo.
pause