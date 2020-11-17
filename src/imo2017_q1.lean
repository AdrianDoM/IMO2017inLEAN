/-
Copyright (c) 2020 Adrián Doña Mateo. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Adrián Doña Mateo.
-/

import algebra.archimedean
import data.nat.modeq
import data.nat.sqrt
import data.zmod.basic
import tactic
open nat

/-!
# IMO 2017 Q1

For each integer a₀ > 1, define a sequence a₀, a₁, a₂, ... by:
				 
	aₙ₊₁ = √aₙ if √aₙ is an integer, aₙ + 3 otherwise, for each n ≥ 0.

Determine all values of a₀ for which there is a number A such that aₙ = A for infinitely
many values of n.
-/

/-- The first order recurrence relation -/
def a (a₀ : ℕ) : ℕ → ℕ
| 0     := a₀
| (n+1) :=
	let k := sqrt (a n) in
	if k * k = a n then k else a n + 3

/-- The definition of periodicity -/
def periodic (a₀ : ℕ) : Prop :=
	∃ A, ∀ N, ∃ M, N ≤ M ∧ a a₀ M = A

/-- If two terms of the sequence are equal, so are all following terms -/
lemma rest_equal (a₀ : ℕ) (m n : ℕ) (h : a a₀ m = a a₀ n) :
	∀ k, a a₀ (m + k) = a a₀ (n + k) :=
begin
	intro k,
	induction k with k ih,
	{	simpa },
	simp [add_succ, a, ih],
end

/--	If two terms of the sequence are equal, then successive terms that are the same
distance appart will be equal -/
lemma periodic_term_of_term_equal (a₀ : ℕ) (m n : ℕ) (hmn : m ≤ n) (h : a a₀ m = a a₀ n) :
	∀ k, a a₀ (m + k * (n - m)) = a a₀ m :=
begin
	intro k,
	induction k with k ih,
	{	simp },
	calc a a₀ (m + k.succ * (n - m))
			= a a₀ (m + k * (n - m) + (n - m)) : by rw [succ_mul, add_assoc]
	... = a a₀ (m + (n - m))               : rest_equal a₀ (m + k * (n - m)) m ih (n - m)
	... = a a₀ n                           : by rw nat.add_sub_cancel' hmn
	... = a a₀ m                           : eq.symm h
end

/-- If two different terms of the sequence are equal, then it visits the same term
infinitely many times -/
lemma periodic_of_term_equal {a₀ m n : ℕ} (hmn : m < n) (h : a a₀ m = a a₀ n) :
	periodic a₀ :=
begin
	use a a₀ m,
	intro N,
	by_cases hNm : N ≤ m,
	{	use [m, hNm] },
	have : 0 < n - m, from nat.sub_pos_of_lt hmn,
	cases archimedean.arch (N - m) this with k hk,
	simp at hk,
	let M := m + k * (n - m),
	have hM : N ≤ M, from
		calc N
				= N - m + m       : by rw nat.sub_add_cancel (le_of_not_ge hNm)
		... ≤ k * (n - m) + m : by simp [hk]
		... = m + k * (n - m) : by rw add_comm,
	use [M, hM],
	apply periodic_term_of_term_equal _ _ _ (le_of_lt hmn) h,
end

/-- A square is not congruent to 2 modulo 3 -/
lemma not_square_of_two_mod_three {n : ℕ} (h : n ≡ 2 [MOD 3]) :
	¬∃ m, m * m = n :=
begin
  rintro ⟨m, rfl⟩,
	have : ¬∃ (m : zmod 3), m * m = 2, dec_trivial,
  apply this,
  use m,
  norm_cast,
  rwa ←zmod.eq_iff_modeq_nat at h,
end

/--	If a term of the sequence is congruent to 2 modulo 3 then it is increasing
from that point on -/
lemma increasing_of_term_cong_two {a₀ n : ℕ} (h : a a₀ n ≡ 2 [MOD 3]) :
	∀ m, a a₀ (n + m) = a a₀ n + 3 * m :=
