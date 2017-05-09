@echo off

rem Drop last error level
cd .

rem Create local variable's stack
setlocal

if 0%__CTRL_SETLOCAL% EQU 1 (
  echo.%~nx0: error: cmd.exe is broken, please restart it!>&2
  exit /b 65535
)
set __CTRL_SETLOCAL=1

call "%%~dp0__init__.bat" || goto :EOF

set "TEST_DATA_FILE_SCRIPT_NAME=%~n0"
set "?~nx0=%~nx0"

echo Running %~nx0...
title %~nx0 %*

set /A __NEST_LVL+=1

set __COUNTER1=1

set ?0=^^

set PRINT_COMMAND=1
set LASTERROR=0

rem 0X
call :TEST "01" "-r 1" "test_svn_changeset" "range_test_repo" . "%%TEST_DATA_FILE_SCRIPT_NAME%%/exec_checkout_rev.lst" 1
call :TEST "02" "-r 2" "test_svn_changeset" "range_test_repo" . "%%TEST_DATA_FILE_SCRIPT_NAME%%/exec_checkout_rev.lst" 2
call :TEST "03" "-r 3" "test_svn_changeset" "range_test_repo" . "%%TEST_DATA_FILE_SCRIPT_NAME%%/exec_checkout_rev.lst" 3
call :TEST "04" "-r 4" "test_svn_changeset" "range_test_repo" . "%%TEST_DATA_FILE_SCRIPT_NAME%%/exec_checkout_rev.lst" 4

call :TEST_SETUP "test_svn_changeset" "range_test_repo" . "%%TEST_DATA_FILE_SCRIPT_NAME%%/exec_update_comb1.lst" && (
  rem 1X
  call :TEST "11" "-r 4 -t current"
  call :TEST "12" "-r 2: -t current"
  call :TEST "12" "-r 2:4 -t current"
  call :TEST "14" "-r :3 -t current"
  call :TEST "15" "-r !2 -t current"
  call :TEST "16" "-r !2:4 -t current"
  call :TEST "17" "-r !:3 -t current"

  rem 2X
  call :TEST "21" "-r - -t current"
  call :TEST "22" "-r 4- -t current"
  call :TEST "23" "-r 2:- -t current"
  call :TEST "23" "-r 2:4- -t current"
  call :TEST "24" "-r :3- -t current"
  call :TEST "25" "-r !2- -t current"
  call :TEST "26" "-r !2:4- -t current"
  call :TEST "27" "-r !:3- -t current"

  call :TEST_TEARDOWN
)

echo.

goto EXIT

:TEST
setlocal

set LASTERROR=0
set INTERRORLEVEL=0

set "TEST_DATA_DIR=%TEST_DATA_FILE_SCRIPT_NAME%/%~1"
set "TEST_CMD_LINE=%~2"

set TEST_DO_TEARDOWN=0
if %TEST_SETUP%0 EQU 0 (
  set TEST_DO_TEARDOWN=1
  call :TEST_SETUP %3 %4 %5 %6 %7 || ( set LASTERROR=%ERRORLEVEL% & goto TEST_EXIT ) )
)

call :TEST_IMPL

:TEST_EXIT
call :TEST_REPORT

if %TEST_DO_TEARDOWN%0 NEQ 0 (
  set "TEST_DO_TEARDOWN="
  call :TEST_TEARDOWN
)

goto TEST_END

:TEST_IMPL
call :GET_ABSOLUTE_PATH "%%TEST_DATA_BASE_DIR%%\%%TEST_DATA_DIR%%\output.txt"
set "TEST_DATA_REF_FILE=%RETURN_VALUE%"

rem builtin commands
pushd "%TEST_SVN_REPOS_ROOT%\%TEST_SVN_CO_REPO_DIR_LIST[0]%" && (
  call "%%SVNCMD_TOOLS_ROOT%%/svn_changeset.bat" %%TEST_CMD_LINE%% > "%TEST_DATA_OUT_FILE%"
  popd
) || ( call set "INTERRORLEVEL=%%ERRORLEVEL%%" & set "LASTERROR=20" & goto LOCAL_EXIT1 )

if not exist "%TEST_DATA_OUT_FILE%" ( set "LASTERROR=21" & goto LOCAL_EXIT1 )

if not exist "%TEST_DATA_REF_FILE%" ( set "LASTERROR=22" & goto LOCAL_EXIT1 )

