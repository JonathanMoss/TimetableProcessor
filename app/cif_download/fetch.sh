#!/bin/bash

set -u

URL='https://publicdatafeeds.networkrail.co.uk/ntrod/CifFileAuthenticate'
AMALG="$CIF_FOLDER/AMALGAMATED.CIF"

function update_db () {
  
  echo $(
    curl -X 'POST' \
    "http://api:8000/api/v1/header/insert/" \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{"csv_line": "'"$1"'" }'
  )
}

function get_ref {
  echo $(head -n 1 $1 | awk '{print $1}' | cut -d. -f3)
}

function get_date {
  echo $(head -n 1 $1 | awk '{print $1}' | grep -Eo 'PD[0-9]{6}' | sed 's/PD//')
}

function touch_time () {
  
  day="${1:4:2}"
  month="${1:2:2}"
  year="${1:0:2}"
  
  echo "20${year}${month}${day}0000.00"
}

function archive_file_name {

  DATE=$(date -r $AMALG +"%d%m%Y")
  echo "$ARCHIVE_CIF/${DATE}.CIF.lz4"

}

function header_info () {

  header=$(head -n 1 $1)
  
  TMP=$(echo "${header:2:20},"\
  "${header:22:6},"\
  "${header:28:4},"\
  "${header:32:7},"\
  "${header:39:7},"\
  "${header:46:1},"\
  "${header:47:1},"\
  "${header:48:6},"\
  "${header:54:6},"\
  "$2,"\
  "$3,"\
  "$4,"\
  "$5")

  TRIMMED=$(tr -d '[:blank:]' <<< $TMP)
  echo "$TRIMMED,$(date '+%F %H:%M:%S')"
  
}

cd $CIF_FOLDER

# Archive the amalgamated CIF.
if [ -f "$AMALG" ]
then
  echo "Archiving $AMALG"
  lz4 -9 -v -f $AMALG $(archive_file_name)
else
  echo "$AMALG not found"
fi

# Clearout the CIF & Archive folders of stuff we dont want
rm -rf *.CIF *.CIF.gz *.gz *.csv
rm -rf $ARCHIVE_CIF/*.CIF

# Create the header file CSV
touch "$CIF_FOLDER/header_inf.csv"

# Download the latest FULL CIF & un-gzip
FILE="CIF_ALL_FULL_DAILY.CIF"
echo "Downloading $FILE"
curl -L -u $NROD_USER:$NROD_PASS -o $FILE.gz "$URL?type=CIF_ALL_FULL_DAILY&day=toc-full.CIF.gz"

if gzip -t $FILE.gz; then
  FULL_CIF_ARCHIVE_SIZE=$(stat --printf="%s" $FILE.gz)
  echo "Archive size: $FULL_CIF_ARCHIVE_SIZE"
  gzip -d $FILE.gz
  FULL_CIF_SIZE=$(stat --printf="%s" $FILE)
  echo "Uncompressed size: $FULL_CIF_SIZE"
else
  rm $FILE.gz
  exit 1
fi

# Get the file reference
REF=$(get_ref $FILE)
echo "File reference: $REF"

# Get the file date
FULL_DATE=$(get_date $FILE)
echo "File date: $FULL_DATE"

TOUCH=$(touch_time $FULL_DATE)
echo "Full CIF File date: $TOUCH"

# Rename the full CIF and adjust the file date
cp $FILE "$REF.CIF"
touch "$REF.CIF" -t $TOUCH
echo "Saved $REF.CIF to $(pwd)"
full_cif_line=$(header_info $FILE $FULL_CIF_ARCHIVE_SIZE $FULL_CIF_SIZE $FILE.gz $REF.CIF)
echo $full_cif_line >> "$CIF_FOLDER/header_inf.csv"
echo $(update_db "$full_cif_line")
rm $FILE

echo "Looking for incremental CIF"
DAYS=("sat" "sun" "mon" "tue" "wed" "thu")
for DAY in ${DAYS[@]}; do
  INC_FILE="toc-update-$DAY"
  curl -L -u $NROD_USER:$NROD_PASS -o $INC_FILE.gz "$URL?type=CIF_ALL_UPDATE_DAILY&day=$INC_FILE.CIF.gz"
  
  if gzip -t $INC_FILE.gz; then
    UPDATE_CIF_ARCHIVE_SIZE=$(stat --printf="%s" $INC_FILE.gz)
    echo "Archive size: $UPDATE_CIF_ARCHIVE_SIZE"
    gzip -d $INC_FILE.gz
    UPDATE_CIF_SIZE=$(stat --printf="%s" $INC_FILE)
    echo "Uncompressed size: $UPDATE_CIF_SIZE"
  else
    rm $INC_FILE.gz
    continue
  fi

  echo "Processing $INC_FILE"
  # Get the file reference
  REF=$(get_ref $INC_FILE)
  echo "File reference: $REF"

  # Get the file date
  INC_DATE=$(get_date $INC_FILE)
  echo "File date: $INC_DATE"

  # Compare dates
  FULL_CIF_DATE=$(date -d "${FULL_DATE}" +"%y%m%d")
  UPDATE_DATE=$(date -d "${INC_DATE}" +"%y%m%d")
  echo "UPDATE_DATE: $INC_DATE"
  echo "FULL_CIF_DATE: $FULL_DATE" 

  if [ $FULL_CIF_DATE -ge $UPDATE_DATE ];
  then
    echo "Deleting $INC_FILE, date expired"
    rm $INC_FILE
  else
    cp $INC_FILE "$REF.CIF"
    touch "$REF.CIF" -t $(touch_time $INC_DATE)
    echo "Saved $REF.CIF to $(pwd)"
    inc_cif_line=$(header_info $INC_FILE $UPDATE_CIF_ARCHIVE_SIZE $UPDATE_CIF_SIZE $INC_FILE.gz "$REF.CIF")
    echo $inc_cif_line >> "$CIF_FOLDER/header_inf.csv"
    echo $(update_db "$inc_cif_line")
    rm $INC_FILE
  fi

done
echo "Finished"

