# AI bridge kit: Claude ↔ Grok via git

A way for two AI assistants to work on one project without the user relaying every message. Each one reads and writes files in a shared **private** git repo, and each commit is a timestamped record of who said what.

It was first used on OTTfilter (Oct 2026). There, Grok ran a 2-day export on its own machine, and Claude wrote and reviewed the code.

## Roles

| | Grok (executor) | Claude (engineer / reviewer) |
|---|---|---|
| Runs on | A machine that stays up | A session that sleeps when idle |
| Does | Runs long jobs, posts status, does things in the user's accounts (Drive, Colab, browser) | Writes and fixes code, reviews results, decides next steps, writes instructions |
| Writes only | `bridge/grok_status.json`, `bridge/grok_to_claude.md` | `bridge/claude_to_grok.md` |

## How it runs without the user

```
Grok pushes bridge/grok_to_claude.md
        │
        ▼
GitHub Action starts Claude (ai-bridge.yml)
        │  reads the new commits, does the work, appends to claude_to_grok.md, pushes
        ▼
Grok pulls every 5 min, sees the reply, acts on it, pushes again ──► loop
```

- **Claude** is started by GitHub on every push from Grok, so no Claude session has to stay open.
- **Grok** is always on and polls for Claude's replies.
- **The user** is only pulled in for decisions that need a person: spending, deleting user data, publishing, legal or terms questions. Claude opens a GitHub issue titled "Needs your decision: …", and GitHub notifies the user by email and in the mobile app.
- **No loops:** Claude's pushes use the workflow's `GITHUB_TOKEN`, which never triggers another workflow run. The workflow also only watches Grok's two files.

Running costs: each Grok message or status push starts one Claude run, paid from the API key or Claude subscription in the repo secret. Pushing status every 30 minutes means about 48 runs a day. Claude ends quickly when there's nothing to answer, but to cut cost, remove `bridge/grok_status.json` from the workflow's `paths` and let Grok mention problems in a message.

## Files

```
.github/workflows/ai-bridge.yml   # starts Claude on every Grok push
bridge/
  grok_status.json     # Grok overwrites this with the current job state
  grok_to_claude.md    # Grok appends messages (never edits old ones)
  claude_to_grok.md    # Claude appends messages (never edits old ones)
  BRIDGE_RULES.md      # Grok's rules; paste to Grok at the start
  CLAUDE_ROLE.md       # Claude's rules; the workflow points Claude here
check_bridge.sh        # for an interactive Claude session to catch up by hand
```

Templates for all of these are in `templates/`.

## Set up a new project

1. Create a **private** GitHub repo, or use the project's repo if it's private.
2. Copy the files into place:
   - `templates/ai-bridge.yml` → `.github/workflows/ai-bridge.yml`
   - the other `templates/*` → `bridge/`
   - `check_bridge.sh` → the repo root
   Then commit.
3. Add **one** repo secret under Settings → Secrets and variables → Actions:
   - `ANTHROPIC_API_KEY`, from console.anthropic.com (pay per use), **or**
   - `CLAUDE_CODE_OAUTH_TOKEN`, from running `claude setup-token` on your computer (uses your Claude subscription). If you use this one, swap the commented line in `ai-bridge.yml`.
4. Give Grok push access with a **fine-grained personal access token**, scoped to that one repo with Contents: read and write.
5. Paste `bridge/BRIDGE_RULES.md` to Grok, give it the goal, and have it push its first message. Within a few minutes, check the repo's **Actions** tab: the first Claude run should show up there and reply in `bridge/claude_to_grok.md`.

## Lessons from the first run

- **Check the terms before collecting data.** OTTfilter collected 121k movies from TMDB and trained a model on them, then found that TMDB's API Terms ban exactly that. Everything had to be deleted. Read the data source's terms before step one.
- **No background daemons inside a Claude session.** The first run tried a monitor loop and a keyword auto-responder. Both failed, because the session sleeps when idle and keyword matching isn't reading. They were replaced by the GitHub Action, which starts a full Claude run on each push.
- **One writer per file, append-only messages.** That gave zero merge conflicts on content. Always run `git pull --rebase` before `git push`, because both sides commit often.
- **Status every ~30 minutes during long jobs**, with a single `unique_total`-style number, so progress is obvious from `git log --oneline`.
- **Ask for proof, not summaries.** When Grok reports deleting or finishing something, ask for paths, counts and search output. Claude should state what it verified itself and what it is taking on Grok's word.
- **Claude reads the bridge before reporting numbers.** In the first run, Claude quoted stale local copies. `check_bridge.sh` pulls first.
- **Set pass/fail bars up front.** For example: "publish only if Recall@10 ≥ 50%". Grok can then decide without waiting on Claude.
- **Nothing sensitive in the bridge.** No API keys, no tokens, no datasets. Counts, scores and file paths only.
