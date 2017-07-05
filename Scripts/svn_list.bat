@echo off

rem Author:   Andrey Dibrov (andry at inbox dot ru)

rem Description:
rem   Script do SVN list with additional functionality like offline mode.

rem Examples:
rem 1. call svn_list.bat -offline branch/current > files.lst
rem 2. pushd branch/current && ( call svn_list.bat -offline . > files.lst & popd )
rem 3. pushd branch/current && ( call svn_list.bat -offline > files.lst & popd )

rem TODO:
rem 1. offline mode w/ or w/o -R

rem Drop last error level
cd .

setlocal

if 0%SVNCMD_TOOLS_DEBUG_VERBOCITY_LVL% GEQ 3 (echo.^>^>%0 %*) >&3

call "%%~dp0__init__.bat" || goto :EOF

set "?~nx0=%~nx0"
set "?~dp0=%~dp0"

rem script flags
set FLAG_OFFLINE=0
set FLAG_REVISION_RANGE=0
set "FLAG_TEXT_REVISION_RANGE="
set FLAG_WCROOT=0
set "FLAG_TEXT_WCROOT="
set "FLAG_TEXT_WCROOT_ABS="

rem svn flags
set "SVN_CMD_FLAG_ARGS="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if not "%FLAG%" == "" ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if not "%FLAG%" == "" (
  if "%FLAG%" == "-offline" (
    set FLAG_OFFLINE=1
  ) else if "%FLAG%" == "-r" (
    rem consume next argument into flags
    set FLAG_REVISION_RANGE=1
    set "FLAG_TEXT_REVISION_RANGE=%~2"
    set SVN_CMD_FLAG_ARGS=%SVN_CMD_FLAG_ARGS%%1 %2
    shift
  ) else if "%FLAG%" == "-wcroot" (
    set FLAG_WCROOT=1
    set "FLAG_TEXT_WCROOT=%~2"
    set "FLAG_TEXT_WCROOT_ABS=%~dpf2"
    shift
  ) else (
    set SVN_CMD_FLAG_ARGS=%SVN_CMD_FLAG_ARGS%%1 
  )

  shift

  rem read until no flags
  goto FLAGS_LOOP
)

set "BRANCH_PATH=%CD%"
if not "%~1" == "" set "BRANCH_PATH=%~dpf1"

if not exist "%BRANCH_PATH%\" (
  echo.%?~nx0%: error: BRANCH_PATH does not exist: "%BRANCH_PATH%".
  exit /b 255
)

set "WCROOT_PATH=%FLAG_TEXT_WCROOT%"
set "WCROOT_PATH_ABS=%FLAG_TEXT_WCROOT_ABS%"

if %FLAG_REVISION_RANGE% NEQ 0 ^
if "%FLAG_TEXT_REVISION_RANGE%" == "" (
  echo.%?~nx0%: error: revision range is not set.
  exit /b 254
) >&2

:ARGSN_LOOP
if not "%~1" == "" (
  set SVN_CMD_FLAG_ARGS=%SVN_CMD_FLAG_ARGS%%1 
  shift
  goto ARGSN_LOOP
)

if %FLAG_WCROOT% NEQ 0 ^
if "%WCROOT_PATH%" == "" (
  echo.%?~nx0%: error: SVN WC root path should not be empty.
  exit /b 255
) >&2

if "%WCROOT_PATH%" == "" (
  set "WCROOT_PATH=."
  set "WCROOT_PATH_ABS=%BRANCH_PATH%"
)

rem test SVN WC root path
if %FLAG_WCROOT% NEQ 0 (
  call :TEST_WCROOT_PATH || goto :EOF
) else (
  set "WCROOT_PATH=%BRANCH_PATH%"
  set "BRANCH_REL_SUB_PATH="
)

goto TEST_WCROOT_PATH_END

:TEST_WCROOT_PATH
set "WCROOT_PATH=%WCROOT_PATH_ABS%"

call set "BRANCH_REL_SUB_PATH=%%BRANCH_PATH:%WCROOT_PATH%=%%"
if not "%BRANCH_REL_SUB_PATH%" == "" (
  if "%BRANCH_REL_SUB_PATH:~0,1%" == "\" (
    set "BRANCH_REL_SUB_PATH=%BRANCH_REL_SUB_PATH:~1%"
  )
)

