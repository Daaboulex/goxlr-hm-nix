#!/usr/bin/env bash
# Usage: bash export-config.sh > goxlr-config.nix
# Reads current GoXLR state and generates Nix Home Manager config.
# Requires: goxlr-client, jq
#
# The output is valid Nix that can be pasted under a host config's
# programs.goxlr = { ... }; block.  Volumes are converted from the
# internal 0-255 range to 0-100 percent.  PascalCase names from the
# JSON status are converted to kebab-case for the Nix module options.

set -euo pipefail

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------
for cmd in goxlr-client jq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: $cmd is required but not found in PATH" >&2
    exit 1
  fi
done

STATUS=$(goxlr-client --status-json 2>/dev/null) || {
  echo "Error: goxlr-client --status-json failed. Is the daemon running?" >&2
  exit 1
}

# Pick the first (usually only) mixer
MIXER=$(echo "$STATUS" | jq -r '.mixers | to_entries[0].value')
if [ "$MIXER" = "null" ] || [ -z "$MIXER" ]; then
  echo "Error: no mixer found in status JSON" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Helper: PascalCase / CamelCase → kebab-case
# e.g. BroadcastMix → broadcast-mix, MicMonitor → mic-monitor
# Also handles single words: Mic → mic, Chat → chat
# And numeric suffixes: StreamMix2 → stream-mix2
# ---------------------------------------------------------------------------
to_kebab() {
  echo "$1" | sed -E '
    s/([a-z0-9])([A-Z])/\1-\2/g
    s/([A-Z]+)([A-Z][a-z])/\1-\2/g
  ' | tr '[:upper:]' '[:lower:]'
}

# ---------------------------------------------------------------------------
# Helper: convert volume 0-255 → 0-100 (rounded)
# ---------------------------------------------------------------------------
vol_percent() {
  local raw="$1"
  echo $(((raw * 100 + 127) / 255))
}

# ---------------------------------------------------------------------------
# Enum lookup tables  (JSON integer index → CLI string)
# Built from `goxlr-client microphone noise-gate attack --help` etc.
# ---------------------------------------------------------------------------
GATE_TIMES=(
  gate10ms gate20ms gate30ms gate40ms gate50ms gate60ms gate70ms gate80ms
  gate90ms gate100ms gate110ms gate120ms gate130ms gate140ms gate150ms
  gate160ms gate170ms gate180ms gate190ms gate200ms gate250ms gate300ms
  gate350ms gate400ms gate450ms gate500ms gate550ms gate600ms gate650ms
  gate700ms gate750ms gate800ms gate850ms gate900ms gate950ms gate1000ms
  gate1100ms gate1200ms gate1300ms gate1400ms gate1500ms gate1600ms
  gate1700ms gate1800ms gate1900ms gate2000ms
)

COMP_RATIOS=(
  ratio1-0 ratio1-1 ratio1-2 ratio1-4 ratio1-6 ratio1-8
  ratio2-0 ratio2-5 ratio3-2 ratio4-0 ratio5-6 ratio8-0
  ratio16-0 ratio32-0 ratio64-0
)

COMP_ATTACKS=(
  comp0ms comp2ms comp3ms comp4ms comp5ms comp6ms comp7ms comp8ms
  comp9ms comp10ms comp12ms comp14ms comp16ms comp18ms comp20ms
  comp23ms comp26ms comp30ms comp35ms comp40ms
)

COMP_RELEASES=(
  comp0ms comp15ms comp25ms comp35ms comp45ms comp55ms comp65ms comp75ms
  comp85ms comp100ms comp115ms comp140ms comp170ms comp230ms comp340ms
  comp680ms comp1000ms comp1500ms comp2000ms comp3000ms
)

# ---------------------------------------------------------------------------
# Map JSON enum strings to CLI strings
# ---------------------------------------------------------------------------
map_mute_type() {
  case "$1" in
  All) echo "all" ;;
  ToStream) echo "to-stream" ;;
  ToVoiceChat) echo "to-voice-chat" ;;
  ToPhones) echo "to-phones" ;;
  ToLineOut) echo "to-line-out" ;;
  ToStream2) echo "to-stream2" ;;
  ToStreams) echo "to-streams" ;;
  *) echo "all" ;;
  esac
}

map_mute_state() {
  case "$1" in
  Unmuted) echo "unmuted" ;;
  MutedToX) echo "muted-to-x" ;;
  MutedToAll) echo "muted-to-all" ;;
  *) echo "unmuted" ;;
  esac
}

