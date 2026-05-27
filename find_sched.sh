#!/bin/bash

set -u

while getopts u:h:t:f:d flag
do
    case "${flag}" in
        u) uid=${OPTARG};;
        h) headcode=${OPTARG};;
        t) tiploc=${OPTARG};;
        d) valid_date=true;;
        f) filename=${OPTARG};;

    esac
done

if [ -v filename ];
then
    CIF=$filename
else
    CIF="/home/$USER/CIF/AMALGAMATED.CIF";
fi

# Make sure ZZ is the file terminator (otherwise we may miss last BS record)

# Get last line
last_line=$(tail -n 1 "$CIF")

# Check if it ends with ZZ
if [[ "$last_line" != *ZZ ]]; then
    echo "WARNING: 'ZZ' record terminator not found..."

    # Check if file is writable
    if [ -w "$CIF" ]; then
        echo "Appending $CIF with ZZ"
        echo "ZZ" >> "$CIF"
    else
        echo "WARNING: cannot append 'ZZ'"
    fi
fi


function select_valid() {

    today=$(date +%y%m%d)
    dow=$(date +%u)

    printf '%s\n' "$1" | awk -v today="$today" -v dow="$dow" '

        function is_valid(bs_line) {
            start = substr(bs_line, 10, 6)
            end   = substr(bs_line, 16, 6)
            days  = substr(bs_line, 22, 7)

            return (start <= today && today <= end && substr(days, dow, 1) == "1")
        }

        # When we hit a new BS, decide whether to print the previous block
        substr($0,1,2)=="BS" {

            # If we already have a block buffered, print it if valid
            if (block && valid) {
                print block
            }

            # Start new block
            block = $0
            valid = is_valid($0)

            next
        }

        # Accumulate lines into current block
        {
            block = block "\n" $0
        }

        END {
            # Print last block
            if (block && valid) {
                print block
            }
        }
    '
}

function output() {
    if [ -v valid_date ];
    then
       select_valid "$1"
    else
        printf '%s\n' "$1"
    fi
}

if [ -v uid ] && [ -v headcode ];
then
    echo "ERROR: Select either a UID OR a headcode to search"
    exit 1
fi

if [ -v uid ];
then
    train=$(pcregrep -Mh "^BS[NDR]{1}$uid\X*?(?=^BS|^ZZ)" "$CIF")
fi

if [ -v headcode ];
then
    train=$(pcregrep -Mh "^BS[NDR]{1}.{29}$headcode\X*?(?=^BS|^ZZ)" "$CIF")
fi

if [ -v tiploc ];
then
    if [ -v train ];
    then
        withtiploc=$(echo "$train" | pcregrep -Mh "^BS[NDR](?:(?!^BS|^ZZ)[\s\S])*?$tiploc(?:(?!^BS|^ZZ)[\s\S])*?(?=^BS|^ZZ|\Z)")
    else
        withtiploc=$(pcregrep -Mh "^BS[NDR](?:(?!^BS|^ZZ)[\s\S])*?$tiploc(?:(?!^BS|^ZZ)[\s\S])*?(?=^BS|^ZZ|\Z)" "$CIF")
    fi
fi

if [ -v withtiploc ];
then
    output "$withtiploc"
    exit 0
fi

if [ -v train ];
then
    output "$train"
    exit 0
fi

echo "ERROR: Check parameters"
exit 1

