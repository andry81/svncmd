@echo off

rem exit if already initialized
if 0%__BATSCRIPT_INIT__% NEQ 0 exit /b 0

set "TESTS_ROOT=%~dp0"
set "TESTS_ROOT=%TESTS_ROOT:~0,-1%"
set "TESTS_ROOT=%TESTS_ROOT:\=/%"

rem initialize Tools "module"
call "%%TESTS_ROOT%%/../../Tools/__init__.bat" || goto :EOF

if "%CONFIG_ROOT%" == "" set "CONFIG_ROOT=%TESTS_ROOT%/../../Config"

rem To avoid interference with already installed versions of tools we have to reset
rem entire environment into initial state when the Windows just installed.
rem Read windows version.
call "%%CONTOOLS_ROOT%%/winver.bat"

for /F "tokens=1,2,* delims=|"eol^= %%i in ("%WINVER_VALUE%") do (
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
set "WINVER_VALUE="
set "OSNAME="
echo %~nx0: Resetting environment to defaults...
call "%%CONTOOLS_ROOT%%/resetenv.bat" -p -e "%%CONFIG_ROOT%%/env/%%~1" >nul
echo.

rem initialize environment again
set "TESTS_ROOT=%~dp0"
set "TESTS_ROOT=%TESTS_ROOT:~0,-1%"
set "TESTS_ROOT=%TESTS_ROOT:\=/%"

rem initialize Tools "module"
call "%%TESTS_ROOT%%/../../Tools/__init__.bat" || goto :EOF

rem external tools root directory
call :ABSPATH EXTERNAL_TOOLS_ROOT "%%TESTS_ROOT%%/../../ToolsExternal"

rem external scripts for tests
call :ABSPATH EXTERNAL_TEST_SCRIPTS_ROOT "%%TESTS_ROOT%%/../../TestScripts"

rem python bin root
call :ABSPATH TEST_PYTHON_BIN_ROOT "%%EXTERNAL_TOOLS_ROOT%%/python/python-win32/3.6.1"

rem python executable path
call :ABSPATH TEST_PYTHON_EXE "%%TEST_PYTHON_BIN_ROOT%%/python.exe"

rem python pytest module command line prefix
call :ABSPATH TEST_PYTHON_PYTEST_CMD_LINE_PREFIX "%%TEST_PYTHON_EXE%%" -B -m pytest

rem python search paths
set "PYTHONPATH=%EXTERNAL_TEST_SCRIPTS_ROOT:\=/%/pyscripts;%TESTS_ROOT:\=/%/pytests"

rem declare initialized
set __BATSCRIPT_INIT__=1

exit /b 0

:ABSPATH
if "%~3" == "" (
  set "%~1=%~f2"
) else set %~1="%~f2" %3 %4 %5 %6 %7 %8 %9
exit /b 0
