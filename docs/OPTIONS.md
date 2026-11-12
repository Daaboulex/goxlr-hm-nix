# Options

Every option the modules of this flake declare. This file is generated from the module sources: change a description there, then run `nix run .#std-write-option-reference`.

## Home Manager module

Declared in [module.nix](../module.nix).

### `programs.goxlr.enable`

Whether to enable declarative GoXLR mixer configuration via goxlr-client.

- Type: boolean
- Default: `false`

### `programs.goxlr.bleepVolume`

Bleep button volume (0-100 percent)

- Type: null or integer between 0 and 100 (both inclusive)
- Default: `null`

### `programs.goxlr.coughButton.isHold`

Whether cough button only mutes while held (not toggled)

- Type: null or boolean
- Default: `null`

### `programs.goxlr.coughButton.muteBehaviour`

Where a press mutes to: all, to-stream, to-voice-chat, to-phones, to-line-out

- Type: null or string
- Default: `null`

### `programs.goxlr.coughButton.muteState`

Cough button mute state: unmuted, muted-to-x, muted-to-all

- Type: null or string
- Default: `null`

### `programs.goxlr.device`

Device serial number (required if multiple GoXLRs connected)

- Type: null or string
- Default: `null`

### `programs.goxlr.effects.activePreset`

Set the active effect preset: preset1, preset2, preset3, preset4, preset5, preset6

- Type: null or string
- Default: `null`

### `programs.goxlr.effects.echo.amount`

Echo amount (0-100)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.echo.delayLeft`

Echo left delay in ms (only for non-ClassicSlap styles)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.echo.delayRight`

Echo right delay in ms (only for non-ClassicSlap styles)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.echo.feedback`

Echo feedback (0-100)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.echo.feedbackXFBLtoR`

Echo cross-feedback left to right (0-100)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.echo.feedbackXFBRtoL`

Echo cross-feedback right to left (0-100)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.echo.style`

Echo style: quarter, eighth, triplet, ping-pong, classic-slap, multi-tap

- Type: null or string
- Default: `null`

### `programs.goxlr.effects.echo.tempo`

Echo tempo in ms (only for ClassicSlap style)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.enabled`

Enable or disable the FX panel

- Type: null or boolean
- Default: `null`

### `programs.goxlr.effects.gender.amount`

Gender amount (-12 to 12)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.gender.style`

Gender style: narrow, medium, wide

- Type: null or string
- Default: `null`

### `programs.goxlr.effects.hardTune.amount`

HardTune amount (0-100)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.hardTune.enabled`

Enable or disable the hard-tune button

- Type: null or boolean
- Default: `null`

### `programs.goxlr.effects.hardTune.rate`

HardTune rate (0-100)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.hardTune.source`

HardTune source: all, music, game, line-in, system

- Type: null or string
- Default: `null`

### `programs.goxlr.effects.hardTune.style`

HardTune style: natural, medium, hard

- Type: null or string
- Default: `null`

### `programs.goxlr.effects.hardTune.window`

HardTune window (0-600)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.loadPreset`

Load an effect preset by name

- Type: null or string
- Default: `null`

### `programs.goxlr.effects.megaphone.amount`

Megaphone amount (0-100)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.megaphone.enabled`

Enable or disable the megaphone button

- Type: null or boolean
- Default: `null`

### `programs.goxlr.effects.megaphone.postGain`

Megaphone post-processing gain (dB)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.megaphone.style`

Megaphone style: megaphone, radio, on-the-phone, overdrive, buzz-cutt, tweed, hi-fi, television

- Type: null or string
- Default: `null`

### `programs.goxlr.effects.pitch.amount`

Pitch amount (-24 to 24)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.pitch.character`

Pitch character (0-100)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.pitch.style`

Pitch style: narrow, wide

- Type: null or string
- Default: `null`

### `programs.goxlr.effects.renameActivePreset`

Rename the currently active effect preset

- Type: null or string
- Default: `null`

### `programs.goxlr.effects.reverb.amount`

Reverb amount (0-100)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.reverb.decay`

Reverb decay (milliseconds)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.reverb.diffuse`

Reverb diffuse level (-50 to 50)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.reverb.earlyLevel`

Reverb early level (dB)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.reverb.highColour`

Reverb high colour (-50 to 50)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.reverb.highFactor`

Reverb high factor (-25 to 25)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.reverb.lowColour`

Reverb low colour (-50 to 50)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.reverb.modDepth`

