#!/usr/bin/env bash

# summarise_cif.sh
# Usage:
#   ./summarise_cif.sh
#   ./summarise_cif.sh TMP
#
# Default input file is TMP.
#
# Handles one or many schedules in the same CIF file.

FILE="${1:-TMP}"

if [[ ! -f "$FILE" ]]; then
    echo "Error: file '$FILE' not found" >&2
    exit 1
fi

awk '
function trim(s) {
    gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", s)
    return s
}

function cif_date(d, yy, mm, dd, yyyy) {
    d = trim(d)

    if (d == "" || length(d) != 6) {
        return ""
    }

    yy = substr(d, 1, 2)
    mm = substr(d, 3, 2)
    dd = substr(d, 5, 2)

    if (yy + 0 >= 70) {
        yyyy = "19" yy
    } else {
        yyyy = "20" yy
    }

    return dd "/" mm "/" yyyy
}

function cif_time(t, hh, mm, half) {
    t = trim(t)

    if (t == "") {
        return ""
    }

    hh = substr(t, 1, 2)
    mm = substr(t, 3, 2)
    half = substr(t, 5, 1)

    if (hh == "" || mm == "") {
        return ""
    }

    if (half == "H") {
        return hh ":" mm "½"
    }

    return hh ":" mm
}

function days_run(bits, result) {
    bits = trim(bits)
    result = ""

    if (substr(bits, 1, 1) == "1") result = result "Mon "
    if (substr(bits, 2, 1) == "1") result = result "Tue "
    if (substr(bits, 3, 1) == "1") result = result "Wed "
    if (substr(bits, 4, 1) == "1") result = result "Thu "
    if (substr(bits, 5, 1) == "1") result = result "Fri "
    if (substr(bits, 6, 1) == "1") result = result "Sat "
    if (substr(bits, 7, 1) == "1") result = result "Sun "

    result = trim(result)

    if (result == "") {
        return "None specified"
    }

    return result
}

function add_location(tiploc, arr, dep, platform, line, path) {
    locations[++loc_count] = sprintf("%s|%s|%s|%s|%s|%s", \
        tiploc, arr, dep, platform, line, path)
}

function print_location(tiploc, arr, dep, platform, line, path) {
    printf "%-10s %-10s %-10s %-8s %-8s %-8s\n", \
        trim(tiploc), cif_time(arr), cif_time(dep), trim(platform), trim(line), trim(path)
}

function reset_schedule() {
    uid = ""
    headcode = ""
    toc = ""
    from_date = ""
    to_date = ""
    days = ""
    start_location = ""
    end_location = ""
    loc_count = 0
    delete locations
}

function print_schedule(i, f) {
    if (!have_schedule) {
        return
    }

    if (schedule_count > 1) {
        print ""
        print ""
    }

    print "Schedule " schedule_count
    print "=========="
    print ""

    printf "Service:           %s to %s\n", \
        start_location == "" ? "Unknown origin" : start_location, \
        end_location == "" ? "Unknown destination" : end_location

    printf "UID:               %s\n", uid == "" ? "Not found" : uid
    printf "Headcode:          %s\n", headcode == "" ? "Not found" : headcode
    printf "TOC code:          %s\n", toc == "" ? "Not found" : toc
    printf "Applicable dates:  %s to %s\n", from_date, to_date
    printf "Days run:          %s\n", days
    print ""

    print "Locations"
    print "---------"
    printf "%-10s %-10s %-10s %-8s %-8s %-8s\n", \
        "TIPLOC", "Arr", "Dep", "Platform", "Line", "Path"

    printf "%-10s %-10s %-10s %-8s %-8s %-8s\n", \
        "------", "---", "---", "--------", "----", "----"

    for (i = 1; i <= loc_count; i++) {
        split(locations[i], f, "|")
        print_location(f[1], f[2], f[3], f[4], f[5], f[6])
    }
}

BEGIN {
    have_schedule = 0
    schedule_count = 0
    reset_schedule()
}

{
    # Remove Windows CR if present
    sub(/\r$/, "")

    rec = substr($0, 1, 2)

    if (rec == "BS") {
        # A new BS starts a new schedule.
        # If we already have one in memory, print it before resetting.

        if (have_schedule) {
            print_schedule()
            reset_schedule()
        }

        have_schedule = 1
        schedule_count++

        # BS - Basic Schedule record
        #
        # 1-2     Record Identity
        # 3       Transaction Type
        # 4-9     Train UID
        # 10-15   Date Runs From
        # 16-21   Date Runs To
        # 22-28   Days Run
        # 33-36   Train Identity / Headcode

        uid       = trim(substr($0, 4, 6))
        from_date = cif_date(substr($0, 10, 6))
        to_date   = cif_date(substr($0, 16, 6))
        days      = days_run(substr($0, 22, 7))
        headcode  = trim(substr($0, 33, 4))
    }

    else if (rec == "BX") {
        # BX - Basic Schedule Extra record
        #
        # Common CIF position:
        # 12-13   ATOC / TOC code

        toc = trim(substr($0, 12, 2))
    }

    else if (rec == "LO") {
        # LO - Origin Location record
        #
        # 1-2     Record Identity
        # 3-10    Location, TIPLOC + Suffix
        # 11-15   Scheduled Departure Time
        # 16-19   Public Departure Time
        # 20-22   Platform
        # 23-25   Line
        # 26-27   Engineering Allowance
        # 28-29   Pathing Allowance
        # 30-41   Activity
        # 42-43   Performance Allowance
        # 44-80   Spare

        start_location = trim(substr($0, 3, 8))

        add_location( \
            substr($0, 3, 8), \
            "", \
            substr($0, 11, 5), \
            substr($0, 20, 3), \
            substr($0, 23, 3), \
            "" \
        )
    }

    else if (rec == "LI") {
        # LI - Intermediate Location record
        #
        # 1-2     Record Identity
        # 3-10    Location, TIPLOC + Suffix
        # 11-15   Scheduled Arrival Time
        # 16-20   Scheduled Departure Time
        # 21-25   Scheduled Pass
        # 26-29   Public Arrival
        # 30-33   Public Departure
        # 34-36   Platform
        # 37-39   Line
        # 40-42   Path
        # 43-54   Activity
        # 55-56   Engineering Allowance
        # 57-58   Pathing Allowance
        # 59-60   Performance Allowance
        # 61-80   Spare

        add_location( \
            substr($0, 3, 8), \
            substr($0, 11, 5), \
            substr($0, 16, 5), \
            substr($0, 34, 3), \
            substr($0, 37, 3), \
            substr($0, 40, 3) \
        )
    }

    else if (rec == "LT") {
        # LT - Terminating Location record
        #
        # 1-2     Record Identity
        # 3-9     TIPLOC
        # 10      Suffix
        # 11-15   Scheduled Arrival Time
        # 16-19   Public Arrival
        # 20-22   Platform
        # 23-25   Path
        # 26-37   Activity
        # 38-40   Reserved
        # 41-80   Spare

        end_location = trim(substr($0, 3, 8))

        add_location( \
            substr($0, 3, 8), \
            substr($0, 11, 5), \
            "", \
            substr($0, 20, 3), \
            "", \
            substr($0, 23, 3) \
        )
    }
}

END {
    # Print the final schedule still held in memory.
    print_schedule()

    if (schedule_count == 0) {
        print "No BS schedule records found in " FILENAME > "/dev/stderr"
        exit 1
    }
}
' "$FILE"