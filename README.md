# goxlr-hm-nix

<!-- BEGIN generated:badges -->
[![CI](https://github.com/Daaboulex/goxlr-hm-nix/actions/workflows/ci.yml/badge.svg)](https://github.com/Daaboulex/goxlr-hm-nix/actions/workflows/ci.yml)
[![NixOS unstable](https://img.shields.io/badge/NixOS-unstable-78C0E8?logo=nixos&logoColor=white)](https://nixos.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
<!-- END generated:badges -->

Home Manager module for declarative GoXLR / GoXLR Mini mixer configuration via `goxlr-client`.

<!-- BEGIN generated:upstream -->
## Upstream

| | |
|---|---|
| **Project** | Original code (no upstream) |
| **License** | N/A |
| **Tracked** | N/A |

<!-- END generated:upstream -->

## Components

| Component | Type | Description |
|---|---|---|
| `homeManagerModules.default` | HM module | Declarative `programs.goxlr.*` options (volumes, faders, routing, mic, submix, effects, sampler, lighting, settings) |
| `goxlr-apply.service` | systemd user unit | Waits for `goxlr-daemon`, then applies declared mixer state via `goxlr-client` on login |
| `export-config.sh` | shell script | Reads `goxlr-client --status-json` and emits a ready-to-paste `programs.goxlr` Nix attrset |

## What it does

Applies mixer state (volumes, fader assignments, routing, microphone settings, effects, sampler, submix, lighting, animation, device settings, profiles) at login via a systemd user service that waits for `goxlr-daemon`.

The NixOS-level GoXLR module handles daemon setup, udev, UCM patches, and PipeWire integration. This module handles the user-facing mixer state.

All string values must be the exact lowercase-hyphenated CLI values accepted by `goxlr-client`.

### GoXLR Mini vs Full

Both devices are fully supported. Mini-specific differences:

- **No effects panel** — reverb, echo, pitch, gender, megaphone, robot, hard tune are Full-only hardware
- **No sampler** — sample pads are Full-only hardware
- **No scribble screens** — fader OLED displays are Full-only hardware
- **No encoder lighting** — rotary encoder rings are Full-only hardware
- **6 buttons** — fader1-mute through fader4-mute, cough, bleep (Full has additional effect-select and effect-toggle buttons)
- **3-band mini EQ** — `microphone.equaliserMini` instead of Full's 10-band `microphone.equaliser`

### Profile management

GoXLR stores profiles as binary files (device profiles: `.goxlr` ZIP archives, mic profiles: `.goxlrMicProfile` XML). These are **not expressible as Nix attrsets** — deploy them with `home.file`:

```nix
home.file = {
  ".local/share/goxlr-utility/profiles/My Profile.goxlr".source =
    ./goxlr-profiles + "/My Profile.goxlr";
  ".local/share/goxlr-utility/mic-profiles/My Mic.goxlrMicProfile".source =
    ./goxlr-mic-profiles + "/My Mic.goxlrMicProfile";
};
```

The `profile` and `micProfile` options load a named profile on login — the profile files must already exist on disk.

<!-- BEGIN generated:installation -->
## Installation

Add as a flake input:

```nix
{
  inputs.goxlr-hm = {
    url = "github:Daaboulex/goxlr-hm-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

Import the Home Manager module:

```nix
home-manager.sharedModules = [ inputs.goxlr-hm.homeManagerModules.default ];
```

<!-- END generated:installation -->

## Usage

Add as a flake input:

```nix
inputs.goxlr-hm.url = "github:Daaboulex/goxlr-hm-nix";
```

Import in your Home Manager config:

```nix
# In your flake, add to Home Manager sharedModules:
home-manager.sharedModules = [
  inputs.goxlr-hm.homeManagerModules.default
];
```

### Example configuration (GoXLR Mini)

```nix
programs.goxlr = {
  enable = true;

  # Load profiles on login
  profile = "Yellow Default";
  micProfile = "Mic NeatKingBee";

  # Channel volumes (0-100 percent)
  volumes = {
    mic = 100; chat = 100; music = 59; game = 100;
    console = 50; system = 82; sample = 100;
    headphones = 100; mic-monitor = 0; line-out = 100;
  };

  # Fader assignments
  faders = { a = "game"; b = "chat"; c = "music"; d = "system"; };

  # Fader mute behaviour
  faderMuteBehaviour = { a = "all"; b = "all"; c = "all"; d = "all"; };

  # Audio routing matrix (input → output → enabled)
  routing = {
    microphone = {
      headphones = false; broadcast-mix = true;
      chat-mic = true; sampler = true;
      line-out = false; stream-mix2 = false;
    };
    chat = { headphones = true; line-out = true; };
    music = { headphones = true; broadcast-mix = true; line-out = true; };
    game = { headphones = true; line-out = true; };
    system = { headphones = true; line-out = true; };
  };

  # Microphone settings (condenser mic example)
  microphone = {
    condenserGain = 36;
    dynamicGain = 37;
    jackGain = 30;
    deEss = 0;
    gate = {
      active = true; threshold = -59;
      attenuation = 30; attack = "gate10ms"; release = "gate200ms";
    };
    compressor = {
      threshold = -18; ratio = "ratio3-2";
      attack = "comp3ms"; release = "comp230ms"; makeUp = 3;
    };
  };

  # Submix (independent monitor/stream volumes)
  submix = {
    enabled = true;
    volumes = { mic = 100; chat = 100; music = 100; game = 100; };
    linked = { mic = true; chat = true; game = true; };
    outputMix = { headphones = "a"; broadcast-mix = "b"; };
    monitorMix = "headphones";
  };

  # Cough/bleep buttons
  coughButton = { isHold = false; muteBehaviour = "all"; };
  bleepVolume = -7;

  # Device settings
  settings = {
    muteHoldDuration = 500;
    monitorWithFx = false;
    deafenOnChatMute = true;
    lockFaders = false;
  };

  # Lighting (yellow theme example)
  lighting = {
    animation = { mode = "none"; };
    faders = {
      a = { display = "two-colour"; top = "000000"; bottom = "FFF80C"; };
      b = { display = "two-colour"; top = "000000"; bottom = "FFF80C"; };
    };
    buttons = {
      fader1-mute = { colour = "FFF80C"; colour2 = "FF00C8"; offStyle = "dimmed"; };
      cough = { colour = "FFF80C"; colour2 = "00FFFF"; offStyle = "dimmed"; };
      bleep = { colour = "FFF80C"; colour2 = "00FFFF"; offStyle = "dimmed"; };
    };
    simple = { global = "003FFA"; accent = "FFF80C"; };
  };
};
```

### Example configuration (GoXLR Full additions)

```nix
programs.goxlr = {
  # ... all Mini options above, plus:

  # Scribble screens (Full-only OLED displays)
  scribbles = {
    a = { text = "Mic"; icon = "microphone"; invert = false; };
    b = { text = "Music"; number = "2"; };
  };

  # Effects panel (Full-only)
  effects = {
    enabled = true;
    activePreset = "preset1";
    reverb = { style = "library"; amount = 20; decay = 2000; };
    echo = { style = "quarter"; amount = 15; feedback = 30; };
    pitch = { style = "narrow"; amount = 0; };
    gender = { style = "narrow"; amount = 0; };
    megaphone = { style = "megaphone"; enabled = false; };
    robot = { style = "robot1"; enabled = false; };
    hardTune = { style = "natural"; enabled = false; };
  };

  # Sampler (Full-only)
  sampler.SamplerA.TopLeft = {
    files = [ "/path/to/sound.wav" ];
    playbackMode = "play-next";
    playbackOrder = "sequential";
  };

  # Encoder lighting (Full-only)
  lighting.encoders = {
    reverb = { colour1 = "00FFFF"; colour2 = "000000"; colour3 = "00FFFF"; };
    echo = { colour1 = "00FFFF"; colour2 = "000000"; colour3 = "00FFFF"; };
  };
};
```

## Options reference

| Option | Type | Description |
|--------|------|-------------|
| `enable` | bool | Enable declarative GoXLR configuration |
| `device` | string | Device serial (required for multi-device) |
| `profile` | string | Device profile to load on login |
| `micProfile` | string | Mic profile to load on login |
| **Channels** | | |
| `volumes` | attrs of int | Channel volumes (0-100 percent) |
| `faders` | attrs of string | Fader-to-channel assignments (a, b, c, d) |
| `faderMuteBehaviour` | attrs of string | Per-fader mute behaviour on press |
| `faderMuteState` | attrs of string | Per-fader mute state (unmuted, muted-to-x, muted-to-all) |
| `scribbles.<fader>.icon` | string | Scribble screen icon file name (Full-only) |
| `scribbles.<fader>.text` | string | Scribble screen text (Full-only) |
| `scribbles.<fader>.number` | string | Scribble screen number (Full-only) |
| `scribbles.<fader>.invert` | bool | Invert scribble display (Full-only) |
| `routing` | attrs of attrs of bool | Input-to-output routing matrix |
| `bleepVolume` | int | Bleep button volume (dB) |
| **Microphone** | | |
| `microphone.dynamicGain` | int | Dynamic (XLR) mic gain in dB |
| `microphone.condenserGain` | int | Condenser mic gain in dB |
| `microphone.jackGain` | int | Jack (3.5mm) mic gain in dB |
| `microphone.deEss` | int | De-esser level (0-100) |
| `microphone.monitorWithFx` | bool | Monitor mic when FX enabled |
| `microphone.gate.*` | various | Noise gate (threshold, attenuation, attack, release, active) |
| `microphone.compressor.*` | various | Compressor (threshold, ratio, attack, release, makeUp) |
| `microphone.equaliser.<band>` | submodule | Full GoXLR EQ (frequency, gain per band) |
| `microphone.equaliserMini.<band>` | submodule | GoXLR Mini EQ (frequency, gain per band) |
| **Submix** | | |
| `submix.enabled` | bool | Enable/disable submixes |
| `submix.volumes` | attrs of int | Submix channel volumes (0-100 percent) |
| `submix.linked` | attrs of bool | Link channel volumes to submix |
| `submix.outputMix` | attrs of string | Output device mix assignment (a or b) |
| `submix.monitorMix` | string | Output device to monitor |
| **Effects (Full-only)** | | |
| `effects.enabled` | bool | Enable/disable FX panel |
| `effects.activePreset` | string | Set active effect preset (preset1-6) |
| `effects.loadPreset` | string | Load effect preset by name |
| `effects.renameActivePreset` | string | Rename the active effect preset |
| `effects.saveActivePreset` | bool | Save the active effect preset after changes |
| `effects.reverb.*` | various | Reverb (style, amount, decay, earlyLevel, tailLevel, preDelay, lowColour, highColour, highFactor, diffuse, modSpeed, modDepth) |
| `effects.echo.*` | various | Echo (style, amount, feedback, tempo, delayLeft, delayRight, feedbackXFBLtoR, feedbackXFBRtoL) |
| `effects.pitch.*` | various | Pitch (style, amount, character) |
| `effects.gender.*` | various | Gender (style, amount) |
| `effects.megaphone.*` | various | Megaphone (style, amount, postGain, enabled) |
| `effects.robot.*` | various | Robot (style, ranges.{low,medium,high}.{gain,frequency,bandwidth}, waveform, pulseWidth, threshold, dryMix, enabled) |
| `effects.hardTune.*` | various | HardTune (style, amount, rate, window, source, enabled) |
| **Sampler (Full-only)** | | |
| `sampler.<bank>.<button>.files` | list of string | Audio files to add |
| `sampler.<bank>.<button>.playbackMode` | string | Playback mode |
| `sampler.<bank>.<button>.playbackOrder` | string | Playback order |
| `sampler.<bank>.<button>.sampleSettings` | list of submodule | Per-sample start/stop percent by index |
| `sampler.<bank>.<button>.removeByIndex` | list of int | Sample indices to remove |
| **Cough button** | | |
| `coughButton.isHold` | bool | Hold-only mode (not toggled) |
| `coughButton.muteBehaviour` | string | Mute target on press |
| `coughButton.muteState` | string | Mute state (unmuted, muted-to-x, muted-to-all) |
| **Device settings** | | |
| `settings.muteHoldDuration` | int | Mute hold duration (ms) |
| `settings.samplePreRecordBuffer` | int | Sampler pre-record buffer (ms, Full-only) |
| `settings.monitorWithFx` | bool | Monitor mic when FX enabled |
| `settings.deafenOnChatMute` | bool | Mute mic when chat muted |
| `settings.lockFaders` | bool | Lock faders on mute-to-all |
| **Lighting** | | |
| `lighting.global` | string | Global colour [RRGGBB] |
| `lighting.animation.*` | various | Animation (mode, mod1, mod2, waterfall) |
| `lighting.fadersAll.*` | various | All-fader lighting (display, top, bottom) |
| `lighting.faders.<fader>.*` | various | Per-fader lighting (top, bottom, display) |
| `lighting.buttons.<button>.*` | various | Per-button lighting (colour, colour2, offStyle) |
| `lighting.buttonGroups.<group>.*` | various | Button group lighting (colour, colour2, offStyle) |
| `lighting.simple` | attrs of string | Simple colour targets (global, accent) |
| `lighting.encoders.<encoder>.*` | various | Encoder lighting (colour1, colour2, colour3, Full-only) |
| **Escape hatch** | | |
| `extraCommands` | list of string | Raw goxlr-client commands |

All options under `programs.goxlr` are prefixed accordingly (e.g., `programs.goxlr.effects.reverb.style`).

## Exporting current settings

To generate Nix config from your current GoXLR state:

```bash
bash export-config.sh > my-goxlr-config.nix
```

This reads `goxlr-client --status-json`, converts all values to the correct format (volumes 0-100, kebab-case names), and outputs valid Nix ready to paste into your `programs.goxlr` block. Detects GoXLR Mini vs Full automatically and omits unavailable features. Requires `goxlr-client` and `jq`.

## Development

```bash
git clone https://github.com/Daaboulex/goxlr-hm-nix
cd goxlr-hm-nix
nix develop                       # enter dev shell, installs pre-commit hooks
nix fmt                           # format flake + module
nix flake check --no-build        # eval check (canonical CI gate, module-only repo)
```

CI runs eval + format on every push; weekly maintenance updates `flake.lock`. No upstream-tracking workflow — this is original code.

<!-- BEGIN generated:options -->
<!-- END generated:options -->

## License

This module is [MIT](./LICENSE) licensed. The upstream GoXLR Utility (daemon + `goxlr-client`) is [MIT](https://github.com/GoXLR-on-Linux/goxlr-utility/blob/main/LICENSE).

<!-- BEGIN generated:footer -->
---

*Maintained as part of the [Daaboulex](https://github.com/Daaboulex) NixOS ecosystem.*
<!-- END generated:footer -->
