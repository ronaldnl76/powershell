@ECHO OFF
echo "%~DP0%~n0.ps1"
powershell -executionpolicy bypass -noprofile -windowstyle hidden -file "%~DP0%~n0.ps1"
