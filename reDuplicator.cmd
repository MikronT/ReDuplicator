@echo off
chcp 65001>nul

%~d0
cd "%~dp0"



set app_name=ReDuplicator
set app_version=Pre-Alpha

set setting_debug=false
set setting_filter_include=
set setting_filter_exclude=
set setting_multithreading=false
set setting_multithreading_threads=2

set settings=settings.ini

set module_rehash=modules\rehash.exe -norecur -none

set input=set /p command= ^^^> 
set input_clear=set command=
set logo=call :logo
set settings_import=if exist "%settings%" for /f "eol=# delims=" %%i in (%settings%) do set setting_%%i



%settings_import%



set argument=%1
set argument=%argument:"=%

if exist "%argument%" ( set directory=%argument%
) else for /f "tokens=1,2,* delims=- " %%i in ("%*") do (
  if "%%i" NEQ "" set key_%%i
  if "%%j" NEQ "" set key_%%j
)

call :directoryChecker

if "%key_call%" NEQ "" call :%key_call% %key_thread%

if exist temp rd /s /q temp









:screen_main
:cycle_sessionSet
set session=%random%%random%
set temp=temp\session-%session%
if exist "%temp%" goto :cycle_sessionSet

if not exist logs md logs
if not exist %temp% md %temp%



set currentDate=%date%
for /f "tokens=2 delims= " %%i in ("%currentDate%") do set currentDate=%%i
for /f "tokens=1-3 delims=/." %%i in ("%currentDate%") do set currentDate=%%k.%%j.%%i



%logo%
%input_clear%

echo.^(i^) Session: %session%
echo.
echo.^(i^) Program directory: "%cd%"
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
%input%



if "%command%" == "1" (
  start "" "%~dpnx0" --call=scan_preparing
  call :screen_scan
)
if "%command%" == "2" call :screen_settings
goto :screen_main









:screen_scan
%logo%

set counter_duplicates=0
for /l %%i in (1, 1, %setting_multithreading_threads%) do if exist %temp%\counter_duplicates%%i for /f "delims=" %%j in (%temp%\counter_duplicates%%i) do set /a counter_duplicates+=%%j

echo.
if exist %temp%\messages type %temp%\messages
echo.
if exist %temp%\counter_filesScanned1 for /f "delims=" %%i in (%temp%\counter_filesScanned1) do echo.^(i^) Files scanned:   %%i
echo.^(i^) Duplicate pairs: %counter_duplicates%
echo.

if exist "%temp%\session_completed" (
  echo.
  echo.
  echo.
  echo.^(i^) Press Enter to go to the main menu
  pause>nul
  exit /b
)

timeout /t 1 >nul
goto :screen_scan









:scan_preparing
%logo% Scan Controller

echo.>%temp%\duplicates
set counter_log=0

:cycle_log_name
set /a counter_log+=1
set log_duplicates=logs\reDuplicator_%currentDate%_%counter_log%.txt
if exist "%log_duplicates%" goto :cycle_log_name



echo.^(i^) Getting directory tree...>>%temp%\messages
set counter_dataLines=0

for /f "delims=" %%i in ('dir /a:-d /b /s "%directory%\*%setting_filter_include%*"') do for /f "delims=" %%j in ("%%i") do (
  set /a counter_dataLines+=1
  echo.%%i;%%~zj>>%temp%\data
)

for /f "delims=" %%i in ("%temp%\data") do echo.^(i^) Directory tree data size: %%~zi bytes>>%temp%\messages
echo.>>%temp%\messages



echo.^(i^) Initialization...>>%temp%\messages
timeout /nobreak /t 3 >nul

set /a multithreading_linesPerThread=%counter_dataLines%/%setting_multithreading_threads%+1
set counter_thread=1
set counter_dataLines_min=0
set counter_dataLines=0
set counter_dataLines_max=%multithreading_linesPerThread%
call :cycle_multithread_initializing



echo.^(i^) Starting file comparing threads...>>%temp%\messages
for /l %%i in (1, 1, %setting_multithreading_threads%) do start "" "%~dpnx0" --call=scan --thread=%%i



