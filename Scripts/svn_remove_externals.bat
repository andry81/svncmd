@echo off

rem Author:   Andrey Dibrov (andry at inbox dot ru)

rem Description:
rem   Script remove SVN externals by list.

rem Examples:
rem 1. call svn_remove_external.bat branch/current rel_dir ext_path 771a6eda-33e6-498b-82b5-7144d63c2b48 1

rem Drop last error level
cd .

setlocal

call "%%~dp0__init__.bat" || goto :EOF

set "?~nx0=%~nx0"

rem script flags
set FLAG_SVN_AUTO_REVERT=0
set FLAG_SVN_REMOVE_UNCHANGED=0

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if not "%FLAG%" == "" ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if not "%FLAG%" == "" (
  if "%FLAG%" == "-ar" (
    set FLAG_SVN_AUTO_REVERT=1
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

set "WORKINGSET_FILE=%~1"
set "WCROOT_PATH=%~2"
set "TO_EXTERNALS_LIST=%~3"
set "FROM_EXTERNALS_LIST=%~4"

if "%WORKINGSET_FILE%" == "" goto NO_WORKINGSET_FILE
if not exist "%WORKINGSET_FILE%" (
  echo.%?~nx0%: error: workingset file does not exist: WORKINGSET_FILE="%WORKINGSET_FILE%".
  exit /b 1
) >&2

:NO_WORKINGSET_FILE

if "%WCROOT_PATH%" == "" goto ERROR_WCROOT_PATH
if not exist "%WCROOT_PATH%\.svn\wc.db" (
  :ERROR_WCROOT_PATH
  (
    echo.%?~nx0%: error: SVN WC root path does not exist or is not versioned: WCROOT_PATH="%WCROOT_PATH%".
    exit /b 2
  ) >&2
)

if "%TO_EXTERNALS_LIST%" == "" goto ERROR_TO_EXTERNALS_LIST
if not exist "%TO_EXTERNALS_LIST%" (
  :ERROR_TO_EXTERNALS_LIST
  (
    echo.%?~nx0%: error: externals file list does not exist: TO_EXTERNALS_LIST="%TO_EXTERNALS_LIST%".
    exit /b 3
  ) >&2
)

if "%FROM_EXTERNALS_LIST%" == "" goto ERROR_FROM_EXTERNALS_LIST
if not exist "%FROM_EXTERNALS_LIST%" (
  :ERROR_FROM_EXTERNALS_LIST
  (
    echo.%?~nx0%: error: externals file list does not exist: FROM_EXTERNALS_LIST="%FROM_EXTERNALS_LIST%".
    exit /b 4
  ) >&2
)

call "%%CONTOOLS_ROOT%%/get_datetime.bat"
set "SYNC_DATE=%RETURN_VALUE:~0,4%_%RETURN_VALUE:~4,2%_%RETURN_VALUE:~6,2%"
set "SYNC_TIME=%RETURN_VALUE:~8,2%_%RETURN_VALUE:~10,2%_%RETURN_VALUE:~12,2%_%RETURN_VALUE:~15,3%"

set "SYNC_TEMP_FILE_DIR=%TEMP%\%?~n0%.%SYNC_DATE%.%SYNC_TIME%"
set "SYNC_EXTERNALS_DIFF_LIST_FILE_TMP=%SYNC_TEMP_FILE_DIR%\$externals_diff.lst"
set "EXTERNAL_DIFF_FILE_TMP=%SYNC_TEMP_FILE_DIR%\$diff.patch"
set "EXTERNAL_INFO_FILE_TMP=%SYNC_TEMP_FILE_DIR%\$info.txt"

rem create temporary files to store local context output
if exist "%SYNC_TEMP_FILE_DIR%\" (
  echo.%?~nx0%: error: temporary generated directory SYNC_TEMP_FILE_DIR already exist: "%SYNC_TEMP_FILE_DIR%"
  exit /b 10
) >&2

mkdir "%SYNC_TEMP_FILE_DIR%" || (
  echo.%?~nx0%: error: could not create temporary diretory: "%SYNC_TEMP_FILE_DIR%"
  exit /b 11
) >&2

call :MAIN
set LASTERROR=%ERRORLEVEL%

rem cleanup temporary files
rmdir /S /Q "%SYNC_TEMP_FILE_DIR%"

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
for /F "usebackq eol= tokens=* delims=" %%i in (`call "%%SQLITE_TOOLS_ROOT%%/sqlite.bat" -batch "%%WCROOT_PATH%%/.svn/wc.db" ".headers off" "select id from "WCROOT" where local_abspath is null or local_abspath = ''"`) do set "WC_ID=%%i"
if "%WC_ID%" == "" (
  echo.%?~nx0%: error: SVN database `WCROOT id` request has failed: "%WCROOT_PATH%/.svn/wc.db".
  exit /b 21
) >&2

rem externals has differences, search for removed externals
for /F "usebackq eol=# tokens=1,2,3 delims=|" %%i in ("%SYNC_EXTERNALS_DIFF_LIST_FILE_TMP%") do (
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

set "EXTERNAL_PATH_TO_REMOVE=%WCROOT_PATH%/%EXTERNAL_DIR_PATH_PREFIX%/%EXTERNAL_DIR_PATH%"

if exist "%EXTERNAL_PATH_TO_REMOVE%\.svn\" goto PROCESS_SVN_REMOVE_EXTERNAL

call "%%CONTOOLS_ROOT%%/svn_remove_external_dir.bat" "%%WCROOT_PATH%%" "%%EXTERNAL_DIR_PATH_PREFIX%%/%%EXTERNAL_DIR_PATH%%" || (
  echo.%?~nx0%: error: external directory remove has failed: EXTERNAL_DIR="%EXTERNAL_DIR_PATH_PREFIX%/%EXTERNAL_DIR_PATH%" WCROOT_PATH="%WCROOT_PATH%".
  exit /b 40
)

exit /b 0

:PROCESS_SVN_REMOVE_EXTERNAL
rem create an external base revision branch difference file to compare with
pushd "%EXTERNAL_PATH_TO_REMOVE%" && (
  svn diff -r BASE . --non-interactive > "%EXTERNAL_DIFF_FILE_TMP%" || ( popd & exit /b 41 )
  popd
)

rem get branch difference file size before update
call "%%CONTOOLS_ROOT%%/get_filesize.bat" "%%EXTERNAL_DIFF_FILE_TMP%%"

if %ERRORLEVEL% NEQ 0 ^
if %FLAG_SVN_AUTO_REVERT% EQU 0 (
  rem being removed external directory has differences but the auto revert flag is not set
  echo.%?~nx0%: error: external directory has differences, manual branch revert is required: EXTERNAL_DIR="%EXTERNAL_DIR_PATH_PREFIX%/%EXTERNAL_DIR_PATH%" WCROOT_PATH="%WCROOT_PATH%".
  exit /b 42
) >&2

pushd "%EXTERNAL_PATH_TO_REMOVE%" && (
  svn info -r BASE . --non-interactive > "%EXTERNAL_INFO_FILE_TMP%" || ( popd & exit /b 50 )
  popd
)

call "%%SVNCMD_TOOLS_ROOT%%/extract_info_param.bat" "%%EXTERNAL_INFO_FILE_TMP%%" "Repository UUID"
set "EXTERNAL_BRANCH_REPOSITORY_UUID=%RETURN_VALUE%"
if "%EXTERNAL_BRANCH_REPOSITORY_UUID%" == "" (
  echo.%?~nx0%: error: `Repository UUID` property is not found in temporary SVN info file requested from the branch: BRANCH_PATH="%SYNC_BRANCH_PATH_TO_REMOVE%".
  exit /b 51
) >&2

set "REPOS_ID="
for /F "usebackq eol= tokens=* delims=" %%i in (`call "%%SQLITE_TOOLS_ROOT%%/sqlite.bat" -batch "%%EXTERNAL_PATH_TO_REMOVE%%/.svn/wc.db" ".headers off" "select id from "REPOSITORY" where uuid='%%EXTERNAL_BRANCH_REPOSITORY_UUID%%'"`) do set "REPOS_ID=%%i"
if "%REPOS_ID%" == "" (
  echo.%?~nx0%: error: SVN database `REPOSITORY id` request has failed: "%EXTERNAL_PATH_TO_REMOVE%/.svn/wc.db".
  exit /b 52
) >&2

call "%%SVNCMD_TOOLS_ROOT%%/svn_remove_external.bat" %%FLAG_TEXT_SVN_AUTO_REVERT%% "%%WCROOT_PATH%%" "%%EXTERNAL_DIR_PATH_PREFIX%%" "%%EXTERNAL_DIR_PATH%%" "%%REPOS_ID%%" "%%WC_ID%%" "%%TO_REV%%" || exit /b 60

exit /b 0
