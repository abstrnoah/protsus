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
    if test -z "$gottoend"; then
        teststatus=FAILED
    fi
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

diff_type() {
    test "$(stat "$1" -c '%F')" = "$(stat "$2" -c '%F')"
}

diff() {
    command diff -q "$1" "$2" >/dev/null
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
    is_locked "$f"
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
    command diff -r "$cf" "$f" \
    && is_unlocked "$f"
}

check_open_with_cat() {
    local f="$1"
    shift
    local cf="$1"
    diff <(open og_cat "$f") "$cf"
    lock "$f"
}

check_cat() {
    local f="$1"
    shift
    local cf="$1"
    diff <(cat "$f") "$cf"
    lock "$f"
}

check_ls() {
    local f="$1"
    diff <(ls "$f" | head -n-2 | tail -n+2) -
}

check_pwd() {
    local p="$1"
    test "$p" = "$(pwd)"
}

rm -rf "$target"
mkdir -p "$target"
og_cd "$target"
og_pwd="$PWD"

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
do_check "open cat" check_open_with_cat "$f" "$cf"
do_check "cat" check_cat "$f" "$cf"

cf="$testimage"
f="image.png"
cp "$testimage" "$f"
protect "$f"
do_check "protect" check_protected_file "$(path_to_protected_path "$f")" "$cf"
do_check "lock" check_lock "$f" "$cf"
open feh "$f"
do_check "image unlocked after open" is_unlocked "$f"
lock "$f"
do_check "image locked after open+lock" is_locked "$f"

cf="$temp/cleartree"
f="./dir"
cp -R ../.git "$cf"
cp -R "$cf" "$f"
# encrypt_d "$f"
protect "$f"
do_check "lock" check_lock "$f" "$cf"
do_check "lock idempotent" check_idempotent lock "$f"
unlock "$f"
do_check "unlock" check_unlock "$f/" "$cf/"
lock "$f"

do_check "ls" check_ls . <<EOF
├── dir
├── image.png
└── regular-file
EOF



mkdir -p protected_dir1/protected_dir2/protected_dir3/
echo "$cleartext" > protected_dir1/protected_dir2/protected_dir3/sus_evidence.txt
protect protected_dir1/protected_dir2/protected_dir3/sus_evidence.txt
protect protected_dir1/protected_dir2/protected_dir3
protect protected_dir1/protected_dir2
protect protected_dir1
do_check "ls" check_ls . <<EOF
├── dir
├── image.png
├── protected_dir1
└── regular-file
EOF
unlock "protected_dir1"
do_check "ls after unlock 1" check_ls . <<EOF
├── dir
├── image.png
├── protected_dir1
│   └── protected_dir2
└── regular-file
EOF
unlock "protected_dir1/protected_dir2"
do_check "ls after unlock 2" check_ls . <<EOF
├── dir
├── image.png
├── protected_dir1
│   └── protected_dir2
│       └── protected_dir3
└── regular-file
EOF
unlock "protected_dir1/protected_dir2/protected_dir3"
do_check "ls after unlock 3" check_ls . <<EOF
├── dir
├── image.png
├── protected_dir1
│   └── protected_dir2
│       └── protected_dir3
│           └── sus_evidence.txt
└── regular-file
EOF
unlock "protected_dir1/protected_dir2/protected_dir3/sus_evidence.txt"
cf="$temp/cleartext"
do_check "unlock nested regular file" check_unlock "protected_dir1/protected_dir2/protected_dir3/sus_evidence.txt" "$cf"

lock "protected_dir1/protected_dir2/protected_dir3/sus_evidence.txt"
lock "protected_dir1/protected_dir2/protected_dir3"
lock "protected_dir1/protected_dir2"
lock "protected_dir1"
cd protected_dir1
do_check "pwd" check_pwd "$og_pwd/protected_dir1"
do_check "ls after cd" check_ls . <<EOF
└── protected_dir2
EOF
cd ..
lock protected_dir1
do_check "ls all locked" check_ls . <<EOF
├── dir
├── image.png
├── protected_dir1
└── regular-file
EOF

gottoend=true
