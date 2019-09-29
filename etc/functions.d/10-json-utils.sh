# Extracts a value from a JSON file given a key in Java.properties notation
# json_get_value data.json Vpc.VpcId
_json_get_value() {

    json_file="${1:-/dev/stdin}"
    json_key=$2

    HELPER_SCRIPT="$PROJECT_ROOT/bin/tools/awsh-json2properties.py"

    if [ -f "$json_file" ]; then

        raw_value=$(cat "$json_file" \
                | $HELPER_SCRIPT \
                | grep "^${json_key}=" \
                | awk -F'=' '{print $2}')

        # Get rid of the quotes if needed
        value=$(eval echo "$raw_value")
        echo $value

    fi

}
