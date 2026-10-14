---
name: vesper-adaptive-icons
description: Integrate Vesper Settings with the sibling Liquid Glass application-icon tool without recreating its engine.
---

# Liquid Glass icon integration

Use this skill when working on Vesper's optional Liquid Glass icon integration.

Read `docs/ADAPTIVE-ICONS.md` first. The sibling project at `../../liquid-glass/` owns discovery, conversion, provider selection, cache state, rendering, hicolor output and restore.

## Vesper boundary

- invoke only `vesper-control liquid-glass status|apply|restore ... --json`
- use exact desktop IDs returned by the sibling `discover` command
- `apply` must use a current local cache and must never create an AI request
- `restore` is reversible and must leave user-modified desktop entries untouched
- let GTK and Vicinae use normal `Papirus`/`auto` resolution with hicolor overrides
- do not add a service, generated icon theme, queue, identity database or provider controls to Vesper

Use the sibling GUI or its explicit `convert --desktop-id …` command for conversion work. Verify with the sibling's Rust tests and, after the sibling is pinned, a live hicolor resolution test.
