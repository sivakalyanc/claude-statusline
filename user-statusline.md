Configure the Claude Code dashboard statusline interactively, one step at a time.

Config file: `~/.claude/statusline-config`

**Step 1 — Read the current config** and show current settings summary.

**Step 2 — Ask: "What do you want to change?"** and present these numbered options:

1. Toggle segments on/off
2. Change bar style
3. Change git detail level
4. Show full current config
5. Done (exit)

**Step 3 — Based on their choice:**

If **1 (Toggle segments)**: Show all segments with their current state (on/off). Ask which ones to toggle. Accept multiple at once (e.g. "show_tokens on, show_cost off"). Update and confirm. Back to Step 2.

Segments: show_model, show_dir, show_git, show_cost, show_burn_rate, show_context, show_rate_limits, show_tokens, show_duration, show_vim_mode, show_lines, show_version, show_effort

If **2 (Change bar style)**: Show the 4 options with visual previews:
1. `blocks` — █████░░░░░
2. `dots` — ●●●●●○○○○○
3. `geometric` — ▰▰▰▰▰▱▱▱▱▱
4. `line` — ━━━━━┄┄┄┄┄
Also ask for bar_width (current value shown, default 10). Update and confirm. Back to Step 2.

If **3 (Change git detail)**: Show options:
1. `basic` — branch + dirty indicator
2. `full` — branch + dirty + untracked + ahead/behind
Update and confirm. Back to Step 2.

If **4 (Show config)**: Cat the current config file contents. Back to Step 2.

If **5 (Done)**: Confirm the final config and say "Changes are live — your statusline updates on the next prompt."

**Rules:**
- Only modify `~/.claude/statusline-config`. Do NOT touch `~/.claude/statusline.sh` or `~/.claude/settings.json`.
- Keep the loop going — always return to Step 2 after each change until the user says done.
- Be concise. No long explanations. Just the menu, the action, the confirmation.
- When writing config, preserve comments and formatting.
