# goxlr-hm-nix

A Home Manager module that keeps the state of a GoXLR or GoXLR Mini mixer in
your Nix configuration. You declare volumes, fader assignments, routing,
microphone settings, effects and lighting, and a user service applies them
through `goxlr-client` when you log in. It is for someone who already runs the
GoXLR Utility and wants the mixer to come up as declared.

Both the GoXLR and the GoXLR Mini are supported. The repository's own check
only evaluates the module. No check here runs against a real mixer.

## Install

The module does not start the GoXLR Utility. nixpkgs' `services.goxlr-utility`
NixOS module does: it registers the udev rules and, with `autoStart.xdg` on,
installs the package and an autostart entry that starts `goxlr-daemon`.

Add the flake:

```nix
{
  inputs.goxlr-hm = {
    url = "github:Daaboulex/goxlr-hm-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

Switch the daemon on and import the module into Home Manager:

```nix
{
  services.goxlr-utility.enable = true;
  home-manager.sharedModules = [ inputs.goxlr-hm.homeModules.default ];
}
```

Then declare the mixer in your Home Manager configuration:

```nix
{
  programs.goxlr = {
    enable = true;
    volumes = {
      mic = 100;
      headphones = 100;
    };
  };
}
```

A user service, `goxlr-apply`, applies this when the graphical session starts.
With `enable` alone and nothing else declared, no service is created.

## Options to set first

| Option under `programs.goxlr` | What it is for |
|---|---|
| `profile`, `micProfile` | Load a device profile and a microphone profile by name |
| `volumes` | Channel volumes, 0 to 100 percent |
| `faders` | The channel each fader, `a` to `d`, controls |
| `routing` | Which input is sent to which output |
| `microphone` | Gain, noise gate, compressor and equaliser |
| `lighting` | Colours of the faders and buttons, and the animation |
| `device` | Serial number of the mixer, needed when more than one GoXLR is connected |
| `extraCommands` | Raw `goxlr-client` commands, run after everything else |

String values are the exact lowercase, hyphenated values `goxlr-client`
accepts, such as `to-stream`. The sampler is the exception: its bank,
button, playback mode and playback order names are PascalCase (`SamplerA`,
`TopLeft`, `PlayNext`, `Sequential`), and the module converts them.

Every option, with its type and description: [docs/OPTIONS.md](docs/OPTIONS.md).

## Profiles

The GoXLR Utility keeps profiles as files: a device profile is a `.goxlr` ZIP
archive, a microphone profile a `.goxlrMicProfile` XML file. They cannot be
written as Nix attribute sets, so deploy them with `home.file`:

```nix
home.file = {
  ".local/share/goxlr-utility/profiles/My Profile.goxlr".source =
    ./goxlr-profiles + "/My Profile.goxlr";
  ".local/share/goxlr-utility/mic-profiles/My Mic.goxlrMicProfile".source =
    ./goxlr-mic-profiles + "/My Mic.goxlrMicProfile";
};
```

`profile` and `micProfile` load a profile by name on login. The file must
already be on disk.

## Export what the mixer has now

From a clone of this repository, with the daemon running:

```bash
bash export-config.sh > my-goxlr-config.nix
```

This reads `goxlr-client --status-json` and prints Nix to paste into your
`programs.goxlr` block, with volumes as 0 to 100 and names in kebab-case. It
needs `goxlr-client` and `jq`. `--profile <name>` exports one device profile
and `--all-profiles` exports every profile.

## Known limits

- A GoXLR Mini has no effects panel, sampler, scribble screens or encoder
  lighting. `effects`, `sampler`, `scribbles` and `lighting.encoders` are for
  the full GoXLR.
- A Mini has its own equaliser option, `microphone.equaliserMini`. The full
  GoXLR uses `microphone.equaliser`.
- Volumes and `bleepVolume` are range-checked when the configuration is built.
  Most other values, such as a channel or style name, go to `goxlr-client` as
  written, so a misspelt one fails at login.
- `export-config.sh` does not write effects, the sampler, the scribble screens
  or the equaliser.

## When the mixer does not come up as declared

```bash
journalctl --user -u goxlr-apply
```

- `GoXLR not ready after 30s, nothing applied` means the daemon did not
  answer, or the mixer named by `device` is not connected. The service tries
  again every ten seconds.
- `route rejected` means one entry of `routing` was refused. The rest is still
  applied and the service does not try again.

## More

- [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md): what a Mini lacks, and a
  complete configuration for each device
- [docs/DESIGN.md](docs/DESIGN.md): how the state is applied, power actions
- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md): the dev shell, the checks, CI

## License

This module is [MIT](./LICENSE) licensed. The upstream GoXLR Utility (daemon + `goxlr-client`) is [MIT](https://github.com/GoXLR-on-Linux/goxlr-utility/blob/main/LICENSE).
