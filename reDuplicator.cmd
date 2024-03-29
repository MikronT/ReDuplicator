@echo off
chcp 65001>nul

%~d0
cd "%~dp0"

if not exist temp md temp



set app_name=ReDuplicator
set app_name_ns=reDuplicator
set app_version_code=1.0.0.3.1.0
set app_version_name=v1.0 Pre-Release 1

set title_main=[MikronT] %app_name% %app_version_name%
set title_scan=%app_name%   Session: %session%   Thread

set update_version_output=temp\%app_name_ns%.version
set update_version_url=https://drive.google.com/uc?export=download^^^&id=1AD5-j7h5W4qxSuGgnjObGaRiAFA5eIwF

set setting_debug=false
set setting_filter_include=
set setting_filter_exclude=
set setting_multithreading=2

set settings=settings.ini



set module_powershell=start /min powershell.exe
set module_rehash=modules\rehash.exe -norecur -none

set getProcessesCount=call :getProcessesCount
set input=set /p command= ^^^> 
set input_clear=set command=
set logo=call :logo
set math_add=call :math_add
set math_format=start /wait /b "" "%~dpnx0" --call=math_format
set math_get=call :math_get
set math_set=call :math_set
set notification=call :notification
set settings_import=call :settings_import



for /f "tokens=1-6 delims=." %%i in ("%app_version_code%") do set app_version_number=%%i%%j%%k%%l%%m%%n

%settings_import%



set argument=%1
set argument=%argument:"=%

if exist "%argument%" ( set directory=%argument%
) else (
  for /f "tokens=1,* delims=- " %%i in ("%*") do (
    if "%%i" NEQ "" set key_%%i
    if "%%j" NEQ "" set key_%%j
  )
)

if "%key_call%" == "scan" %logo% %title_scan% %key_args%
if "%key_call%" NEQ "" call :%key_call% %key_args%



