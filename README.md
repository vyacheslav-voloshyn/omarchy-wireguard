# Omarchy WireGuard

Bar widget for [Omarchy](https://omarchy.org) that shows whether a
NetworkManager WireGuard connection is up and toggles it with a click.

| Up | Down |
|---|---|
| ![Connection up](screenshots/up.png) | ![Connection down](screenshots/down.png) |

- Shield-lock icon, bright when the connection is up, dimmed when it is down,
  highlighted while it is coming up or going down.
- Tooltip shows the connection name and its state.
- State follows `nmcli monitor` events, so there is no polling.

## Requirements

A WireGuard connection managed by NetworkManager, for example one imported with:

```bash
nmcli connection import type wireguard file /path/to/wg0.conf
```

## Install

```bash
omarchy plugin add https://github.com/vyacheslav-voloshyn/omarchy-wireguard.git --enable
```

Review the source before enabling: plugins run unsandboxed inside
`omarchy-shell`. The plugin id is `amsi.wireguard`.

Point it at your connection (default `workpc`):

```bash
omarchy bar set amsi.wireguard connection <connection-name>
```

`allowMultiple` is on, so you can put one widget per tunnel on the bar.

Update with `omarchy plugin update amsi.wireguard`.

## Controls

| Action | Result |
|---|---|
| Left click | `nmcli connection up` / `down` for the configured connection |
| Right click | Opens `nmtui` in your terminal |

## What it runs

- `nmcli monitor`: one long-running process per widget, restarted if
  NetworkManager restarts.
- `nmcli -g GENERAL.STATE connection show <name>`: after each monitor event.
- `nmcli connection up|down id <name>`: on click.

No network access of its own, no files read or written.

## License

MIT
