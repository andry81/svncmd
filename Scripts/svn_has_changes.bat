@echo off

rem Author:   Andrey Dibrov (andry at inbox dot ru)

rem Description:
rem   Script do filter SVN status for changed versioned items or unversioned
rem   items.

rem Flags:
rem  -stat-exclude-? - exclude status lines for unversionned files (? prefixed) from "svn status" output.
rem  -stat-exclude-versioned - exclude status lines for versionned files (non ? prefixed) from "svn status" output.
rem     Versioned items has inclusion priority over unversioned items.

rem Examples:
rem 1. call svn_has_changes.bat branch/current subdir/project1

rem Drop return value
set RETURN_VALUE=0

rem Drop last error level
cd .

setlocal

if 0%SVNCMD_TOOLS_DEBUG_VERBOCITY_LVL% GEQ 6 (echo.^>^>%0 %*) >&3

set "?~nx0=%~nx0"

rem script flags
set FLAG_SVN_STATUS_EXCLUDE_?=0
set FLAG_SVN_STATUS_EXCLUDE_VERSIONED=0

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if not "%FLAG%" == "" ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if not "%FLAG%" == "" (
  if "%FLAG%" == "-stat-exclude-?" (
    set FLAG_SVN_STATUS_EXCLUDE_?=1
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

if %FLAG_SVN_STATUS_EXCLUDE_?% NEQ 0 set FLAG_SVN_STATUS_EXCLUDE_VERSIONED=0

set "DIR_PATH_PREFIX=%~1"
set "DIR_PATH_SUBDIR=%~2"

if "%DIR_PATH_PREFIX%" == "" goto DIR_PATH_PREFIX_ERROR
if not exist "%DIR_PATH_PREFIX%\" goto DIR_PATH_PREFIX_ERROR
goto DIR_PATH_PREFIX_END

:DIR_PATH_PREFIX_ERROR
(
  echo.%?~nx0%: error: directory does not exist: "%DIR_PATH_PREFIX%".
  exit /b 1
) >&2

:DIR_PATH_PREFIX_END

if "%DIR_PATH_SUBDIR%" == "" goto DIR_PATH_SUBDIR_END
if "%DIR_PATH_SUBDIR:~1,1%" == ":" goto DIR_PATH_SUBDIR_ERROR
if not exist "%DIR_PATH_PREFIX%\%DIR_PATH_SUBDIR%\" goto DIR_PATH_SUBDIR_ERROR
goto DIR_PATH_SUBDIR_END

:DIR_PATH_SUBDIR_ERROR
(
  echo.%?~nx0%: error: directory does not exist or not relative: "%DIR_PATH_PREFIX%\%DIR_PATH_SUBDIR%\".
  exit /b 2
) >&2

:DIR_PATH_SUBDIR_END

rem Svn status returns true unversioned items only if directory is a part of repository.
rem If the parent path of an external directory is not under version control and an external directory parent path is not the WC root path,
rem then the svn status will always report such component directories from the parent path as unversioned.
rem So instead of call to the script you must check unversioned items in the parent path through the shell.

rem escape findstr.exe special control characters
if "%DIR_PATH_SUBDIR%" == "" goto IGNORE_DIR_PATH_SUBDIR

set "DIR_PATH_SUBDIR=%DIR_PATH_SUBDIR:\=\\%"
set "DIR_PATH_SUBDIR=%DIR_PATH_SUBDIR:.=\.%"
set "DIR_PATH_SUBDIR=%DIR_PATH_SUBDIR:[=\[%"
set "DIR_PATH_SUBDIR=%DIR_PATH_SUBDIR:]=\]%"
set "DIR_PATH_SUBDIR=%DIR_PATH_SUBDIR:^=\^%"
set "DIR_PATH_SUBDIR=%DIR_PATH_SUBDIR:$=\$%"

:IGNORE_DIR_PATH_SUBDIR

rem always use not empty first filter
set "FINDSTR_EXP_FIRST_FILTER=^| findstr.exe /R /C:"^[^? 	]"
set "FINDSTR_EXP_SECOND_FILTER="
if %FLAG_SVN_STATUS_EXCLUDE_?% NEQ 0 (
  set FINDSTR_EXP_FIRST_FILTER= ^| findstr.exe /R /V /C:"^?"
  if not "%DIR_PATH_SUBDIR%" == "" set FINDSTR_EXP_SECOND_FILTER= ^| findstr.exe /R /C:"^[^? 	]*[ 	][ 	]*%DIR_PATH_SUBDIR%$"
) else if %FLAG_SVN_STATUS_EXCLUDE_VERSIONED% NEQ 0 (
  set FINDSTR_EXP_FIRST_FILTER=^| findstr.exe /R /C:"^?"
  if not "%DIR_PATH_SUBDIR%" == "" set FINDSTR_EXP_SECOND_FILTER= ^| findstr.exe /R /C:"^?[^ 	]*[ 	][ 	]*%DIR_PATH_SUBDIR%$"
) else (
  if not "%DIR_PATH_SUBDIR%" == "" set FINDSTR_EXP_SECOND_FILTER= ^| findstr.exe /R /C:"^[^? 	]*[ 	][ 	]*%DIR_PATH_SUBDIR%$"
)

rem findstr returns 0 on not empty list
( svn status "%DIR_PATH_PREFIX%" --depth infinity --non-interactive 2>nul || exit /b 3 )%FINDSTR_EXP_FIRST_FILTER%%FINDSTR_EXP_SECOND_FILTER%

(
  endlocal
  if %ERRORLEVEL% EQU 0 set RETURN_VALUE=1
)

exit /b 0
