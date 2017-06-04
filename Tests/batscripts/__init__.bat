@echo off

if "%__NEST_LVL%" == "" set __NEST_LVL=0

if %__NEST_LVL% GTR 0 exit /b 0

set __PASSED_TESTS=0
set __OVERALL_TESTS=0

set "TESTS_ROOT=%~dp0"
set "TESTS_ROOT=%TESTS_ROOT:\=/%"
if "%TESTS_ROOT:~-1%" == "/" set "TESTS_ROOT=%TESTS_ROOT:~0,-1%"

rem override some values
set "SVNCMD_TOOLS_ROOT=%TESTS_ROOT%/../../Scripts"
set "SVNCMD_TOOLS_ROOT=%SVNCMD_TOOLS_ROOT:\=/%"
if "%SVNCMD_TOOLS_ROOT:~-1%" == "/" set "SVNCMD_TOOLS_ROOT=%SVNCMD_TOOLS_ROOT:~0,-1%"

rem initialize Tools "module"
call "%%TESTS_ROOT%%/../../Tools/__init__.bat" || goto :EOF

set "TEST_SRC_BASE_DIR=%~dp0"
set "TEST_SRC_BASE_DIR=%TEST_SRC_BASE_DIR:~0,-1%"

set "TEST_DATA_BASE_DIR=%TEST_SRC_BASE_DIR%\_testdata"
set "TEST_TEMP_BASE_DIR=%TEST_SRC_BASE_DIR%\..\..\Temp"

call :GET_ABSOLUTE_PATH "%%TEST_DATA_BASE_DIR%%"
set "TEST_DATA_BASE_DIR=%RETURN_VALUE%"

exit /b 0

:GET_ABSOLUTE_PATH
set "RETURN_VALUE=%~dpf1"
exit /b 0

