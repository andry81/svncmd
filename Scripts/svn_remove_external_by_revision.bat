@echo off

rem Author:   Andrey Dibrov (andry at inbox dot ru)

rem Description:
rem   Script for remove a single SVN external from the WC root between base
rem   revision and the target revision.

rem Examples:
rem 1. call svn_remove_external_by_revision.bat branch/current 100 ./proj1 proj1_subdir ext_path 1 1

rem Drop last error level
type nul>nul

setlocal

if 0%SVNCMD_TOOLS_DEBUG_VERBOSITY_LVL% GEQ 2 (echo.^>^>%0 %*) >&3

call "%%~dp0__init__.bat" || exit /b

call "%%SVNCMD_PROJECT_ROOT%%/__init__/declare_builtins.bat" %%0 %%*

rem script flags
set FLAG_SVN_IGNORE_NESTED_EXTERNALS_LOCAL_CHANGES=0
set "FLAG_TEXT_SVN_EXTERNALS_RECURSIVE=-R"
set FLAG_SVN_AUTO_REVERT=0
set FLAG_SVN_NESTED_ONLY=0
set "BARE_FLAGS="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-ignore_nested_externals_local_changes" (
    set FLAG_SVN_IGNORE_NESTED_EXTERNALS_LOCAL_CHANGES=1
    set "FLAG_TEXT_SVN_EXTERNALS_RECURSIVE="
    set BARE_FLAGS=%BARE_FLAGS% %1
    shift
  ) else if "%FLAG%" == "-ar" (
    set FLAG_SVN_AUTO_REVERT=1
    set BARE_FLAGS=%BARE_FLAGS% %1
    shift
  ) else if "%FLAG%" == "-nested_only" (
    set FLAG_SVN_NESTED_ONLY=1
    shift
  ) else (
    echo.%?~nx0%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  rem read until no flags
  goto FLAGS_LOOP
)

set "SYNC_BRANCH_PATH=%~1"
set "SYNC_BRANCH_PATH_ABS=%~f1"
set "REVISION=%~2"
set "WCROOT_PATH=%~3"
set "WCROOT_PATH_ABS=%~f3"
set "EXTERNAL_DIR_PATH_PREFIX=%~4"
set "EXTERNAL_DIR_PATH=%~5"
set "REPOS_ID=%~6"
set "WC_ID=%~7"

if not defined SYNC_BRANCH_PATH goto NO_SYNC_BRANCH_PATH
if not exist "%SYNC_BRANCH_PATH%\" goto NO_SYNC_BRANCH_PATH

goto NO_SYNC_BRANCH_PATH_END
:NO_SYNC_BRANCH_PATH
(
  echo.%?~nx0%: error: branch path does not exist: SYNC_BRANCH_PATH="%SYNC_BRANCH_PATH%".
  exit /b 1
) >&2
:NO_SYNC_BRANCH_PATH_END

if not defined REVISION goto INVALID_REVISION
if %REVISION% EQU 0 goto INVALID_REVISION

goto INVALID_REVISION_END
:INVALID_REVISION
(
  echo.%?~nx0%: error: invalid revision: REVISION="%REVISION%".
  exit /b 2
) >&2
:INVALID_REVISION_END

if not defined WCROOT_PATH goto ERROR_WCROOT_PATH
if "%WCROOT_PATH:~1,1%" == ":" goto ERROR_WCROOT_PATH
call :SET_WCROOT_PATH_ABS "%%SYNC_BRANCH_PATH_ABS%%/%%WCROOT_PATH%%"

goto SET_WCROOT_PATH_ABS_END

:SET_WCROOT_PATH_ABS
set "WCROOT_PATH_ABS=%~f1"
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

if %FLAG_SVN_NESTED_ONLY% NEQ 0 (
  if not defined EXTERNAL_DIR_PATH_PREFIX set EXTERNAL_DIR_PATH_PREFIX=.
  if not defined EXTERNAL_DIR_PATH set EXTERNAL_DIR_PATH=.
)

if not "%EXTERNAL_DIR_PATH_PREFIX%" == "." (
  set "EXTERNAL_BRANCH_PATH_PREFIX=%EXTERNAL_DIR_PATH_PREFIX%/%EXTERNAL_DIR_PATH%"
) else if not "%EXTERNAL_DIR_PATH%" == "." (
  set "EXTERNAL_BRANCH_PATH_PREFIX=%EXTERNAL_DIR_PATH%"
) else set EXTERNAL_BRANCH_PATH_PREFIX=.

