@echo off

rem Author:   Andrey Dibrov (andry at inbox dot ru)

rem Description:
rem   Generate externals CSV list from dumped svn:externals file.
rem

rem Drop last error level
cd .

setlocal

call "%%~dp0__init__.bat" || goto :EOF

set "?~nx0=%~nx0"

rem script flags
set FLAG_SVN_NO_URI_TRANSFORM=0

:FLAGS_LOOP

rem flags always at first
set "FLAG=%~1"

if not "%FLAG%" == "" ^
if not "%FLAG:~0,1%" == "-" set "FLAG="

if not "%FLAG%" == "" (
  if "%FLAG%" == "-no_uri_transform" (
    set FLAG_SVN_NO_URI_TRANSFORM=1
    shift
  ) else (
    echo.%?~nx0%: error: invalid flag: %FLAG%
    exit /b -255
  ) >&2

  rem read until no flags
  goto FLAGS_LOOP
)

set "EXTERNALS_FILE=%~dpf1"
set "REPO_ROOT=%~2"
set "DIR_URL=%~3"

if "%EXTERNALS_FILE%" == "" (
  echo.%?~nx0%: error: externals file is not set.
  exit /b 1
) >&2

if not exist "%EXTERNALS_FILE%" (
  echo.%?~nx0%: error: externals file does not exist: "%EXTERNALS_FILE%".
  exit /b 2
) >&2

if %FLAG_SVN_NO_URI_TRANSFORM% NEQ 0 goto IGNORE_URI_ARGS_CHECK

if "%REPO_ROOT%" == "" (
  echo.%?~nx0%: error: `Repository Root` argument is not set.
  exit /b 3
) >&2

if "%DIR_URL%" == "" (
  echo.%?~nx0%: error: `URL` argument is not set.
  exit /b 4
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
if "%EXTERNAL_PATH_EXP%%EXTERNAL_DIR_PATH%" == "" exit /b 0
if not "%EXTERNAL_PATH_EXP%" == "" ^
if not "%EXTERNAL_DIR_PATH%" == "" goto PARSE_EXTERNAL_PATH_EXP_OK

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
  if not "%EXTERNAL_PATH_EXP%" == "" set "EXTERNAL_DIR_PATH_PREFIX=%EXTERNAL_PATH_EXP:\=/%"
  set "EXTERNAL_PATH_EXP="
  set "EXTERNAL_DIR_PATH="
  for /F "eol= tokens=2,* delims= " %%i in ("%EXTERNAL_DIR_PATH%") do (
    set "EXTERNAL_PATH_EXP=%%i"
    set "EXTERNAL_DIR_PATH=%%j"
  )
)

if "%EXTERNAL_PATH_EXP:~0,1%" == "#" exit /b 0

rem echo "EXTERNAL_PATH_EXP=%EXTERNAL_PATH_EXP%"

rem continue search for SVN revision arguments
set "EXTERNAL_URI_REV_OPERATIVE="

if not "%EXTERNAL_PATH_EXP%" == "" ^
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

if "%EXTERNAL_PATH_EXP%%EXTERNAL_DIR_PATH%" == "" exit /b 0
if not "%EXTERNAL_PATH_EXP%" == "" ^
if not "%EXTERNAL_DIR_PATH%" == "" goto PARSE_EXTERNAL_PATH_EXP_OK2

(
  echo.%?~nx0%: error: svn:externals `URL` or `Path` value is not recognized in file: "%EXTERNALS_FILE%": "%EXTERNAL_PATH_EXP%%EXTERNAL_DIR_PATH%".
  exit /b 28
) >&2

:PARSE_EXTERNAL_PATH_EXP_OK2

set "EXTERNAL_URI_PATH="
set "EXTERNAL_URI_REV_PEG="
set "EXTERNAL_CURRENT_REV="
for /F "eol= tokens=1,2 delims=@" %%i in ("%EXTERNAL_PATH_EXP%") do (
  set "EXTERNAL_URI_PATH=%%i"
  if not "%%j" == "" set "EXTERNAL_URI_REV_PEG=%%j"
)

rem absolute URI or nothing
set "EXTERNAL_URI=-"

if %FLAG_SVN_NO_URI_TRANSFORM% NEQ 0 goto IGNORE_URI_TRANSFORM

call "%%SVNCMD_TOOLS_ROOT%%/make_url_absolute.bat" "%%DIR_URL%%" "%%EXTERNAL_URI_PATH%%" "%%REPO_ROOT%%"
if %ERRORLEVEL% NEQ 0 (
  echo.%?~nx0%: error: invalid svn:externals path transformation: BASE_URL="%DIR_URL%" ^
EXTERNAL_PATH="%EXTERNAL_URI_PATH%" REPOSITORY_ROOT="%REPO_ROOT%" RESULT="%RETURN_VALUE%".
  exit /b 20
) >&2
set "EXTERNAL_URI=%RETURN_VALUE%"

:IGNORE_URI_TRANSFORM
if "%EXTERNAL_DIR_PATH_PREFIX%" == "" set EXTERNAL_DIR_PATH_PREFIX=.
if "%EXTERNAL_URI_REV_OPERATIVE%" == "" set EXTERNAL_URI_REV_OPERATIVE=0
if "%EXTERNAL_URI_REV_PEG%" == "" set EXTERNAL_URI_REV_PEG=0

rem TODO: EXTERNAL_DIR_PATH_PREFIX can be repo URL path, transformation required in case of compare with another list with local paths in the first parameter 
echo.%EXTERNAL_DIR_PATH_PREFIX%^|%EXTERNAL_DIR_PATH%^|%EXTERNAL_URI_REV_OPERATIVE%^|%EXTERNAL_URI_REV_PEG%^|%EXTERNAL_URI%
