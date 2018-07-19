@echo off

rem Author:   Andrey Dibrov (andry at inbox dot ru)

rem Description:
rem   Script for remove SVN externals from the WC root by difference of 2
rem   externals list representing the state "before" (from) and the state
rem   "after" (to).

rem Examples:
rem 1. call svn_remove_externals.bat branch/current branch_workingset.lst ./proj1/proj1_subdir/ext_path to_externals.lst from_externals.lst

rem Drop last error level
type nul>nul

setlocal

if 0%SVNCMD_TOOLS_DEBUG_VERBOSITY_LVL% GEQ 2 (echo.^>^>%0 %*) >&3

call "%%~dp0__init__.bat" || goto :EOF

set "?~n0=%~n0"
set "?~nx0=%~nx0"

rem script flags
set FLAG_SVN_IGNORE_NESTED_EXTERNALS_LOCAL_CHANGES=0
set FLAG_SVN_AUTO_REVERT=0
set FLAG_SVN_REMOVE_UNCHANGED=0
set "BARE_FLAGS="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-ignore_nested_externals_local_changes" (
    set FLAG_SVN_IGNORE_NESTED_EXTERNALS_LOCAL_CHANGES=1
    set BARE_FLAGS=%BARE_FLAGS% %1
    shift
  ) else if "%FLAG%" == "-ar" (
    set FLAG_SVN_AUTO_REVERT=1
    set BARE_FLAGS=%BARE_FLAGS% %1
    shift
  ) else if "%FLAG%" == "-remove_unchanged" (
    set FLAG_SVN_REMOVE_UNCHANGED=1
    shift
  ) else (
    echo.%?~nx0%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  rem read until no flags
  goto FLAGS_LOOP
)

set "SYNC_BRANCH_PATH=%~1"
set "SYNC_BRANCH_PATH_ABS=%~dpf1"
set "WORKINGSET_FILE=%~2"
set "WCROOT_PATH=%~3"
set "WCROOT_PATH_ABS=%~dpf3"
set "TO_EXTERNALS_LIST=%~4"
set "FROM_EXTERNALS_LIST=%~5"

if not defined SYNC_BRANCH_PATH goto NO_SYNC_BRANCH_PATH
if not exist "%SYNC_BRANCH_PATH%\" goto NO_SYNC_BRANCH_PATH

goto NO_SYNC_BRANCH_PATH_END
:NO_SYNC_BRANCH_PATH
(
  echo.%?~nx0%: error: branch path does not exist: SYNC_BRANCH_PATH="%SYNC_BRANCH_PATH%".
  exit /b 1
) >&2
:NO_SYNC_BRANCH_PATH_END

if not defined WORKINGSET_FILE goto NO_WORKINGSET_FILE
if not exist "%WORKINGSET_FILE%" goto NO_WORKINGSET_FILE

goto NO_WORKINGSET_FILE_END
:NO_WORKINGSET_FILE
(
  echo.%?~nx0%: error: workingset file does not exist: WORKINGSET_FILE="%WORKINGSET_FILE%".
  exit /b 2
) >&2
:NO_WORKINGSET_FILE_END

if not defined WCROOT_PATH goto ERROR_WCROOT_PATH
if "%WCROOT_PATH:~1,1%" == ":" goto ERROR_WCROOT_PATH
call :SET_WCROOT_PATH_ABS "%%SYNC_BRANCH_PATH_ABS%%/%%WCROOT_PATH%%"

goto SET_WCROOT_PATH_ABS_END

:SET_WCROOT_PATH_ABS
set "WCROOT_PATH_ABS=%~dpf1"
exit /b 0

:SET_WCROOT_PATH_ABS_END

if not exist "%WCROOT_PATH_ABS%/.svn/wc.db" goto ERROR_WCROOT_PATH

goto ERROR_WCROOT_PATH_END
:ERROR_WCROOT_PATH
(
  echo.%?~nx0%: error: SVN WC root path is not relative or does not exist or is not under version control: WCROOT_PATH="%WCROOT_PATH%" SYNC_BRANCH_PATH="%SYNC_BRANCH_PATH_ABS%".
  exit /b 3
) >&2
:ERROR_WCROOT_PATH_END

