#!/bin/bash

set -u

function get_files_to_process {
    # Returns a list of filenames to process from db
    echo $(
        curl -X 'GET' \
        "http://api:8000/api/v1/header/files_to_process/" \
        -H 'accept: application/json'
    )
}

function get_index {
    # This will be a curl command to fetch the next index from the db API
    echo 1
}

cd $PROC_DIR
rm -rf *

FILES_PROC=0
INDEX=$(get_index)
echo $(get_files_to_process) | jq -c '.result[]' --raw-output | while read -r filename;
do
    let "FILES_PROC++"
    mkdir $FILES_PROC
    cd $FILES_PROC
    touch bs.csv bx.csv lo.csv li.csv lt.csv cr.csv
    touch $filename
    gawk -f /root/app/cif_convert.awk ind=$INDEX $CIF_FOLDER/$filename
    # Remove empty lines
    for i in *.csv; do
        [ -f "$i" ] || break
        sed -i '/^$/d' $i
    done
    cd ..
done
