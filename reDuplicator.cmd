@echo off
chcp 65001>nul

%~d0
cd "%~dp0"

set parameter=%1
set parameter=%parameter:"=%

if exist "%parameter%" set directory=%parameter%

if "%parameter%" NEQ "/max" ( start /max "" "%~nx0" /max & exit )


call :logo
echo.^(i^) Program directory: "%cd%"
if exist "%directory%" ( echo.^(i^) Work directory: "%directory%"
) else echo.^(^!^) Directory not found: "%directory%"
echo.^(i^) Completed^!
pause>nul
exit





:logo
title [MikronT] ReDuplicator ^| %directory%
color 0b
cls
echo.
echo.
echo.    [MikronT] ==^> ReDuplicator
echo.   =============================
echo.     See other here:
echo.         github.com/MikronT
echo.
echo.
echo.
exit /b