map_animation_mode() {
  case "$1" in
  None) echo "none" ;;
  RetroRainbow) echo "retro-rainbow" ;;
  RainbowDark) echo "rainbow-dark" ;;
  RainbowBright) echo "rainbow-bright" ;;
  Simple) echo "simple" ;;
  Ripple) echo "ripple" ;;
  *) echo "none" ;;
  esac
}

map_waterfall() {
  case "$1" in
  Down) echo "down" ;;
  Up) echo "up" ;;
  Off) echo "off" ;;
  *) echo "down" ;;
  esac
}

map_fader_display() {
  case "$1" in
  TwoColour) echo "two-colour" ;;
  Gradient) echo "gradient" ;;
  Meter) echo "meter" ;;
  GradientMeter) echo "gradient-meter" ;;
  *) echo "two-colour" ;;
  esac
}

map_button_off_style() {
  case "$1" in
  Dimmed) echo "dimmed" ;;
  Colour2) echo "colour2" ;;
  DimmedColour2) echo "dimmed-colour2" ;;
  *) echo "dimmed" ;;
  esac
}

# Map JSON button names to CLI button names
map_button_name() {
  case "$1" in
  Fader1Mute) echo "fader1-mute" ;;
  Fader2Mute) echo "fader2-mute" ;;
  Fader3Mute) echo "fader3-mute" ;;
  Fader4Mute) echo "fader4-mute" ;;
  Bleep) echo "bleep" ;;
  Cough) echo "cough" ;;
  EffectSelect1) echo "effect-select1" ;;
  EffectSelect2) echo "effect-select2" ;;
  EffectSelect3) echo "effect-select3" ;;
  EffectSelect4) echo "effect-select4" ;;
  EffectSelect5) echo "effect-select5" ;;
  EffectSelect6) echo "effect-select6" ;;
  EffectFx) echo "effect-fx" ;;
  EffectMegaphone) echo "effect-megaphone" ;;
  EffectRobot) echo "effect-robot" ;;
  EffectHardTune) echo "effect-hard-tune" ;;
  SamplerSelectA) echo "sampler-select-a" ;;
  SamplerSelectB) echo "sampler-select-b" ;;
  SamplerSelectC) echo "sampler-select-c" ;;
  SamplerTopLeft) echo "sampler-top-left" ;;
  SamplerTopRight) echo "sampler-top-right" ;;
  SamplerBottomLeft) echo "sampler-bottom-left" ;;
  SamplerBottomRight) echo "sampler-bottom-right" ;;
  SamplerClear) echo "sampler-clear" ;;
  *) to_kebab "$1" ;;
  esac
}

# Map JSON simple lighting target names to CLI names
map_simple_target() {
  case "$1" in
  Global) echo "global" ;;
  Accent) echo "accent" ;;
  *) to_kebab "$1" ;;
  esac
}

# Map JSON encoder names to CLI names
map_encoder_name() {
  case "$1" in
  Reverb) echo "reverb" ;;
  Echo) echo "echo" ;;
  Pitch) echo "pitch" ;;
  Gender) echo "gender" ;;
  *) to_kebab "$1" ;;
  esac
}

# Map JSON channel name to Nix config channel name
map_channel() {
  case "$1" in
  Mic) echo "mic" ;;
  LineIn) echo "line-in" ;;
  Console) echo "console" ;;
  System) echo "system" ;;
  Game) echo "game" ;;
  Chat) echo "chat" ;;
  Sample) echo "sample" ;;
  Music) echo "music" ;;
  Headphones) echo "headphones" ;;
  MicMonitor) echo "mic-monitor" ;;
  LineOut) echo "line-out" ;;
  *) to_kebab "$1" ;;
  esac
}

# Map JSON routing input name to CLI input name
map_router_input() {
  case "$1" in
  Microphone) echo "microphone" ;;
  Chat) echo "chat" ;;
  Music) echo "music" ;;
  Game) echo "game" ;;
  Console) echo "console" ;;
  LineIn) echo "line-in" ;;
  System) echo "system" ;;
  Samples) echo "samples" ;;
  *) to_kebab "$1" ;;
  esac
}

