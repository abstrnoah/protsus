# protsus

Protect sus evidence from the crewmates.

__WARNING:__ This software is not meant for mission-critical encryption. It was created for a fun puzzle, not to protect your social security number. It does use actual encryption (via GnuPG) but does not make much effort to prevent cleartext from persisting on disk.

Created as a component in the 2025 Stack "SERF".

Frosh will be presented with a terminal supporting exactly "three" commands
* `ls` - List the text files and directories in the current directory.
* TODO: `cd` - Change directories, either `..` (up one level) or to a subdirectory. If the subdirectory is password protected, then they will be prompted for the password and, upon successful decryption, the directory will be decrypted and entered.
* `open $command` - Open a file using `$command`. If it is password protected, then they will be prompted for the password.
* `cat` - Run `open cat`.
* `feh` - Run `open feh`.

Design goals
* The commands `ls`, `cd`, `cat`, `feh` should behave like normal except that sometimes the user is prompted for a password.
* The user should not have to use `gpg`, `tar`, or other encryption/archival tools to interact with the directory tree.
* Little effort will be made (in this first version at least) to prevent the so-inclined crewmate from meddling with the directory structure or breaking abstraction. However, encrypted files should _never_ be accessible without the password.
* TODO Support flavour text

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
