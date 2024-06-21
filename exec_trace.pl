exec_trace(Goal, Knowledge, Trace) :-
    exec_trace([Goal], Knowledge, [], RevTrace),
    reverse(Trace, RevTrace).

exec_trace([], _, Trace, Trace).
exec_trace([Goal|Goals], Knowledge, Trace, NewTrace) :-
    copy_term(Knowledge, BoundKnowledge),
    member(Goal, BoundKnowledge),
    exec_trace(Goals, Knowledge, [Goal|Trace], NewTrace).
exec_trace([Goal|Goals], Knowledge, Trace, NewTrace) :-
    copy_term(Knowledge, BoundKnowledge),    
    member(Goal :- Body, BoundKnowledge),
    pair_to_list(Body, BodyList),
    append(BodyList, Goals, NewGoals),
    exec_trace(NewGoals, Knowledge, [Goal :- Body|Trace], NewTrace).

pair_to_list(Pair, [Pair]) :-
    Pair \= (_, _).
pair_to_list((A, B), [A|L]) :-
    pair_to_list(B, L).

clause_body((_ :- Body), Body).