if not "%EXTERNAL_DIR_PATH_PREFIX%" == "." (
  set "EXTERNAL_BRANCH_PATH=%WCROOT_PATH:\=/%/%EXTERNAL_BRANCH_PATH_PREFIX%"
  set "EXTERNAL_BRANCH_PATH_ABS=%WCROOT_PATH_ABS:\=/%/%EXTERNAL_BRANCH_PATH_PREFIX%"
) else (
  set "EXTERNAL_BRANCH_PATH=%WCROOT_PATH:\=/%"
  set "EXTERNAL_BRANCH_PATH_ABS=%WCROOT_PATH_ABS:\=/%"
)

if %FLAG_SVN_NESTED_ONLY% NEQ 0 goto IGNORE_EXTERNAL_DIR_PREFIX

if not defined EXTERNAL_DIR_PATH_PREFIX goto ERROR_EXTERNAL_BRANCH_PATH
if not defined EXTERNAL_DIR_PATH goto ERROR_EXTERNAL_BRANCH_PATH
if not exist "%EXTERNAL_BRANCH_PATH_ABS%/.svn/wc.db" goto ERROR_EXTERNAL_BRANCH_PATH

goto ERROR_EXTERNAL_BRANCH_PATH_END
:ERROR_EXTERNAL_BRANCH_PATH
(
  echo.%?~nx0%: error: external branch path does not exist or is not under version control: EXTERNAL_BRANCH_PATH="%EXTERNAL_BRANCH_PATH_PREFIX%" WCROOT_PATH="%WCROOT_PATH%" SYNC_BRANCH_PATH="%SYNC_BRANCH_PATH_ABS%".
  exit /b 4
) >&2
:ERROR_EXTERNAL_BRANCH_PATH_END

if not defined REPOS_ID (
  echo.%?~nx0%: error: invalid REPOS_ID: REPOS_ID="%REPOS_ID%" EXTERNAL_BRANCH_PATH="%EXTERNAL_BRANCH_PATH_PREFIX%" WCROOT_PATH="%WCROOT_PATH%" SYNC_BRANCH_PATH="%SYNC_BRANCH_PATH_ABS%".
  exit /b 5
) >&2

if not defined WC_ID (
  echo.%?~nx0%: error: invalid WC_ID: WC_ID="%WC_ID%" EXTERNAL_BRANCH_PATH="%EXTERNAL_BRANCH_PATH_PREFIX%" WCROOT_PATH="%WCROOT_PATH%" SYNC_BRANCH_PATH="%SYNC_BRANCH_PATH_ABS%".
  exit /b 6
) >&2

:IGNORE_EXTERNAL_DIR_PREFIX
call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%"

set "BRANCH_FROM_EXTERNALS_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\$externals_from.txt"
set "BRANCH_FROM_EXTERNALS_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\$externals_from.lst"
set "BRANCH_TO_EXTERNALS_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\$externals_to.txt"
set "BRANCH_TO_EXTERNALS_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\$externals_to.lst"
set "BRANCH_TO_EXTERNALS_INFO_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\$info_externals_to.txt"
set "BRANCH_FILES_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\$files.lst"

call :MAIN
set LASTERROR=%ERRORLEVEL%

rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

exit /b %LASTERROR%

:MAIN

echo BRANCH_LOCAL_REL_PATH=%BRANCH_LOCAL_REL_PATH%
if "%EXTERNAL_DIR_PATH_PREFIX%" == "." (
  set "BRANCH_LOCAL_REL_PATH=%EXTERNAL_DIR_PATH%"
  set "BRANCH_DEF_LOCAL_REL_PATH="
) else (
  set "BRANCH_LOCAL_REL_PATH=%EXTERNAL_DIR_PATH_PREFIX%/%EXTERNAL_DIR_PATH%"
  set "BRANCH_DEF_LOCAL_REL_PATH=%EXTERNAL_DIR_PATH_PREFIX%"
)

call "%%CONTOOLS_ROOT%%/filesys/split_pathstr.bat" "%%BRANCH_LOCAL_REL_PATH%%" / "" BRANCH_PARENT_REL_PATH

