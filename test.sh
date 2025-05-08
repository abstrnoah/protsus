#!/bin/env bash

. ./lib.sh

target="./protsus-test-target"
passphrase="1nf3cted"
cleartext="Super secret stuff\n"
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
    diff -q <(unsafe_decrypt "$pf") <(echo -en "$cleartext") >/dev/null
}

check_shred() {
    local f="$1"
    shift
    local cleartext="$1"
    test -f "$f" \
    && ! diff -q <(echo -en "$cleartext") "$f" >/dev/null \
    && diff -q <(echo "$tombstone") "$f" >/dev/null \
    && is_locked "$f" >/dev/null
}

rm -rf "$target"
mkdir -p "$target"
cd "$target"

echo -en "$cleartext" > "$f"
protect "$f"
do_check protect check_protected_file "$(path_to_protected_path "$f")" "$cleartext"
do_check shred check_shred "$f" "$cleartext"
