#!/bin/env bash

. ./lib.sh

target="./test-target"
passphrase="1nf3cted"
cleartext="Super secret content"
pf="$(path_to_protected_path "$f")"

testimage=$(readlink -f "./secret-image.png")

teststatus=PASSED


temp="$(mktemp -d \
        || oops "unable to create temporary build directory")"

teardown() {
    echo "RESULTS: $teststatus"
    rm -rf "$temp"
}
trap teardown EXIT INT QUIT TERM

do_check() {
    local name="$1"
    shift
    if "$@"; then
        echo "TEST: $name: PASS"
    else
        echo "TEST: $name: FAIL"
        teststatus=FAILED
    fi
}

unsafe_decrypt() {
    local pf="$1"
    command gpg --batch --pinentry-mode loopback --passphrase "$passphrase" --decrypt "$pf" &>/dev/null \
    || command gpg --decrypt "$pf" 2>/dev/null
}

diff() {
    command diff -q "$@" >/dev/null
}

check_protected_file() {
    local pf="$1"
    shift
    local cf="$1"
    diff <(unsafe_decrypt "$pf") "$cf"
}

check_lock() {
    local f="$1"
    shift
    local cf="$1"
    test -f "$f" \
    && ! diff "$cf" "$f" \
    && diff <(echo "$tombstone") "$f" \
    && is_locked "$f"
}

check_idempotent() {
    local c="$1"
    shift
    local f="$1"
    local pf="$(path_to_protected_path "$f")"
    "$c" "$f" &>/dev/null
    cp "$f" "$temp/$f.old"
    cp "$pf" "$temp/$pf.old"
    "$c" "$f" &>/dev/null
    "$c" "$f" &>/dev/null
    diff "$temp/$f.old" "$f"
    diff "$temp/$pf.old" "$pf"
}

check_unlock() {
    local f="$1"
    shift
    local cf="$1"
    diff "$cf" "$f" \
    && is_unlocked "$f"
}

rm -rf "$target"
mkdir -p "$target"
cd "$target"

cf="$temp/cleartext"
f="regular-file"
echo "$cleartext" > "$cf"
cp "$cf" "$f"
protect "$f"
do_check "protect" check_protected_file "$(path_to_protected_path "$f")" "$cf"
do_check "lock" check_lock "$f" "$cf"
do_check "lock idempotent" check_idempotent lock "$f"
unlock "$f"
do_check "unlock" check_unlock "$f" "$cf"
do_check "unlock idempotent" check_idempotent unlock "$f"
lock "$f"
do_check "lock" check_lock "$f" "$cf"
do_check "lock idempotent" check_idempotent lock "$f"

# cf="$testimage"
# f="image.png"
# cp "$testimage" "$f"
# protect "$f"
# do_check "protect" check_protected_file "$(path_to_protected_path "$f")" "$cf"
# do_check "lock" check_lock "$f" "$cf"
# open "$f"
# do_check "image unlocked after open" is_unlocked "$f"
# lock "$f"
# do_check "image locked after open+lock" is_locked "$f"

cf="$temp"
f="dir"
cp -R .. "$temp"
cp -R "$cf" "$f"
encrypt_d "$f"
