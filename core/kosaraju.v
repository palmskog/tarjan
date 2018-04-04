From mathcomp Require Import all_ssreflect.
From tarjan
Require Import extra.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Section Kosaraju.

Variable T : finType.
Implicit Types s : {set T}.
Implicit Types l : seq T.
Implicit Types A B C : pred T.
Implicit Types x y z : T.

Lemma connect_rev (V : finType) (g : rel V) (x y : V) :
  connect g x y -> connect [rel x y | g y x] y x.
Proof.
move=> /connectP[p Pxp ->].
elim: p x Pxp => // z p IH x /=/andP[xGy /IH sCz].
by apply: connect_trans sCz (connect1 _).
Qed.

Section Diconnect.

Variable r : rel T.
Local Notation "x -[]-> y" := 
  (connect r x y) (at level 10, format "x  -[]->  y") .

(* x is diconnected to y *)
Definition diconnect x y  :=  connect r x y && connect r y x.

Local Notation "x =[]= y" := (diconnect x y) 
  (at level 10, format "x  =[]=  y").

Lemma diconnect0 : reflexive diconnect.
Proof. by move=> x; apply/andP. Qed.

Lemma diconnect_sym : symmetric diconnect.
Proof. by move=> x y; apply/andP/andP=> [] []. Qed.

Lemma diconnect_trans : transitive diconnect.
Proof.
move=> x y z /andP[Cyx Cxy] /andP[Cxz Czx].
by rewrite /diconnect (connect_trans Cyx) ?(connect_trans Czx).
Qed.

End Diconnect.

Lemma eq_diconnect r1 r2 : r1 =2 r2 -> diconnect r1 =2 diconnect r2.
Proof.
by move=> r1Er2 x y; rewrite /diconnect !(eq_connect r1Er2).
Qed.

Section Relto.

Variable r : rel T.

Local Notation "x -[ s ]-> y" := 
  (connect (rel_of_simpl_rel (relto s r)) x y)
  (at level 10, format "x  -[ s ]->  y").

Local Notation "x -[]-> y" := 
  (connect r x y) (at level 10, format "x  -[]->  y") .

Local Notation "x =[]= y" := (diconnect r x y) 
  (at level 10, format "x  =[]=  y").

Lemma connect_to_from  a x y :
  x -[a]-> y -> connect (relfrom a [rel x y | r y x]) y x.
Proof.
move => /connect_rev.
by apply: connect_sub => x1 y1 H; apply: connect1 .
Qed.

Lemma connect_from_to  a x y :
  connect (relfrom a r) x y -> connect (relto a [rel x y | r y x]) y x.
Proof.
move => /connect_rev.
by apply: connect_sub => x1 y1 H; apply: connect1 .
Qed.

Lemma connect_to1 (a : pred T) x y : a y -> r x y -> x -[a]-> y.
Proof. by move=> ay Rxy; apply: connect1; rewrite /= [_ \in _]ay. Qed.

Lemma connect_toW a: 
  subrel (connect (relto a r)) (connect r).
Proof. by apply: connect_sub => x y /andP[_ H]; apply: connect1. Qed.

Lemma connect_to_sub (a b : pred T) x y : 
 a \subset b -> x -[a]-> y -> x -[b]-> y.
Proof.
move=> /subsetP Hs.
apply/connect_sub => x1 y1 /= /andP[y1Ia x1Ry1].
by apply: connect_to1 (Hs _ _) _.
Qed.

Local Notation "x =[ a ]= y" := (diconnect (rel_of_simpl_rel (relto a r)) x y) 
  (at level 10, format "x  =[ a ]=  y").

Lemma diconnect_to_sub (a b : pred T) x y : 
  a \subset b -> x =[a]= y -> x =[b]= y.
Proof. 
by move=> Hs /andP[Cxy Cyx]; rewrite /diconnect !(connect_to_sub Hs).
Qed.

Lemma eq_diconnect_to (a b : pred T) x y :  a =1 b -> x =[a]= y = x =[b]= y.
Proof.
move=> aEb; apply: eq_diconnect=> x1 y1.
by rewrite /= -!topredE /= aEb.
Qed.

Lemma diconnect_to_predT :  diconnect (relto predT r) =2 diconnect r.
Proof. by move=> x y. Qed.
 
Lemma connect_toT :  (connect (relto predT r)) =2 (connect r).
Proof. by []. Qed.

Lemma connect_to_forced (a : pred T) x y :
 (forall z, z != x -> x -[]-> z ->  z -[]-> y -> a z) ->
  x -[]-> y ->  x -[a]-> y.
Proof.
move=> Hf /connectP[p {p}/shortenP[p Hp Up _ Hy]].
apply/connectP.
elim: p {-2 4}x Hy Up Hp (connect0 (relto a r) x) =>
   [z /=-> _ _ Hz| z p IH /= z1 Hy /and3P[H1 H2 H3] /andP[Rxy Pp] Hz1].
  by exists [::].
move: H1; rewrite inE negb_or => /andP[xDz H1].
have Az : a z.
  apply: Hf; first by rewrite eq_sym.
    apply: connect_trans (connect_toW Hz1) (connect1 Rxy).
    by apply/connectP; exists p.
