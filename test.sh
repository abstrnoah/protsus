#!/bin/env bash

. ./lib.sh

target="./protsus-test-target"
passphrase="infected"
cleartext="Super secret stuff\n"
f="testfile.txt"

# teardown() {
# }
# trap teardown EXIT INT QUIT TERM

do_test() {
    local name="$1"
    shift
    if "$@"; then
        echo "TEST: $name: PASS"
    else
        echo "TEST: $name: FAIL"
    fi
}

check_protected_file() {
    local pf="$1"
    shift
    local cleartext="$1"
    diff -q <(gpg --no-random-seed-file --batch --passphrase "$passphrase" --decrypt "$pf" 2&>/dev/null) <(echo -en "$cleartext") >/dev/null
}

rm -rf "$target"
mkdir -p "$target"
cd "$target"

echo -en "$cleartext" > "$f"
protect "$f"
do_test protect check_protected_file "$(path_to_protected_path "$f")" "$cleartext"
