---
name: save
description: Save the user's changes with a properly formatted message. Activate when the user wants to save their work, save what they've done, create a save point, or preserve their changes.
---

You are helping a non-technical user (designer or PM) save their work in the Buildertrend frontend project.

## Language rules

Never use these technical terms with the user. Use the plain-English alternative instead:

| Don't say | Say instead |
|---|---|
| commit | "save your changes" or "save point" |
| stage / staged | "include" or "included" |
| diff | "what changed" |
| branch | "your own copy" or "safe copy" |
| repository / repo | "the project" or "the codebase" |

If the user uses technical terms, that's fine — understand them but respond in plain language.

**IMPORTANT: Never combine commands with shell operators.** No `&&`, `||`, `;`, `|`, `>`, `<`, `` ` ``, `$(...)`, or `eval`. Always run each command as a separate Bash tool call.

## Step 1: Include all changes

Run `git add -A`.

## Step 2: Check what changed

Run `git status` to see what was added, changed, or removed.

If nothing changed, tell the user: **"There's nothing new to save — your work is already up to date."** Then stop.

Otherwise, summarize the changes to the user in plain English. For example: "Here's what changed: the header color was updated and a new button was added to the login page."

## Step 3: Figure out the ticket number

Check the current branch name by running `git branch --show-current`.

- If the branch name starts with a number (e.g., `231499-update-header-color`), that's the ticket number. The full ticket ID is `ado-<number>` (e.g., `ado-231499`).
- If the branch name doesn't start with a number, ask the user: **"Do you have a ticket number for this? It looks like 'ado-' followed by some numbers (e.g., ado-251313). It's OK if you don't have one."**
  - If they provide one, use it.
  - If they don't have one, you cannot save without a ticket number. Tell the user: **"I need a ticket number to save your changes. Check with your team or look in Azure DevOps for the right ticket, then let me know."** Then stop.

## Step 4: Write the save message

Compose a message in this exact format:

```
ado-<number> <short present-tense description>
```

Rules:
- Start with the full ticket ID: `ado-` followed by the number
- Then a single space
- Then a short, present-tense description of what changed (not what you did — what the code does now)
- Keep it under 72 characters total

**Examples:**
- `ado-231499 Update header color to match new brand palette`
- `ado-251313 Fix login button spacing on mobile`
- `ado-198004 Add loading spinner to dashboard`
- `ado-210055 Remove deprecated banner from settings page`

## Step 5: Save

Run `git commit -m "<message>"`.

Tell the user: **"I've saved your changes. You can keep making more changes, or we can send these for review."**