Reverb mod depth (-25 to 25)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.reverb.modSpeed`

Reverb mod speed (-25 to 25)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.reverb.preDelay`

Reverb pre-delay (0-100)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.reverb.style`

Reverb style: library, dark-bloom, music-club, real-plate, chapel, hockey-arena

- Type: null or string
- Default: `null`

### `programs.goxlr.effects.reverb.tailLevel`

Reverb tail level (dB)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.robot.dryMix`

Robot dry mix (dB)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.robot.enabled`

Enable or disable the robot button

- Type: null or boolean
- Default: `null`

### `programs.goxlr.effects.robot.pulseWidth`

Robot pulse width (0-100)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.robot.ranges`

Per-range robot settings. Keys: low, medium, high.

- Type: attribute set of (submodule)
- Default: `{ }`
- Example:

  ```nix
  {
    high = {
      gain = -2;
    };
    low = {
      bandwidth = 20;
      frequency = 40;
      gain = 5;
    };
    medium = {
      gain = 3;
    };
  }
  ```

### `programs.goxlr.effects.robot.ranges.<name>.bandwidth`

Bandwidth value for this range

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.robot.ranges.<name>.frequency`

Frequency value for this range

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.robot.ranges.<name>.gain`

Gain value for this range

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.robot.style`

Robot style: robot1, robot2, robot3

- Type: null or string
- Default: `null`

### `programs.goxlr.effects.robot.threshold`

Robot activation threshold (dB)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.robot.waveform`

Robot waveform (0-255)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.effects.saveActivePreset`

Save the currently active effect preset after applying changes

- Type: boolean
- Default: `false`

### `programs.goxlr.extraCommands`

Additional raw goxlr-client commands to run after all declarative settings are applied.

- Type: list of string
- Default: `[ ]`
- Example:

  ```nix
  [
    "goxlr-client effects reverb style library"
  ]
  ```

### `programs.goxlr.faderMuteBehaviour`

Per-fader mute behaviour on single press. Keys: a, b, c, d. Values: all, to-stream, to-voice-chat, to-phones, to-line-out. Hold always mutes to all.

- Type: attribute set of (null or string)
- Default: `{ }`
- Example:

  ```nix
  {
    a = "all";
    b = "to-stream";
  }
  ```

### `programs.goxlr.faderMuteState`

Per-fader mute state. Keys: a, b, c, d. Values: unmuted, muted-to-x, muted-to-all.

- Type: attribute set of (null or string)
- Default: `{ }`
- Example:

  ```nix
  {
    a = "unmuted";
    c = "muted-to-all";
  }
  ```

### `programs.goxlr.faders`

Map faders (a, b, c, d) to channel names (mic, chat, music, game, console, system, sample, headphones, mic-monitor, line-out).

- Type: attribute set of string
- Default: `{ }`
- Example:

  ```nix
  {
    a = "mic";
    b = "music";
    c = "chat";
    d = "system";
  }
  ```

### `programs.goxlr.lighting.animation.mod1`

Animation mod1 value (0-255)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.lighting.animation.mod2`

