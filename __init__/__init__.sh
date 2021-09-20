#!/bin/bash

# Script can be ONLY included by "source" command.
[[ -z "$BASH" || (-n "$BASH_LINENO" && BASH_LINENO[0] -le 0) || "$SVNCMD_PROJECT_ROOT_INIT0_DIR" == "$BASH_SOURCE_DIR" ]] && return

source '/bin/bash_tacklelib' || exit $?

tkl_export_path SVNCMD_PROJECT_ROOT_INIT0_DIR "$BASH_SOURCE_DIR" # including guard

[[ -z "$NEST_LVL" ]] && tkl_declare_global NEST_LVL 0

[[ -z "$SVNCMD_PROJECT_ROOT" ]] &&                  tkl_export_path -a -s SVNCMD_PROJECT_ROOT                   "$BASH_SOURCE_DIR/.."
[[ -z "$SVNCMD_PROJECT_EXTERNALS_ROOT" ]] &&        tkl_export_path -a -s SVNCMD_PROJECT_EXTERNALS_ROOT         "$SVNCMD_PROJECT_ROOT/_externals"

[[ -z "$PROJECT_OUTPUT_ROOT" ]] &&                  tkl_export_path -a -s PROJECT_OUTPUT_ROOT                   "$SVNCMD_PROJECT_ROOT/_out"
[[ -z "$PROJECT_LOG_ROOT" ]] &&                     tkl_export_path -a -s PROJECT_LOG_ROOT                      "$SVNCMD_PROJECT_ROOT/.log"

[[ -z "$SVNCMD_PROJECT_INPUT_CONFIG_ROOT" ]] &&     tkl_export_path -a -s SVNCMD_PROJECT_INPUT_CONFIG_ROOT      "$SVNCMD_PROJECT_ROOT/_config"
[[ -z "$SVNCMD_PROJECT_OUTPUT_CONFIG_ROOT" ]] &&    tkl_export_path -a -s SVNCMD_PROJECT_OUTPUT_CONFIG_ROOT     "$PROJECT_OUTPUT_ROOT/config/svncmd"

# init external projects, common dependencies must be always initialized at first

if [[ -f "$SVNCMD_PROJECT_EXTERNALS_ROOT/contools/__init__/__init__.sh" ]]; then
  tkl_include "$SVNCMD_PROJECT_EXTERNALS_ROOT/contools/__init__/__init__.sh" || tkl_abort_include
fi

if [[ -f "$SVNCMD_PROJECT_EXTERNALS_ROOT/tacklelib/__init__/__init__.sh" ]]; then
  tkl_include "$SVNCMD_PROJECT_EXTERNALS_ROOT/tacklelib/__init__/__init__.sh" || tkl_abort_include
fi

tkl_include "$TACKLELIB_BASH_ROOT/tacklelib/buildlib.sh" || tkl_abort_include

[[ ! -e "$PROJECT_OUTPUT_ROOT" ]] && { mkdir -p "$PROJECT_OUTPUT_ROOT" || tkl_abort 10; }
[[ ! -e "$PROJECT_LOG_ROOT" ]] && { mkdir -p "$PROJECT_LOG_ROOT" || tkl_abort 11; }
[[ ! -e "$SVNCMD_PROJECT_OUTPUT_CONFIG_ROOT" ]] && { mkdir -p "$SVNCMD_PROJECT_OUTPUT_CONFIG_ROOT" || tkl_abort 12; }

tkl_include "$TACKLELIB_BASH_ROOT/tacklelib/tools/load_config.sh" || tkl_abort_include

tkl_load_config_dir "$SVNCMD_PROJECT_INPUT_CONFIG_ROOT" "$SVNCMD_PROJECT_OUTPUT_CONFIG_ROOT"

: # resets exit code to 0
