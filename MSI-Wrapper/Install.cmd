@ECHO OFF
Set THISDIR=%~DP0

Set APP=Application X
Set MSI=Application_1.0_X64.msi
Set ARG=REBOOT=ReallySuppress /QN
Set VER=4.5.1.0
Set VERSEARCH=1

Title Applicatie %APP%

Echo.
Echo Install Application %APP%

if "%PROCESSOR_ARCHITECTURE%"=="AMD64" goto 64BIT
start "" /WAIT "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -NoLogo -NoProfile -WindowStyle Hidden -File "%THISDIR%%~n0.ps1" -APP %APP% -MSI %MSI% -ARG "%ARG%" -VER %VER% -VERSEARCH %VERSEARCH%
goto END 
:64BIT
start "" /WAIT "Powershell.exe" -executionpolicy bypass -NoLogo -NoProfile -WindowStyle hidden -file "%THISDIR%%~n0.ps1" -APP %APP% -MSI %MSI% -ARG "%ARG%" -VER %VER% -VERSEARCH %VERSEARCH%
:END