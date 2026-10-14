# Liquid Glass application icons

Status: current integration contract. The conversion engine is not part of
Vesper.

## ownership

`../../liquid-glass/` is the consumer-agnostic sibling project and owns all
application icon discovery, source parsing, AI conversion, SVG validation,
cache state, GPU rendering, hicolor output, user desktop overrides and restore
behaviour. Its authoritative documents are:

- `../../liquid-glass/docs/LIQUID-GLASS.md` for visual and renderer rules
- `../../liquid-glass/docs/API.md` for the versioned JSON CLI
- `../../liquid-glass/docs/AI-PIPELINE.md` for remote-provider boundaries

Vesper owns only the Settings integration. It must not reintroduce an icon
worker, a durable conversion queue, a generated icon theme, a `.vicon` format,
an identity inventory, AI provider settings or a renderer.

## installed application contract

Liquid Glass uses normal freedesktop mechanisms below the user data root:

```text
$XDG_DATA_HOME/liquid-glass-icon/out/         canonical SVG cache
$XDG_DATA_HOME/liquid-glass-icon/managed-icons.json
$XDG_DATA_HOME/icons/hicolor/<size>/apps/     rendered PNGs
$XDG_DATA_HOME/applications/<desktop-id>      reversible user override
```

The original package desktop entry is never edited. `restore` removes only a
managed override and refuses to overwrite a later user change. Vesper must not
delete old `~/.local/share/vesper/adaptive-icons/` data or user desktop entries
as part of migration.

The configured GTK and Vicinae icon theme stays normal `Papirus`/`auto` and
inherits `hicolor`. No `Vesper-Adaptive` theme is generated or selected.

## Vesper control surface

`vesper-control liquid-glass <command...>` is a thin process handoff to the
sibling `liquid-glass-icon` executable. It has no fallback implementation.
The sibling package is optional and must already be available on the user
profile `PATH`; an unavailable executable remains an explicit Settings error.

Vesper uses only these commands:

```text
liquid-glass-icon status [--desktop-id ID]... --json
liquid-glass-icon apply (--desktop-id ID... | --managed) --appearance NAME --json
liquid-glass-icon restore --desktop-id ID... --json
```

The Appearance page may open `liquid-glass-icon-gui` and apply managed current
caches. The Apps inspector may inspect status, apply one current cache, and
restore one managed override. Conversion happens only in the sibling GUI or
its explicit `convert --desktop-id …` CLI command. Vesper startup, Caelestia
theme changes and UI polling must never cause an AI request.

## migration and verification

Migration is source-only until the sibling release is pinned into the Vesper
flake and a Nix-capable host evaluates it. Do not fabricate a lock-file entry
for an unpublished or dirty sibling checkout.

Acceptance requires:

1. Vesper has no `vesper-icon-*` binary, Cargo crate, service, generated theme
   or Caelestia identity patch.
2. Settings sends the documented JSON CLI commands and handles an unavailable
   sibling explicitly.
3. A current cache can be applied without a provider request.
4. Restore preserves a changed user desktop override by refusing to overwrite
   it.
5. A Nix evaluation/build and a live GTK, Vicinae and Caelestia session prove
   hicolor resolution after the sibling is pinned.