pushd "%WCROOT_PATH_ABS%" && (
  rem remove nested externals recursively
  call :SVN_REMOVE_EXTERNALS || ( popd & exit /b )
  if %FLAG_SVN_NESTED_ONLY% EQU 0 (
    rem remove all versioned files and directories in the external directory
    call :SVN_REMOVE_BY_LIST || ( popd & exit /b )
    rem remove parent path of the external directory if no unversioned files on the way
    call :REMOVE_EXTERNAL_UNCHANGED_DIR_PATH || ( popd & exit /b )
    rem remove record from the WC EXTERNALS table to unlink the external directory from the WC root.
    call :REMOVE_WCROOT_EXTERNAL || ( popd & exit /b )
  )
  popd
)

exit /b 0

:SVN_REMOVE_EXTERNALS
echo 1 EXTERNAL_BRANCH_PATH_ABS=%EXTERNAL_BRANCH_PATH_ABS%
pushd "%EXTERNAL_BRANCH_PATH_ABS%" && (
  rem from externals
  svn pget svn:externals . -R --non-interactive > "%BRANCH_FROM_EXTERNALS_FILE_TMP%" || ( popd & exit /b 30 )

  svn pget svn:externals -r "%REVISION%" . -R --non-interactive > "%BRANCH_TO_EXTERNALS_FILE_TMP%" || ( popd & exit /b 31 )

  rem to retrieve URL for externals under particular revision
  svn info -r "%REVISION%" . --non-interactive > "%BRANCH_TO_EXTERNALS_INFO_FILE_TMP%" || ( popd & exit /b 32 )

  popd
)

echo 1
rem read temporary info file
call "%%SVNCMD_TOOLS_ROOT%%/extract_info_param.bat" "%%BRANCH_TO_EXTERNALS_INFO_FILE_TMP%%" "URL"
set "BRANCH_CURRENT_REV_DIR_URL=%RETURN_VALUE%"
if not defined BRANCH_CURRENT_REV_DIR_URL (
  echo.%?~nx0%: error: `URL` property is not found in temporary SVN info file requested from the branch: BRANCH_PATH="%SYNC_BRANCH_PATH%".
  exit /b 33
) >&2

rem convert externals into CSV list
call "%%SVNCMD_TOOLS_ROOT%%/gen_externals_list_from_pget.bat" -no_uri_transform "%%BRANCH_FROM_EXTERNALS_FILE_TMP%%" > "%BRANCH_FROM_EXTERNALS_LIST_FILE_TMP%"
if %ERRORLEVEL% NEQ 0 (
  echo.%?~nx0%: error: generation of the externals list file has failed: ERROR="%ERRORLEVEL%" EXTERNAL_BRANCH_PATH="%EXTERNAL_BRANCH_PATH_PREFIX%" WCROOT_PATH="%WCROOT_PATH%" SYNC_BRANCH_PATH="%SYNC_BRANCH_PATH_ABS%".
  exit /b 34
) >&2

call "%%SVNCMD_TOOLS_ROOT%%/gen_externals_list_from_pget.bat" -no_uri_transform -make_dir_path_prefix_rel "%%BRANCH_TO_EXTERNALS_FILE_TMP%%" "" "%%BRANCH_CURRENT_REV_DIR_URL%%" > "%BRANCH_TO_EXTERNALS_LIST_FILE_TMP%"
if %ERRORLEVEL% NEQ 0 (
  echo.%?~nx0%: error: generation of the externals list file has failed: ERROR="%ERRORLEVEL%" EXTERNAL_BRANCH_PATH="%EXTERNAL_BRANCH_PATH_PREFIX%" WCROOT_PATH="%WCROOT_PATH%" SYNC_BRANCH_PATH="%SYNC_BRANCH_PATH_ABS%".
  exit /b 35
) >&2

call "%%SVNCMD_TOOLS_ROOT%%/svn_remove_externals.bat"%%BARE_FLAGS%% -remove_unchanged "%%SYNC_BRANCH_PATH%%/%%EXTERNAL_BRANCH_PATH%%" "%%EXTERNAL_DIR_PATH%%" "%%BRANCH_TO_EXTERNALS_LIST_FILE_TMP%%" "%%BRANCH_FROM_EXTERNALS_LIST_FILE_TMP%%"
if %ERRORLEVEL% GTR 0 (
  echo.%?~nx0%: error: preprocess of the update externals remove has failed: ERROR="%ERRORLEVEL%" EXTERNAL_BRANCH_PATH="%EXTERNAL_BRANCH_PATH_PREFIX%" WCROOT_PATH="%WCROOT_PATH%" SYNC_BRANCH_PATH="%SYNC_BRANCH_PATH_ABS%".
  exit /b 36
) >&2