# Map JSON routing output name to CLI output name
map_router_output() {
  case "$1" in
  Headphones) echo "headphones" ;;
  BroadcastMix) echo "broadcast-mix" ;;
  ChatMic) echo "chat-mic" ;;
  Sampler) echo "sampler" ;;
  LineOut) echo "line-out" ;;
  StreamMix2) echo "stream-mix2" ;;
  *) to_kebab "$1" ;;
  esac
}

# ---------------------------------------------------------------------------
# Begin output
# ---------------------------------------------------------------------------
echo "# Generated by export-config.sh on $(date -Iseconds)"
echo "# Paste this under: programs.goxlr = { ... };"
echo "{"
echo "  enable = true;"
echo ""

# ---------------------------------------------------------------------------
# Volumes
# ---------------------------------------------------------------------------
echo "  # Channel volumes (0-100 percent)"
echo "  volumes = {"
echo "$MIXER" | jq -r '.levels.volumes | to_entries[] | "\(.key) \(.value)"' | while read -r ch val; do
  nix_ch=$(map_channel "$ch")
  pct=$(vol_percent "$val")
  echo "    ${nix_ch} = ${pct};"
done
echo "  };"
echo ""

# ---------------------------------------------------------------------------
# Fader assignments
# ---------------------------------------------------------------------------
echo "  # Fader → channel assignments"
echo "  faders = {"
for f in A B C D; do
  ch=$(echo "$MIXER" | jq -r ".fader_status.${f}.channel")
  nix_f=$(echo "$f" | tr '[:upper:]' '[:lower:]')
  nix_ch=$(map_channel "$ch")
  echo "    ${nix_f} = \"${nix_ch}\";"
done
echo "  };"
echo ""

# ---------------------------------------------------------------------------
# Fader mute behaviour
# ---------------------------------------------------------------------------
echo "  # Fader mute behaviour (single-press target)"
echo "  faderMuteBehaviour = {"
for f in A B C D; do
  mt=$(echo "$MIXER" | jq -r ".fader_status.${f}.mute_type")
  nix_f=$(echo "$f" | tr '[:upper:]' '[:lower:]')
  nix_mt=$(map_mute_type "$mt")
  echo "    ${nix_f} = \"${nix_mt}\";"
done
echo "  };"
echo ""

# ---------------------------------------------------------------------------
# Routing matrix
# ---------------------------------------------------------------------------
echo "  # Audio routing matrix"
echo "  routing = {"
echo "$MIXER" | jq -r '.router | to_entries[] | .key' | while read -r input; do
  nix_input=$(map_router_input "$input")
  echo "    ${nix_input} = {"
  echo "$MIXER" | jq -r ".router.\"${input}\" | to_entries[] | \"\(.key) \(.value)\"" | while read -r output enabled; do
    nix_output=$(map_router_output "$output")
    echo "      ${nix_output} = ${enabled};"
  done
  echo "    };"
done
echo "  };"
echo ""

# ---------------------------------------------------------------------------
# Microphone settings
# ---------------------------------------------------------------------------
echo "  # Microphone settings"
echo "  microphone = {"

# Gains
dyn_gain=$(echo "$MIXER" | jq -r '.mic_status.mic_gains.Dynamic')
con_gain=$(echo "$MIXER" | jq -r '.mic_status.mic_gains.Condenser')
jack_gain=$(echo "$MIXER" | jq -r '.mic_status.mic_gains.Jack')
echo "    dynamicGain = ${dyn_gain};"
echo "    condenserGain = ${con_gain};"
echo "    jackGain = ${jack_gain};"
echo ""

# De-ess
deess=$(echo "$MIXER" | jq -r '.levels.deess')
echo "    deEss = ${deess};"
echo ""

# Gate
echo "    # Noise gate"
echo "    gate = {"
gate_threshold=$(echo "$MIXER" | jq -r '.mic_status.noise_gate.threshold')
gate_atten=$(echo "$MIXER" | jq -r '.mic_status.noise_gate.attenuation')
gate_attack_idx=$(echo "$MIXER" | jq -r '.mic_status.noise_gate.attack')
gate_release_idx=$(echo "$MIXER" | jq -r '.mic_status.noise_gate.release')
gate_enabled=$(echo "$MIXER" | jq -r '.mic_status.noise_gate.enabled')
echo "      threshold = ${gate_threshold};"
echo "      attenuation = ${gate_atten};"
echo "      attack = \"${GATE_TIMES[$gate_attack_idx]}\";"
echo "      release = \"${GATE_TIMES[$gate_release_idx]}\";"
echo "      active = ${gate_enabled};"
echo "    };"
echo ""

