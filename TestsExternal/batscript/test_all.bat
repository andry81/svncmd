@echo off

setlocal

call "%%~dp0__init__.bat" || goto :EOF

set /A __NEST_LVL+=1

call "%%TESTS_ROOT%%/test_svn_changeset.bat"
set LASTERROR=%ERRORLEVEL%

set /A __NEST_LVL-=1

if %__NEST_LVL% LEQ 0 (
  echo.^
  pause
)

exit /b %LASTERROR%
