# goxlr-hm-nix

Home Manager module for declarative GoXLR mixer configuration via `goxlr-client`.

## What it does

Applies mixer state (volumes, fader assignments, routing, microphone settings, effects, sampler, submix, lighting, animation, device settings, profiles) at login via a systemd user service that waits for `goxlr-daemon`.

The NixOS-level GoXLR module handles daemon setup, udev, UCM patches, and PipeWire integration. This module handles the user-facing mixer state.

All string values must be the exact lowercase-hyphenated CLI values accepted by `goxlr-client`.

## Usage

Add as a flake input:

```nix
inputs.goxlr-hm.url = "github:Daaboulex/goxlr-hm-nix";
```

Import in your Home Manager config:

```nix
imports = [ inputs.goxlr-hm.homeManagerModules.default ];

programs.goxlr = {
  enable = true;

  # Load a profile on login
  profile = "Default";
  micProfile = "Default";

  # Channel volumes (0-100 percent, CLI converts to 0-255 internally)
  volumes = {
    mic = 100;
    chat = 80;
    music = 60;
    game = 75;
    system = 70;
    headphones = 85;
  };

  # Fader assignments
  faders = {
    a = "mic";
    b = "music";
    c = "chat";
    d = "system";
  };

  # Fader mute behaviour (per-fader)
  faderMuteBehaviour = {
    a = "all";
    b = "to-stream";
  };

  # Fader mute state (per-fader)
  faderMuteState = {
    a = "unmuted";
    c = "muted-to-all";
  };

  # Scribble screens (full GoXLR only)
  scribbles = {
    a = { text = "Mic"; icon = "microphone"; invert = false; };
    b = { text = "Music"; number = "2"; };
  };

  # Audio routing matrix
  routing = {
    microphone = {
      headphones = true;
      chat-mic = true;
      broadcast-mix = true;
    };
  };

  # Microphone settings
  microphone = {
    dynamicGain = 55;
    monitorWithFx = true;
    gate = {
      threshold = -35;
      attenuation = 100;
      active = true;
    };
    compressor = {
      threshold = -20;
      ratio = "ratio3-0";
      makeUp = 6;
    };
    deEss = 0;
    # Full GoXLR equaliser
    equaliser = {
      equalizer250-hz = { gain = 3; };
      equalizer1-k-hz = { gain = -2; frequency = 1000.0; };
    };
  };

  # Submix settings
  submix = {
    enabled = true;
    volumes = { mic = 255; chat = 200; };
    linked = { mic = true; };
    outputMix = { headphones = "a"; };
    monitorMix = "headphones";
  };

  # Effects panel
  effects = {
    enabled = true;
    activePreset = "preset1";
    renameActivePreset = "My Preset";
    saveActivePreset = true;
    reverb = {
      style = "library";
      amount = 20;
      decay = 2000;
    };
    echo = {
      style = "quarter";
      amount = 15;
      feedback = 30;
    };
    pitch = { style = "narrow"; amount = 0; };
    gender = { style = "narrow"; amount = 0; };
    megaphone = { style = "megaphone"; enabled = false; };
    robot = {
      style = "robot1";
      ranges = {
        low = { gain = 5; frequency = 40; bandwidth = 20; };
      };
      enabled = false;
    };
    hardTune = { style = "natural"; enabled = false; };
  };

  # Sampler (PascalCase keys are auto-converted to lowercase-hyphenated for goxlr-client)
  sampler = {
    SamplerA = {
      TopLeft = {
        files = [ "/path/to/sound.wav" ];
        playbackMode = "play-next";
        playbackOrder = "sequential";
        sampleSettings = [
          { startPercent = 10.0; stopPercent = 90.0; }
        ];
      };
      BottomRight = {
        files = [ "/path/to/other.wav" ];
        playbackMode = "loop";
        removeByIndex = [ 0 ];  # Remove sample at index 0
      };
    };
  };

  # Device settings
  settings = {
    muteHoldDuration = 500;
    lockFaders = false;
    deafenOnChatMute = false;
    monitorWithFx = true;
  };

  # Lighting
  lighting = {
    global = "00FFFF";
    animation = {
      mode = "rainbow-bright";
      mod1 = 50;
      mod2 = 50;
      waterfall = "down";
    };
    fadersAll = { display = "two-colour"; top = "00FFFF"; bottom = "000000"; };
    faders = {
      a = { top = "00FFFF"; bottom = "000000"; display = "two-colour"; };
      b = { top = "FF00FF"; bottom = "000000"; display = "two-colour"; };
    };
    buttonGroups = {
      fader-mute = { colour = "FF0000"; offStyle = "dimmed"; };
    };
  };

  # Cough button
  coughButton = {
    isHold = true;
    muteBehaviour = "to-stream";
    muteState = "unmuted";
  };

  # Raw commands for anything not covered by options
  extraCommands = [ ];
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
| `scribbles.<fader>.icon` | string | Scribble screen icon file name |
| `scribbles.<fader>.text` | string | Scribble screen text |
| `scribbles.<fader>.number` | string | Scribble screen number (top-left) |
| `scribbles.<fader>.invert` | bool | Invert scribble display |
| `routing` | attrs of attrs of bool | Input-to-output routing matrix |
| `bleepVolume` | int | Bleep button volume (0-100) |
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
| **Effects** | | |
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
| **Sampler** | | |
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
| `settings.samplePreRecordBuffer` | int | Sampler pre-record buffer (ms) |
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
| `lighting.simple` | attrs of string | Simple colour targets |
| `lighting.encoders.<encoder>.*` | various | Encoder lighting (colour1, colour2, colour3) |
| **Escape hatch** | | |
| `extraCommands` | list of string | Raw goxlr-client commands |

All options under `programs.goxlr` are prefixed accordingly (e.g., `programs.goxlr.effects.reverb.style`).

All string values for channel names, fader names, styles, modes, and behaviours must be the exact lowercase-hyphenated values accepted by `goxlr-client`.

## Exporting current settings

To generate Nix config from your current GoXLR state:

```bash
bash export-config.sh > my-goxlr-config.nix
```

This reads `goxlr-client --status-json`, converts all values to the correct format (volumes 0-100, kebab-case names), and outputs valid Nix ready to paste into your `programs.goxlr` block. Requires `goxlr-client` and `jq`.

## License

MIT
