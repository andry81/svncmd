@echo off

rem Author:   Andrey Dibrov (andry at inbox dot ru)

rem Description:
rem   Script requests piece of wc.db (NODES_BASE/NODES_CURRENT tables) paths
rem   with revisions range in format:
rem      -r "- | [!]FromRevision[-] | [!]FromRevisionExcluding[:[-] | :ToRevisionIncluding[-]]"
rem   All together it reperesents a changeset for a given revisions range.

rem Examples:
rem 1. rem Read files of 66 revision only.
rem    call svn_changeset.bat -r 66 branch/current > files.lst
rem 2. rem Read files of 66 revision only.
rem    pushd branch/current && ( call svn_changeset.bat -r 66: . > files.lst & popd )
rem 3. rem Read files of 66 revision only.
rem    pushd branch/current && ( call svn_changeset.bat -r 66: > files.lst & popd )
rem 4. rem Read files higher than 66 revision.
rem    pushd "..." && ( call svn_changeset.bat -r 66: > files.lst & popd )
rem 5. rem Read files higher than 66 revision and less or equal to 70 resivion.
rem    pushd "..." && ( call svn_changeset.bat -r 66:70 > files.lst & popd )
rem 6. rem Read none 66 revision files with not empty revision number.
rem    pushd "..." && ( call svn_changeset.bat -r !66 > files.lst & popd )
rem 7. rem Read inversed range where revisions higher than 67 and less or equal to 66 revision.
rem    pushd "..." && ( call svn_changeset.bat -r !66:67 > files.lst & popd )
rem 8. rem Read files without revision number (empty).
rem    pushd "..." && ( call svn_changeset.bat -r - > files.lst & popd )
rem 9. rem Read none 66 revision files including empty revision number.
rem    pushd "..." && ( call svn_changeset.bat -r !66- > files.lst & popd )

rem Drop last error level
type nul>nul

setlocal

if 0%SVNCMD_TOOLS_DEBUG_VERBOCITY_LVL% GEQ 3 (echo.^>^>%0 %*) >&3

call "%%~dp0__init__.bat" || goto :EOF

set "?~nx0=%~nx0"
set "?~dp0=%~dp0"

