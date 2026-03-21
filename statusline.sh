#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Claude Code Statusline — Dashboard                         ║
# ║  Config: ~/.claude/statusline-config                        ║
# ╚══════════════════════════════════════════════════════════════╝
set -f  # disable globbing for safety

# ── Load config ──────────────────────────────────────────────────
CONFIG_FILE="$HOME/.claude/statusline-config"
# defaults
show_model=true show_dir=true show_git=true show_cost=true
show_burn_rate=true show_context=true show_rate_limits=true show_tokens=false
show_duration=true show_vim_mode=true show_lines=false show_version=false
show_effort=true git_detail=basic bar_style=blocks bar_width=10

if [[ -f "$CONFIG_FILE" ]]; then
  while IFS='=' read -r key val; do
    key="${key%%#*}"          # strip inline comments
    key="${key// /}"          # trim spaces
    val="${val%%#*}"
    val="${val## }"; val="${val%% }"
    [[ -z "$key" ]] && continue
    printf -v "$key" '%s' "$val" 2>/dev/null
  done < "$CONFIG_FILE"
fi

# ── NO_COLOR support ────────────────────────────────────────────
if [[ -n "${NO_COLOR:-}" ]]; then
  c() { :; }
  RST=""
else
  c() { printf '\033[%sm' "$1"; }
  RST=$'\033[0m'
fi

# ── 256-color palette ───────────────────────────────────────────
FG_BLUE="38;5;75"    FG_CYAN="38;5;117"   FG_GREEN="38;5;114"
FG_ORANGE="38;5;215" FG_YELLOW="38;5;222" FG_RED="38;5;203"
FG_MAGENTA="38;5;176" FG_WHITE="38;5;252" FG_GRAY="38;5;245"
FG_LAVENDER="38;5;183" FG_MINT="38;5;158" FG_GOLD="38;5;220"
FG_PEACH="38;5;216"  FG_DIM="2"

BG_DBLUE="48;5;24"   BG_OLIVE="48;5;65"  BG_PURPLE="48;5;96"
BG_BROWN="48;5;130"  BG_DGRAY="48;5;236" BG_MGRAY="48;5;238"
BG_LGRAY="48;5;240"  BG_TEAL="48;5;30"   BG_DGREEN="48;5;22"

# ── Read stdin JSON (single jq call) ────────────────────────────
input=$(cat)

eval "$(echo "$input" | jq -r '
  def s(f): f // "" | tostring | gsub("'\''"; "'\''\\'\'''\''");
  @sh "j_model=\(s(.model.display_name))",
  @sh "j_cwd=\(s(.workspace.current_dir))",
  @sh "j_cost=\(s(.cost.total_cost_usd))",
  @sh "j_duration=\(s(.cost.total_duration_ms))",
  @sh "j_lines_add=\(s(.cost.total_lines_added))",
  @sh "j_lines_rm=\(s(.cost.total_lines_removed))",
  @sh "j_ctx_used=\(s(.context_window.used_percentage))",
  @sh "j_ctx_used=\(s(.context_window.used_percentage))",
  @sh "j_ctx_size=\(s(.context_window.context_window_size))",
  @sh "j_tok_in=\(s(.context_window.total_input_tokens))",
  @sh "j_tok_out=\(s(.context_window.total_output_tokens))",
  @sh "j_rl5_used=\(s(.rate_limits.five_hour.used_percentage))",
  @sh "j_rl5_reset=\(s(.rate_limits.five_hour.resets_at))",
  @sh "j_rl7_used=\(s(.rate_limits.seven_day.used_percentage))",
  @sh "j_rl7_reset=\(s(.rate_limits.seven_day.resets_at))",
  @sh "j_vim=\(s(.vim.mode))",
  @sh "j_version=\(s(.version))",
  @sh "j_exceed=\(s(.exceeds_200k_tokens))",
  @sh "j_output_style=\(s(.output_style.name))"
' 2>/dev/null)"

# ── Effort level from settings.json ─────────────────────────────
j_effort=""
if [[ "$show_effort" == "true" && -f "$HOME/.claude/settings.json" ]]; then
  j_effort=$(jq -r '.effortLevel // empty' "$HOME/.claude/settings.json" 2>/dev/null)
fi

