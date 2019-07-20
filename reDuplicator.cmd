@echo off
chcp 65001>nul

%~d0
cd "%~dp0"



set app_name=ReDuplicator
set app_version=Alpha 1

set title_main=[MikronT] %app_name% %app_version%
set title_scan=%app_name%   Session: %session%   Thread

set setting_debug=false
set setting_filter_include=
set setting_filter_exclude=
set setting_multithreading=2

set settings=settings.ini

set module_rehash=modules\rehash.exe -norecur -none

set getProcessesCount=call :getProcessesCount
set input=set /p command= ^^^> 
set input_clear=set command=
set logo=call :logo
set settings_import=call :settings_import



%settings_import%



set argument=%1
set argument=%argument:"=%

if exist "%argument%" ( set directory=%argument%
) else for /f "tokens=1,* delims=- " %%i in ("%*") do (
  if "%%i" NEQ "" set key_%%i
  if "%%j" NEQ "" set key_%%j
)

if exist "%directory%" (
  if not exist temp md temp
  echo.%directory%>temp\directory
  for /f "delims=" %%i in ("temp\directory") do if "%%~zi" == "5" set directory=%directory:\=%
)

if "%key_call%" == "scan" %logo% %title_scan% %key_args%
if "%key_call%" NEQ "" call :%key_call% %key_args%



%getProcessesCount% %title_main%*
if "%counter_processes%" == "2" exit









:screen_main
:cycle_sessionSet
set session=%random%%random%
set temp=temp\session-%session%
if exist "%temp%" goto :cycle_sessionSet

set currentDate=%date%
for /f "tokens=2 delims= " %%i in ("%currentDate%") do set currentDate=%%i
for /f "tokens=1-3 delims=/." %%i in ("%currentDate%") do set currentDate=%%k.%%j.%%i

if not exist logs md logs
if not exist %temp% md %temp%

set log=logs\reDuplicator_%currentDate%_%session%.txt
set counter_log=0
if exist "%log%" call :cycle_log_name



%input_clear%
%logo%

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
  start %debugModifier_b% "" "%~dpnx0" --call=scan_controller
  call :screen_scan
)
if "%command%" == "2" call :screen_settings



if exist %temp% rd /s /q %temp%
goto :screen_main









:screen_scan
set counter_filesScanned=0
for /l %%i in (1, 1, %setting_multithreading%) do if exist %temp%\counter_filesScanned%%i for /f "delims=" %%j in (%temp%\counter_filesScanned%%i) do set /a counter_filesScanned+=%%j
set /a counter_filesScanned/=%setting_multithreading%

set counter_duplicates=0
for /l %%i in (1, 1, %setting_multithreading%) do if exist %temp%\counter_duplicates%%i for /f "delims=" %%j in (%temp%\counter_duplicates%%i) do set /a counter_duplicates+=%%j

if "%counter_duplicates%" NEQ "0" (
  call :math_set counter_duplicates_size 0
  for /l %%i in (1, 1, %setting_multithreading%) do if exist %temp%\counter_duplicates_size%%i for /f "delims=" %%j in (%temp%\counter_duplicates_size%%i) do call :math_add counter_duplicates_size %%j

  start /wait /b "" "%~dpnx0" --call=math_format --args=counter_duplicates_size
  if exist %temp%\math_number_format_counter_duplicates_size for /f "delims=" %%i in (%temp%\math_number_format_counter_duplicates_size) do set counter_duplicates_size=%%i
)



setlocal EnableDelayedExpansion
%logo%

if exist %temp%\messages (
  type %temp%\messages
  echo.    Files scanned    :^|:  %counter_filesScanned%
  if "%counter_duplicates%" NEQ "0" (
    echo.    Duplicates       :^|:  %counter_duplicates%
    echo.    Duplicates size  :^|:  %counter_duplicates_size%
  )
  echo.
)
endlocal



if not exist "%temp%\session_completed" (
  timeout /t 3 >nul
  goto :screen_scan
)



if exist "%log%" (
  echo.^(i^) All info saved into the log file:
  for /f "delims=" %%i in ("%log%") do echo.      %log%  :^|:  %%~zi bytes
) else echo.^(^!^) Any duplicates not found

echo.
echo.
echo.
echo.^(i^) Press Enter to go to the main menu
pause>nul
exit /b









:scan_controller
echo.^(i^) Getting directory tree...>>%temp%\messages
set counter_dataLines=0

for /f "delims=" %%i in ('dir /a:-d /b /s "%directory%\*%setting_filter_include%*"') do for /f "delims=" %%j in ("%%i") do (
  set /a counter_dataLines+=1
  echo.%%i;%%~zj>>%temp%\data
)

