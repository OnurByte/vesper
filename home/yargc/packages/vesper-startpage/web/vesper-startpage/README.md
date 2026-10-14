# vesper startpage

The shipped startpage is the standalone file at
`../../static/index.html`. It contains its CSS and JavaScript inline, so browsers
can open it with `file://` after a reboot without a loopback server or systemd
unit.

The page keeps shortcut clicks in localStorage, renders a small local click
graph, and links Tor sources directly for Tor Browser. It cannot read Zen or
Helium SQLite history from a static file page, and it does not pretend to.

The React frontend below is retained as the old development surface. Run its
checks from this directory when changing that source:

```bash
bun run selfcheck
bun run typecheck
bun run lint
bun run build
```

The Nix package installs the standalone HTML from `../../static/`.
Home Manager passes that same file to Helium with `--custom-ntp`, so the `+`
button opens Vesper instead of the built-in New Tab page.
