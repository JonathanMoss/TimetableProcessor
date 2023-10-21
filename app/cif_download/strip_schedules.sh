#!/bin/bash

set -u

cd $CIF_FOLDER
rm -f AMALGAMATED.CIF
touch AMALGAMATED.CIF

pcregrep -Mh "^BS\X*?(?=^BS|^ZZ)" *.CIF >> AMALGAMATED.CIF
