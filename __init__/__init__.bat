@echo off

if /i "%SVNCMD_ROOT_INIT0_DIR%" == "%~dp0" exit /b 0

set "SVNCMD_ROOT_INIT0_DIR=%~dp0"

if not defined NEST_LVL set NEST_LVL=0

if not defined SVNCMD_PROJECT_ROOT                call :CANONICAL_PATH SVNCMD_PROJECT_ROOT                "%%~dp0.."

if not defined CONTOOLS_ROOT                      call :CANONICAL_PATH CONTOOLS_ROOT                      "%%SVNCMD_PROJECT_ROOT%%/Tools"
if not defined CONTOOLS_BUILD_TOOLS_ROOT          call :CANONICAL_PATH CONTOOLS_BUILD_TOOLS_ROOT          "%%CONTOOLS_ROOT%%/build"
if not defined CONTOOLS_SQLITE_TOOLS_ROOT         call :CANONICAL_PATH CONTOOLS_SQLITE_TOOLS_ROOT         "%%CONTOOLS_ROOT%%/sqlite"
if not defined CONTOOLS_TESTLIB_ROOT              call :CANONICAL_PATH CONTOOLS_TESTLIB_ROOT              "%%CONTOOLS_ROOT%%/testlib"
if not defined CONTOOLS_XML_TOOLS_ROOT            call :CANONICAL_PATH CONTOOLS_XML_TOOLS_ROOT            "%%CONTOOLS_ROOT%%/xml"
if not defined CONTOOLS_VARS_ROOT                 call :CANONICAL_PATH CONTOOLS_VARS_ROOT                 "%%CONTOOLS_ROOT%%/vars"

if not defined SVNCMD_TOOLS_ROOT                  call :CANONICAL_PATH SVNCMD_TOOLS_ROOT                  "%%SVNCMD_PROJECT_ROOT%%/Scripts"

if not defined CONTOOLS_UTILITIES_ROOT            call :CANONICAL_PATH CONTOOLS_UTILITIES_ROOT            "%%SVNCMD_PROJECT_ROOT%%/Utilities"
if not defined CONTOOLS_UTILITIES_BIN_ROOT        call :CANONICAL_PATH CONTOOLS_UTILITIES_BIN_ROOT        "%%CONTOOLS_UTILITIES_ROOT%%/bin"
if not defined CONTOOLS_GNUWIN32_ROOT             call :CANONICAL_PATH CONTOOLS_GNUWIN32_ROOT             "%%CONTOOLS_UTILITIES_BIN_ROOT%%/gnuwin32"
if not defined CONTOOLS_UTILITIES_HASHDEEP_ROOT   call :CANONICAL_PATH CONTOOLS_UTILITIES_HASHDEEP_ROOT   "%%CONTOOLS_UTILITIES_BIN_ROOT%%/hashdeep"
if not defined CONTOOLS_UTILITIES_SQLITE_ROOT     call :CANONICAL_PATH CONTOOLS_UTILITIES_SQLITE_ROOT     "%%CONTOOLS_UTILITIES_BIN_ROOT%%/sqlite"

exit /b 0

:CANONICAL_PATH
setlocal DISABLEDELAYEDEXPANSION
set "RETURN_VALUE=%~dpf2"
set "RETURN_VALUE=%RETURN_VALUE:\=/%"
if "%RETURN_VALUE:~-1%" == "/" set "RETURN_VALUE=%RETURN_VALUE:~0,-1%"
(
  endlocal
  set "%~1=%RETURN_VALUE%"
)
exit /b 0
