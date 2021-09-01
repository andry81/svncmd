#!/bin/bash

# Script can be ONLY included by "source" command.
[[ -z "$BASH" || (-n "$BASH_LINENO" && BASH_LINENO[0] -le 0) || "$SVNCMD_PROJECT_ROOT_INIT0_DIR" == "$BASH_SOURCE_DIR" ]] && return

source '/bin/bash_tacklelib' || exit $?

[[ -z "$NEST_LVL" ]] && tkl_declare_global NEST_LVL 0

[[ -z "$SVNCMD_PROJECT_ROOT" ]] && {
  tkl_normalize_path "$BASH_SOURCE_DIR/.." -a || tkl_abort 9
  tkl_export SVNCMD_PROJECT_ROOT                     "${RETURN_VALUE:-*:\$\{SVNCMD_PROJECT_ROOT\}}" # safety: replace by not applicable or unexisted directory if empty
  SVNCMD_PROJECT_ROOT="$RETURN_VALUE"
}

[[ -z "$SVNCMD_PROJECT_EXTERNALS_ROOT" ]] &&         tkl_export SVNCMD_PROJECT_EXTERNALS_ROOT      "$SVNCMD_PROJECT_ROOT/_externals"

[[ -z "$SVNCMD_TOOLS_ROOT" ]] &&                     tkl_export SVNCMD_TOOLS_ROOT                  "$SVNCMD_PROJECT_ROOT/Scripts"

# init external projects

if [[ -f "$SVNCMD_PROJECT_EXTERNALS_ROOT/contools/__init__/__init__.sh" ]]; then
  tkl_include "$SVNCMD_PROJECT_EXTERNALS_ROOT/contools/__init__/__init__.sh" || tkl_abort_include
fi

SVNCMD_PROJECT_ROOT_INIT0_DIR="$BASH_SOURCE_DIR" # including guard

: # resets exit code to 0
