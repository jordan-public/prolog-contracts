:- retractall(collect_clauses/2).
:- retractall(collect_all_clauses/1).

% Collect all predicate indicators in the current program, excluding private, foreign, and built-in predicates
collect_all_predicates(Predicates) :-
    findall(Pred/Arity, provable(Pred/Arity), Predicates).

% Collect all clauses for a given predicate
collect_clauses(Pred/Arity, Clauses) :-
    functor(Head, Pred, Arity),
    findall(Head :- Body, clause(Head, Body), Clauses).

% Collect all clauses for all predicates
collect_all_clauses(AllClauses) :-
    collect_all_predicates(Predicates),
    findall(Clause, 
            (member(Pred/Arity, Predicates),
             collect_clauses(Pred/Arity, Clauses),
             member(Clause, Clauses)),
            AllClauses).

% Example usage to get all clauses in the program
% ?- collect_all_clauses(AllClauses).