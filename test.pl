:- use_module(args).
:- use_module(library(format)).

:- initialization(main).

commands_basic -->
    flag_option(file, ["-f"], [required, help_text("File to read")]).


main :-
    argparse(commands_basic, Res),
    portray_clause(Res).
