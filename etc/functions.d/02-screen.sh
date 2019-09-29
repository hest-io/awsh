# Simple function to print a horizontal rule
_print_hr() {

    local COLUMNS=$(tput cols)

    echo ""
    echo -e "$(counter=0; while [ $counter -lt $COLUMNS ]; do echo -n "="; let counter=counter+1; done)"
    echo ""

}


# Simple function to print a Top level header
_print_head_l1() {

    local COLUMNS=$(tput cols)
    local whitespace="$(counter=0; while [ $counter -lt $COLUMNS ]; do echo -n " "; let counter=counter+1; done)"
    local hr_line="$(counter=0; while [ $counter -lt $COLUMNS ]; do echo -n "="; let counter=counter+1; done)"

    concat_line=$(printf "= %s %s" "$1" "$whitespace")
    let COLUMNS=COLUMNS-2
    fixed_size_format="%-${COLUMNS}.${COLUMNS}s ="
    fixed_size_line=$(printf "$fixed_size_format" "$concat_line")

    echo ""
    echo "$hr_line"
    echo -e "$fixed_size_line"
    echo "$hr_line"
    echo ""

}


# Simple function to print a 2nd level header
_print_head_l2() {

    local COLUMNS=$(tput cols)
    local hr_line="$(counter=0; while [ $counter -lt $COLUMNS ]; do echo -n "="; let counter=counter+1; done)"

    concat_line=$(printf "= %s %s" "$1" "$hr_line")
    fixed_size_format="%-${COLUMNS}.${COLUMNS}s"
    fixed_size_line=$(printf "$fixed_size_format" "$concat_line")

    echo ""
    echo -e "$fixed_size_line"
    echo ""

}

