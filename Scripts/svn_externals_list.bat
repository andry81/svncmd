@echo off

rem Author:   Andrey Dibrov (andry at inbox dot ru)

rem Description:
rem   Script requests piece of wc.db (EXTERNALS table) paths,
rem   builds externals CSV list and filters out them by target path.
rem

rem Examples:
rem 1. call svn_externals_list.bat -offline branch/current > externals.lst
rem 2. pushd branch/current && ( call svn_externals_list.bat -offline . > externals.lst & popd )
rem 3. pushd branch/current && ( call svn_externals_list.bat -offline > externals.lst & popd )

rem Drop last error level
type nul>nul

setlocal

if 0%SVNCMD_TOOLS_DEBUG_VERBOCITY_LVL% GEQ 3 (echo.^>^>%0 %*) >&3

call "%%~dp0__init__.bat" || goto :EOF

set "?~n0=%~n0"
set "?~nx0=%~nx0"
set "?~dp0=%~dp0"
set "?~dpf0=%~dpf0"

call "%%CONTOOLS_ROOT%%/std/allocate_temp_dir.bat" . "%%?~n0%%"

set "INFO_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\$info.txt"
set "EXTERNALS_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\$externals.txt"
set "EXTERNALS_LIST_FILE_TMP=%SCRIPT_TEMP_CURRENT_DIR%\externals.lst"

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

rem cleanup temporary files
call "%%CONTOOLS_ROOT%%/std/free_temp_dir.bat"

(
  endlocal
  rem restore chcp variables
  set "CURRENT_CP=%CURRENT_CP%"
  set "LAST_CP=%LAST_CP%"
  exit /b %LASTERROR%
)

:MAIN
rem script flags
set FLAG_RECURSIVE=0
set FLAG_PREFIX_PATH=0
set "FLAG_TEXT_PREFIX_PATH="
set FLAG_OFFLINE=0
set "FLAG_TEXT_OFFLINE="
set FLAG_WCROOT=0
set FLAG_NO_URI_TRANSFORM=0
set "FLAG_TEXT_NO_URI_TRANSFORM="
set "FLAG_TEXT_WCROOT="
set "FLAG_TEXT_WCROOT_ABS="
set FLAG_LOCAL_PATHS_ONLY=0
set "FLAG_TEXT_LOCAL_PATHS_ONLY="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-offline" (
    set FLAG_OFFLINE=1
    set "FLAG_TEXT_OFFLINE= -offline"
  ) else if "%FLAG%" == "-wcroot" (
    set FLAG_WCROOT=1
    set "FLAG_TEXT_WCROOT=%~2"
    set "FLAG_TEXT_WCROOT_ABS=%~dpf2"
    shift
  ) else if "%FLAG%" == "-no_uri_transform" (
    set FLAG_NO_URI_TRANSFORM=1
    set "FLAG_TEXT_NO_URI_TRANSFORM= -no_uri_transform"
  ) else if "%FLAG%" == "-l" (
    set FLAG_LOCAL_PATHS_ONLY=1
    set "FLAG_TEXT_LOCAL_PATHS_ONLY= -l"
  ) else if "%FLAG%" == "-R" (
    set FLAG_RECURSIVE=1
  ) else if "%FLAG%" == "-prefix_path" (
    set FLAG_PREFIX_PATH=1
    set "FLAG_TEXT_PREFIX_PATH=%~2"
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

if not exist "%BRANCH_PATH%\" (
  echo.%?~nx0%: error: BRANCH_PATH does not exist: "%BRANCH_PATH%".
  exit /b 255
)

set "WCROOT_PATH=%FLAG_TEXT_WCROOT%"
set "WCROOT_PATH_ABS=%FLAG_TEXT_WCROOT_ABS%"

if %FLAG_WCROOT% NEQ 0 ^
if not defined WCROOT_PATH (
  echo.%?~nx0%: error: SVN WC root path should not be empty.
  exit /b 254
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
  echo.%?~nx0%: error: SVN WC root path must be absolute and BRANCH_PATH must be descendant to the SVN WC root path: WCROOT_PATH="%WCROOT_PATH:\=/%" BRANCH_PATH="%BRANCH_PATH:\=/%".
  exit /b 253
) >&2

