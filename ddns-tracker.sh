#!/bin/bash
#

# ddns-tracker.sh

# Intended to track DDNS address changes over time for a list of
# hosts and only recording changes from the last address.

# Requires: cut, date, dig, grep, tail

# VARIABLES

site_list="ddns-tracker.conf"
output_file="ddns-tracker.csv"

#
# FUNCTIONS
#

last_address() {
    local site=$1
    local last_addr
    last_addr=$(grep $site $output_file | tail -n 1 | cut -d "," -f 2 )
    if [ -z "$last_addr" ]; then
        last_addr="missing"
    fi
    echo "$last_addr"
}

do_sites() {
    local last_addr
    while read site; do
        current_addr=$(dig +short -t A $site)
        if [ -z "$current_addr" ]; then
            current_addr="lookup error"
        fi
        last_addr=$(last_address $site)
        if [[ "$last_addr" == "missing" ]] || [[ "$current_addr" != "$last_addr" ]]; then
            echo "$site,$current_addr,$(date)" >> $output_file
        fi
    done < $site_list
}

usage() {
    cat <<-EOF

    Options:
    -f [ sitefile ]         list of sites to check [default=$site_list]
    -o [ outfile ]          output filename [default=$output_file]
    -h                      help

EOF
}

#
# MAIN
#

if [ "$#" -ne 0 ]; then
    while getopts "f:o:h" opt; do
        case $opt in
            "f")
                site_list="$OPTARG"
                ;;
            "o")
                output_file="$OPTARG"
                ;;
            :)
                echo "Option -$OPTARG requires an argument." >&2
                usage
                exit 1
                ;;
            "h" | *)
                usage
                exit 1
                ;;
        esac
    done
fi

if [ -z "$site_list" ]; then
    echo "Site list file required, use \"-f filename\" or set script variable"
    usage
    exit 1
fi

if [ ! -r "$site_list" ]; then
    echo "Can't read sitefile: $site_list"
    exit 1
fi

if [ -z "$output_file" ]; then
    echo "Output file required, use \"-o filename\" or set script variable"
    usage
    exit 1
fi

if [ ! -r "$output_file" ]; then
    if [ ! -e "$output_file" ]; then
        touch "$output_file"
        if [ "$?" -ne 0 ]; then
            echo "Can't create output file: $output_file"
            exit 1
        fi
    else
        echo "Can't read output file: $output_file"
        exit 1
    fi
fi

do_sites
