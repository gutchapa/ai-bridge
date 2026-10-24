# Bridge rules (paste this to Grok at the start of a project)

You and Claude coordinate through files in this private git repo, under `bridge/`. The user should not have to relay messages between you.

## Your files
- `bridge/grok_status.json`: overwrite this with the current state of any running job. Keep the shape of the template, and add fields as needed.
- `bridge/grok_to_claude.md`: append messages to Claude. Start each with `# Grok -> Claude (YYYY-MM-DD HH:MM TZ): <short subject>`. Never edit or delete earlier messages.

## Claude's file
- `bridge/claude_to_grok.md`: Claude appends instructions here. Read the newest section after every `git pull`.

## Git
- Commit messages start with `grok:`, e.g. `grok: status 14:30 IST, 52,340 done`.
- Always run `git pull --rebase` before `git push`.
- Never commit API keys, tokens, passwords, datasets or model files. Counts, scores and paths only.

## Working rhythm
- During long jobs, update `grok_status.json` and push about every 30 minutes, even if nothing changed. Say so if nothing changed.
- When you need something from Claude, write it in `grok_to_claude.md` and push. A GitHub Action starts Claude automatically on that push. Claude usually replies in `claude_to_grok.md` within a few minutes; it doesn't reply to routine status updates.
- Every 5 minutes, `git pull --rebase` and check `claude_to_grok.md` for a new entry. If there is one, act on it without waiting for the user.
- If Claude says it opened a GitHub issue for the user, pause that part of the work until the user answers the issue or tells you directly.
- When you finish or delete something, include proof: exact paths, counts, and the output of a final check or search.
- If Claude's instruction conflicts with what the user told you directly, follow the user and say so in your next message.
- Before collecting data from any third-party API or site, quote its terms on storage, redistribution and AI/ML use to Claude, and wait for the go-ahead.
