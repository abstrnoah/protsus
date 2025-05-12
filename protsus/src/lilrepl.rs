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
//! use protsus::lilrepl::{LilreplError, Result, Lil};
//! use protsus::lilrepl::NArgs::*;
//! use protsus::lilrepl::default_prompt;
//!
//! fn print_arguments(lil: Lil) {
//!     println!("Arguments: {lil.args:?}");
//! }
//!
//! fn main() -> Result<()> {
//!     let commands = HashMap::from([
//!         ("print-arguments", Command {evaluator: print_arguments, nargs: Any}),
//!     ]);
//!     let lil = Lil::new(default_prompt, commands);
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
    /// The repl has exited.
    Exit,
}

/// Return type for lilrepl
pub type Result<T> = std::result::Result<T, LilreplError>;

pub enum NArgs {
    NArgs(usize),
    Any,
}

/// Command specification
pub struct Command<F> where F: FnOnce(&Lil) {
    evaluator: F,
    nargs: NArgs,
}

/// Repl state
pub struct Lil {
    pub cwd: PathBuf,
    pub args: Vec<String>,
    commands: HashMap<String, Evaluator>,
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
