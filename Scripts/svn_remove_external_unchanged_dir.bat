@echo off

rem Author:   Andrey Dibrov (andry at inbox dot ru)

rem Description:
rem   Script for remove a single SVN external directory from the WC root if it
rem   does not have unversioned items.
rem
rem CAUTION:
rem   The externals must be already processed through the call to the
rem   svn_remove_externals.bat script or checked on local changes absence,
rem   otherwise you may lose the local changes in nested externals!
rem

rem Examples:
rem 1. call svn_remove_external_unchanged_dir.bat branch/current/proj1 proj1_subdir ext_dir

rem Drop last error level
cd .

setlocal

call "%%~dp0__init__.bat" || goto :EOF

set "?~n0=%~n0"

set "WCROOT_PATH=%~1"
set "EXTERNAL_DIR_PATH_PREFIX=%~2"
set "EXTERNAL_DIR_PATH=%~3"

if "%SYNC_BRANCH_PATH%" == "" goto NO_SYNC_BRANCH_PATH
if not exist "%SYNC_BRANCH_PATH%\" goto NO_SYNC_BRANCH_PATH

goto NO_SYNC_BRANCH_PATH_END
:NO_SYNC_BRANCH_PATH
(
  echo.%?~nx0%: error: branch path does not exist: SYNC_BRANCH_PATH="%SYNC_BRANCH_PATH%".
  exit /b 1
) >&2
:NO_SYNC_BRANCH_PATH_END

if "%WORKINGSET_FILE%" == "" goto NO_WORKINGSET_FILE
if not exist "%WORKINGSET_FILE%" goto NO_WORKINGSET_FILE

goto NO_WORKINGSET_FILE_END
:NO_WORKINGSET_FILE
(
  echo.%?~nx0%: error: workingset file does not exist: WORKINGSET_FILE="%WORKINGSET_FILE%".
  exit /b 2
) >&2
:NO_WORKINGSET_FILE_END

if "%WCROOT_PATH%" == "" goto ERROR_WCROOT_PATH
if not exist "%WCROOT_PATH%\.svn\wc.db" goto ERROR_WCROOT_PATH

goto ERROR_WCROOT_PATH_END
:ERROR_WCROOT_PATH
(
  echo.%?~nx0%: error: SVN WC root path does not exist or is not under version control: WCROOT_PATH="%WCROOT_PATH%".
  exit /b 3
) >&2
:ERROR_WCROOT_PATH_END

if not "%EXTERNAL_DIR_PATH_PREFIX%" == "." (
  set "EXTERNAL_BRANCH_PATH_PREFIX=%EXTERNAL_DIR_PATH_PREFIX%/%EXTERNAL_DIR_PATH%"
) else (
  set "EXTERNAL_BRANCH_PATH_PREFIX=%EXTERNAL_DIR_PATH%"
)
set "EXTERNAL_BRANCH_PATH=%WCROOT_PATH:\=/%/%EXTERNAL_BRANCH_PATH_PREFIX%"

if "%EXTERNAL_DIR_PATH_PREFIX%" == "" goto ERROR_EXTERNAL_BRANCH_PATH
if "%EXTERNAL_DIR_PATH%" == "" goto ERROR_EXTERNAL_BRANCH_PATH
if not exist "%EXTERNAL_BRANCH_PATH%\.svn\wc.db" goto ERROR_EXTERNAL_BRANCH_PATH

goto ERROR_EXTERNAL_BRANCH_PATH_END
:ERROR_EXTERNAL_BRANCH_PATH
(
  echo.%?~nx0%: error: external branch path does not exist or is not under version control: EXTERNAL_BRANCH_PATH="%EXTERNAL_BRANCH_PATH_PREFIX%" WCROOT_PATH="%WCROOT_PATH%".
  exit /b 4
) >&2
:ERROR_EXTERNAL_BRANCH_PATH_END

rem pushd protects root directory from accidental remove!
pushd "%WCROOT_PATH%/%EXTERNAL_DIR_PATH_PREFIX%" && (
  set "DIR_PATH=%EXTERNAL_DIR_PATH%"
  call :REMOVE_EXTERNAL_EMPTY_DIR_PATH
  popd
)

exit /b

:REMOVE_EXTERNAL_EMPTY_DIR_PATH
rem safe checks
if "%DIR_PATH%" == "" exit /b 0
if "%DIR_PATH%" == "." exit /b 0
if "%DIR_PATH:~1,1%" == ":" exit /b 0
rem test whole path on empty directory
rem set "DIR_PATH=%DIR_PATH:/=\%"
if exist "%DIR_PATH%\" (
  call :REMOVE_EXTERNAL_EMPTY_DIR_PATH_IMPL || goto :EOF
)
exit /b 0

:REMOVE_EXTERNAL_EMPTY_DIR_PATH_IMPL
rem We must requested statuses for all subdirectories in the DIR_PATH before we begin to remove,
rem otherwise the SVN status will change after a very first remove!
call "%%CONTOOLS_ROOT%%/index_pathstr.bat" DIR_PATH_ARR_ /\ "%%DIR_PATH%%"
set DIR_PATH_SIZE=%RETURN_VALUE%
set DIR_PATH_OFFSET=%DIR_PATH_SIZE%
set "DIR_PATH_DIR="

