# protsus

Protect sus evidence from the crewmates.

Created as a component in the 2025 Stack "SERF".

Frosh will be presented with a terminal supporting exactly three commands
* `ls` - List the text files and directories in the current directory.
* `cd` - Change directories, either `..` (up one level) or to a subdirectory. If the subdirectory is password protected, then they will be prompted for the password and, upon successful decryption, the directory will be decrypted and entered.
* `cat` - Print a file to standard output. If it is password protected, then they will be prompted for the password.

Design goals
* The commands `ls`, `cd`, and `cat` should behave like normal except that sometimes the user is prompted for a password.
* The user should not have to use `gpg`, `tar`, or other encryption/archival tools to interact with the directory tree.
* Little effort will be made (in this first version at least) to prevent the so-inclined user from meddling with the directory structure or breaking abstraction. However, encrypted files should _never_ be accessible without the password.

# Design

* Ordinary files appear in the tree ordinarily.
* Encrypted files `$f` appear in pairs: An encrypted file `.$f.protsus` and a dummy file `$f`. The existence of `.$f.protsus` implies that `$f` must be decrypted before use.
* Upon decryption,
    * Directories are decrypted and mounted onto `$f`.
    * Regular files are decrypted onto `$f`.
* Upon reencryption,
    * Mounted directories are unmounted.
    * Decrypted regular files are `shred`ed.
* Files remain decrypted till explicitly `lock`ed.

# Commands

* `unlock $f` - Unlock a protected file, idempotently. It is an error to unlock an unprotected file.
* `lock $f` - Lock a protected file, idempotently. It is an error to lock an unprotected file.
* `cd $f` - Unlock if necessary and move inside a directory. It is an error for `$f` to be a non-directory. Does not conform to the standard `cd` interface.
* `ls | tree` - List the files in the current directory like `tree`. Does not conform to the standard `ls` or `tree` interface.
* `open $f` - Unlock if necessary and open a regular file (via `xdg-open`). It is an error for `$f` to be a non-regular file.
* `protsus protect $f` - Protect a file and leave it in a `lock`ed state.
