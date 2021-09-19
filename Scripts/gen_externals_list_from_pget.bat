@echo off

rem Author:   Andrey Dibrov (andry at inbox dot ru)

rem Description:
rem   Generate externals CSV list from dumped svn:externals file.
rem

rem Drop last error level
type nul>nul

setlocal

if 0%SVNCMD_TOOLS_DEBUG_VERBOSITY_LVL% GEQ 4 (echo.^>^>%0 %*) >&3

call "%%~dp0__init__.bat" || exit /b

set "?~nx0=%~nx0"

rem script flags
set FLAG_NO_URI_TRANSFORM=0
set FLAG_MAKE_DIR_PATH_PREFIX_REL=0
set FLAG_PREFIX_PATH=0
set "FLAG_TEXT_PREFIX_PATH="
set FLAG_LOCAL_PATHS_ONLY=0

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if defined FLAG ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if defined FLAG (
  if "%FLAG%" == "-no_uri_transform" (
    set FLAG_NO_URI_TRANSFORM=1
    shift
  ) else if "%FLAG%" == "-make_dir_path_prefix_rel" (
    set FLAG_MAKE_DIR_PATH_PREFIX_REL=1
    shift
  ) else if "%FLAG%" == "-prefix_path" (
    set FLAG_PREFIX_PATH=1
    set "FLAG_TEXT_PREFIX_PATH=%~2"
    shift
    shift
  ) else if "%FLAG%" == "-l" (
    set FLAG_LOCAL_PATHS_ONLY=1
    shift
  ) else (
    echo.%?~nx0%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  rem read until no flags
  goto FLAGS_LOOP
)

if %FLAG_PREFIX_PATH% NEQ 0 ^
if not defined FLAG_TEXT_PREFIX_PATH (
  echo.%?~nx0%: error: prefix path is empty.
  exit /b 1
) >&2

set "EXTERNALS_FILE=%~f1"
set "REPO_ROOT=%~2"
set "DIR_URL=%~3"

if not defined EXTERNALS_FILE (
  echo.%?~nx0%: error: externals file is not set.
  exit /b 2
) >&2

if not exist "%EXTERNALS_FILE%" (
  echo.%?~nx0%: error: externals file does not exist: "%EXTERNALS_FILE%".
  exit /b 3
) >&2

if %FLAG_MAKE_DIR_PATH_PREFIX_REL% NEQ 0 goto CHECK_DIR_URL
if %FLAG_NO_URI_TRANSFORM% NEQ 0 goto IGNORE_URI_ARGS_CHECK
if %FLAG_LOCAL_PATHS_ONLY% NEQ 0 goto IGNORE_URI_ARGS_CHECK

if not defined REPO_ROOT (
  echo.%?~nx0%: error: `Repository Root` argument is not set.
  exit /b 4
) >&2

:CHECK_DIR_URL
if not defined DIR_URL (
  echo.%?~nx0%: error: `URL` argument is not set.
  exit /b 5
) >&2

:IGNORE_URI_ARGS_CHECK
set "EXTERNAL_DIR_PATH_PREFIX="

rem echo --- %EXTERNALS_FILE% ---
set "EXTERNAL_PATH_EXP="
set "EXTERNAL_DIR_PATH="
for /F "usebackq eol=# tokens=1,* delims= " %%i in ("%EXTERNALS_FILE%") do (
  set "EXTERNAL_PATH_EXP=%%i"
  set "EXTERNAL_DIR_PATH=%%j"
  call :PARSE_EXTERNAL_PATH_EXP || exit /b
)

exit /b 0

:PARSE_EXTERNAL_PATH_EXP
if not defined EXTERNAL_PATH_EXP if not defined EXTERNAL_DIR_PATH exit /b 0
if defined EXTERNAL_PATH_EXP ^
if defined EXTERNAL_DIR_PATH goto PARSE_EXTERNAL_PATH_EXP_OK

(
  echo.%?~nx0%: error: svn:externals property line is not recognized in file: "%EXTERNALS_FILE%": "%EXTERNAL_PATH_EXP%%EXTERNAL_DIR_PATH%".
  exit /b 10
) >&2

:PARSE_EXTERNAL_PATH_EXP_OK

rem test on different SVN revision formats

rem remove trailing spaces
call :REMOVE_TRAILING_SPACES "%%EXTERNAL_DIR_PATH%%
goto REMOVE_TRAILING_SPACES_END

:REMOVE_TRAILING_SPACES
set "EXTERNAL_DIR_PATH=%~1"
exit /b 0

:REMOVE_TRAILING_SPACES_END
if "%EXTERNAL_DIR_PATH:~0,1%" == "#" exit /b 0

if "%EXTERNAL_DIR_PATH:~0,1%" == "-" (
  if defined EXTERNAL_PATH_EXP set "EXTERNAL_DIR_PATH_PREFIX=%EXTERNAL_PATH_EXP:\=/%"
  set "EXTERNAL_PATH_EXP="
  set "EXTERNAL_DIR_PATH="
  for /F "eol= tokens=2,* delims= " %%i in ("%EXTERNAL_DIR_PATH%") do (
    set "EXTERNAL_PATH_EXP=%%i"
    set "EXTERNAL_DIR_PATH=%%j"
  )
)

if "%EXTERNAL_PATH_EXP:~0,1%" == "#" exit /b 0

rem echo "EXTERNAL_PATH_EXP=%EXTERNAL_PATH_EXP%"

rem continue search for SVN revision arguments
set "EXTERNAL_URI_REV_OPERATIVE="

if defined EXTERNAL_PATH_EXP ^
if "%EXTERNAL_PATH_EXP:~0,2%" == "-r" (
  set "EXTERNAL_PATH_EXP="
  set "EXTERNAL_DIR_PATH="
  for /F "eol=# tokens=1,2,* delims= " %%i in ("%EXTERNAL_PATH_EXP:~2% %EXTERNAL_DIR_PATH%") do (
    set "EXTERNAL_URI_REV_OPERATIVE=%%i"
    set "EXTERNAL_PATH_EXP=%%j"
    set "EXTERNAL_DIR_PATH=%%k"
  )
)

rem echo ==== %NEST_INDEX% %EXTERNAL_DIR_PATH% ===

if not defined EXTERNAL_PATH_EXP if not defined EXTERNAL_DIR_PATH exit /b 0
if defined EXTERNAL_PATH_EXP ^
if defined EXTERNAL_DIR_PATH goto PARSE_EXTERNAL_PATH_EXP_OK2

(
  echo.%?~nx0%: error: svn:externals `URL` or `Path` value is not recognized in file: "%EXTERNALS_FILE%": "%EXTERNAL_PATH_EXP%%EXTERNAL_DIR_PATH%".
  exit /b 28
) >&2

:PARSE_EXTERNAL_PATH_EXP_OK2

set "EXTERNAL_URI_PATH="
set "EXTERNAL_URI_REV_PEG="
set "EXTERNAL_CURRENT_REV="
for /F "eol= tokens=1,2 delims=@" %%i in ("%EXTERNAL_PATH_EXP%") do (
  set "EXTERNAL_URI_PATH=%%i"
  if not "%%j" == "" set "EXTERNAL_URI_REV_PEG=%%j"
)

rem absolute URI or nothing
set "EXTERNAL_URI=-"

if %FLAG_NO_URI_TRANSFORM% NEQ 0 goto IGNORE_URI_TRANSFORM
if %FLAG_LOCAL_PATHS_ONLY% NEQ 0 goto IGNORE_URI_TRANSFORM

call "%%SVNCMD_TOOLS_ROOT%%/make_url_absolute.bat" "%%DIR_URL%%" "%%EXTERNAL_URI_PATH%%" "%%REPO_ROOT%%"
if %ERRORLEVEL% NEQ 0 (
  echo.%?~nx0%: error: invalid svn:externals path transformation: BASE_URL="%DIR_URL%" ^
EXTERNAL_PATH="%EXTERNAL_URI_PATH%" REPOSITORY_ROOT="%REPO_ROOT%" RESULT="%RETURN_VALUE%".
  exit /b 20
) >&2
set "EXTERNAL_URI=%RETURN_VALUE%"

:IGNORE_URI_TRANSFORM
if %FLAG_MAKE_DIR_PATH_PREFIX_REL% EQU 0 goto IGNORE_DIR_PATH_PREFIX_TRANSFORM
if %FLAG_LOCAL_PATHS_ONLY% NEQ 0 goto IGNORE_DIR_PATH_PREFIX_TRANSFORM

call set "EXTERNAL_DIR_PATH_SUFFIX=%%EXTERNAL_DIR_PATH_PREFIX:%DIR_URL%=%%"
if not defined EXTERNAL_DIR_PATH_SUFFIX goto TRANSFORM_DIR_PATH_PREFIX

if not "%DIR_URL%%EXTERNAL_DIR_PATH_SUFFIX%" == "%EXTERNAL_DIR_PATH_PREFIX%" goto IGNORE_DIR_PATH_PREFIX_TRANSFORM
if not "%EXTERNAL_DIR_PATH_SUFFIX:~0,1%" == "/" goto IGNORE_DIR_PATH_PREFIX_TRANSFORM

set "EXTERNAL_DIR_PATH_SUFFIX=%EXTERNAL_DIR_PATH_SUFFIX:~1%"

:TRANSFORM_DIR_PATH_PREFIX
set "EXTERNAL_DIR_PATH_PREFIX=%EXTERNAL_DIR_PATH_SUFFIX%"

:IGNORE_DIR_PATH_PREFIX_TRANSFORM
if not defined EXTERNAL_DIR_PATH_PREFIX set EXTERNAL_DIR_PATH_PREFIX=.
if not defined EXTERNAL_URI_REV_OPERATIVE set EXTERNAL_URI_REV_OPERATIVE=-
if not defined EXTERNAL_URI_REV_PEG set EXTERNAL_URI_REV_PEG=-

if %FLAG_PREFIX_PATH% EQU 0 goto IGNORE_PREFIX_PATH

if not "%EXTERNAL_DIR_PATH_PREFIX%" == "." (
  call "%%CONTOOLS_ROOT%%/filesys/subtract_relative_path.bat" "%%FLAG_TEXT_PREFIX_PATH%%" "%%EXTERNAL_DIR_PATH_PREFIX%%/%%EXTERNAL_DIR_PATH%%"
) else (
  call "%%CONTOOLS_ROOT%%/filesys/subtract_relative_path.bat" "%%FLAG_TEXT_PREFIX_PATH%%" "%%EXTERNAL_DIR_PATH%%"
)
if %ERRORLEVEL% NEQ 0 exit /b 0

set "EXTERNAL_PATH=%RETURN_VALUE%"

if %FLAG_LOCAL_PATHS_ONLY% NEQ 0 goto PRINT_EXTERNAL_PATH
goto PRINT_EXTERNAL_RECORD

:IGNORE_PREFIX_PATH
if %FLAG_LOCAL_PATHS_ONLY% NEQ 0 (
  if not "%EXTERNAL_DIR_PATH_PREFIX%" == "." (
    set "EXTERNAL_PATH=%EXTERNAL_DIR_PATH_PREFIX%/%EXTERNAL_DIR_PATH%"
  ) else (
    set "EXTERNAL_PATH=%EXTERNAL_DIR_PATH%"
  )
)

if %FLAG_LOCAL_PATHS_ONLY% NEQ 0 goto PRINT_EXTERNAL_PATH
goto PRINT_EXTERNAL_RECORD

:PRINT_EXTERNAL_PATH
rem special form of the echo command to ignore special characters in the echo value.
for /F "eol= tokens=* delims=" %%i in ("%EXTERNAL_PATH%") do (echo.%%i)

exit /b 0

:PRINT_EXTERNAL_RECORD
rem TODO: EXTERNAL_DIR_PATH_PREFIX can be repo URL path, transformation required in case of compare with another list with local paths in the first parameter 
rem special form of the echo command to ignore special characters in the echo value.
for /F "eol= tokens=* delims=" %%i in ("%EXTERNAL_DIR_PATH_PREFIX%|%EXTERNAL_DIR_PATH%|%EXTERNAL_URI_REV_OPERATIVE%|%EXTERNAL_URI_REV_PEG%|%EXTERNAL_URI%") do (echo.%%i)

exit /b 0
