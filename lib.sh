set -e
if test -n "${DEBUG:-}"; then
    set -x
fi

stat_type_f="regular file"
stat_type_d="directory"

say() {
    echo "$@"
}

oops() {
    say "Error:" "$@" >/dev/stderr
    return 1
}

shred() {
    local f="$1"
    local t="$(stat "$f" -c '%F')"
    say "This message will self-destruct: $f"
    rm -rf "$f"
    echo "$t" > "$f"
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

decrypt_d() {
    local f="$1"
    local pf="$(path_to_protected_path "$f")"
    rm "$f"
    gpg --decrypt "$pf" | tar xzf -
}

is_protected() {
    local f="$1"
    local pf="$(path_to_protected_path "$f")"
    test -e "$f" && test -f "$pf"
}

is_locked() {
    local f="$1"
    test -f "$f" \
    && (command diff -q <(echo "$stat_type_f") "$f" >/dev/null \
        || command diff -q <(echo "$stat_type_d") "$f" >/dev/null)
}

get_type() {
    local f="$1"
    if is_locked "$f"; then
        cat "$f";
    else
        stat "$f" -c '%F'
    fi
}

is_f() {
    local f="$1"
    test "$(get_type "$f")" = "$stat_type_f"
}

is_d() {
    local f="$1"
    test "$(get_type "$f")" = "$stat_type_d"
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
    if is_protected "$f"; then
        oops "File already protected: $f"
    fi
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
    if is_d "$f"; then
        decrypt_d "$f"
    elif is_f "$f"; then
        decrypt_f "$f"
    else
        oops "unlock: Invalid filetype: $f"
    fi
}

open() {
    local c="$1"
    shift
    local f="$1"
    if ! test -f "$f"; then
        oops "Unable to open non-regular file: $f"
    fi
    if is_protected "$f"; then
        unlock "$f"
    fi
    "$c" "$f"
}
