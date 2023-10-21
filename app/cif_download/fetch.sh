#!/bin/bash

set -u

URL='https://publicdatafeeds.networkrail.co.uk/ntrod/CifFileAuthenticate'

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

  DATE=$(date -r $CIF_FOLDER/AMALGAMATED.CIF +"%d%m%Y")
  echo "$ARCHIVE_CIF/${DATE}.CIF.lz4"

}

cd $CIF_FOLDER

# Archive the amalgamated CIF.
echo "Archiving AMALGAMATED.CIF"
lz4 -9 -v -f AMALGAMATED.CIF $(archive_file_name)

# Clearout the CIF & Archive folders of stuff we dont want
rm -rf *.CIF *.CIF.gz *.gz *.csv
rm -rf $ARCHIVE_CIF/*.CIF

# Download the latest FULL CIF & un-gzip
FILE="CIF_ALL_FULL_DAILY.CIF"
echo "Downloading $FILE"
curl -L -u $NROD_USER:$NROD_PASS -o $FILE.gz "$URL?type=CIF_ALL_FULL_DAILY&day=toc-full.CIF.gz"

if gzip -t $FILE.gz; then
  gzip -d $FILE.gz
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
mv $FILE "$REF.CIF"
touch "$REF.CIF" -t $TOUCH
echo "Saved $REF.CIF to $(pwd)"

echo "Looking for incremental CIF"
DAYS=("sat" "sun" "mon" "tue" "wed" "thu")
for DAY in ${DAYS[@]}; do
  INC_FILE="toc-update-$DAY"
  curl -L -u $NROD_USER:$NROD_PASS -o $INC_FILE.gz "$URL?type=CIF_ALL_UPDATE_DAILY&day=$INC_FILE.CIF.gz"
  
  if gzip -t $INC_FILE.gz; then
    gzip -d $INC_FILE.gz
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
    mv $INC_FILE "$REF.CIF"
    touch "$REF.CIF" -t $(touch_time $INC_DATE)
    echo "Saved $REF.CIF to $(pwd)"
  fi

done
echo "Finished"

