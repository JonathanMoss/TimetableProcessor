#!/bin/bash

set -u

cd $CIF_FOLDER
rm -rf *.CIF *.CIF.gz
URL='https://publicdatafeeds.networkrail.co.uk/ntrod/CifFileAuthenticate'

function get_ref {
  echo $(head -n 1 $1 | awk '{print $1}' | cut -d. -f3)
}

function get_date {
  echo $(head -n 1 $1 | awk '{print $1}' | grep -Eo 'PD[0-9]{6}' | sed 's/PD//')
}

function touch_time {
  
  DT=$1
  day="${DT:4:2}"
  month="${DT:2:2}"
  year="${DT:0:2}"
  echo $day$month$year
}

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
# echo "File date: $FULL_DATE"

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
  DATE=$(get_date $INC_FILE)
  echo "File date: $(touch_time $DATE)"

  # Compare dates
  FULL_CIF_DATE=$(date -d $TOUCH +"%Y%m%d")
  UPDATE=$(date -d $(touch_time $DATE) +"%Y%m%d")

  if [ $FULL_CIF_DATE -ge $UPDATE ];
  then
    echo "Deleting $INC_FILE, date expired"
    rm $INC_FILE
  else
    mv $INC_FILE "$REF.CIF"
    touch "$REF.CIF" -t $(touch_time $DATE)
    echo "Saved $REF.CIF to $(pwd)"
  fi

done
echo "Finished"

