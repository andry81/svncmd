@echo off

rem Author:   Andrey Dibrov (andry at inbox dot ru)

rem Description:
rem   Svn changeset generation script from 2 externals (externals CSV list).
rem   Generate CSV file with not sorted differences between 2 SVN externals
rem   lists and returns:
rem     > 0 if changeset has errors.
rem     = 0 if changeset has differences.
rem     < 0 if changeset has no differences.

rem   Changeset file per line format:
rem   <S>|<local_path>|<external_path>|<op_rev>|<peg_rev>|<repo>|<prepo>|<peg_prev>|<op_prev>
rem   , where:
rem     <S> - status of external revision:
rem       " " - no changes;
rem       "*" - revision or repo changed;
rem       "+" - external added;
rem       "-" - external removed.
rem     <local_path> - local path from the WC root to the directory with
rem                    externals property.
rem     <external_path> - local path from the directory with externals property
rem                    to the directory with external content.
rem     <op_rev> - new or current operative revision of the external
rem                repository if added/changed, last if removed.
rem     <peg_rev> - new or current PEG revision of the external repository if
rem                 added/changed, last if removed.
rem     <repo> - new or current repository path.
rem     <prepo> - previous repository path.
rem     <peg_prev> - previous PEG revision of the external repository
rem                 if repository is changed.
rem     <op_prev> - previous operative revision of the external repository
rem                 if repository is changed.

rem Examples:
rem 1. call gen_diff_svn_workingset.bat svn_extenals1.lst svn_workingset2.lst svn_workingset_changeset.lst
rem    type svn_workingset_changeset.lst

rem Drop last error level
call;

rem enable delayed expansion to speed overall code iterations
setlocal ENABLEDELAYEDEXPANSION

if 0%SVNCMD_TOOLS_DEBUG_VERBOSITY_LVL% GEQ 3 (echo.^>^>%0 %*) >&3

set "SVN_WORKINGSET_NEXT=%~1"
set "SVN_WORKINGSET_PREV=%~2"
set "SVN_WORKINGSET_DIFF=%~3"

if not exist "!SVN_WORKINGSET_NEXT!" (
  echo.%~nx0: error: svn next externals list file does not exist: "!SVN_WORKINGSET_NEXT!"
  exit /b 1
) >&2

if not exist "!SVN_WORKINGSET_PREV!" (
  echo.%~nx0: error: svn prev externals list file does not exist: "!SVN_WORKINGSET_PREV!"
  exit /b 2
) >&2

rem drop output difference file
del /F /Q /A:-D "!SVN_WORKINGSET_DIFF!" 2>nul
if exist "!SVN_WORKINGSET_DIFF!" (
  echo.%~nx0: error: svn externals differences file could not be recreated: "!SVN_WORKINGSET_DIFF!"
  exit /b 3
) >&2

rem always create an empty file
type nul > "!SVN_WORKINGSET_DIFF!" || exit /b 4

rem load externals lines into variables to speed up overall code iterations
set "LOAD_SVN_WORKINGSET=!SVN_WORKINGSET_NEXT!"
set "SVN_WORKINGSET_LINE_VAR_PREFIX=SVN_WORKINGSET_NEXT_LINE_"
set "SVN_WORKINGSET_NUM_LINES_VAR=SVN_WORKINGSET_NEXT_LINES"
set LASTERROR=0
call :LOAD_SVN_WORKINGSET

if !LASTERROR! NEQ 0 (
  echo.%~nx0: error: svn next externals file is broken: "!SVN_WORKINGSET_NEXT!"
  exit /b !LASTERROR!
) >&2

set "LOAD_SVN_WORKINGSET=!SVN_WORKINGSET_PREV!"
set "SVN_WORKINGSET_LINE_VAR_PREFIX=SVN_WORKINGSET_PREV_LINE_"
set "SVN_WORKINGSET_NUM_LINES_VAR=SVN_WORKINGSET_PREV_LINES"
set LASTERROR=0
call :LOAD_SVN_WORKINGSET

if !LASTERROR! NEQ 0 (
  echo.%~nx0: error: svn previous externals file is broken: "!SVN_WORKINGSET_PREV!"
  exit /b !LASTERROR!
) >&2

set WORKINGSETS_HAS_CHANGES=0

rem make next one workingset a left one, search for changed and added
set SVN_WORKINGSET_SEARCH_T=0
set SVN_WORKINGSET_L_LINE_VAR=SVN_WORKINGSET_NEXT_LINE_
set SVN_WORKINGSET_R_LINE_VAR=SVN_WORKINGSET_PREV_LINE_
set SVN_WORKINGSET_L_LINES_VAR=SVN_WORKINGSET_NEXT_LINES
set SVN_WORKINGSET_R_LINES_VAR=SVN_WORKINGSET_PREV_LINES

