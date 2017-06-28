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
cd .

setlocal

if 0%SVNCMD_TOOLS_DEBUG_VERBOCITY_LVL% GEQ 3 (echo.^>^>%0 %*) >&3

call "%%~dp0__init__.bat" || goto :EOF

set "?~nx0=%~nx0"

rem read the date and time
set "DATETIME_VALUE="
for /F "usebackq eol=	 tokens=1,2 delims==" %%i in (`wmic os get LocalDateTime /VALUE 2^> nul`) do if "%%i" == "LocalDateTime" set "DATETIME_VALUE=%%j"

if "%DATETIME_VALUE%" == "" goto DATETIME_VALUE_END

set "DATE_VALUE=%DATETIME_VALUE:~0,4%_%DATETIME_VALUE:~4,2%_%DATETIME_VALUE:~6,2%"
set "TIME_VALUE=%DATETIME_VALUE:~8,2%_%DATETIME_VALUE:~10,2%_%DATETIME_VALUE:~12,2%_%DATETIME_VALUE:~15,3%"

:DATETIME_VALUE_END

set "SCRIPT_TMP_DIR=%TEMP%\%DATE_VALUE%.%TIME_VALUE%"

set "INFO_FILE_TMP=%SCRIPT_TMP_DIR%\$info.txt"
set "EXTERNALS_FILE_TMP=%SCRIPT_TMP_DIR%\$externals.txt"
set "EXTERNALS_LIST_FILE_TMP=%SCRIPT_TMP_DIR%\externals.lst"

if exist "%SCRIPT_TMP_DIR%\" (
  echo.%?~nx0%: error: unique temporary directory must not exist before it's creation: "%SCRIPT_TMP_DIR%\".
  exit /b -254
) >&2

mkdir "%SCRIPT_TMP_DIR%"

call :MAIN %%*
set LASTERROR=%ERRORLEVEL%

rem cleanup temporary files
rmdir /S /Q "%SCRIPT_TMP_DIR%"

exit /b %LASTERROR%

:MAIN
rem script flags
set FLAG_SVN_OFFLINE=0
set ARG_SVN_WCROOT=0
set FLAG_SVN_NO_URI_TRANSFORM=0
set "ARG_SVN_NO_URI_TRANSFORM="
set "ARG_SVN_WCROOT_PATH="
set "ARG_SVN_WCROOT_PATH_ABS="

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if not "%FLAG%" == "" ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if not "%FLAG%" == "" (
  if "%FLAG%" == "-offline" (
    set FLAG_SVN_OFFLINE=1
  ) else if "%FLAG%" == "-wcroot" (
    set ARG_SVN_WCROOT=1
    set "ARG_SVN_WCROOT_PATH=%~2"
    set "ARG_SVN_WCROOT_PATH_ABS=%~dpf2"
    shift
  ) else if "%FLAG%" == "-no_uri_transform" (
    set FLAG_SVN_NO_URI_TRANSFORM=1
    set "ARG_SVN_NO_URI_TRANSFORM= -no_uri_transform"
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

if /i not "%SVN_WCROOT_PATH%" == "%CD%" (
  pushd "%SVN_WCROOT_PATH%" && (
    call :IMPL
    popd
  )
) else call :IMPL

exit /b

:IMPL

rem filter output only for the current directory path
set "SQLITE_EXP_SELECT_CMD_LINE=* from new_externals "
if %FLAG_SVN_OFFLINE% NEQ 0 ^
if %ARG_SVN_WCROOT% NEQ 0 (
  if not "%SVN_BRANCH_REL_SUB_PATH%" == "" (
    set "SQLITE_EXP_SELECT_CMD_LINE=substr(local_relpath_new, length('%SVN_BRANCH_REL_SUB_PATH%/')+1) as local_relpath_new_suffix from new_externals where substr(local_relpath_new, 1, length('%SVN_BRANCH_REL_SUB_PATH%/')) == '%SVN_BRANCH_REL_SUB_PATH%/' collate nocase and local_relpath_new_suffix != '' "
  )
)

if %FLAG_SVN_OFFLINE% NEQ 0 (
  call "%%SQLITE_TOOLS_ROOT%%/sqlite.bat" -batch "%SVN_WCROOT_PATH%\.svn\wc.db" ".headers off" "with new_externals as ( select case when kind != 'dir' then local_relpath else local_relpath || '/' end as local_relpath_new from externals where local_relpath != '' and presence != 'not-present') select %%SQLITE_EXP_SELECT_CMD_LINE%%"
  exit /b
)

if %FLAG_SVN_NO_URI_TRANSFORM% NEQ 0 goto IGNORE_URI_TRANSFORM

svn info . --non-interactive > "%INFO_FILE_TMP%" || exit /b 251

call "%%SVNCMD_TOOLS_ROOT%%/extract_info_param.bat" "%%INFO_FILE_TMP%%" "URL"
set "BRANCH_DIR_URL=%RETURN_VALUE%"
if "%BRANCH_DIR_URL%" == "" (
  echo.%?~nx0%: error: `URL` property is not found in SVN info file: "%INFO_FILE_TMP%".
  exit /b 250
) >&2

call "%%SVNCMD_TOOLS_ROOT%%/extract_info_param.bat" "%%INFO_FILE_TMP%%" "Repository Root"
set "BRANCH_REPO_ROOT=%RETURN_VALUE%"
if "%BRANCH_REPO_ROOT%" == "" (
  echo.%?~nx0%: error: `Repository Root` property is not found in SVN info file: "%BRANCH_INFO_FILE%".
  exit /b 249
) >&2

:IGNORE_URI_TRANSFORM
rem from externals
svn pget svn:externals . -R --non-interactive > "%EXTERNALS_FILE_TMP%" || exit /b 248

rem TODO:
rem 1. add `-prefix_path "<prefix_path>"` flag to the gen_externals_list_from_pget.bat script to ignore externals with different <prefix_path> path

rem convert externals into CSV list
call "%%SVNCMD_TOOLS_ROOT%%/gen_externals_list_from_pget.bat"%%ARG_SVN_NO_URI_TRANSFORM%% "%%EXTERNALS_FILE_TMP%%" "%%BRANCH_REPO_ROOT%%" "%%BRANCH_DIR_URL%%" || exit /b 247
