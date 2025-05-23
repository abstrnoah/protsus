set -e
if test "${DEBUG:-}" = "x"; then
    set -x
fi

stat_type_f="regular file"
stat_type_d="directory"

verb() {
    if test -n "$DEBUG"; then
        echo "DEBUG:" "$@"
    fi
}

say() {
    echo "$@"
}

oops() {
    say "Error:" "$@" >/dev/stderr
    return 1
}

shred() {
    local f="$1"
    local t="$(stat "$f" -c '%F' 2>/dev/null)"
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
        command cat "$f"
    else
        stat "$f" -c '%F' 2>/dev/null
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
        return
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
        oops "protect: File already protected: $f"
        return
    fi
    if test -d "$f"; then
        protect_d "$f" || return
    elif test -f "$f"; then
        protect_f "$f" || return
    else
        oops "protect: Invalid filetype: $f"
        return
    fi
}

protect_f() {
    local f="$1"
    encrypt_f "$f" || return
    lock "$f"
}

protect_d() {
    local f="$1"
    encrypt_d "$f" || return
    lock "$f"
}

unlock() {
    local f="$1"
    if ! is_protected "$f"; then
        oops "unlock: You can't unlock an unprotected file: $f"
        return
    fi
    if ! is_locked "$f"; then
        say "Already unlocked: $f"
        return 0
    fi
    if is_d "$f"; then
        decrypt_d "$f" || return
    elif is_f "$f"; then
        decrypt_f "$f" || return
    else
        oops "unlock: Invalid filetype: $f"
        return
    fi
}

open() {
    local c="$1"
    shift
    local f="$1"
    if is_protected "$f" &&  is_locked "$f"; then
        unlock "$f" || return
    fi
    "$c" "$f"
}

ls() {
    local f="$1"
    if ! is_d "$f"; then
        oops "ls: Unable to list a non-directory: $f"
        return
    fi
    open tree "$f"
}

og_cat() {
    command cat "$@"
}

cat() {
    local f="$1"
    if ! is_f "$f"; then
        oops "cat: Unable to print a non-regular file: $f"
        return
    fi
    open og_cat "$f"
}

og_feh() {
    command feh "$@"
}

feh() {
    local f="$1"
    if ! is_f "$f"; then
        oops "feh: Unable to view a non-regular file: $f"
        return
    fi
    open og_feh "$f"
}

og_cd() {
    command cd "$@"
}

cd() {
    local f="$1"
    if ! is_d "$f"; then
        oops "cd: Unable to change into a non-directory: $f"
        return
    fi
    open og_cd "$f"
}