call :PROCESS_WORKINGSET_L

rem make previous one workingset a left one, search for removed only
set SVN_WORKINGSET_SEARCH_T=1
set SVN_WORKINGSET_L_LINE_VAR=SVN_WORKINGSET_PREV_LINE_
set SVN_WORKINGSET_R_LINE_VAR=SVN_WORKINGSET_NEXT_LINE_
set SVN_WORKINGSET_L_LINES_VAR=SVN_WORKINGSET_PREV_LINES
set SVN_WORKINGSET_R_LINES_VAR=SVN_WORKINGSET_NEXT_LINES

call :PROCESS_WORKINGSET_L

if %WORKINGSETS_HAS_CHANGES% EQU 0 exit /b -1

exit /b 0

:PROCESS_WORKINGSET_L
set FOR_L_INDEX=1
:PROCESS_WORKINGSET_L_FOR_LOOP
call :PROCESS_LINE_WORKINGSET_L || exit /b
set /A FOR_L_INDEX+=1
if !FOR_L_INDEX! GTR !%SVN_WORKINGSET_L_LINES_VAR%! exit /b 0
goto PROCESS_WORKINGSET_L_FOR_LOOP

:PROCESS_LINE_WORKINGSET_L
set "R_LOCAL_PATH_FOUND="
set "R_EXT_PATH_FOUND="
set R_OP_REV_FOUND=0
set R_PEG_REV_FOUND=0
set R_REPO_FOUND=-

set "L_LOCAL_PATH="
set "L_EXT_PATH="
set "L_OP_REV="
set "L_PEG_REV="
set "L_REPO="
set "SVN_WORKINGSET_L_LINE=!%SVN_WORKINGSET_L_LINE_VAR%%FOR_L_INDEX%!"
for /F "eol=# tokens=1,2,3,4,5 delims=|" %%i in ("!SVN_WORKINGSET_L_LINE!") do (
  set "L_LOCAL_PATH=%%i"
  set "L_EXT_PATH=%%j"
  set "L_OP_REV=%%k"
  set "L_PEG_REV=%%l"
  set "L_REPO=%%m"
)

set WORKINGSET_LOCAL_PATH_FOUND=0
set WORKINGSET_EXT_PATH_FOUND=0
set WORKINGSET_REPO_FOUND=0
set WORKINGSET_REV_CHANGED=0

rem echo.!L_REPO!^|!L_OP_REV!^|!L_PEG_REV!

call :PROCESS_WORKINGSET_R

if !SVN_WORKINGSET_SEARCH_T! EQU 0 (
  if !WORKINGSET_LOCAL_PATH_FOUND! NEQ 0 (
    if !WORKINGSET_EXT_PATH_FOUND! NEQ 0 (
      if !WORKINGSET_REPO_FOUND! NEQ 0 (
        if !WORKINGSET_REV_CHANGED! EQU 0 (
          (echo. ^|!L_LOCAL_PATH!^|!L_EXT_PATH!^|!L_OP_REV!^|!L_PEG_REV!^|!L_REPO!)>>"!SVN_WORKINGSET_DIFF!"
        ) else (
          set WORKINGSETS_HAS_CHANGES=1
          (echo.^*^|!L_LOCAL_PATH!^|!L_EXT_PATH!^|!L_OP_REV!^|!L_PEG_REV!^|!L_REPO!^|!R_REPO_FOUND!^|-^|!R_PEG_REV_FOUND!)>>"!SVN_WORKINGSET_DIFF!"
        )
      ) else (
        set WORKINGSETS_HAS_CHANGES=1
        (echo.^*^|!L_LOCAL_PATH!^|!L_EXT_PATH!^|!L_OP_REV!^|!L_PEG_REV!^|!L_REPO!^|!R_REPO_FOUND!^|!R_PEG_REV_FOUND!^|!R_OP_REV_FOUND!)>>"!SVN_WORKINGSET_DIFF!"
      )
    ) else (
      set WORKINGSETS_HAS_CHANGES=1
      (echo.+^|!L_LOCAL_PATH!^|!L_EXT_PATH!^|!L_OP_REV!^|!L_PEG_REV!^|!L_REPO!)>>"!SVN_WORKINGSET_DIFF!"
    )
  ) else if defined L_LOCAL_PATH (
    set WORKINGSETS_HAS_CHANGES=1
    (echo.+^|!L_LOCAL_PATH!^|!L_EXT_PATH!^|!L_OP_REV!^|!L_PEG_REV!^|!L_REPO!)>>"!SVN_WORKINGSET_DIFF!"
  )
) else if defined L_LOCAL_PATH (
  if !WORKINGSET_LOCAL_PATH_FOUND! EQU 0 (
    set WORKINGSETS_HAS_CHANGES=1
    (echo.-^|!L_LOCAL_PATH!^|!L_EXT_PATH!^|!L_OP_REV!^|!L_PEG_REV!^|!L_REPO!)>>"!SVN_WORKINGSET_DIFF!"
  ) else if !WORKINGSET_EXT_PATH_FOUND! EQU 0 (
    set WORKINGSETS_HAS_CHANGES=1
    (echo.-^|!L_LOCAL_PATH!^|!L_EXT_PATH!^|!L_OP_REV!^|!L_PEG_REV!^|!L_REPO!)>>"!SVN_WORKINGSET_DIFF!"
  )
)

