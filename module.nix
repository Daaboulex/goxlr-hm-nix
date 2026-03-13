# GoXLR Utility Home Manager module — declarative mixer state via goxlr-client.
#
# Applies volumes, fader assignments, routing, microphone settings, effects,
# sampler, submix, lighting, animation, device settings, and profile loading
# at login via a systemd user service that waits for the goxlr-daemon socket.
#
# The NixOS-level module (parts/goxlr.nix) handles daemon setup, udev, UCM
# patches, PipeWire EQ chains, and denoise.  This HM module handles the
# user-facing mixer state that goxlr-client configures.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.goxlr;

  # Build a list of goxlr-client commands from the declared state
  deviceFlag = lib.optionalString (cfg.device != null) "--device ${cfg.device} ";

  mkDeviceCmd = args: "goxlr-client ${deviceFlag}${args}";

  # Sampler case transformation — goxlr-client expects lowercase-hyphenated keys
  samplerBank =
    bank:
    {
      SamplerA = "a";
      SamplerB = "b";
      SamplerC = "c";
    }
    .${bank} or (throw "Unknown sampler bank: ${bank}");

  samplerButton =
    button:
    {
      TopLeft = "top-left";
      TopRight = "top-right";
      BottomLeft = "bottom-left";
      BottomRight = "bottom-right";
    }
    .${button} or (throw "Unknown sampler button: ${button}");

  samplerPlaybackMode =
    mode:
    {
      PlayNext = "play-next";
      PlayStop = "play-stop";
      PlayFade = "play-fade";
      StopOnRelease = "stop-on-release";
      FadeOnRelease = "fade-on-release";
      Loop = "loop";
    }
    .${mode} or (throw "Unknown playback mode: ${mode}");

  samplerPlaybackOrder =
    order:
    {
      Sequential = "sequential";
      Random = "random";
    }
    .${order} or (throw "Unknown playback order: ${order}");

  # --- Profile commands ---
  profileCmds =
    lib.optionals (cfg.profile != null) [
      (mkDeviceCmd "profiles device load ${lib.escapeShellArg cfg.profile}")
    ]
    ++ lib.optionals (cfg.micProfile != null) [
      (mkDeviceCmd "profiles microphone load ${lib.escapeShellArg cfg.micProfile}")
    ];

  # --- Volume commands ---
  volumeCmds = lib.mapAttrsToList (
    channel: volume: mkDeviceCmd "volume ${channel} ${toString volume}"
  ) cfg.volumes;

  # --- Fader commands ---
  faderChannelCmds = lib.mapAttrsToList (
    fader: channel: mkDeviceCmd "faders channel ${fader} ${channel}"
  ) cfg.faders;

  faderMuteBehaviourCmds = lib.concatLists (
    lib.mapAttrsToList (
      fader: behaviour:
      lib.optionals (behaviour != null) [
        (mkDeviceCmd "faders mute-behaviour ${fader} ${behaviour}")
      ]
    ) cfg.faderMuteBehaviour
  );

  faderMuteStateCmds = lib.concatLists (
    lib.mapAttrsToList (
      fader: state:
      lib.optionals (state != null) [
        (mkDeviceCmd "faders mute-state ${fader} ${state}")
      ]
    ) cfg.faderMuteState
  );

  # --- Fader scribble commands ---
  scribbleCmds = lib.concatLists (
    lib.mapAttrsToList (
      fader: scfg:
      lib.optionals (scfg.icon != null) [
        (mkDeviceCmd "faders scribbles icon ${fader} ${lib.escapeShellArg scfg.icon}")
      ]
      ++ lib.optionals (scfg.text != null) [
        (mkDeviceCmd "faders scribbles text ${fader} ${lib.escapeShellArg scfg.text}")
      ]
      ++ lib.optionals (scfg.number != null) [
        (mkDeviceCmd "faders scribbles number ${fader} ${lib.escapeShellArg scfg.number}")
      ]
      ++ lib.optionals (scfg.invert != null) [
        (mkDeviceCmd "faders scribbles invert ${fader} ${lib.boolToString scfg.invert}")
      ]
    ) cfg.scribbles
  );

  # --- Routing commands ---
  routingCmds = lib.concatLists (
    lib.mapAttrsToList (
      input: outputs:
      lib.mapAttrsToList (
        output: enabled: mkDeviceCmd "router ${input} ${output} ${lib.boolToString enabled}"
      ) outputs
    ) cfg.routing
  );

  # --- Microphone commands ---
  micGainCmds =
    lib.optionals (cfg.microphone.dynamicGain != null) [
      (mkDeviceCmd "--dynamic-gain ${toString cfg.microphone.dynamicGain}")
    ]
    ++ lib.optionals (cfg.microphone.condenserGain != null) [
      (mkDeviceCmd "--condenser-gain ${toString cfg.microphone.condenserGain}")
    ]
    ++ lib.optionals (cfg.microphone.jackGain != null) [
      (mkDeviceCmd "--jack-gain ${toString cfg.microphone.jackGain}")
    ];

  micGateCmds =
    let
      g = cfg.microphone.gate;
    in
    lib.optionals (g.threshold != null) [
      (mkDeviceCmd "microphone noise-gate threshold ${toString g.threshold}")
    ]
    ++ lib.optionals (g.attenuation != null) [
      (mkDeviceCmd "microphone noise-gate attenuation ${toString g.attenuation}")
    ]
    ++ lib.optionals (g.attack != null) [
      (mkDeviceCmd "microphone noise-gate attack ${g.attack}")
    ]
    ++ lib.optionals (g.release != null) [
      (mkDeviceCmd "microphone noise-gate release ${g.release}")
    ]
    ++ lib.optionals (g.active != null) [
      (mkDeviceCmd "microphone noise-gate active ${lib.boolToString g.active}")
    ];

  micCompressorCmds =
    let
      c = cfg.microphone.compressor;
    in
    lib.optionals (c.threshold != null) [
      (mkDeviceCmd "microphone compressor threshold ${toString c.threshold}")
    ]
    ++ lib.optionals (c.ratio != null) [
      (mkDeviceCmd "microphone compressor ratio ${c.ratio}")
    ]
    ++ lib.optionals (c.attack != null) [
      (mkDeviceCmd "microphone compressor attack ${c.attack}")
    ]
    ++ lib.optionals (c.release != null) [
      (mkDeviceCmd "microphone compressor release ${c.release}")
    ]
    ++ lib.optionals (c.makeUp != null) [
      (mkDeviceCmd "microphone compressor make-up ${toString c.makeUp}")
    ];

  micDeEssCmds = lib.optionals (cfg.microphone.deEss != null) [
    (mkDeviceCmd "microphone de-ess ${toString cfg.microphone.deEss}")
  ];

  micMonitorFxCmds = lib.optionals (cfg.microphone.monitorWithFx != null) [
    (mkDeviceCmd "microphone monitor-mic-with-fx ${lib.boolToString cfg.microphone.monitorWithFx}")
  ];

  # --- Microphone equaliser commands (full GoXLR) ---
  micEqCmds = lib.concatLists (
    lib.mapAttrsToList (
      freq: eqcfg:
      lib.optionals (eqcfg.frequency != null) [
        (mkDeviceCmd "microphone equaliser frequency ${freq} ${toString eqcfg.frequency}")
      ]
      ++ lib.optionals (eqcfg.gain != null) [
        (mkDeviceCmd "microphone equaliser gain ${freq} ${toString eqcfg.gain}")
      ]
    ) cfg.microphone.equaliser
  );

  # --- Microphone equaliser commands (GoXLR Mini) ---
  micEqMiniCmds = lib.concatLists (
    lib.mapAttrsToList (
      freq: eqcfg:
      lib.optionals (eqcfg.frequency != null) [
        (mkDeviceCmd "microphone equaliser-mini frequency ${freq} ${toString eqcfg.frequency}")
      ]
      ++ lib.optionals (eqcfg.gain != null) [
        (mkDeviceCmd "microphone equaliser-mini gain ${freq} ${toString eqcfg.gain}")
      ]
    ) cfg.microphone.equaliserMini
  );

  # --- Submix commands ---
  submixEnableCmds = lib.optionals (cfg.submix.enabled != null) [
    (mkDeviceCmd "submix enabled ${lib.boolToString cfg.submix.enabled}")
  ];

  submixVolumeCmds = lib.mapAttrsToList (
    channel: volume: mkDeviceCmd "submix volume ${channel} ${toString volume}"
  ) cfg.submix.volumes;

  submixLinkedCmds = lib.concatLists (
    lib.mapAttrsToList (
      channel: linked:
      lib.optionals (linked != null) [
        (mkDeviceCmd "submix linked ${channel} ${lib.boolToString linked}")
      ]
    ) cfg.submix.linked
  );

  submixOutputMixCmds = lib.concatLists (
    lib.mapAttrsToList (
      device: mix:
      lib.optionals (mix != null) [
        (mkDeviceCmd "submix output-mix ${device} ${mix}")
      ]
    ) cfg.submix.outputMix
  );

  submixMonitorMixCmds = lib.optionals (cfg.submix.monitorMix != null) [
    (mkDeviceCmd "submix monitor-mix ${cfg.submix.monitorMix}")
  ];

  # --- Effects commands ---
  effectsEnabledCmds = lib.optionals (cfg.effects.enabled != null) [
    (mkDeviceCmd "effects enabled ${lib.boolToString cfg.effects.enabled}")
  ];

  effectsPresetCmds =
    lib.optionals (cfg.effects.activePreset != null) [
      (mkDeviceCmd "effects set-active-preset ${cfg.effects.activePreset}")
    ]
    ++ lib.optionals (cfg.effects.loadPreset != null) [
      (mkDeviceCmd "effects load-effect-preset ${lib.escapeShellArg cfg.effects.loadPreset}")
    ]
    ++ lib.optionals (cfg.effects.renameActivePreset != null) [
      (mkDeviceCmd "effects rename-active-preset ${lib.escapeShellArg cfg.effects.renameActivePreset}")
    ]
    ++ lib.optionals cfg.effects.saveActivePreset [
      (mkDeviceCmd "effects save-active-preset")
    ];

  # --- Reverb ---
  reverbCmds =
    let
      r = cfg.effects.reverb;
    in
    lib.optionals (r.style != null) [
      (mkDeviceCmd "effects reverb style ${r.style}")
    ]
    ++ lib.optionals (r.amount != null) [
      (mkDeviceCmd "effects reverb amount ${toString r.amount}")
    ]
    ++ lib.optionals (r.decay != null) [
      (mkDeviceCmd "effects reverb decay ${toString r.decay}")
    ]
    ++ lib.optionals (r.earlyLevel != null) [
      (mkDeviceCmd "effects reverb early-level ${toString r.earlyLevel}")
    ]
    ++ lib.optionals (r.tailLevel != null) [
      (mkDeviceCmd "effects reverb tail-level ${toString r.tailLevel}")
    ]
    ++ lib.optionals (r.preDelay != null) [
      (mkDeviceCmd "effects reverb pre-delay ${toString r.preDelay}")
    ]
    ++ lib.optionals (r.lowColour != null) [
      (mkDeviceCmd "effects reverb low-colour ${toString r.lowColour}")
    ]
    ++ lib.optionals (r.highColour != null) [
      (mkDeviceCmd "effects reverb high-colour ${toString r.highColour}")
    ]
    ++ lib.optionals (r.highFactor != null) [
      (mkDeviceCmd "effects reverb high-factor ${toString r.highFactor}")
    ]
    ++ lib.optionals (r.diffuse != null) [
      (mkDeviceCmd "effects reverb diffuse ${toString r.diffuse}")
    ]
    ++ lib.optionals (r.modSpeed != null) [
      (mkDeviceCmd "effects reverb mod-speed ${toString r.modSpeed}")
    ]
    ++ lib.optionals (r.modDepth != null) [
      (mkDeviceCmd "effects reverb mod-depth ${toString r.modDepth}")
    ];

  # --- Echo ---
  echoCmds =
    let
      e = cfg.effects.echo;
    in
    lib.optionals (e.style != null) [
      (mkDeviceCmd "effects echo style ${e.style}")
    ]
    ++ lib.optionals (e.amount != null) [
      (mkDeviceCmd "effects echo amount ${toString e.amount}")
    ]
    ++ lib.optionals (e.feedback != null) [
      (mkDeviceCmd "effects echo feedback ${toString e.feedback}")
    ]
    ++ lib.optionals (e.tempo != null) [
      (mkDeviceCmd "effects echo tempo ${toString e.tempo}")
    ]
    ++ lib.optionals (e.delayLeft != null) [
      (mkDeviceCmd "effects echo delay-left ${toString e.delayLeft}")
    ]
    ++ lib.optionals (e.delayRight != null) [
      (mkDeviceCmd "effects echo delay-right ${toString e.delayRight}")
    ]
    ++ lib.optionals (e.feedbackXFBLtoR != null) [
      (mkDeviceCmd "effects echo feedback-xfb-lto-r ${toString e.feedbackXFBLtoR}")
    ]
    ++ lib.optionals (e.feedbackXFBRtoL != null) [
      (mkDeviceCmd "effects echo feedback-xfb-rto-l ${toString e.feedbackXFBRtoL}")
    ];

  # --- Pitch ---
  pitchCmds =
    let
      p = cfg.effects.pitch;
    in
    lib.optionals (p.style != null) [
      (mkDeviceCmd "effects pitch style ${p.style}")
    ]
    ++ lib.optionals (p.amount != null) [
      (mkDeviceCmd "effects pitch amount ${toString p.amount}")
    ]
    ++ lib.optionals (p.character != null) [
      (mkDeviceCmd "effects pitch character ${toString p.character}")
    ];

  # --- Gender ---
  genderCmds =
    let
      g = cfg.effects.gender;
    in
    lib.optionals (g.style != null) [
      (mkDeviceCmd "effects gender style ${g.style}")
    ]
    ++ lib.optionals (g.amount != null) [
      (mkDeviceCmd "effects gender amount ${toString g.amount}")
    ];

  # --- Megaphone ---
  megaphoneCmds =
    let
      m = cfg.effects.megaphone;
    in
    lib.optionals (m.style != null) [
      (mkDeviceCmd "effects megaphone style ${m.style}")
    ]
    ++ lib.optionals (m.amount != null) [
      (mkDeviceCmd "effects megaphone amount ${toString m.amount}")
    ]
    ++ lib.optionals (m.postGain != null) [
      (mkDeviceCmd "effects megaphone post-gain ${toString m.postGain}")
    ]
    ++ lib.optionals (m.enabled != null) [
      (mkDeviceCmd "effects megaphone enabled ${lib.boolToString m.enabled}")
    ];

  # --- Robot ---
  robotCmds =
    let
      r = cfg.effects.robot;
    in
    lib.optionals (r.style != null) [
      (mkDeviceCmd "effects robot style ${r.style}")
    ]
    ++ lib.concatLists (
      lib.mapAttrsToList (
        range: rcfg:
        lib.optionals (rcfg.gain != null) [
          (mkDeviceCmd "effects robot gain ${range} ${toString rcfg.gain}")
        ]
        ++ lib.optionals (rcfg.frequency != null) [
          (mkDeviceCmd "effects robot frequency ${range} ${toString rcfg.frequency}")
        ]
        ++ lib.optionals (rcfg.bandwidth != null) [
          (mkDeviceCmd "effects robot bandwidth ${range} ${toString rcfg.bandwidth}")
        ]
      ) r.ranges
    )
    ++ lib.optionals (r.waveform != null) [
      (mkDeviceCmd "effects robot wave-form ${toString r.waveform}")
    ]
    ++ lib.optionals (r.pulseWidth != null) [
      (mkDeviceCmd "effects robot pulse-width ${toString r.pulseWidth}")
    ]
    ++ lib.optionals (r.threshold != null) [
      (mkDeviceCmd "effects robot threshold ${toString r.threshold}")
    ]
    ++ lib.optionals (r.dryMix != null) [
      (mkDeviceCmd "effects robot dry-mix ${toString r.dryMix}")
    ]
    ++ lib.optionals (r.enabled != null) [
      (mkDeviceCmd "effects robot enabled ${lib.boolToString r.enabled}")
    ];

  # --- HardTune ---
  hardTuneCmds =
    let
      h = cfg.effects.hardTune;
    in
    lib.optionals (h.style != null) [
      (mkDeviceCmd "effects hard-tune style ${h.style}")
    ]
    ++ lib.optionals (h.amount != null) [
      (mkDeviceCmd "effects hard-tune amount ${toString h.amount}")
    ]
    ++ lib.optionals (h.rate != null) [
      (mkDeviceCmd "effects hard-tune rate ${toString h.rate}")
    ]
    ++ lib.optionals (h.window != null) [
      (mkDeviceCmd "effects hard-tune window ${toString h.window}")
    ]
    ++ lib.optionals (h.source != null) [
      (mkDeviceCmd "effects hard-tune source ${h.source}")
    ]
    ++ lib.optionals (h.enabled != null) [
      (mkDeviceCmd "effects hard-tune enabled ${lib.boolToString h.enabled}")
    ];

  # --- Sampler commands ---
  samplerCmds = lib.concatLists (
    lib.mapAttrsToList (
      bank: buttons:
      let
        b = samplerBank bank;
      in
      lib.concatLists (
        lib.mapAttrsToList (
          button: scfg:
          let
            btn = samplerButton button;
          in
          lib.optionals (scfg.playbackMode != null) [
            (mkDeviceCmd "sampler playback-mode ${b} ${btn} ${samplerPlaybackMode scfg.playbackMode}")
          ]
          ++ lib.optionals (scfg.playbackOrder != null) [
            (mkDeviceCmd "sampler playback-order ${b} ${btn} ${samplerPlaybackOrder scfg.playbackOrder}")
          ]
          ++ lib.concatMap (file: [
            (mkDeviceCmd "sampler add ${b} ${btn} ${lib.escapeShellArg file}")
          ]) scfg.files
          ++ lib.concatLists (
            lib.imap0 (
              i: sp:
              lib.optionals (sp.startPercent != null) [
                (mkDeviceCmd "sampler start-percent ${b} ${btn} ${toString i} ${toString sp.startPercent}")
              ]
              ++ lib.optionals (sp.stopPercent != null) [
                (mkDeviceCmd "sampler stop-percent ${b} ${btn} ${toString i} ${toString sp.stopPercent}")
              ]
            ) scfg.sampleSettings
          )
          ++ lib.concatMap (idx: [
            (mkDeviceCmd "sampler remove-by-index ${b} ${btn} ${toString idx}")
          ]) scfg.removeByIndex
        ) buttons
      )
    ) cfg.sampler
  );

  # --- Animation commands ---
  animationCmds =
    let
      a = cfg.lighting.animation;
    in
    lib.optionals (a.mode != null) [
      (mkDeviceCmd "lighting animation mode ${a.mode}")
    ]
    ++ lib.optionals (a.mod1 != null) [
      (mkDeviceCmd "lighting animation mod1 ${toString a.mod1}")
    ]
    ++ lib.optionals (a.mod2 != null) [
      (mkDeviceCmd "lighting animation mod2 ${toString a.mod2}")
    ]
    ++ lib.optionals (a.waterfall != null) [
      (mkDeviceCmd "lighting animation water-fall ${a.waterfall}")
    ];

  # --- Lighting faders-all commands ---
  lightingFadersAllCmds =
    let
      fa = cfg.lighting.fadersAll;
    in
    lib.optionals (fa.display != null) [
      (mkDeviceCmd "lighting faders-all display ${fa.display}")
    ]
    ++ lib.optionals (fa.top != null && fa.bottom != null) [
      (mkDeviceCmd "lighting faders-all colour ${fa.top} ${fa.bottom}")
    ];

  # --- Lighting button-group commands ---
  lightingButtonGroupCmds = lib.concatLists (
    lib.mapAttrsToList (
      group: gcfg:
      lib.optionals (gcfg.colour != null) [
        (mkDeviceCmd "lighting button-group colour ${group} ${gcfg.colour}${
          lib.optionalString (gcfg.colour2 != null) " ${gcfg.colour2}"
        }")
      ]
      ++ lib.optionals (gcfg.offStyle != null) [
        (mkDeviceCmd "lighting button-group off-style ${group} ${gcfg.offStyle}")
      ]
    ) cfg.lighting.buttonGroups
  );

  # --- Lighting commands (existing) ---
  lightingGlobalCmds = lib.optionals (cfg.lighting.global != null) [
    (mkDeviceCmd "lighting global ${cfg.lighting.global}")
  ];

  lightingFaderCmds = lib.concatLists (
    lib.mapAttrsToList (
      fader: lcfg:
      lib.optionals (lcfg.top != null && lcfg.bottom != null) [
        (mkDeviceCmd "lighting fader colour ${fader} ${lcfg.top} ${lcfg.bottom}")
      ]
      ++ lib.optionals (lcfg.display != null) [
        (mkDeviceCmd "lighting fader display ${fader} ${lcfg.display}")
      ]
    ) cfg.lighting.faders
  );

  lightingButtonCmds = lib.concatLists (
    lib.mapAttrsToList (
      button: bcfg:
      lib.optionals (bcfg.colour != null) [
        (mkDeviceCmd "lighting button colour ${button} ${bcfg.colour}${
          lib.optionalString (bcfg.colour2 != null) " ${bcfg.colour2}"
        }")
      ]
      ++ lib.optionals (bcfg.offStyle != null) [
        (mkDeviceCmd "lighting button off-style ${button} ${bcfg.offStyle}")
      ]
    ) cfg.lighting.buttons
  );

  lightingSimpleCmds = lib.mapAttrsToList (
    target: colour: mkDeviceCmd "lighting simple-colour ${target} ${colour}"
  ) cfg.lighting.simple;

  lightingEncoderCmds = lib.concatLists (
    lib.mapAttrsToList (
      encoder: ecfg:
      lib.optionals (ecfg.colour1 != null && ecfg.colour2 != null && ecfg.colour3 != null) [
        (mkDeviceCmd "lighting encoder-colour ${encoder} ${ecfg.colour1} ${ecfg.colour2} ${ecfg.colour3}")
      ]
    ) cfg.lighting.encoders
  );

  # --- Cough button commands ---
  coughCmds =
    lib.optionals (cfg.coughButton.isHold != null) [
      (mkDeviceCmd "cough-button button-is-hold ${lib.boolToString cfg.coughButton.isHold}")
    ]
    ++ lib.optionals (cfg.coughButton.muteBehaviour != null) [
      (mkDeviceCmd "cough-button mute-behaviour ${cfg.coughButton.muteBehaviour}")
    ]
    ++ lib.optionals (cfg.coughButton.muteState != null) [
      (mkDeviceCmd "cough-button mute-state ${cfg.coughButton.muteState}")
    ];

  # --- Bleep volume ---
  bleepCmds = lib.optionals (cfg.bleepVolume != null) [
    (mkDeviceCmd "bleep-volume ${toString cfg.bleepVolume}")
  ];

  # --- Device settings commands ---
  settingsCmds =
    let
      s = cfg.settings;
    in
    lib.optionals (s.muteHoldDuration != null) [
      (mkDeviceCmd "settings mute-hold-duration ${toString s.muteHoldDuration}")
    ]
    ++ lib.optionals (s.samplePreRecordBuffer != null) [
      (mkDeviceCmd "settings sample-pre-record-buffer ${toString s.samplePreRecordBuffer}")
    ]
    ++ lib.optionals (s.monitorWithFx != null) [
      (mkDeviceCmd "settings monitor-with-fx ${lib.boolToString s.monitorWithFx}")
    ]
    ++ lib.optionals (s.deafenOnChatMute != null) [
      (mkDeviceCmd "settings deafen-on-chat-mute ${lib.boolToString s.deafenOnChatMute}")
    ]
    ++ lib.optionals (s.lockFaders != null) [
      (mkDeviceCmd "settings lock-faders ${lib.boolToString s.lockFaders}")
    ];

  # --- All commands in order ---
  allCmds =
    profileCmds
    ++ volumeCmds
    ++ faderChannelCmds
    ++ faderMuteBehaviourCmds
    ++ faderMuteStateCmds
    ++ scribbleCmds
    ++ routingCmds
    ++ micGainCmds
    ++ micGateCmds
    ++ micCompressorCmds
    ++ micDeEssCmds
    ++ micMonitorFxCmds
    ++ micEqCmds
    ++ micEqMiniCmds
    ++ submixEnableCmds
    ++ submixVolumeCmds
    ++ submixLinkedCmds
    ++ submixOutputMixCmds
    ++ submixMonitorMixCmds
    ++ effectsEnabledCmds
    ++ effectsPresetCmds
    ++ reverbCmds
    ++ echoCmds
    ++ pitchCmds
    ++ genderCmds
    ++ megaphoneCmds
    ++ robotCmds
    ++ hardTuneCmds
    ++ samplerCmds
    ++ coughCmds
    ++ bleepCmds
    ++ settingsCmds
    ++ lightingGlobalCmds
    ++ animationCmds
    ++ lightingFadersAllCmds
    ++ lightingFaderCmds
    ++ lightingButtonCmds
    ++ lightingButtonGroupCmds
    ++ lightingSimpleCmds
    ++ lightingEncoderCmds
    ++ cfg.extraCommands;

  applyScript = pkgs.writeShellScript "goxlr-apply" ''
    set -euo pipefail
    export PATH="${lib.makeBinPath [ pkgs.goxlr-utility ]}:$PATH"

    # Wait for goxlr-daemon to be reachable (up to 30s)
    for i in $(seq 1 30); do
      if goxlr-client ${deviceFlag}--status >/dev/null 2>&1; then
        break
      fi
      if [ "$i" -eq 30 ]; then
        echo "goxlr-daemon not reachable after 30s, giving up" >&2
        exit 1
      fi
      sleep 1
    done

    # Small delay for device initialization after daemon is up
    sleep 1

    ${lib.concatStringsSep "\n" allCmds}

    echo "GoXLR state applied (${toString (builtins.length allCmds)} commands)"
  '';

  # Nullable option helpers
  mkNullOpt =
    type: description:
    lib.mkOption {
      type = lib.types.nullOr type;
      default = null;
      inherit description;
    };

  mkNullStr = mkNullOpt lib.types.str;
  mkNullInt = mkNullOpt lib.types.int;
  mkNullBool = mkNullOpt lib.types.bool;

  faderLightingSubmodule = lib.types.submodule {
    options = {
      top = mkNullStr "Top colour in hex [RRGGBB]";
      bottom = mkNullStr "Bottom colour in hex [RRGGBB]";
      display = mkNullStr "Display style: two-colour, gradient, meter, gradient-meter";
    };
  };

  buttonLightingSubmodule = lib.types.submodule {
    options = {
      colour = mkNullStr "Primary button colour [RRGGBB]";
      colour2 = mkNullStr "Secondary button colour [RRGGBB]";
      offStyle = mkNullStr "Off style: dimmed, colour2, dimmed-colour2";
    };
  };

  encoderLightingSubmodule = lib.types.submodule {
    options = {
      colour1 = mkNullStr "Inactive colour [RRGGBB]";
      colour2 = mkNullStr "Active colour [RRGGBB]";
      colour3 = mkNullStr "Knob colour [RRGGBB]";
    };
  };

  scribbleSubmodule = lib.types.submodule {
    options = {
      icon = mkNullStr "Icon file name for the scribble screen";
      text = mkNullStr "Text to display on the scribble screen";
      number = mkNullStr "Number/text for top-left of scribble screen";
      invert = mkNullBool "Whether to invert the scribble display";
    };
  };

  eqBandSubmodule = lib.types.submodule {
    options = {
      frequency = mkNullOpt lib.types.float "EQ frequency value (Hz)";
      gain = mkNullInt "EQ gain value (dB)";
    };
  };

  robotRangeSubmodule = lib.types.submodule {
    options = {
      gain = mkNullInt "Gain value for this range";
      frequency = mkNullInt "Frequency value for this range";
      bandwidth = mkNullInt "Bandwidth value for this range";
    };
  };

  samplerSampleSettingsSubmodule = lib.types.submodule {
    options = {
      startPercent = mkNullOpt lib.types.float "Start position as percentage (0.0-100.0)";
      stopPercent = mkNullOpt lib.types.float "Stop position as percentage (0.0-100.0)";
    };
  };

  samplerButtonSubmodule = lib.types.submodule {
    options = {
      files = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Audio files to add to this sampler button";
      };
      playbackMode = mkNullStr "Playback mode: play-next, play-stop, play-fade, stop-on-release, fade-on-release, loop";
      playbackOrder = mkNullStr "Playback order: sequential, random";
      sampleSettings = lib.mkOption {
        type = lib.types.listOf samplerSampleSettingsSubmodule;
        default = [ ];
        description = "Per-sample settings (start/stop percent) by index, matching the order in files";
      };
      removeByIndex = lib.mkOption {
        type = lib.types.listOf lib.types.int;
        default = [ ];
        description = "Sample indices to remove from this button";
      };
    };
  };
