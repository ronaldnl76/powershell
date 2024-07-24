$ECHO OFF

set THISDIR=%~DP0

start "" "Powershell.exe" -executionpolicy bypass -noprofile -file "%THISDIR%%~n0.ps1" -windowsstyle hidden
