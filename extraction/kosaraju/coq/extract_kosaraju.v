From mathcomp
Require Import all_ssreflect.
From tarjan
Require Import kosaraju.
Require Extraction.

Section Kosaraju.
  Variable (V : finType) (successors : V -> seq V).
  Notation edge := (grel successors).

  Definition gkosaraju := kosaraju edge.
End Kosaraju.

Definition nkosaraju n := @kosaraju [finType of 'I_n].

Extraction "extraction/kosaraju/ocaml/nkosaraju.ml" nkosaraju.