# ── Directory shortening ────────────────────────────────────────
dir=""
if [[ "$show_dir" == "true" && -n "$j_cwd" ]]; then
  IFS='/' read -ra segs <<< "$j_cwd"
  n=${#segs[@]}
  if (( n <= 4 )); then
    dir="$j_cwd"
  else
    dir="…/${segs[$((n-3))]}/${segs[$((n-2))]}/${segs[$((n-1))]}"
  fi
  # replace $HOME prefix with ~
  dir="${dir/#$HOME/\~}"
fi

# ── Git info ────────────────────────────────────────────────────
git_branch="" git_dirty="" git_untracked="" git_ahead="" git_behind=""
if [[ "$show_git" == "true" ]]; then
  gdir="${j_cwd:-$(pwd)}"
  if git -C "$gdir" rev-parse --git-dir >/dev/null 2>&1; then
    git_branch=$(git -C "$gdir" symbolic-ref --short HEAD 2>/dev/null \
                 || git -C "$gdir" rev-parse --short HEAD 2>/dev/null)
    if ! git -C "$gdir" diff --quiet 2>/dev/null || \
       ! git -C "$gdir" diff --cached --quiet 2>/dev/null; then
      git_dirty="*"
    fi
    if [[ -n "$(git -C "$gdir" ls-files --others --exclude-standard 2>/dev/null | head -1)" ]]; then
      git_untracked="?"
    fi
    if [[ "$git_detail" == "full" && -n "$git_branch" ]]; then
      local_ahead=$(git -C "$gdir" rev-list --count "@{upstream}..HEAD" 2>/dev/null || echo 0)
      local_behind=$(git -C "$gdir" rev-list --count "HEAD..@{upstream}" 2>/dev/null || echo 0)
      [[ "$local_ahead" -gt 0 ]] && git_ahead="↑${local_ahead}"
      [[ "$local_behind" -gt 0 ]] && git_behind="↓${local_behind}"
    fi
  fi
fi

# ── Derived values ──────────────────────────────────────────────
# Cost formatting
cost_str=""
if [[ "$show_cost" == "true" && -n "$j_cost" && "$j_cost" != "0" ]]; then
  cost_rounded=$(printf "%.2f" "$j_cost" 2>/dev/null || echo "$j_cost")
  cost_str="cost: \$${cost_rounded}"
fi

# Duration formatting (ms → human)
duration_str=""
if [[ "$show_duration" == "true" && -n "$j_duration" && "$j_duration" != "0" ]]; then
  ms="$j_duration"
  if (( ms >= 3600000 )); then
    duration_str="session: $((ms/3600000))h$((ms%3600000/60000))m"
  elif (( ms >= 60000 )); then
    duration_str="session: $((ms/60000))m$((ms%60000/1000))s"
  elif (( ms >= 1000 )); then
    duration_str="session: $((ms/1000))s"
  else
    duration_str="session: ${ms}ms"
  fi
fi

# Token count formatting (K/M)
tok_str=""
if [[ "$show_tokens" == "true" ]]; then
  fmt_tok() {
    local n="$1"
    if [[ -z "$n" || "$n" == "0" ]]; then echo "0"; return; fi
    if (( n >= 1000000 )); then
      printf "%.1fM" "$(echo "scale=1; $n/1000000" | bc)"
    elif (( n >= 1000 )); then
      printf "%.1fK" "$(echo "scale=1; $n/1000" | bc)"
    else
      echo "$n"
    fi
  }
  tok_in=$(fmt_tok "$j_tok_in")
  tok_out=$(fmt_tok "$j_tok_out")
  tok_str="tokens: ${tok_in}↑${tok_out}↓"
fi

# Burn rate (cost per minute)
burn_str=""
if [[ "$show_burn_rate" == "true" && -n "$j_cost" && -n "$j_duration" \
      && "$j_cost" != "0" && "$j_duration" != "0" ]]; then
  burn=$(echo "scale=4; $j_cost / ($j_duration / 60000)" | bc 2>/dev/null)
  if [[ -n "$burn" ]]; then
    burn_str="burn: \$${burn}/m"
  fi
fi

# Lines changed
lines_str=""
if [[ "$show_lines" == "true" ]]; then
  [[ -n "$j_lines_add" && "$j_lines_add" != "0" ]] && lines_str="+${j_lines_add}"
  if [[ -n "$j_lines_rm" && "$j_lines_rm" != "0" ]]; then
    [[ -n "$lines_str" ]] && lines_str="${lines_str}/"
    lines_str="${lines_str}-${j_lines_rm}"
  fi
  [[ -n "$lines_str" ]] && lines_str="lines: ${lines_str}"
fi

# Rate limit reset time (relative)
rl_reset_str() {
  local reset_at="$1"
  [[ -z "$reset_at" ]] && return
  local now reset_epoch diff_s
  now=$(date +%s 2>/dev/null) || return
  reset_epoch=$(date -d "$reset_at" +%s 2>/dev/null) || return
  diff_s=$(( reset_epoch - now ))
  if (( diff_s <= 0 )); then
    echo "now"
  elif (( diff_s < 3600 )); then
    echo "$((diff_s/60))m"
  else
    echo "$((diff_s/3600))h$((diff_s%3600/60))m"
  fi
}

# ── Helper: color for percentage (higher = worse) ───────────────
color_for_used() {
  local pct="${1:-0}"
  pct="${pct%.*}"
  if (( pct < 50 )); then echo "$FG_GREEN"
  elif (( pct < 70 )); then echo "$FG_YELLOW"
  elif (( pct < 90 )); then echo "$FG_ORANGE"
  else echo "$FG_RED"
  fi
}

# ── Helper: progress bar ───────────────────────────────────────
progress_bar() {
  local pct="${1:-0}" width="${bar_width:-10}"
  pct="${pct%.*}"
  (( pct < 0 )) && pct=0; (( pct > 100 )) && pct=100
  local filled=$(( pct * width / 100 ))
  local empty=$(( width - filled ))
  local fc ec
  case "$bar_style" in
    dots)      fc="●" ec="○" ;;
    geometric) fc="▰" ec="▱" ;;
    line)      fc="━" ec="┄" ;;
    *)         fc="█" ec="░" ;;
  esac
  local bar=""
  for (( i=0; i<filled; i++ )); do bar+="$fc"; done
  for (( i=0; i<empty; i++ )); do bar+="$ec"; done
  echo "$bar"
}