:REMOVE_EXTERNAL_EMPTY_DIR_PATH_IMPL_UPDATE_STATUS_LOOP
if %DIR_PATH_OFFSET% LEQ 0 goto REMOVE_EXTERNAL_EMPTY_DIR_PATH_IMPL_REMOVE

call set "DIR_PATH_PREFIX=%%DIR_PATH_ARR_%DIR_PATH_OFFSET%%%"

set "DIR_PATH_ARR_TO_REMOVE_%DIR_PATH_OFFSET%="

call "%%CONTOOLS_ROOT%%/split_pathstr.bat" "%%DIR_PATH_PREFIX%%" /\ DIR_PATH_SUBDIR

rem test path component on empty directory
if "%DIR_PATH_PREFIX%" == "" goto REMOVE_EXTERNAL_EMPTY_DIR_PATH_IMPL_REMOVE
if "%DIR_PATH_PREFIX%" == "." goto REMOVE_EXTERNAL_EMPTY_DIR_PATH_IMPL_REMOVE

if not exist "%DIR_PATH_PREFIX:/=\%\" exit /b 0

rem Svn status returns true unversioned items only if directory is a part of repository.
rem If the parent path of the external directory is not under version control of the WC root and the external directory parent path is not the WC root path,
rem then the svn status will always report such component directories from the parent path as unversioned.
rem So instead of call to the svn status we must check unversioned items in the parent path through the shell.

rem escape findstr.exe special control characters
set "DIR_PATH_SUBDIR=%DIR_PATH_SUBDIR:\=\\%"
set "DIR_PATH_SUBDIR=%DIR_PATH_SUBDIR:.=\.%"
set "DIR_PATH_SUBDIR=%DIR_PATH_SUBDIR:[=\[%"
set "DIR_PATH_SUBDIR=%DIR_PATH_SUBDIR:]=\]%"
set "DIR_PATH_SUBDIR=%DIR_PATH_SUBDIR:^=\^%"
set "DIR_PATH_SUBDIR=%DIR_PATH_SUBDIR:$=\$%"

rem findstr returns 0 on not empty list
( svn status "%DIR_PATH_PREFIX%" --depth infinity --non-interactive 2>nul || exit /b 50 ) | findstr.exe /R /C:"^? " | findstr.exe /R /V /C:"^?[ 	][ 	]*%DIR_PATH_SUBDIR%$"

if %ERRORLEVEL% NEQ 0 goto REMOVE_EXTERNAL_EMPTY_DIR_PATH_IMPL_CHECK_DIR_ON_UNVERSIONED_FILES
goto REMOVE_EXTERNAL_EMPTY_DIR_PATH_IMPL_REMOVE

:REMOVE_EXTERNAL_EMPTY_DIR_PATH_IMPL_CHECK_DIR_ON_UNVERSIONED_FILES
call :HAS_DIR_PATH_UNVERSIONED_FILES && goto REMOVE_EXTERNAL_EMPTY_DIR_PATH_IMPL_REMOVE

set "DIR_PATH_ARR_TO_REMOVE_%DIR_PATH_OFFSET%=%DIR_PATH_PREFIX%"

:REMOVE_EXTERNAL_EMPTY_DIR_PATH_IMPL_UPDATE_STATUS_LOOP_REPEAT
call "%%CONTOOLS_ROOT%%/split_pathstr.bat" "%%DIR_PATH_PREFIX%%" /\ DIR_PATH_DIR

set /A DIR_PATH_OFFSET-=1

goto REMOVE_EXTERNAL_EMPTY_DIR_PATH_IMPL_UPDATE_STATUS_LOOP

:REMOVE_EXTERNAL_EMPTY_DIR_PATH_IMPL_REMOVE
set DIR_PATH_OFFSET=%DIR_PATH_SIZE%

:REMOVE_EXTERNAL_EMPTY_DIR_PATH_IMPL_REMOVE_LOOP
if %DIR_PATH_OFFSET% LEQ 0 exit /b 0

call set "DIR_PATH_PREFIX=%%DIR_PATH_ARR_TO_REMOVE_%DIR_PATH_OFFSET%%%"

if "%DIR_PATH_PREFIX%" == "" exit /b 0

call :CMD rmdir /S /Q "%%DIR_PATH_PREFIX:/=\%%" || exit /b 51

set /A DIR_PATH_OFFSET-=1

goto REMOVE_EXTERNAL_EMPTY_DIR_PATH_IMPL_REMOVE_LOOP

:HAS_DIR_PATH_UNVERSIONED_FILES
rem directories with the .svn subdirectory has being request through the svn commands
if exist "%DIR_PATH_PREFIX%\.svn\" exit /b 1

for /F "usebackq eol=	 tokens=* delims=" %%i in (`dir /A /B "%DIR_PATH_PREFIX%"`) do (
  if /i not "%%i" == ".svn" if /i not "%DIR_PATH_DIR%" == "%%i" exit /b 0
)

exit /b 1

:CMD
echo.^>%*
rem Drop last error code
cd .
(%*)
exit /b
