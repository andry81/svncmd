@echo off

if /i "%SVNCMD_PROJECT_ROOT_INIT0_DIR%" == "%~dp0" exit /b 0

if not defined NEST_LVL set NEST_LVL=0

if not defined SVNCMD_PROJECT_ROOT                call :CANONICAL_PATH SVNCMD_PROJECT_ROOT                "%%~dp0.."
if not defined SVNCMD_PROJECT_EXTERNALS_ROOT      call :CANONICAL_PATH SVNCMD_PROJECT_EXTERNALS_ROOT      "%%SVNCMD_PROJECT_ROOT%%/_externals"

if not defined SVNCMD_TOOLS_ROOT                  call :CANONICAL_PATH SVNCMD_TOOLS_ROOT                  "%%SVNCMD_PROJECT_ROOT%%/Scripts"

rem init contools project
if exist "%SVNCMD_PROJECT_EXTERNALS_ROOT%/contools/__init__/__init__.bat" (
  call "%%SVNCMD_PROJECT_EXTERNALS_ROOT%%/contools/__init__/__init__.bat" || exit /b
)

set "SVNCMD_PROJECT_ROOT_INIT0_DIR=%~dp0"

exit /b 0

:CANONICAL_PATH
setlocal DISABLEDELAYEDEXPANSION
for /F "eol= tokens=* delims=" %%i in ("%~2\.") do set "RETURN_VALUE=%%~fi"
rem set "RETURN_VALUE=%RETURN_VALUE:\=/%"
(
  endlocal
  set "%~1=%RETURN_VALUE%"
)
exit /b 0
