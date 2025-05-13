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
//! use rustyline::error::ReadlineError;
//! use rustyline::{DefaultEditor, Result};
//! use protsus::lilrepl::{LilreplError, Result, Lil};
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
    Io,
    Eof,
    /// The repl has exited
    Exit,
    /// The command is not registered with the repl
    InvalidCommandError,
    /// Incorrect number of arguments passed to command
    InvalidNArgsError,
}

/// Return type for lilrepl
pub type Result<T> = std::result::Result<T, LilreplError>;

pub enum NArgs {
    NArgs(usize),
    Any,
}

/// Command specification
pub struct Command {
    evaluator: Evaluator,
    nargs: NArgs,
}

/// A map of command specifications
pub type Commands = HashMap<String, Command>;

/// A function that produces a prompt from repl state
pub type Prompter = Box<dyn Fn(&Lil) -> String>;

/// Repl state
pub struct Lil {
    rl: DefaultEditor,
    commands: Commands,
    root: PathBuf,
    pub cwd: PathBuf,
    pub args: Vec<String>,
    pub stdout: String,
    pub stderr: String,
    prompter: Prompter,
}

impl Lil {
    pub fn new(prompter: Prompter, commands: Commands) -> Result<Lil> {
        let cwd = current_dir?;
        let rl = DefaultEditor::new()?;
        Lil {
            rl: rl,
            commands: commands,
            root: cwd,
            cwd: cwd,
            args: Vec::new(),
            stdout: String::new(),
            stderr: String::new(),
            prompter: Prompter,
        }
    }

    pub fn rep(&self) {
        // READ
        // Prompt
        let line = match self.rl.readline(self.prompter(self)) {
        // Get input
            Ok(line) => line,
            Err(ReadlineError::Interrupted) => {
                println!("CTRL-C");
                return LilreplError::Exit
            },
            Err(ReadlineError::Eof) => {
                println!("CTRL-D");
                return LilreplError::Exit
            },
            Err(err) => {
                println!("Error: {:?}", err);
                return LilreplError::Exit
            }
        };

        // Tokenise
        let args = shell_words::split(line)?;

        // Match command
        let command = match self.commands.get(args) {
            Some(command) => command,
            None => return Err(InvalidCommandError),
        };
        // Validate number of arguments
        if let NArgs(n) = command.nargs {
            if n + 1 != lil.args.len() return Err(InvalidNArgsError);
        }

        // EVALUATE
        // Run command evaluator
        command.evaluator(&lil);

        // PRINT
        // Print standard out
        // Print standard error
        // Change directory

        Ok(())
    }
}




// #[cfg(test)]
// mod tests {
//     use super::*;

//     #[test]
//     fn it_works() {
//         let result = add(2, 2);
//         assert_eq!(result, 4);
//     }
// }
