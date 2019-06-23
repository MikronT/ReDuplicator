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
set temp_data=temp\data

set setting_debug=false
set setting_filter_include=
set setting_filter_exclude=
set settings=settings.ini



if exist "%settings%" for /f "eol=# delims=" %%i in (%settings%) do set setting_%%i

set currentDate=%date%
for /f "tokens=2 delims= " %%i in ("%currentDate%") do set currentDate=%%i
for /f "tokens=1-3 delims=/." %%i in ("%currentDate%") do set currentDate=%%k.%%j.%%i

set log_duplicates=logs\reDuplicator_%currentDate%.txt

if not exist logs md logs>nul 2>nul
md temp>nul 2>nul



goto :menu_main
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







:menu_main
call :logo
set command=

echo.^(i^) Program directory: "%cd%"
if exist "%directory%" ( echo.^(i^) Work directory:    "%directory%"
) else (
  color 0c
  echo.^(^!^) Directory not found: "%directory%"
  pause>nul
  exit
)
echo.
echo.^(i^) Main Menu
echo.    ^(1^) Run scan
echo.    ^(2^) Settings
echo.
echo.
echo.
set /p command= ^> 



if "%command%" == "1" call :duplicatesScan
if "%command%" == "2" call :menu_settings
goto :menu_main







:duplicatesScan
if exist %log_duplicates% for /l %%i in (10,-1,1) do echo.>>%log_duplicates%
echo.=============================================================================>>%log_duplicates%
echo.ReDuplicator Log File ^| %currentDate%>>%log_duplicates%
echo.>>%log_duplicates%
echo.>>%log_duplicates%
if "%setting_debug%" == "true" (
  echo.Variables:>>%log_duplicates%
  echo.  debug=%setting_debug%>>%log_duplicates%
  echo.  filter_include=%setting_filter_include%>>%log_duplicates%
  echo.  filter_exclude=%setting_filter_exclude%>>%log_duplicates%
  echo.  log_duplicates=%log_duplicates%>>%log_duplicates%
  echo.>>%log_duplicates%
  echo.>>%log_duplicates%
)
echo.>>%log_duplicates%



for /f "delims=" %%i in ('dir /a:-d /b /s "%directory%\*%setting_filter_include%*"') do for /f "delims=" %%j in ("%%i") do echo.%%i;%%~zj>>%temp_data%



for /f "tokens=1,2,* delims=;" %%i in ('type %temp_data% ^| find /i /v "%setting_filter_exclude%"') do (
  for /f "tokens=1,2,* delims=;" %%o in ('type %temp_data% ^| find /i /v "%setting_filter_exclude%"') do (
    if "%%i" NEQ "%%o" if "%%j" == "%%p" (
      for /f "skip=1 tokens=2* delims=:" %%k in ('%module_rehash% -sha1 "%%i"') do (
        for /f "skip=1 tokens=2* delims=:" %%q in ('%module_rehash% -sha1 "%%o"') do (
          if "%%k" == "%%q" (
            echo.^(i^) Duplicates:
            if "%setting_debug%" == "false" (
              echo.    %%i
              echo.    %%o
            ) else (
              echo.    %%i
              echo.        size: %%j bytes
              echo.        sha1:%%k
              echo.    %%o
              echo.        size: %%p bytes
              echo.        sha1:%%q
              echo.
            )
            echo.
            echo.

            echo.Duplicates:>>%log_duplicates%
            if "%setting_debug%" == "false" (
              echo.    %%i>>%log_duplicates%
              echo.    %%o>>%log_duplicates%
            ) else (
              echo.    %%i
              echo.        size: %%j bytes
              echo.        sha1:%%k
              echo.    %%o
              echo.        size: %%p bytes
              echo.        sha1:%%q
              echo.
            )>>%log_duplicates%
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







:menu_settings
call :logo
set buffer=
set command=

call :settings_import

echo.^(i^) Settings Menu
echo.    Filters:
echo.      ^(1^) Include: %setting_filter_include%
echo.      ^(2^) Exclude: %setting_filter_exclude%
echo.
echo.    ^(3^) Debug: %setting_debug%
echo.
echo.    ^(0^) Go back
echo.
echo.
echo.
set /p command= ^> 



setlocal EnableDelayedExpansion
if "%command%" == "0" ( set command= & exit /b )
if "%command%" == "1" (
  set /p buffer=^(^>^) Enter Include filter ^> 
  if "!buffer!" == "" ( set setting_filter_include=
  ) else set setting_filter_include=!buffer!
)
if "%command%" == "2" (
  set /p buffer=^(^>^) Enter Exclude filter ^> 
  if "!buffer!" == "" ( set setting_filter_exclude=
  ) else set setting_filter_exclude=!buffer!
)
if "%command%" == "3" if "%setting_debug%" == "true" ( set setting_debug=false
) else set setting_debug=true

call :settings_save
endlocal
goto :menu_settings





:settings_import
if exist "%settings%" for /f "eol=# delims=" %%i in (%settings%) do set setting_%%i
exit /b





:settings_save
echo.# ReDuplicator Settings #>%settings%
echo.debug=%setting_debug%>>%settings%
echo.filter_include=%setting_filter_include%>>%settings%
echo.filter_exclude=%setting_filter_exclude%>>%settings%
exit /b