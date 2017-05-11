@echo off

rem Author:   Andrey Dibrov (andry at inbox dot ru)

rem Description:
rem   Script remove single SVN external.

rem Examples:
rem 1. call svn_remove_external.bat branch/current rel_dir ext_path 771a6eda-33e6-498b-82b5-7144d63c2b48 1

rem Drop last error level
cd .

setlocal

call "%%~dp0__init__.bat" || goto :EOF

set "?~nx0=%~nx0"

rem script flags
set FLAG_SVN_AUTO_REVERT=0
set "FLAG_TEXT_SVN_AUTO_REVERT="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if not "%FLAG%" == "" ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if not "%FLAG%" == "" (
  if "%FLAG%" == "-ar" (
    set FLAG_SVN_AUTO_REVERT=1
    set "FLAG_TEXT_SVN_AUTO_REVERT=-ar"
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
set "EXTERNAL_DIR_PATH_PREFIX=%~3"
set "EXTERNAL_DIR_PATH=%~4"
set "REPOS_ID=%~5"
set "WC_ID=%~6"

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

set "EXTERNAL_BRANCH_PATH=%WCROOT_PATH:\=/%/%EXTERNAL_DIR_PATH_PREFIX%/%EXTERNAL_DIR_PATH%"

if "%EXTERNAL_DIR_PATH_PREFIX%" == "" goto ERROR_EXTERNAL_BRANCH_PATH
if "%EXTERNAL_DIR_PATH%" == "" goto ERROR_EXTERNAL_BRANCH_PATH
if not exist "%EXTERNAL_BRANCH_PATH%\.svn\wc.db" (
  :ERROR_EXTERNAL_BRANCH_PATH
  (
    echo.%?~nx0%: error: the external branch path does not exist or is not versioned: EXTERNAL_BRANCH_PATH="%EXTERNAL_BRANCH_PATH%".
    exit /b 3
  ) >&2
)

if "%REPOS_ID%" == "" (
  echo.%?~nx0%: error: invalid REPOS_ID: REPOS_ID="%REPOS_ID%".
  exit /b 4
) >&2

if "%WC_ID%" == "" (
  echo.%?~nx0%: error: invalid WC_ID: WC_ID="%WC_ID%".
  exit /b 5
) >&2


if "%EXTERNAL_DIR_PATH_PREFIX%" == "." (
  set "BRANCH_LOCAL_REL_PATH=%EXTERNAL_DIR_PATH%"
  set "BRANCH_DEF_LOCAL_REL_PATH="
) else (
  set "BRANCH_LOCAL_REL_PATH=%EXTERNAL_DIR_PATH_PREFIX%/%EXTERNAL_DIR_PATH%"
  set "BRANCH_DEF_LOCAL_REL_PATH=%EXTERNAL_DIR_PATH_PREFIX%"
)

call "%%CONTOOLS_ROOT%%/split_pathstr.bat" "%%BRANCH_LOCAL_REL_PATH%%" / "" BRANCH_PARENT_REL_PATH

pushd "%WCROOT_PATH%" && (
  rem remove nested externals recursively
  call :SVN_REMOVE_EXTERNALS || ( popd & exit /b 10 )
  rem remove all versioned files and directories in the external directory
  call :SVN_REMOVE_BY_LIST || ( popd & exit /b 11 )
  rem remove parent path of the external directory if no unversioned files on the way
  call :REMOVE_EMPTY_DIR_PATH || ( popd & exit /b 12 )
  rem remove record from the WC EXTERNALS table to unlink the external directory from the WC root.
  call :REMOVE_WCROOT_EXTERNAL || ( popd & exit /b 13 )
  popd
)

exit /b 0

:SVN_REMOVE_EXTERNALS

rem If workingset file is set, then find the external revision and info file in the workingset file, otherwise
rem use the base revision externals list.

rem ...

set "WORKINGSET_REV_FOUND="

pushd "%SYNC_BRANCH_PATH%" && (
  rem from externals
  svn pget svn:externals -r BASE . -R --non-interactive > "%BRANCH_FROM_EXTERNALS_FILE_TMP%" || ( popd & exit /b 20 )

  if not "%WORKINGSET_REV_FOUND%" == "" (
    svn pget svn:externals -r "%WORKINGSET_REV_FOUND%" . -R --non-interactive > "%BRANCH_TO_EXTERNALS_FILE_TMP%" || ( popd & exit /b 21 )
  )

  popd
)

rem convert externals into CSV list
call "%%SVNCMD_TOOLS_ROOT%%/gen_externals_list_from_pget.bat" -no_uri_transform "%%BRANCH_FROM_EXTERNALS_FILE_TMP%%" > "%BRANCH_FROM_EXTERNALS_LIST_FILE_TMP%"
if %ERRORLEVEL% NEQ 0 (
  echo.%?~nx0%: error: generation of the externals list file has failed: ERROR="%ERRORLEVEL%" EXTERNALS_FILE="%BRANCH_FROM_EXTERNALS_FILE_TMP%".
  exit /b 22
) >&2

if "%WORKINGSET_REV_FOUND%" == "" goto NO_TO_EXTERNALS

call "%%SVNCMD_TOOLS_ROOT%%/gen_externals_list_from_pget.bat" -no_uri_transform "%%BRANCH_TO_EXTERNALS_FILE_TMP%%" > "%BRANCH_FROM_EXTERNALS_LIST_FILE_TMP%"
if %ERRORLEVEL% NEQ 0 (
  echo.%?~nx0%: error: generation of the externals list file has failed: ERROR="%ERRORLEVEL%" EXTERNALS_FILE="%BRANCH_TO_EXTERNALS_FILE_TMP%".
  exit /b 23
) >&2

:NO_TO_EXTERNALS

call "%%SVNCMD_TOOLS_ROOT%%/svn_remove_externals.bat" %%FLAG_TEXT_SVN_AUTO_REVERT%% -remove_unchanged "%%BRANCH_WORKINGSET_FILE%%" "%%SYNC_BRANCH_PATH%%" "%%BRANCH_TO_EXTERNALS_LIST_FILE_TMP%%" "%%BRANCH_FROM_EXTERNALS_LIST_FILE_TMP%%"
if %ERRORLEVEL% GTR 0 (
  echo.%?~nx0%: error: preprocess of the update externals remove has failed: ERROR="%ERRORLEVEL%" BRANCH_PATH="%SYNC_BRANCH_PATH%".
  exit /b 24
) >&2

exit /b 0

:SVN_REMOVE_BY_LIST
rem set a current directory for "svn ls" command to reduce path lengths in output and from there the ".svn" directory search up to the root
pushd "%EXTERNAL_BRANCH_PATH%" && (
  call "%%SVNCMD_TOOLS_ROOT%%/svn_list.bat" -offline . --depth infinity --non-interactive > "%BRANCH_FILES_FILE_TMP%" 2>nul || ( popd & goto :EOF )

  echo.Removing external directory content: "%EXTERNAL_BRANCH_PATH_REL%"...
  for /F "usebackq eol=	 tokens=* delims=" %%i in (`sort /R "%BRANCH_FILES_FILE_TMP%"`) do (
    set "SVN_FILE_PATH=%%i"
    call :REMOVE_SVN_FILE_PATH || ( popd & goto :EOF )
  )
  popd
)
exit /b 0

:REMOVE_SVN_FILE_PATH
rem safe checks
if "%SVN_FILE_PATH%" == "" exit /b 0
if "%SVN_FILE_PATH%" == "." exit /b 0
if "%SVN_FILE_PATH:~-1%" == "/" (
  rmdir /Q "%SVN_FILE_PATH:/=\%" 2>nul && echo.- "%EXTERNAL_BRANCH_PATH%/%SVN_FILE_PATH%"
) else (
  del /F /Q /A:-D "%SVN_FILE_PATH:/=\%" 2>nul && echo.- "%EXTERNAL_BRANCH_PATH%/%SVN_FILE_PATH%"
)
exit /b 0

:REMOVE_EMPTY_DIR_PATH
rem safe checks
if "%DIR_PATH%" == "" exit /b 0
if "%DIR_PATH%" == "." exit /b 0
if "%DIR_PATH:~1,1%" == ":" exit /b 0
rem test whole path on empty directory
rem set "DIR_PATH=%DIR_PATH:/=\%"
if exist "%DIR_PATH%\" (
  call :REMOVE_EMPTY_DIR_PATH_IMPL || goto :EOF
)
exit /b 0

:REMOVE_EMPTY_DIR_PATH_IMPL
call "%%CONTOOLS_ROOT%%/index_pathstr.bat" DIR_PATH_ARR_ /\ "%%DIR_PATH%%"
set DIR_PATH_SIZE=%RETURN_VALUE%

set DIR_PATH_OFFSET=%DIR_PATH_SIZE%
:REMOVE_EMPTY_DIR_PATH_IMPL_REMOVE_LOOP
if %DIR_PATH_OFFSET% LEQ 0 exit /b 0

call set "DIR_PATH_PREFIX=%%DIR_PATH_ARR_%DIR_PATH_OFFSET%%%"
rem test path component on empty directory
if not "%DIR_PATH_PREFIX%" == "." ^
if exist "%DIR_PATH_PREFIX:/=\%\" (
  rem findstr returns 0 on not empty list
  (
    ( svn status "%DIR_PATH_PREFIX%" --depth infinity --non-interactive 2>nul || exit /b 116 ) | findstr.exe /R /C:"^? "
  ) >nul || (
    call :CMD rmdir /S /Q "%%DIR_PATH_PREFIX:/=\%%" || exit /b 117
  )
)

