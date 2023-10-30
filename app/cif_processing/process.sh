#!/bin/bash

set -u

function get_index {
    # This will be a curl command to fetch the next index from the db API
    echo 1
}

rm *.csv
touch bs.csv bx.csv lo.csv li.csv lt.csv cr.csv

for i in $CIF_FOLDER/*.CIF; do
    [ -f "$i" ] || break
    gawk -f cif_convert.awk ind=$(get_index) $i
done

# Remove empty lines
for i in *.csv; do
    [ -f "$i" ] || break
    sed -i '/^$/d' $i
done