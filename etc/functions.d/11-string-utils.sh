# Reproduces the behaviour of the Python aray.join() function. Copied from the
# awesome example on https://stackoverflow.com/a/17841619
_join_by() {
    local IFS="$1";
    shift;
    echo "$*";
}
