//! Create a little domain-specific repl.
//!
//! Wraps rustyline.
//!
//! Everything goes through a single mutable repl state object.
//! The lilrepl provider handles Read and Print.
//! You, the client, specify Evaulation by mapping command strings to handlers.
//!
//! # Features
//! * State is handed to the `LilEvaluator` with:
//!     * Path to current working directory
//!     * Vector of positional arguments, beginning with the command
//!     * Standard output stream
//!     * Standard error stream
//! * Handlers may mutate:
//!     * The path
//!     * Standard output and error streams
//! * Prompt is configurable as a function of state
//!
//! # Example
//! ```
//! use std::collections::HashMap;
//! use protsus::lilrepl::{Result, Lil};
//! use protsus::lilrepl::NArgs::*;
//! use protsus::lilrepl::default_prompter;
//!
//! fn print_arguments(lil: Lil) {
//!     println!("Arguments: {lil.args:?}");
//! }
//!
//! fn main() -> Result<()> {
//!     let commands = HashMap::from([
//!         ("print-arguments", Command {evaluator: print_arguments, nargs: Any}),
//!     ]);
//!     let mut lil = Lil::new(default_prompter, commands)?;
//!
//!     while let Ok(()) = lil.rep();
//! }
//! ```

use std::path::PathBuf;
use std::collections::HashMap;

/// Function type of an evaluator bound to a command
pub type Evaluator = Box<dyn FnOnce(&Lil)>;

/// Error type for lilrepl
pub enum LilreplError {
    /// The repl has exited
    Exit,
    /// The command is not registered with the repl
    InvalidCommandError,
    /// Incorrect number of arguments passed to command
    InvalidNArgsError,
    /// You can't cd above the repl's root
    CdAbovIOErroreRootError,
    /// I/O error
    IOError,
}

/// Return type for lilrepl
pub type Result<T> = std::result::Result<T, LilreplError>;

/// Number of arguments a repl command accepts
pub enum NArgs {
    NArgs(usize),
    Any,
}

/// Command specification
pub struct Command {
    evaluator: Evaluator,
    nargs: NArgs,
}

/// A map from command strings to command specifications
pub type Commands = HashMap<String, Command>;

/// A function that produces a prompt from repl state
pub type Prompter = Box<dyn Fn(&Lil) -> String>;

/// Print path relative to starting directory
pub fn default_prompter(lil: &Lil) -> String {
    format!("{}>", lil.cwd.to_str().or(Err(LilreplError::IOError))?)
}

/// Repl state
pub struct Lil {
    rl: rustyline::DefaultEditor,
    commands: Commands,
    /// Where the repl started
    root: PathBuf,
    cwd: PathBuf,
    args: Vec<String>,
    stdout: String,
    stderr: String,
    prompter: Prompter,
}

impl Lil {
    pub fn new(prompter: Prompter, commands: Commands) -> Result<Lil> {
        let cwd = current_dir?;
        let rl = DefaultEditor::new()?;
        Lil {
            rl,
            commands,
            root: cwd,
            cwd,
            args: Vec::new(),
            stdout: String::new(),
            stderr: String::new(),
            prompter,
        }
    }

    pub fn rep(&self) -> Result<()> {
        // READ
        // Prompt
        let line = match self.rl.readline(self.prompter(self)) {
        // Get input
            Ok(line) => line,
            Err(ReadlineError::Interrupted) => {
                println!("CTRL-C");
                return Err(LilreplError::Exit)
            },
            Err(ReadlineError::Eof) => {
                println!("CTRL-D");
                return Err(LilreplError::Exit)
            },
            Err(err) => {
                println!("Error: {:?}", err);
                return Err(LilreplError::Exit)
            }
        };

        // Tokenise
        let args = shell_words::split(line).or(Err(LilreplError::TokenisationError))?;

        // Match command
        let command = self.commands.get(args).unwrap_or(Err(LilreplError::InvalidCommandError))?;
        // Validate number of arguments
        if let NArgs(n) = command.nargs {
            if n + 1 != lil.args.len() { return Err(LilreplError::InvalidNArgsError); }
        }

        // EVALUATE
        // Run command evaluator
        command.evaluator(&lil)?;

        // PRINT
        // Print standard out
        println!("{}", lil.stdout);
        // Print standard error
        eprintln!("{}", lil.stderr);
        // Change directory
        lil.cwd = lil.cwd.absolute().or(Err(LilreplError::IOError))?;
        if !lil.cwd.starts_with(lil.root) {
            return Err(LilreplError::CdAboveRootError);
        }
        set_current_dir(cwd).or(Err(LilreplError::IOError))?;

        Ok(())
    }
}


// #[cfg(test)]
// mod tests {
//     use super::*;

//     #[test]
//     fn default_prompter_test() {
//         default_prompter(lil)
//     }
// }
