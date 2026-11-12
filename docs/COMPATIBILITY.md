# GoXLR Mini and full GoXLR

Both devices are supported. The one check this flake declares evaluates the
module with `enable = true` and stops there. No check in the repository runs
against a real mixer.

## What a Mini does not have

- No effects panel. Reverb, echo, pitch, gender, megaphone, robot and hard
  tune are hardware of the full GoXLR only.
- No sampler. The sample pads are hardware of the full GoXLR only.
- No scribble screens. The fader OLED displays are hardware of the full GoXLR
  only.
- No encoder lighting. The rotary encoder rings are hardware of the full GoXLR
  only.
- Six buttons: `fader1-mute` to `fader4-mute`, `cough` and `bleep`. The full
  GoXLR has effect-select and effect-toggle buttons as well.
- Its own equaliser option, `microphone.equaliserMini`, in place of the full
  GoXLR's `microphone.equaliser`.

`microphone.equaliser` takes ten bands, `equalizer31-hz` to `equalizer16-k-hz`.
`microphone.equaliserMini` takes six, `equalizer90-hz` to `equalizer8-k-hz`.
The band names are in the option descriptions in [module.nix](../module.nix).

## A configuration for a GoXLR Mini

What the block below sets, in order:

- the device profile and the microphone profile to load on login
- channel volumes, 0 to 100 percent
- the channel on each fader, and what a press of each fader's mute button mutes
- the routing matrix: the input, then the output, then whether the route is on
- microphone settings, here for a condenser microphone
- the submix, which gives independent monitor and stream volumes
- the cough button and the bleep volume, 0 to 100 percent
- device settings
- lighting, here a yellow theme

```nix
programs.goxlr = {
  enable = true;

  profile = "Yellow Default";
  micProfile = "Mic NeatKingBee";

  volumes = {
    mic = 100; chat = 100; music = 59; game = 100;
    console = 50; system = 82; sample = 100;
    headphones = 100; mic-monitor = 0; line-out = 100;
  };

  faders = { a = "game"; b = "chat"; c = "music"; d = "system"; };

  faderMuteBehaviour = { a = "all"; b = "all"; c = "all"; d = "all"; };

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

  submix = {
    enabled = true;
    volumes = { mic = 100; chat = 100; music = 100; game = 100; };
    linked = { mic = true; chat = true; game = true; };
    outputMix = { headphones = "a"; broadcast-mix = "b"; };
    monitorMix = "headphones";
  };

  coughButton = { isHold = false; muteBehaviour = "all"; };
  bleepVolume = 50;

  settings = {
    muteHoldDuration = 500;
    monitorWithFx = false;
    deafenOnChatMute = true;
    lockFaders = false;
  };

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

## Additions for a full GoXLR

A full GoXLR takes every option of the Mini block above. It also takes the
four below, each for hardware a Mini does not have: the scribble screens, the
effects panel, the sampler and the encoder lighting.

```nix
programs.goxlr = {
  scribbles = {
    a = { text = "Mic"; icon = "microphone"; invert = false; };
    b = { text = "Music"; number = "2"; };
  };

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

  sampler.SamplerA.TopLeft = {
    files = [ "/path/to/sound.wav" ];
    playbackMode = "PlayNext";
    playbackOrder = "Sequential";
  };

  lighting.encoders = {
    reverb = { colour1 = "00FFFF"; colour2 = "000000"; colour3 = "00FFFF"; };
    echo = { colour1 = "00FFFF"; colour2 = "000000"; colour3 = "00FFFF"; };
  };
};
```
