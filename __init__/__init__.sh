#!/bin/bash

# Script can be ONLY included by "source" command.
[[ -z "$BASH" || (-n "$BASH_LINENO" && BASH_LINENO[0] -le 0) || "$SVNCMD_PROJECT_ROOT_INIT0_DIR" == "$BASH_SOURCE_DIR" ]] && return 0

source '/bin/bash_tacklelib' || exit $?

SVNCMD_PROJECT_ROOT_INIT0_DIR="$BASH_SOURCE_DIR" # including guard

[[ -z "$NEST_LVL" ]] && NEST_LVL=0

tkl_normalize_path "$BASH_SOURCE_DIR/.." -a || tkl_abort 10
SVNCMD_PROJECT_ROOT="$RETURN_VALUE"

[[ -z "$SVNCMD_PROJECT_EXTERNALS_ROOT" ]] &&      tkl_export SVNCMD_PROJECT_EXTERNALS_ROOT      "$SVNCMD_PROJECT_ROOT/_externals"

[[ -z "$SVNCMD_TOOLS_ROOT" ]] &&                  tkl_export SVNCMD_TOOLS_ROOT                  "$SVNCMD_PROJECT_ROOT/Scripts"

# init contools project
if [[ -f "$SVNCMD_PROJECT_EXTERNALS_ROOT/contools/__init__/__init__.sh" ]]; then
  tkl_include "$SVNCMD_PROJECT_EXTERNALS_ROOT/contools/__init__/__init__.sh" || tkl_abort_include
fi

return 0