# Compressor
echo "    # Compressor"
echo "    compressor = {"
comp_threshold=$(echo "$MIXER" | jq -r '.mic_status.compressor.threshold')
comp_ratio_idx=$(echo "$MIXER" | jq -r '.mic_status.compressor.ratio')
comp_attack_idx=$(echo "$MIXER" | jq -r '.mic_status.compressor.attack')
comp_release_idx=$(echo "$MIXER" | jq -r '.mic_status.compressor.release')
comp_makeup=$(echo "$MIXER" | jq -r '.mic_status.compressor.makeup_gain')
echo "      threshold = ${comp_threshold};"
echo "      ratio = \"${COMP_RATIOS[$comp_ratio_idx]}\";"
echo "      attack = \"${COMP_ATTACKS[$comp_attack_idx]}\";"
echo "      release = \"${COMP_RELEASES[$comp_release_idx]}\";"
echo "      makeUp = ${comp_makeup};"
echo "    };"

echo "  };"
echo ""

# ---------------------------------------------------------------------------
# Submix settings
# ---------------------------------------------------------------------------
submix_data=$(echo "$MIXER" | jq -r '.levels.submix')
if [ "$submix_data" != "null" ]; then
  submix_enabled=$(echo "$submix_data" | jq -r '.enabled // empty' 2>/dev/null || true)

  echo "  # Submix settings"
  echo "  submix = {"

  if [ -n "$submix_enabled" ]; then
    echo "    enabled = ${submix_enabled};"
  else
    echo "    enabled = true;"
  fi

  # Submix volumes
  submix_vols=$(echo "$submix_data" | jq -r '.volume // empty' 2>/dev/null || true)
  if [ -n "$submix_vols" ] && [ "$submix_vols" != "null" ]; then
    echo "    volumes = {"
    echo "$submix_data" | jq -r '.volume | to_entries[] | "\(.key) \(.value)"' 2>/dev/null | while read -r ch val; do
      nix_ch=$(map_channel "$ch")
      pct=$(vol_percent "$val")
      echo "      ${nix_ch} = ${pct};"
    done
    echo "    };"
  fi

  # Submix linked
  submix_linked=$(echo "$submix_data" | jq -r '.linked // empty' 2>/dev/null || true)
  if [ -n "$submix_linked" ] && [ "$submix_linked" != "null" ]; then
    echo "    linked = {"
    echo "$submix_data" | jq -r '.linked | to_entries[] | "\(.key) \(.value)"' 2>/dev/null | while read -r ch val; do
      nix_ch=$(map_channel "$ch")
      echo "      ${nix_ch} = ${val};"
    done
    echo "    };"
  fi

  # Submix output mix
  submix_mix=$(echo "$submix_data" | jq -r '.mix // empty' 2>/dev/null || true)
  if [ -n "$submix_mix" ] && [ "$submix_mix" != "null" ]; then
    echo "    outputMix = {"
    echo "$submix_data" | jq -r '.mix | to_entries[] | "\(.key) \(.value)"' 2>/dev/null | while read -r dev mix; do
      nix_dev=$(map_router_output "$dev")
      nix_mix=$(echo "$mix" | tr '[:upper:]' '[:lower:]')
      echo "      ${nix_dev} = \"${nix_mix}\";"
    done
    echo "    };"
  fi

  echo "  };"
  echo ""
fi

# ---------------------------------------------------------------------------
# Cough button
# ---------------------------------------------------------------------------
echo "  # Cough button"
echo "  coughButton = {"
cough_toggle=$(echo "$MIXER" | jq -r '.cough_button.is_toggle')
cough_mute=$(echo "$MIXER" | jq -r '.cough_button.mute_type')
# is_toggle=false means it's a hold button; isHold is the inverse
if [ "$cough_toggle" = "true" ]; then
  echo "    isHold = false;"
else
  echo "    isHold = true;"
fi
echo "    muteBehaviour = \"$(map_mute_type "$cough_mute")\";"
echo "  };"
echo ""

# ---------------------------------------------------------------------------
# Bleep volume
# ---------------------------------------------------------------------------
bleep_raw=$(echo "$MIXER" | jq -r '.levels.bleep')
bleep_pct=$(vol_percent "$bleep_raw")
echo "  # Bleep button volume"
echo "  bleepVolume = ${bleep_pct};"
echo ""

