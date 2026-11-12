# Design

## The pieces

| Piece | Kind | What it does |
|---|---|---|
| `homeModules.default` | Home Manager module | Declares the `programs.goxlr.*` options: volumes, faders, routing, mic, submix, effects, sampler, lighting, settings. `homeModules.goxlr` is the same module under a second name. |
| `goxlr-apply.service` | systemd user unit | Waits for `goxlr-daemon`, then applies the declared mixer state through `goxlr-client` on login |
| [`export-config.sh`](../export-config.sh) | shell script | Reads `goxlr-client --status-json` and emits a `programs.goxlr` Nix attribute set, ready to paste |

## What this module leaves to nixpkgs

nixpkgs' `services.goxlr-utility` NixOS module registers the GoXLR Utility's
udev rules and, with `autoStart.xdg` on, installs the package and an XDG
autostart entry that starts `goxlr-daemon`. This module handles the mixer
state a user sees and nothing else.

## How the state is applied

Nix turns every declared value into one `goxlr-client` command and writes the
commands into a script. The script takes `goxlr-client` from nixpkgs'
`goxlr-utility` package.

The script first asks `goxlr-client --status-json` once a second, up to thirty
times. With `device` set it also waits until that serial is among the
connected mixers. If neither happens it stops with
`GoXLR not ready after 30s, nothing applied`.

The commands then run in a fixed order. The profiles load first. After them
come volumes, faders, scribbles, routing, microphone, submix, effects, sampler,
the cough and bleep buttons, device settings and lighting. `extraCommands` run
last.

A route that is refused is reported and counted, and the run carries on. At
the end the script exits with status 2 if any route was refused.

The unit is a oneshot service that starts with the graphical session. The
daemon starts through XDG autostart, with no guaranteed order relative to this
service, so systemd runs the service again ten seconds after a failure. Status
2 is the exception: a refused route is not retried.

No service is created while nothing is declared. `enable` alone is not enough:
the unit exists once there is at least one command or one power action.

## Values that are only sent together

- A fader colour, in `lighting.faders` or `lighting.fadersAll`, is sent only
  when both `top` and `bottom` are set.
- An encoder colour is sent only when `colour1`, `colour2` and `colour3` are
  all set.
- `lighting.animation.mod1`, `mod2` and `waterfall` are sent only when `mode`
  is set to something other than `none`.

## Value names

All string values must be the exact lowercase-hyphenated CLI values accepted
by `goxlr-client`. The sampler is the exception: its bank, button, playback
mode and playback order names are PascalCase (`SamplerA`, `TopLeft`,
`PlayNext`, `Sequential`), and the module converts them. A sampler name the
module does not know fails the evaluation.

## Why profiles are files

GoXLR stores profiles as binary files. A device profile is a `.goxlr` ZIP
archive and a microphone profile is a `.goxlrMicProfile` XML file. These are
not expressible as Nix attribute sets, so they are deployed with `home.file`
and the `profile` and `micProfile` options only load one by name.

## Power actions

`powerActions.shutdown`, `powerActions.sleep` and `powerActions.wake` name a
device profile, a microphone profile or a profile whose colours to load. They
are not sent through `goxlr-client`. The apply script rewrites the daemon's
own `~/.config/goxlr-utility/settings.json` with `jq` instead.

It writes the shutdown, sleep and wake command lists of the mixer named by
`device`, or of the first mixer in the file when `device` is unset. Once any
power action is declared all three lists are replaced, so an action with
nothing declared becomes an empty list. If the settings file does not exist
yet, nothing is written.
