function bs (line, id) {
    # Formats a Basic Schedule Record into CSV format

    return id "," \
    substr(line, 3, 1) "," \
    substr(line, 4, 6) "," \
    substr(line, 10, 6) "," \
    substr(line, 16, 6) "," \
    substr(line, 22, 7) "," \
    substr(line, 29, 1) "," \
    substr(line, 30, 1) "," \
    substr(line, 31, 2) "," \
    substr(line, 33, 4) "," \
    substr(line, 37, 4) "," \
    substr(line, 42, 8) "," \
    substr(line, 50, 1) "," \
    substr(line, 51, 3) "," \
    substr(line, 54, 4) "," \
    substr(line, 58, 3) "," \
    substr(line, 61, 6) "," \
    substr(line, 67, 1) "," \
    substr(line, 68, 1) "," \
    substr(line, 69, 1) "," \
    substr(line, 71, 4) "," \
    substr(line, 75, 4) "," \
    substr(line, 80, 1) "\n"
}

function bx (line, id) {
    # Formats a Schedule Extra Record into CSV format

    return id "," \
    substr(line, 7, 5) "," \
    substr(line, 12, 2) "," \
    substr(line, 14, 1) "\n"
}

function lo (line, id) {
    # Formats an Origin Location Record into CSV format

    return id "," \
    substr(line, 3, 7) "," \
    substr(line, 10, 1) "," \
    substr(line, 11, 5) "," \
    substr(line, 16, 4) "," \
    substr(line, 20, 3) "," \
    substr(line, 23, 3) "," \
    substr(line, 26, 2) "," \
    substr(line, 28, 2) "," \
    substr(line, 30, 12) "," \
    substr(line, 42, 2) "\n"
}

function li (line, id) {
    # Formats an Intermediate Location Record into CSV format

    return id "," \
    substr(line, 3, 7) "," \
    substr(line, 10, 1) "," \
    substr(line, 11, 5) "," \
    substr(line, 16, 5) "," \
    substr(line, 21, 5) "," \
    substr(line, 26, 4) "," \
    substr(line, 30, 4) "," \
    substr(line, 34, 3) "," \
    substr(line, 37, 3) "," \
    substr(line, 40, 3) "," \
    substr(line, 43, 12) "," \
    substr(line, 55, 2) "," \
    substr(line, 57, 2) "," \
    substr(line, 59, 2) "\n"
}

function lt (line, id) {
    # Formats a Terminating Location Record into CSV format

    return id "," \
    substr(line, 3, 7) "," \
    substr(line, 10, 1) "," \
    substr(line, 11, 5) "," \
    substr(line, 16, 4) "," \
    substr(line, 20, 3) "," \
    substr(line, 23, 3) "," \
    substr(line, 26, 12) "\n"
}

function cr (line, id) {
    # Formats a Change Record into CSV format

    return id "," \
    substr(line, 3, 7) "," \
    substr(line, 10, 1) "," \
    substr(line, 11, 2) "," \
    substr(line, 13, 4) "," \
    substr(line, 17, 4) "," \
    substr(line, 22, 8) "," \
    substr(line, 30, 1) "," \
    substr(line, 31, 3) "," \
    substr(line, 34, 4) "," \
    substr(line, 38, 3) "," \
    substr(line, 41, 6) "," \
    substr(line, 47, 1) "," \
    substr(line, 48, 1) "," \
    substr(line, 49, 1) "," \
    substr(line, 51, 4) "," \
    substr(line, 55, 4) "," \
    substr(line, 63, 5) "\n"
   
}

function write_files () {
# Updates the CSV records to the respective files

    NUM_PROC=0
    print BS >> "bs.csv"
    BS=""
    print BX >> "bx.csv"
    BX=""
    print LO >> "lo.csv"
    LO=""
    print LI >> "li.csv"
    LI=""
    print LT >> "lt.csv"
    LT=""
    print CR >> "cr.csv"
    CR=""
}

BEGIN { 

    split( ARGV[1], splitVar, "=" )
    IND=int(splitVar[2])
    NUM_PROC=0
    BS=""
    BX=""
    LO=""
    LI=""
    LT=""
    CR=""
    
}

{
    switch (substr ($0, 0, 2)) {
        case "BS":
            NUM_PROC+=1
            BS=BS bs($0, IND+=1)
            break
        case "BX":
            BX=BX bx($0, IND)
            break
        case "LO":
            LO=LO lo($0, IND)
            break
        case "LI":
            LI=LI li($0, IND)
            break
        case "LT":
            LT=LT lt($0, IND)
            break
        case "CR":
            CR=CR cr($0, IND)
            break
    }
    
    if (NUM_PROC == 1000) {
        write_files()
    }

}

END {
    if (NUM_PROC > 0 && NUM_PROC < 1000) {
        write_files()
    }
}