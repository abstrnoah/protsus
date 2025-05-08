if test -n "${DEBUG:-}"; then
    set -x
fi

tombstone="skullemoji"

say() {
    echo "$0: $@"
}

oops() {
    say "Error:" "$@" >/dev/stderr
    return 1
}

shred() {
    local f="$1"
    say "This message will self-destruct: $f"
    command shred "$f"
    echo "$tombstone" > "$f"
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
    gpg --no-random-seed-file --armour --output "$pf" --symmetric "$f" 2>/dev/null
}

is_protected() {
    local f="$1"
    local pf="$(path_to_protected_path "$f")"
    test -e "$f" && test -f "$pf"
}

is_locked() {
    local f="$1"
    diff -q <(echo "$tombstone") "$f" &>/dev/null
}

lock() {
    local f="$1"
    if ! is_protected "$f"; then
        oops "lock: You can't lock an unprotected file."
    fi
    if is_locked "$f"; then
        say "Already locked: $f"
        return 0
    fi
    say "Locking: $f"
    shred "$f"
}

protect() {
    local f="$1"
    if test -d "$f"; then
        oops "Unimplemented TODO"
    elif test -f "$f"; then
        protect_f "$f"
    else
        oops "protect: Invalid filetype: $f"
    fi
}

protect_f() {
    local f="$1"
    gpg_encrypt "$f"
    lock "$f"
}

unlock() {
    local f="$1"
    if ! is_protected "$f"; then
        oops "unlock: You can't unlock an unprotected file."
    fi
}
