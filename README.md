# Claude Code Dashboard Statusline

A rich, configurable statusline for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that displays model info, context usage, cost tracking, git status, rate limits, and more — right in your terminal.

```
model: Claude Opus 4.6 (1M) │ ~/git/myproject │  main*? │ effort: high │ v1.0.45
ctx ●●●●●○○○○○ 47% 470K/1M │ session cost: $1.24 │ burn: $0.0312/m │ cache: 82%
session:39m12s │ api:28m4s │ 5h: 23%(4h12m) │ 7d: 8%(6d2h) │ tokens: 142.3K↑18.7K↓ │ lines: +247/-31
```

## Features

- **3-line dashboard** layout with logical grouping
- **18 toggleable segments** — show only what you care about
- **Context bar** with progress indicator and token counts (e.g. 470K/1M)
- **Cost tracking** — session total, burn rate ($/min), cost per line changed
- **Rate limits** — 5-hour and 7-day usage with reset countdowns
- **Git status** — branch, dirty, untracked, ahead/behind
- **Cache hit ratio** — see how much prompt caching is saving
- **Warnings** — automatic alerts for high context usage (>80%) and rate limits (>90%)
- **4 bar styles** — blocks `█░`, dots `●○`, geometric `▰▱`, line `━┄`
- **256-color** with `NO_COLOR` support
- **Zero dependencies** beyond `bash`, `jq`, and `git`

## Setup

### 1. Copy the files

```bash
# Clone the repo (or download the files)
git clone https://github.com/sivakalyanc/claude-statusline.git
cd claude-statusline

# Copy the script and config to ~/.claude/
cp statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
cp statusline-config ~/.claude/statusline-config
```

### 2. Configure Claude Code settings

Add the statusline command to your Claude Code settings. Edit `~/.claude/settings.json`:

```json
{
  "statusline": {
    "command": "~/.claude/statusline.sh"
  }
}
```

Or if you already have a `settings.json`, just add the `"statusline"` key.

That's it. The statusline appears on your next Claude Code prompt.

### 3. (Optional) Customize

Edit `~/.claude/statusline-config` to toggle segments on/off, change bar styles, and adjust git detail level:

```bash
# Toggle any segment off
show_burn_rate=false
show_vim_mode=false

# Change the progress bar style: blocks | dots | geometric | line
bar_style=dots

# Git detail: basic (branch + dirty) | full (branch + dirty + untracked + ahead/behind)
git_detail=full

# Progress bar width (number of characters)
bar_width=10
```

Changes take effect on the next prompt refresh — no restart needed.

## Segments

| Segment | Config Key | Description |
|---------|-----------|-------------|
| Model | `show_model` | Current Claude model name |
| Directory | `show_dir` | Working directory (auto-shortened) |
| Git | `show_git` | Branch, dirty, untracked, ahead/behind |
| Vim Mode | `show_vim_mode` | Current vim mode (if vim keybindings enabled) |
| Effort | `show_effort` | Reasoning effort level from settings |
| Version | `show_version` | Claude Code version |
| Context | `show_context` | Context window usage bar + percentage |
| Context Size | `show_ctx_size` | Token count display (e.g. 470K/1M) |
| Cost | `show_cost` | Session cost in USD |
| Burn Rate | `show_burn_rate` | Cost per minute |
| Cost/Line | `show_cost_per_line` | Cost per line of code changed |
| Cache | `show_cache` | Prompt cache hit ratio |
| Duration | `show_duration` | Total session wall-clock time |
| API Time | `show_api_time` | Total API processing time |
| Rate Limits | `show_rate_limits` | 5-hour and 7-day usage with reset times |
| Tokens | `show_tokens` | Total input/output token counts |
| Lines | `show_lines` | Lines added/removed this session |
| Warnings | `show_ctx_warning` | Auto-alerts for high context/rate limit usage |

## Dashboard Layout

```
Line 1: model │ directory │ git │ vim │ effort │ version
Line 2: context bar │ cost │ burn rate │ cost/line │ cache
Line 3: session time │ api time │ rate limits │ tokens │ lines
Line 4: (warnings — only shown when context >80% or rate limit >90%)
```

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (CLI, desktop app, or IDE extension)
- `bash` (4.0+)
- `jq`
- `git` (for git segment)

## License

MIT
