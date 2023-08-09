From Coq Require Import Lia.
Definition dec (X: Type) : Type := X + (X -> False).
Definition decider {X} (p: X -> Prop) := forall x, dec (p x).
Definition iffT (X Y: Type) : Type := (X -> Y) * (Y -> X).
Notation "X <=> Y" := (iffT X Y) (at level 95, no associativity).
Notation sig := sigT.
Notation Sig := existT.
Notation pi1 := projT1.
Notation pi2 := projT2.
Notation "'Sigma' x .. y , p" :=
  (sig (fun x => .. (sigT (fun y => p%type)) ..))
    (at level 200, x binder, right associativity,
     format "'[' 'Sigma'  '/  ' x  ..  y ,  '/  ' p ']'")
    : type_scope.

Definition injective {X Y} (f: X -> Y) :=
  forall x x', f x = f x' -> x = x'.
Definition surjective {X Y} (f: X -> Y) :=
  forall y, exists x, f x = y.
Definition bijective {X Y} (f: X -> Y) :=
  injective f /\ surjective f.

(*** Injections *)

Definition inv {X Y: Type} (g: Y -> X) (f: X -> Y) := forall x, g (f x) = x.
Inductive injection (X Y: Type) : Type :=
| Injection {f: X -> Y} {g: Y -> X} (_: inv g f).
Inductive bijection (X Y: Type) : Type :=
| Bijection {f: X -> Y} {g: Y -> X} (_: inv g f) (_: inv f g).

From Coq Require Import Arith.Cantor.

Definition injection_nat_x_nat : injection (nat * nat) nat.
Proof.
  exists to_nat of_nat. exact cancel_of_to.
Qed.

Fact injection_nat_option X :
  injection X nat -> injection (option X) nat.
Proof.
  intros [f g H].
  exists (fun a => match a with Some x => S (f x) | None => 0 end)
    (fun n => match n with 0 => None | S n => Some ( g n) end).
  intros [x|]; congruence.
Qed.

Fact injection_option X Y :
  injection (option X) Y -> X -> injection X Y.
Proof.
  intros [f g H] x0.
  exists (fun x => f (Some x))
    (fun y => match g y with Some x => x | None => x0 end).
  intros x. rewrite H. reflexivity.
Qed.

(*** Equality deciders *)

Definition eqdec X := forall x y: X, dec (x = y).

Definition eqdec_bot : eqdec False.
Proof.
  intros [].
Qed.

Definition eqdec_nat : eqdec nat.
Proof.
  hnf; induction x as [|x IH]; destruct y as [|y]; unfold dec in *.
  1-3: intuition congruence.
  destruct (IH y); intuition congruence.
Qed.

Fact eqdec_injective {X Y f} :
  @injective X Y f -> eqdec Y -> eqdec X.
