function bs () {

    out='BS',       # Record Type
    out+=${1:2:1},  # Transaction Type
    out+=${1:3:6},  # UID
    out+=${1:9:6},  # Schedule Start Date
    out+=${1:15:6}, # Schedule End Date
    out+=${1:21:7}, # Days Run
    out+=${1:28:1}, # Bank Holiday
    out+=${1:29:1}, # Status
    out+=${1:30:2}, # Category
    out+=${1:32:4}, # Identity
    out+=${1:36:4}, # Headcode
    out+=${1:41:8}, # Service Code
    out+=${1:49:1}, # Portion ID
    out+=${1:50:3}, # Power Type
    out+=${1:53:4}, # Timing Load
    out+=${1:57:3}, # Speed
    out+=${1:60:6}, # Operating Characteristics
    out+=${1:66:1}, # Seating Class
    out+=${1:67:1}, # Sleepers
    out+=${1:68:1}, # Reservations
    out+=${1:70:4}, # Catering Code
    out+=${1:79:1}  # STP Indicator

    echo $out
}

function bx () {

    out='BX',        # Record Type
    out+=${1:11:2},  # ATOC Code
    out+=${1:13:1},  # Applicable Timetable
    out+=${1:14:8}   # Retain Service ID

    echo $out
}

function lo () {

    out='LO',        # Record Type
    out+=${1:2:7},   # TIPLOC
    out+=${1:9:1},   # Suffix
    out+=${1:10:5},  # WTT Dep.
    out+=${1:15:4},  # Public Dep.
    out+=${1:19:3},  # Platform
    out+=${1:22:3},  # Line Out
    out+=${1:25:2},  # Engineering Allowance
    out+=${1:27:2},  # Pathing Allowance
    out+=${1:29:12}, # Activity
    out+=${1:41:2}   # Performance Allowance

    echo $out

}

function li () {

    out='LI',        # Record Type
    out+=${1:2:7},   # TIPLOC
    out+=${1:9:1},   # Suffix
    out+=${1:10:5},  # WTT Arr.
    out+=${1:15:5},  # WTT Dep.
    out+=${1:20:5},  # WTT Pass
    out+=${1:25:4},  # Public Arr.
    out+=${1:29:4},  # Public Dep.
    out+=${1:33:3},  # Platform
    out+=${1:36:3},  # Line
    out+=${1:39:3},  # Path
    out+=${1:42:12}, # Activity
    out+=${1:54:2},  # Engineering Allowance
    out+=${1:56:2},  # Pathing Allowance
    out+=${1:58:2}   # Performance Allowance

    echo $out

}

function lt () {

    out='LT',        # Record Type
    out+=${1:2:7},   # TIPLOC
    out+=${1:9:1},   # Suffix
    out+=${1:10:5},  # WTT Arr.
    out+=${1:15:4},  # Public Arr..
    out+=${1:19:3},  # Platform
    out+=${1:22:3},  # Path
    out+=${1:25:12}, # Activity


    echo $out

}

cd $CIF_FOLDER
# rm -f *.csv
# touch CIF.csv

# while IFS="" read -r line || [ -n "$line" ]
# do
#     case ${line:0:2} in

#         'BS')
#             echo $(bs "$line") >> CIF.csv
#         ;;

#         'BX')
#             echo $(bx "$line") >> CIF.csv
#         ;;

#         'LO')
#             echo $(lo "$line") >> CIF.csv
#         ;;

#         'LI')
#             echo $(li "$line") >> CIF.csv
#         ;;

#         'LT')
#             echo $(lt "$line") >> CIF.csv
#         ;;

#     esac

# done < AMALGAMATED.CIF

# while IFS="" read -r line || [ -n "$line" ]
# do

#     echo "*****"
#     echo $line
#     echo "*****"

# done < <(pcregrep -Mh "^BS\X*?(?=^BS|^ZZ)" *.CIF)

gawk '/^BS\X/,/^BS|^ZZ/' *.CIF

