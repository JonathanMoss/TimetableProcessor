#!/bin/bash

set -u

CIF="/home/$USER/CIF/AMALGAMATED.CIF"

while getopts u:h: flag
do
    case "${flag}" in
        u) pcregrep -Mh "^BS[NDR]{1}${OPTARG}\X*?(?=^BS|^ZZ)" "$CIF" | ack --passthru '(?<=^BS.{30})(.{4})';;
        h) pcregrep -Mh "^BS[NDR]{1}.{29}${OPTARG}\X*?(?=^BS|^ZZ)" "$CIF" | ack --passthru '(?<=^BS.{1})(.{6})';;
    esac
done


