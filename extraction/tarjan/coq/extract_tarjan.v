From mathcomp
Require Import all_ssreflect.
From tarjan
Require Import tarjan.
Require Extraction.

Definition ntarjan n := @tarjan [finType of 'I_n].

Extraction "extraction/tarjan/ocaml/ntarjan.ml" ntarjan.