exit /b 0

:PROCESS_WORKINGSET_R
set FOR_R_INDEX=1
:PROCESS_WORKINGSET_R_FOR_LOOP
call :PROCESS_LINE_WORKINGSET_R || exit /b
set /A FOR_R_INDEX+=1
if !FOR_R_INDEX! GTR !%SVN_WORKINGSET_R_LINES_VAR%! exit /b 0
goto PROCESS_WORKINGSET_R_FOR_LOOP

:PROCESS_LINE_WORKINGSET_R
set "R_LOCAL_PATH="
set "R_EXT_PATH="
set "R_OP_REV="
set "R_PEG_REV="
set "R_REPO="
set "SVN_WORKINGSET_R_LINE=!%SVN_WORKINGSET_R_LINE_VAR%%FOR_R_INDEX%!"
for /F "eol=# tokens=1,2,3,4,5 delims=|" %%i in ("!SVN_WORKINGSET_R_LINE!") do (
  set "R_LOCAL_PATH=%%i"
  set "R_EXT_PATH=%%j"
  set "R_OP_REV=%%k"
  set "R_PEG_REV=%%l"
  set "R_REPO=%%m"
)
rem echo R !R_LOCAL_PATH!-!R_EXT_PATH!-!R_OP_REV!-!R_PEG_REV!-!R_REPO!

rem case insensitive compare!
if not "!L_LOCAL_PATH!|!R_LOCAL_PATH!" == "|" ^
if /i "!L_LOCAL_PATH!" == "!R_LOCAL_PATH!" (
  set WORKINGSET_LOCAL_PATH_FOUND=1
  set R_LOCAL_PATH_FOUND=!R_LOCAL_PATH!
  rem case insensitive compare ^(svn supports case sensitive external paths!^)
  if /i "!L_EXT_PATH!" == "!R_EXT_PATH!" (
    set WORKINGSET_EXT_PATH_FOUND=1
    set R_LOCAL_PATH_FOUND=!R_LOCAL_PATH!
    set R_REPO_FOUND=!R_REPO!
    set R_OP_REV_FOUND=!R_OP_REV!
    set R_PEG_REV_FOUND=!R_PEG_REV!
    if "!L_REPO!" == "!R_REPO!" (
      set WORKINGSET_REPO_FOUND=1
      if !L_OP_REV! NEQ !R_OP_REV! set WORKINGSET_REV_CHANGED=1
      if !L_PEG_REV! NEQ !R_PEG_REV! set WORKINGSET_REV_CHANGED=1
      exit /b -1
    )
  )
)

exit /b 0

:LOAD_SVN_WORKINGSET
set SVN_WORKINGSET_INDEX=0
for /F "eol=# tokens=1,2,3,4,5 delims=|" %%i in (!LOAD_SVN_WORKINGSET!) do (
  set "LOCAL_PATH=%%i"
  set "EXT_PATH=%%j"
  set "OP_REV=%%k"
  set "PEG_REV=%%l"
  set "REPO=%%m"
  call :LOAD_LINE_SVN_WORKINGSET || exit /b
)
set "%SVN_WORKINGSET_NUM_LINES_VAR%=!SVN_WORKINGSET_INDEX!"
exit /b 0

:LOAD_LINE_SVN_WORKINGSET
if not defined LOCAL_PATH ( set "LASTERROR=10" && exit /b 1 )
if not defined EXT_PATH ( set "LASTERROR=11" && exit /b 1 )
if not defined OP_REV ( set "LASTERROR=12" && exit /b 1 )
if not defined PEG_REV ( set "LASTERROR=13" && exit /b 1 )
if not defined REPO ( set "LASTERROR=14" && exit /b 1 )
if !OP_REV! LSS 0 ( set "LASTERROR=15" && exit /b 1 )
if !PEG_REV! LSS 0 ( set "LASTERROR=16" && exit /b 1 )

set /A SVN_WORKINGSET_INDEX+=1

set "!SVN_WORKINGSET_LINE_VAR_PREFIX!!SVN_WORKINGSET_INDEX!=!LOCAL_PATH!|!EXT_PATH!|!OP_REV!|!PEG_REV!|!REPO!"

exit /b 0