in
{
  options.programs.goxlr = {
    enable = lib.mkEnableOption "declarative GoXLR mixer configuration via goxlr-client";

    device = mkNullStr "Device serial number (required if multiple GoXLRs connected)";

    # --- Profile loading ---
    profile = mkNullStr "Device profile to load on login";
    micProfile = mkNullStr "Microphone profile to load on login";

    # --- Channel volumes (0-100) ---
    volumes = lib.mkOption {
      type = lib.types.attrsOf lib.types.int;
      default = { };
      example = {
        mic = 100;
        chat = 80;
        music = 60;
        game = 75;
        console = 50;
        system = 70;
        sample = 50;
        headphones = 85;
        line-out = 50;
      };
      description = "Channel volume levels (0-100 percent). Keys are channel names: mic, chat, music, game, console, system, sample, headphones, mic-monitor, line-out.";
    };

    # --- Fader assignments ---
    faders = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        a = "mic";
        b = "music";
        c = "chat";
        d = "system";
      };
      description = "Map faders (a, b, c, d) to channel names (mic, chat, music, game, console, system, sample, headphones, mic-monitor, line-out).";
    };

    # --- Fader mute behaviour ---
    faderMuteBehaviour = lib.mkOption {
      type = lib.types.attrsOf (lib.types.nullOr lib.types.str);
      default = { };
      example = {
        a = "all";
        b = "to-stream";
      };
      description = "Per-fader mute behaviour on single press. Keys: a, b, c, d. Values: all, to-stream, to-voice-chat, to-phones, to-line-out. Hold always mutes to all.";
    };

    # --- Fader mute state ---
    faderMuteState = lib.mkOption {
      type = lib.types.attrsOf (lib.types.nullOr lib.types.str);
      default = { };
      example = {
        a = "unmuted";
        c = "muted-to-all";
      };
      description = "Per-fader mute state. Keys: a, b, c, d. Values: unmuted, muted-to-x, muted-to-all.";
    };

    # --- Fader scribble screens (full GoXLR only) ---
    scribbles = lib.mkOption {
      type = lib.types.attrsOf scribbleSubmodule;
      default = { };
      example = {
        a = {
          text = "Mic";
          icon = "microphone";
          invert = false;
        };
      };
      description = "Per-fader scribble screen settings (full GoXLR only). Keys: a, b, c, d.";
    };

    # --- Routing matrix ---
    routing = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.bool);
      default = { };
      example = {
        microphone = {
          headphones = true;
          chat-mic = true;
          broadcast-mix = true;
          samples = false;
        };
        music = {
          headphones = true;
          broadcast-mix = true;
        };
      };
      description = ''
        Audio routing matrix. Keys are input devices, values are attrsets of output devices to booleans.
        Inputs: microphone, chat, music, game, console, line-in, system, samples
        Outputs: headphones, broadcast-mix, chat-mic, sampler, line-out
      '';
    };

    # --- Microphone settings ---
    microphone = {
      dynamicGain = mkNullInt "Dynamic (XLR) microphone gain in dB (recommended < 72)";
      condenserGain = mkNullInt "Condenser (XLR + phantom) microphone gain in dB (recommended < 72)";
      jackGain = mkNullInt "Jack (3.5mm) microphone gain in dB (recommended < 72)";
      deEss = mkNullInt "De-esser level (0-100)";
      monitorWithFx = mkNullBool "Enable microphone monitor whenever FX are enabled";

      gate = {
        threshold = mkNullInt "Noise gate threshold in dB (-59 to 0)";
        attenuation = mkNullInt "Noise gate attenuation percentage (0-100)";
        attack = mkNullStr "Noise gate attack time (e.g., gate10ms, gate20ms, gate30ms, gate40ms, gate50ms)";
        release = mkNullStr "Noise gate release time (e.g., gate10ms, gate20ms, gate30ms, gate40ms, gate50ms)";
        active = mkNullBool "Whether noise gate is active";
      };

      compressor = {
        threshold = mkNullInt "Compressor threshold in dB (-24 to 0)";
        ratio = mkNullStr "Compressor ratio (e.g., ratio1-0, ratio1-1, ... ratio20-0)";
        attack = mkNullStr "Compressor attack time (e.g., comp0ms, comp2ms, comp3ms, ... comp20ms)";
        release = mkNullStr "Compressor release time (e.g., comp0ms, comp15ms, comp25ms, ... comp1000ms)";
        makeUp = mkNullInt "Compressor make-up gain in dB";
      };

      equaliser = lib.mkOption {
        type = lib.types.attrsOf eqBandSubmodule;
        default = { };
        example = {
          equalizer90-hz = {
            frequency = 90.0;
            gain = 3;
          };
          equalizer250-hz = {
            gain = -2;
          };
        };
        description = "Full GoXLR equaliser bands. Keys: equalizer31-hz, equalizer63-hz, equalizer125-hz, equalizer250-hz, equalizer500-hz, equalizer1-k-hz, equalizer2-k-hz, equalizer4-k-hz, equalizer8-k-hz, equalizer16-k-hz.";
      };

      equaliserMini = lib.mkOption {
        type = lib.types.attrsOf eqBandSubmodule;
        default = { };
        example = {
          equalizer90-hz = {
            gain = 3;
          };
        };
        description = "GoXLR Mini equaliser bands. Keys: equalizer90-hz, equalizer250-hz, equalizer500-hz, equalizer1-k-hz, equalizer3-k-hz, equalizer8-k-hz.";
      };
    };

    # --- Submix settings ---
    submix = {
      enabled = mkNullBool "Enable or disable submixes";

      volumes = lib.mkOption {
        type = lib.types.attrsOf lib.types.int;
        default = { };
        example = {
          mic = 255;
          chat = 200;
        };
        description = "Submix channel volume levels (0-100 percent). Same channel names as main volumes (lowercase-hyphenated).";
      };

      linked = lib.mkOption {
        type = lib.types.attrsOf (lib.types.nullOr lib.types.bool);
        default = { };
        example = {
          mic = true;
          chat = false;
        };
        description = "Whether channel volumes are linked to submix volumes. Keys are lowercase-hyphenated channel names.";
      };

      outputMix = lib.mkOption {
        type = lib.types.attrsOf (lib.types.nullOr lib.types.str);
        default = { };
        example = {
          headphones = "a";
          broadcast-mix = "b";
        };
        description = "Output device mix assignment. Keys are output devices (lowercase-hyphenated), values are mix names (a or b).";
      };

      monitorMix = mkNullStr "Output device to monitor (e.g., headphones, broadcast-mix, chat-mic, sampler, line-out)";
    };

    # --- Effects panel ---
    effects = {
      enabled = mkNullBool "Enable or disable the FX panel";
      activePreset = mkNullStr "Set the active effect preset: preset1, preset2, preset3, preset4, preset5, preset6";
      loadPreset = mkNullStr "Load an effect preset by name";
      renameActivePreset = mkNullStr "Rename the currently active effect preset";
      saveActivePreset = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Save the currently active effect preset after applying changes";
      };

      reverb = {
        style = mkNullStr "Reverb style: library, dark-bloom, music-club, real-plate, chapel, hockey-arena";
        amount = mkNullInt "Reverb amount (0-100)";
        decay = mkNullInt "Reverb decay (milliseconds)";
        earlyLevel = mkNullInt "Reverb early level (dB)";
        tailLevel = mkNullInt "Reverb tail level (dB)";
        preDelay = mkNullInt "Reverb pre-delay (0-100)";
        lowColour = mkNullInt "Reverb low colour (-50 to 50)";
        highColour = mkNullInt "Reverb high colour (-50 to 50)";
        highFactor = mkNullInt "Reverb high factor (-25 to 25)";
        diffuse = mkNullInt "Reverb diffuse level (-50 to 50)";
        modSpeed = mkNullInt "Reverb mod speed (-25 to 25)";
        modDepth = mkNullInt "Reverb mod depth (-25 to 25)";
      };

      echo = {
        style = mkNullStr "Echo style: quarter, eighth, triplet, ping-pong, classic-slap, multi-tap";
        amount = mkNullInt "Echo amount (0-100)";
        feedback = mkNullInt "Echo feedback (0-100)";
        tempo = mkNullInt "Echo tempo in ms (only for ClassicSlap style)";
        delayLeft = mkNullInt "Echo left delay in ms (only for non-ClassicSlap styles)";
        delayRight = mkNullInt "Echo right delay in ms (only for non-ClassicSlap styles)";
        feedbackXFBLtoR = mkNullInt "Echo cross-feedback left to right (0-100)";
        feedbackXFBRtoL = mkNullInt "Echo cross-feedback right to left (0-100)";
      };

      pitch = {
        style = mkNullStr "Pitch style: narrow, wide";
        amount = mkNullInt "Pitch amount (-24 to 24)";
        character = mkNullInt "Pitch character (0-100)";
      };

      gender = {
        style = mkNullStr "Gender style: narrow, medium, wide";
        amount = mkNullInt "Gender amount (-12 to 12)";
      };

      megaphone = {
        style = mkNullStr "Megaphone style: megaphone, radio, on-the-phone, overdrive, buzz-cutt, tweed, hi-fi, television";
        amount = mkNullInt "Megaphone amount (0-100)";
        postGain = mkNullInt "Megaphone post-processing gain (dB)";
        enabled = mkNullBool "Enable or disable the megaphone button";
      };

      robot = {
        style = mkNullStr "Robot style: robot1, robot2, robot3";
        ranges = lib.mkOption {
          type = lib.types.attrsOf robotRangeSubmodule;
          default = { };
          example = {
            low = {
              gain = 5;
              frequency = 40;
              bandwidth = 20;
            };
            medium = {
              gain = 3;
            };
            high = {
              gain = -2;
            };
          };
          description = "Per-range robot settings. Keys: low, medium, high.";
        };
        waveform = mkNullInt "Robot waveform (0-255)";
        pulseWidth = mkNullInt "Robot pulse width (0-100)";
        threshold = mkNullInt "Robot activation threshold (dB)";
        dryMix = mkNullInt "Robot dry mix (dB)";
        enabled = mkNullBool "Enable or disable the robot button";
      };

      hardTune = {
        style = mkNullStr "HardTune style: natural, medium, hard";
        amount = mkNullInt "HardTune amount (0-100)";
        rate = mkNullInt "HardTune rate (0-100)";
        window = mkNullInt "HardTune window (0-600)";
        source = mkNullStr "HardTune source: all, music, game, line-in, system";
        enabled = mkNullBool "Enable or disable the hard-tune button";
      };
    };

    # --- Sampler ---
    sampler = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf samplerButtonSubmodule);
      default = { };
      example = {
        SamplerA = {
          TopLeft = {
            files = [ "/path/to/sound.wav" ];
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
      };
      description = "Sampler configuration. First key is bank (SamplerA, SamplerB, SamplerC), second key is button (TopLeft, TopRight, BottomLeft, BottomRight). Keys use PascalCase in config and are converted to CLI format automatically. Playback modes/orders also use PascalCase (PlayNext, PlayStop, Sequential, Random, etc.).";
    };

    # --- Cough button ---
    coughButton = {
      isHold = mkNullBool "Whether cough button only mutes while held (not toggled)";
      muteBehaviour = mkNullStr "Where a press mutes to: all, to-stream, to-voice-chat, to-phones, to-line-out";
      muteState = mkNullStr "Cough button mute state: unmuted, muted-to-x, muted-to-all";
    };

    # --- Bleep button ---
    bleepVolume = mkNullInt "Bleep button volume (0-100)";

    # --- Device settings ---
    settings = {
      muteHoldDuration = mkNullInt "How long to hold a mute button (ms) before it mutes to all";
      samplePreRecordBuffer = mkNullInt "How far in the past (ms) the sampler should listen for audio";
      monitorWithFx = mkNullBool "Enable mic monitoring when FX are enabled";
      deafenOnChatMute = mkNullBool "Whether to mute the microphone when voice chat is muted";
      lockFaders = mkNullBool "Lock faders to their current value on mute-to-all";
    };

    # --- Lighting ---
    lighting = {
      global = mkNullStr "Global colour in hex [RRGGBB]";

      animation = {
        mode = mkNullStr "Animation mode: none, retro-rainbow, rainbow-dark, rainbow-bright, simple, ripple";
        mod1 = mkNullInt "Animation mod1 value (0-255)";
        mod2 = mkNullInt "Animation mod2 value (0-255)";
        waterfall = mkNullStr "Waterfall direction: down, up, off";
      };

      fadersAll = {
        display = mkNullStr "Display style for all faders: two-colour, gradient, meter, gradient-meter";
        top = mkNullStr "Top colour for all faders [RRGGBB]";
        bottom = mkNullStr "Bottom colour for all faders [RRGGBB]";
      };

      faders = lib.mkOption {
        type = lib.types.attrsOf faderLightingSubmodule;
        default = { };
        example = {
          a = {
            top = "00FFFF";
            bottom = "000000";
            display = "two-colour";
          };
        };
        description = "Per-fader lighting. Keys: a, b, c, d.";
      };

      buttons = lib.mkOption {
        type = lib.types.attrsOf buttonLightingSubmodule;
        default = { };
        description = "Per-button lighting. Keys are button names (e.g., fader1-mute, effect-select1, cough, etc.).";
      };

      buttonGroups = lib.mkOption {
        type = lib.types.attrsOf buttonLightingSubmodule;
        default = { };
        example = {
          fader-mute = {
            colour = "FF0000";
            offStyle = "dimmed";
          };
        };
        description = "Lighting for groups of buttons. Keys are group names (e.g., fader-mute, effect-selector, effect-types).";
      };

      simple = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Simple (one-colour) lighting targets. Map target name to hex colour.";
      };

      encoders = lib.mkOption {
        type = lib.types.attrsOf encoderLightingSubmodule;
        default = { };
        description = "Encoder lighting. Keys are encoder names (e.g., reverb, echo, pitch, gender).";
      };
    };

    # --- Extra commands ---
    extraCommands = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "goxlr-client effects reverb style library"
      ];
      description = "Additional raw goxlr-client commands to run after all declarative settings are applied.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.all (v: v >= 0 && v <= 100) (builtins.attrValues cfg.volumes);
        message = "All GoXLR volume values must be between 0 and 100 (percent)";
      }
      {
        assertion = builtins.all (v: v >= 0 && v <= 100) (builtins.attrValues cfg.submix.volumes);
        message = "All GoXLR submix volume values must be between 0 and 100 (percent)";
      }
    ];

    systemd.user.services.goxlr-apply = lib.mkIf (allCmds != [ ]) {
      Unit = {
        Description = "Apply declarative GoXLR mixer state";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${applyScript}";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
