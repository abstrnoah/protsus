if test -n "${DEBUG:-}"; then
    set -x
fi


oops() {
    echo "$0: Error: $@" >/dev/stderr
    return 1
}

# Dummy shred for development
shred() {
    echo "Seriously shredding this file right now"
}

path_to_protected_path() {
    local f="$1"
    local dn="$(dirname "$f")"
    local bn="$(basename "$f")"
    echo "$dn/.$bn.protsus"
}

gpg_encrypt() {
    local f="$1"
    local pf="$(path_to_protected_path "$f")"
    gpg --output "$pf" --symmetric "$f"
}

protect() {
    local f="$1"
    if test -d "$f"; then
        protect_d "$f"
    elif test -f "$f"; then
        protect_f "$f"
    else
        oops "protect: Invalid filetype: $f"
    fi
}

protect_f() {
    local f="$1"
    gpg_encrypt "$f"
    shred "$f"
}

lock() {
    local f="$1"
}

# unlock() {
# }
