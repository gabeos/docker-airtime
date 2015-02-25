#!/bin/bash

DEACTIVATION_DIR=/deactivated

# Deactivate file by moving it to a specific location 
# and caching original location
function deactivate () {
    if [[ $# -eq 0 ]]; then
        echo "deactivate must be called with file path as argument."
    fi
    for TBD_FILE in "$@"; do
        ORIG_DIR=$(dirname $(realpath "$TBD_FILE"))
        BASENAME=$(basename $(realpath "$TBD_FILE"))
        mv "$TBD_FILE" /$DEACTIVATION_DIR/
        echo "$ORIG_DIR" >"/$DEACTIVATION_DIR/$BASENAME.dir"
    done
}

function activate () {
    if [[ $# -eq 0 ]]; then
        echo "activate must be called with file name as argument."
    fi
    for TBA_FILE in $@; do
        if [[ -e /$DEACTIVATION_DIR/$TBA_FILE ]] && \
           [[ -e /$DEACTIVATION_DIR/$TBA_FILE.dir ]]; then
            mv "/$DEACTIVATION_DIR/$TBA_FILE" `cat "/$DEACTIVATION_DIR/$TBA_FILE.dir"`
        fi
    end
}


