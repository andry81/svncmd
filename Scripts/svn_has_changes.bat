@echo off

rem Author:   Andrey Dibrov (andry at inbox dot ru)

rem Description:
rem   Script do filter SVN status for changed versioned items or unversioned
rem   items.

rem Flags:
rem  -r - process externals recursively.
rem  -stat-exclude-? - exclude status lines for items not under version
rem     control (? prefixed) from "svn status" output.
rem  -stat-include-X - include status lines for unversioned directories created
rem     by an externals definition (X prefixed) from "svn status" output.
rem  -stat-exclude-versioned - exclude status lines for versioned files
rem     (not ? or X prefixed) from "svn status" output.
rem  By default, script does not print externals definition status lines
rem  (X prefixed) and does not use recursion on them.

rem Examples:
rem 1. call svn_has_changes.bat branch/current subdir/project1

rem Drop return value
set RETURN_VALUE=0

rem Drop last error level
cd .

setlocal

if 0%SVNCMD_TOOLS_DEBUG_VERBOCITY_LVL% GEQ 6 (echo.^>^>%0 %*) >&3

set "?~nx0=%~nx0"

rem exclude unversioned items
set FLAG_SVN_STATUS_EXCLUDE_?=0
set "FLAG_TEXT_SVN_STATUS_INCLUDE_?=?"
set "FLAG_TEXT_SVN_STATUS_EXCLUDE_?="
rem show externals status (status with the X character)
set FLAG_SVN_STATUS_INCLUDE_X=0
set "FLAG_TEXT_SVN_STATUS_INCLUDE_X="
set "FLAG_TEXT_SVN_STATUS_EXCLUDE_X=X"
rem read status inexternals recursively (by default, ignore externals status)
set FLAG_SVN_EXTERNALS_RECURSIVE=0
set "FLAG_TEXT_SVN_IGNORE_EXTERNALS=--ignore-externals"
rem exclude versioned changes
set FLAG_SVN_STATUS_EXCLUDE_VERSIONED=0

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if not "%FLAG%" == "" ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if not "%FLAG%" == "" (
  if "%FLAG%" == "-stat-exclude-?" (
    set FLAG_SVN_STATUS_EXCLUDE_?=1
    set "FLAG_TEXT_SVN_STATUS_INCLUDE_?="
    set "FLAG_TEXT_SVN_STATUS_EXCLUDE_?=?"
  ) else if "%FLAG%" == "-stat-include-X" (
    set FLAG_SVN_STATUS_INCLUDE_X=1
    set "FLAG_TEXT_SVN_STATUS_INCLUDE_X=X"
    set "FLAG_TEXT_SVN_STATUS_EXCLUDE_X="
  ) else if "%FLAG%" == "-r" (
    set FLAG_SVN_EXTERNALS_RECURSIVE=1
    set "FLAG_TEXT_SVN_IGNORE_EXTERNALS="
  ) else if "%FLAG%" == "-stat-exclude-versioned" (
    set FLAG_SVN_STATUS_EXCLUDE_VERSIONED=1
  ) else (
    echo.%?~nx0%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  goto FLAGS_LOOP
)

set "DIR_PATH_PREFIX=%~1"
set "DIR_PATH_SUBDIR=%~2"

if "%DIR_PATH_PREFIX%" == "" goto DIR_PATH_PREFIX_ERROR

set "DIR_PATH_PREFIX=%DIR_PATH_PREFIX:/=\%"

rem remove trailing back slash
if "%DIR_PATH_PREFIX:~-1%" == "\" set "DIR_PATH_PREFIX=%DIR_PATH_PREFIX:~0,-1%"

if not exist "%DIR_PATH_PREFIX%\" goto DIR_PATH_PREFIX_ERROR
goto DIR_PATH_PREFIX_END

:DIR_PATH_PREFIX_ERROR
(
  echo.%?~nx0%: error: directory does not exist: "%DIR_PATH_PREFIX%".
  exit /b -255
) >&2

:DIR_PATH_PREFIX_END

if "%DIR_PATH_SUBDIR%" == "" goto DIR_PATH_SUBDIR_END

set "DIR_PATH_SUBDIR=%DIR_PATH_SUBDIR:/=\%"

rem remove trailing back slash
if "%DIR_PATH_SUBDIR:~-1%" == "\" set "DIR_PATH_SUBDIR=%DIR_PATH_SUBDIR:~0,-1%"

if "%DIR_PATH_SUBDIR:~1,1%" == ":" goto DIR_PATH_SUBDIR_ERROR
if not exist "%DIR_PATH_PREFIX%\%DIR_PATH_SUBDIR%\" goto DIR_PATH_SUBDIR_ERROR
goto DIR_PATH_SUBDIR_END

:DIR_PATH_SUBDIR_ERROR
(
  echo.%?~nx0%: error: directory does not exist or not relative: "%DIR_PATH_PREFIX%\%DIR_PATH_SUBDIR%\".
  exit /b -254
) >&2

:DIR_PATH_SUBDIR_END

rem Svn status returns true unversioned items only if directory is a part of repository.
rem If the parent path of an external directory is not under version control and an external directory parent path is not the WC root path,
rem then the svn status will always report such component directories from the parent path as unversioned.
rem So instead of call to the script you must check unversioned items in the parent path through the shell.

rem always use not empty first filter
set FINDSTR_EXP_FIRST_FILTER= ^| findstr.exe /R /C:"^[ ACDIMR%FLAG_TEXT_SVN_STATUS_INCLUDE_X%%FLAG_TEXT_SVN_STATUS_INCLUDE_?%!~][ CM][ L][ +][ S%FLAG_TEXT_SVN_STATUS_INCLUDE_X%][ K][ KOTB][ C]."
set "FINDSTR_EXP_SECOND_FILTER="
if %FLAG_SVN_STATUS_EXCLUDE_VERSIONED% NEQ 0 (
  set FINDSTR_EXP_SECOND_FILTER= ^| findstr.exe /R /C:"^[%FLAG_TEXT_SVN_STATUS_INCLUDE_X%%FLAG_TEXT_SVN_STATUS_INCLUDE_?%]" /C:"^....[%FLAG_TEXT_SVN_STATUS_INCLUDE_X%]"
)

set "SVN_STATUS_FILE_PATH=%DIR_PATH_PREFIX%"
if not "%DIR_PATH_SUBDIR%" == "" set "SVN_STATUS_FILE_PATH=%SVN_STATUS_FILE_PATH%\%DIR_PATH_SUBDIR%"

rem findstr returns 0 on not empty list
( svn status "%SVN_STATUS_FILE_PATH%" --depth infinity %FLAG_TEXT_SVN_IGNORE_EXTERNALS% --non-interactive 2>nul || exit /b)%FINDSTR_EXP_FIRST_FILTER%%FINDSTR_EXP_SECOND_FILTER%

(
  endlocal
  if %ERRORLEVEL% EQU 0 set RETURN_VALUE=1
)

exit /b 0
