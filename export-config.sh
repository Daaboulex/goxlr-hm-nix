#!/usr/bin/env bash
# Usage: bash export-config.sh [OPTIONS] > goxlr-config.nix
# Reads current GoXLR state and generates Nix Home Manager config.
# Requires: goxlr-client, jq
#
# Options:
#   --all-profiles    Export every device profile and mic profile
#   --profile <name>  Export a specific device profile by name
#   -h, --help        Show this help message
#
# The output is valid Nix that can be pasted under a host config's
# programs.goxlr = { ... }; block.  Volumes are converted from the
# internal 0-255 range to 0-100 percent.  PascalCase names from the
# JSON status are converted to kebab-case for the Nix module options.
#
# GoXLR Full vs Mini:
#   Full-only features (effects, sampler, scribbles, encoder lighting)
#   are exported when present and skipped when the device is a Mini.

set -euo pipefail

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
MODE="current" # current | all | single
TARGET_PROFILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
  --all-profiles)
    MODE="all"
    shift
    ;;
  --profile)
    MODE="single"
    if [[ $# -lt 2 ]]; then
      echo "Error: --profile requires a profile name argument" >&2
      exit 1
    fi
    TARGET_PROFILE="$2"
    shift 2
    ;;
  -h | --help)
    head -n 14 "$0" | tail -n +2 | sed 's/^# \?//'
    exit 0
    ;;
  *)
    echo "Error: unknown option '$1' (try --help)" >&2
    exit 1
    ;;
  esac
done

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
MIXER_KEY=$(echo "$STATUS" | jq -r '.mixers | to_entries[0].key')
MIXER=$(echo "$STATUS" | jq -r '.mixers | to_entries[0].value')
if [ "$MIXER" = "null" ] || [ -z "$MIXER" ]; then
  echo "Error: no mixer found in status JSON" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Profile discovery
# ---------------------------------------------------------------------------
ORIG_PROFILE=$(echo "$MIXER" | jq -r '.profile_name')
ORIG_MIC_PROFILE=$(echo "$MIXER" | jq -r '.mic_profile_name')

# Read available profiles from top-level .files
readarray -t PROFILES < <(echo "$STATUS" | jq -r '.files.profiles[]' 2>/dev/null)
readarray -t MIC_PROFILES < <(echo "$STATUS" | jq -r '.files.mic_profiles[]' 2>/dev/null)

# Validate --profile target exists
if [ "$MODE" = "single" ]; then
  found=false
  for p in "${PROFILES[@]}"; do
    if [ "$p" = "$TARGET_PROFILE" ]; then
      found=true
      break
    fi
  done
  if [ "$found" = "false" ]; then
    echo "Error: profile '${TARGET_PROFILE}' not found." >&2
    echo "Available profiles: ${PROFILES[*]}" >&2
    exit 1
  fi
fi

# ---------------------------------------------------------------------------
# Cleanup trap — always restore original profiles on exit
# ---------------------------------------------------------------------------
NEEDS_RESTORE=false