if defined BRANCH_REL_SUB_PATH set "BRANCH_REL_SUB_PATH=%BRANCH_REL_SUB_PATH:\=/%"

exit /b 0

:TEST_WCROOT_PATH_END

if not exist "%WCROOT_PATH%\.svn\wc.db" (
  echo.%?~nx0%: error: SVN WC database file is not found: "%WCROOT_PATH:\=/%/.svn/wc.db"
  exit /b 252
) >&2

:CHECK_WCROOT_PATH_DB_END

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
rem self recursion check
if not defined WCROOT_EXTERNALS (
  set WCROOT_EXTERNALS=1
) else if %WCROOT_EXTERNALS%0 NEQ 0 (
  set WCROOT_EXTERNALS=0
)

set "PREFIX_PATH=%FLAG_TEXT_PREFIX_PATH%"
if not defined PREFIX_PATH set "PREFIX_PATH=."

set "PREFIX_PATH_PREFIX=%FLAG_TEXT_PREFIX_PATH%"

if "%PREFIX_PATH_PREFIX%" == "." set "PREFIX_PATH_PREFIX="

if defined PREFIX_PATH_PREFIX set "PREFIX_PATH_PREFIX=%PREFIX_PATH_PREFIX:\=/%"

if defined PREFIX_PATH_PREFIX (
  if not "/" == "%PREFIX_PATH_PREFIX:~-1%" (
    set "PREFIX_PATH_PREFIX=%PREFIX_PATH_PREFIX%/"
  )
)

if %FLAG_OFFLINE% EQU 0 goto IGNORE_WC_DB

rem check on supported wc.db user version
call "%%?~dp0%%impl/svn_get_wc_db_user_ver.bat"

if not defined WC_DB_USER_VERSION (
  echo.%?~nx0%: error: SVN WC database user version is not set or not found: "%WCROOT_PATH:\=/%/.svn/wc.db"
  exit /b 249
) >&2

if %WC_DB_USER_VERSION% LSS 31 (
  echo.%?~nx0%: warning: SVN WC database user version is not supported: %WC_DB_USER_VERSION%; supported greater or equal to: 31
) >&2

if %FLAG_LOCAL_PATHS_ONLY% EQU 0 goto IGNORE_LOCAL_PATH_ONLY

set "SQLITE_EXP_SELECT_FIRST_FILTER= case when kind != 'dir' then local_relpath else local_relpath || '/' end"
set "SQLITE_EXP_WHERE_FIRST_FILTER="
if %FLAG_WCROOT% NEQ 0 ^
if defined BRANCH_REL_SUB_PATH (
  set "SQLITE_EXP_SELECT_FIRST_FILTER= substr(case when kind != 'dir' then local_relpath else local_relpath || '/' end, length('%BRANCH_REL_SUB_PATH%/')+1)"
  set "SQLITE_EXP_WHERE_FIRST_FILTER= and substr(local_relpath || '/', 1, length('%BRANCH_REL_SUB_PATH%/')) == '%BRANCH_REL_SUB_PATH%/' collate nocase"
)

set "SQLINE_EXP_EXTERNALS_LIST=select%SQLITE_EXP_SELECT_FIRST_FILTER% from externals where local_relpath != '' and presence != 'not-present'%SQLITE_EXP_WHERE_FIRST_FILTER%"

if %FLAG_RECURSIVE% EQU 0 (
  call "%%SQLITE_TOOLS_ROOT%%/sqlite.bat" -batch "%%WCROOT_PATH%%\.svn\wc.db" ".headers off" "%%SQLINE_EXP_EXTERNALS_LIST%%"
  exit /b
)

rem make recursion
call "%%SQLITE_TOOLS_ROOT%%/sqlite.bat" -batch "%%WCROOT_PATH%%\.svn\wc.db" ".headers off" "%%SQLINE_EXP_EXTERNALS_LIST%%" > "%EXTERNALS_LIST_FILE_TMP%"

for /F "usebackq eol=	 tokens=* delims=" %%i in ("%EXTERNALS_LIST_FILE_TMP%") do (
  set "LOCAL_PATH=%%i"
  call :PROCESS_LOCAL_EXTERNAL_RECORD || goto :EOF
)

