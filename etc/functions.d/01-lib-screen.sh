# Useful aliases for color codes

# Text Bold
__bold='\e[1m'
# Text Underline
__underline='\e[4m'

# Color Reset
__reset='\e[0m'
__no_color='\e[0m'

# Color escape prefixes
__color_start="\\033["
__color_end="m"
__fg="38;5;"
__bg="48;5;"

# Colors
__black="000"
__grey="008"
__gray="008"
__red="009"
__green="010"
__dark_green="022"
__yellow="011"
__blue="012"
__pink="013"
__cyan="014"
__white="015"
__light_orange="208"
__dark_orange="202"
__purple="089"

# Hestio brand colors
__awsh_brand_bg="056"
__awsh_brand_fg="015"
__awsh_datetime_bg="141"
__awsh_datetime_fg="000"
__awsh_account_bg="129"
__awsh_account_fg="015"
__awsh_region_bg="183"
__awsh_region_fg="000"


# Encode the color FG and BG colors
function _screen_encode_color {

    local -r c_bg=$1
    local -r c_fg=$2
    echo "${__color_start}${__bg}${c_bg};${__fg}${c_fg}${__color_end}"

}


# Simple function to print a horizontal rule
function _screen_print_hr {

    local detected_cols=$(tput cols)
    : "${detected_cols:=80}"

    echo ""
    echo -e "$(counter=0; while [[ ${counter} -lt ${detected_cols} ]]; do echo -n "="; ((counter=counter+1)); done)"
    echo ""

}


# Simple function to print a Top level header
function _screen_print_header_l1 {

    local detected_cols=$(tput cols)
    local whitespace="$(counter=0; while [[ $counter -lt $detected_cols ]]; do echo -n " "; ((counter=counter+1)); done)"
    local hr_line="$(counter=0; while [[ $counter -lt $detected_cols ]]; do echo -n "="; ((counter=counter+1)); done)"

    concat_line=$(printf "= %s %s" "$1" "$whitespace")
    ((detected_cols=detected_cols-2))
    fixed_size_format="%-${detected_cols}.${detected_cols}s ="
    fixed_size_line=$(printf "$fixed_size_format" "$concat_line")

    echo ""
    echo "${hr_line}"
    echo -e "${fixed_size_line}"
    echo "${hr_line}"
    echo ""

}


# Simple function to print a 2nd level header
function _screen_print_header_l2 {

    local detected_cols=$(tput cols)
    local hr_line="$(counter=0; while [[ $counter -lt $detected_cols ]]; do echo -n "="; ((counter=counter+1)); done)"

    concat_line=$(printf "= %s %s" "$1" "$hr_line")
    fixed_size_format="%-${detected_cols}.${detected_cols}s"
    fixed_size_line=$(printf "$fixed_size_format" "$concat_line")

    echo ""
    echo -e "${fixed_size_line}"
    echo ""

}


function _screen_info {
    echo -e "$(_screen_encode_color '' ${__green})INFO: ${__reset}${@}"
}


function _screen_error {
    echo -e "$(_screen_encode_color '' ${__red})ERROR: ${__reset}${@}"
}


function _screen_warn {
    echo -e "$(_screen_encode_color '' ${__yellow})WARNING: ${__reset}${@}"
}
