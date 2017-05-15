@echo off

call "%%~dp0__init__.bat" || goto :EOF

set /A __NEST_LVL+=1

rem redirect call into python script with the same name
"%TEST_PYTHON_EXE%" "%~dp0%~n0.py" %*
set LASTERROR=%ERRORLEVEL%

set /A __NEST_LVL-=1

if %__NEST_LVL% LEQ 0 (
  echo.^
  pause
)

exit /b %LASTERROR%