for /f "delims=" %%i in ("%temp%\data") do echo.    Directory tree data size: %%~zi bytes>>%temp%\messages
echo.>>%temp%\messages



echo.^(i^) Initialization...>>%temp%\messages

set /a multithreading_linesPerThread=%counter_dataLines%/%setting_multithreading%+1
set counter_thread=1
set counter_dataLines_min=0
set counter_dataLines=0
set counter_dataLines_max=%multithreading_linesPerThread%
call :cycle_multithread_initializing

echo.    Initialized: %setting_multithreading% threads>>%temp%\messages
echo.>>%temp%\messages



echo.^(i^) Starting file comparing threads...>>%temp%\messages

echo.>%temp%\duplicates
for /l %%i in (1, 1, %setting_multithreading%) do start %debugModifier_min% "" "%~dpnx0" --call=scan --args=%%i
timeout /nobreak /t 2 >nul



:cycle_scanWait
timeout /nobreak /t 1 >nul
%getProcessesCount% %title_scan%*
if "%counter_processes%" NEQ "0" goto :cycle_scanWait



start /wait %debugModifier_b% "" "%~dpnx0" --call=log_controller

echo.>%temp%\session_completed
exit









:cycle_log_name
set /a counter_log+=1
set log=logs\reDuplicator_%currentDate%_%session%_%counter_log%.txt
if exist "%log%" goto :cycle_log_name









:cycle_multithread_initializing
call :multithread_data_writing

if "%counter_thread%" == "%setting_multithreading%" exit /b

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









:scan
if not exist %temp%\data_thread%1 exit

setlocal EnableDelayedExpansion
set counter_filesScanned=0
set counter_duplicates=0
set counter_duplicates_size=0