# ── Git string assembly ────────────────────────────────────────
git_str=""
if [[ -n "$git_branch" ]]; then
  git_str=" ${git_branch}${git_dirty}${git_untracked}${git_ahead}${git_behind}"
fi

# ── Vim mode string ────────────────────────────────────────────
vim_str=""
if [[ "$show_vim_mode" == "true" && -n "$j_vim" ]]; then
  vim_str="vim: $j_vim"
fi

# ── Dashboard renderer ────────────────────────────────────────────
# Two-line info-dense layout with labeled segments and bars
render_dashboard() {
  local line1="" line2=""

  # Line 1: model │ dir │ git │ vim
  if [[ "$show_model" == "true" && -n "$j_model" ]]; then
    line1+="$(c "$FG_CYAN")${j_model}${RST}"
  fi
  if [[ -n "$dir" ]]; then
    [[ -n "$line1" ]] && line1+=" $(c "$FG_GRAY")│${RST} "
    line1+="$(c "$FG_BLUE")${dir}${RST}"
  fi
  if [[ -n "$git_str" ]]; then
    [[ -n "$line1" ]] && line1+=" $(c "$FG_GRAY")│${RST} "
    line1+="$(c "$FG_ORANGE")${git_str}${RST}"
  fi
  if [[ -n "$vim_str" ]]; then
    [[ -n "$line1" ]] && line1+=" $(c "$FG_GRAY")│${RST} "
    line1+="$(c "$FG_MAGENTA")${vim_str}${RST}"
  fi
  if [[ "$show_effort" == "true" && -n "$j_effort" ]]; then
    [[ -n "$line1" ]] && line1+=" $(c "$FG_GRAY")│${RST} "
    line1+="$(c "$FG_LAVENDER")effort: ${j_effort}${RST}"
  fi

  # Line 2: ctx bar │ cost │ burn │ duration │ rate limits
  if [[ "$show_context" == "true" && -n "$j_ctx_used" ]]; then
    local ctx_c; ctx_c=$(color_for_used "$j_ctx_used")
    local ctx_bar; ctx_bar=$(progress_bar "$j_ctx_used")
    line2+="$(c "$ctx_c")context used ${ctx_bar} ${j_ctx_used}%${RST}"
  fi
  if [[ -n "$cost_str" ]]; then
    [[ -n "$line2" ]] && line2+=" $(c "$FG_GRAY")│${RST} "
    line2+="$(c "$FG_GREEN")${cost_str}${RST}"
  fi
  if [[ -n "$burn_str" ]]; then
    [[ -n "$line2" ]] && line2+=" $(c "$FG_GRAY")│${RST} "
    line2+="$(c "$FG_PEACH")${burn_str}${RST}"
  fi
  if [[ -n "$duration_str" ]]; then
    [[ -n "$line2" ]] && line2+=" $(c "$FG_GRAY")│${RST} "
    line2+="$(c "$FG_CYAN")${duration_str}${RST}"
  fi
  if [[ "$show_rate_limits" == "true" && -n "$j_rl5_used" ]]; then
    [[ -n "$line2" ]] && line2+=" $(c "$FG_GRAY")│${RST} "
    local rl_c; rl_c=$(color_for_used "$j_rl5_used")
    line2+="$(c "$rl_c")5h: ${j_rl5_used}%${RST}"
  fi
  if [[ "$show_rate_limits" == "true" && -n "$j_rl7_used" ]]; then
    line2+=" $(c "$(color_for_used "$j_rl7_used")")7d: ${j_rl7_used}%${RST}"
  fi
  if [[ -n "$tok_str" ]]; then
    [[ -n "$line2" ]] && line2+=" $(c "$FG_GRAY")│${RST} "
    line2+="$(c "$FG_GRAY")${tok_str}${RST}"
  fi
  if [[ -n "$lines_str" ]]; then
    [[ -n "$line2" ]] && line2+=" $(c "$FG_GRAY")│${RST} "
    line2+="$(c "$FG_MINT")${lines_str}${RST}"
  fi

  printf '\033[0m%s' "$line1"
  [[ -n "$line2" ]] && printf '\n\033[0m%s' "$line2"
}

# ── Render ───────────────────────────────────────────────────────
render_dashboard
