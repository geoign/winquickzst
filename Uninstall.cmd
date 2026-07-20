@echo off
chcp 65001 >nul
title WinQuickZst - Uninstall
echo ============================================
echo    WinQuickZst  -  Uninstall
echo ============================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Uninstall.ps1"
echo.
pause