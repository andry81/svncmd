@echo off

if "%__NEST_LVL%" == "" set __NEST_LVL=0

if %__NEST_LVL% GTR 0 exit /b 0

if "%CONTOOLS_ROOT%" == "" set "CONTOOLS_ROOT=%~dp0..\..\tools"
set "CONTOOLS_ROOT=%CONTOOLS_ROOT:\=/%"
if "%CONTOOLS_ROOT:~-1%" == "/" set "CONTOOLS_ROOT=%CONTOOLS_ROOT:~0,-1%"

rem To avoid interference with already installed versions of tools we have to reset
rem entire environment into initial state to just after the Windows install.
rem Read windows version.
call "%%CONTOOLS_ROOT%%/winver.bat"

for /F "eol= tokens=1,2,* delims=|" %%i in ("%WINVER_VALUE%") do (
  set "OSNAME=%%i"
)

if "%OSNAME%" == "" (
  echo.%~nx0: error: Windows version is not detected.
  exit /b 255
) >&2

if "%OSNAME%" == "Windows" (
  echo.%~nx0: error: Windows version is unknown.
  exit /b 254
) >&2

if "%OSNAME%" == "Windows2000" goto :RESET_ENV_WIN2K_AND_CONTINUE
if "%OSNAME%" == "WindowsXP" goto :RESET_ENV_WINXP_AND_CONTINUE
if "%OSNAME%" == "WindowsVista" goto :RESET_ENV_WINVISTA_AND_CONTINUE
if "%OSNAME%" == "Windows7" goto :RESET_ENV_WIN7_AND_CONTINUE
if "%OSNAME%" == "Windows8" goto :RESET_ENV_WIN8_AND_CONTINUE

echo.%~nx0: error: Windows version is not supported.
exit /b 253

:RESET_ENV_WIN2K_AND_CONTINUE
call :RESET_ENV_AND_CONTINUE vars_win2k.lst
goto :EOF

:RESET_ENV_WINXP_AND_CONTINUE
call :RESET_ENV_AND_CONTINUE vars_winxp.lst
goto :EOF

:RESET_ENV_WINVISTA_AND_CONTINUE
call :RESET_ENV_AND_CONTINUE vars_vista.lst
goto :EOF

:RESET_ENV_WIN7_AND_CONTINUE
call :RESET_ENV_AND_CONTINUE vars_win7.lst
goto :EOF

:RESET_ENV_WIN8_AND_CONTINUE
call :RESET_ENV_AND_CONTINUE vars_win8.lst
goto :EOF

:RESET_ENV_AND_CONTINUE
rem Reset environment
set "__NEST_LVL="
set "CONTOOLS_ROOT=%CONTOOLS_ROOT%"
set "WINVER_VALUE="
set "OSNAME="
echo %~nx0: Resetting environment to defaults...
call "%%CONTOOLS_ROOT%%/Tools/resetenv.bat" -p -e "%%~dp0..\..\Config\env\%%~1" >nul
echo.

rem builtin variables
set __NEST_LVL=0

set __PASSED_TESTS=0
set __OVERALL_TESTS=0

set "TESTS_ROOT=%~dp0"
set "TESTS_ROOT=%TESTS_ROOT:\=/%"
if "%TESTS_ROOT:~-1%" == "/" set "TESTS_ROOT=%TESTS_ROOT:~0,-1%"

if "%CONTOOLS_ROOT%" == "" set "CONTOOLS_ROOT=%~dp0..\..\tools"
set "CONTOOLS_ROOT=%CONTOOLS_ROOT:\=/%"
if "%CONTOOLS_ROOT:~-1%" == "/" set "CONTOOLS_ROOT=%CONTOOLS_ROOT:~0,-1%"

if "%GNUWIN32_ROOT%" == "" set "GNUWIN32_ROOT=%CONTOOLS_ROOT%/gnuwin32"
set "GNUWIN32_ROOT=%GNUWIN32_ROOT:\=/%"
if "%GNUWIN32_ROOT:~-1%" == "/" set "GNUWIN32_ROOT=%GNUWIN32_ROOT:~0,-1%"

if "%SVNCMD_TOOLS_ROOT%" == "" set "SVNCMD_TOOLS_ROOT=%CONTOOLS_ROOT%/scm/svn"
set "SVNCMD_TOOLS_ROOT=%SVNCMD_TOOLS_ROOT:\=/%"
if "%SVNCMD_TOOLS_ROOT:~-1%" == "/" set "SVNCMD_TOOLS_ROOT=%SVNCMD_TOOLS_ROOT:~0,-1%"

rem load rest variables
call "%%CONTOOLS_ROOT%%/setvarsfromfile.bat" "%%~dp0init.vars"

rem declare initialized
set __INIT__=1