rem %module_powershell% "(New-Object System.Net.WebClient).DownloadFile("""%update_version_url%""", """%update_version_output%""")"
%module_powershell% "Invoke-WebRequest -Uri """%update_version_url%""" -OutFile """%update_version_output%""""



%getProcessesCount% %title_main%*
set counter_processes_main=%counter_processes%

%getProcessesCount% %title_main%   Shutdown*
set /a counter_processes_main-=%counter_processes%

if %counter_processes_main% GEQ 2 exit









:screen_main
if exist "%directory%" (
  echo.%directory%>temp\directory
  for /f "delims=" %%i in ("temp\directory") do if "%%~zi" == "5" set directory=%directory:\=%
)

:cycle_session
set session=%random%%random%
set temp=temp\session-%session%
if exist "%temp%" goto :cycle_session

set currentDate=%date%
for /f "tokens=2 delims= " %%i in ("%currentDate%") do set currentDate=%%i
for /f "tokens=1-3 delims=/." %%i in ("%currentDate%") do set currentDate=%%k.%%j.%%i

if not exist logs md logs
if not exist %temp% md %temp%

set log_name=logs\%app_name_ns%_%currentDate%_%session%
set log=%log_name%
set log_debug=%log_name%_debug
set counter_log=0

if exist "%log%.txt" ( call :cycle_log_name
) else if exist "%log_debug%.txt" ( call :cycle_log_name
) else (
  set log=%log_name%.txt
  set log_debug=%log_name%_debug.txt
)

if "%setting_debug%" == "false" set log_debug=nul

if exist "%update_version_output%" for /f "tokens=1-6 delims=." %%i in (%update_version_output%) do if "%%l" == "4" if %%i%%j%%k%%l%%m%%n GTR %app_version_number% echo.>temp\return_update_available



%input_clear%
%logo%

echo.^(i^) Session: %session%
echo.
echo.^(i^) Program directory: "%cd%"
if exist "%directory%" (
  echo.^(i^) Work directory:    "%directory%"
  echo.
  echo.
  echo.^(i^) Main Menu
  echo.    ^(1^) Run scan
  echo.    ^(2^) Open logs folder
  echo.    ^(3^) Settings
) else (
  if "%setting_debug%" == "true" ( echo.^(^!^) Directory not found: "%directory%"
  ) else echo.^(^!^) Directory not found^!
  echo.^(i^) Use Drag^&Drop: drag the directory into this window or onto the %~nx0 file
)
if exist "temp\return_update_available" (
  echo.
  echo.    ^(i^) %app_name% update is now available^! Press ^(U^) to download update
)
echo.
echo.    ^(0^) Exit
echo.
echo.
echo.
%input%
if defined command set command=%command:"=%



if exist "%directory%" (
  if "%command%" == "1" (
    start %debugModifier_b% "" "%~dpnx0" --call=scan_controller
    set shutdown=-1
    set shutdown_hours=0
    start "" "%~dpnx0" --call=screen_shutdown
    call :screen_scan
  )
  if "%command%" == "2" start explorer "%~dp0logs"
  if "%command%" == "3" call :screen_settings
)
if /i "%command%" == "U" if exist "temp\return_update_available" start "" "https://github.com/MikronT/%app_name%/releases/latest"
if "%command%" == "0" exit

if exist "%command%" set directory=%command%



if exist "%temp%\return_sessionCompleted" if exist "%temp%\return_shutdown" for /f "delims=" %%i in ('type "%temp%\return_shutdown"') do if "%%i" NEQ "-1" (
  %notification% warning The computer will plan shutdown in 10s! Close the window to cancel this
  timeout /t 10 >nul
  shutdown /s /t %%i
) else shutdown /a

if exist %temp% rd /s /q %temp%
goto :screen_main









:screen_scan
set counter_files_scanned=0
(for /l %%i in (1, 1, %setting_multithreading%) do if exist %temp%\counter_files_scanned%%i for /f "delims=" %%j in (%temp%\counter_files_scanned%%i) do set /a counter_files_scanned+=%%j)>nul 2>>%log_debug%
set /a counter_files_scanned/=%setting_multithreading%


set counter_files_all=0
(if exist %temp%\counter_files_all for /f "delims=" %%i in (%temp%\counter_files_all) do set counter_files_all=%%i)>nul 2>>%log_debug%
if "%counter_files_all%" == "0" ( set counter_operation=0
) else set /a counter_operation=%counter_files_scanned%*100/%counter_files_all%


set counter_duplicates=0
(for /l %%i in (1, 1, %setting_multithreading%) do if exist %temp%\counter_duplicates%%i for /f "delims=" %%j in (%temp%\counter_duplicates%%i) do set /a counter_duplicates+=%%j)>nul 2>>%log_debug%


if "%counter_duplicates%" NEQ "0" (
  %math_set% counter_duplicates_size 0
  (for /l %%i in (1, 1, %setting_multithreading%) do if exist %temp%\counter_duplicates_size%%i for /f "delims=" %%j in (%temp%\counter_duplicates_size%%i) do %math_add% counter_duplicates_size %%j)>nul 2>>%log_debug%

  %math_format% --args=counter_duplicates_size
  (if exist %temp%\math_number_format_counter_duplicates_size for /f "delims=" %%i in (%temp%\math_number_format_counter_duplicates_size) do set counter_duplicates_size=%%i)>nul 2>>%log_debug%
)



%logo%

if exist %temp%\messages (
  type %temp%\messages
  echo.    Files scanned    :^|:  %counter_files_scanned%/%counter_files_all%
  if "%counter_operation%"  NEQ "0" echo.    Completed        :^|:  %counter_operation%%%
  if "%counter_duplicates%" NEQ "0" (
    echo.    Duplicates       :^|:  %counter_duplicates%
    echo.    Duplicates size  :^|:  %counter_duplicates_size%
  )
)



if not exist "%temp%\return_sessionCompleted" (
  timeout /t 5 >nul
  goto :screen_scan
)



if exist "%log%" (
  (
    echo.Files scanned    :^|:  %counter_files_scanned%/%counter_files_all%
    if "%counter_duplicates%"    NEQ "0" (
      echo.Duplicates       :^|:  %counter_duplicates%
      echo.Duplicates size  :^|:  %counter_duplicates_size%
    )
  )>>%log%

  echo.
  echo.^(i^) All info saved to the log file:
  for /f "delims=" %%i in ("%log%") do echo.      %log%  :^|:  %%~zi bytes
  %notification% info Scan completed. All info saved to the log
) else (
  echo.^(^!^) Any duplicates not found
  %notification% info Scan completed. Any duplicates not found
)

echo.
echo.
echo.
echo.^(i^) Press Enter to go to the main menu

timeout /t 20 >nul
exit /b









:scan_controller
echo.^(i^) Getting directory tree...>>%temp%\messages
set counter_files_all=0

for /f "delims=" %%i in ('dir /a:-d /b /s "%directory%\*%setting_filter_include%*"') do for /f "delims=" %%j in ("%%i") do (
  set /a counter_files_all+=1
  echo.%%i;%%~zj>>%temp%\data
)

echo.%counter_files_all%>%temp%\counter_files_all
for /f "delims=" %%i in ("%temp%\data") do echo.    Directory tree data size: %%~zi bytes>>%temp%\messages
echo.>>%temp%\messages



echo.^(i^) Initialization...>>%temp%\messages
set /a multithreading_linesPerThread=%counter_files_all%/%setting_multithreading%+1

set counter_thread=1
set counter_dataLines_min=0
set counter_dataLines=0
set counter_dataLines_max=%multithreading_linesPerThread%
call :multithread_initializing

echo.    Initialized: %setting_multithreading% threads>>%temp%\messages
echo.>>%temp%\messages



echo.^(i^) Starting file comparing threads...>>%temp%\messages
for /l %%i in (1, 1, %setting_multithreading%) do start %debugModifier_min% "" "%~dpnx0" --call=scan --args=%%i
timeout /nobreak /t 2 >nul



:cycle_scanWait
timeout /nobreak /t 5 >nul
%getProcessesCount% %title_scan%*
if "%counter_processes%" NEQ "0" goto :cycle_scanWait



start /wait %debugModifier_b% "" "%~dpnx0" --call=log_controller

echo.>%temp%\return_sessionCompleted
taskkill /f /im cmd.exe /fi "WINDOWTITLE eq %title_main%   Shutdown   Session: %session%">nul
exit









:cycle_log_name
set /a counter_log+=1

if exist "%log%_%counter_log%"       goto :cycle_log_name
if exist "%log_debug%_%counter_log%" goto :cycle_log_name

set log=%log%_%counter_log%.txt
set log_debug=%log_debug%_%counter_log%.txt
exit /b









:multithread_initializing
call :multithread_dataWriting

if "%counter_thread%" == "%setting_multithreading%" exit /b

set /a counter_thread+=1
set /a counter_dataLines_min+=%multithreading_linesPerThread%
set /a counter_dataLines_max+=%multithreading_linesPerThread%
goto :multithread_initializing





:multithread_dataWriting
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
set counter_files_scanned=0
set counter_duplicates=0
set counter_duplicates_size=0

for /f "tokens=1,2,* delims=;" %%i in ('type %temp%\data ^| find /i /v "%setting_filter_exclude%"') do (
  %getProcessesCount% %title_main%*
  if "!counter_processes!" == "0" exit
  set /a counter_files_scanned+=1
  echo.!counter_files_scanned!>%temp%\counter_files_scanned%1
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
(for /f "delims=" %%i in ('dir /a:-d /b "%temp%\log_thread*" ^| find /i /c "log_thread"') do if "%%i" NEQ "0" (
  echo.%app_name% Log File ^| %currentDate%
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
))>>%log% 2>>%log_debug%

for %%i in (%log% %log_debug%) do for /f "delims=" %%j in ("%%i") do if "%%~zj" == "0" del /q "%%i"

if exist "%log%" for /l %%i in (1, 1, %setting_multithreading%) do if exist %temp%\log_thread%%i type %temp%\log_thread%%i>>%log%
exit









:screen_shutdown
setlocal EnableDelayedExpansion
mode con:cols=50 lines=30

%input_clear%
%logo% %title_main%   Shutdown   Session: %session%

if "%shutdown%" == "-1" ( echo.^(i^) Shutdown: not planned
) else if "%shutdown%" == "0" ( echo.^(i^) Shutdown: immediatery
) else if "%shutdown%" == "600" ( echo.^(i^) Shutdown: in 10m
) else if "%shutdown%" == "1800" ( echo.^(i^) Shutdown: in 30m
) else echo.^(i^) Shutdown: in %shutdown_hours%h
echo.
echo.^(^?^) Do you want to plan your computer's shutdown^?
echo.    ^(1^) Shutdown immediatery
echo.    ^(2^) Shutdown in 10m
echo.    ^(3^) Shutdown in 30m
echo.    ^(4^) Enter custom interval
echo.
echo.    ^(5^) Cancel shutdown
echo.
echo.
echo.
%input%



if "%command%" == "1" set shutdown=0
if "%command%" == "2" set shutdown=600
if "%command%" == "3" set shutdown=1800
if "%command%" == "4" (
  set /p shutdown_hours=^(^>^) Enter a valid number in hours ^(up to 24^) ^> 
  if "!shutdown_hours!" NEQ "" if !shutdown_hours! GEQ 0 if !shutdown_hours! LEQ 24 set /a shutdown=!shutdown_hours!*3600
)
if "%command%" == "5" set shutdown=-1



echo.%shutdown%>%temp%\return_shutdown
goto :screen_shutdown









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
  echo.# %app_name% Settings #
  echo.
  echo.debug=%setting_debug%
  echo.filter_include=%setting_filter_include%
  echo.filter_exclude=%setting_filter_exclude%
  echo.multithreading=%setting_multithreading%i
)>%settings%

endlocal
goto :screen_settings









:logo
if "%*" == "" (
  title %title_main% ^| Session: %session% ^| %directory%
  mode con:cols=110 lines=30
) else title %*
color 0b
cls
echo.
echo.
echo.    [MikronT] ==^> %app_name%
echo.                  %app_version_name%
echo.   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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









:notification
setlocal EnableDelayedExpansion
if /i "%1" == "info"    set notification_type=Info
if /i "%1" == "warning" set notification_type=Warning
if /i "%1" == "error"   set notification_type=Error

set notification_args=%*
set "notification_text=!notification_args:%1 =!"

%module_powershell% "Add-Type -AssemblyName System.Windows.Forms; $balloon = New-Object System.Windows.Forms.NotifyIcon; $path = (Get-Process -id $pid).Path; $balloon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path); $balloon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::%notification_type%; $balloon.BalloonTipText = '%notification_text%'; $balloon.BalloonTipTitle = """%app_name% %notification_type%"""; $balloon.Visible = $true; $balloon.ShowBalloonTip(5000)"
endlocal
exit /b









:math_set
echo.%2>%temp%\math_number_%1
exit /b





:math_add
if exist "%temp%\math_number_%1" for /f "delims=" %%z in (%temp%\math_number_%1) do set math_number=%%z
set /a math_number+=%2
%math_set% %1 %math_number%
exit /b





:math_format
set math_number_format_B=0
set math_number_format_KB=0
set math_number_format_MB=0
set math_number_format_GB=0
set math_number_format_TB=0

for /f "delims=" %%z in (%temp%\math_number_%1) do (
  set    math_number_format_B=%%z
  set /a math_number_format_KB=%%z/1024
  set /a math_number_format_MB=%%z/1024/1024
  set /a math_number_format_GB=%%z/1024/1024/1024
  set /a math_number_format_TB=%%z/1024/1024/1024/1024
)

(        if "%math_number_format_TB%" NEQ "0" ( echo.%math_number_format_TB% TB
  ) else if "%math_number_format_GB%" NEQ "0" ( echo.%math_number_format_GB% GB
  ) else if "%math_number_format_MB%" NEQ "0" ( echo.%math_number_format_MB% MB
  ) else if "%math_number_format_KB%" NEQ "0" ( echo.%math_number_format_KB% KB
  ) else                                        echo.%math_number_format_B% bytes
)>%temp%\math_number_format_%1
exit