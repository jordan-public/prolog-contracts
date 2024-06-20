:- dynamic grandparent/2.
:- dynamic parent/2.
:- retractall(grandparent/2).
:- retractall(parent/2).

grandparent(A, C) :- parent(A, B), parent(B, C).

parent(adam, seth).
parent(seth, enosh).
parent(adam, cain).

% Include in Stark Proof
provable(grandparent/2).
provable(parent/2).