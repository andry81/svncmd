@echo off

rem Create local variable's stack
setlocal

call "%%~dp0__init__.bat" || goto :EOF
call "%%CONTOOLS_TESTLIB_ROOT%%/init.bat" "%%~f0" || goto :EOF

call "%%TESTS_ROOT%%/test_make_url_canonical.bat"
call "%%TESTS_ROOT%%/test_make_url_absolute.bat"

rem WARNING: must be called without the call prefix!
"%CONTOOLS_TESTLIB_ROOT%/exit.bat"

rem no code can be executed here, just in case
exit /b
