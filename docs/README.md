# Vesper docs

This file is the documentation index and authority map.

Agents must read this before making architecture changes.

## status vocabulary

Use these labels consistently near the top of architecture documents:

- `current` — documents implemented behavior and current operational truth
- `partial` — some described behavior exists, some remains target work
- `spec` — target architecture or feature contract, not proof of implementation
- `plan` — implementation/design plan that must not be treated as active behavior unless explicitly activated

When a `partial`, `spec` or `plan` document conflicts with current code, current code wins unless the task explicitly changes the implementation.

## authority rules

Repository-wide guardrails live in `../AGENTS.md`.

Subsystem architecture must have one canonical document. Do not create parallel Markdown files for the same contract when one of the documents below already owns it.

| document | status | authority |
|---|---|---|
| `INSTALL.md` | current | verified storage/install topology |
| `BACKUP.md` | current | Restic backup and restore contract |
| `SECRETS.md` | current | secret ownership and sops-nix usage |
| `MCP.md` | current | shared MCP registry and runtime behavior |
| `SKILLS.md` | current | canonical active skill tree and skill lifecycle |
| `HERMES.md` | current | Hermes scheduling and recurring research contract |
| `HERMES-ADHOC-RESEARCH.md` | current | ad-hoc Hermes research workflow |
| `HERMES-RESEARCH-LINKS.md` | current | Hermes source/link discovery contract |
| `SETTINGS.md` | partial | Settings information architecture, cross-page UX and runtime-to-declarative control model |
| `NETWORK-SETTINGS.md` | current | Vesper network settings behavior |
| `ADAPTIVE-ICONS.md` | current | Vesper integration boundary for the sibling Liquid Glass application-icon project |
| `AI.md` | partial | AI control-plane product boundary, credentials, agents and orchestration |
| `AI-ANALYTICS.md` | spec | analytics normalization and measurement semantics |
| `APPS-SETTINGS.md` | partial | installed-app settings contract and Store handoff |
| `../../vesper-store/docs/MARKETPLACE.md` | external | sibling Vesper Store architecture and transaction model |
| `DESKTOP-ERGONOMICS.md` | plan | high-frequency desktop interaction and ergonomics implementation plan |

## canonical boundaries

### Settings

`SETTINGS.md` is the only repository-wide Settings architecture document.

It owns:

- Settings navigation/information architecture
- cross-page UX rules
- System/NixOS, Display, Power, System Health, Input, Shortcuts, Services and global Settings search target surfaces
- the runtime -> declarative persistence workflow
- placement of Recovery, Network/Privacy, AI, Automation, Apps, Wellbeing and Appearance capabilities inside Settings

It does **not** replace the underlying subsystem contracts.

For example:

- backup/restore behavior stays in `BACKUP.md`
- Hermes scheduling stays in `HERMES.md`
- AI capability semantics stay in `AI.md`
- analytics semantics stay in `AI-ANALYTICS.md`
- installed-app behavior stays in `APPS-SETTINGS.md`
- network runtime behavior stays in `NETWORK-SETTINGS.md`
- optional Liquid Glass integration stays in `ADAPTIVE-ICONS.md`

Do not create separate `DISPLAY.md`, `POWER.md`, `RECOVERY-CENTER.md`, `SHORTCUTS.md`, `PRIVACY-SETTINGS.md`, `AUTOMATION-SETTINGS.md` or similar Settings feature docs unless their subsystem becomes independently complex enough to need a non-UI operational contract.

### Liquid Glass icons

`ADAPTIVE-ICONS.md` is the only Vesper integration contract for the sibling
Liquid Glass icon project.

Do not reintroduce icon conversion, rendering, queue or provider rules into
Vesper. Those belong to the sibling project's canonical documents.

### Vesper Store

`../../vesper-store/docs/MARKETPLACE.md` is the only Vesper Store architecture document.

Do not restore Store implementation or architecture documents inside Vesper.

The document is a target specification. Current code must be inspected before claiming a Store capability is implemented.

### AI

`AI.md` owns the AI control-plane product boundary.