begin
	intro m,
	induction m with m ih,
	{	simp },
	have : a a₀ (n + m) ≡ 2 [MOD 3],
	{	rw [ih, modeq, add_mod, mul_mod, mod_self],
		simpa	},
	rw add_succ,
	simp [a],
	split_ifs with hsq,
	{	exfalso,
		apply not_square_of_two_mod_three this ⟨_, hsq⟩ },
	rw [ih, add_assoc, ←mul_succ],
end

#check nat.add_sub_cancel'

/-- If a term of the sequence is congruent to 2 modulo 3 then it is not periodic -/
lemma not_periodic_of_term_cong_two (a₀ n : ℕ) (h : a a₀ n ≡ 2 [MOD 3]) :
	¬ periodic a₀ :=
begin
	rintro ⟨A, hA⟩,
	rcases hA n with ⟨m₁, hnm₁, hm₁⟩,
	have : a a₀ m₁ ≡ 2 [MOD 3],
	{	apply modeq.trans _ h,
		have : (↑(a a₀ m₁) : zmod 3) = ↑(a a₀ n + 3 * (m₁ - n)), 
		{	congr,
			convert increasing_of_term_cong_two h (m₁ - n),
			rw nat.add_sub_cancel' hnm₁ },
		simp at this,
		rwa ←zmod.eq_iff_modeq_nat 3 },
	rcases hA (m₁ + 1) with ⟨m₂, hmm₂, hm₂⟩,
	have : a a₀ m₂ = A + 3 * (m₂ - m₁),
	{	rw ←hm₁,
		convert increasing_of_term_cong_two this (m₂ - m₁),
		rw nat.add_sub_cancel' (le_of_succ_le hmm₂) },
	rw hm₂ at this,
	have hmm₂ : 0 < m₂ - m₁, from nat.sub_pos_of_lt (lt_of_succ_le hmm₂),
	linarith, 
end

/-- There are no perfect squares strictly between a² and (a+1)² -/
lemma no_middle_square {a n : ℕ} (hl : a * a < n) (hr : n < (a + 1) * (a + 1)):
	¬ ∃ t, t * t = n :=
begin
	rintro ⟨t, rfl⟩,
	have : a < t, from nat.mul_self_lt_mul_self_iff.mpr hl,
	have : t < a + 1, from nat.mul_self_lt_mul_self_iff.mpr hr,
	linarith,
end

/- This long lemma takes care of each possibility for b and t mod 3.
Some parts involve repetitive computation so I suspect some refactoring is possible -/
lemma first_square_aux {b t : ℕ} {bm tm : zmod 3} (hb : bm = b) (hbm : bm ≠ 2) (ht : tm = t)
	(ht1 : t * t < b) (ht2 : b ≤ (t + 1) * (t + 1)) :
	∃ (j : fin 3) n, b + 3 * n = (t + 1 + j) * (t + 1 + j) ∧
	∀ k, k < n → ¬ ∃ r, r * r = b + 3 * k :=
begin
	have : bm * bm = bm,
	{	fin_cases bm; ring,
		contradiction },
	/-
		j is selected to find the first suitable entry in the following table.
		+---+---------+---------+---------+
		| t | (t+1)^2 | (t+2)^2 | (t+3)^2 |
		+---+---------+---------+---------+
		| 0 |       1 |       1 |       0 |
		| 1 |       1 |       0 |       1 |
		| 2 |       0 |       1 |       1 |
		+---+---------+---------+---------+
	-/
	let j : fin 3 := if tm = 2 then bm else (if bm = 1 then 0 else (if tm = 0 then 2 else 1)),
	use j,
	have : bm = (t + 1 + j) * (t + 1 + j),
	{	simp [←ht, j],
		symmetry,
		split_ifs,
		{	rw h, convert ‹bm * bm = bm›; abel },
		{	rw h_1, ring, fin_cases tm; ring, contradiction },
		{	rw h_2, ring, fin_cases bm, abel, repeat {contradiction} },
		fin_cases tm,
		{	contradiction },
		{	fin_cases bm, dsimp, ring, repeat {contradiction} },
		contradiction },
	have : b ≤ (t + 1 + j) * (t + 1 + j),
	{	have : 0 ≤ ↑j, dec_trivial,
		have : t + 1 ≤ t + 1 + ↑j, linarith,
		apply le_trans ht2,
		apply mul_self_le_mul_self (nat.zero_le _) this },
	have : (3 : ℤ) ∣ (t + 1 + j) * (t + 1 + j) - b,
	{ apply (zmod.int_coe_zmod_eq_zero_iff_dvd _ 3).mp,
		simp [←hb],
		rw ‹bm = (t + 1 + j) * (t + 1 + j)›,
		ring },
	cases this with n hn,
	cases n with n,
	{	use n,
		have h : b + 3 * n = (t + 1 + ↑j) * (t + 1 + ↑j),
		{	apply (int.coe_nat_eq_coe_nat_iff _ _).mp,
			simp,
			rw [int.coe_nat_eq n, ←hn],
			ring },
		use h,
		intros k hk hr,
		have h1 : t * t < b + 3 * k, linarith,
		simp [j] at h,
		split_ifs at h,
		{ fin_cases bm,
			{ simp at h,
		 		have h2 : b + 3 * k < (t + 1) * (t + 1), linarith, 
				exact no_middle_square h1 h2 hr },
			{ simp at h,
				have h3 : (0 : zmod 3) = (t + 1) * (t + 1), rw [←ht, h_1], ring,
				by_cases b + 3 * k < (t + 1) * (t + 1),
				{ exact no_middle_square h1 h hr },
				have h1 : (t + 1) * (t + 1) < b + 3 * k,
				{	cases eq_or_lt_of_not_lt h with h h,
					{ exfalso,
						have : ↑(b + 3 * k) = (↑((t + 1) * (t + 1)) : zmod 3), rw h,
						simp at this,
						rw [←h3] at this,
						have h : (1 : zmod 3) ≠ 0, norm_num,
						exact h (eq.trans hb this) },
					exact h },
				have h2 : b + 3 * k < (t + 1 + 1) * (t + 1 + 1), linarith,
				exact no_middle_square h1 h2 hr },
			contradiction },
		{ simp at h,
			have h2 : b + 3 * k < (t + 1) * (t + 1), linarith,
			exact no_middle_square h1 h2 hr },
		{ simp at h,
			fin_cases bm,
			{ /- longest case. compare against (t + 1) * (t + 1) and (t + 2) * (t + 2) -/
				by_cases b + 3 * k < (t + 1) * (t + 1),
				{	exact no_middle_square h1 h hr },
				have h1 : (t + 1) * (t + 1) < b + 3 * k,
				{	cases eq_or_lt_of_not_lt h with h h,
					{ exfalso, 
						have h3 : (1 : zmod 3) = (t + 1) * (t + 1), rw [←ht, h_3], ring,
						have : ↑(b + 3 * k) = (↑((t + 1) * (t + 1)) : zmod 3), rw h,
						simp at this,
						rw [←h3] at this,
						exact h_2 (eq.trans hb this) },
					exact h },
				by_cases b + 3 * k < (t + 2) * (t + 2),
				{	exact no_middle_square h1 h hr },
				have h1 : (t + 2) * (t + 2) < b + 3 * k,
				{ cases eq_or_lt_of_not_lt h with h h,
					{ exfalso, 
						have h3 : (1 : zmod 3) = (t + 2) * (t + 2), rw [←ht, h_3], ring,
						have : ↑(b + 3 * k) = (↑((t + 2) * (t + 2)) : zmod 3), rw h,
						simp at this,
						rw [←h3] at this,
						exact h_2 (eq.trans hb this) },
					exact h },
				have h2 : b + 3 * k < (t + 3) * (t + 3), linarith,
				exact no_middle_square h1 h2 hr },
			{ contradiction },
			{ contradiction } },
		{ simp at h,
			fin_cases tm,
			{ contradiction },
			{ dsimp at ht,
				fin_cases bm,
				{ have h3 : (1 : zmod 3) = (t + 1) * (t + 1), rw ←ht, ring,
					by_cases b + 3 * k < (t + 1) * (t + 1),
					{ exact no_middle_square h1 h hr },
					have h1 : (t + 1) * (t + 1) < b + 3 * k,
					{	cases eq_or_lt_of_not_lt h with h h,
						{ exfalso,
							have : ↑(b + 3 * k) = (↑((t + 1) * (t + 1)) : zmod 3), rw h,
							simp at this,
							rw [←h3] at this,
							exact h_2 (eq.trans hb this) },
						exact h },
					have h2 : b + 3 * k < (t + 1 + 1) * (t + 1 + 1), linarith,
					exact no_middle_square h1 h2 hr },
				{ contradiction },
				{ contradiction } },
			{ contradiction } } },
	exfalso,
	have : (0 : ℤ) ≤ (t + 1 + j) * (t + 1 + j) - b,
	{	apply int.sub_nonneg_of_le,
		norm_cast,
		exact this },
	rw hn at this,
	have : 3 * -[1+ n] < 0,
	{	apply int.mul_neg_of_pos_of_neg,
		norm_num,
		apply int.neg_succ_lt_zero },
	linarith,
end

/-- If ¬ aₙ ≡ 2 [MOD 3] and aₙ > 9 then the next perfect square in the sequence is one of
t², (t+1)² or (t+2)², where t is the largest natural number such that t² ≤ aₙ -/
lemma first_square {a₀ n : ℕ} (h1 : ¬ a a₀ n ≡ 2 [MOD 3]) (h2 : a a₀ n ≠ 0) :
	let t := sqrt (a a₀ n - 1) in
	∃ (j : fin 3) m, n ≤ m ∧ a a₀ m = (t + 1 + j) * (t + 1 + j) ∧
	∀ k, n ≤ k → k < m → ¬ ∃ r, r * r = a a₀ k :=
begin
	intro,
	have ht1 : t * t < a a₀ n,
	{	simp [t],
		apply lt_of_le_of_lt (sqrt_le _),
		rw ←pred_eq_sub_one,
		apply pred_lt,
		assumption },
	have ht2 : a a₀ n ≤ (t + 1) * (t + 1),
	{	have : a a₀ n - 1 < (t + 1) * (t + 1), from lt_succ_sqrt _,
		rw ←pred_eq_sub_one at this,
		apply le_of_pred_lt this },
	set am : zmod 3 := a a₀ n with ham,
	set tm : zmod 3 := t with htm,
	have hamn2 : am ≠ 2,
	{ by_contradiction,
		simp at h,
		have : (↑(a a₀ n) : zmod 3) = ↑2, rw ←ham, assumption,
		rw zmod.eq_iff_modeq_nat at this,
		exact h1 this },
	rcases first_square_aux ham hamn2 htm ht1 ht2 with ⟨j, i, hsq, hfirst⟩,
	use [j, n + i, by simp],
	have hi : ∀ k, k ≤ i → a a₀ (n + k) = a a₀ n + 3 * k,
	{	intro k,
		induction k with k ih,
		{	intro, ring },
		intro hk,
		have ih : a a₀ (n + k) = a a₀ n + 3 * k, from ih (le_of_succ_le hk),
		rw add_succ,
		simp [a],
		split_ifs,
		{ exfalso,
			apply hfirst k (lt_of_succ_le hk) ⟨sqrt (a a₀ n + 3 * k), _⟩,
			rwa ←ih },
		rw [ih, add_assoc, ←mul_succ] },
	split,
	{	rwa hi i (by refl) },
	intros k hk1 hk2,
	have hkni : k - n < i, from (nat.sub_lt_left_iff_lt_add hk1).mpr hk2,
	have : a a₀ k = a a₀ n + 3 * (k - n),
	{	rw ←hi (k - n) _,
		{	rw nat.add_sub_cancel' hk1 },
		exact le_of_lt hkni },
	rw this,
	exact hfirst _ hkni,
end

/-- If ¬ aₙ ≡ 2 [MOD 3] and aₙ > 9 then there is an index m > n such that aₘ < aₙ -/
lemma term_lt_of_term_not_congr_2 {a₀ n : ℕ} (h1 : ¬ a a₀ n ≡ 2 [MOD 3]) (h2 : 9 < a a₀ n) :
	∃ m, m > n ∧ a a₀ m < a a₀ n :=
begin
	rcases first_square h1 (by linarith) with ⟨j, m, hnm, ham, hfirst⟩,
	use [m + 1, by linarith],
	simp [a],
	split_ifs with hsq hnsq,
	{ apply sqrt_lt.mpr,
		rw ham,
		apply nat.mul_self_lt_mul_self,
		have : 9 ≤ a a₀ n - 1, { rw ←pred_eq_sub_one, apply le_pred_of_lt h2 },
		have h3 : 3 ≤ sqrt (a a₀ n - 1), { apply le_sqrt.mpr, linarith },
		have h2 : 2 ≤ sqrt (a a₀ n - 1), from le_of_succ_le h3,
		calc sqrt (a a₀ n - 1) + 1 + ↑j
				≤ sqrt (a a₀ n - 1) + 3
			:	by { have : ↑j ≤ 2, from le_of_lt_succ (fin.is_lt j),	linarith }
		... ≤ sqrt (a a₀ n - 1) + sqrt (a a₀ n - 1)
			: by linarith
		... = 2 * sqrt (a a₀ n - 1)
			: by rw two_mul
		... ≤ sqrt (a a₀ n - 1) * sqrt (a a₀ n - 1)
			: by { apply mul_le_mul h2, refl, repeat {linarith} }
		... ≤ a a₀ n - 1
			: by apply sqrt_le
		... < a a₀ n
			:	by { rw ←pred_eq_sub_one, apply pred_lt, linarith } },
	exfalso,
	have : sqrt (a a₀ m) = sqrt (a a₀ n - 1) + 1 + ↑j, { rw ham, apply sqrt_eq },
	rw ←this at ham,
	exact hsq (eq.symm ham),
end

/-- A multiple of 3 is always followed by a multiple of 3 -/
lemma mul_three_of_mul_three {a₀ n : ℕ} (h : a a₀ n ≡ 0 [MOD 3]) :
	∀ m, n ≤ m → a a₀ m ≡ 0 [MOD 3] :=
begin
	have : ∀ k, a a₀ (n + k) ≡ 0 [MOD 3],
	{ intro k,
		induction k with k ih,
		{	simpa },
		rw add_succ,
		simp [a],
		split_ifs with hsq,
		{	rw [←hsq, modeq.modeq_zero_iff, prime.dvd_mul] at ih,
			{	cases ih;	{ apply modeq.modeq_zero_iff.mpr, exact ih } },
			norm_num },
		rw ←add_zero 0,
		apply modeq.modeq_add,
		{ assumption },
		simp [modeq] },
	intros m hnm,
	convert this (m - n),
	rw nat.add_sub_cancel' hnm,
end


/-- If aₙ ∈ {3,6,9}, then the sequence visits three infinitely many times -/
lemma periodic_of_three_six_nine {a₀ n : ℕ} (h : a a₀ n = 3 ∨ a a₀ n = 6 ∨ a a₀ n = 9) :
	periodic a₀ :=
begin
	have h9 : ∀ n, a a₀ n = 9 → a a₀ (n+1) = 3,
	{ intros n h,
		have hsq : sqrt (3 * 3) = 3, rw sqrt_eq 3,
		change sqrt 9 = 3 at hsq,
		simp [a],
		split_ifs with h',
		{	rwa h },
		rw [h, hsq] at h',
		contradiction },
	have h6 : ∀ n, a a₀ n = 6 → a a₀ (n+1) = 9,
	{ intros n h,
		simp [a],
		split_ifs with h',
		{ rw h at h',
			exfalso,
			apply @no_middle_square 2 6 _ _ ⟨sqrt 6, h'⟩; norm_num },
		rw h },
	have h3 : ∀ n, a a₀ n = 3 → a a₀ (n+1) = 6,
	{	intros n h,
		simp [a],
		split_ifs with h',
		{	rw h at h',
			exfalso,
			apply @no_middle_square 1 3 _ _ ⟨sqrt 3, h'⟩; norm_num },
		rw h },
	apply @periodic_of_term_equal _ n (n + 3) (by linarith),
	rcases h with c3 | c6 | c9,
	{	rw c3,
		have : a a₀ (n+1) = 6, from h3 _ c3,
		have : a a₀ (n+2) = 9, from h6 _ this,
		have : a a₀ (n+3) = 3, from h9 _ this,
		rw this },
	{ rw c6,
		have : a a₀ (n+1) = 9, from h6 _ c6,
		have : a a₀ (n+2) = 3, from h9 _ this,
		have : a a₀ (n+3) = 6, from h3 _ this,
		rw this },
	{ rw c9,
		have : a a₀ (n+1) = 3, from h9 _ c9,
		have : a a₀ (n+2) = 6, from h3 _ this,
		have : a a₀ (n+3) = 9, from h6 _ this,
		rw this },
end

lemma mul_three_le_9 {x : ℕ} (h9 : x ≤ 9) (h3 : 3 ∣ x) : x = 0 ∨ x = 3 ∨ x = 6 ∨ x = 9 :=
begin
    cases h3 with k h3k,
    have : k ≤ 3 := by linarith,
    interval_cases k; dec_trivial!,
end

/-- If aₙ ≡ 0 [MOD 3], then there is an index m > n such that aₘ = 3 -/
lemma periodic_of_term_cong_zero (a₀ n : ℕ) (h : a a₀ n ≡ 0 [MOD 3]) :
	periodic a₀ :=
begin
	have hlt : ∀ k, 9 ≤ a a₀ n - k → ∃ m, n ≤ m ∧ a a₀ m ≤ a a₀ n - k,
	{	intro k,
		induction k with k ih,
		{	intro, use [n, by refl], rw nat.sub_zero },
		intro hk,
		have hk' : 9 ≤ a a₀ n - k,
		{	rw sub_succ at hk,
			apply le_trans hk (pred_le _) },
		rcases ih hk' with ⟨m, hnm, hm⟩,
		by_cases h9 : a a₀ m ≤ 9,
		{	use [m, hnm, le_trans h9 hk] },
		have h0 : a a₀ m ≡ 0 [MOD 3], from mul_three_of_mul_three h m hnm,
		have hn2 : ¬ a a₀ m ≡ 2 [MOD 3], -- this should be a lot easier
		{	intro h,
			have : 2 ≡ 0 [MOD 3], from modeq.trans (modeq.symm h) h0,
			rw [modeq.modeq_zero_iff] at this,
			have : 3 ≤ 2, from le_of_dvd (by norm_num) this,
			linarith },
		have h9 : 9 < a a₀ m, from lt_of_not_ge h9,
		rcases term_lt_of_term_not_congr_2 hn2 h9 with ⟨m', hnm', hm'⟩,
		use [m', le_trans hnm (le_of_lt hnm')],
		rw sub_succ,
		apply le_pred_of_lt,
		apply lt_of_lt_of_le hm' hm	},
	have : ∃ m, n ≤ m ∧ a a₀ m ≤ 9,
	{	by_cases h9 : a a₀ n ≤ 9,
		{ use [n, h9] },
		have : a a₀ n - (a a₀ n - 9) = 9, from nat.sub_sub_self (le_of_not_le h9),
		rcases hlt (a a₀ n - 9) (le_of_eq (eq.symm this)) with ⟨m, hnm, hm⟩,
		rw this at hm,
		use [m, hnm, hm] },
	rcases this with ⟨m, hnm, hm⟩,
	have : a a₀ m = 0 ∨ a a₀ m = 3 ∨ a a₀ m = 6 ∨ a a₀ m = 9,
	{	apply mul_three_le_9 hm,
		rw ←modeq.modeq_zero_iff,
		exact mul_three_of_mul_three h m hnm },
	cases this with h0 h369,
	{	apply @periodic_of_term_equal _ m (m + 1) (lt_succ_self m), 
		rw h0,
		simp [a],
		split_ifs,
		{	rw h0, refl },
		rw h0 at h_1,
		contradiction },
	apply periodic_of_three_six_nine h369,
end

lemma term_cong_two_of_four_seven {a₀ n : ℕ} (h : a a₀ n = 4 ∨ a a₀ n = 7) :
	∃ m, n < m ∧ a a₀ m ≡ 2 [MOD 3] :=
begin
	have h4 : ∀ n, a a₀ n = 4 → a a₀ (n+1) = 2,
	{	intros n han,
		have hsq : sqrt (2 * 2) = 2, from sqrt_eq 2,
		change sqrt 4 = 2 at hsq,
		simp [a],
		split_ifs with h',
		{	rwa han },
		rw [han, hsq] at h',
		contradiction },
	have h7 : ∀ n, a a₀ n = 7 → a a₀ (n+1) = 10,
	{ intros n han,
		simp [a],
		split_ifs with h',
		{	rw han at h',
			exfalso,
			apply @no_middle_square 2 7 _ _ ⟨sqrt 7, h'⟩; norm_num },
		rw han },
	have h10 : ∀ n, a a₀ n = 10 → a a₀ (n+1) = 13,
	{ intros n han,
		simp [a],
		split_ifs with h',
		{	rw han at h',
			exfalso,
			apply @no_middle_square 3 10 _ _ ⟨sqrt 10, h'⟩; norm_num },
		rw han },
	have h13 : ∀ n, a a₀ n = 13 → a a₀ (n+1) = 16,
	{ intros n han,
		simp [a],
		split_ifs with h',
		{	rw han at h',
			exfalso,
			apply @no_middle_square 3 13 _ _ ⟨sqrt 13, h'⟩; norm_num },
		rw han },
	have h16 : ∀ n, a a₀ n = 16 → a a₀ (n+1) = 4,
	{	intros n han,
		have hsq : sqrt (4 * 4) = 4, from sqrt_eq 4,
		change sqrt 16 = 4 at hsq,
		simp [a],
		split_ifs with h',
		{	rwa han },
		rw [han, hsq] at h',
		contradiction },
	cases h with c4 c7,
	{	use [n + 1, lt_succ_self n],
		have : a a₀ (n+1) = 2, from h4 _ c4,
		rw this },
	{ use [n + 5, by linarith],
		have : a a₀ (n+1) = 10, from h7 _ c7,
		have : a a₀ (n+2) = 13, from h10 _ this,
		have : a a₀ (n+3) = 16, from h13 _ this,
		have : a a₀ (n+4) = 4, from h16 _ this,
		have : a a₀ (n+5) = 2, from h4 _ this,
		rw this },
end

lemma eq_1_4_7_of_cong_1_le_9 (x : ℕ) (h9 : x ≤ 9) (h1 : x ≡ 1 [MOD 3]) :
	x = 1 ∨ x = 4 ∨ x = 7 :=
begin
	by_cases h : x < 1,
	{	interval_cases x, contradiction },
	have hx1 : 1 ≤ x, from le_of_not_lt h,
	have : 3 ∣ x - 1, from (modeq.modeq_iff_dvd' hx1).mp (modeq.symm h1),
	cases this with k h3k,
	have : x = 3 * k + 1, { rw [←nat.sub_add_cancel hx1, h3k] },
	have : k ≤ 8, linarith,
	interval_cases k; dec_trivial!,
end

/-- If aₙ ≡ 1 [MOD 3], then there is an index m > n such that aₘ ≡ 2 [MOD 3] -/
lemma term_cong_two_of_term_cong_one (a₀ n : ℕ) (h : a a₀ n ≡ 1 [MOD 3]) :
	∃ m, m > n ∧ a a₀ m ≡ 2 [MOD 3] :=
begin
	by_contradiction hf,
	have h1 : ∀ k, a a₀ (n + k) ≡ 1 [MOD 3],
	{ intro k,
		induction k with k ih,
		{ assumption },
		rw add_succ,
		simp [a],
		split_ifs with h',
		{	apply (zmod.eq_iff_modeq_nat 3).mp,
			set t : zmod 3 := sqrt (a a₀ (n + k)) with ht,
			have h' : (↑(sqrt (a a₀ (n + k)) * sqrt (a a₀ (n + k))) : zmod 3) = ↑(a a₀ (n + k)),
			{	congr, assumption },
			simp [←ht] at h',
			have ih : (↑(a a₀ (n + k)) : zmod 3) = ↑1,
			{	apply (zmod.eq_iff_modeq_nat 3).mpr, assumption },
			rw ih at h',
			fin_cases t,
			{	have : t * t = ↑0, rw h_1, ring,
				have : ↑0 = ↑1, from eq.trans (eq.symm this) h',
				rw (zmod.eq_iff_modeq_nat 3) at this,
				have : 3 ∣ 1, from modeq.modeq_zero_iff.mp (eq.symm this),
				have : 3 ≤ 1, from le_of_dvd (by norm_num) this,
				contradiction },
			{ assumption },
			{	dsimp at h_1,
				have : a a₀ (n + k).succ = sqrt (a a₀ (n + k)),	{	simp [a], split_ifs, refl },
				have : t = ↑(a a₀ (n + k).succ), { rw this },
				exfalso,
				apply hf ⟨(n + k).succ, _, _⟩,
				{ apply lt_of_lt_of_le (lt_succ_self n),
					apply succ_le_succ,
					linarith },
				rw ←(zmod.eq_iff_modeq_nat 3),
				rwa ←this } },
		rw ←(zmod.eq_iff_modeq_nat 3),
		simp,
		rw ←(zmod.eq_iff_modeq_nat 3) at ih,
		assumption },
	have hlt : ∀ k, 9 ≤ a a₀ n - k → ∃ m, n ≤ m ∧ a a₀ m ≤ a a₀ n - k,
	{ intro k,
		induction k with k ih,
		{	intro, use [n, le_refl n, by refl] },
		intro hk,
		have hk' : 9 ≤ a a₀ n - k,
		{	rw sub_succ at hk,
			apply le_trans hk (pred_le _) },
		rcases ih hk' with ⟨m, hnm, hm⟩,
		by_cases h9 : a a₀ m ≤ 9,
		{	use [m, hnm, le_trans h9 hk] },
		have h0 : a a₀ m ≡ 1 [MOD 3],
		{ convert h1 (m - n),
			symmetry,
			apply nat.add_sub_cancel' hnm },
		have hn2 : ¬ a a₀ m ≡ 2 [MOD 3], -- this should be a lot easier
		{	intro h,
			have : 1 ≡ 2 [MOD 3], from modeq.trans (modeq.symm h0) h,
			rw @modeq.modeq_iff_dvd' _ 1 2 (by norm_num) at this,
			simp at this,
			linarith },
		have h9 : 9 < a a₀ m, from lt_of_not_ge h9,
		rcases term_lt_of_term_not_congr_2 hn2 h9 with ⟨m', hnm', hm'⟩,
		use [m', le_trans hnm (le_of_lt hnm')],
		rw sub_succ,
		apply le_pred_of_lt,
		apply lt_of_lt_of_le hm' hm },
	sorry
end