fc "%TEST_DATA_OUT_FILE%" "%TEST_DATA_REF_FILE%" > nul
if %ERRORLEVEL% NEQ 0 set LASTERROR=23

:LOCAL_EXIT1
popd
exit /b

:TEST_SETUP
if %TEST_SETUP%0 NEQ 0 exit /b -1
set TEST_SETUP=1
set "TEST_TEARDOWN="

set LASTERROR=0
set INTERRORLEVEL=0

call "%%CONTOOLS_ROOT%%/get_datetime.bat"
set "SYNC_DATE=%RETURN_VALUE:~0,4%_%RETURN_VALUE:~4,2%_%RETURN_VALUE:~6,2%"
set "SYNC_TIME=%RETURN_VALUE:~8,2%_%RETURN_VALUE:~10,2%_%RETURN_VALUE:~12,2%_%RETURN_VALUE:~15,3%"

set "TEST_TEMP_DIR_NAME=%TEST_DATA_FILE_SCRIPT_NAME%.%SYNC_DATE%.%SYNC_TIME%"
set "TEST_TEMP_DIR_PATH=%TEST_TEMP_BASE_DIR%\%TEST_TEMP_DIR_NAME%"

mkdir "%TEST_TEMP_DIR_PATH%" || exit /b 1

set "TEST_SVN_REPO_PATH=%~1"
set "TEST_SVN_CO_REPO_DIR_LIST=%~2"
set "TEST_SVN_CO_BRANCH_PATH_LIST=%~3"
set "TEST_CMD_FILE_REL_PATH=%~4"
set "TEST_SVN_REVISIONS_LIST=%~5"

set "TEST_SVN_CO_REPO_DIR_LIST.SIZE="
call "%%CONTOOLS_ROOT%%/std/append_list_from_string.bat" TEST_SVN_CO_REPO_DIR_LIST 0 -1 "" "%TEST_SVN_CO_REPO_DIR_LIST%"
set "TEST_SVN_CO_BRANCH_PATH_LIST.SIZE="
call "%%CONTOOLS_ROOT%%/std/append_list_from_string.bat" TEST_SVN_CO_BRANCH_PATH_LIST 0 -1 "" "%TEST_SVN_CO_BRANCH_PATH_LIST%"

call "%%CONTOOLS_ROOT%%/std/iterate_index.bat" "%%TEST_SVN_CO_REPO_DIR_LIST.SIZE%%" INDEX0 ^
call "${{CONTOOLS_ROOT}}$/abspath.bat" "${{TEST_DATA_SVN_REPOS_BASE_DIR}}$\${{TEST_SVN_REPO_PATH}}$\${{TEST_SVN_CO_REPO_DIR_LIST[${{INDEX0}}$]}}$\${{TEST_SVN_CO_BRANCH_PATH_LIST[${{INDEX0}}$]}}$" : ^
set "TEST_SVN_REPO_PATH_ABS_LIST[${{INDEX0}}$]=${{PATH_VALUE:\=/}}$"

call :GET_ABSOLUTE_PATH "%%TEST_DATA_BASE_DIR%%\%%TEST_CMD_FILE_REL_PATH%%"
set "TEST_CMD_FILE=%RETURN_VALUE%"

set "TEST_SVN_REVISIONS_LIST.SIZE="
call "%%CONTOOLS_ROOT%%/std/append_list_from_string.bat" TEST_SVN_REVISIONS_LIST 0 -1 "" "%TEST_SVN_REVISIONS_LIST%"

call :GET_ABSOLUTE_PATH "%TEST_TEMP_DIR_PATH%\output.txt"
set "TEST_DATA_OUT_FILE=%RETURN_VALUE%"

call :GET_ABSOLUTE_PATH "%%TEST_TEMP_DIR_PATH%%\repos"
set "TEST_SVN_REPOS_ROOT=%RETURN_VALUE%"

call :EXEC_TEST_CMD_FILE

exit /b %LASTERROR%

:GET_ABSOLUTE_PATH
set "RETURN_VALUE=%~dpf1"
exit /b 0

:TEST_TEARDOWN
if %TEST_SETUP%0 EQU 0 exit /b -1
set "TEST_SETUP="
set TEST_TEARDOWN=1

rem cleanup temporary files
if not "%TEST_TEMP_DIR_PATH%" == "" ^
if exist "%TEST_TEMP_DIR_PATH%\" rmdir /S /Q "%TEST_TEMP_DIR_PATH%"

exit /b 0

:EXEC_TEST_CMD_FILE
rem avoid environment variables touch
setlocal