Animation mod2 value (0-255)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.lighting.animation.mode`

Animation mode: none, retro-rainbow, rainbow-dark, rainbow-bright, simple, ripple

- Type: null or string
- Default: `null`

### `programs.goxlr.lighting.animation.waterfall`

Waterfall direction: down, up, off

- Type: null or string
- Default: `null`

### `programs.goxlr.lighting.buttonGroups`

Lighting for groups of buttons. Keys are group names (e.g., fader-mute, effect-selector, effect-types).

- Type: attribute set of (submodule)
- Default: `{ }`
- Example:

  ```nix
  {
    fader-mute = {
      colour = "FF0000";
      offStyle = "dimmed";
    };
  }
  ```

### `programs.goxlr.lighting.buttonGroups.<name>.colour`

Primary button colour [RRGGBB]

- Type: null or string
- Default: `null`

### `programs.goxlr.lighting.buttonGroups.<name>.colour2`

Secondary button colour [RRGGBB]

- Type: null or string
- Default: `null`

### `programs.goxlr.lighting.buttonGroups.<name>.offStyle`

Off style: dimmed, colour2, dimmed-colour2

- Type: null or string
- Default: `null`

### `programs.goxlr.lighting.buttons`

Per-button lighting. Keys are button names (e.g., fader1-mute, effect-select1, cough, etc.).

- Type: attribute set of (submodule)
- Default: `{ }`

### `programs.goxlr.lighting.buttons.<name>.colour`

Primary button colour [RRGGBB]

- Type: null or string
- Default: `null`

### `programs.goxlr.lighting.buttons.<name>.colour2`

Secondary button colour [RRGGBB]

- Type: null or string
- Default: `null`

### `programs.goxlr.lighting.buttons.<name>.offStyle`

Off style: dimmed, colour2, dimmed-colour2

- Type: null or string
- Default: `null`

### `programs.goxlr.lighting.encoders`

Encoder lighting. Keys are encoder names (e.g., reverb, echo, pitch, gender).

- Type: attribute set of (submodule)
- Default: `{ }`

### `programs.goxlr.lighting.encoders.<name>.colour1`

Inactive colour [RRGGBB]

- Type: null or string
- Default: `null`

### `programs.goxlr.lighting.encoders.<name>.colour2`

Active colour [RRGGBB]

- Type: null or string
- Default: `null`

### `programs.goxlr.lighting.encoders.<name>.colour3`

Knob colour [RRGGBB]

- Type: null or string
- Default: `null`

### `programs.goxlr.lighting.faders`

Per-fader lighting. Keys: a, b, c, d.

- Type: attribute set of (submodule)
- Default: `{ }`
- Example:

  ```nix
  {
    a = {
      bottom = "000000";
      display = "two-colour";
      top = "00FFFF";
    };
  }
  ```

### `programs.goxlr.lighting.faders.<name>.bottom`

Bottom colour in hex [RRGGBB]

- Type: null or string
- Default: `null`

### `programs.goxlr.lighting.faders.<name>.display`

Display style: two-colour, gradient, meter, gradient-meter

- Type: null or string
- Default: `null`

### `programs.goxlr.lighting.faders.<name>.top`

Top colour in hex [RRGGBB]

- Type: null or string
- Default: `null`

### `programs.goxlr.lighting.fadersAll.bottom`

Bottom colour for all faders [RRGGBB]

- Type: null or string
- Default: `null`

### `programs.goxlr.lighting.fadersAll.display`

Display style for all faders: two-colour, gradient, meter, gradient-meter

- Type: null or string
- Default: `null`

### `programs.goxlr.lighting.fadersAll.top`

Top colour for all faders [RRGGBB]

- Type: null or string
- Default: `null`

### `programs.goxlr.lighting.global`

Global colour in hex [RRGGBB]

- Type: null or string
- Default: `null`

### `programs.goxlr.lighting.simple`

Simple (one-colour) lighting targets. Map target name to hex colour.

- Type: attribute set of string
- Default: `{ }`

### `programs.goxlr.micProfile`

Microphone profile to load on login

- Type: null or string
- Default: `null`

### `programs.goxlr.microphone.compressor.attack`

Compressor attack time (e.g., comp0ms, comp2ms, comp3ms, ... comp20ms)

- Type: null or string
- Default: `null`

### `programs.goxlr.microphone.compressor.makeUp`

Compressor make-up gain in dB

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.microphone.compressor.ratio`

Compressor ratio (e.g., ratio1-0, ratio1-1, ... ratio20-0)

- Type: null or string
- Default: `null`

### `programs.goxlr.microphone.compressor.release`

Compressor release time (e.g., comp0ms, comp15ms, comp25ms, ... comp1000ms)

- Type: null or string
- Default: `null`

### `programs.goxlr.microphone.compressor.threshold`

Compressor threshold in dB (-24 to 0)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.microphone.condenserGain`

Condenser (XLR + phantom) microphone gain in dB (recommended < 72)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.microphone.deEss`

De-esser level (0-100)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.microphone.dynamicGain`

Dynamic (XLR) microphone gain in dB (recommended < 72)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.microphone.equaliser`

Full GoXLR equaliser bands. Keys: equalizer31-hz, equalizer63-hz, equalizer125-hz, equalizer250-hz, equalizer500-hz, equalizer1-k-hz, equalizer2-k-hz, equalizer4-k-hz, equalizer8-k-hz, equalizer16-k-hz.

- Type: attribute set of (submodule)
- Default: `{ }`
- Example:

  ```nix
  {
    equalizer250-hz = {
      gain = -2;
    };
    equalizer90-hz = {
      frequency = 90.0;
      gain = 3;
    };
  }
  ```

### `programs.goxlr.microphone.equaliser.<name>.frequency`

EQ frequency value (Hz)

- Type: null or floating point number
- Default: `null`

### `programs.goxlr.microphone.equaliser.<name>.gain`

