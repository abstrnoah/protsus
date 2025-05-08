#!/bin/env bash

. ./lib.sh

target="./protsus-test-target"
passphrase="1nf3cted"
cleartext="Super secret stuff"
f="testfile.txt"

# teardown() {
# }
# trap teardown EXIT INT QUIT TERM

do_check() {
    local name="$1"
    shift
    if "$@"; then
        echo "TEST: $name: PASS"
    else
        echo "TEST: $name: FAIL"
    fi
}

unsafe_decrypt() {
    local pf="$1"
    gpg --batch --pinentry-mode loopback --passphrase "$passphrase" --decrypt "$pf" &>/dev/null \
    || gpg --decrypt "$pf" 2>/dev/null
}

check_protected_file() {
    local pf="$1"
    shift
    local cleartext="$1"
    diff -q <(unsafe_decrypt "$pf") <(echo "$cleartext") >/dev/null
}

check_lock() {
    local f="$1"
    shift
    local cleartext="$1"
    test -f "$f" \
    && ! diff -q <(echo "$cleartext") "$f" >/dev/null \
    && diff -q <(echo "$tombstone") "$f" >/dev/null \
    && is_locked "$f" >/dev/null
}

check_lock_idempotent() {
    local f="$1"
    local pf="$(path_to_protected_path "$f")"
    lock "$f" &>/dev/null
    local f_contents="$(cat "$f")"
    local pf_contents="$(cat "$pf")"
    lock "$f" &>/dev/null
    lock "$f" &>/dev/null
    diff -q <(lock "$f") <(echo "$0: Already locked: $f")
    diff -q <(echo "$f_contents") "$f"
    diff -q <(echo "$pf_contents") "$pf"
}

check_unlock_idempotent() {
    local f="$1"
    local pf="$(path_to_protected_path "$f")"
    unlock "$f" &>/dev/null
    local f_contents="$(cat "$f")"
    local pf_contents="$(cat "$pf")"
    unlock "$f" &>/dev/null
    unlock "$f" &>/dev/null
    diff -q <(unlock "$f") <(echo "$0: Already unlocked: $f")
    diff -q <(echo "$f_contents") "$f"
    diff -q <(echo "$pf_contents") "$pf"
}

check_unlock() {
    local f="$1"
    shift
    local cleartext="$1"
    diff -q <(echo "$cleartext") "$f" >/dev/null
}

rm -rf "$target"
mkdir -p "$target"
cd "$target"

echo "$cleartext" > "$f"
protect "$f"
do_check "protect" check_protected_file "$(path_to_protected_path "$f")" "$cleartext"
do_check "lock" check_lock "$f" "$cleartext"
do_check "lock idempotent" check_lock_idempotent "$f"

unlock "$f"
do_check "unlock" check_unlock "$f" "$cleartext"
do_check "unlock idempotent" check_unlock_idempotent "$f"
lock "$f"
do_check "lock" check_lock "$f" "$cleartext"
do_check "lock idempotent" check_lock_idempotent "$f"
