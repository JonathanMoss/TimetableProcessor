#!/bin/bash

set -u

CSV_ROOT="/var/lib/postgresql/csv"

function delete_expired {
    # Hit the endpoint to delete expired records
    curl -sS -X 'DELETE' \
    'http://api:8000/api/v1/tsdb/delete_expired/' \
    -H 'accept: application/json'    
}

function process_del {
    # Hit the endpoint to process CIF deletions
    curl -sS -X 'DELETE' \
    'http://api:8000/api/v1/tsdb/process_del/' \
    -H 'accept: application/json'    
}

function process_rep {
    # Hit the endpoint to process CIF replacements
    curl -sS -X 'PUT' \
    'http://api:8000/api/v1/tsdb/process_rep/' \
    -H 'accept: application/json'    
}

function truncate_bs {
    # Hit the endpoint to start truncate of basic_schedule table
    curl -sS -X 'DELETE' \
    'http://api:8000/api/v1/tsdb/truncate_bs/' \
    -H 'accept: application/json'
}

function is_full_cif () {
    # Returns 0 if not full cif, 1 if full cif
    response=$(
        curl -sS -X 'GET' \
        "http://api:8000/api/v1/header/get_update/indicator/$1" \
        -H 'accept: application/json'
    )

    full_cif=$(echo $response | jq --raw-output '.result')
    if [[ $full_cif == 'F' ]]; then
        echo '1'
    else
        echo '0'
    fi
}

function get_files_to_process {
    # Returns a list of filenames to process from db
    echo $(
        curl -sS -X 'GET' \
        "http://api:8000/api/v1/header/files_to_process/" \
        -H 'accept: application/json'
    )
}

function save_index {
    # Writes the updated bs.count
    echo $(tail -n 1 bs.csv | awk -F ',' '{print $1}') > ../bs.count
}

function get_index {
    # Return 0 or the last index for bs records
    if ! [ -f bs.count ]; then
        response=$(
            curl -sS -X 'GET' \
            "http://api:8000/api/v1/tsdb/next_index/" \
            -H 'accept: application/json'
        )
        echo $(echo $response | jq -c '.result')
    else
        echo $(tail -n 1 bs.count | awk -F ',' '{print $1}')
    fi
}

function update_db () {
  # Sends a request to import the files into the database
  echo $(
    curl -sS -X 'POST' \
    "http://api:8000/api/v1/tsdb/import/" \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{"bs": "'"$CSV_ROOT/$1/bs.csv"'", "bx": "'"$CSV_ROOT/$1/bx.csv"'", "cr": "'"$CSV_ROOT/$1/cr.csv"'", "lo": "'"$CSV_ROOT/$1/lo.csv"'"}'
  )
}

function bs_csv_header {
    # Returns the BS CSV header row
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
    # Returns the BX CSV header row
    echo "bs_id,uic_code,atoc_code,applicable_timetable"
}

function lo_csv_header {
    # Returns the LO CSV header row
    echo "bs_id,record_type,tiploc,suffix,wta," \
    "wtp,wtd,pta,ptd,platform,line,path,activity," \
    "engineering_allowance,pathing_allowance,performance_allowance"
}

function cr_csv_header {
    # Returns the CR CSV header row
    echo "bs_id,tiploc,suffix,train_category,train_identity,headcode," \
    "train_service_code,portion_id,power_type,timing_load,speed," \
    "operating_characteristics,seating_class,sleepers,reservations," \
    "catering_code,service_branding,uic_code"
}

cd $PROC_DIR
rm -rf *

# Fetch each file to process and loop through...
echo $(get_files_to_process) | jq -rc '.result' | sed 's/[{}]//g' | sed 's/"//g' | sed 's/,/\n/g' | while read -r record;
do

    HEADER=$(echo $record | awk -F: '{print $1}')  # Get the file header index
    FILENAME=$(echo $record | awk -F: '{print $2}') # Get the CIF filename to process

    if [[ -z "${HEADER}" ]]; then
        echo "No records to process"
        exit 1
    fi

    # If its a full CIF, wipe the database
    if [[ $(is_full_cif $HEADER) == '1' ]]; then
        truncate_bs
    fi

    INDEX=$(get_index) # Get the bs_id to start from

    mkdir $HEADER
    cd $HEADER

    # Create the csv files and write headers
    touch bs.csv bx.csv lo.csv cr.csv
    echo $(bs_csv_header) | sed 's/ //g' >> bs.csv
    echo $(bx_csv_header) | sed 's/ //g' >> bx.csv
    echo $(lo_csv_header) | sed 's/ //g' >> lo.csv
    echo $(cr_csv_header) | sed 's/ //g' >> cr.csv
    touch $FILENAME

    # Process each CIF file
    gawk -f /root/app/cif_convert.awk ind=$INDEX header=$HEADER $CIF_FOLDER/$FILENAME

    # Remove empty lines
    for i in *.csv; do
        [ -f "$i" ] || break
        sed -i '/^$/d' $i
    done

    # Import the created records into the database
    update_db $HEADER

    # Update bs.count
    save_index

    cd ..
    process_del
    process_rep
    delete_expired
done