for /f "tokens=1,2,* delims=;" %%i in ('type %temp%\data ^| find /i /v "%setting_filter_exclude%"') do (
  set /a counter_filesScanned+=1
  echo.!counter_filesScanned!>%temp%\counter_filesScanned%1
  for /f "tokens=1,2,* delims=;" %%o in ('type %temp%\data_thread%1 ^| find /i /v "%setting_filter_exclude%"') do (
    if "%%i" NEQ "%%o" if "%%j" == "%%p" (
      for /f "skip=1 tokens=2* delims=:" %%k in ('%module_rehash% -sha1 "%%i"') do (
        for /f "skip=1 tokens=2* delims=:" %%q in ('%module_rehash% -sha1 "%%o"') do (
          if "%%k" == "%%q" (
            for /f "delims=" %%z in ('type %temp%\duplicates ^| find /i /c "%%i"') do if "%%z" == "0" (
              echo.%%i>>%temp%\duplicates
              echo.%%o>>%temp%\duplicates

              set /a counter_duplicates+=1
              echo.!counter_duplicates!>%temp%\counter_duplicates%1

              set /a counter_duplicates_size+=%%j
              echo.!counter_duplicates_size!>%temp%\counter_duplicates_size%1

              echo.^(i^) Duplicates:
              if "%setting_debug%" == "false" (
                echo.    %%i  :^|:  %%j bytes
                echo.    %%o  :^|:  %%p bytes
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

              (
                echo.Duplicates:
                if "%setting_debug%" == "false" (
                  echo.    %%i  :^|:  %%j bytes
                  echo.    %%o  :^|:  %%p bytes
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
              )>>%temp%\log_thread%1
            )
          )
        )
      )
    )
  )
)

endlocal
exit









:log_controller
(
  for /f "delims=" %%i in ('dir /a:-d /b "%temp%\log_thread*" ^| find /i /c "log_thread"') do if "%%i" NEQ "0" (
    echo.ReDuplicator Log File ^| %currentDate%
    echo.
    echo.
    if "%setting_debug%" == "true" (
      echo.Variables:
      echo.  debug=%setting_debug%
      echo.  filter_include=%setting_filter_include%
      echo.  filter_exclude=%setting_filter_exclude%
      echo.  multithreading=%setting_multithreading%
      echo.
      echo.  log=%log%
      echo.  session=%session%
      echo.  temp=%temp%
      echo.
      echo.
    )
    echo.
  )

  for /l %%i in (1, 1, %setting_multithreading%) do if exist %temp%\log_thread%%i type %temp%\log_thread%%i
)>>%log%
exit









:screen_settings
%settings_import%
set buffer=

%input_clear%
%logo%

echo.^(i^) Settings Menu
echo.    Filters:

if "%setting_filter_include%" == "" ( echo.      ^(1^) Include: [all]
) else echo.      ^(1^) Include: %setting_filter_include%
if "%setting_filter_exclude%" == "" ( echo.      ^(2^) Exclude: [nothing]
) else echo.      ^(2^) Exclude: %setting_filter_exclude%

echo.

if "%setting_multithreading%" == "1" ( echo.    ^(3^) Multithreading: false
) else echo.    ^(3^) Multithreading ^(threads^): %setting_multithreading%

if %setting_multithreading% GTR 2 (
  echo.       ^(i^) Warning^! More threads - more bugs^!
  echo.
)

echo.    ^(4^) Debug: %setting_debug%
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
if "%command%" == "3" (
         if "%setting_multithreading%" == "1" ( set setting_multithreading=2
  ) else if "%setting_multithreading%" == "2" ( set setting_multithreading=3
  ) else if "%setting_multithreading%" == "3" ( set setting_multithreading=4
  ) else if "%setting_multithreading%" == "4" ( set setting_multithreading=5
  ) else if "%setting_multithreading%" == "5" ( set setting_multithreading=6
  ) else if "%setting_multithreading%" == "6" ( set setting_multithreading=7
  ) else if "%setting_multithreading%" == "7"   set setting_multithreading=1
)
if "%command%" == "4" if "%setting_debug%" == "true" ( set setting_debug=false
) else set setting_debug=true



(
  echo.# ReDuplicator Settings #
  echo.
  echo.debug=%setting_debug%
  echo.filter_include=%setting_filter_include%
  echo.filter_exclude=%setting_filter_exclude%
  echo.multithreading=%setting_multithreading%i
)>>%settings%

endlocal
goto :screen_settings









:logo
if "%*" == "" ( title %title_main% ^| Session: %session% ^| %directory%
) else title %*
color 0b
cls
echo.
echo.
echo.    [MikronT] ==^> %app_name%
echo.                  %app_version%
echo.   ============================
echo.     See other here:
echo.         github.com/MikronT
echo.
echo.
echo.
exit /b









:settings_import
if exist "%settings%" for /f "eol=# delims=" %%i in (%settings%) do set setting_%%i

if "%setting_debug%" == "true" (
  set debugModifier_b=
  set debugModifier_min=
) else (
  set debugModifier_b=/b
  set debugModifier_min=/min
)
for /f "delims=i" %%i in ("%setting_multithreading%") do set setting_multithreading=%%i
exit /b









:getProcessesCount
set counter_processes=0

for /f "delims=" %%i in ('tasklist /fi "IMAGENAME eq cmd.exe" /fi "WINDOWTITLE eq %*" ^| find /i /c "cmd.exe"') do set /a counter_processes+=%%i
for /f "delims=" %%i in ('tasklist /fi "IMAGENAME eq cmd.exe" /fi "WINDOWTITLE eq Select %*" ^| find /i /c "cmd.exe"') do set /a counter_processes+=%%i
exit /b









:math_set
echo.%2>%temp%\math_number_%1
exit /b





:math_add
set math_add_number=0
if exist "%temp%\math_number_%1" for /f "delims=" %%z in (%temp%\math_number_%1) do set math_add_number=%%z

set /a math_add_number+=%2
echo.%math_add_number%>%temp%\math_number_%1
exit /b





:math_format
for /f "delims=" %%z in (%temp%\math_number_%1) do (
  set    math_number_format_B_%1=%%z
  set /a math_number_format_KB_%1=%%z/1024
  set /a math_number_format_MB_%1=%%z/1024/1024
  set /a math_number_format_GB_%1=%%z/1024/1024/1024
  set /a math_number_format_TB_%1=%%z/1024/1024/1024/1024
)

setlocal EnableDelayedExpansion

(
  if "!math_number_format_TB_%1!" NEQ "0" (
    if !math_number_format_TB_%1! LSS !math_number_format_GB_%1! echo.!math_number_format_TB_%1! TB
  ) else if "!math_number_format_GB_%1!" NEQ "0" (
    if !math_number_format_GB_%1! LSS !math_number_format_MB_%1! echo.!math_number_format_GB_%1! GB
  ) else if "!math_number_format_MB_%1!" NEQ "0" (
    if !math_number_format_MB_%1! LSS !math_number_format_KB_%1! echo.!math_number_format_MB_%1! MB
  ) else if "!math_number_format_KB_%1!" NEQ "0" (
    if !math_number_format_KB_%1! LSS !math_number_format_B_%1! echo.!math_number_format_KB_%1! KB
  ) else echo.!math_number_format_B_%1! bytes
)>%temp%\math_number_format_%1

endlocal
exit