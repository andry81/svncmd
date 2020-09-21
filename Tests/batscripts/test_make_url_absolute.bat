@echo off

rem Drop last error level
type nul>nul

rem Create local variable's stack
setlocal

if 0%__CTRL_SETLOCAL% EQU 1 (
  echo.%~nx0: error: cmd.exe is broken, please restart it!>&2
  exit /b 65535
)
set __CTRL_SETLOCAL=1

call "%%~dp0__init__.bat" || goto :EOF
call "%%CONTOOLS_TESTLIB_ROOT%%/init.bat" "%%~dpf0" || goto :EOF

set ?0=^^

call :TEST "file:///./root/dir1/test"                 "file:///./root/./dir1/2/3/4/../../.././dir2/.." "./test"
call :TEST "file:///./root/dir2/test"                 "file:///./root/./dir1/.././dir2" "./test"
call :TEST "file:///./root/test"                      "file:///./root/./dir1/.././dir2" "../test"
call :TEST "https://root/dir1/test"                   "https://root/./dir1/./dir2/.."   "%%?0%%/test"     "https://root/./dir1"
call :TEST "https://root2/test"                       "https://root/./dir1/./dir2/.."   "//root2/test"    "https://root/./dir1"
call :TEST "https://root/test"                        "https://root/./dir1/./dir2/.."   "/test"           "https://root/./dir1"
call :TEST "https://root/dir1/test"                   "https://root/./dir1/./dir2/.."   "test"
call :TEST "https://root/dir1/dir2/dir3"              "https://root/./dir1/./dir2/.."   "https://root/./dir1/./dir2/./dir3"

echo.

rem WARNING: must be called without the call prefix!
"%CONTOOLS_TESTLIB_ROOT%/exit.bat"

rem no code can be executed here, just in case
exit /b

:TEST
call "%%CONTOOLS_TESTLIB_ROOT%%/test.bat" %%*
exit /b