Do not make any orchestration backend a core product dependency. CCCC is optional and replaceable behind Vesper's backend-neutral Agent Teams/orchestration boundary.

`AI-ANALYTICS.md` owns analytics source normalization and measurement semantics. Do not create parallel quota, token, cost, active-time or vibe-coding definitions elsewhere.

`SETTINGS.md` may define where AI controls appear and how they interact with the wider Settings control plane, but it must not redefine provider, permission or analytics truth.

### apps

`APPS-SETTINGS.md` owns installed-application settings behavior.
`../../vesper-store/docs/MARKETPLACE.md` owns discovery and installation.

Do not build a second installed-app management surface inside Vesper Store.

### desktop ergonomics

`DESKTOP-ERGONOMICS.md` owns the planned high-frequency interaction layer built on the existing Hyprland + Caelestia desktop.

Its status is `plan`. It may reference existing implementation primitives but must not be treated as proof that the planned interaction is active.

### visual shell

The consumer-agnostic Liquid Glass contract lives in the sibling project
`../../liquid-glass/docs/LIQUID-GLASS.md`.

Vesper owns only its enforced Settings controls and runtime/declarative mapping.
Current Caelestia and Hyprland behavior remains the source of truth for the
shell; the sibling contract does not authorize automatic visual changes.

## active remediation ledger

This is the repository-wide ledger for confirmed cross-subsystem reliability and architecture issues. It is not a second architecture document. Each item points to the canonical contract that owns the final behavior.

Priority vocabulary:

- `P0` — root architecture/state/lifecycle error that can make current behavior false or block reliable implementation
- `P1` — correctness, security, identity, reliability or maintainability defect that should be fixed before expanding the affected subsystem
- `P2` — bounded cleanup or dependency-hygiene issue with lower immediate operational risk

Class vocabulary:

- `state ownership` — two layers can claim or mutate the same state without one authority
- `lifecycle` — process/session/service ownership is split or not bound to the correct target
- `semantic drift` — implemented behavior does not match the declared protocol/model
- `source drift` — reviewed source differs from the source actually built or shipped
- `identity` — application/package/runtime identity can be attributed incorrectly
- `security boundary` — capability or trust scope is wider than intended
- `observability` — UI/doctor status can report inferred or stale state as authoritative
- `documentation drift` — high-authority documentation can steer implementation away from current code
- `dependency hygiene` — dependency/update/reproducibility boundaries are unnecessarily opaque or broad

An item stays open until the implementation is changed, the verification condition passes and the owning document describes the resulting current behavior.