Proof.
  intros H d x x'. specialize (H x x').
  destruct (d (f x) (f x')) as [H1|H1];
    unfold dec in *; intuition  congruence.
Qed.

Definition eqdec_injection X Y :
  injection X Y -> eqdec Y -> eqdec X.
Proof.
  intros [f g H] d x1 x2.
  destruct (d (f x1) (f x2)) as [H1|H1];
    unfold dec; intuition congruence.
Qed.

Definition eqdec_option X :
  eqdec X <=> eqdec (option X).
Proof.
  split; intros d.
  - intros [x1|] [x2|].
    2-4:  unfold dec; intuition congruence.
    specialize (d x1 x2).
    unfold dec in *; intuition congruence.
  - intros x1 x2.
    specialize (d (Some x1) (Some x2)).
    unfold dec in *; intuition congruence.
Qed.

Definition eqdec_sum X Y :
  eqdec X * eqdec Y <=> eqdec (X + Y).
Proof.
  split.
  - intros [dX dY] [x1|y1] [x2|y2].
    + destruct (dX x1 x2); unfold dec in *; intuition congruence.
    + unfold dec in *; intuition congruence.
    + unfold dec in *; intuition congruence.
    + destruct (dY y1 y2); unfold dec in *; intuition congruence.
  - intros d; split.
    + intros x1 x2.
      destruct (d (inl x1) (inl x2)); unfold dec in *; intuition congruence.
    + intros y1 y2.
      destruct (d (inr y1) (inr y2)); unfold dec in *; intuition congruence.
Qed.

Definition eqdec_prod X Y :
  eqdec X -> eqdec Y -> eqdec (X * Y).
Proof.
  intros dX dY [x1 y1] [x2 y2].
  destruct (dX x1 x2), (dY y1 y2);
    unfold dec in *; intuition congruence.
Qed.

(*** Enumerators *)

Definition enum' X (f: nat -> option X) := forall x, exists n, f n = Some x.

Definition enum X := sig (enum' X).

Definition enum_bot : enum False.
Proof.
  exists (fun _ => None). intros [].
Qed.

Definition enum_nat : enum nat.
Proof.
  exists Some. hnf; eauto.
Qed.

Definition enum_injection X Y :
  injection X Y -> enum Y -> enum X.
Proof.
  intros [f g H] [e H1].
  exists (fun n => match e n with Some x => Some (g x) | None => None end).
  intros x. specialize (H1 (f x)) as [n H1].
  exists n. rewrite H1. congruence.
Qed.

Definition enum_option X :
  enum X <=> enum (option X).
Proof.
  split; intros [e H].
  - exists (fun n => Some match n with 0 => None| S n => e n end).
    intros [x|].
    + specialize (H x) as [n H]. exists (S n). congruence.
    + exists 0. reflexivity.
  - exists (fun n => match e n with Some (Some x) => Some x | _ => None end).
    intros x.
    specialize (H (Some x)) as [n H].
    exists n. rewrite H. reflexivity.
Qed.

Definition enum_sum X Y :
  enum X * enum Y <=> enum (X + Y).
Proof.
  split.
  - intros [[eX HX] [eY HY]].
    destruct injection_nat_x_nat as [f g H].
    exists (fun n => match g n with
             | (0,n) => match eX n with
                       | Some x => Some (inl x)
                       | None => None
                       end
             | (1,n) => match eY n with
                       | Some y => Some (inr y)
                       | None => None
                       end
             | _ => None
             end).
    intros [x|y].
    + specialize (HX x) as [n HX].
      exists (f (0,n)). rewrite H, HX. reflexivity.
    + specialize (HY y) as [n HY].
      exists (f (1,n)). rewrite H, HY. reflexivity.
  - intros [e He]. split.
    + exists (fun n => match e n with Some (inl x) => Some x | _ => None end).
      intros x. specialize (He (inl x)) as [n He].
      exists n. rewrite He. reflexivity.
    + exists (fun n => match e n with Some (inr y) => Some y | _ => None end).
      intros y. specialize (He (inr y)) as [n He].
      exists n. rewrite He. reflexivity.
Qed.

Definition enum_prod X Y :
  enum X -> enum Y -> enum (X * Y).
Proof.
  intros [eX HX] [eY HY].
  destruct injection_nat_x_nat as [f g H].
  exists (fun n => let (nx,ny) := g n in
           match eX nx, eY ny with
           | Some x, Some y => Some (x,y)
           | _, _ => None
           end).
  intros (x,y).
  destruct (HX x) as [nx Hx].
  destruct (HY y) as [ny Hy].
  exists (f (nx,ny)).
  rewrite H, Hx, Hy.
  reflexivity.
Qed.

(*** Co_Enumerators *)

Definition co_enum {X} (g: X -> nat) f :=
  forall x, f (g x) = Some x.

Fact co_enum_enum X f g :
  co_enum g f -> enum' X f.
Proof.
  intros H x. exists (g x). congruence.
Qed.

Fact co_enum_injective X f g :
  @co_enum X g f -> injective g.
Proof.
  intros H x y H1 %(f_equal f). congruence.
Qed.

Fact co_enum_eqdec X f g :
  @co_enum X g f -> eqdec X.
Proof.
  intros H %co_enum_injective.
  generalize H eqdec_nat. apply eqdec_injective.
Qed.

(*** EWOs *)

Definition ewo X := forall (p: X -> Prop), decider p -> ex p -> sig p.

Definition ewo_bot : ewo False.
Proof.
  intros p _ [[] _].
Qed.

From Coq Require Import ConstructiveEpsilon.

Definition ewo_nat : ewo nat.
Proof.
  intros p H1 H2.
  apply constructive_indefinite_ground_description_nat in H2.
  - destruct H2; eauto. 
  - intros n. destruct (H1 n); auto.
Qed.

Definition ewo_injection X Y :
  injection X Y -> ewo Y -> ewo X.
Proof.
  intros [f g H] e p d H1.
  destruct (e (fun y => p (g y))) as [y H2].
  - intros y. apply d.
  - destruct H1 as [x H1]. exists (f x). congruence.
  - eauto.
Qed.

Definition ewo_option X :
  ewo X <=> ewo (option X).
Proof.
  split; intros e p d H.
  - destruct (d None) as [H1|H1]. {eauto.}
    destruct (e (fun x => p (Some x))) as [x H2].
    + intros x. apply d.
    + destruct H as [[x|] H].
      * eauto.
      * exfalso. auto.
    + eauto.
  - destruct (e (fun a => match a with Some x => p x | None => False end)) as [[x|] H1].
    + intros [x|]. {apply d.} right. easy.
    + destruct H as [x H]. exists (Some x). easy.
    + eauto.
    + contradict H1.
Qed.

(*** Inverse functions via EWOs *)

Fact co_inv_ex {X Y f} :
  @surjective X Y f -> ewo X -> eqdec Y -> Sigma g, inv f g.
Proof.
  intros H e d.
  enough (G: forall y, Sigma x, f x = y).
  { exists (fun y => pi1 (G y)). intros y. apply (pi2 (G y)). }
  intros y. apply e.
  - intros x. apply d.
  - apply H. 
Qed.

Fact bijection_ex X Y f :
  @bijective X Y f -> ewo X -> eqdec Y -> Sigma g, inv g f /\ inv f g.
Proof.
  intros [H1 H2] e d.
  destruct (co_inv_ex H2 e d) as [g H3].
  exists g. split. 2:exact H3.
  intros x. apply H1. congruence.
Qed.

Fact co_enum_ex {X f} :
  eqdec X -> enum' X f -> Sigma g, co_enum g f.
Proof.
  intros d H.
  assert (F: forall x, Sigma n, f n = Some x).
  { intros x. apply ewo_nat.
    - intros n. apply eqdec_option in d. apply d.
    - apply H. }
  exists (fun x => pi1 (F x)). intros x. apply (pi2 (F x)).
Qed.

(*** Countable Types *)

Definition cty X := (eqdec X * enum X) %type.

Definition cty_bot : cty False.
Proof.
  split. apply eqdec_bot. apply enum_bot.
Qed.

Definition cty_nat : cty nat.
Proof.
  split. apply eqdec_nat. apply enum_nat.
Qed.

Definition cty_injection X Y :
  injection X Y -> cty Y -> cty X.
Proof.
  intros H [d e]. split.
  - apply eqdec_injection in H; assumption.
  - apply enum_injection in H; assumption.
Qed.

Definition cty_sum X Y :
  cty X -> cty Y -> cty (X + Y).
Proof.
  intros [dX eX] [dY eY]. split.
  - apply eqdec_sum. split; assumption.
  - apply enum_sum. split; assumption.
Qed.

Definition cty_prod X Y :
  cty X -> cty Y -> cty (X * Y).
Proof.
  intros [dX eX] [dY eY]. split.
  - apply eqdec_prod; assumption.
  - apply enum_prod; assumption.
Qed.

Definition cty_nat_x_nat : cty (nat * nat).
Proof.
  apply cty_prod; apply cty_nat.
Qed.

Definition cty_option X :
  cty X <=> cty (option X).
Proof.
  split; intros [d e]; split.
  - revert d. apply eqdec_option.
  - revert e. apply enum_option.
  - revert d. apply eqdec_option.
  - revert e. apply enum_option.
Qed.

Fact cty_char_co_enum X :
  cty X <=> Sigma g f, @co_enum X g f.
Proof.
  split.
  - intros (d&f&H).
    destruct (co_enum_ex d H) as [g Hg]. exists g, f. exact Hg.
  - intros (g&f&H). split.
    + eapply co_enum_eqdec, H.
    + exists f. eapply co_enum_enum, H.
Qed.

Fact cty_char_retract X :
  cty X <=> injection (option X) nat.
Proof.
  split.
  - intros (g&f&H) %cty_char_co_enum.
    exists (fun a => match a with Some x => S (g x) | None => 0 end)
      (fun n => match n with 0 => None | S n => f n end).
    intros [x|]; easy.
  - intros H. apply cty_injection in H.
    + revert H. apply cty_option.
    + apply cty_nat.
Qed.

Fact cty_ewo {X} :
  cty X -> ewo X.
Proof.
  intros H %cty_char_retract %ewo_injection.
  - revert H. apply ewo_option.
  - apply ewo_nat.
Qed.

Fact cty_injection_nat X :
  injection X nat -> cty X.
Proof.
  intros H. apply cty_char_retract, injection_nat_option, H.
Qed.

Fact cty_flat_injection X :
  cty X -> X -> injection X nat.
Proof.
  intros H %cty_char_retract. apply injection_option, H.
Qed.

(*** Least *)

Definition safe (p: nat -> Prop) n := forall k, p k -> k >= n.
Definition least (p: nat -> Prop) n := p n /\ safe p n.
Notation unique p := (forall x x', p x -> p x' -> x = x').

Fact least_unique (p: nat -> Prop) :
  unique (least p).
Proof.
  intros x y [H1 H2] [H3 H4].
  enough (x <= y /\ y <= x) by lia. split.
  - apply H2, H3.
  - apply H4, H1.
Qed.

Fact safe_S p n :
  safe p n -> ~p n -> safe p (S n).
Proof.
  intros H1 H2 k H3. specialize (H1 k H3).
  enough (k <> n) by lia. congruence.
Qed.


Definition least_sigma (p: nat -> Prop) :
  decider p -> sig p -> sig (least p).
Proof.
  intros d.
  enough (forall n, sig (least p) + safe p n) as F.
  { intros [n Hn]. destruct (F n) as [H|H]. easy. exists n. easy. }
  induction n as [|n [IH|IH]].
  - right. hnf; lia.
  - eauto.
  - destruct (d n) as [H|H].
    + left. exists n. easy.
    + right. apply safe_S; easy.
Qed.

Fact least_exists (p: nat -> Prop) :
  decider p -> ex p -> ex (least p).
Proof.
  intros d [n Hn].
  destruct (least_sigma p d) as [x H]; eauto.
Qed.

Definition least_dec p :
  decider p -> decider (least p).
Proof.
  intros d n.
  destruct (d n) as [H|H].
  2:{ right. intros [H2 _]. easy. }
  destruct (least_sigma p d) as [x Hx]. {eauto.}
  destruct (eqdec_nat x n) as [->|H1]. {left. exact Hx.}
  right. intros H2. contradict H1.
  eapply least_unique; eassumption.
Qed.

Definition least_ewo (p: nat -> Prop) :
  decider p -> ex p -> sig (least p).
Proof.
  intros d H. apply least_sigma. exact d.
  apply ewo_nat; assumption.
Qed.

(*** Nonrepeating Enumerators *)

Definition fnrep {X} (f: nat -> option X) : Prop :=
  forall m n, f m = f n -> f m <> None -> m = n.

Definition cty_enum_fnrep {X} :
  cty X -> Sigma f, enum' X f /\ fnrep f.
Proof.
  intros (d&f&Hf).
  assert (D: forall x, decider (fun n => f n = Some x)).
  { intros x n. apply (eqdec_option X). exact d. }
  exists (fun n => match f n with
           | None => None
           | Some x => if least_dec (fun n => f n = Some x) (D x) n
                      then Some x
                      else None
           end).
  split.
  - intros x.
    destruct (least_exists _ (D x) (Hf x)) as (k&Hk).
    assert (Hx: f k = Some x). {apply Hk.}
    exists k. destruct (f k) as [y|]. 2:easy.
    assert (x=y) as <- by congruence.
    destruct least_dec as [H|H]; easy.
  - intros m n.
    destruct (f m) as [xm|] eqn:Em. 2:easy.
    destruct (f n) as [xn|] eqn:En. 2:easy.
    destruct (least_dec _ _ m) as [H1|H1]. 2:easy.
    destruct (least_dec _ _ n) as [H2|H2]. 2:easy.
    intros [= ->] _. eapply least_unique; eassumption.
Qed.

(*** Alignments *)

Definition hit {X} (f: X -> nat) n := exists x, f x = n.
Definition serial {X} (f: X -> nat) := forall n, hit f (S n) -> hit f n.
Definition alignment {X} (f: X -> nat) := serial f /\ injective f.

Definition cty_alignment {X} :
  cty X -> sig (@alignment X).
Proof.
  intros H.
  destruct (cty_enum_fnrep H) as (f&H1&H2).
  destruct H as [d _].
  destruct (co_enum_ex d H1) as [g Hg].
  (* hn = # hits f has below n *)
  pose (h := fix h n := match n with
                        | 0 => 0
                        | S n => if f n then S (h n) else h n
                        end).
  assert (h_serial: forall k n, h n = S k -> Sigma m y, m < n /\ f m = Some y /\ h m = k).
  { intros k; induction n as [|n IH]; cbn. lia.
    destruct (f n) as [y|] eqn:E.
    - intros [= <-]. exists n, y. intuition lia.
    - intros (m&y&H)%IH. exists m, y. intuition lia. }
  assert (h_increasing: forall m x n, f m = Some x -> m < n -> h m < h n).
  { intros m x. induction n as [|n IH].
    - lia.
    - intros H3 H4. cbn.
      assert (m = n \/ m < n) as [->|H5] by lia.
      + rewrite H3. lia.
      + destruct (f n) as [y|].
        * specialize (IH H3 H5). lia.
        * auto. }
  exists (fun x => h (g x)). split.
  - intros n [x (m&y&H3&H4&<-)%h_serial].
    exists y. enough (g y = m) by congruence.
    apply H2; congruence.
  - intros x y H.
    eapply co_enum_injective. exact Hg.
    enough (g x < g y \/ g y < g x -> False) by lia.
    intros [H3|H3]; eapply h_increasing in H3; try lia;  apply Hg.
Qed.

Fact cty_alignment_bijection X g :
  cty X -> @alignment X g -> surjective g -> bijection X nat.
Proof.
  intros H1 [Hg1 Hg2] H2.
  enough (Sigma f : nat -> X, inv f g /\ inv g f) as (f&H3&H4).
  { exists g f; easy. }
  apply bijection_ex. easy. apply cty_ewo. exact H1. apply eqdec_nat.
Qed.

(*** Finite Types and Cutoffs *)

From Coq Require Import List.
Import ListNotations.
Notation "x 'el' A" := (In x A) (at level 70).
Notation "x 'nel' A" := (~ In x A) (at level 70).
Fixpoint nrep {X} (A: list X) : Prop :=
  match A with
  | [] => True
  | x::A => x nel A /\ nrep A
  end.
Fact map_injective {X Y f x A} :
  @injective X Y f -> f x el map f A -> x el A.
Proof.
  intros H (?&->%H&H2) %in_map_iff. exact H2.
Qed.
Fact nrep_map X Y f A :
  @injective X Y f -> nrep A -> nrep (map f A).
Proof.
  intros H.
  induction A as [|x A IH]; cbn.
  - auto.
  - intros [H2 H3]. split. 
    + contradict H2. eapply map_injective; eassumption.
    + auto.
Qed.

Definition covering {X} (A: list X) :=
  forall x, x el A.
Definition listing {X} (A: list X) :=
  covering A /\ nrep A.
Definition fin n X : Type :=
  eqdec X * Sigma A,  @listing X A /\ length A = n.

Definition cty_hit {X f n} :
  cty X -> @hit X f n -> Sigma x, f x = n.
Proof.
  intros H1 H2. apply (cty_ewo H1). 2:exact H2.
  intros x. apply eqdec_nat.
Qed.

Definition cty_alignment_list {X f} n :
  cty X -> @alignment X f -> hit f n ->
  Sigma A, nrep A /\ length A = S n /\
         forall k, k <= n <-> k el map f A.
Proof.
  intros H1 H2 H3.
  induction n as [|n IH].
  - destruct (cty_hit H1 H3) as [x H4].
    exists [x]. split; cbn. easy. split. easy. intuition lia.
  - destruct (cty_hit H1 H3) as [x H4].
    destruct IH as (A&IH1&IH2&IH3). {apply H2, H3.}
    exists (x::A). cbn. split. 1:split. 2:exact IH1. 2:split. 2:congruence.
    + intros H5. enough (f x <= n) by lia.
      apply IH3. apply in_map, H5. 
    +  intros k. split. 
      * intros H5. cbn.
        assert (k = S n \/ k <= n) as [->|H6] by lia. {auto.}
        right. apply IH3, H6.
      * intros [<-|H5]. lia. apply IH3 in H5. lia.
Qed.

Fact hit_self X f x :
  @hit X f (f x).
Proof.
  exists x. reflexivity.
Qed.

Definition cutoff {X} (f: X -> nat) n :=  forall k, hit f k <-> k < n.

Definition alignment_cutoff_fin X f n :
  cty X -> @alignment X f -> cutoff f n -> fin n X.
Proof.
  intros H1 H2 H3. split. {apply H1.}
  destruct n.
  - exists []. split. 2:easy. split. 2:easy.
    intros x. enough (f x < 0) by lia. apply H3,hit_self.
  - destruct (cty_alignment_list n H1 H2) as (A&H7&H8&H9).
    {apply H3. lia.} 
    exists A. split. 2:easy. split. 2:easy.
    intros x. eapply map_injective. apply H2.
    apply H9. enough (f x < S n) by lia. apply H3,hit_self.
Qed.

Definition serial_list A := forall n, S n el A -> n el A.

Fact serial_list_nrep A :
  serial_list A -> nrep A ->
  forall k, k el A <-> k < length A.
Admitted.

Definition fin_alignment_cutoff X f n :
  fin n X -> @alignment X f -> cutoff f n.
Proof.
  intros (H1&A&[H2 H3]&<-) H5. hnf.
  assert(H6: forall k, hit f k <-> k el map f A).
  { intros k. split; intros H7.
    - apply in_map_iff. destruct H7 as [x H7].
      exists x. split. exact H7. apply H2.
    - apply in_map_iff in H7 as (x&<-&H8). apply hit_self. }
  enough(forall k, k el map f A <-> k < length A). {firstorder.}
  rewrite <- map_length with (f:=f).
  apply serial_list_nrep.
  + intros k (x&H7&H8) %in_map_iff.
    assert (H9: hit f k). {apply H5. exists x. exact H7.}
    apply H6, H9.
  + apply nrep_map. apply H5. exact H3.
Qed.
 
(*** Finite or Infinite *)

Fact serial_hit_le X f n k :
  @serial X f -> hit f n -> k <= n -> hit f k.
Proof.
  intros H. induction n as [|n IH]; intros H1 H2.
  - assert (k=0) as -> by lia. exact H1.
  - assert (k=S n \/ k <= n) as [->|H3] by lia.
    exact H1.
    firstorder.
Qed.

Definition XM : Prop := forall X: Prop, X \/ ~X.

Fact least_xm_exists (p: nat -> Prop) :
  XM -> ex p -> ex (least p).
Proof.
  intros xm.
  enough (forall n, ex (least p) \/ safe p n) as H1.
  { intros [n H]. specialize (H1 n) as [H1|H1]. easy. exists n; easy. }
  induction n as [|n [IH|IH]].
  - right. hnf; lia.
  - left. exact IH.
  - destruct (xm (p n)) as [H|H].
    + left. exists n. easy.
    + right. apply safe_S; easy.
Qed.

Fact XM_cutoff_or_surjective X f :
  XM -> @serial X f -> ex (cutoff f) \/ surjective f.
Proof.
  intros xm H.
  destruct (xm (surjective f)) as [H1|H1]. {auto.} left.
  pose (miss n := ~hit f n).
  enough (ex (least miss)) as [n H2].
  - exists n. intros k. split; intros H3.
    + destruct (xm (hit f k)) as [H4|H4]. {auto.} exfalso.
      apply H2 in H4. lia.
    + enough (~ n <= k) by lia. intros H4.
      destruct H2 as [H2 _]. enough (hit f n) by easy.
      revert H H3 H4. apply serial_hit_le.
  - apply least_xm_exists. exact xm.
    destruct (xm (ex miss)) as [H2|H2]. {auto.} exfalso.
    apply H1. intros n.
    destruct (xm (hit f n)) as [H3|H3]. {auto.} exfalso.
    eauto.
Qed.

Inductive box (X: Type) : Prop := T (x:X).

Fact cty_finite_or_infinite X :
  XM -> cty X -> box ((Sigma n, fin n X) + bijection X nat).
Proof.
  intros xm H.
  destruct (cty_alignment H) as [f H1].
  edestruct XM_cutoff_or_surjective as [H2|H2]. exact xm. now apply H1.
  - destruct H2 as [n H2]. constructor. left. exists n.
    eapply alignment_cutoff_fin; eassumption.
  - constructor. right.
    eapply cty_alignment_bijection; eassumption.
Qed.

