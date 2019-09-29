# Setup of ANSIBLE

# Set the Ansible Config file path
ANSIBLE_CONFIG=${PROJECT_ROOT}/etc/ansible.cfg
ANSIBLE_PLUGINS_ROOT=${PROJECT_ROOT}/lib/ansible
ANSIBLE_HOSTS=${ANSIBLE_PLUGINS_ROOT}/plugins/inventory/ec2.py
EC2_INI_PATH=${ANSIBLE_PLUGINS_ROOT}/plugins/inventory/ec2.ini

export ANSIBLE_CONFIG ANSIBLE_PLUGINS_ROOT EC2_INI_PATH ANSIBLE_HOSTS

# Basic completion for ansible based on the ANSIBLE_HOSTS file
_ansible_targets()
{
    local cur prev opts base
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Local file precedence, then ENV variable, then nothing
    if [ -f "$(pwd)/ansible.hosts" ]; then
        target_list="$(pwd)/ansible.hosts"
    elif [ -f "${ANSIBLE_HOSTS}" ]; then
        target_list="${ANSIBLE_HOSTS}"
    else
        target_list="/dev/null"
    fi

    opts="$(cat "${target_list}" | grep -v '^#' | strings | tr -d '[' | tr -d ']' | sort | uniq)"

    COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
    return 0
}

# Activate the Ansible target completer
if [ -n "$BASH_VERSION" ]; then
    complete -F _ansible_targets ansible
fi