| priority | class | root cause / issue | required fix | verification | canonical owner |
|---|---|---|---|---|---|
| P0 | state ownership | Caelestia runtime settings write `~/.config/caelestia/shell.json`; Vesper now seeds that path instead of keeping a live Home Manager file owner, but activation and restart persistence still need a live proof | keep the runtime-owned Caelestia config writable and use the declarative seed only for first-run defaults | change a native Caelestia setting, restart the shell/session and confirm the value persists without Home Manager/store write failures; a later HM activation must not silently erase runtime-owned state | `SETTINGS.md` + current Caelestia integration |
| P0 | lifecycle | the repository now defines an explicit `hyprland-session.target` bridge and binds Caelestia/Vesper daemons to `graphical-session.target`, but the activated generation has not yet proven the target and service graph | activate the Home Manager generation, start the target from Hyprland and remove all direct long-lived process spawns from compositor startup | login must activate the intended graphical session target; Vicinae, Caelestia, portals and migrated desktop daemons must start, stop and restart with the session | `SETTINGS.md`, `DESKTOP-ERGONOMICS.md`, current Hyprland and Home Manager config |
| P0 | source drift | `vesper-control` is compiled directly from tracked Rust source and its Nix activation/build proof remains pending | keep its direct Rust test and package build pointed at the same source | Nix package build and Home Manager activation use the tested source | `SETTINGS.md`, `NETWORK-SETTINGS.md` |
| P1 | state ownership | Wellbeing now uses the exact active Hyprland runtime class plus a `.desktop` stem fallback; it no longer depends on an icon-engine identity inventory, and a local fixture rejects similarly named app merging | keep this bounded fallback and never turn display-name matching into attribution | fixture and live desktop checks show unrelated similar app names do not merge | `APPS-SETTINGS.md` |
| P1 | identity | Apps previously inferred Flatpak ownership from a matching desktop/application ID | backend now resolves the winning desktop entry, `X-Flatpak`/export evidence and exact `flatpak info --user/--system` scope before exposing owner, permissions or removal; a local collision/tombstone fixture proves resolver precedence, while external Store ownership and live collision proof remain pending | native and Flatpak copies with overlapping IDs must be attributed to the winning source; permissions/remove/size controls must follow that owner only; live collision proof remains pending | `APPS-SETTINGS.md`, `../../vesper-store/docs/MARKETPLACE.md` |
| P1 | observability | `vesper-doctor` exposes bounded desktop/session keys for the graphical target, portals, Vicinae, Caelestia config writability and Vesper clipboard services; a source fixture proves they skip explicitly outside a graphical session, while live activated-session proof remains pending | keep checks ownership-specific and skip them explicitly outside a graphical session | `vesper-doctor --json` must expose stable keys and return warnings when each invariant is intentionally broken in a fixture/manual test | `SETTINGS.md` + `vesper-doctor` implementation |
| P1 | security boundary | Agent Cockpit persists only the process identity from `ps comm` in a private `0700` state directory with private `0600` snapshots; the source fixture rejects token-like argv persistence, while activated-generation proof is still pending | keep process snapshots bounded and diagnostic; never persist raw argv or prompt/token-like arguments | fixture with token/prompt-like argv must not place the sensitive value in durable agent snapshots | `AI.md`, `../AGENTS.md` |
| P1 | observability | Privacy HUD reads the two `vesper-cliphist-*` user services instead of inferring clipboard-history health from Caelestia/Quickshell; a local fixture verifies partial watcher state, while activated-session proof remains pending | keep clipboard history tied to the ownership-specific watcher/service state | killing both watchers while leaving Caelestia alive must make clipboard-history state unhealthy/offline | `../AGENTS.md` privacy contract |
| P1 | observability | Privacy HUD shares a private bounded 10-second runtime snapshot across QML and AI callers; a local ownership fixture verifies service-owned Tor and PipeWire microphone signals, while wellbeing remains one long-lived five-second sampler with a 30-second UI summary read | keep expensive privacy probes cached or event-driven and keep wellbeing sampling owned by its daemon rather than the UI | repeated UI refreshes must not spawn full Git/process/device probe sets at the same rate when source state has not changed | `AI.md`, `APPS-SETTINGS.md`, `../AGENTS.md` |
| P1 | security boundary | Nix daemon trusted users are now limited to `root`; the configured substituter/key does not require wheel-wide trust, but the activated-user workflow still needs a Nix-capable host proof | keep trusted users at the minimum required principals and retain the existing cache configuration | normal `nh`/flake/cache workflows must still function after removing unnecessary wheel-wide trust | current Nix module + `../AGENTS.md` Nix contract |
| P1 | security boundary | Zapret2 now limits the NFQUEUE path to the verified physical `wlan0` and `enp2s0` interfaces; activated nftables proof is still pending | keep VPN, tunnel, loopback, container and Wi-Fi P2P interfaces outside the desync path | nftables/Zapret rules must show only the declared physical interfaces entering the desync path; VPN/tunnel control traffic must remain outside unless explicitly desired | `NETWORK-SETTINGS.md` + current privacy module |
| P1 | dependency hygiene | browser/context MCPs launched with `bunx` are exact-versioned but still fetched from the package registry at runtime rather than from the Nix build graph | package high-value MCP runtimes through Nix where practical or explicitly document/cache-pin the mutable runtime boundary | offline/session-start test must distinguish packaged MCPs from intentionally network-dependent runtimes; authenticated-browser MCP availability must not depend on an undocumented first-run download | `MCP.md`, `AI.md` |
| P1 | security boundary | one shared MCP registry is automatically exposed to multiple agent runtimes while per-agent capability enforcement is not implemented | keep inventory separate from authorization and introduce enforceable per-agent MCP capability policy before exposing allow/deny controls | denied agent fixture must be technically unable to invoke the restricted MCP, not merely show a disabled label | `AI.md`, `MCP.md` |
| P1 | state ownership | wellbeing now gates each sample on explicit logind `IdleHint=no` and `LockedHint=no`; live lock/idle proof is still pending | keep accounting on the session owner and skip samples when the state is idle, locked or unknown; keep foreground sampling explicitly approximate | lock/idle interval must not increase app usage totals | `APPS-SETTINGS.md` |
| P1 | observability | Privacy HUD uses a running PipeWire `Stream/Input/Audio` node for microphone attention and `tor.service` for system Tor; a local fixture proves that a non-system `tor` process cannot set Tor state, while live capture/browser-isolation proof remains pending | keep microphone attention tied to real capture and system-Tor state tied to the system-owned unit | an unmuted unused microphone must remain inactive; active capture must be detected; Tor Browser alone must not make the system-Tor indicator active | `../AGENTS.md` privacy contract |
| P1 | state ownership | proxy configuration now derives status from the effective private `environment.d` file, writes it atomically and has local failure/permission proof; activated user-session handoff is still pending | keep effective-file status authoritative and remove legacy bookkeeping coherently | injected write failure must leave status unconfigured and must not expose secret-bearing files broadly | `NETWORK-SETTINGS.md` |
| P1 | semantic drift | airplane mode now snapshots Wi-Fi/WWAN and optional Bluetooth state in the user runtime directory and restores it on exit; live hardware round-trip proof is still pending | keep the state runtime-only, report radio failures and restore the exact captured state | round-trip test with mixed Wi-Fi/WWAN/Bluetooth initial states must restore the exact prior state | `NETWORK-SETTINGS.md` |
| P1 | observability | `vesper-doctor` tests the configured Restic file's existence without reading its root-only contents; a source fixture uses an unreadable file, while activated-generation proof remains pending | keep configuration health on existence/metadata or another privileged service-visible condition, and keep repository checks privileged | correct `0600 root:root` configuration must report configured without exposing contents | `BACKUP.md` |
| P2 | dependency hygiene | `llm-agents` packages are consumed from their own nixpkgs graph even though upstream exposes a shared-nixpkgs overlay | evaluate moving to the upstream shared-nixpkgs overlay so agent packages build against Vesper's pinned package universe, unless upstream compatibility requires isolation | closure/eval comparison must show no regression and one intentional nixpkgs authority for integrated packages | `AI.md` + current flake |
| P2 | dependency hygiene | the normal update alias advances many fast-moving inputs together, including heavily patched Caelestia/Quickshell and AI/browser packages | split update workflows by input family or require grouped compatibility verification for broad updates | update procedure must support advancing shell, AI and application inputs independently and still run the relevant build checks | current flake + maintenance docs |
| P2 | state ownership | GNOME Keyring + greetd PAM enablement is now owned by `modules/core/security.nix`; the duplicate desktop declaration has been removed, but the post-change Nix evaluation is still pending | keep the configuration in the core security module and do not reintroduce desktop-module copies | Nix evaluation stays unchanged after deduplication and only one module owns the policy | current security/desktop modules |

### remediation order

Use this order unless a smaller prerequisite is required:

1. Caelestia writable-state ownership
2. Hyprland/systemd graphical-session lifecycle
3. first-party source/build convergence
4. Apps package/source ownership attribution
5. doctor and HUD truthfulness
6. security-boundary narrowing for Nix, Zapret2 and shared MCP capability exposure
7. dependency/build-boundary cleanup
8. lower-risk module cleanup

Do not mark an item closed because prose was updated. The implementation change and verification must land first.

## agent documentation rules

Before changing a subsystem:

1. inspect current code
2. read `../AGENTS.md`
3. read this index
4. read the authoritative subsystem document
5. distinguish current behavior from target behavior
6. make the smallest coherent change
7. update the document status or current-state section when implementation materially changes

Do not infer implementation from examples, diagrams, desired UI copy or future-tense requirements.
Do not resurrect removed features from stale prose.
Do not duplicate facts across many docs when a link to the canonical contract is enough.
