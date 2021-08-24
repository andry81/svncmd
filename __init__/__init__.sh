#!/bin/bash

# Script can be ONLY included by "source" command.
[[ -z "$BASH" || (-n "$BASH_LINENO" && BASH_LINENO[0] -le 0) || "$SVNCMD_PROJECT_ROOT_INIT0_DIR" == "$BASH_SOURCE_DIR" ]] && return 0

source '/bin/bash_tacklelib' || exit $?

SVNCMD_PROJECT_ROOT_INIT0_DIR="$BASH_SOURCE_DIR" # including guard

[[ -z "$NEST_LVL" ]] && NEST_LVL=0

tkl_normalize_path "$BASH_SOURCE_DIR/.." -a && \
SVNCMD_PROJECT_ROOT="$RETURN_VALUE"

[[ -z "$SVNCMD_PROJECT_EXTERNALS_ROOT" ]] &&      tkl_export SVNCMD_PROJECT_EXTERNALS_ROOT      "$SVNCMD_PROJECT_ROOT/_externals"

[[ -z "$CONTOOLS_ROOT" ]] &&                      tkl_export CONTOOLS_ROOT                      "$SVNCMD_PROJECT_EXTERNALS_ROOT/contools/Scripts/Tools"
[[ -z "$CONTOOLS_BUILD_TOOLS_ROOT" ]] &&          tkl_export CONTOOLS_BUILD_TOOLS_ROOT          "$CONTOOLS_ROOT/build"
[[ -z "$CONTOOLS_SQLITE_TOOLS_ROOT" ]] &&         tkl_export CONTOOLS_SQLITE_TOOLS_ROOT         "$CONTOOLS_ROOT/sqlite"
[[ -z "$CONTOOLS_TESTLIB_ROOT" ]] &&              tkl_export CONTOOLS_TESTLIB_ROOT              "$CONTOOLS_ROOT/testlib"
[[ -z "$CONTOOLS_XML_TOOLS_ROOT" ]] &&            tkl_export CONTOOLS_XML_TOOLS_ROOT            "$CONTOOLS_ROOT/xml"
[[ -z "$CONTOOLS_VARS_ROOT" ]] &&                 tkl_export CONTOOLS_VARS_ROOT                 "$CONTOOLS_ROOT/vars"

[[ -z "$SVNCMD_TOOLS_ROOT" ]] &&                  tkl_export SVNCMD_TOOLS_ROOT                  "$SVNCMD_PROJECT_ROOT/Scripts"

[[ -z "$CONTOOLS_UTILITIES_ROOT" ]] &&            tkl_export CONTOOLS_UTILITIES_ROOT            "$SVNCMD_PROJECT_EXTERNALS_ROOT/contools/Utilities"
[[ -z "$CONTOOLS_UTILITIES_BIN_ROOT" ]] &&        tkl_export CONTOOLS_UTILITIES_BIN_ROOT        "$CONTOOLS_UTILITIES_ROOT/bin"
[[ -z "$CONTOOLS_GNUWIN32_ROOT" ]] &&             tkl_export CONTOOLS_GNUWIN32_ROOT             "$CONTOOLS_UTILITIES_BIN_ROOT/gnuwin32"
[[ -z "$CONTOOLS_UTILITIES_HASHDEEP_ROOT" ]] &&   tkl_export CONTOOLS_UTILITIES_HASHDEEP_ROOT   "$CONTOOLS_UTILITIES_BIN_ROOT/hashdeep"
[[ -z "$CONTOOLS_UTILITIES_SQLITE_ROOT" ]] &&     tkl_export CONTOOLS_UTILITIES_SQLITE_ROOT     "$CONTOOLS_UTILITIES_BIN_ROOT/sqlite"

return 0
