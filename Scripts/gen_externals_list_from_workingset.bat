@echo off

rem Author:   Andrey Dibrov (andry at inbox dot ru)

rem Description:
rem   Generate externals CSV list from workingset file.
rem

rem Drop last error level
type nul>nul

setlocal

if 0%SVNCMD_TOOLS_DEBUG_VERBOSITY_LVL% GEQ 3 (echo.^>^>%0 %*) >&3

call "%%~dp0__init__.bat" || exit /b

set "?~nx0=%~nx0"

rem script flags
set FLAG_SVN_EXTERNALS_RECURSIVE=0

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-R" (
    set FLAG_SVN_EXTERNALS_RECURSIVE=1
    set "FLAG_SVN_EXTERNALS_PROPGET=-R"
    shift
  ) else (
    echo.%?~nx0%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  rem read until no flags
  goto FLAGS_LOOP
)

set "BRANCH_WORKINGSET_FILE=%~dpf1"
set "BRANCH_WORKINGSET_CATALOG_DIR=%~dpf2"

if not defined BRANCH_WORKINGSET_FILE (
  echo.%?~nx0%: error: branch workingset file is not set.
  exit /b 1
) >&2

if not exist "%BRANCH_WORKINGSET_FILE%" (
  echo.%?~nx0%: error: branch workingset file does not exist: "%BRANCH_WORKINGSET_FILE%".
  exit /b 2
) >&2

if not defined BRANCH_WORKINGSET_CATALOG_DIR (
  echo.%?~nx0%: error: branch workingset catalog is not set.
  exit /b 3
) >&2

if not exist "%BRANCH_WORKINGSET_CATALOG_DIR%\" (
  echo.%?~nx0%: error: branch workingset catalog does not exist: "%BRANCH_WORKINGSET_CATALOG_DIR%".
  exit /b 4
) >&2

for /F "usebackq eol=# tokens=4,5,6,7 delims=|" %%i in ("%BRANCH_WORKINGSET_FILE%") do (
  set "BRANCH_DECORATED_PATH=%%i"
  set "BRANCH_URI=%%j"
  set "BRANCH_EXTERNAL_URI_REV_PEG=%%k"
  set "BRANCH_EXTERNAL_URI_REV_OPERATIVE=%%l"
  call :BRANCH_WORKINGSET_LINE || exit /b
)

exit /b 0

:BRANCH_WORKINGSET_LINE
if not defined BRANCH_DECORATED_PATH (
  echo.%?~nx0%: error: found empty branch path in workingset.
  exit /b 10
) >&2

if not defined BRANCH_URI (
  echo.%?~nx0%: error: found empty branch uri in workingset.
  exit /b 11
) >&2

rem ignore not root branch repository paths if -R flag was not set
if %FLAG_SVN_EXTERNALS_RECURSIVE% EQU 0 ^
if not "%BRANCH_DECORATED_PATH::=%" == "%BRANCH_DECORATED_PATH%" exit /b 0

rem echo.  %BRANCH_DECORATED_PATH%^|%BRANCH_URI%

rem translate workingset branch path into workingset catalog path (reduced) and branch path (unreduced)
set "BRANCH_UNREDUCED_PATH=%BRANCH_DECORATED_PATH::#=/%"
set "BRANCH_UNREDUCED_PATH=%BRANCH_UNREDUCED_PATH::=/%"

set "BRANCH_REDUCED_PATH=%BRANCH_DECORATED_PATH:/=--%"
set "BRANCH_REDUCED_PATH=%BRANCH_REDUCED_PATH::=/%"

if "%BRANCH_UNREDUCED_PATH:~0,1%" == "#" set "BRANCH_UNREDUCED_PATH=%BRANCH_UNREDUCED_PATH:~1%"

rem have to set a current directory for relative path values
if not exist "%BRANCH_WORKINGSET_CATALOG_DIR%/%BRANCH_REDUCED_PATH%" (
  echo.%?~nx0%: error: could not synchronize branch from non existen workingset catalog directory: BRANCH_PATH="%BRANCH_UNREDUCED_PATH%" CATALOG_DIR="%BRANCH_WORKINGSET_CATALOG_DIR%/%BRANCH_REDUCED_PATH%".
  exit /b 20
) >&2

set "BRANCH_EXTERNALS_FILE=%BRANCH_WORKINGSET_CATALOG_DIR%/%BRANCH_REDUCED_PATH%/$externals.lst"
if not exist "%BRANCH_EXTERNALS_FILE%" (
  echo.%?~nx0%: error: externals file required for branch synchronization is not found: BRANCH_PATH="%BRANCH_UNREDUCED_PATH%" BRANCH_EXTERNALS_FILE="%BRANCH_EXTERNALS_FILE%".
  exit /b 21
) >&2

call "%%CONTOOLS_ROOT%%/filesys/split_pathstr.bat" "%%BRANCH_DECORATED_PATH%%" : BRANCH_DECORATED_PATH_FILE BRANCH_DECORATED_PATH_DIR
set BRANCH_DECORATED_PATH_SIZE=%RETURN_VALUE%
if %BRANCH_DECORATED_PATH_SIZE% LSS 1 (
  echo.%?~nx0%: error: invalid path index.
  exit /b 22
) >&2

set "BRANCH_EXTERNAL_DIR_PATH=%BRANCH_DECORATED_PATH_FILE%"
if "%BRANCH_EXTERNAL_DIR_PATH:~0,1%" == "#" set "BRANCH_EXTERNAL_DIR_PATH=%BRANCH_EXTERNAL_DIR_PATH:~1%"

if not defined BRANCH_DECORATED_PATH_DIR set BRANCH_DECORATED_PATH_DIR=.
set "BRANCH_EXTERNAL_DIR_PATH_PREFIX=%BRANCH_DECORATED_PATH_DIR::#=/%"
set "BRANCH_EXTERNAL_DIR_PATH_PREFIX=%BRANCH_EXTERNAL_DIR_PATH_PREFIX::=/%"
if "%BRANCH_EXTERNAL_DIR_PATH_PREFIX:~0,1%" == "#" set "BRANCH_EXTERNAL_DIR_PATH_PREFIX=%BRANCH_EXTERNAL_DIR_PATH_PREFIX:~1%"

echo.%BRANCH_EXTERNAL_DIR_PATH_PREFIX%^|%BRANCH_EXTERNAL_DIR_PATH%^|%BRANCH_EXTERNAL_URI_REV_OPERATIVE%^|%BRANCH_EXTERNAL_URI_REV_PEG%^|%BRANCH_URI%

exit /b 0