set /A DIR_PATH_OFFSET-=1

goto REMOVE_EMPTY_DIR_PATH_IMPL_REMOVE_LOOP

:REMOVE_WCROOT_EXTERNAL
set "PREV_WC_ID="
for /F "usebackq eol= tokens=* delims=" %%i in (`call "%%SQLITE_TOOLS_ROOT%%/sqlite.bat" -batch "%%WCROOT_PATH%%/.svn/wc.db" ".headers off" "select wc_id from "EXTERNALS" where wc_id = '%%WC_ID%%' and local_relpath = '%%BRANCH_LOCAL_REL_PATH%%' and def_local_relpath = '%BRANCH_DEF_LOCAL_REL_PATH%' "`) do set "PREV_WC_ID=%%i"

rem Update/Insert record into the WC EXTERNALS table to link the external directory to the WC root.
if not "%PREV_WC_ID%" == "" (
  call "%%SQLITE_TOOLS_ROOT%%/sqlite.bat" -batch "%%SYNC_BRANCH_PARENT_PATH%%/.svn/wc.db" ".headers off" ^
    "delete from EXTERNALS where wc_id = '%%WC_ID%%' and local_relpath = '%%BRANCH_LOCAL_REL_PATH%%' and parent_relpath = '%%BRANCH_PARENT_REL_PATH%%' and repos_id = '%%REPOS_ID%%' and presence = 'normal' and kind = 'dir'" >nul
)
