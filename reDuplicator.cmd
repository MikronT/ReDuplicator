@echo off
chcp 65001>nul

%~d0
cd "%~dp0"



set temp_data=temp\data
set app_name=ReDuplicator
set app_version=Pre-Alpha

set setting_debug=false
set setting_filter_include=
set setting_filter_exclude=

set settings=settings.ini

set module_rehash=modules\rehash.exe -norecur -none
set settings_import=if exist "%settings%" for /f "eol=# delims=" %%i in (%settings%) do set setting_%%i






set argument=%1
set argument=%argument:"=%

%settings_import%
if exist "%argument%" ( set directory=%argument%
) else for /f "tokens=1,* delims=- " %%i in ("%*") do if "%%i" NEQ "" set key_%%i

%directoryChecker%





if exist %temp% rd /s /q %temp%

if not exist logs md logs>nul 2>nul
md %temp%>nul 2>nul









:screen_main
set currentDate=%date%
for /f "tokens=2 delims= " %%i in ("%currentDate%") do set currentDate=%%i
for /f "tokens=1-3 delims=/." %%i in ("%currentDate%") do set currentDate=%%k.%%j.%%i



%logo%
%input_clear%

echo.^(i^) Program directory: "%cd%"
echo.^(i^) Temp directory:    "%temp%"
if exist "%directory%" ( echo.^(i^) Work directory:    "%directory%"
) else (
  color 0c
  echo.^(^!^) Directory not found: "%directory%"
  echo.^(i^) Use Drag^&Drop: drag the directory onto the %~nx0 file
  pause>nul
  exit
)
echo.
echo.
echo.^(i^) Main Menu
echo.
echo.    ^(1^) Run scan
echo.    ^(2^) Settings
echo.
echo.
echo.
set /p command= ^> 



if "%command%" == "1" call :scan
if "%command%" == "2" call :menu_settings
goto :menu_main
goto :screen_main









:scan
%logo%
set counter=0

:cycle_log_name
set /a counter+=1
set log_duplicates=logs\reDuplicator_%currentDate%_%counter%.txt
if exist "%log_duplicates%" goto :cycle_log_name



echo.^(i^) Getting directory tree...

for /f "delims=" %%i in ('dir /a:-d /b /s "%directory%\*%setting_filter_include%*"') do for /f "delims=" %%j in ("%%i") do echo.%%i;%%~zj>>%temp_data%

for /f "delims=" %%i in ("temp\data") do echo.^(i^) Directory tree data size: %%~zi bytes



echo.^(i^) Starting files comparing...
set counter=0

for /f "tokens=1,2,* delims=;" %%i in ('type %temp_data% ^| find /i /v "%setting_filter_exclude%"') do (
  set /a counter+=1
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

            if not exist "%log_duplicates%" call :initiateLog

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



echo.^(i^) Completed^!

if exist %log_duplicates% ( echo.^(i^) All info saved into the %log_duplicates% file
) else echo.^(^!^) Any duplicates not found

echo.^(i^) Files scanned: %counter%
for /f "delims=" %%i in ("%log_duplicates%") do echo.^(i^) Log file size: %%~zi bytes
pause>nul
exit /b









:screen_settings
%logo%
set buffer=
%input_clear%

%settings_import%

echo.^(i^) Settings Menu
echo.    Filters:

if "%setting_filter_include%" == "" ( echo.      ^(1^) Include: all
) else echo.      ^(1^) Include: %setting_filter_include%
if "%setting_filter_exclude%" == "" ( echo.      ^(2^) Exclude: nothing
) else echo.      ^(2^) Exclude: %setting_filter_exclude%

echo.
echo.    ^(3^) Debug: %setting_debug%
echo.
echo.    ^(0^) Go back
echo.
echo.
echo.
%input%



setlocal EnableDelayedExpansion
if "%command%" == "0" ( %input_clear% & exit /b )
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



echo.# ReDuplicator Settings #>%settings%
echo.debug=%setting_debug%>>%settings%
echo.filter_include=%setting_filter_include%>>%settings%
echo.filter_exclude=%setting_filter_exclude%>>%settings%

endlocal
goto :screen_settings









:logo
title [MikronT] %app_name% %app_version% ^| %directory%
color 0b
cls
echo.
echo.
echo.    [MikronT] ==^> %app_name%
echo.                  %app_version%
echo.   =============================
echo.     See other here:
echo.         github.com/MikronT
echo.
echo.
echo.
exit /b









:directoryChecker
if exist "%directory%" (
  echo.%directory%>%temp%\directory
  for /f "delims=" %%i in ("%temp%\directory") do if "%%~zi" == "5" set directory=%directory:\=%
)
exit /b









:initiateLog
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
exit /b