# protsus

Protect suspicious evidence from the frosh.

__WARNING:__ This software is not meant for mission-critical encryption. It was created for a fun puzzle, not to protect your social security number. It does use actual encryption (via GnuPG) but does not make much effort to prevent cleartext from persisting on disk.

Created as a component in the 2025 Stack "SERF".

# Installation

This package comprises three scripts:
* `protsus-core` - Is the core script, lacking readline support. Install to your PATH as `protsus-core`.
* `protsus` - Wraps core with `rlwrap -c`, which gives it nice readline features. Install to PATH as `protsus`.
* `protsus-frosh-shell` - Is a script meant to be set as the frosh's login shell, takes no arguments.

## Build with Nix
```sh
# Write the three executables to `result/bin/`
nix build `github:abstrnoah/protsus`

# Install the scripts to PATH
cp result/bin/* /bin/

# Set the frosh login shell to protsus
chsh -s /bin/protsus-frosh-shell FROSH_USERNAME
```

## Curl from GitHub
```sh
# Download tarball from GitHub and extract executables to `result/bin/`
curl -L https://github.com/abstrnoah/protsus/releases/latest/download/protsus.tar.gz | tar xzpf -

# Install the scripts to PATH
cp result/bin/* /bin/

# Set the frosh login shell to protsus
chsh -s /bin/protsus-frosh-shell FROSH_USERNAME
```

# Usage

```sh
# Start a shell for the frosh
protsus frosh

# Start a shell for administration
protsus admin
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

# TODO
* Flavour text?
