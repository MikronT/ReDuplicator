@echo off
chcp 65001>nul

%~d0
cd "%~dp0"

set parameter=%1
set parameter=%parameter:"=%

if exist "%parameter%" set directory=%parameter%

if exist temp rd /s /q temp

if "%parameter%" NEQ "/max" ( start /max "" "%~nx0" /max & exit )



set module_rehash=modules\rehash.exe -norecur -none
set settings=settings.ini
set temp_data=temp\data

set setting_filter_fileType_include=
rem set setting_filter_fileType_include=\*.jar
set setting_filter_fileType_exclude=
rem set setting_filter_fileType_exclude=.json

set currentDate=%date%
for /f "tokens=2 delims= " %%i in ("%currentDate%") do set currentDate=%%i
for /f "tokens=1-3 delims=/." %%i in ("%currentDate%") do set currentDate=%%k.%%j.%%i

set log_duplicates=logs\reDuplicator_%currentDate%.txt

if not exist logs md logs
md temp





call :logo
echo.^(i^) Program directory: "%cd%"
if exist "%directory%" ( echo.^(i^) Work directory: "%directory%"
) else echo.^(^!^) Directory not found: "%directory%"
echo.
echo.
echo.
timeout /nobreak /t 1 >nul



if exist %log_duplicates% for /l %%i in (10,-1,1) do echo.>>%log_duplicates%
echo.=============================================================================>>%log_duplicates%
echo.ReDuplicator Log File ^| %currentDate%>>%log_duplicates%
echo.>>%log_duplicates%
echo.Variables:>>%log_duplicates%
echo.  setting_filter_fileType_include=%setting_filter_fileType_include%>>%log_duplicates%
echo.  setting_filter_fileType_exclude=%setting_filter_fileType_exclude%>>%log_duplicates%
echo.  log_duplicates=%log_duplicates%>>%log_duplicates%
echo.>>%log_duplicates%
echo.>>%log_duplicates%
echo.>>%log_duplicates%



for /f "delims=" %%i in ('dir /a:-d /b /s "%directory%\*%setting_filter_fileType_include%"') do for /f "delims=" %%j in ("%%i") do echo.%%i;%%~zj>>%temp_data%



for /f "tokens=1,2,* delims=;" %%i in ('type %temp_data% ^| find /i /v "%setting_filter_fileType_exclude%"') do (
  for /f "tokens=1,2,* delims=;" %%o in ('type %temp_data% ^| find /i /v "%setting_filter_fileType_exclude%"') do (
    if "%%i" NEQ "%%o" if "%%j" == "%%p" (
      for /f "skip=1 tokens=2* delims=:" %%k in ('%module_rehash% -sha1 "%%i"') do (
        for /f "skip=1 tokens=2* delims=:" %%q in ('%module_rehash% -sha1 "%%o"') do (
          if "%%k" == "%%q" (
            echo.^(i^) Duplicates:
            echo.    %%i
            echo.        size: %%j bytes
            echo.        sha1:%%k
            echo.    %%o
            echo.        size: %%p bytes
            echo.        sha1:%%q
            echo.
            echo.
            echo.

            echo.Duplicates:>>%log_duplicates%
            echo.    %%i>>%log_duplicates%
            echo.        size: %%j bytes>>%log_duplicates%
            echo.        sha1:%%k>>%log_duplicates%
            echo.    %%o>>%log_duplicates%
            echo.        size: %%p bytes>>%log_duplicates%
            echo.        sha1:%%q>>%log_duplicates%
            echo.>>%log_duplicates%
            echo.>>%log_duplicates%
            echo.>>%log_duplicates%
          )
        )
      )
    )
  )
)



echo.=============================================================================>>%log_duplicates%



echo.^(i^) Completed^!
if exist %log_duplicates% ( echo.^(i^) All info saved into the %log_duplicates% file
) else echo.^(i^) Any duplicates not found
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