if not defined TO_EXTERNALS_LIST goto ERROR_TO_EXTERNALS_LIST
if not exist "%TO_EXTERNALS_LIST%" goto ERROR_TO_EXTERNALS_LIST

goto ERROR_TO_EXTERNALS_LIST_END
:ERROR_TO_EXTERNALS_LIST
(
  echo.%?~nx0%: error: externals file list does not exist: TO_EXTERNALS_LIST="%TO_EXTERNALS_LIST%".
  exit /b 4
) >&2
:ERROR_TO_EXTERNALS_LIST_END

if not defined FROM_EXTERNALS_LIST goto ERROR_FROM_EXTERNALS_LIST
if not exist "%FROM_EXTERNALS_LIST%" goto ERROR_FROM_EXTERNALS_LIST

goto ERROR_FROM_EXTERNALS_LIST_END
:ERROR_FROM_EXTERNALS_LIST
(
  echo.%?~nx0%: error: externals file list does not exist: FROM_EXTERNALS_LIST="%FROM_EXTERNALS_LIST%".
  exit /b 5
) >&2
:ERROR_FROM_EXTERNALS_LIST_END

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%"

set "SYNC_EXTERNALS_DIFF_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\$externals_diff.lst"
set "EXTERNAL_INFO_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\$info.txt"

call :MAIN
set LASTERROR=%ERRORLEVEL%

rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

exit /b %LASTERROR%

:MAIN

rem generate externals difference file
call "%%SVNCMD_TOOLS_ROOT%%/gen_diff_svn_externals.bat" "%%TO_EXTERNALS_LIST%%" "%%FROM_EXTERNALS_LIST%%" "%%SYNC_EXTERNALS_DIFF_LIST_FILE_TMP%%"
if %ERRORLEVEL% GTR 0 (
  echo.%?~nx0%: error: invalid svn:externals file lists: ERROR="%ERRORLEVEL%" TO_EXTERNALS="%TO_EXTERNALS_LIST%" FROM_EXTERNALS="%FROM_EXTERNALS_LIST%".
  exit /b 20
) >&2

if %ERRORLEVEL% NEQ 0 exit /b 0

set "WC_ID="
for /F "usebackq eol=	 tokens=* delims=" %%i in (`call "%%SQLITE_TOOLS_ROOT%%/sqlite.bat" -batch "%%WCROOT_PATH_ABS%%/.svn/wc.db" ".headers off" "select id from "WCROOT" where local_abspath is null or local_abspath = ''"`) do set "WC_ID=%%i"
if not defined WC_ID (
  echo.%?~nx0%: error: SVN database `WCROOT id` request has failed: "%WCROOT_PATH%/.svn/wc.db" SYNC_BRANCH_PATH="%SYNC_BRANCH_PATH_ABS%".
  exit /b 21
) >&2

rem externals has differences, remove external directories required to be removed
for /F "usebackq eol=# tokens=1,2,3 delims=|" %%i in (`sort /R "%SYNC_EXTERNALS_DIFF_LIST_FILE_TMP%"`) do (
  set "EXTERNAL_DIR_PATH_PREFIX=%%j"
  set "EXTERNAL_DIR_PATH=%%k"
  if "%%i" == "-" (
    call :PROCESS_REMOVE || goto :EOF
  ) else if "%%i" == " " (
    if %FLAG_SVN_REMOVE_UNCHANGED% NEQ 0 ( call :PROCESS_REMOVE || goto :EOF )
  )
)

exit /b 0

:PROCESS_REMOVE
setlocal

if not "%EXTERNAL_DIR_PATH_PREFIX%" == "." (
  set "EXTERNAL_BRANCH_PATH_PREFIX=%EXTERNAL_DIR_PATH_PREFIX%/%EXTERNAL_DIR_PATH%"
) else (
  set "EXTERNAL_BRANCH_PATH_PREFIX=%EXTERNAL_DIR_PATH%"
)

set "EXTERNAL_BRANCH_PATH_TO_REMOVE=%WCROOT_PATH_ABS:\=/%/%EXTERNAL_BRANCH_PATH_PREFIX%"