have Raz : x -[a]-> z.
 by apply: connect_trans Hz1 (connect_to1 Az Rxy).
have Uxp : uniq (x :: p) by rewrite /= H1.
have [p1 H1p1 H2p1] := IH _ Hy Uxp Pp Raz.
by exists (z :: p1); rewrite //= [_ \in _]Az Rxy.
Qed.

Lemma reltoI a b : relto (predI a b) r =2 relto a (relto b r).
Proof. by move=> x y; rewrite /= andbA. Qed.

Lemma connect_to_C1r x y z :
  ~~ z -[]-> y ->  x -[]-> y -> x -[predC1 z]-> y.
Proof.
move=> Hzy Hxy.
apply: connect_to_forced => //= z1 H1 H2 H3.
by apply/eqP=> H4; case/negP: Hzy; rewrite -H4.
Qed.

Lemma connect_to_C1l x y z : 
  ~~ x -[]-> z ->  x -[]-> y -> x -[predC1 z]-> y.
Proof.
move=> Hzy Hxy.
apply: connect_to_forced => //= z1 H1 H2 H3.
by apply/eqP=> H4; case/negP: Hzy; rewrite -H4.
Qed.

Lemma connect_to_C1_id x y : x -[]-> y = x -[predC1 x]-> y.
Proof.
apply/idP/idP; last by apply: connect_toW.
case/connectP => p /shortenP[p' Pxp' Uxp' Sxp' Lyxp'].
apply/connectP; exists p' => //=.
rewrite path_to Pxp'; apply/allP=> z zIp' /=.
have /= /andP[H _] := Uxp'.
by apply: contraNneq H => <-.
Qed.

(* Canonical element in a list : find the first element of l
   that is equivalent to x walking only that satisfies a *)
Definition can_to x a l := nth x l (find (diconnect (relto a r) x) l).

Local Notation "C[ x ]_( a , l ) " := (can_to x a l) 
  (at level 9, format "C[ x ]_( a ,  l )").

Lemma eq_can_to x a b l : a =1 b -> C[x]_(a, l) = C[x]_(b, l).
Proof.
move=> aEb; rewrite /can_to /=.
congr (nth _ _ _).
apply: eq_find => y.
by apply: eq_diconnect_to.
Qed.

Lemma mem_can_to x a l : x \in l -> C[x]_(a, l) \in l.
Proof.
move=> xIp1; rewrite /can_to.
by case: (leqP (size l) (find (diconnect (relto a r) x) l)) => H1;
  [rewrite nth_default | rewrite mem_nth].
Qed.

Lemma can_to_cons x y a l : 
  C[x]_(a, y :: l) =  if x =[a]= y then y else C[x]_(a,l).
Proof.  by rewrite /can_to /=; case: (boolP (diconnect _ _ _)) => Hr. Qed.

Lemma can_to_cat x a l1 l2 : x \in l1 -> C[x]_(a, l1 ++ l2) = C[x]_(a, l1).
Proof.
move=> xIl1.
rewrite /can_to find_cat; case: (boolP (has _ _)).
  by rewrite nth_cat has_find => ->.
by move/hasPn/(_ x xIl1); rewrite diconnect0.
Qed.

Lemma diconnect_can_to x a l : x \in l -> C[x]_(a, l) =[a]= x.
Proof.
move=> xIl; rewrite diconnect_sym; apply: nth_find.
by apply/hasP; exists x => //; exact: diconnect0.
Qed.

(* x occurs before y in l *)
Definition before l x y  := index x l <= index y l.

Local Notation "x =[ l ]< y" := (before l x y) 
  (at level 10, format "x  =[ l ]<  y").

Lemma before_filter_inv a x y l (l1 := [seq i <- l | a i]) :
  x \in l1 -> y \in l1 -> x =[l1]< y -> x =[l]< y.
Proof.
rewrite {}/l1 /before; elim: l => //= z l IH.
case E : (a z) => /=.
  rewrite !inE ![_ == z]eq_sym.
  by case: eqP => //= Hx; case: eqP.
move=> xIl yIl; move: (xIl) (yIl).
rewrite !mem_filter.
case: eqP => [<-|_ _]; first by rewrite E.
case: eqP => [<-|_ _]; first by rewrite E.
by apply: IH.
Qed.

Lemma before_filter x y l a (l1 := [seq i <- l | a i]) :
  x \in l1 -> x =[l]< y -> x =[l1]< y.
Proof.
rewrite {}/l1 /before; elim: l => //= z l IH.
case E : (a z) => /=.
  rewrite inE eq_sym.
  by case: eqP => //= Hx; case: eqP.
move=> xIl Hi; apply: IH => //.
by case: eqP xIl Hi => [<-| _]; [rewrite mem_filter E | case: eqP].
Qed.

Lemma leq_index_nth x l i : index (nth x l i) l  <= i.
Proof.
elim: l i => //= y l IH [|i /=]; first by rewrite eqxx.
by case: eqP => // _; apply: IH.
Qed.

Lemma index_find x l a :  has a l -> index (nth x l (find a l)) l = find a l.
Proof.
move=> Hal.
apply/eqP; rewrite eqn_leq leq_index_nth.
case: leqP => // /(before_find x).
by rewrite nth_index ?nth_find // mem_nth // -has_find.
Qed.

Lemma before_can_to x y a l : 
  x \in l -> y \in l -> x =[a]= y -> C[x]_(a, l) =[l]< y.
Proof.
move=> Hx Hy; rewrite diconnect_sym => Hr.
have F : has (diconnect (relto a r) x) l.
  by apply/hasP; exists y => //; rewrite diconnect_sym.
rewrite /before /can_to index_find //.
case: leqP => // /(before_find x).
by rewrite nth_index // diconnect_sym Hr.
Qed.

Lemma before_can_toW x a b l : 
  x \in l -> b \subset a -> C[x]_(a, l) =[l]< C[x]_(b, l).
Proof.
move=> xIl Hs.
have Hs1 : has (diconnect (relto a r) x) l.
  by apply/hasP; exists x => //; exact: diconnect0.
have Hs2 : has (diconnect (relto b r) x) l.
  by apply/hasP; exists x => //; exact: diconnect0.
rewrite /before /can_to !index_find //.
apply: sub_find => z.
by apply: diconnect_to_sub.
Qed.

End Relto.

Section ConnectRelto.

Variable r : rel T.

Local Notation "x -[ s ]-> y" := 
  (connect (rel_of_simpl_rel (relto s r)) x y)
  (at level 10, format "x  -[ s ]->  y").

Local Notation "x -[]-> y" := 
  (connect r x y) (at level 10, format "x  -[]->  y") .

Local Notation "x =[]= y" := (diconnect r x y) 
  (at level 10, format "x  =[]=  y").

Local Notation "x =[ a ]= y" := (diconnect (rel_of_simpl_rel (relto a r)) x y) 
  (at level 10, format "x  =[ a ]=  y").

Local Notation "C[ x ]_( a , l )" := (can_to r x a l) 
  (at level 9, format "C[ x ]_( a ,  l )").

Local Notation "x =[ l ]< y" := (before l x y) 
  (at level 10, format "x  =[ l ]<  y").

(* The list l is topogically sorted with respect to a if
      all elements of l respects a
   and
      the list is closed under connection with respect to a
   and
      canonical elements are before their connected elements 
*)
Definition tsorted (a : pred T) (l : seq T) := 
 [/\ l \subset a,
     forall x y, x \in l -> x -[a]-> y -> y \in l &
     forall x y, x \in l -> x -[a]-> y -> C[x]_(a, l) =[l]< y
 ].

Local Notation " TS[ a , l ]" := (tsorted a l) 
  (at level 10, format "TS[ a ,  l ]").
Local Notation "TS[ l ] " := (tsorted predT l) 
  (at level 10, format "TS[ l ]").

Lemma tsortedE a l :
 l \subset a ->
 (forall x y, x \in l -> x -[a]-> y -> y \in l /\  C[x]_(a, l) =[l]< y) ->
 TS[a, l].
Proof.
by move=> lSa HR; split => // x y xIl xCy; have [] := HR _ _ xIl xCy.
Qed.

Lemma eq_tsorted a b l : a =1 b -> TS[a, l] -> TS[b , l].
Proof.
move=> aEb [/= lSa Ca Ba].
have aE2b : relto a r =2 relto b r by move=> x y; rewrite /= -topredE /= aEb.
split => /= [|x y xIl xCy|x y xIl xCy].
- apply: subset_trans lSa _.
  by apply/subsetP=> i; rewrite -!topredE /= aEb.
- by apply: Ca xIl _; rewrite (eq_connect aE2b).
rewrite -(eq_can_to _ _ _ aEb).
by apply: Ba xIl _; rewrite (eq_connect aE2b).
Qed.

Lemma tsorted_nil a : TS[a, [::]].
Proof. by split=> //; apply/subsetP => x. Qed.

(* Removing the equivalent element on top preserves the sorting *)
Lemma tsorted_inv x a l : 
  TS[a, x :: l] -> TS[a, [seq y <- x :: l | ~~ x =[a]= y]].
Proof.
move=> [xlSa CR BR]; split => [|y z|y z].
- rewrite /= diconnect0 /=.
  apply/(subset_trans _ xlSa)/subsetP=> z /=.
  by rewrite !inE orbC mem_filter => /andP[_ ->].
- rewrite !mem_filter => /andP[xNDy yIxl] yCz.
  apply/andP; split; last by apply: CR yCz.
  apply: contra xNDy => xDz.
  have : C[y]_(a, x :: l) =[x :: l]< x.
    apply: BR yIxl (connect_trans yCz _).
    by case/andP: xDz.
  rewrite /before index_head /=; case: eqP => // -> _.
  by apply: diconnect_can_to.
rewrite !mem_filter => /andP[xNDy yIxl] yCz.
have ->: C[y]_(a, [seq i <- x :: l | ~~ x =[a]= i]) = C[y]_(a, x :: l).
  elim: (x :: l) => //= t l1 IH.
  case : (boolP (_ =[_]= _)) => Ext /=; last first.
    by rewrite /can_to /=; case : (boolP (_ =[_]= _)).
  rewrite IH  /can_to /=.
  case : (boolP (_ =[_]= _)) => Eyt //=.
  by case/negP: xNDy; apply: diconnect_trans Ext _; rewrite diconnect_sym.
apply: before_filter; last by apply: BR.
rewrite mem_filter mem_can_to // ?andbT.
apply: contra xNDy => xDc.
by apply: diconnect_trans xDc (diconnect_can_to _ _ _).
Qed.

(* Computing the connected elements for the reversed graph gives
   the equivalent class of the top element of a tologically sorted list *)
Lemma tsorted_diconnect x y a l : 
  TS[a, x :: l] -> x =[a]= y = (y \in x :: l) && y -[a]-> x.
Proof.
move=> [_ CR BR].
apply/idP/idP=> [/andP[Cxy Cyx]|/andP[yIxl Cyx]].
  by rewrite (CR x y) // inE eqxx.
have F := diconnect_can_to _ _ yIxl.
have := BR y x yIxl Cyx.
by rewrite /before /= eqxx; case: eqP => //->.
Qed.

(* Computing topological sort by concatenation *)
Lemma tsorted_cat a l1 l2 : 
  TS[a, l1] -> TS[[predD a & [pred x in l1]], l2] -> TS[a, l2 ++ l1].
Proof.
set b := [predD _ & _].
move=> [l1Sa Cl1 Bl1] [l2Sb Cl2] Bl2.
apply: tsortedE => [|x y].
  apply/subsetP => z.
  rewrite mem_cat => /orP[/(subsetP l2Sb)|/(subsetP l1Sa) //].
  by rewrite inE => /andP[].
have [xIl2 _ Hc|xNIl2] := boolP (x \in l2); last first.
  rewrite mem_cat (negPf xNIl2) /= => xIl1 Cxy.
  have yIl1 := Cl1 _ _ xIl1 Cxy.
  have xBy := Bl1 _ _ xIl1 Cxy.
  split; first by rewrite mem_cat yIl1 orbT.
  rewrite /before [index y _]index_cat.
  have [yIl2|yNil2] := boolP (y \in l2).
    have/subsetP/(_ y yIl2)/= := l2Sb.
    by rewrite !inE /= yIl1.
  rewrite index_cat; have [rIl2| rNIl2] := boolP (_ \in l2).
    by apply: leq_trans (index_size _ _) (leq_addr _ _).
  rewrite leq_add2l.
  move: rNIl2; rewrite /can_to find_cat.
  have [HH|HH] := boolP (has _ _).
    by rewrite nth_cat -has_find HH mem_nth // -has_find.
  rewrite nth_cat ltnNge leq_addr /= => _.
  by rewrite addnC addnK.
have [/forallP F|] :=
     boolP [forall z, [&& z != x, x -[a]-> z & z -[a]-> y] ==> 
                   (z \notin l1)].
  have xCy : x -[b]-> y.
    have /eq_connect-> : 
      relto [predD a & [pred x in l1]] r =2
      relto [predC [pred x in l1]]  (relto a r).
      by move=> x1 y1; rewrite /= !inE !andbA.
    apply: connect_to_forced => // z zDx xCz zCy.
    rewrite !inE /=.
    have /implyP->// := F z.
    by rewrite zDx xCz.
  have yIl2 := Cl2 _ _ xIl2 xCy.
  have xBy := Bl2 _ _ xIl2 xCy.
  split; first by rewrite mem_cat yIl2.
  rewrite /before [index y _]index_cat yIl2.
  apply: leq_trans xBy.
  rewrite can_to_cat // index_cat mem_can_to //.
  apply: before_can_toW=> //; apply/subsetP=> i.
  by rewrite !inE => /andP[].
rewrite negb_forall => /existsP[z].
rewrite negb_imply -!andbA negbK => /and4P[zDx xCz zCy zIl1].
have yIl1 := Cl1 _ _ zIl1 zCy.
have zBy := Bl1 _ _ zIl1 zCy.
split; first by rewrite mem_cat yIl1 orbT.
rewrite /before [index y _]index_cat.
have [yIl2|_] := boolP (_ \in _).
  have/subsetP/(_ y yIl2)/= := l2Sb.
  by rewrite !inE yIl1.
rewrite index_cat.
have [_|/negP[]] := boolP (_ \in _).
  by apply: leq_trans (index_size _ _) (leq_addr _ _).
rewrite /can_to; elim: (l2) xIl2 => //= a1 l IH.
rewrite inE => /orP[/eqP->|/IH]; first by rewrite diconnect0 inE eqxx.
case: (_ =[_]= _) => //=; first by rewrite inE eqxx.
by rewrite inE orbC => ->.
Qed.

(* Elements that are notin l do not matter *)
Lemma tsorted_setU1_l x a l (b : pred T := [predD1 a & x]) :
   x \notin l -> TS[a, l] -> TS[b, l].
Proof.
move=> xNIl [lSa Cl Bl]; apply: tsortedE => /= [|t z tIl tCz].
  apply/subsetP=> i; rewrite !inE.
  by case: eqP => //= [-> /(negP xNIl)//|_ /(subsetP lSa)].
have tC'z : t -[a]-> z.
  apply: connect_to_sub tCz.
  by apply/subsetP => i /andP[].
have zIl := Cl _ _ tIl tC'z.
have tBz := Bl _ _ tIl tC'z.
split => //; suff->: C[t]_(b, l) = C[t]_(a, l) by [].
congr nth; apply: eq_in_find => y /= yIl.
have [xIa|xNIa] := boolP (x \in a); last first.
  apply: eq_diconnect_to => x1.
  by rewrite /b /=; case: eqP=> // ->; rewrite [a _](negPf xNIa).
apply/idP/idP => /=. 
  apply/diconnect_to_sub/subsetP=> u.
  by rewrite !inE => /andP[].
case/andP=> tCy Cyt.
have /eq_diconnect-> : relto b r =2 relto (predC1 x) (relto a r).
  by move=> x1 y1; rewrite /b /= !inE !andbA.
by apply/andP; split; apply: connect_to_C1l => //; 
   apply: contra xNIl=> /Cl->.
Qed.

(* Computing topologically sorted list by adding a top element *)
Lemma tsorted_cons_r x a l (b : pred T := [predD1 a & x]) :
 (forall y, y \in l -> x -[a]-> y) ->
 (forall y, r x y -> a y -> y != x -> y \in l) ->
  a x -> TS[b, l] ->  TS[a, x :: l].
Proof.
move=> AxC AyIl Ax [/= lSb Cl Bl]; apply: tsortedE => [|y z] /=.
  apply/subsetP=> y; rewrite inE => /orP[/eqP->//|/(subsetP lSb)].
  by rewrite inE=> /andP[].
have F t : t != x -> x -[b]-> t -> t \in l.
  move=> tDx /connectP[[_ /eqP|v p]] /=; first by rewrite (negPf tDx).
  rewrite -!andbA /= => /and4P[vDx vIa xRv Pbrvp tLvp].
  have/Cl->// : v \in l.
    by apply: AyIl => //; rewrite inE.
  by apply/connectP; exists p.
rewrite inE.
have Hr : relto b r =2 (relto (predC1 x) (relto a r)).
  by move=> x1 y1; rewrite /= !inE !andbA.
have [/eqP-> /= _ xCz|yDx /= yIl yCz] := boolP (y == x).
  split; last by rewrite /before /= can_to_cons diconnect0 eqxx.
  have [/eqP<-|zDx] := boolP (z == x); first by rewrite !inE eqxx.
  rewrite inE (F z) ?orbT // 1?eq_sym // (eq_connect Hr).
  by rewrite -connect_to_C1_id.
have [yCz'|yNCz'] := boolP (y -[b]-> z).
  have zIxs := Cl _ _ yIl yCz'.
  have yBz := Bl _ _ yIl yCz'.
  split; first by rewrite inE zIxs orbT.
  have [/eqP xEz|xDz] := boolP (x == z).
    rewrite can_to_cons.
    suff->: y =[a]= x by rewrite /before /= eqxx.
    rewrite /diconnect {1}xEz yCz /=.
    by apply: AxC.
  rewrite can_to_cons; case: (_ =[_]= _); first by rewrite /before /= eqxx.
  rewrite /before /= (negPf xDz); case: eqP => //= _.
  rewrite ltnS.
  apply: leq_trans yBz => /=.
  apply: before_can_toW => //; apply/subsetP=> i.
  by rewrite inE => /andP[].
have [yCx|yNCx] := boolP (y -[a]-> x); last first.
  case/negP: yNCz'.
  by rewrite (eq_connect Hr); apply: connect_to_C1l.
have [xCz| xNCz] := boolP (x -[a]-> z); last first.
  case/negP: yNCz'.
  by rewrite (eq_connect Hr); apply: connect_to_C1r.
split.
  rewrite inE.
  have [//|zDx/=] := boolP (z == x).
  apply: F => //.
  by rewrite (eq_connect Hr) -connect_to_C1_id.
rewrite /before can_to_cons.
suff->: y =[a]= x; first by rewrite /before /= eqxx.
rewrite /diconnect yCx /=.
by apply: AxC.
Qed.

Lemma connect_to_rev l a b x y : 
     {subset b <= a} -> 
     (forall z, (z \in b) = (z \in x :: l)) ->
     TS[a, x :: l] ->
     ((y \in x :: l) && y -[a]-> x) = (connect (relto b [rel x y | r y x]) x y).
Proof.
move=> /subsetP HS HD HW.
have xIxl : x \in x :: l by rewrite inE eqxx.
case: (x =P y) => [<-|/eqP xDy]; first by rewrite xIxl !connect0.
have [yIxl/=|yNIxl/=] := boolP (y \in _); last first.
  apply/sym_equal/idP/negP; apply: contra yNIxl => /connectP[[/= _ ->//|z p]].
  rewrite path_to /= => /and3P[_ zB /allP ApB ->].
  have := mem_last z p.
  by rewrite -HD inE => /orP[/eqP->//|/ApB].
have [yCx|yNCx] := boolP (y -[_]-> x); last first.
apply/sym_equal/idP/negP; apply: contra yNCx => xCy.
  have /connectP[p Hp Hy] := connect_to_from xCy.
  apply/connectP; exists p => //.
  move: Hp; rewrite /= path_from path_to => /andP[->].
  case: p Hy => // z p1.
  rewrite {3}lastI /= all_rcons => <- /= /andP[_ /allP Ap].
  rewrite [a x](subsetP HS) ?HD //.
  by apply/allP=> i /Ap iB; rewrite [a _](subsetP HS).
apply/sym_equal/idP.
have /connect_to_from/connectP[p Hp Hy] : y -[b]-> x.
  rewrite (eq_connect (_ : _ =2 (relto b (relto a r)))); last first.
    move=> x1 y1 /=.
    by case: (boolP (_ \in b)) => // /(subsetP HS)->.
  apply: connect_to_forced => // z zDy yCz zCx.
  rewrite [b _]HD.
  by have [_ /(_ y z yIxl yCz)] := HW.
apply/connectP; exists p => //.
move: Hp; rewrite /= path_from path_to => /andP[->].
case: p Hy => // z p1.
rewrite {3}lastI /= /= all_rcons => <- /= /andP[_ Ap].
by rewrite  [b _]HD yIxl.
Qed.

End ConnectRelto.

Section Stack.

Variable r : rel T.

Local Notation "x -[ l ]-> y" := 
  (connect  (rel_of_simpl_rel (relto l r)) x y) 
  (at level 10, format "x  -[ l ]->  y").
Local Notation "x -[]-> y" := (connect r x y) 
  (at level 10, format "x  -[]->  y").
Local Notation "x =[ l ]= y" := (diconnect (relto l r) x y) 
  (at level 10, format "x  =[ l ]=  y").
Local Notation "x =[]= y" := (diconnect r x y) 
  (at level 10, format "x  =[]=  y").
Local Notation "TS[ a , l ]" := (tsorted r a l) 
  (at level 10, format "TS[ a ,  l ]").
Local Notation "TS[ l ]" := (tsorted r (pred_of_simpl predT) l) 
  (at level 10, format "TS[ l ]").

Section Pdfs.

Variable g : T -> seq T.

Fixpoint rpdfs m (p : {set T} * seq T) x :=
  if x \notin p.1  then p else 
  if m is m1.+1 then 
     let p1 := foldl (rpdfs m1) (p.1 :\ x, p.2) (g x) in (p1.1, x :: p1.2)
  else p.

Definition pdfs := rpdfs #|T|.

End Pdfs.

Lemma pdfs_correct (p : {set T} * seq T) x :
  let (s, l) := p in 
  uniq l /\  {subset l <= ~: s} ->
  let p1 := pdfs (rgraph r) p x in
  let (s1, l1) := p1 in
  if x \notin s then p1 = p else
       [/\ #|s1| <= #|s| & uniq l1]
    /\
       exists l2 : seq T,
       [/\ x \in l2, s1 = s :\: [set y in l2], l1 = l2 ++ l, 
           TS[[pred x in s], l2] &
           forall y, y \in l2 -> x -[[pred x in s]]-> y].
Proof.
rewrite /pdfs.
have: #|p.1| <= #|T| by apply/subset_leq_card/subsetP=> i.
elim: #|T| x p => /= [x [s l]|n IH x [s l]]/=.
  rewrite leqn0 => /eqP/cards0_eq-> [HUl HS].
  by rewrite inE.
have [xIs Hl [HUl HS]/=|xNIs Hl [HUl HS]//] := boolP (x \in s).
set p := (_, l); set F := rpdfs _ _; set L := rgraph _ _.
have: 
     [/\ #|p.1| < #|s| & uniq p.2]
  /\
     exists l2,
      [/\  
           x \notin p.1, 
           p.1 = (s :\ x) :\: [set z in l2], 
           p.2 = l2 ++ l, TS[[predD1 s & x], l2] &
           forall y, y \in l2 -> x -[[predD1 s & x]]-> y
      ].
  split; [split => // | exists [::]; split => //=].
  - by rewrite /p /= [#|s|](cardsD1 x) xIs.
  - by rewrite !inE eqxx.
  - by rewrite setD0.
  by exact: tsorted_nil.
have: forall y, r x y -> (y \notin p.1) || (y \in L).
  by move=> y; rewrite [_ \in rgraph _ _]rgraphK orbC => ->.
have: forall y, (y \in L) -> r x y.
  by move=> y; rewrite [_ \in rgraph _ _]rgraphK.
rewrite {}/p.
elim: L (_, _) => /=
    [[s1 l1] /= _ yIp [[sSs1 Ul1] [l2 [xIs1 s1E l1E Rwl2 xCy]]]|
    y l' IH1 [s1 l1] /= Rx yIp [[sSs1 Ul1] [l2 [xIs1 s1E l1E Rwl2 xCy]]]].
  split; [split=> // |exists (x :: l2); split] => // [||||||y].
  - rewrite subset_leqif_cards // s1E.
    by apply: subset_trans (subsetDl _ _) (subD1set _ _).
  - rewrite Ul1 andbT l1E mem_cat negb_or.
    have [/= Dl2 _] := Rwl2.
    have /subsetP/(_ x)/implyP/=  := Dl2.
    rewrite !inE /= eqxx implybF => ->.
    have  /implyP := HS x.
    by rewrite !inE xIs implybF.
  - by rewrite inE eqxx.
  - by apply/setP => z; rewrite s1E !inE negb_or andbC andbAC.
  - by rewrite l1E.
  - apply: tsorted_cons_r => // [y yInl2|y /yIp].
    rewrite connect_to_C1_id
           (eq_connect (_ : _ =2 (relto [predD1 s & x] r))) ?xCy //.
      by move=> x1 y1; rewrite /= !inE andbA.
    rewrite orbF s1E 3!inE negb_and => /orP[]; first by rewrite negbK.
    by rewrite !inE negb_and => /orP[] /negPf->.
  rewrite inE => /orP[/eqP->|yIl2].
    by apply: connect0.
  apply: connect_to_sub (xCy _ yIl2); apply/subsetP => i /=.
  by rewrite !inE => /andP[].
have F1 : #|s1| <= n.
  by rewrite -ltnS (leq_trans _ Hl).
have F2 : {subset l1 <= ~: s1}.
  move=> i; rewrite l1E s1E !inE mem_cat => /orP[->//|/HS].
  by rewrite inE => /negPf->; rewrite !andbF.
have := IH y (s1, l1) F1 (conj Ul1 F2).
rewrite /F /=; case: rpdfs => s3 l3 /= Hv.
apply: IH1 => [z zIl|z Rxz /=|]; first by apply: Rx; rewrite inE zIl orbT.
  case: (boolP (y \in s1)) Hv =>
       [yIs1/= [[Ss1s3 Ul3] [l4 [yIl4 s3E l3E Rwl4 Cyz]]]
       |yNIs1/= [-> _]]; last first. 
    case/orP: (yIp _ Rxz) => [->//|].
    by rewrite inE => /orP[/eqP->|->]; [rewrite yNIs1|rewrite orbT].
  rewrite s3E !inE !negb_and.
  case/orP: (yIp _ Rxz) => [->//|]; first by rewrite orbT.
  rewrite inE => /orP[/eqP->|->]; last by rewrite orbT.
  by rewrite yIl4.
case: (boolP (y \in s1)) Hv =>
      [yIs1 [[Ss1s3 Ul3] [l4 [yIl4 s3E l3E Rwl4 Cyz]]]
      |yNIs1 [-> ->]]; last first.
  by split=> //; exists l2; split.
split; [split=> //= | exists (l4 ++ l2); split => //= [||||z]]. 
- by apply: leq_ltn_trans Ss1s3 _.
- by rewrite s3E s1E !inE eqxx !andbF.
- by apply/setP => i; rewrite s3E s1E !inE mem_cat negb_or -!andbA.
- by rewrite l3E l1E catA.
- apply: tsorted_cat => //.
  apply: eq_tsorted Rwl4 => i.
  by rewrite /= s1E !inE.
rewrite mem_cat => /orP[] zIl4; last by apply: xCy.
apply: connect_trans (_: y -[_]-> z); last first.
  apply: connect_to_sub (Cyz _ zIl4); apply/subsetP => i.
  by rewrite /= s1E !inE => /andP[].
apply: connect_to1 (Rx _ _); rewrite !inE ?eqxx //.
by move: yIs1; rewrite s1E !inE=> /and3P[_ ->].
Qed.

Lemma pdfs_connect s x : 
  x \in s ->
  let (s1, l1) := pdfs (rgraph r) (s, [::]) x in
  [/\ uniq l1, s1 = s :\: [set x in l1], l1 \subset s & 
      forall y, y \in l1 = x -[[pred u in s]]-> y].
Proof.
move=> xIs.
set p := (_, _).
have UN : [/\ uniq p.2 & {subset p.2 <= ~: p.1}] by [].
case: pdfs (pdfs_correct (_, _) x UN) => s1 l1.
rewrite xIs => /=[[[_ Ul1] [l2 [xIl2 s1E l1E WH Cy]]]].
split => // [||y].
- by apply/setP=> i; rewrite s1E l1E !inE cats0.
- apply/subsetP=> z.
  rewrite l1E cats0.
  by have [/subsetP/(_ z)/=] := WH.
apply/idP/idP => [|H].
  by rewrite l1E cats0; exact: Cy.
rewrite l1E cats0.
by have [_ /(_ x y xIl2 H)] := WH.
Qed.

(* Building the topologically-ordered sequence of all nodes *)
Definition tseq :=
  (foldl (pdfs (rgraph r)) (setT, [::]) (enum T)).2.

(* The sequence is topologically sorted and contains all the nodes *)
Lemma tseq_correct : TS[tseq] /\ forall x, x \in tseq.
Proof.
suff: [/\
        {subset (setT : {set T}, [::]).2  <= tseq},
        TS[tseq] &
         forall x : T, x \in (enum T) ->  x \in tseq].
  case=> H1 H2 H3; split => // x.
  by rewrite H3 // mem_enum.
rewrite /tseq; set F := foldl _; set p := (_, _).
have : TS[p.2] by apply: tsorted_nil.
have: p.1 = ~: [set x in p.2].
  by apply/setP=> i; rewrite /= !inE.
have: uniq p.2 by [].
elim: (enum T) p => /= [|y l IH [s1 l1] HUl1 /= Hi Rw].
  by split.
have HS : {subset l1 <= ~: s1}.
  by move=> i; rewrite Hi !inE negbK.
have :=  pdfs_correct (_, _) y (conj HUl1 HS).
have [yIs1|yNIs1] := boolP (y \in s1); last first.
  case: pdfs => s2 l2 [-> ->].
  have /= [Sl2 HR xI] := IH (s1,l1) HUl1 Hi Rw.
  split => // x.
  rewrite inE => /orP[/eqP->|xIl]; last by apply: xI.
  apply: Sl2.
  by move: yNIs1; rewrite Hi !inE negbK.
case: pdfs => s2 l2 /= [[Ss1s2 Ul2] [l3 [yIl3 s2E l2E RWl3 Cyz]]].
case: (IH (s2, l2)) => //= [|| Sl2F RwF FI]. 
- by apply/setP=> i; rewrite s2E Hi l2E !inE mem_cat negb_or.
- rewrite l2E; apply: (tsorted_cat Rw).
  apply: eq_tsorted RWl3 => i.
  by rewrite /= Hi !inE andbT.
split=> // [i iIl1|x]; first by rewrite Sl2F // l2E mem_cat iIl1 orbT.
rewrite inE => /orP[/eqP->|//]; last exact: FI.
by apply: Sl2F; rewrite l2E mem_cat yIl3.
Qed.


End Stack.

Variable r : rel T.

Definition kosaraju :=
  let f := pdfs (rgraph [rel x y | r y x]) in 
  (foldl  (fun (p : {set T} * seq (seq T)) x => if x \notin p.1 then p else 
                      let p1 := f (p.1, [::]) x in  (p1.1, p1.2 :: p.2))
          (setT, [::]) (tseq r)).2.

Lemma kosaraju_correct :
    let l := flatten kosaraju in 
 [/\ uniq l, forall i, i \in l &
     forall c : seq T, c \in kosaraju -> 
        exists x, forall y, (y \in c) = (connect r x y && connect r y x)]. 
Proof.
rewrite /kosaraju.
set f := pdfs (rgraph [rel x y | r y x]).
set g := fun p x => if _ then _ else _.
set p := (_, _).
have: uniq (flatten p.2) by [].
have: forall c, c \in (flatten p.2) ++ (tseq r).
  by move=>c; case: (tseq_correct r) => _ /(_ c).
have: forall c, c \in p.2 -> 
                exists x, c =i (diconnect (relto predT r) x) by [].
have: ~: p.1 =i flatten p.2.
 by move=> i; rewrite !inE in_nil.
have: tsorted r (predT : pred T) [seq i <- tseq r | i \in p.1].
  have->: [seq i <- tseq r | i \in p.1] = tseq r.
    by apply/all_filterP/allP=> y; rewrite inE.
  by case: (tseq_correct r).
elim: tseq p => [[s l]/= HR HI HE HFI HUF|].
  split=> // i.
  by have := HFI i; rewrite cats0.
move=> x l IH [s1 l1] HR HI HE HFI HUF.
rewrite /g /f /=.
have [xIs1|xNIs1] := boolP (x \in s1); last first.
  apply: IH => //= [|i]; first by move: HR; rewrite /= (negPf xNIs1).
  have:= HFI i; rewrite !mem_cat inE /=.
  by case: eqP => //->; rewrite -HI !inE xNIs1.
have := (@pdfs_connect ([rel x y | r y x]) s1 x xIs1).
case: pdfs => s2 l2 /= [Ul2 s2E Dl2 xCy].
move: HR; rewrite /= xIs1; set L := [seq _ <- _ | _] => HR.
have l2R : l2 =i (diconnect r x).
  move=> y.
  rewrite xCy -(@connect_to_rev r L setT) //.
  - rewrite -tsorted_diconnect //.
      rewrite -topredE /=.
      by apply: eq_diconnect => i j; rewrite /= !inE.
    by apply: eq_tsorted HR => i; rewrite  !inE //= topredE inE.
  - move=> i; rewrite /= !inE mem_filter.
    have := HFI i; rewrite /= mem_cat -HI /= !inE.
    case: (_ =P _) => [->|] /=; first by rewrite xIs1.
    by case: (_ \in _).
 by apply: eq_tsorted HR => i; rewrite // inE topredE inE.
apply: IH => [|i|i|i|] //=.
- suff->: [seq i <- l | i \in s2] =
          [seq i <- x :: L | ~~ diconnect r x i].
    by apply: tsorted_inv.
  rewrite /= diconnect0 /=.
  rewrite -filter_predI.
  apply: eq_filter => y /=.
  by rewrite s2E !inE l2R.
- by rewrite s2E !mem_cat !inE -HI negb_and negbK inE.
- by rewrite inE => /orP[/eqP->|//]; [exists x | apply: HE].
- have:= HFI i.
  rewrite /= !mem_cat !inE => /or3P[->|/eqP->|->].
  - by rewrite orbT.
  - by rewrite xCy connect0.
  by rewrite !orbT.
rewrite cat_uniq Ul2 HUF /= andbT.
apply/hasPn => i /=.
have/subsetP/(_ i)/= := Dl2.
by rewrite -HI /= !inE; do 2 case: (_ \in _).
Qed.

End Kosaraju.

Print rpdfs.
Print pdfs.
Print tseq.
Print kosaraju.
Print dfs.

