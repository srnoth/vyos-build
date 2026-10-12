# Noth fleet curated-build state
# Read by the monthly analysis routine; updated locally on promotion.
status: PROMOTED
image: 2026.09.15-noth1
base_nightly: 2026.09.15-0029-rolling
base_vyos_build_commit: 22dfa15927f2bd01336ab2c0154800f061b0f2e8
base_vyos_1x_commit: 4e1793c69cb077dbfde2fe2c012b664b4bf1cba2
curated_vyos_build_head: 8c73ef84307d832323813042c67f04a8a27f0a8d (branch noth-stable)
curated_vyos_1x_head: a84f7e54f23ff1463b8548474a9cfed38c7c60a6 (branch noth-stable, srnoth/vyos-1x)
kernel: 6.18.50
linux_firmware: 20260916
promoted: 2026-10-12 (noth-camper-fw1 only; noth-sc-fw2 not yet)
included_on_top_of_base:
  - vyos-build PR #1323 (T9197, iwlwifi firmware selection; upstream 78005f0, merged 2026-10-12)
  - vyos-1x f75c7b74d (T8989, OIDC audience hotfix)
  - vyos-1x d16a88c27 (T9377, prerequisite for the next entry)
  - vyos-1x c8d75f88f (T9368, PR #5520, FRR reconcile after a DHCP lease)
deferred_to_next_cycle:
  - kernel 6.18.54 / 6.18.55 bumps
  - T9410
known_constraints:
  - T3871 interface naming rework is in the base; every ethernet interface must
    carry hw-id in the config before upgrading (T9291 / T9440).
  - noth-sc-fw2: review open WWAN reports (T9350, T9326, T9174, T9349) before
    promoting there.
notes: When judging the next candidate, anything listed under
  included_on_top_of_base that is already contained in the candidate needs no
  cherry-pick. Take the candidate's commits from the nightly's own manifest,
  not from `git rev-list --before`.
