@echo off

rem exit if already initialized
if 0%__INIT__% NEQ 0 exit /b 0

if "%CONTOOLS_ROOT%" == "" set "CONTOOLS_ROOT=%~dp0..\..\Tools"
set "CONTOOLS_ROOT=%CONTOOLS_ROOT:\=/%"
if "%CONTOOLS_ROOT:~-1%" == "/" set "CONTOOLS_ROOT=%CONTOOLS_ROOT:~0,-1%"

if "%CONFIG_ROOT%" == "" set "CONFIG_ROOT=%~dp0..\..\Config"
set "CONFIG_ROOT=%CONFIG_ROOT:\=/%"
if "%CONFIG_ROOT:~-1%" == "/" set "CONFIG_ROOT=%CONFIG_ROOT:~0,-1%"

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
call "%%CONTOOLS_ROOT%%/resetenv.bat" -p -e "%%CONFIG_ROOT%%/env/%%~1" >nul
echo.

rem basic variables
set "TESTS_ROOT=%~dp0"
set "TESTS_ROOT=%TESTS_ROOT:\=/%"
if "%TESTS_ROOT:~-1%" == "/" set "TESTS_ROOT=%TESTS_ROOT:~0,-1%"

if "%TEST_SCRIPTS_ROOT%" == "" set "TEST_SCRIPTS_ROOT=%TESTS_ROOT%/../../Scripts"
set "TEST_SCRIPTS_ROOT=%TEST_SCRIPTS_ROOT:\=/%"
if "%TEST_SCRIPTS_ROOT:~-1%" == "/" set "TEST_SCRIPTS_ROOT=%TEST_SCRIPTS_ROOT:~0,-1%"

rem external tools root directory
call :ABSPATH EXTERNAL_TOOLS_ROOT "%%TESTS_ROOT%%/../../ToolsExternal"

rem python bin root
call :ABSPATH TEST_PYTHON_BIN_ROOT "%%EXTERNAL_TOOLS_ROOT%%/python/python-3.x-win32"

rem python executable path
call :ABSPATH TEST_PYTHON_EXE "%%TEST_PYTHON_BIN_ROOT%%/python.exe"

rem python pytest module command line prefix
call :ABSPATH TEST_PYTHON_PYTEST_CMD_LINE_PREFIX "%%TEST_PYTHON_EXE%%" -B -m pytest

rem python search paths
set "PYTHONPATH=%%TESTS_ROOT:\=/%%/pyscripts;%%TESTS_ROOT:\=/%%/pytests"

rem nest level to call tests end logic in case of exit from a batch file with 0 nest level
if "%__NEST_LVL%" == "" set __NEST_LVL=0

rem declare initialized
set __INIT__=1

exit /b 0

:ABSPATH
if "%~3" == "" (
  set "%~1=%~dpf2"
) else set %~1="%~dpf2" %3 %4 %5 %6 %7 %8 %9
exit /b 0
