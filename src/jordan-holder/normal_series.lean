import category_theory.isomorphism_classes
import group_theory.quotient_group
import .subgroup .normal_embedding .simple_group .trivial_class .quotient_group .fingroup

universe u

inductive normal_series : Group.{u} → Type (u+1)
| trivial {G : Group} (hG : subsingleton G) : normal_series G
| base {G : Group} (hG : ¬ subsingleton G): normal_series G
| cons (H G : Group)
  (f : normal_embedding H G) (s : normal_series H) : normal_series G

namespace normal_series

variables {G H K : Group.{u}}

/- Given a normal series for G and an isomorphism G ≃* H, we can produce a normal series for H
by changing the last step from going into G to go into H. -/
def of_mul_equiv_right (h : G ≃* H) : normal_series G → normal_series H
| (trivial hG) := trivial $ @equiv.subsingleton.symm _ _ h.to_equiv hG
| (base hG) := base $ λ hH, hG $ @equiv.subsingleton _ _ h.to_equiv hH
| (cons K G f s) := cons K H (normal_embedding.comp_mul_equiv f h) s

open category_theory 

/- The factors of a normal series are the quotient groups of consecutive elements in the series. -/
@[simp]
def factors : Π {G : Group.{u}}, normal_series G → multiset (isomorphism_classes.obj $ Cat.of Group)
| _ (trivial _) := 0
| G (base _) := quotient.mk' G ::ₘ 0
| _ (cons H G f s) := quotient.mk' (Group.of $ quotient_group.quotient f.φ.range) ::ₘ factors s

/- A composition series is a normal series with simple and nontrivial factors. -/
def composition_series (G : Group.{u}) : Type (u+1) :=
{ σ : normal_series G // ∀ G' ∈ σ.factors, is_simple_class G' ∧ ¬ is_trivial_class G' }

def join {N : subgroup G} [hN : N.normal] : composition_series (Group.of N) →
  composition_series (Group.of $ quotient_group.quotient N) → composition_series G := sorry


local attribute [instance] classical.prop_decidable

variables [hG : fintype G]

-- set_option trace.class_instances true

/- Jordan-Hölder 1. Every finite group has a composition series. -/
noncomputable def exists_composition_series_of_finite :
  composition_series G :=
suffices h : ∀ (n : ℕ) (G : Group) (hG : fintype G),
  @fintype.card G hG = n → composition_series G,
  from h (@fintype.card G hG) G hG rfl,
λ N, N.strong_rec_on $ begin
  intros n ih H, introI hH, intro hn,
  apply classical.subtype_of_exists,
  by_cases h1 : subsingleton H,
  { existsi trivial h1, intro, simp },
  by_cases h2 : is_simple H,
  { existsi normal_series.base h1,
    intros G' hG', simp at hG', simp [hG', quotient.lift_on'_mk'],
    exact ⟨h2, h1⟩ },
  rcases not_is_simple.mp h2 with ⟨N, hN, hNbot, hNtop⟩,
  haveI := hN, -- Add N.normal to instance cache
  suffices s : composition_series H, from ⟨s.val, s.property⟩,
  apply @join _ N hN,
  { apply ih (fintype.card N) (hn ▸ subgroup.card_lt hNtop),
    { simp only [Group.coe_of, eq_self_iff_true] },
    rw Group.coe_of, apply_instance },
  apply ih (fintype.card $ quotient_group.quotient N),
  { rw ←hn, apply quotient_group.card_quotient_lt hNbot },
  { simp only [Group.coe_of, eq_self_iff_true] },
  rw Group.coe_of, apply_instance,
end

/- Jordan-Hölder 2. Any two composition series for `G` have the same factors. -/
theorem eq_factors_of_composition_series (G : Group) [hG : fintype G] (σ τ : composition_series G) :
  σ.val.factors = τ.val.factors := sorry

end normal_series