cleanup() {
  if [ "$NEEDS_RESTORE" = "true" ]; then
    goxlr-client profiles device load "$ORIG_PROFILE" 2>/dev/null || true
    sleep 0.5
    goxlr-client profiles microphone load "$ORIG_MIC_PROFILE" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Re-read mixer state from daemon
# ---------------------------------------------------------------------------
refresh_mixer() {
  local st
  st=$(goxlr-client --status-json 2>/dev/null) || {
    echo "Error: failed to re-read status after profile switch" >&2
    return 1
  }
  MIXER=$(echo "$st" | jq -r '.mixers | to_entries[0].value')
}

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
# Output: microphone section only (for mic-profile iteration)
# ---------------------------------------------------------------------------
emit_microphone_section() {
  local prefix="$1" # line prefix (e.g. "  " or "# ")

  # Gains
  local dyn_gain con_gain jack_gain deess
  dyn_gain=$(echo "$MIXER" | jq -r '.mic_status.mic_gains.Dynamic')
  con_gain=$(echo "$MIXER" | jq -r '.mic_status.mic_gains.Condenser')
  jack_gain=$(echo "$MIXER" | jq -r '.mic_status.mic_gains.Jack')
  echo "${prefix}  # Microphone settings"
  echo "${prefix}  microphone = {"
  echo "${prefix}    dynamicGain = ${dyn_gain};"
  echo "${prefix}    condenserGain = ${con_gain};"
  echo "${prefix}    jackGain = ${jack_gain};"
  echo "${prefix}"

  # De-ess
  deess=$(echo "$MIXER" | jq -r '.levels.deess')
  echo "${prefix}    deEss = ${deess};"
  echo "${prefix}"

  # Gate
  local gate_threshold gate_atten gate_attack_idx gate_release_idx gate_enabled
  gate_threshold=$(echo "$MIXER" | jq -r '.mic_status.noise_gate.threshold')
  gate_atten=$(echo "$MIXER" | jq -r '.mic_status.noise_gate.attenuation')
  gate_attack_idx=$(echo "$MIXER" | jq -r '.mic_status.noise_gate.attack')
  gate_release_idx=$(echo "$MIXER" | jq -r '.mic_status.noise_gate.release')
  gate_enabled=$(echo "$MIXER" | jq -r '.mic_status.noise_gate.enabled')
  echo "${prefix}    # Noise gate"
  echo "${prefix}    gate = {"
  echo "${prefix}      threshold = ${gate_threshold};"
  echo "${prefix}      attenuation = ${gate_atten};"
  echo "${prefix}      attack = \"${GATE_TIMES[$gate_attack_idx]}\";"
  echo "${prefix}      release = \"${GATE_TIMES[$gate_release_idx]}\";"
  echo "${prefix}      active = ${gate_enabled};"
  echo "${prefix}    };"
  echo "${prefix}"

  # Compressor
  local comp_threshold comp_ratio_idx comp_attack_idx comp_release_idx comp_makeup
  comp_threshold=$(echo "$MIXER" | jq -r '.mic_status.compressor.threshold')
  comp_ratio_idx=$(echo "$MIXER" | jq -r '.mic_status.compressor.ratio')
  comp_attack_idx=$(echo "$MIXER" | jq -r '.mic_status.compressor.attack')
  comp_release_idx=$(echo "$MIXER" | jq -r '.mic_status.compressor.release')
  comp_makeup=$(echo "$MIXER" | jq -r '.mic_status.compressor.makeup_gain')
  echo "${prefix}    # Compressor"
  echo "${prefix}    compressor = {"
  echo "${prefix}      threshold = ${comp_threshold};"
  echo "${prefix}      ratio = \"${COMP_RATIOS[$comp_ratio_idx]}\";"
  echo "${prefix}      attack = \"${COMP_ATTACKS[$comp_attack_idx]}\";"
  echo "${prefix}      release = \"${COMP_RELEASES[$comp_release_idx]}\";"
  echo "${prefix}      makeUp = ${comp_makeup};"
  echo "${prefix}    };"

  echo "${prefix}  };"
}

# ---------------------------------------------------------------------------
# Output: full profile config block
# Arg 1: line prefix ("" for active, "# " for commented-out)
# ---------------------------------------------------------------------------
emit_full_profile() {
  local prefix="$1"
  local profile_name mic_profile_name
  profile_name=$(echo "$MIXER" | jq -r '.profile_name')
  mic_profile_name=$(echo "$MIXER" | jq -r '.mic_profile_name')

  echo "${prefix}{"
  echo "${prefix}  enable = true;"
  echo "${prefix}  profile = \"${profile_name}\";"
  echo "${prefix}  micProfile = \"${mic_profile_name}\";"
  echo "${prefix}"

  # Volumes
  echo "${prefix}  # Channel volumes (0-100 percent)"
  echo "${prefix}  volumes = {"
  echo "$MIXER" | jq -r '.levels.volumes | to_entries[] | "\(.key) \(.value)"' | while read -r ch val; do
    local nix_ch pct
    nix_ch=$(map_channel "$ch")
    pct=$(vol_percent "$val")
    echo "${prefix}    ${nix_ch} = ${pct};"
  done
  echo "${prefix}  };"
  echo "${prefix}"

  # Fader assignments
  echo "${prefix}  # Fader -> channel assignments"
  echo "${prefix}  faders = {"
  for f in A B C D; do
    local ch nix_f nix_ch
    ch=$(echo "$MIXER" | jq -r ".fader_status.${f}.channel")
    nix_f=$(echo "$f" | tr '[:upper:]' '[:lower:]')
    nix_ch=$(map_channel "$ch")
    echo "${prefix}    ${nix_f} = \"${nix_ch}\";"
  done
  echo "${prefix}  };"
  echo "${prefix}"

  # Fader mute behaviour
  echo "${prefix}  # Fader mute behaviour (single-press target)"
  echo "${prefix}  faderMuteBehaviour = {"
  for f in A B C D; do
    local mt nix_f nix_mt
    mt=$(echo "$MIXER" | jq -r ".fader_status.${f}.mute_type")
    nix_f=$(echo "$f" | tr '[:upper:]' '[:lower:]')
    nix_mt=$(map_mute_type "$mt")
    echo "${prefix}    ${nix_f} = \"${nix_mt}\";"
  done
  echo "${prefix}  };"
  echo "${prefix}"

  # Routing matrix
  echo "${prefix}  # Audio routing matrix"
  echo "${prefix}  routing = {"
  echo "$MIXER" | jq -r '.router | to_entries[] | .key' | while read -r input; do
    local nix_input
    nix_input=$(map_router_input "$input")
    echo "${prefix}    ${nix_input} = {"
    echo "$MIXER" | jq -r ".router.\"${input}\" | to_entries[] | \"\(.key) \(.value)\"" | while read -r output enabled; do
      local nix_output
      nix_output=$(map_router_output "$output")
      echo "${prefix}      ${nix_output} = ${enabled};"
    done
    echo "${prefix}    };"
  done
  echo "${prefix}  };"
  echo "${prefix}"

  # Microphone settings
  emit_microphone_section "$prefix"
  echo "${prefix}"

  # Submix settings
  local submix_supported submix_data
  submix_supported=$(echo "$MIXER" | jq -r '.levels.submix_supported')
  submix_data=$(echo "$MIXER" | jq -r '.levels.submix')
  if [ "$submix_supported" = "true" ] && [ "$submix_data" != "null" ]; then
    local has_inputs
    has_inputs=$(echo "$submix_data" | jq -r '.inputs | length' 2>/dev/null || echo "0")

    echo "${prefix}  # Submix settings"
    echo "${prefix}  submix = {"

    if [ "$has_inputs" -gt 0 ]; then
      echo "${prefix}    enabled = true;"
    else
      echo "${prefix}    enabled = false;"
    fi

    # Submix volumes (from .inputs[].volume)
    if [ "$has_inputs" -gt 0 ]; then
      echo "${prefix}    volumes = {"
      echo "$submix_data" | jq -r '.inputs | to_entries[] | "\(.key) \(.value.volume)"' 2>/dev/null | while read -r ch val; do
        local nix_ch pct
        nix_ch=$(map_channel "$ch")
        pct=$(vol_percent "$val")
        echo "${prefix}      ${nix_ch} = ${pct};"
      done
      echo "${prefix}    };"

      # Submix linked (from .inputs[].linked)
      echo "${prefix}    linked = {"
      echo "$submix_data" | jq -r '.inputs | to_entries[] | "\(.key) \(.value.linked)"' 2>/dev/null | while read -r ch val; do
        local nix_ch
        nix_ch=$(map_channel "$ch")
        echo "${prefix}      ${nix_ch} = ${val};"
      done
      echo "${prefix}    };"
    fi

    # Submix output mix (from .outputs)
    local submix_outputs
    submix_outputs=$(echo "$submix_data" | jq -r '.outputs // empty' 2>/dev/null || true)
    if [ -n "$submix_outputs" ] && [ "$submix_outputs" != "null" ]; then
      echo "${prefix}    outputMix = {"
      echo "$submix_data" | jq -r '.outputs | to_entries[] | "\(.key) \(.value)"' 2>/dev/null | while read -r dev mix; do
        local nix_dev nix_mix
        nix_dev=$(map_router_output "$dev")
        nix_mix=$(echo "$mix" | tr '[:upper:]' '[:lower:]')
        echo "${prefix}      ${nix_dev} = \"${nix_mix}\";"
      done
      echo "${prefix}    };"
    fi

    # Monitor mix output (from .levels.output_monitor)
    local monitor_out
    monitor_out=$(echo "$MIXER" | jq -r '.levels.output_monitor // empty')
    if [ -n "$monitor_out" ] && [ "$monitor_out" != "null" ]; then
      local nix_monitor
      nix_monitor=$(map_channel "$monitor_out")
      echo "${prefix}    monitorMix = \"${nix_monitor}\";"
    fi

    echo "${prefix}  };"
    echo "${prefix}"
  fi

  # Cough button
  local cough_toggle cough_mute
  echo "${prefix}  # Cough button"
  echo "${prefix}  coughButton = {"
  cough_toggle=$(echo "$MIXER" | jq -r '.cough_button.is_toggle')
  cough_mute=$(echo "$MIXER" | jq -r '.cough_button.mute_type')
  if [ "$cough_toggle" = "true" ]; then
    echo "${prefix}    isHold = false;"
  else
    echo "${prefix}    isHold = true;"
  fi
  echo "${prefix}    muteBehaviour = \"$(map_mute_type "$cough_mute")\";"
  echo "${prefix}  };"
  echo "${prefix}"

  # Bleep volume
  local bleep_raw bleep_pct
  bleep_raw=$(echo "$MIXER" | jq -r '.levels.bleep')
  bleep_pct=$(vol_percent "$bleep_raw")
  echo "${prefix}  # Bleep button volume"
  echo "${prefix}  bleepVolume = ${bleep_pct};"
  echo "${prefix}"

  # Lighting
  echo "${prefix}  # Lighting"
  echo "${prefix}  lighting = {"

  # Animation
  local anim_mode anim_mod1 anim_mod2 anim_wf
  echo "${prefix}    animation = {"
  anim_mode=$(echo "$MIXER" | jq -r '.lighting.animation.mode')
  anim_mod1=$(echo "$MIXER" | jq -r '.lighting.animation.mod1')
  anim_mod2=$(echo "$MIXER" | jq -r '.lighting.animation.mod2')
  anim_wf=$(echo "$MIXER" | jq -r '.lighting.animation.waterfall_direction')
  echo "${prefix}      mode = \"$(map_animation_mode "$anim_mode")\";"
  echo "${prefix}      mod1 = ${anim_mod1};"
  echo "${prefix}      mod2 = ${anim_mod2};"
  echo "${prefix}      waterfall = \"$(map_waterfall "$anim_wf")\";"
  echo "${prefix}    };"
  echo "${prefix}"

  # Fader lighting
  echo "${prefix}    # Per-fader lighting"
  echo "${prefix}    faders = {"
  for f in A B C D; do
    local nix_f style c1 c2
    nix_f=$(echo "$f" | tr '[:upper:]' '[:lower:]')
    style=$(echo "$MIXER" | jq -r ".lighting.faders.${f}.style // empty")
    c1=$(echo "$MIXER" | jq -r ".lighting.faders.${f}.colours.colour_one // empty")
    c2=$(echo "$MIXER" | jq -r ".lighting.faders.${f}.colours.colour_two // empty")
    if [ -n "$style" ]; then
      echo "${prefix}      ${nix_f} = {"
      echo "${prefix}        top = \"${c1}\";"
      echo "${prefix}        bottom = \"${c2}\";"
      echo "${prefix}        display = \"$(map_fader_display "$style")\";"
      echo "${prefix}      };"
    fi
  done
  echo "${prefix}    };"
  echo "${prefix}"

  # Button lighting
  echo "${prefix}    # Per-button lighting"
  echo "${prefix}    buttons = {"
  echo "$MIXER" | jq -r '.lighting.buttons | to_entries[] | .key' | while read -r btn; do
    local nix_btn c1 c2 off
    nix_btn=$(map_button_name "$btn")
    c1=$(echo "$MIXER" | jq -r ".lighting.buttons.\"${btn}\".colours.colour_one // empty")
    c2=$(echo "$MIXER" | jq -r ".lighting.buttons.\"${btn}\".colours.colour_two // empty")
    off=$(echo "$MIXER" | jq -r ".lighting.buttons.\"${btn}\".off_style // empty")
    echo "${prefix}      \"${nix_btn}\" = {"
    echo "${prefix}        colour = \"${c1}\";"
    if [ -n "$c2" ]; then
      echo "${prefix}        colour2 = \"${c2}\";"
    fi
    if [ -n "$off" ]; then
      echo "${prefix}        offStyle = \"$(map_button_off_style "$off")\";"
    fi
    echo "${prefix}      };"
  done
  echo "${prefix}    };"
  echo "${prefix}"

  # Encoder lighting
  local encoder_count
  encoder_count=$(echo "$MIXER" | jq -r '.lighting.encoders | length')
  if [ "$encoder_count" -gt 0 ]; then
    echo "${prefix}    # Encoder lighting"
    echo "${prefix}    encoders = {"
    echo "$MIXER" | jq -r '.lighting.encoders | to_entries[] | .key' | while read -r enc; do
      local nix_enc c1 c2 c3
      nix_enc=$(map_encoder_name "$enc")
      c1=$(echo "$MIXER" | jq -r ".lighting.encoders.\"${enc}\".colours.colour_one // empty")
      c2=$(echo "$MIXER" | jq -r ".lighting.encoders.\"${enc}\".colours.colour_two // empty")
      c3=$(echo "$MIXER" | jq -r ".lighting.encoders.\"${enc}\".colours.colour_three // empty")
      echo "${prefix}      ${nix_enc} = {"
      echo "${prefix}        colour1 = \"${c1}\";"
      echo "${prefix}        colour2 = \"${c2}\";"
      echo "${prefix}        colour3 = \"${c3}\";"
      echo "${prefix}      };"
    done
    echo "${prefix}    };"
    echo "${prefix}"
  fi

  # Simple lighting
  local simple_count
  simple_count=$(echo "$MIXER" | jq -r '.lighting.simple | length')
  if [ "$simple_count" -gt 0 ]; then
    echo "${prefix}    # Simple (single-colour) lighting"
    echo "${prefix}    simple = {"
    echo "$MIXER" | jq -r '.lighting.simple | to_entries[] | .key' | while read -r tgt; do
      local nix_tgt colour
      nix_tgt=$(map_simple_target "$tgt")
      colour=$(echo "$MIXER" | jq -r ".lighting.simple.\"${tgt}\".colour_one // empty")
      echo "${prefix}      ${nix_tgt} = \"${colour}\";"
    done
    echo "${prefix}    };"
  fi

  echo "${prefix}  };"
  echo "${prefix}"

  # Settings
  local settings_data
  settings_data=$(echo "$MIXER" | jq -r '.settings // empty')
  if [ -n "$settings_data" ] && [ "$settings_data" != "null" ]; then
    local mute_hold_duration monitor_with_fx deafen_on_chat_mute lock_faders
    mute_hold_duration=$(echo "$MIXER" | jq '.settings.mute_hold_duration')
    monitor_with_fx=$(echo "$MIXER" | jq '.settings.enable_monitor_with_fx')
    deafen_on_chat_mute=$(echo "$MIXER" | jq '.settings.vc_mute_also_mute_cm')
    lock_faders=$(echo "$MIXER" | jq '.settings.lock_faders')

    echo "${prefix}  # Settings"
    echo "${prefix}  settings = {"
    [ "$mute_hold_duration" != "null" ] && echo "${prefix}    muteHoldDuration = ${mute_hold_duration};"
    [ "$monitor_with_fx" != "null" ] && echo "${prefix}    monitorWithFx = ${monitor_with_fx};"
    [ "$deafen_on_chat_mute" != "null" ] && echo "${prefix}    deafenOnChatMute = ${deafen_on_chat_mute};"
    [ "$lock_faders" != "null" ] && echo "${prefix}    lockFaders = ${lock_faders};"
    echo "${prefix}  };"
  fi

  echo "${prefix}}"
}

# ---------------------------------------------------------------------------
# Utility/daemon settings (from .config, not per-profile)
# ---------------------------------------------------------------------------
emit_utility_config() {
  local prefix="$1"
  local autostart show_tray tts_enabled net_access log_level fw_source open_ui
  autostart=$(echo "$STATUS" | jq '.config.autostart_enabled')
  show_tray=$(echo "$STATUS" | jq '.config.show_tray_icon')
  tts_enabled=$(echo "$STATUS" | jq '.config.tts_enabled')
  net_access=$(echo "$STATUS" | jq '.config.allow_network_access')
  log_level=$(echo "$STATUS" | jq -r '.config.log_level // empty')
  fw_source=$(echo "$STATUS" | jq -r '.config.firmware_source // empty')
  open_ui=$(echo "$STATUS" | jq '.config.open_ui_on_launch')

  echo "${prefix}# Utility settings (daemon-level, not managed by HM module):"
  [ "$autostart" != "null" ] && echo "${prefix}# autostart_enabled = ${autostart}"
  [ "$show_tray" != "null" ] && echo "${prefix}# show_tray_icon = ${show_tray}"
  [ "$tts_enabled" != "null" ] && echo "${prefix}# tts_enabled = ${tts_enabled}"
  [ "$net_access" != "null" ] && echo "${prefix}# allow_network_access = ${net_access}"
  [ -n "$log_level" ] && echo "${prefix}# log_level = \"${log_level}\""
  [ -n "$fw_source" ] && echo "${prefix}# firmware_source = \"${fw_source}\""
  [ "$open_ui" != "null" ] && echo "${prefix}# open_ui_on_launch = ${open_ui}"
}

# ---------------------------------------------------------------------------
# Lifecycle commands (shutdown/sleep/wake profile switching)
# ---------------------------------------------------------------------------
emit_lifecycle_commands() {
  local prefix="$1"

  echo "${prefix}# Lifecycle commands (daemon-level, set in settings.json):"

  # Extract profile names from lifecycle command arrays
  local shutdown_profile shutdown_mic
  shutdown_profile=$(echo "$MIXER" | jq -r '
		[.shutdown_commands[]? | select(has("LoadProfile")) | .LoadProfile[0]] | first // empty')
  shutdown_mic=$(echo "$MIXER" | jq -r '
		[.shutdown_commands[]? | select(has("LoadMicProfile")) | .LoadMicProfile[0]] | first // empty')
  if [ -n "$shutdown_profile" ] || [ -n "$shutdown_mic" ]; then
    echo "${prefix}# shutdown: profile = \"${shutdown_profile}\", micProfile = \"${shutdown_mic}\""
  fi

  local sleep_profile sleep_mic
  sleep_profile=$(echo "$MIXER" | jq -r '
		[.sleep_commands[]? | select(has("LoadProfile")) | .LoadProfile[0]] | first // empty')
  sleep_mic=$(echo "$MIXER" | jq -r '
		[.sleep_commands[]? | select(has("LoadMicProfile")) | .LoadMicProfile[0]] | first // empty')
  if [ -n "$sleep_profile" ] || [ -n "$sleep_mic" ]; then
    echo "${prefix}# sleep: profile = \"${sleep_profile}\", micProfile = \"${sleep_mic}\""
  fi

  local wake_profile wake_mic
  wake_profile=$(echo "$MIXER" | jq -r '
		[.wake_commands[]? | select(has("LoadProfile")) | .LoadProfile[0]] | first // empty')
  wake_mic=$(echo "$MIXER" | jq -r '
		[.wake_commands[]? | select(has("LoadMicProfile")) | .LoadMicProfile[0]] | first // empty')
  if [ -n "$wake_profile" ] || [ -n "$wake_mic" ]; then
    echo "${prefix}# wake: profile = \"${wake_profile}\", micProfile = \"${wake_mic}\""
  fi
}

# ---------------------------------------------------------------------------
# Mode: current (default) — export live state
# ---------------------------------------------------------------------------
DEVICE_TYPE=$(echo "$MIXER" | jq -r '.hardware.device_type // "Unknown"')

if [ "$MODE" = "current" ]; then
  echo "# Generated by export-config.sh on $(date -Iseconds)"
  echo "# Device: GoXLR ${DEVICE_TYPE}"
  echo "# Paste this under: programs.goxlr = { ... };"
  emit_full_profile ""
  echo ""
  emit_utility_config ""
  echo ""
  emit_lifecycle_commands ""
  exit 0
fi

# ---------------------------------------------------------------------------
# Mode: single — export one specific profile
# ---------------------------------------------------------------------------
if [ "$MODE" = "single" ]; then
  echo "# Generated by export-config.sh on $(date -Iseconds)"
  echo "# Profile: ${TARGET_PROFILE}"

  if [ "$TARGET_PROFILE" != "$ORIG_PROFILE" ]; then
    NEEDS_RESTORE=true
    goxlr-client profiles device load "$TARGET_PROFILE" 2>/dev/null || {
      echo "Error: failed to load profile '${TARGET_PROFILE}'" >&2
      exit 1
    }
    sleep 0.5
    refresh_mixer
  fi

  emit_full_profile ""
  echo ""
  emit_utility_config ""
  echo ""
  emit_lifecycle_commands ""
  exit 0
fi

# ---------------------------------------------------------------------------
# Mode: all — export every device profile + mic profiles
# ---------------------------------------------------------------------------
echo "# Generated by export-config.sh on $(date -Iseconds)"
echo "# Profiles available: $(
  IFS=", "
  echo "${PROFILES[*]}"
)"
echo "# Mic profiles available: $(
  IFS=", "
  echo "${MIC_PROFILES[*]}"
)"
echo ""

NEEDS_RESTORE=true

# --- Device profiles ---
for profile in "${PROFILES[@]}"; do
  # Load profile
  if [ "$profile" != "$ORIG_PROFILE" ]; then
    goxlr-client profiles device load "$profile" 2>/dev/null || {
      echo "# Error: failed to load profile '${profile}' — skipping" >&2
      continue
    }
    sleep 0.5
    refresh_mixer
  else
    # Re-read in case a previous iteration changed things; first iteration
    # with the original profile can just use what we already have, but if
    # we're coming back to it after switching we need to reload.
    if [ "$profile" != "$(echo "$MIXER" | jq -r '.profile_name')" ]; then
      goxlr-client profiles device load "$profile" 2>/dev/null || continue
      sleep 0.5
      refresh_mixer
    fi
  fi

  local_profile_name=$(echo "$MIXER" | jq -r '.profile_name')
  is_active="false"
  if [ "$profile" = "$ORIG_PROFILE" ]; then
    is_active="true"
  fi

  echo ""
  sep="# $(printf '=%.0s' {1..54})"
  if [ "$is_active" = "true" ]; then
    echo "$sep"
    echo "# Profile: ${profile}  (currently active)"
    echo "$sep"
    emit_full_profile ""
  else
    echo "$sep"
    echo "# Profile: ${profile}"
    echo "$sep"
    emit_full_profile "# "
  fi
done

# --- Mic profiles ---
echo ""
echo ""
echo "# ======================================================================"
echo "# Mic profiles (microphone section only)"
echo "# ======================================================================"

for mic_profile in "${MIC_PROFILES[@]}"; do
  # Load mic profile
  if [ "$mic_profile" != "$(echo "$MIXER" | jq -r '.mic_profile_name')" ]; then
    goxlr-client profiles microphone load "$mic_profile" 2>/dev/null || {
      echo "# Error: failed to load mic profile '${mic_profile}' — skipping" >&2
      continue
    }
    sleep 0.5
    refresh_mixer
  fi

  is_active="false"
  if [ "$mic_profile" = "$ORIG_MIC_PROFILE" ]; then
    is_active="true"
  fi

  echo ""
  sep="# $(printf '=%.0s' {1..54})"
  if [ "$is_active" = "true" ]; then
    echo "$sep"
    echo "# Mic profile: ${mic_profile}  (currently active)"
    echo "$sep"
    emit_microphone_section ""
  else
    echo "$sep"
    echo "# Mic profile: ${mic_profile}"
    echo "$sep"
    emit_microphone_section "# "
  fi
done

echo ""
echo ""
echo "# ======================================================================"
echo "# Utility settings (daemon-level)"
echo "# ======================================================================"
emit_utility_config ""
echo ""
echo "# ======================================================================"
echo "# Lifecycle commands (daemon-level, set in settings.json)"
echo "# ======================================================================"
emit_lifecycle_commands ""

# Cleanup trap restores original profiles on exit
