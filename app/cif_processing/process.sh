cd "${HOME}"/CIF/
# # BS=$(pcregrep -Mh "^BS\X*?(?=^BS|^ZZ)" *.CIF)

# while read -u n; do
#     echo "$n"
#     echo 
# done < <(pcregrep -Mh "^BS\X*?(?=^BS|^ZZ)" *.CIF)

# pcregrep -Mh "^BS\X*?(?=^BS|^ZZ)" *.CIF | awk '{print $0}; END {print "--------"}'

pcregrep -Mh "^BS\X*?(?=^BS|^ZZ)" *.CIF | mapfile