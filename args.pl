:- module(args, [argparse/2, flag_option//3]).

:- use_module(library(dcgs)).
:- use_module(library(lists)).
:- use_module(library(iso_ext)).
:- use_module(library(format)).
:- use_module(library(charsio)).

argparse(ArgDescription, ArgResults) :-
    '$toplevel':argv(Argv),
    argparse_(ArgDescription, ArgResults, Argv),
    (
	ArgResults = error(_) ->
	(print_error(ArgResults), halt)
    ;   true),
    (
	member(help, ArgResults) ->
	(print_help(ArgDescription), halt)
    ;   true).

help_option(toggle_option(help, ["-h", "--help"], [help_text("Show the help message")])).

print_error(error(unknown_option(Option))) :-
    format("Unknown option: ~s~n", [Option]).

print_error(error(no_value_supplied(Option))) :-
    format("No value supplied for the ~a option~n", [Option]).

print_error(error(missing_required_argument(Option))) :-
    format("Missing required argument: ~a~n", [Option]).

print_help(Desc) :-
    phrase(Desc, DescList),
    help_option(HelpOption),
    phrase(print_help_([HelpOption|DescList]), HelpText),
    format("~s", [HelpText]).

print_help_(Desc) -->
    print_help_usage_(Desc),
    print_help_options_(Desc).

print_help_usage_(Desc) -->
    "Usage: PROGRAM ",
    print_help_usage_has_options(Desc),
    "\n".

print_help_usage_has_options(Desc) -->
    { member(X, Desc), functor(X, N, _), member(N, [flag_option, toggle_option]) },
    "[OPTIONS] ".

print_help_usage_has_options(Desc) -->
    { member(X, Desc), functor(X, N, _), \+ member(N, [flag_option, toggle_option]) }, "".

print_help_options_(Desc) -->
    "Options:\n",
    print_help_options_line(Desc).

print_help_options_line([]) --> "".
print_help_options_line([X|Xs]) -->
    {
	X = flag_option(_Name, Patterns, Options),
	string_join(Patterns, ", ", PrintPatterns),
	(
	    member(help_text(H), Options) ->
	    HelpText = H
	;   HelpText = ""
	)
    },
    "\t", PrintPatterns, "\t", HelpText, "\n",
    print_help_options_line(Xs).
print_help_options_line([X|Xs]) -->
    {
	X = toggle_option(_Name, Patterns, Options),
	string_join(Patterns, ", ", PrintPatterns),
	(
	    member(help_text(H), Options) ->
	    HelpText = H
	;   HelpText = ""
	)
    },
    "\t", PrintPatterns, "\t", HelpText, "\n",
    print_help_options_line(Xs).

string_join([X], _, X).
string_join([X,Y|Xs], Join, Str) :-
    append(X, Join, Str0),
    string_join([Y|Xs], Join, Str1),
    append(Str0, Str1, Str).

argparse_(Desc, Res, Argv) :-
    phrase(Desc, DescList),
    help_option(HelpOption),
    parse_args(Argv, [HelpOption|DescList], [], Res0),
    (
	member(help, Res0) ->
	Res = Res0
    ;
    (
	Res0 = error(_) ->
	Res = Res0
    ;   required_flags(DescList, Res0, Res))).

parse_args([], _, Res, Res).
parse_args([X|Xs], Desc, Res0, Res) :-
    member(FlagOption, Desc),
    FlagOption = flag_option(Name, Patterns, _Options),
    member(X, Patterns),!,
    parse_args_string(Xs, Desc, Res0, Res, Name).
parse_args([X|Xs], Desc, Res0, Res) :-
    member(ToggleOption, Desc),
    ToggleOption = toggle_option(Name, Patterns, _Options),
    member(X, Patterns),!,
    parse_args(Xs, Desc, [Name|Res0], Res).

parse_args([X|_], _, _, error(unknown_option(X))).

parse_args_string([], _, _, error(no_value_supplied(Name)), Name).
    
parse_args_string([X|Xs], Desc, Res0, Res, Name) :-
    Option =.. [Name, X],
    parse_args(Xs, Desc, [Option|Res0], Res).

required_flags([], Res, Res).
required_flags([X|Xs], Res0, Res) :-
    X = flag_option(Name, _, Options),
    (
	member(required, Options) ->
	(
	    (member(Y, Res0), Y =.. [Name|_]) ->
		required_flags(Xs, Res0, Res)
	    ;   Res = error(missing_required_argument(Name))
	)
    ;   required_flags(Xs, Res0, Res)).
required_flags([X|Xs], Res0, Res) :-
    X = toggle_option(Name, _, Options),
    (
	member(required, Options) ->
	(
	    (member(Y, Res0), Y =.. [Name|_]) ->
		required_flags(Xs, Res0, Res)
	    ;   Res = error(missing_required_argument(Name))
	)
    ;   required_flags(Xs, Res0, Res)).
pattern(X) :-
    X = [(-),C],
    char_type(C, alphabetic),!.
pattern(X) :-
    X = [(-), (-)|_],!.
pattern(X) :-
    throw(invalid_pattern_representation(X)).

flag_option(Name, Patterns, Options) -->
    {
	maplist(pattern, Patterns)
    },
    [flag_option(Name, Patterns, Options)].

toggle_option(Name, Patterns, Options) -->
    {
	maplist(pattern, Patterns)
    },
    [toggle_option(Name, Patterns, Options)].

commands_basic -->
    flag_option(file, ["-f"], [required, help_text("File to read")]).

commands_basic_error -->
    flag_option(file, ["f"], [required, help_text("File to read")]).

test_basic_001 :-
    argparse_(commands_basic, [file("hello.txt")], ["-f", "hello.txt"]).

test_basic_002 :-
    argparse_(commands_basic, error(no_value_supplied(file)), ["-f"]).

test_basic_003 :-
    argparse_(commands_basic, error(unknown_option("-g")), ["-g"]).

test_basic_004 :-
    argparse_(commands_basic, [help], ["-h"]).

test_basic_005 :-
    argparse_(commands_basic, error(missing_required_argument(file)), []).

test_basic_006 :-
    catch(argparse_(commands_basic_error, _, _), invalid_pattern_representation("f"), true).

test :-
    forall((current_predicate(args:Name/0), atom_chars(Name, NameCs), append("test_", _, NameCs)), (
	       portray_clause(executing(Name)),
	       call(args:Name)
	   )),
    halt.
test :- halt(1).
