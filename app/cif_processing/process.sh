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
    response=$(
        curl -X 'GET' \
        "http://api:8000/api/v1/tsdb/next_index/" \
        -H 'accept: application/json'
    )

    echo $(echo $response | jq -c '.result')
}

cd $PROC_DIR
rm -rf *

FILES_PROC=0
INDEX=$(get_index)
echo $(get_files_to_process) | jq -rc '.result' | sed 's/[{}]//g' | sed 's/"//g' | sed 's/,/\n/g' | while read -r record;
do
    HEADER=$(echo $record | awk -F: '{print $1}')
    FILENAME=$(echo $record | awk -F: '{print $2}')
    let "FILES_PROC++"
    mkdir $HEADER
    cd $HEADER
    touch bs.csv bx.csv lo.csv cr.csv
    touch $FILENAME
    gawk -f /root/app/cif_convert.awk ind=$INDEX header=$HEADER $CIF_FOLDER/$FILENAME
    # Remove empty lines
    for i in *.csv; do
        [ -f "$i" ] || break
        sed -i '/^$/d' $i
    done
    cd ..
done