exit /b 0

:SVN_REMOVE_BY_LIST
rem set a current directory for "svn ls" command to reduce path lengths in output and from there the ".svn" directory search up to the root
pushd "%EXTERNAL_BRANCH_PATH_ABS%" && (
  call "%%SVNCMD_TOOLS_ROOT%%/svn_list.bat" -offline . --depth infinity --non-interactive > "%BRANCH_FILES_FILE_TMP%" 2>nul || ( popd & exit /b )

  echo.Removing external directory content: "%EXTERNAL_BRANCH_PATH%"...
  for /F "usebackq eol= tokens=* delims=" %%i in (`sort /R "%BRANCH_FILES_FILE_TMP%"`) do (
    set "SVN_FILE_PATH=%%i"
    call :REMOVE_SVN_FILE_PATH || ( popd & exit /b )
  )
  echo.
  popd
)

exit /b 0

:REMOVE_SVN_FILE_PATH
rem safe checks
if not defined SVN_FILE_PATH exit /b 0
if "%SVN_FILE_PATH%" == "." exit /b 0
if "%SVN_FILE_PATH:~-1%" == "/" (
  rmdir /Q "%SVN_FILE_PATH:/=\%" 2>nul && echo.- "%EXTERNAL_BRANCH_PATH%/%SVN_FILE_PATH%"
) else (
  del /F /Q /A:-D "%SVN_FILE_PATH:/=\%" 2>nul && echo.- "%EXTERNAL_BRANCH_PATH%/%SVN_FILE_PATH%"
)

exit /b 0

:REMOVE_EXTERNAL_UNCHANGED_DIR_PATH
echo.Removing external directory parent path: "%EXTERNAL_BRANCH_PATH%"...
call "%%SVNCMD_TOOLS_ROOT%%/svn_remove_external_unchanged_dir.bat" "%%WCROOT_PATH_ABS%%" "%%EXTERNAL_DIR_PATH_PREFIX%%" "%%EXTERNAL_DIR_PATH%%"
if %ERRORLEVEL% NEQ 0 (
  echo.%?~nx0%: error: external branch directory remove has failed: ERROR="%ERRORLEVEL%" EXTERNAL_BRANCH_PATH="%EXTERNAL_BRANCH_PATH_PREFIX%" WCROOT_PATH="%WCROOT_PATH%" SYNC_BRANCH_PATH="%SYNC_BRANCH_PATH_ABS%".
  exit /b 40
) >&2

exit /b 0

:REMOVE_WCROOT_EXTERNAL
set "BRANCH_LOCAL_REL_PATH=%EXTERNAL_BRANCH_PATH_PREFIX:\=/%"
set "BRANCH_DEF_LOCAL_REL_PATH=%EXTERNAL_DIR_PATH_PREFIX:\=/%"
if "%BRANCH_DEF_LOCAL_REL_PATH%" == "." set "BRANCH_DEF_LOCAL_REL_PATH="

rem delete record from the WC EXTERNALS table to unlink the external directory from the WC root.
call "%%CONTOOLS_SQLITE_TOOLS_ROOT%%/sqlite.bat" -batch "%%WCROOT_PATH_ABS%%/.svn/wc.db" ".headers off" ^
  "delete from EXTERNALS where wc_id = '%%WC_ID%%' and local_relpath = '%%BRANCH_LOCAL_REL_PATH%%' and repos_id = '%%REPOS_ID%%' and presence = 'normal' and kind = 'dir' and def_local_relpath = '%%BRANCH_DEF_LOCAL_REL_PATH%%'"
if %ERRORLEVEL% NEQ 0 (
  echo.%?~nx0%: error: failed to delete a record from the EXTERNALS table in the WC root: ERROR="%ERRORLEVEL%" EXTERNAL_BRANCH_PATH="%EXTERNAL_BRANCH_PATH_PREFIX%" WCROOT_PATH="%WCROOT_PATH%" SYNC_BRANCH_PATH="%SYNC_BRANCH_PATH_ABS%".
  exit /b 60
) >&2

exit /b 0

:CMD
echo.^>%*
rem Drop last error code
type nul>nul
(%*)
exit /b
