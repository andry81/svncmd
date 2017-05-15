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

set /A __NEST_LVL+=1

%TEST_PYTHON_PYTEST_CMD_LINE_PREFIX% "pytests/%~n0.py"
set LASTERROR=%ERRORLEVEL%

set /A __NEST_LVL-=1

if %__NEST_LVL% LEQ 0 (
  echo.^
  pause
)

exit /b %LASTERROR%

rem set "TEST_DATA_FILE_SCRIPT_NAME=%~n0"
rem set "?~nx0=%~nx0"
rem 
rem echo Running %~nx0...
rem title %~nx0 %*
rem 
rem set /A __NEST_LVL+=1
rem 
rem set __COUNTER1=1
rem 
rem set ?0=^^
rem 
rem set PRINT_COMMAND=1
rem set LASTERROR=0
rem 
rem rem 0X
rem call :TEST "01" "-r 1" "test_svn_changeset" "range_test_repo" . "%%TEST_DATA_FILE_SCRIPT_NAME%%/exec_checkout_rev.lst" 1
rem call :TEST "02" "-r 2" "test_svn_changeset" "range_test_repo" . "%%TEST_DATA_FILE_SCRIPT_NAME%%/exec_checkout_rev.lst" 2
rem call :TEST "03" "-r 3" "test_svn_changeset" "range_test_repo" . "%%TEST_DATA_FILE_SCRIPT_NAME%%/exec_checkout_rev.lst" 3
rem call :TEST "04" "-r 4" "test_svn_changeset" "range_test_repo" . "%%TEST_DATA_FILE_SCRIPT_NAME%%/exec_checkout_rev.lst" 4
rem 
rem call :TEST_SETUP "test_svn_changeset" "range_test_repo" . "%%TEST_DATA_FILE_SCRIPT_NAME%%/exec_update_comb1.lst" && (
rem   rem 1X
rem   call :TEST "11" "-r 4 -t current"
rem   call :TEST "12" "-r 2: -t current"
rem   call :TEST "12" "-r 2:4 -t current"
rem   call :TEST "14" "-r :3 -t current"
rem   call :TEST "15" "-r !2 -t current"
rem   call :TEST "16" "-r !2:4 -t current"
rem   call :TEST "17" "-r !:3 -t current"
rem 
rem   rem 2X
rem   call :TEST "21" "-r - -t current"
rem   call :TEST "22" "-r 4- -t current"
rem   call :TEST "23" "-r 2:- -t current"
rem   call :TEST "23" "-r 2:4- -t current"
rem   call :TEST "24" "-r :3- -t current"
rem   call :TEST "25" "-r !2- -t current"
rem   call :TEST "26" "-r !2:4- -t current"
rem   call :TEST "27" "-r !:3- -t current"
rem 
rem   call :TEST_TEARDOWN
rem )
rem 
rem echo.
rem 
rem goto EXIT
rem 
rem :TEST
rem setlocal
rem 
rem set LASTERROR=0
rem set INTERRORLEVEL=0
rem 
rem set "TEST_DATA_DIR=%TEST_DATA_FILE_SCRIPT_NAME%/%~1"
rem set "TEST_CMD_LINE=%~2"
rem 
rem set TEST_DO_TEARDOWN=0
rem if %TEST_SETUP%0 EQU 0 (
rem   set TEST_DO_TEARDOWN=1
rem   call :TEST_SETUP %3 %4 %5 %6 %7 || ( set LASTERROR=%ERRORLEVEL% & goto TEST_EXIT ) )
rem )
rem 
rem call :TEST_IMPL
rem 
rem :TEST_EXIT
rem call :TEST_REPORT
rem 
rem if %TEST_DO_TEARDOWN%0 NEQ 0 (
rem   set "TEST_DO_TEARDOWN="
rem   call :TEST_TEARDOWN
rem )
rem 
rem goto TEST_END
rem 
rem :TEST_IMPL
rem call :GET_ABSOLUTE_PATH "%%TEST_DATA_BASE_DIR%%\%%TEST_DATA_DIR%%\output.txt"
rem set "TEST_DATA_REF_FILE=%RETURN_VALUE%"
rem 
rem rem builtin commands
rem pushd "%TEST_SVN_REPOS_ROOT%\%TEST_SVN_CO_REPO_DIR_LIST[0]%" && (
rem   call "%%SVNCMD_TOOLS_ROOT%%/svn_changeset.bat" %%TEST_CMD_LINE%% > "%TEST_DATA_OUT_FILE%"
rem   popd
rem ) || ( call set "INTERRORLEVEL=%%ERRORLEVEL%%" & set "LASTERROR=20" & goto LOCAL_EXIT1 )
rem 
rem if not exist "%TEST_DATA_OUT_FILE%" ( set "LASTERROR=21" & goto LOCAL_EXIT1 )
rem 
rem if not exist "%TEST_DATA_REF_FILE%" ( set "LASTERROR=22" & goto LOCAL_EXIT1 )
rem 
rem fc "%TEST_DATA_OUT_FILE%" "%TEST_DATA_REF_FILE%" > nul
rem if %ERRORLEVEL% NEQ 0 set LASTERROR=23
rem 
rem :LOCAL_EXIT1
rem popd
rem exit /b
rem 
rem :TEST_SETUP
rem if %TEST_SETUP%0 NEQ 0 exit /b -1
rem set TEST_SETUP=1
rem set "TEST_TEARDOWN="
rem 
rem set LASTERROR=0
rem set INTERRORLEVEL=0
rem 
rem call "%%CONTOOLS_ROOT%%/get_datetime.bat"
rem set "SYNC_DATE=%RETURN_VALUE:~0,4%_%RETURN_VALUE:~4,2%_%RETURN_VALUE:~6,2%"
rem set "SYNC_TIME=%RETURN_VALUE:~8,2%_%RETURN_VALUE:~10,2%_%RETURN_VALUE:~12,2%_%RETURN_VALUE:~15,3%"
rem 
rem set "TEST_TEMP_DIR_NAME=%TEST_DATA_FILE_SCRIPT_NAME%.%SYNC_DATE%.%SYNC_TIME%"
rem set "TEST_TEMP_DIR_PATH=%TEST_TEMP_BASE_DIR%\%TEST_TEMP_DIR_NAME%"
rem 
rem mkdir "%TEST_TEMP_DIR_PATH%" || exit /b 1
rem 
rem set "TEST_SVN_REPO_PATH=%~1"
rem set "TEST_SVN_CO_REPO_DIR_LIST=%~2"
rem set "TEST_SVN_CO_BRANCH_PATH_LIST=%~3"
rem set "TEST_CMD_FILE_REL_PATH=%~4"
rem set "TEST_SVN_REVISIONS_LIST=%~5"
rem 
rem set "TEST_SVN_CO_REPO_DIR_LIST.SIZE="
rem call "%%CONTOOLS_ROOT%%/std/append_list_from_string.bat" TEST_SVN_CO_REPO_DIR_LIST 0 -1 "" "%TEST_SVN_CO_REPO_DIR_LIST%"
rem set "TEST_SVN_CO_BRANCH_PATH_LIST.SIZE="
rem call "%%CONTOOLS_ROOT%%/std/append_list_from_string.bat" TEST_SVN_CO_BRANCH_PATH_LIST 0 -1 "" "%TEST_SVN_CO_BRANCH_PATH_LIST%"
rem 
rem call "%%CONTOOLS_ROOT%%/std/iterate_index.bat" "%%TEST_SVN_CO_REPO_DIR_LIST.SIZE%%" INDEX0 ^
rem call "${{CONTOOLS_ROOT}}$/abspath.bat" "${{TEST_DATA_SVN_REPOS_BASE_DIR}}$\${{TEST_SVN_REPO_PATH}}$\${{TEST_SVN_CO_REPO_DIR_LIST[${{INDEX0}}$]}}$\${{TEST_SVN_CO_BRANCH_PATH_LIST[${{INDEX0}}$]}}$" : ^
rem set "TEST_SVN_REPO_PATH_ABS_LIST[${{INDEX0}}$]=${{PATH_VALUE:\=/}}$"
rem 
rem call :GET_ABSOLUTE_PATH "%%TEST_DATA_BASE_DIR%%\%%TEST_CMD_FILE_REL_PATH%%"
rem set "TEST_CMD_FILE=%RETURN_VALUE%"
rem 
rem set "TEST_SVN_REVISIONS_LIST.SIZE="
rem call "%%CONTOOLS_ROOT%%/std/append_list_from_string.bat" TEST_SVN_REVISIONS_LIST 0 -1 "" "%TEST_SVN_REVISIONS_LIST%"
rem 
rem call :GET_ABSOLUTE_PATH "%TEST_TEMP_DIR_PATH%\output.txt"
rem set "TEST_DATA_OUT_FILE=%RETURN_VALUE%"
rem 
rem call :GET_ABSOLUTE_PATH "%%TEST_TEMP_DIR_PATH%%\repos"
rem set "TEST_SVN_REPOS_ROOT=%RETURN_VALUE%"
rem 
rem call :EXEC_TEST_CMD_FILE
rem 
rem exit /b %LASTERROR%
rem 
rem :GET_ABSOLUTE_PATH
rem set "RETURN_VALUE=%~dpf1"
rem exit /b 0
rem 
rem :TEST_TEARDOWN
rem if %TEST_SETUP%0 EQU 0 exit /b -1
rem set "TEST_SETUP="
rem set TEST_TEARDOWN=1
rem 
rem rem cleanup temporary files
rem if not "%TEST_TEMP_DIR_PATH%" == "" ^
rem if exist "%TEST_TEMP_DIR_PATH%\" rmdir /S /Q "%TEST_TEMP_DIR_PATH%"
rem 
rem exit /b 0
rem 
rem :EXEC_TEST_CMD_FILE
rem rem avoid environment variables touch
rem setlocal
rem 
rem pushd "%TEST_TEMP_DIR_PATH%" || ( set "LASTERROR=10" & goto EXEC_TEST_CMD_FILE_EXIT )
rem 
rem set NUM_PUSHD=1
rem 
rem rem command list execution
rem for /F "usebackq eol=; tokens=1,2,* delims=|" %%i in ("%TEST_CMD_FILE%") do (
rem   if "%%k" == "" ( set "LASTERROR=11" & goto LOCAL_EXIT0 )
rem   if "%%j" == "" ( set "LASTERROR=12" & goto LOCAL_EXIT0 )
rem   if "%%i" == "" ( set "LASTERROR=13" & goto LOCAL_EXIT0 )
rem 
rem   rem prefix command
rem   if not "%%i" == "." (
rem     call :IF_EXIST "%%i" || ( set "LASTERROR=14" & goto LOCAL_EXIT0 )
rem     call :CMD pushd "%%i" || ( set "LASTERROR=15" & goto LOCAL_EXIT0 )
rem     set /A NUM_PUSHD+=1
rem   )
rem 
rem   rem command
rem   call :CMD %%k || ( call set "INTERRORLEVEL=%%ERRORLEVEL%%" & set "LASTERROR=16" & goto LOCAL_EXIT0 )
rem 
rem   rem suffix command
rem   if not "%%j" == "." (
rem     call :CMD %%j || ( set "LASTERROR=17" & goto LOCAL_EXIT0 )
rem   )
rem )
rem 
rem :LOCAL_EXIT0
rem call :POPD
rem if %PRINT_COMMAND% NEQ 0 echo.
rem endlocal
rem exit /b
rem 
rem :CMD
rem if %PRINT_COMMAND% NEQ 0 echo.^>%~nx1 %2 %3 %4 %5 %6 %7 %8 %9
rem (%*) > nul
rem exit /b
rem 
rem :IF_EXIST
rem if exist "%~1" exit /b 0
rem exit /b 1
rem 
rem :POPD
rem set POPD_INDEX=0
rem :POPD_LOOP
rem if %POPD_INDEX% GEQ %NUM_PUSHD% exit /b 0
rem popd
rem set /A POPD_INDEX+=1
rem goto POPD_LOOP
rem 
rem :TEST_REPORT
rem if %LASTERROR% NEQ 0 (
rem   rem copy workingset on error
rem   mkdir "%TEST_SRC_BASE_DIR%\_output\%TEST_TEMP_DIR_NAME%\reference\%TEST_DATA_DIR:*/=%"
rem   call "%%CONTOOLS_ROOT%%/xcopy_dir.bat" "%%TEST_TEMP_DIR_PATH%%" "%%TEST_SRC_BASE_DIR%%\_output\%%TEST_TEMP_DIR_NAME%%" /Y /H /E > nul
rem   call "%%CONTOOLS_ROOT%%/xcopy_dir.bat" "%%TEST_DATA_BASE_DIR%%\%%TEST_DATA_DIR%%" "%%TEST_SRC_BASE_DIR%%\_output\%%TEST_TEMP_DIR_NAME%%\reference\%TEST_DATA_DIR:*/=%" /Y /H /E > nul
rem 
rem   echo.FAILED: %__COUNTER1%: ERROR=%LASTERROR%.%INTERRORLEVEL% REFERENCE=`%TEST_DATA_REF_FILE%` OUTPUT=`%TEST_SRC_BASE_DIR%\_output\%TEST_TEMP_DIR_NAME%`
rem   echo.
rem   exit /b 0
rem )
rem 
rem echo.PASSED: %__COUNTER1%: REFERENCE=`%TEST_DATA_REF_FILE%`
rem if %PRINT_COMMAND% NEQ 0 if %TEST_TEARDOWN%0 NEQ 0 echo.
rem 
rem set /A __PASSED_TESTS+=1
rem 
rem exit /b 0
rem 
rem :TEST_END
rem set /A __OVERALL_TESTS+=1
rem set /A __COUNTER1+=1
rem 
rem rem Drop internal variables but use some changed value(s) for the return
rem (
rem   endlocal
rem   set LASTERROR=%LASTERROR%
rem   set __PASSED_TESTS=%__PASSED_TESTS%
rem   set __OVERALL_TESTS=%__OVERALL_TESTS%
rem   set __COUNTER1=%__COUNTER1%
rem )
rem 
rem goto :EOF
rem 
rem :EXIT
rem rem Drop internal variables but use some changed value(s) for the return
rem (
rem   endlocal
rem   set LASTERROR=%LASTERROR%
rem   set __PASSED_TESTS=%__PASSED_TESTS%
rem   set __OVERALL_TESTS=%__OVERALL_TESTS%
rem   set __NEST_LVL=%__NEST_LVL%
rem )
rem 
rem set /A __NEST_LVL-=1
rem 
rem if %__NEST_LVL%0 EQU 0 (
rem   echo    %__PASSED_TESTS% of %__OVERALL_TESTS% tests is passed.
rem   pause
rem )
rem 