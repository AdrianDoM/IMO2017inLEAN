import group_theory.subgroup
import algebra.punit_instances

namespace subgroup

variables {G H K : Type*} [group G] [group H] [group K]

@[simp] lemma coe_inj {H : subgroup G} (x y : H) : (x : G) = y ↔ x = y := set_coe.ext_iff

@[simp] lemma range_subtype (H : subgroup G) : H.subtype.range = H :=
ext' $ H.subtype.coe_range.trans subtype.range_coe

variables {f : G →* H}

lemma map_eq_comap_of_inverse {g : H →* G} (hl : function.left_inverse g f)
  (hr : function.right_inverse g f) (K : subgroup G) : map f K = comap g K :=
ext' $ by rw [coe_map, coe_comap, set.image_eq_preimage_of_inverse hl hr]

lemma map_comap_eq (hf : function.surjective f) (K : subgroup H) :
  map f (comap f K) = K :=
ext' $ by rw [coe_map, coe_comap, set.image_preimage_eq ↑K hf]

lemma ker_le_comap {K : subgroup H} : f.ker ≤ comap f K :=
(gc_map_comap f).monotone_u bot_le

lemma le_ker_iff_map {K : subgroup G} : K ≤ f.ker ↔ map f K = ⊥ :=
by rw [monoid_hom.ker, eq_bot_iff, gc_map_comap]

lemma subsingleton_subgroup_iff {H : subgroup G} : subsingleton H ↔ H = ⊥ :=
⟨λ h, le_antisymm (λ a ha, sorry) bot_le,
λ h, subsingleton.intro $ λ ⟨a, ha⟩ ⟨b, hb⟩, by { rw h at *, congr, rw [mem_bot.mp ha, mem_bot.mp hb] }⟩

end subgroup

namespace monoid_hom

open subgroup

variables {G H : Type*} [group G] [group H]

@[simp] lemma range_one : (1 : G →* H).range = ⊥ :=
subgroup.ext $ λ x, ⟨
  λ ⟨y, hy⟩, mem_bot.mpr (hy ▸ one_apply _),
  λ hx, ⟨1, (mem_bot.mp hx).symm ▸ one_apply _⟩
⟩

lemma injective_iff_ker_eq_bot (f : G →* H) : function.injective f ↔ f.ker = ⊥ :=
iff.trans (injective_iff f)
  ⟨λ h, le_antisymm (λ x hx, subgroup.mem_bot.mpr $ h x $ (mem_ker f).mp hx) bot_le,
  λ h x hx, by { rwa [←mem_ker, h, subgroup.mem_bot] at hx }⟩

instance range_subsingleton {f : G →* H} [subsingleton G] : subsingleton f.range :=
⟨λ ⟨a, x, hx⟩ ⟨b, y, hy⟩, by simp only [←hx, ←hy, subsingleton.elim x y]⟩

lemma range_subsingleton_eq_bot (f : G →* H) [subsingleton G] : f.range = ⊥ :=
by rw ←subsingleton_subgroup_iff.mp monoid_hom.range_subsingleton; apply_instance

lemma mem_range_self (f : G →* H) (x : G) : f x ∈ f.range := mem_range.mpr ⟨x, rfl⟩

def range_restrict (f : G →* H) : G →* f.range :=
f.cod_restrict f.range f.mem_range_self

end monoid_hom

namespace mul_equiv

variables {G H : Type*} [group G] [group H]
variables {f : G →* H}

def of_left_inverse {g : H → G} (h : function.left_inverse g f) : G ≃* f.range :=
{ to_fun := f.range_restrict,
  inv_fun := g ∘ f.range.subtype,
  left_inv := h,
  right_inv := λ x, subtype.ext $
    let ⟨x', hx'⟩ := monoid_hom.mem_range.mp x.prop in
    show f (g x) = x, by rw [←hx', h x'],
  .. f.range_restrict }

noncomputable def of_injective (h : function.injective f) : G ≃* f.range :=
of_left_inverse $ classical.some_spec h.has_left_inverse

def of_subsingleton (h : subsingleton G) : G ≃* punit :=
⟨λ _, punit.star, λ _, 1, λ x, subsingleton.elim _ _, λ x, subsingleton.elim _ _, λ _ _, rfl⟩

end mul_equiv