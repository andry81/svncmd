#!/bin/bash

# reference: https://stackoverflow.com/questions/2735890/find-svn-revision-by-removed-text
# example: svn_find_rev_with_text_remove.sh "filename" "text to search"

LANG=en_US # to workaround a binary error

file="$1"
REVISIONS=`svn log $file -q --stop-on-copy | grep "^r" | cut -d"r" -f2 | cut -d" " -f1`
for rev in $REVISIONS; do
    prevRev=$(($rev-1))
    difftext=`svn diff --old=$file@$prevRev --new=$file@$rev | tr -s " " | grep -v " -\ \- " | grep -e "$2"`
    if [[ -n "$difftext" ]]; then
        echo "$rev: $difftext"
    fi
done