rem check branch changes status
call "%%SVNCMD_TOOLS_ROOT%%/svn_has_changes.bat" -stat-exclude-? "%%EXTERNAL_BRANCH_PATH_TO_REMOVE%%" || ( popd & exit /b 41 )

if %RETURN_VALUE% NEQ 0 ^
if %FLAG_SVN_AUTO_REVERT% EQU 0 (
  rem being removed external directory has differences but the auto revert flag is not set
  echo.%?~nx0%: error: external directory has differences, manual branch revert is required: EXTERNAL_DIR="%EXTERNAL_DIR_PATH_PREFIX%/%EXTERNAL_DIR_PATH%" WCROOT_PATH="%WCROOT_PATH%" SYNC_BRANCH_PATH="%SYNC_BRANCH_PATH_ABS%".
  exit /b 42
) >&2

pushd "%EXTERNAL_BRANCH_PATH_TO_REMOVE%" && (
  svn info . --non-interactive > "%EXTERNAL_INFO_FILE_TMP%" || ( popd & exit /b 50 )
  popd
)

call "%%SVNCMD_TOOLS_ROOT%%/extract_info_param.bat" "%%EXTERNAL_INFO_FILE_TMP%%" "Repository UUID"
set "EXTERNAL_BRANCH_REPOSITORY_UUID=%RETURN_VALUE%"
if not defined EXTERNAL_BRANCH_REPOSITORY_UUID (
  echo.%?~nx0%: error: `Repository UUID` property is not found in temporary SVN info file requested from the branch: BRANCH_PATH="%SYNC_BRANCH_PATH_TO_REMOVE%".
  exit /b 51
) >&2

set "REPOS_ID="
for /F "usebackq eol=	 tokens=* delims=" %%i in (`call "%%SQLITE_TOOLS_ROOT%%/sqlite.bat" -batch "%%EXTERNAL_BRANCH_PATH_TO_REMOVE%%/.svn/wc.db" ".headers off" "select id from "REPOSITORY" where uuid='%%EXTERNAL_BRANCH_REPOSITORY_UUID%%'"`) do set "REPOS_ID=%%i"
if not defined REPOS_ID (
  echo.%?~nx0%: error: SVN database `REPOSITORY id` request has failed: "%EXTERNAL_BRANCH_PATH_TO_REMOVE%/.svn/wc.db".
  exit /b 52
) >&2

if %FLAG_SVN_IGNORE_NESTED_EXTERNALS_LOCAL_CHANGES% NEQ 0 goto IGNORE_NESTED_EXTERNALS_LOCAL_CHANGES

call "%%SVNCMD_TOOLS_ROOT%%/svn_remove_external.bat"%%BARE_FLAGS%% "%%SYNC_BRANCH_PATH%%" "%%WORKINGSET_FILE%%" "%%WCROOT_PATH%%" "%%EXTERNAL_DIR_PATH_PREFIX%%" "%%EXTERNAL_DIR_PATH%%" "%%REPOS_ID%%" "%%WC_ID%%"
if %ERRORLEVEL% NEQ 0 (
  echo.%?~nx0%: error: external branch directory remove has failed: ERROR="%ERRORLEVEL%" EXTERNAL_BRANCH_PATH="%EXTERNAL_BRANCH_PATH_PREFIX%" WCROOT_PATH="%WCROOT_PATH%" SYNC_BRANCH_PATH="%SYNC_BRANCH_PATH_ABS%".
  exit /b 60
) >&2

exit /b 0

:IGNORE_NESTED_EXTERNALS_LOCAL_CHANGES
call "%%SVNCMD_TOOLS_ROOT%%/svn_remove_external_unchanged_dir.bat" "%%WCROOT_PATH_ABS%%" "%%EXTERNAL_DIR_PATH_PREFIX%%" "%%EXTERNAL_DIR_PATH%%"
if %ERRORLEVEL% NEQ 0 (
  echo.%?~nx0%: error: external branch empty directory remove has failed: ERROR="%ERRORLEVEL%" EXTERNAL_BRANCH_PATH="%EXTERNAL_BRANCH_PATH_PREFIX%" WCROOT_PATH="%WCROOT_PATH%" SYNC_BRANCH_PATH="%SYNC_BRANCH_PATH_ABS%".
  exit /b 61
) >&2

exit /b 0
