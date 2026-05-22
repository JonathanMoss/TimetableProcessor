#!/bin/bash

set -u

CIF="/home/$USER/CIF/AMALGAMATED.CIF";
ROOT_REGEX="^BS[NDR]\X+?(?=^BS|^ZZ)"

HOPE="(?ms)^BS[NDR](?:(?!^BS|^ZZ)[\s\S])*?CREWE(?:(?!^BS|^ZZ)[\s\S])*?(?=^BS|^ZZ|\Z)"


while getopts u:h:t: flag
do
    case "${flag}" in
        u) uid=${OPTARG};;
        h) headcode=${OPTARG};;
        t) tiploc=${OPTARG};;
    esac
done

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
    printf '%s\n' "$withtiploc"
    exit 0
fi

if [ -v train ];
then
    printf '%s\n' "$train"
    exit 0
fi

echo "ERROR: Check parameters"