:cycle_scanWait
timeout /nobreak /t 1 >nul
for /f "delims=" %%i in ('tasklist /fi "IMAGENAME eq cmd.exe" /fi "WINDOWTITLE eq %app_name% Thread*" ^| find /i /c "cmd.exe"') do if "%%i" == "0" goto :cycle_scanWait_outPoint
goto :cycle_scanWait
:cycle_scanWait_outPoint



timeout /nobreak /t 1 >nul
echo.>%temp%\session_completed



echo.^(i^) Completed^!>>%temp%\messages
echo.>>%temp%\messages

if exist %log_duplicates% (
  echo.^(i^) All info saved into the %log_duplicates% file>>%temp%\messages
  for /f "delims=" %%i in ("%log_duplicates%") do echo.^(i^) Log file size: %%~zi bytes>>%temp%\messages
) else echo.^(^!^) Any duplicates not found>>%temp%\messages
exit









:scan
%logo%
title %app_name% Thread %1
setlocal EnableDelayedExpansion
set counter_filesScanned=0
set counter_duplicates=0

for /f "tokens=1,2,* delims=;" %%i in ('type %temp%\data ^| find /i /v "%setting_filter_exclude%"') do (
  set /a counter_filesScanned+=1
  echo.!counter_filesScanned!>%temp%\counter_filesScanned%1
  for /f "tokens=1,2,* delims=;" %%o in ('type %temp%\data_thread%1 ^| find /i /v "%setting_filter_exclude%"') do (
    if "%%i" NEQ "%%o" if "%%j" == "%%p" (
      for /f "skip=1 tokens=2* delims=:" %%k in ('%module_rehash% -sha1 "%%i"') do (
        for /f "skip=1 tokens=2* delims=:" %%q in ('%module_rehash% -sha1 "%%o"') do (
          if "%%k" == "%%q" (
            for /f "delims=" %%z in ('type %temp%\duplicates ^| find /i /c "%%i"') do if "%%z" == "0" (
              set /a counter_duplicates+=1
              echo.!counter_duplicates!>%temp%\counter_duplicates%1

              echo.%%i>>%temp%\duplicates
              echo.%%o>>%temp%\duplicates

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
)

endlocal
exit









:screen_settings
%logo%
set buffer=
%input_clear%

%settings_import%

echo.^(i^) Settings Menu
echo.    Filters:

if "%setting_filter_include%" == "" ( echo.      ^(1^) Include: [all]
) else echo.      ^(1^) Include: %setting_filter_include%
if "%setting_filter_exclude%" == "" ( echo.      ^(2^) Exclude: [nothing]
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
echo.
echo.debug=%setting_debug%>>%settings%
echo.filter_include=%setting_filter_include%>>%settings%
echo.filter_exclude=%setting_filter_exclude%>>%settings%
echo.multithreading=%setting_multithreading%>>%settings%
echo.multithreading_threads=%setting_multithreading_threads%>>%settings%

endlocal
goto :screen_settings









:logo
if "%*" == "" ( title [MikronT] %app_name% %app_version% ^| %directory%
) else title [MikronT] %app_name% %app_version% ^| %directory% ^| %*
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
  if not exist temp md temp
  echo.%directory%>temp\directory
  for /f "delims=" %%i in ("temp\directory") do if "%%~zi" == "5" set directory=%directory:\=%
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









:cycle_multithread_initializing
call :multithread_data_writing

if "%counter_thread%" == "%setting_multithreading_threads%" exit /b

set /a counter_thread+=1
set /a counter_dataLines_min+=%multithreading_linesPerThread%
set /a counter_dataLines_max+=%multithreading_linesPerThread%
goto :cycle_multithread_initializing









:multithread_data_writing
setlocal EnableDelayedExpansion
for /f "delims=" %%i in (%temp%\data) do (
  set /a counter_dataLines+=1
  if !counter_dataLines! GTR %counter_dataLines_min% echo.%%i>>%temp%\data_thread%counter_thread%
  if "!counter_dataLines!" == "%counter_dataLines_max%" exit /b
)
endlocal
exit /b