pushd "%TEST_TEMP_DIR_PATH%" || ( set "LASTERROR=10" & goto EXEC_TEST_CMD_FILE_EXIT )

set NUM_PUSHD=1

rem command list execution
for /F "usebackq eol=; tokens=1,2,* delims=|" %%i in ("%TEST_CMD_FILE%") do (
  if "%%k" == "" ( set "LASTERROR=11" & goto LOCAL_EXIT0 )
  if "%%j" == "" ( set "LASTERROR=12" & goto LOCAL_EXIT0 )
  if "%%i" == "" ( set "LASTERROR=13" & goto LOCAL_EXIT0 )

  rem prefix command
  if not "%%i" == "." (
    call :IF_EXIST "%%i" || ( set "LASTERROR=14" & goto LOCAL_EXIT0 )
    call :CMD pushd "%%i" || ( set "LASTERROR=15" & goto LOCAL_EXIT0 )
    set /A NUM_PUSHD+=1
  )

  rem command
  call :CMD %%k || ( call set "INTERRORLEVEL=%%ERRORLEVEL%%" & set "LASTERROR=16" & goto LOCAL_EXIT0 )

  rem suffix command
  if not "%%j" == "." (
    call :CMD %%j || ( set "LASTERROR=17" & goto LOCAL_EXIT0 )
  )
)

:LOCAL_EXIT0
call :POPD
if %PRINT_COMMAND% NEQ 0 echo.
endlocal
exit /b

:CMD
if %PRINT_COMMAND% NEQ 0 echo.^>%~nx1 %2 %3 %4 %5 %6 %7 %8 %9
(%*) > nul
exit /b

:IF_EXIST
if exist "%~1" exit /b 0
exit /b 1

:POPD
set POPD_INDEX=0
:POPD_LOOP
if %POPD_INDEX% GEQ %NUM_PUSHD% exit /b 0
popd
set /A POPD_INDEX+=1
goto POPD_LOOP

:TEST_REPORT
if %LASTERROR% NEQ 0 (
  rem copy workingset on error
  mkdir "%TEST_SRC_BASE_DIR%\_output\%TEST_TEMP_DIR_NAME%\reference\%TEST_DATA_DIR:*/=%"
  call "%%CONTOOLS_ROOT%%/xcopy_dir.bat" "%%TEST_TEMP_DIR_PATH%%" "%%TEST_SRC_BASE_DIR%%\_output\%%TEST_TEMP_DIR_NAME%%" /Y /H /E > nul
  call "%%CONTOOLS_ROOT%%/xcopy_dir.bat" "%%TEST_DATA_BASE_DIR%%\%%TEST_DATA_DIR%%" "%%TEST_SRC_BASE_DIR%%\_output\%%TEST_TEMP_DIR_NAME%%\reference\%TEST_DATA_DIR:*/=%" /Y /H /E > nul

  echo.FAILED: %__COUNTER1%: ERROR=%LASTERROR%.%INTERRORLEVEL% REFERENCE=`%TEST_DATA_REF_FILE%` OUTPUT=`%TEST_SRC_BASE_DIR%\_output\%TEST_TEMP_DIR_NAME%`
  echo.
  exit /b 0
)

echo.PASSED: %__COUNTER1%: REFERENCE=`%TEST_DATA_REF_FILE%`
if %PRINT_COMMAND% NEQ 0 if %TEST_TEARDOWN%0 NEQ 0 echo.

set /A __PASSED_TESTS+=1

exit /b 0

:TEST_END
set /A __OVERALL_TESTS+=1
set /A __COUNTER1+=1

rem Drop internal variables but use some changed value(s) for the return
(
  endlocal
  set LASTERROR=%LASTERROR%
  set __PASSED_TESTS=%__PASSED_TESTS%
  set __OVERALL_TESTS=%__OVERALL_TESTS%
  set __COUNTER1=%__COUNTER1%
)

goto :EOF

:EXIT
rem Drop internal variables but use some changed value(s) for the return
(
  endlocal
  set LASTERROR=%LASTERROR%
  set __PASSED_TESTS=%__PASSED_TESTS%
  set __OVERALL_TESTS=%__OVERALL_TESTS%
  set __NEST_LVL=%__NEST_LVL%
)

set /A __NEST_LVL-=1

if %__NEST_LVL%0 EQU 0 (
  echo    %__PASSED_TESTS% of %__OVERALL_TESTS% tests is passed.
  pause
)
