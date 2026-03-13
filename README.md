# goxlr-hm-nix

Home Manager module for declarative GoXLR mixer configuration via `goxlr-client`.

## What it does

Applies mixer state (volumes, fader assignments, routing, microphone settings, effects, sampler, submix, lighting, animation, device settings, profiles) at login via a systemd user service that waits for `goxlr-daemon`.

The NixOS-level GoXLR module handles daemon setup, udev, UCM patches, and PipeWire integration. This module handles the user-facing mixer state.

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

  # Channel volumes (0-100)
  volumes = {
    Mic = 100;
    Chat = 80;
    Music = 60;
    Game = 75;
    System = 70;
    Headphones = 85;
  };

  # Fader assignments
  faders = {
    A = "Mic";
    B = "Music";
    C = "Chat";
    D = "System";
  };

  # Fader mute behaviour (per-fader)
  faderMuteBehaviour = {
    A = "All";
    B = "ToStream";
  };

  # Fader mute state (per-fader)
  faderMuteState = {
    A = false;
    C = true;
  };

  # Scribble screens (full GoXLR only)
  scribbles = {
    A = { text = "Mic"; icon = "microphone"; invert = false; };
    B = { text = "Music"; number = "2"; };
  };

  # Audio routing matrix
  routing = {
    Microphone = {
      Headphones = true;
      ChatMic = true;
      BroadcastMix = true;
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
      ratio = "Ratio3_0";
      makeUp = 6;
    };
    deEss = 0;
    # Full GoXLR equaliser
    equaliser = {
      Equalizer250Hz = { gain = 3; };
      Equalizer1KHz = { gain = -2; frequency = 1000.0; };
    };
  };

  # Submix settings
  submix = {
    enabled = true;
    volumes = { Mic = 100; Chat = 80; };
    linked = { Mic = true; };
    outputMix = { Headphones = "A"; };
    monitorMix = "Headphones";
  };

  # Effects panel
  effects = {
    enabled = true;
    activePreset = "Preset1";
    renameActivePreset = "My Preset";
    saveActivePreset = true;
    reverb = {
      style = "Library";
      amount = 20;
      decay = 2000;
    };
    echo = {
      style = "Quarter";
      amount = 15;
      feedback = 30;
    };
    pitch = { style = "Narrow"; amount = 0; };
    gender = { style = "Narrow"; amount = 0; };
    megaphone = { style = "Megaphone"; enabled = false; };
    robot = {
      style = "Robot1";
      ranges = {
        Low = { gain = 5; frequency = 40; bandwidth = 20; };
      };
      enabled = false;
    };
    hardTune = { style = "Natural"; enabled = false; };
  };

  # Sampler (PascalCase keys are auto-converted to lowercase-hyphenated for goxlr-client)
  sampler = {
    SamplerA = {
      TopLeft = {
        files = [ "/path/to/sound.wav" ];
        playbackMode = "PlayNext";
        playbackOrder = "Sequential";
        sampleSettings = [
          { startPercent = 10.0; stopPercent = 90.0; }
        ];
      };
      BottomRight = {
        files = [ "/path/to/other.wav" ];
        playbackMode = "Loop";
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
      mode = "RainbowBright";
      mod1 = 50;
      mod2 = 50;
      waterfall = "Down";
    };
    fadersAll = { display = "TwoColour"; top = "00FFFF"; bottom = "000000"; };
    faders = {
      A = { top = "00FFFF"; bottom = "000000"; display = "TwoColour"; };
      B = { top = "FF00FF"; bottom = "000000"; display = "TwoColour"; };
    };
    buttonGroups = {
      FaderMute = { colour = "FF0000"; offStyle = "Dimmed"; };
    };
  };

  # Cough button
  coughButton = {
    isHold = true;
    muteBehaviour = "ToStream";
    muteState = false;
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
| `volumes` | attrs of int | Channel volumes (0-100) |
| `faders` | attrs of string | Fader-to-channel assignments (A, B, C, D) |
| `faderMuteBehaviour` | attrs of string | Per-fader mute behaviour on press |
| `faderMuteState` | attrs of bool | Per-fader mute state (true = muted) |
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
| `submix.volumes` | attrs of int | Submix channel volumes (0-100) |
| `submix.linked` | attrs of bool | Link channel volumes to submix |
| `submix.outputMix` | attrs of string | Output device mix assignment (A or B) |
| `submix.monitorMix` | string | Output device to monitor |
| **Effects** | | |
| `effects.enabled` | bool | Enable/disable FX panel |
| `effects.activePreset` | string | Set active effect preset (Preset1-6) |
| `effects.loadPreset` | string | Load effect preset by name |
| `effects.renameActivePreset` | string | Rename the active effect preset |
| `effects.saveActivePreset` | bool | Save the active effect preset after changes |
| `effects.reverb.*` | various | Reverb (style, amount, decay, earlyLevel, tailLevel, preDelay, lowColour, highColour, highFactor, diffuse, modSpeed, modDepth) |
| `effects.echo.*` | various | Echo (style, amount, feedback, tempo, delayLeft, delayRight, feedbackXFBLtoR, feedbackXFBRtoL) |
| `effects.pitch.*` | various | Pitch (style, amount, character) |
| `effects.gender.*` | various | Gender (style, amount) |
| `effects.megaphone.*` | various | Megaphone (style, amount, postGain, enabled) |
| `effects.robot.*` | various | Robot (style, ranges.{Low,Medium,High}.{gain,frequency,bandwidth}, waveform, pulseWidth, threshold, dryMix, enabled) |
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
| `coughButton.muteState` | bool | Mute state (true = muted) |
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

## License

MIT
