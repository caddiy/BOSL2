#!/bin/bash

OPENSCAD=openscad
if [ "$(uname -s)" == "Darwin" ]; then
    OPENSCAD=/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD
fi

INFILES=("$@")
if (( ${#INFILES[@]} == 0 )); then
    INFILES=(tests/test_*.scad)
fi

OUTCODE=0
for testfile in "${INFILES[@]}"; do
    if [[ -f "$testfile" ]] ; then
        repname="$(basename "$testfile" | sed 's/^test_//')"
        "${OPENSCAD}" -o out.echo --hardwarnings --check-parameters true --check-parameter-ranges true "$testfile" 2>&1
        retcode=$?
        output=$(cat out.echo)
        if (( retcode == 0 )) && [[ "$output" = "" ]]; then
            echo "$repname: PASS"
        else
            echo "$repname: FAIL!"
            echo "$output"
            OUTCODE="$retcode"
        fi
        rm -f out.echo
    fi
done
exit "$OUTCODE"

