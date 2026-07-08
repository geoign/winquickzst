@echo off
chcp 65001 >nul
title WinQuickArchiver - Uninstall
echo ============================================
echo    WinQuickArchiver  -  Uninstall
echo ============================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Uninstall.ps1"
echo.
pause
