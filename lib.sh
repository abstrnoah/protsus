if test -n "${DEBUG:-}"; then
    set -x
fi

tombstone="skullemoji"

say() {
    echo "$@"
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

gpg() {
    command gpg --no-random-seed-file --armour "$@" 2>/dev/null
}

encrypt_f() {
    local f="$1"
    local pf="$(path_to_protected_path "$f")"
    gpg --output "$pf" --symmetric "$f"
}

encrypt_d() {
    local f="$1"
    local pf="$(path_to_protected_path "$f")"
    tar czpf - "$f" | gpg --output "$pf" --symmetric
}

decrypt_f() {
    local f="$1"
    local pf="$(path_to_protected_path "$f")"
    rm "$f"
    gpg --output "$f" --decrypt "$pf"
}

is_protected() {
    local f="$1"
    local pf="$(path_to_protected_path "$f")"
    test -e "$f" && test -f "$pf"
}

is_locked() {
    local f="$1"
    test -f "$f" && diff <(echo "$tombstone") "$f"
}

is_unlocked() {
    ! is_locked "$@"
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
        protect_d "$f"
    elif test -f "$f"; then
        protect_f "$f"
    else
        oops "protect: Invalid filetype: $f"
    fi
}

protect_f() {
    local f="$1"
    encrypt_f "$f"
    lock "$f"
}

protect_d() {
    local f="$1"
    encrypt_d "$f"
    lock "$f"
}

unlock() {
    local f="$1"
    if ! is_protected "$f"; then
        oops "unlock: You can't unlock an unprotected file."
    fi
    if ! is_locked "$f"; then
        say "Already unlocked: $f"
        return 0
    fi
    if test -d "$f"; then
        decrypt_d "$f"
    elif test -f "$f"; then
        decrypt_f "$f"
    else
        oops "unlock: Invalid filetype: $f"
    fi
}

open() {
    local f="$1"
    if is_protected "$f"; then
        unlock "$f"
    fi
    xdg-open "$f"
}
