@ECHO OFF

Set THISDIR=%~DP0

if "%PROCESSOR_ARCHITECTURE%"=="AMD64" goto 64BIT
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%THISDIR%%~n0.ps1"
goto END
:64BIT
"Powershell.exe" -executionpolicy bypass -NoLogo -NoProfile -file "%THISDIR%%~n0.ps1"
:END