EQ gain value (dB)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.microphone.equaliserMini`

GoXLR Mini equaliser bands. Keys: equalizer90-hz, equalizer250-hz, equalizer500-hz, equalizer1-k-hz, equalizer3-k-hz, equalizer8-k-hz.

- Type: attribute set of (submodule)
- Default: `{ }`
- Example:

  ```nix
  {
    equalizer90-hz = {
      gain = 3;
    };
  }
  ```

### `programs.goxlr.microphone.equaliserMini.<name>.frequency`

EQ frequency value (Hz)

- Type: null or floating point number
- Default: `null`

### `programs.goxlr.microphone.equaliserMini.<name>.gain`

EQ gain value (dB)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.microphone.gate.active`

Whether noise gate is active

- Type: null or boolean
- Default: `null`

### `programs.goxlr.microphone.gate.attack`

Noise gate attack time (e.g., gate10ms, gate20ms, gate30ms, gate40ms, gate50ms)

- Type: null or string
- Default: `null`

### `programs.goxlr.microphone.gate.attenuation`

Noise gate attenuation percentage (0-100)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.microphone.gate.release`

Noise gate release time (e.g., gate10ms, gate20ms, gate30ms, gate40ms, gate50ms)

- Type: null or string
- Default: `null`

### `programs.goxlr.microphone.gate.threshold`

Noise gate threshold in dB (-59 to 0)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.microphone.jackGain`

Jack (3.5mm) microphone gain in dB (recommended < 72)

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.microphone.monitorWithFx`

Enable microphone monitor whenever FX are enabled

- Type: null or boolean
- Default: `null`

### `programs.goxlr.powerActions.shutdown.loadColours`

Profile whose colours to load on shutdown

- Type: null or string
- Default: `null`

### `programs.goxlr.powerActions.shutdown.micProfile`

Mic profile to load on shutdown

- Type: null or string
- Default: `null`

### `programs.goxlr.powerActions.shutdown.profile`

Device profile to load on shutdown

- Type: null or string
- Default: `null`

### `programs.goxlr.powerActions.sleep.loadColours`

Profile whose colours to load when going to sleep

- Type: null or string
- Default: `null`

### `programs.goxlr.powerActions.sleep.micProfile`

Mic profile to load when going to sleep

- Type: null or string
- Default: `null`

### `programs.goxlr.powerActions.sleep.profile`

Device profile to load when going to sleep

- Type: null or string
- Default: `null`

### `programs.goxlr.powerActions.wake.loadColours`

Profile whose colours to load on wake

- Type: null or string
- Default: `null`

### `programs.goxlr.powerActions.wake.micProfile`

Mic profile to load on wake

- Type: null or string
- Default: `null`

### `programs.goxlr.powerActions.wake.profile`

Device profile to load on wake

- Type: null or string
- Default: `null`

### `programs.goxlr.powerActions.wake.reloadSettings`

Whether to reload daemon settings on wake

- Type: boolean
- Default: `false`

### `programs.goxlr.profile`

Device profile to load on login

- Type: null or string
- Default: `null`

### `programs.goxlr.routing`

Audio routing matrix. Keys are input devices, values are attrsets of output devices to booleans.
Inputs: microphone, chat, music, game, console, line-in, system, samples
Outputs: headphones, broadcast-mix, chat-mic, sampler, line-out

- Type: attribute set of attribute set of boolean
- Default: `{ }`
- Example:

  ```nix
  {
    microphone = {
      broadcast-mix = true;
      chat-mic = true;
      headphones = true;
      samples = false;
    };
    music = {
      broadcast-mix = true;
      headphones = true;
    };
  }
  ```

### `programs.goxlr.sampler`

Sampler configuration. First key is bank (SamplerA, SamplerB, SamplerC), second key is button (TopLeft, TopRight, BottomLeft, BottomRight). Keys use PascalCase in config and are converted to CLI format automatically. Playback modes/orders also use PascalCase (PlayNext, PlayStop, Sequential, Random, etc.).

- Type: attribute set of attribute set of (submodule)
- Default: `{ }`
- Example:

  ```nix
  {
    SamplerA = {
      TopLeft = {
        files = [
          "/path/to/sound.wav"
        ];
        playbackMode = "PlayNext";
        playbackOrder = "Sequential";
        sampleSettings = [
          {
            startPercent = 10.0;
            stopPercent = 90.0;
          }
        ];
      };
    };
  }
  ```

### `programs.goxlr.sampler.<name>.<name>.files`

Audio files to add to this sampler button

- Type: list of string
- Default: `[ ]`

### `programs.goxlr.sampler.<name>.<name>.playbackMode`

Playback mode: PlayNext, PlayStop, PlayFade, StopOnRelease, FadeOnRelease, Loop

- Type: null or string
- Default: `null`

### `programs.goxlr.sampler.<name>.<name>.playbackOrder`

Playback order: Sequential, Random

- Type: null or string
- Default: `null`

### `programs.goxlr.sampler.<name>.<name>.removeByIndex`

Sample indices to remove from this button

- Type: list of signed integer
- Default: `[ ]`

### `programs.goxlr.sampler.<name>.<name>.sampleSettings`

Per-sample settings (start/stop percent) by index, matching the order in files

- Type: list of (submodule)
- Default: `[ ]`

### `programs.goxlr.sampler.<name>.<name>.sampleSettings.*.startPercent`

Start position as percentage (0.0-100.0)

- Type: null or floating point number
- Default: `null`

### `programs.goxlr.sampler.<name>.<name>.sampleSettings.*.stopPercent`

Stop position as percentage (0.0-100.0)

- Type: null or floating point number
- Default: `null`

### `programs.goxlr.scribbles`

Per-fader scribble screen settings (full GoXLR only). Keys: a, b, c, d.

- Type: attribute set of (submodule)
- Default: `{ }`
- Example:

  ```nix
  {
    a = {
      icon = "microphone";
      invert = false;
      text = "Mic";
    };
  }
  ```

### `programs.goxlr.scribbles.<name>.icon`

Icon file name for the scribble screen

- Type: null or string
- Default: `null`

### `programs.goxlr.scribbles.<name>.invert`

Whether to invert the scribble display

- Type: null or boolean
- Default: `null`

### `programs.goxlr.scribbles.<name>.number`

Number/text for top-left of scribble screen

- Type: null or string
- Default: `null`

### `programs.goxlr.scribbles.<name>.text`

Text to display on the scribble screen

- Type: null or string
- Default: `null`

### `programs.goxlr.settings.deafenOnChatMute`

Whether to mute the microphone when voice chat is muted

- Type: null or boolean
- Default: `null`

### `programs.goxlr.settings.lockFaders`

Lock faders to their current value on mute-to-all

- Type: null or boolean
- Default: `null`

### `programs.goxlr.settings.monitorWithFx`

Enable mic monitoring when FX are enabled

- Type: null or boolean
- Default: `null`

### `programs.goxlr.settings.muteHoldDuration`

How long to hold a mute button (ms) before it mutes to all

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.settings.samplePreRecordBuffer`

