From mathcomp
Require Import all_ssreflect.
From tarjan
Require Import tarjan_bigmin.
Require Extraction.

Definition ntarjan n := @tarjan [finType of 'I_n].

Extraction "extraction/tarjan-bigmin/ocaml/ntarjan.ml" ntarjan.