# ---------------------------------------------------------------------------
# Lighting
# ---------------------------------------------------------------------------
echo "  # Lighting"
echo "  lighting = {"

# Animation
echo "    animation = {"
anim_mode=$(echo "$MIXER" | jq -r '.lighting.animation.mode')
anim_mod1=$(echo "$MIXER" | jq -r '.lighting.animation.mod1')
anim_mod2=$(echo "$MIXER" | jq -r '.lighting.animation.mod2')
anim_wf=$(echo "$MIXER" | jq -r '.lighting.animation.waterfall_direction')
echo "      mode = \"$(map_animation_mode "$anim_mode")\";"
echo "      mod1 = ${anim_mod1};"
echo "      mod2 = ${anim_mod2};"
echo "      waterfall = \"$(map_waterfall "$anim_wf")\";"
echo "    };"
echo ""

# Fader lighting
echo "    # Per-fader lighting"
echo "    faders = {"
for f in A B C D; do
  nix_f=$(echo "$f" | tr '[:upper:]' '[:lower:]')
  style=$(echo "$MIXER" | jq -r ".lighting.faders.${f}.style // empty")
  c1=$(echo "$MIXER" | jq -r ".lighting.faders.${f}.colours.colour_one // empty")
  c2=$(echo "$MIXER" | jq -r ".lighting.faders.${f}.colours.colour_two // empty")
  if [ -n "$style" ]; then
    echo "      ${nix_f} = {"
    echo "        top = \"${c1}\";"
    echo "        bottom = \"${c2}\";"
    echo "        display = \"$(map_fader_display "$style")\";"
    echo "      };"
  fi
done
echo "    };"
echo ""

# Button lighting
echo "    # Per-button lighting"
echo "    buttons = {"
echo "$MIXER" | jq -r '.lighting.buttons | to_entries[] | .key' | while read -r btn; do
  nix_btn=$(map_button_name "$btn")
  c1=$(echo "$MIXER" | jq -r ".lighting.buttons.\"${btn}\".colours.colour_one // empty")
  c2=$(echo "$MIXER" | jq -r ".lighting.buttons.\"${btn}\".colours.colour_two // empty")
  off=$(echo "$MIXER" | jq -r ".lighting.buttons.\"${btn}\".off_style // empty")
  echo "      \"${nix_btn}\" = {"
  echo "        colour = \"${c1}\";"
  if [ -n "$c2" ]; then
    echo "        colour2 = \"${c2}\";"
  fi
  if [ -n "$off" ]; then
    echo "        offStyle = \"$(map_button_off_style "$off")\";"
  fi
  echo "      };"
done
echo "    };"
echo ""

# Encoder lighting
encoder_count=$(echo "$MIXER" | jq -r '.lighting.encoders | length')
if [ "$encoder_count" -gt 0 ]; then
  echo "    # Encoder lighting"
  echo "    encoders = {"
  echo "$MIXER" | jq -r '.lighting.encoders | to_entries[] | .key' | while read -r enc; do
    nix_enc=$(map_encoder_name "$enc")
    c1=$(echo "$MIXER" | jq -r ".lighting.encoders.\"${enc}\".colours.colour_one // empty")
    c2=$(echo "$MIXER" | jq -r ".lighting.encoders.\"${enc}\".colours.colour_two // empty")
    c3=$(echo "$MIXER" | jq -r ".lighting.encoders.\"${enc}\".colours.colour_three // empty")
    echo "      ${nix_enc} = {"
    echo "        colour1 = \"${c1}\";"
    echo "        colour2 = \"${c2}\";"
    echo "        colour3 = \"${c3}\";"
    echo "      };"
  done
  echo "    };"
  echo ""
fi

# Simple lighting
simple_count=$(echo "$MIXER" | jq -r '.lighting.simple | length')
if [ "$simple_count" -gt 0 ]; then
  echo "    # Simple (single-colour) lighting"
  echo "    simple = {"
  echo "$MIXER" | jq -r '.lighting.simple | to_entries[] | .key' | while read -r tgt; do
    nix_tgt=$(map_simple_target "$tgt")
    colour=$(echo "$MIXER" | jq -r ".lighting.simple.\"${tgt}\".colour_one // empty")
    echo "      ${nix_tgt} = \"${colour}\";"
  done
  echo "    };"
fi

echo "  };"
echo "}"
