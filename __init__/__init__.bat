@echo off

if /i "%SVNCMD_PROJECT_ROOT_INIT0_DIR%" == "%~dp0" exit /b 0

set "SVNCMD_PROJECT_ROOT_INIT0_DIR=%~dp0"

if not defined NEST_LVL set NEST_LVL=0

if not defined SVNCMD_PROJECT_ROOT                call "%%~dp0canonical_path.bat" SVNCMD_PROJECT_ROOT                "%%~dp0.."
if not defined SVNCMD_PROJECT_EXTERNALS_ROOT      call "%%~dp0canonical_path.bat" SVNCMD_PROJECT_EXTERNALS_ROOT      "%%SVNCMD_PROJECT_ROOT%%/_externals"

if not defined PROJECT_OUTPUT_ROOT                call "%%~dp0canonical_path.bat" PROJECT_OUTPUT_ROOT                "%%SVNCMD_PROJECT_ROOT%%/_out"
if not defined PROJECT_LOG_ROOT                   call "%%~dp0canonical_path.bat" PROJECT_LOG_ROOT                   "%%SVNCMD_PROJECT_ROOT%%/.log"

if not defined SVNCMD_PROJECT_INPUT_CONFIG_ROOT   call "%%~dp0canonical_path.bat" SVNCMD_PROJECT_INPUT_CONFIG_ROOT   "%%SVNCMD_PROJECT_ROOT%%/_config"
if not defined SVNCMD_PROJECT_OUTPUT_CONFIG_ROOT  call "%%~dp0canonical_path.bat" SVNCMD_PROJECT_OUTPUT_CONFIG_ROOT  "%%PROJECT_OUTPUT_ROOT%%/config/svncmd"

if %NO_GEN%0 EQU 0 (
  if not exist "%SVNCMD_PROJECT_OUTPUT_CONFIG_ROOT%\" ( mkdir "%SVNCMD_PROJECT_OUTPUT_CONFIG_ROOT%" || exit /b 10 )
)

if not defined LOAD_CONFIG_VERBOSE if %INIT_VERBOSE%0 NEQ 0 set LOAD_CONFIG_VERBOSE=1

if %NO_GEN%0 EQU 0 (
  call "%%CONTOOLS_ROOT%%/build/load_config_dir.bat" %%* -lite_parse -gen_user_config "%%SVNCMD_PROJECT_INPUT_CONFIG_ROOT%%" "%%SVNCMD_PROJECT_OUTPUT_CONFIG_ROOT%%" || exit /b
) else call "%%CONTOOLS_ROOT%%/build/load_config_dir.bat" %%* -lite_parse "%%SVNCMD_PROJECT_INPUT_CONFIG_ROOT%%" "%%SVNCMD_PROJECT_OUTPUT_CONFIG_ROOT%%" || exit /b

rem init external projects

if exist "%SVNCMD_PROJECT_EXTERNALS_ROOT%/contools/__init__/__init__.bat" (
  call "%%SVNCMD_PROJECT_EXTERNALS_ROOT%%/contools/__init__/__init__.bat" %%* || exit /b
)

if exist "%SVNCMD_PROJECT_EXTERNALS_ROOT%/tacklelib/__init__/__init__.bat" (
  call "%%SVNCMD_PROJECT_EXTERNALS_ROOT%%/tacklelib/__init__/__init__.bat" %%* || exit /b
)

if %NO_GEN%0 EQU 0 (
  call "%%CONTOOLS_ROOT%%/std/mkdir_if_notexist.bat" "%%PROJECT_OUTPUT_ROOT%%" || exit /b 11

  if %NO_LOG%0 EQU 0 (
    call "%%CONTOOLS_ROOT%%/std/mkdir_if_notexist.bat" "%%PROJECT_LOG_ROOT%%" || exit /b 12
  )
)

if defined CHCP call "%%CONTOOLS_ROOT%%/std/chcp.bat" %%CHCP%%

exit /b 0
