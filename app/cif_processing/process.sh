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

function update_db () {
  
  echo $(
    curl -X 'POST' \
    "http://api:8000/api/v1/tsdb/import/" \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{"bs": "'"/root/PROC_DIR/$1/bs.csv"'", "bx": "'"/root/PROC_DIR/$1/bx.csv"'", "cr": "'"/root/PROC_DIR/$1/cr.csv"'", "lo": "'"/root/PROC_DIR/$1/lo.csv"'"}'
  )
}

function bs_csv_header {

    echo "id,cif_header,transaction_type,uid,"\
    "date_runs_from,date_runs_to,days_run,"\
    "bank_holiday_running,train_status,"\
    "train_category,train_identity,headcode,"\
    "train_service_code,portion_id,power_type,"\
    "timing_load,speed,operating_characteristics,"\
    "seating_class,sleepers,reservations,catering_code,"\
    "service_branding,stp_indicator"
}

function bx_csv_header {

    echo "bs_id,uic_code,atoc_code,applicable_timetable"

}

function lo_csv_header {

    echo "bs_id,record_type,tiploc,suffix,wta," \
    "wtp,wtd,pta,ptd,platform,line,path,activity," \
    "engineering_allowance,pathing_allowance,performance_allowance"

}

function cr_csv_header {

    echo "bs_id,tiploc,suffix,train_category,train_identity,headcode," \
    "train_service_code,portion_id,power_type,timing_load,speed," \
    "operating_characteristics,seating_class,sleepers,reservations," \
    "catering_code,service_branding,uic_code"

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
    echo $(bs_csv_header) | sed 's/ //g' >> bs.csv
    echo $(bx_csv_header) | sed 's/ //g' >> bx.csv
    echo $(lo_csv_header) | sed 's/ //g' >> lo.csv
    echo $(cr_csv_header) | sed 's/ //g' >> cr.csv
    touch $FILENAME
    gawk -f /root/app/cif_convert.awk ind=$INDEX header=$HEADER $CIF_FOLDER/$FILENAME
    # echo $(update_db $HEADER)
    # Remove empty lines
    for i in *.csv; do
        [ -f "$i" ] || break
        sed -i '/^$/d' $i
    done
    cd ..
done
