@echo off

rem Drop last error level
cd .

rem Create local variable's stack
setlocal

if %__NEST_LVL%0 EQU 0 (
  call "%%~dp0..\__init__.bat" || goto :EOF
)

rem call python module from here with all the arguments
"%TEST_PYTHON_EXE_PATH%" -m "%~dp0%~n0.py" %*
