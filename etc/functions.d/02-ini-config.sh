# Awesome INI parser in BASH detailed in http://pastebin.com/m4fe6bdaf
# from http://theoldschooldevops.com/2008/02/09/bash-ini-parser/ with some
# updates to help with section capture

# Use as _ini_cfg_parser "${PROJECT_ROOT}/test/sample.ini". Once loaded the
# section names are available from the $_ini_cfg_sections variable
_ini_cfg_parser () {
    fixed_file=$(cat "$1" | grep -v -e "^$" -e"^ *#" -e "^#" | sed -r -e 's/(\S*)(\s*)=(\s*)(.*)/\1=\4/g' ) # fix spaces either side of the '='
    IFS=$'\n' && ini=( $fixed_file )         # convert to line-array
    ini=( ${ini[*]//;*/} )                   # remove ';' comments
    ini=( ${ini[*]/#[/\}$'\n'cfg.section.} ) # set section prefix
    ini=( ${ini[*]/%]/ \(} )                 # convert text2function (1)
    ini=( ${ini[*]/=/=\( } )                 # convert item to array
    ini=( ${ini[*]/%/ \)} )                  # close array parenthesis
    ini=( ${ini[*]/%\( \)/\(\) \{} )         # convert text2function (2)
    ini=( ${ini[*]/%\} \)/\}} )              # remove extra parenthesis
    ini[0]=''                                # remove first element
    ini[${#ini[*]} + 1]='}'                  # add the last brace
    eval "$(echo "${ini[*]}")"               # eval the result to load and import the content
    # Now build a list of section names and expose it as _ini_cfg_get_sections
    _ini_cfg_sections="$(echo "${ini[*]}" | grep -oE '^cfg\.section.*\(' | sed -e 's/\ (//g' | sed -e 's/ /_/g')"
    export _ini_cfg_sections
}