exit /b 0

:PROCESS_LOCAL_EXTERNAL_RECORD
set "LOCAL_PREFIX_PATH=%PREFIX_PATH_PREFIX%%LOCAL_PATH%"
if "/" == "%LOCAL_PREFIX_PATH:~-1%" set "LOCAL_PREFIX_PATH=%LOCAL_PREFIX_PATH:~0,-1%"

rem special form of the echo command to ignore special characters in the echo value.
for /F "eol=	 tokens=* delims=" %%i in ("%PREFIX_PATH_PREFIX%%LOCAL_PATH%") do (echo.%%i)

call "%%?~dpf0%%" -R%%FLAG_TEXT_OFFLINE%%%%FLAG_TEXT_NO_URI_TRANSFORM%% -l -prefix_path "%%LOCAL_PREFIX_PATH%%" "%%LOCAL_PATH%%"

exit /b

:IGNORE_LOCAL_PATH_ONLY

set "SQLITE_EXP_WHERE_FIRST_FILTER="
if %FLAG_WCROOT% NEQ 0 ^
if defined BRANCH_REL_SUB_PATH (
  set "SQLITE_EXP_WHERE_FIRST_FILTER= and substr(local_relpath || '/', 1, length('%BRANCH_REL_SUB_PATH%/')) == '%BRANCH_REL_SUB_PATH%/' collate nocase"
)

if %FLAG_NO_URI_TRANSFORM% NEQ 0 goto IGNORE_URI_TRANSFORM

set "SQLINE_EXP_EXTERNALS_LIST=select case when def_local_relpath != '' then def_local_relpath else '.' end as local_prefix, case when def_local_relpath != '' then substr(case when kind != 'dir' then local_relpath else local_relpath || '/' end, length(def_local_relpath)+2) else case when kind != 'dir' then local_relpath else local_relpath || '/' end end as external_path, case when def_revision != '' then def_revision else '-' end as operative_rev, case when def_operational_revision != '' then def_operational_revision else '-' end as peg_rev, repos_id, def_repos_relpath from externals where local_relpath != '' and presence != 'not-present'%SQLITE_EXP_WHERE_FIRST_FILTER%"

for /F "usebackq eol=	 tokens=1,2,3,4,5,6 delims=|" %%i in (`@call "%%SQLITE_TOOLS_ROOT%%/sqlite.bat" -batch "%%WCROOT_PATH%%\.svn\wc.db" ".headers off" ".mode list" ".separator |" ".nullvalue ." "%%SQLINE_EXP_EXTERNALS_LIST%%"`) do (
  set "LOCAL_PREFIX=%%i"
  set "EXTERNAL_PATH=%%j"
  set "OPERATIVE_REV=%%k"
  set "PEG_REV=%%l"
  set "REPOS_ID=%%m"
  set "REPO_RELPATH=%%n"
  call :PROCESS_EXTERNAL_RECORD || goto :EOF
)

exit /b 0

:PROCESS_EXTERNAL_RECORD
set "REPOROOT="
for /F "usebackq eol=	 tokens=* delims=" %%i in (`@call "%%SQLITE_TOOLS_ROOT%%/sqlite.bat" -batch "%%WCROOT_PATH%%\.svn\wc.db" ".headers off" "select root from repository where id='%%REPOS_ID%%'"`) do set "REPOROOT=%%i"
if not defined REPOROOT (
  echo.%?~nx0%: error: SVN database `REPOSITORY root` request has failed: "%WCROOT_PATH:\=/%/.svn/wc.db".
  exit /b 240
) >&2

set "REPOPATH=%REPOROOT%"
if defined REPO_RELPATH set "REPOPATH=%REPOPATH%/%REPO_RELPATH%"

set "LOCAL_PREFIX_SUFFIX=%LOCAL_PREFIX%"
if "%LOCAL_PREFIX_SUFFIX%" == "." ^
if defined PREFIX_PATH_PREFIX (
  set "LOCAL_PREFIX_SUFFIX="
  if "/" == "%PREFIX_PATH_PREFIX:~-1%" (
    set "PREFIX_PATH_PREFIX=%PREFIX_PATH_PREFIX:~0,-1%"
  )
)

