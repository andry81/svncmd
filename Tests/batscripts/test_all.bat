@echo off

rem Create local variable's stack
setlocal

call "%%~dp0__init__.bat"

set /A __NEST_LVL+=1

call "%%TESTS_ROOT%%/test_make_url_canonical.bat"
call "%%TESTS_ROOT%%/test_make_url_absolute.bat"

set /A __NEST_LVL-=1

if %__NEST_LVL%0 EQU 0 (
  echo    %__PASSED_TESTS% of %__OVERALL_TESTS% tests is passed.
  echo.^
  pause
)