if not "%BRANCH_REL_SUB_PATH%" == "" ^
if /i not "%WCROOT_PATH%\%BRANCH_REL_SUB_PATH%" == "%BRANCH_PATH%" (
  echo.%?~nx0%: error: SVN WC root path must be absolute and current directory path must be descendant to the SVN WC root path: WCROOT_PATH="%WCROOT_PATH:\=/%" BRANCH_PATH="%BRANCH_PATH:\=/%".
  exit /b 252
) >&2

if not "%BRANCH_REL_SUB_PATH%" == "" set "BRANCH_REL_SUB_PATH=%BRANCH_REL_SUB_PATH:\=/%"

exit /b 0

:TEST_WCROOT_PATH_END

if %FLAG_WCROOT% NEQ 0 goto CHECK_WCROOT_PATH_DB
if %FLAG_OFFLINE% NEQ 0 goto CHECK_WCROOT_PATH_DB

goto CHECK_WCROOT_PATH_DB_END

:CHECK_WCROOT_PATH_DB
if not exist "%WCROOT_PATH%\.svn\wc.db" (
  echo.%?~nx0%: error: SVN WC database file is not found: "%WCROOT_PATH:\=/%/.svn/wc.db"
  exit /b 249
) >&2

:CHECK_WCROOT_PATH_DB_END

if %FLAG_OFFLINE% NEQ 0 (
  if /i not "%WCROOT_PATH%" == "%CD%" (
    pushd "%WCROOT_PATH%" && (
      call :IMPL
      popd
    )
  ) else call :IMPL
) else call :IMPL

(
  endlocal
  rem restore chcp variables
  set "CURRENT_CP=%CURRENT_CP%"
  set "LAST_CP=%LAST_CP%"
  exit /b
)

:IMPL
if %FLAG_OFFLINE% EQU 0 goto IGNORE_WC_DB

rem check on supported wc.db user version
call "%%?~dp0%%impl/svn_get_wc_db_user_ver.bat"

if "%WC_DB_USER_VERSION%" == "" (
  echo.%?~nx0%: error: SVN WC database user version is not set or not found: "%WCROOT_PATH:\=/%/.svn/wc.db"
  exit /b 250
) >&2

if %WC_DB_USER_VERSION% LSS 31 (
  echo.%?~nx0%: warning: SVN WC database user version is not supported: %WC_DB_USER_VERSION%; supported greater or equal to: 31
) >&2

rem parse -r argument value
set "SQLITE_EXP_REVISION_RANGE_SUFFIX="
if %FLAG_REVISION_RANGE% NEQ 0 call "%%SVNCMD_TOOLS_ROOT%%/impl/svn_arg_parse-r.bat" "%%FLAG_TEXT_REVISION_RANGE%%"
if not "%SQLITE_EXP_REVISION_RANGE%" == "" set "SQLITE_EXP_REVISION_RANGE_SUFFIX= and (%SQLITE_EXP_REVISION_RANGE%)"

rem filter output only for the current directory path
set "SQLITE_EXP_WHERE_FIRST_FILTER="
if %FLAG_WCROOT% NEQ 0 ^
if not "%BRANCH_REL_SUB_PATH%" == "" (
  set "SQLITE_EXP_WHERE_FIRST_FILTER= and substr(local_relpath || '/', 1, length('%BRANCH_REL_SUB_PATH%/')) == '%BRANCH_REL_SUB_PATH%/' collate nocase"
)

set "SQLINE_EXP_NODES_LIST=select substr(case when kind != 'dir' then local_relpath else local_relpath || '/' end, length('%BRANCH_REL_SUB_PATH%/')+1) as local_relpath_new from nodes_base where local_relpath != '' and presence != 'not-present'%SQLITE_EXP_WHERE_FIRST_FILTER% order by local_relpath asc"

call "%%SQLITE_TOOLS_ROOT%%/sqlite.bat" -batch "%WCROOT_PATH%\.svn\wc.db" ".headers off" "%%SQLINE_EXP_NODES_LIST%%"

exit /b

:IGNORE_WC_DB

svn ls %SVN_CMD_FLAG_ARGS%