rem special form of the echo command to ignore special characters in the echo value.
for /F "eol=	 tokens=* delims=" %%i in ("%PREFIX_PATH_PREFIX%%LOCAL_PREFIX_SUFFIX%|%EXTERNAL_PATH%|%OPERATIVE_REV%|%PEG_REV%|%REPOPATH%") do (echo.%%i)

if %FLAG_RECURSIVE% EQU 0 exit /b

rem make recursion
if not "%LOCAL_PREFIX%" == "." (
  call "%%?~dpf0%%" -R%%FLAG_TEXT_OFFLINE%%%%FLAG_TEXT_NO_URI_TRANSFORM%%%%FLAG_TEXT_LOCAL_PATHS_ONLY%% -prefix_path "%%PREFIX_PATH_PREFIX%%%%LOCAL_PREFIX%%/%%EXTERNAL_PATH%%" "%%LOCAL_PREFIX%%/%%EXTERNAL_PATH%%"
) else (
  call "%%?~dpf0%%" -R%%FLAG_TEXT_OFFLINE%%%%FLAG_TEXT_NO_URI_TRANSFORM%%%%FLAG_TEXT_LOCAL_PATHS_ONLY%% -prefix_path "%%PREFIX_PATH_PREFIX%%%%EXTERNAL_PATH%%" "%%EXTERNAL_PATH%%"
)

exit /b

:IGNORE_URI_TRANSFORM

set "SQLINE_EXP_EXTERNALS_LIST=select case when def_local_relpath != '' then def_local_relpath else '.' end as local_prefix, case when def_local_relpath != '' then substr(case when kind != 'dir' then local_relpath else local_relpath || '/' end, length(def_local_relpath)+2) else case when kind != 'dir' then local_relpath else local_relpath || '/' end end as external_path, case when def_revision != '' then def_revision else '-' end as operative_rev, case when def_operational_revision != '' then def_operational_revision else '-' end as peg_rev, '-' from externals where local_relpath != '' and presence != 'not-present'%SQLITE_EXP_WHERE_FIRST_FILTER%"

call "%%SQLITE_TOOLS_ROOT%%/sqlite.bat" -batch "%%WCROOT_PATH%%\.svn\wc.db" ".headers off" ".mode list" ".separator |" ".nullvalue ." "%%SQLINE_EXP_EXTERNALS_LIST%%"

exit /b

:IGNORE_WC_DB

if %FLAG_NO_URI_TRANSFORM% NEQ 0 goto IGNORE_URI_TRANSFORM
if %FLAG_LOCAL_PATHS_ONLY% NEQ 0 goto IGNORE_URI_TRANSFORM

svn info . --non-interactive > "%INFO_FILE_TMP%" || exit /b 248

call "%%SVNCMD_TOOLS_ROOT%%/extract_info_param.bat" "%%INFO_FILE_TMP%%" "URL"
set "BRANCH_DIR_URL=%RETURN_VALUE%"
if not defined BRANCH_DIR_URL (
  echo.%?~nx0%: error: `URL` property is not found in SVN info file: "%INFO_FILE_TMP%".
  exit /b 230
) >&2

call "%%SVNCMD_TOOLS_ROOT%%/extract_info_param.bat" "%%INFO_FILE_TMP%%" "Repository Root"
set "BRANCH_REPO_ROOT=%RETURN_VALUE%"
if not defined BRANCH_REPO_ROOT (
  echo.%?~nx0%: error: `Repository Root` property is not found in SVN info file: "%BRANCH_INFO_FILE%".
  exit /b 229
) >&2

:IGNORE_URI_TRANSFORM
rem from externals
svn pget svn:externals . -R --non-interactive > "%EXTERNALS_FILE_TMP%" || exit /b 247

set "CMD_LINE_PREFIX_PATH="

rem ignore prefix path in recursion
if %WCROOT_EXTERNALS% EQU 0 ^
if defined BRANCH_REL_SUB_PATH set CMD_LINE_PREFIX_PATH= -prefix_path "%BRANCH_REL_SUB_PATH%"

