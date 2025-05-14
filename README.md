# protsus

Protect suspicious evidence from the frosh.

__WARNING:__ This software is not meant for mission-critical encryption. It was created for a fun puzzle, not to protect your social security number. It does use actual encryption (via GnuPG) but does not make much effort to prevent cleartext from persisting on disk.

Created as a component in the 2025 Stack "SERF".

Design goals:
* The commands `ls`, `cd`, etc. should behave like normal except that sometimes the user is prompted for a password.
* The user should not have to use `gpg`, `tar`, or other encryption/archival tools to interact with the directory tree.
* Little effort will be made (in this first version at least) to prevent the so-inclined crewmate from meddling with the directory structure or breaking abstraction. However, encrypted files should _never_ be accessible without the password.
* TODO: Support flavour text

# Installation

## Build with Nix
```sh
# Writes an executable to `result/bin/protsus`.
nix build `github:abstrnoah/protsus`
```

## Get script from GitHub
```sh
curl -L 'https://github.com/abstrnoah/protsus/releases/latest/download/protsus'
```

## Install with readline wrapper
Wrap `protsus` with `readline` to enable nice editing capabilities, using the following script.

```sh
#!/bin/env bash
rlwrap -c /full/path/to/protsus "$@"
```

## Download from GitHub

# Usage

```sh
# Start a shell for the frosh
rlwrap -c protsus frosh

# Start a shell for administration
rlwrap -c protsus admin

# Use `rlwrap -c` to get nice editing features (-c enables tab-completion).
```

`protsus` restricts you to the directory where it is started. That it, you cannot run `cd ..` from the starting directory.

From within the `protsus` prompt, run `help` to see available commands.

# Design

* Ordinary files appear in the tree ordinarily.
* Encrypted files `$f` appear in pairs: An encrypted file `.$f.protsus` and a dummy file `$f`. The existence of `.$f.protsus` implies that `$f` must be decrypted before use.
* Upon decryption,
    * Directories are decrypted onto `$f`.
    * Regular files are decrypted onto `$f`.
* Upon reencryption, unencrypted files are overwritten.
* Files remain decrypted till explicitly `lock`ed.

# Commands

* `protect $f` - Protect a file and leave it in a `lock`ed state. WARNING: The original file is shredded.
* `lock $f` - Lock a protected file, idempotently. It is an error to lock an unprotected file. WARNING: The unprotected file is shredded.
* `unlock $f` - Unlock a protected file, idempotently. It is an error to unlock an unprotected file.
* `cd $f` - Unlock if necessary and move inside a directory. It is an error for `$f` to be a non-directory. Does not conform to the standard `cd` interface.
* `ls` - List the files in the current directory like `tree`. Does not conform to the standard `ls` or `tree` interface.
* `open $command $f` - Unlock if necessary and open a file.
