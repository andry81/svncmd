@echo off

rem Author:   Andrey Dibrov (andry at inbox dot ru)

rem Description:
rem   Script requests piece of wc.db (EXTERNALS table) paths,
rem   builds externals CSV list and filters out them by target path.
rem

rem Examples:
rem 1. call svn_externals_list.bat -updated branch/current > externals.lst
rem 2. pushd branch/current && ( call svn_externals_list.bat -updated . > externals.lst & popd )
rem 3. pushd branch/current && ( call svn_externals_list.bat -updated > externals.lst & popd )

rem Drop last error level
cd .

setlocal

if 0%SVNCMD_TOOLS_DEBUG_VERBOCITY_LVL% GEQ 3 (echo.^>^>%0 %*) >&3

call "%%~dp0__init__.bat" || goto :EOF

set "?~nx0=%~nx0"

rem script flags
set FLAG_SVN_UPDATED=0
set ARG_SVN_WCROOT=0
set "ARG_SVN_WCROOT_PATH="
set "ARG_SVN_WCROOT_PATH_ABS="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if not "%FLAG%" == "" ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if not "%FLAG%" == "" (
  if "%FLAG%" == "-updated" (
    set FLAG_SVN_UPDATED=1
  ) else if "%FLAG%" == "-wcroot" (
    set ARG_SVN_WCROOT=1
    set "ARG_SVN_WCROOT_PATH=%~2"
    set "ARG_SVN_WCROOT_PATH_ABS=%~dpf2"
    shift
  ) else (
    echo.%?~nx0%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  shift

  rem read until no flags
  goto FLAGS_LOOP
)

set "BRANCH_PATH=%CD%"
if not "%~1" == "" set "BRANCH_PATH=%~dpf1"

if %ARG_SVN_WCROOT% NEQ 0 ^
if "%ARG_SVN_WCROOT_PATH%" == "" (
  echo.%?~nx0%: error: SVN WC root path should not be empty.
  exit /b 254
) >&2

if "%ARG_SVN_WCROOT_PATH%" == "" (
  set "ARG_SVN_WCROOT_PATH=."
  set "ARG_SVN_WCROOT_PATH_ABS=%BRANCH_PATH%"
)

rem test SVN WC root path
if %ARG_SVN_WCROOT% NEQ 0 (
  call :TEST_WCROOT_PATH || goto :EOF
) else set "SVN_WCROOT_PATH=%BRANCH_PATH%"

goto TEST_WCROOT_PATH_END

:TEST_WCROOT_PATH
set "SVN_WCROOT_PATH=%ARG_SVN_WCROOT_PATH_ABS%"

call set "SVN_BRANCH_REL_SUB_PATH=%%BRANCH_PATH:%SVN_WCROOT_PATH%=%%"
if not "%SVN_BRANCH_REL_SUB_PATH%" == "" (
  if "%SVN_BRANCH_REL_SUB_PATH:~0,1%" == "\" (
    set "SVN_BRANCH_REL_SUB_PATH=%SVN_BRANCH_REL_SUB_PATH:~1%"
  )
)

if not "%SVN_BRANCH_REL_SUB_PATH%" == "" ^
if /i not "%SVN_WCROOT_PATH%\%SVN_BRANCH_REL_SUB_PATH%" == "%BRANCH_PATH%" (
  echo.%?~nx0%: error: SVN WC root path must be absolute and BRANCH_PATH must be descendant to the SVN WC root path: SVN_WCROOT_PATH="%SVN_WCROOT_PATH:\=/%" BRANCH_PATH="%BRANCH_PATH:\=/%".
  exit /b 253
) >&2

if not "%SVN_BRANCH_REL_SUB_PATH%" == "" set "SVN_BRANCH_REL_SUB_PATH=%SVN_BRANCH_REL_SUB_PATH:\=/%"

exit /b 0

:TEST_WCROOT_PATH_END

if not exist "%SVN_WCROOT_PATH%\.svn\wc.db" (
  echo.%?~nx0%: error: SVN WC database file is not found: "%SVN_WCROOT_PATH:\=/%/.svn/wc.db"
  exit /b 252
) >&2

:CHECK_WCROOT_PATH_DB_END

if %FLAG_SVN_UPDATED% NEQ 0 (
  if /i not "%SVN_WCROOT_PATH%" == "%CD%" (
    pushd "%SVN_WCROOT_PATH%" && (
      call :IMPL
      popd
    )
  ) else call :IMPL
) else call :IMPL

exit /b

:IMPL

rem filter output only for the current directory path
set "SQLITE_EXP_SELECT_CMD_LINE=* from new_externals "
if %FLAG_SVN_UPDATED% NEQ 0 ^
if %ARG_SVN_WCROOT% NEQ 0 (
  if not "%SVN_BRANCH_REL_SUB_PATH%" == "" (
    set "SQLITE_EXP_SELECT_CMD_LINE=substr(local_relpath_new, length('%SVN_BRANCH_REL_SUB_PATH%/')+1) as local_relpath_new_suffix from new_externals where substr(local_relpath_new, 1, length('%SVN_BRANCH_REL_SUB_PATH%/')) == '%SVN_BRANCH_REL_SUB_PATH%/' collate nocase and local_relpath_new_suffix != '' "
  )
)

if %FLAG_SVN_UPDATED% NEQ 0 (
  call "%%SQLITE_TOOLS_ROOT%%/sqlite.bat" -batch "%SVN_WCROOT_PATH%\.svn\wc.db" ".headers off" "with new_externals as ( select case when kind != 'dir' then local_relpath else local_relpath || '/' end as local_relpath_new from externals where local_relpath != '' and presence != 'not-present') select %%SQLITE_EXP_SELECT_CMD_LINE%%"
) else (
  rem TODO
)
