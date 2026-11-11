# Noth fleet curated-build state
# Read by the monthly analysis routine; updated locally on promotion.
status: PROMOTED
image: 2026.09.15-noth3
base_nightly: 2026.09.15-0029-rolling
base_vyos_build_commit: 22dfa15927f2bd01336ab2c0154800f061b0f2e8
base_vyos_1x_commit: 4e1793c69cb077dbfde2fe2c012b664b4bf1cba2
curated_vyos_build_head: 0984a382 (branch noth3, srnoth/vyos-build; the ISO was built from 5055e301, same sources)
curated_vyos_1x_head: 653aac06e04f4cb3f4e86bbba9245b57a2001c6f (branch noth3, srnoth/vyos-1x)
kernel: 6.18.57
linux_firmware: 20260916
promoted: 2026-11-10/11 (five routers; the rest of the fleet in progress)
previous: 2026.09.15-noth1 (2026-10-12, branch noth-stable), noth2 (2026-11-10, branch noth2, withdrawn: WWAN naming regression)
included_on_top_of_base:
  - vyos-build PR #1323 (T9197, iwlwifi firmware selection; upstream 78005f0)
  - vyos-build kernel bumps T9385 (6.18.54, 6.18.55) and T9470 (6.18.57)
  - vyos-build: Intel out-of-tree NIC drivers pinned to the noth1 commits; package.toml commit_id honoured (from T9577)
  - vyos-1x f75c7b74d (T8989, OIDC audience hotfix)
  - vyos-1x d16a88c27 (T9377, prerequisite for the next entry)
  - vyos-1x c8d75f88f (T9368, PR #5520, FRR reconcile after a DHCP lease)
  - vyos-1x T9454 (render FRR after a DHCP lease only once the commit completed)
  - vyos-1x T9349 (do not start dhcp6c in debug mode)
  - vyos-1x T9326 (WWAN dual-stack connect on single-PDN-context networks)
  - vyos-1x T9350 (WWAN re-dial in vyos-netlinkd; disconnect; ModemManager queries; dialable wait)
  - vyos-1x T9442 (FRR config cache only after apply; reload when not applied)
  - vyos-1x T9254 (no ESN transforms in IKE proposals)
  - vyos-1x T9542 (swanctl/systemctl instead of the removed ipsec script; op-mode fixes)
  - vyos-1x T9474 / T9475 (rebuild firewall, PBR, conntrack, NAT, NAT66 tables when rule file and table drift)
  - vyos-1x 7b17be1a0 (own fix, T3871 follow-up: never bootstrap-name a WWAN modem into ethN; not yet upstream)
carry_forward_next_cycle (take the upstream fix if rolling has one, else carry our patch):
  - T9610: python/vyos/ethtool.py check_flow_control() rejects disable-flow-control on
    i40e/ice (02471a8b8). Our patch: a separate flow-control driver list without i40e/ice.
    A router with i40e ports runs without disable-flow-control until then; restore it
    with the fixed image (add it to the new image's copied config.boot before reboot).
  - T9611: service_dhcpv6-server.py does not chown /config/dhcp/kea-dhcp6-serverid to _kea;
    kea-dhcp6 fails when the _kea UID shifts between images. Our patch: include the file
    in the chown loop.
  - 7b17be1a0 (WWAN bootstrap naming): check whether upstream fixed T3871 for wwan.
known_constraints:
  - T3871 interface naming rework is in the base; every ethernet interface must
    carry hw-id in the config before upgrading (T9291 / T9440).
  - Bare-metal routers: bridge MACs come from machine-id, which changes per image.
    Pin bridge MACs before upgrading.
  - Run the upgrade-check gates before each install (flow-control on i40e/ice,
    missing hw-id); after the install, check the /config owner-change diff.
notes: When judging the next candidate, anything listed under
  included_on_top_of_base that is already contained in the candidate needs no
  cherry-pick. Take the candidate's commits from the nightly's own manifest,
  not from `git rev-list --before`.