rem script flags
set FLAG_REVISION_RANGE=0
set "FLAG_TEXT_REVISION_RANGE="
set FLAG_NODES_TABLE=0
set "FLAG_TEXT_NODES_TABLE="
set FLAG_WCROOT=0
set "FLAG_TEXT_WCROOT="
set "FLAG_TEXT_WCROOT_ABS="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-r" (
    rem consume next argument into flags
    set FLAG_REVISION_RANGE=1
    set "FLAG_TEXT_REVISION_RANGE=%~2"
    shift
    shift
  ) else if "%FLAG%" == "-t" (
    rem consume next argument into flags
    set FLAG_NODES_TABLE=1
    set "FLAG_TEXT_NODES_TABLE=%~2"
    shift
    shift
  ) else if "%FLAG%" == "-wcroot" (
    set FLAG_WCROOT=1
    set "FLAG_TEXT_WCROOT=%~2"
    set "FLAG_TEXT_WCROOT_ABS=%~dpf2"
    shift
    shift
  ) else (
    echo.%?~nx0%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

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
if not defined FLAG_TEXT_REVISION_RANGE (
  echo.%?~nx0%: error: revision range is not set.
  exit /b 254
) >&2

if %FLAG_NODES_TABLE% NEQ 0 ^
if not defined FLAG_TEXT_NODES_TABLE (
  echo.%?~nx0%: error: SVN WC database node table name suffix is not set.
  exit /b 253
) >&2

if %FLAG_WCROOT% NEQ 0 ^
if not defined WCROOT_PATH (
  echo.%?~nx0%: error: SVN WC root path should not be empty.
  exit /b 252
) >&2

if not defined WCROOT_PATH (
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
if defined BRANCH_REL_SUB_PATH (
  if "%BRANCH_REL_SUB_PATH:~0,1%" == "\" (
    set "BRANCH_REL_SUB_PATH=%BRANCH_REL_SUB_PATH:~1%"
  )
)

if defined BRANCH_REL_SUB_PATH ^
if /i not "%WCROOT_PATH%\%BRANCH_REL_SUB_PATH%" == "%BRANCH_PATH%" (
  echo.%?~nx0%: error: SVN WC root path must be absolute and current directory path must be descendant to the SVN WC root path: WCROOT_PATH="%WCROOT_PATH:\=/%" BRANCH_PATH="%BRANCH_PATH:\=/%".
  exit /b 251
) >&2

if defined BRANCH_REL_SUB_PATH set "BRANCH_REL_SUB_PATH=%BRANCH_REL_SUB_PATH:\=/%"

exit /b 0

:TEST_WCROOT_PATH_END

if not exist "%WCROOT_PATH%\.svn\wc.db" (
  echo.%?~nx0%: error: SVN WC database file is not found: "%WCROOT_PATH:\=/%/.svn/wc.db"
  exit /b 250
) >&2

if /i not "%WCROOT_PATH%" == "%CD%" (
  pushd "%WCROOT_PATH%" && (
    call :IMPL
    popd
  )
) else call :IMPL

(
  endlocal
  rem restore chcp variables
  set "CURRENT_CP=%CURRENT_CP%"
  set "LAST_CP=%LAST_CP%"
  exit /b
)

:IMPL
rem check on supported wc.db user version
call "%%?~dp0%%impl/svn_get_wc_db_user_ver.bat"

if not defined WC_DB_USER_VERSION (
  echo.%?~nx0%: error: SVN WC database user version is not set or not found: "%WCROOT_PATH:\=/%/.svn/wc.db"
  exit /b 249
) >&2

if %WC_DB_USER_VERSION% LSS 31 (
  echo.%?~nx0%: warning: SVN WC database user version is not supported: %WC_DB_USER_VERSION%; supported greater or equal to: 31
) >&2

rem parse -r argument value
set "SQLITE_EXP_REVISION_RANGE_SUFFIX="
if %FLAG_REVISION_RANGE% NEQ 0 call "%%?~dp0%%impl/svn_arg_parse-r.bat" "%%FLAG_TEXT_REVISION_RANGE%%"
if defined SQLITE_EXP_REVISION_RANGE set "SQLITE_EXP_REVISION_RANGE_SUFFIX= and (%SQLITE_EXP_REVISION_RANGE%)"

if not defined FLAG_TEXT_NODES_TABLE (
  set "SQLITE_EXP_NODES_TABLE=nodes_base"
) else if not "%FLAG_TEXT_NODES_TABLE%" == "-" (
  set "SQLITE_EXP_NODES_TABLE=nodes_%FLAG_TEXT_NODES_TABLE%"
) else (
  set "SQLITE_EXP_NODES_TABLE=nodes"
)

rem filter output only for the current directory path
set "SQLITE_EXP_WHERE_FIRST_FILTER="
if %FLAG_WCROOT% NEQ 0 ^
if defined BRANCH_REL_SUB_PATH (
  set "SQLITE_EXP_WHERE_FIRST_FILTER= and substr(local_relpath || '/', 1, length('%BRANCH_REL_SUB_PATH%/')) == '%BRANCH_REL_SUB_PATH%/' collate nocase"
)

call "%%SQLITE_TOOLS_ROOT%%/sqlite.bat" -batch "%WCROOT_PATH%\.svn\wc.db" ".headers off" ".mode list" ".separator |" ".nullvalue ." "select revision, case when kind != 'dir' then local_relpath else local_relpath || '/' end as local_relpath_new from %%SQLITE_EXP_NODES_TABLE%% where local_relpath != ''%%SQLITE_EXP_REVISION_RANGE_SUFFIX%%%%SQLITE_EXP_WHERE_FIRST_FILTER%% order by local_relpath asc"
