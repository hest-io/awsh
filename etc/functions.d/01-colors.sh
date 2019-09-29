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


__get_color_escape() {

    local c_bg=$1
    local c_fg=$2
    echo "${__color_start}${__bg}${c_bg};${__fg}${c_fg}${__color_end}"

}
