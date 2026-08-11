# Noth fleet curated-build state
# Read by the monthly analysis routine; updated locally on promotion.
status: BOOTSTRAP-PENDING
base_nightly: none
base_vyos_build_commit: none
base_vyos_1x_commit: none
promoted: never
notes: Bootstrap target = first nightly containing vyos-build e14a489 (T9197
  CONFIG_IWLMLD) with rebuilt vyos-linux-firmware, after hardware validation
  on noth-camper-fw1. Until then, treat the newest nightly >=28 days old as the
  provisional analysis window endpoint.
