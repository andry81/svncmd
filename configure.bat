@echo off

setlocal

set "CONFIGURE_ROOT=%~dp0"
set "CONFIGURE_ROOT=%CONFIGURE_ROOT:~0,-1%"

if exist "%CONFIGURE_ROOT%/Scripts/__init__.bat" exit /b 1

rem generate default configure.user.bat
(
  echo.@echo off
  echo.
  echo.if "%%CONTOOLS_ROOT%%" == "" set "CONTOOLS_ROOT=%%~dp0..\Tools"
  echo.set "CONTOOLS_ROOT=%%CONTOOLS_ROOT:\=/%%"
  echo.if "%%CONTOOLS_ROOT:~-1%%" == "/" set "CONTOOLS_ROOT=%%CONTOOLS_ROOT:~0,-1%%"
  echo.
  echo.if "%%GNUWIN32_ROOT%%" == "" set "GNUWIN32_ROOT=%%CONTOOLS_ROOT%%/gnuwin32"
  echo.set "GNUWIN32_ROOT=%%GNUWIN32_ROOT:\=/%%"
  echo.if "%%GNUWIN32_ROOT:~-1%%" == "/" set "GNUWIN32_ROOT=%%GNUWIN32_ROOT:~0,-1%%"
  echo.
  echo.if "%%SVNCMD_TOOLS_ROOT%%" == "" set "SVNCMD_TOOLS_ROOT=%%~dp0"
  echo.set "SVNCMD_TOOLS_ROOT=%%SVNCMD_TOOLS_ROOT:\=/%%"
  echo.if "%%SVNCMD_TOOLS_ROOT:~-1%%" == "/" set "SVNCMD_TOOLS_ROOT=%%SVNCMD_TOOLS_ROOT:~0,-1%%"
  echo.
  echo.if "%%SQLITE_TOOLS_ROOT%%" == "" set "SQLITE_TOOLS_ROOT=%%CONTOOLS_ROOT%%/sqlite"
  echo.set "SQLITE_TOOLS_ROOT=%%SQLITE_TOOLS_ROOT:\=/%%"
  echo.if "%%SQLITE_TOOLS_ROOT:~-1%%" == "/" set "SQLITE_TOOLS_ROOT=%%SQLITE_TOOLS_ROOT:~0,-1%%"
  echo.
  echo.if "%%XML_TOOLS_ROOT%%" == "" set "XML_TOOLS_ROOT=%%CONTOOLS_ROOT%%/xml"
  echo.set "XML_TOOLS_ROOT=%%XML_TOOLS_ROOT:\=/%%"
  echo.if "%%XML_TOOLS_ROOT:~-1%%" == "/" set "XML_TOOLS_ROOT=%%XML_TOOLS_ROOT:~0,-1%%"
  echo.
  echo.if "%%VARS_ROOT%%" == "" set "VARS_ROOT=%%CONTOOLS_ROOT%%/vars"
  echo.set "VARS_ROOT=%%VARS_ROOT:\=/%%"
  echo.if "%%VARS_ROOT:~-1%%" == "/" set "VARS_ROOT=%%VARS_ROOT:~0,-1%%"
) > "%CONFIGURE_ROOT%/Scripts/__init__.bat"

exit /b 0
