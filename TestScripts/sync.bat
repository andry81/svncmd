@echo off

rem Flags:
rem  -R - update root externals recursively.
rem  -r - checkout/relocate/revert/update all branch directories (recursively or not) w/o flag --ignore-externals.
rem       If set then the script will synchronize a parent branch state with children branches through the svn.exe call only.
rem       If not set, then the script will sychronize parent-children databases itself by the wc.db direct access.
rem  -fresh - remove root branch directory content before checkout it.
rem  -ac - auto cleanup all branches before relocate/revert/update to mainly remove all locks.
rem  -ar - auto revert any branch changes.
rem  -arloc - auto relocate to URL from workingset if previous URL is different (repository location + in repository relative path change).

setlocal

if not exist "%~dp0configure.user.bat" ^
if exist "%~dp0configure.bat" ( call "%%~dp0configure.bat" || exit /b 65534 )
if exist "%~dp0configure.user.bat" ( call "%%~dp0configure.user.bat" || exit /b 65533 )

if "%CONTOOLS_ROOT%" == "" set "CONTOOLS_ROOT=%~dp0tools"
set "CONTOOLS_ROOT=%CONTOOLS_ROOT:\=/%"
if "%CONTOOLS_ROOT:~-1%" == "/" set "CONTOOLS_ROOT=%CONTOOLS_ROOT:~0,-1%"

if "%~1" == "" exit /b 65532
if "%~2" == "" exit /b 65531

call "%%CONTOOLS_ROOT%%/scm/svn/sync_branch_workingset.bat" %%3 %%4 %%5 %%6 %%7 %%8 %%9 "%%~1" "%%~2_root_info.txt" "%%~2_root_changeset.lst" "%%~2_root_diff.patch" "%%~2_root_externals.lst" "%%~2_workingset.lst" "%%~2_workingset"