How far in the past (ms) the sampler should listen for audio

- Type: null or signed integer
- Default: `null`

### `programs.goxlr.submix.enabled`

Enable or disable submixes

- Type: null or boolean
- Default: `null`

### `programs.goxlr.submix.linked`

Whether channel volumes are linked to submix volumes. Keys are lowercase-hyphenated channel names.

- Type: attribute set of (null or boolean)
- Default: `{ }`
- Example:

  ```nix
  {
    chat = false;
    mic = true;
  }
  ```

### `programs.goxlr.submix.monitorMix`

Output device to monitor (e.g., headphones, broadcast-mix, chat-mic, sampler, line-out)

- Type: null or string
- Default: `null`

### `programs.goxlr.submix.outputMix`

Output device mix assignment. Keys are output devices (lowercase-hyphenated), values are mix names (a or b).

- Type: attribute set of (null or string)
- Default: `{ }`
- Example:

  ```nix
  {
    broadcast-mix = "b";
    headphones = "a";
  }
  ```

### `programs.goxlr.submix.volumes`

Submix channel volume levels (0-100 percent). Same channel names as main volumes (lowercase-hyphenated).

- Type: attribute set of signed integer
- Default: `{ }`
- Example:

  ```nix
  {
    chat = 75;
    mic = 100;
  }
  ```

### `programs.goxlr.volumes`

Channel volume levels (0-100 percent). Keys are channel names: mic, chat, music, game, console, system, sample, headphones, mic-monitor, line-out.

- Type: attribute set of signed integer
- Default: `{ }`
- Example:

  ```nix
  {
    chat = 80;
    console = 50;
    game = 75;
    headphones = 85;
    line-out = 50;
    mic = 100;
    music = 60;
    sample = 50;
    system = 70;
  }
  ```
