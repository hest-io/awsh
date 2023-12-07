# Attempts to link current branch with matching branch at origin
# _git_upstream_branch_match
function _git_ubm {
    local p_br_name="$(git branch --show-current)"
    git branch --set-upstream-to="origin/${p_br_name}" "${p_br_name}"
}

