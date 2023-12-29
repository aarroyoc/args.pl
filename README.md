# args.pl
Argument Parser for Scryer Prolog

Declarative express your command line arguments.

```prolog
:- use_module(args).
:- use_module(library(format)).

:- initialization(main).

commands_basic -->
    flag_option(file, ["-f"], [required, help_text("File to read")]).


main :-
    argparse(commands_basic, Res),
    portray_clause(Res).
```

Currently it supports two kinds of options:
 - `toggle_option(Name, Patterns, Options)`, which do not support arguments (are boolean)
 - `flag_option(Name, Patterns, Options)`, which support a single argument

The Name refers to the name of the option and it's the name you need to refer to read back the value in your application.
Patterns is a list of strings containing the patterns to enable that option. They must be one of the following:
 - `-c` a single dash followed by a single alphabetic character
 - `--long` two dashes followed by some text

Options are the additional information we can give to the option. The following ones are supported:

- `required` makes the option mandatory to be present, will show an error if it doesn't
- `help_text(HelpText)` adds a help text for the generated help page.

args autogenerates errors if arguments are passed with a mistake, checks for required arguments and generates a help page accessible via `-h`.