if %FLAG_RECURSIVE% EQU 0 (
  rem convert externals into CSV list
  call "%%SVNCMD_TOOLS_ROOT%%/gen_externals_list_from_pget.bat"%%FLAG_TEXT_NO_URI_TRANSFORM%%%%FLAG_TEXT_LOCAL_PATHS_ONLY%%%%CMD_LINE_PREFIX_PATH%% "%%EXTERNALS_FILE_TMP%%" "%%BRANCH_REPO_ROOT%%" "%%BRANCH_DIR_URL%%" || exit /b 246
  exit /b 0
)

rem make recursion
call "%%SVNCMD_TOOLS_ROOT%%/gen_externals_list_from_pget.bat"%%FLAG_TEXT_NO_URI_TRANSFORM%%%%FLAG_TEXT_LOCAL_PATHS_ONLY%%%%CMD_LINE_PREFIX_PATH%% "%%EXTERNALS_FILE_TMP%%" "%%BRANCH_REPO_ROOT%%" "%%BRANCH_DIR_URL%%" > "%EXTERNALS_LIST_FILE_TMP%" || exit /b 245

for /F "usebackq eol=	 tokens=1,2,3,4,5 delims=|" %%i in ("%EXTERNALS_LIST_FILE_TMP%") do (
  set "LOCAL_PREFIX=%%i"
  set "EXTERNAL_PATH=%%j"
  set "OPERATIVE_REV=%%k"
  set "PEG_REV=%%l"
  set "REPOPATH=%%m"
  call :PROCESS_PGET_EXTERNAL_RECORD || goto :EOF
)

exit /b 0

:PROCESS_PGET_EXTERNAL_RECORD
set "LOCAL_PREFIX_SUFFIX=%LOCAL_PREFIX%"
if "%LOCAL_PREFIX_SUFFIX%" == "." ^
if defined PREFIX_PATH_PREFIX (
  set "LOCAL_PREFIX_SUFFIX="
  if "/" == "%PREFIX_PATH_PREFIX:~-1%" (
    set "PREFIX_PATH_PREFIX=%PREFIX_PATH_PREFIX:~0,-1%"
  )
)

if %FLAG_LOCAL_PATHS_ONLY% NEQ 0 (
  rem special form of the echo command to ignore special characters in the echo value.
  for /F "eol=	 tokens=* delims=" %%i in ("%PREFIX_PATH_PREFIX%%LOCAL_PREFIX_SUFFIX%") do (echo.%%i)
) else (
  rem special form of the echo command to ignore special characters in the echo value.
  for /F "eol=	 tokens=* delims=" %%i in ("%PREFIX_PATH_PREFIX%%LOCAL_PREFIX_SUFFIX%|%EXTERNAL_PATH%|%OPERATIVE_REV%|%PEG_REV%|%REPOPATH%") do (echo.%%i)
)

set "EXTERNAL_PATH_SUFFIX=%EXTERNAL_PATH%"

rem make recursion
if not "%LOCAL_PREFIX%" == "." (
  if defined EXTERNAL_PATH_SUFFIX set "EXTERNAL_PATH_SUFFIX=/%EXTERNAL_PATH_SUFFIX%"
  call "%%?~dpf0%%" -R%%FLAG_TEXT_OFFLINE%%%%FLAG_TEXT_NO_URI_TRANSFORM%%%%FLAG_TEXT_LOCAL_PATHS_ONLY%% -prefix_path "%%PREFIX_PATH_PREFIX%%%%LOCAL_PREFIX%%%%EXTERNAL_PATH_SUFFIX%%" "%%LOCAL_PREFIX%%%%EXTERNAL_PATH_SUFFIX%%"
) else (
  call "%%?~dpf0%%" -R%%FLAG_TEXT_OFFLINE%%%%FLAG_TEXT_NO_URI_TRANSFORM%%%%FLAG_TEXT_LOCAL_PATHS_ONLY%% -prefix_path "%%PREFIX_PATH_PREFIX%%%%EXTERNAL_PATH_SUFFIX%%" "%%EXTERNAL_PATH%%"
)
