---
name: zsh-special-variable-clobbering
description: |
  Fix for zsh shell prompt disappearing or showing unexpected text after running
  a function. Use when: (1) shell prompt changes to random text after a function
  runs, (2) PROMPT/PS1 gets overwritten unexpectedly, (3) variable named "prompt"
  in a zsh function clobbers the shell prompt. Covers zsh case-insensitive special
  variables and safe naming conventions.
author: Claude Code
version: 1.0.0
date: 2025-07-15
---

# Zsh Special Variable Clobbering

## Problem
Zsh functions that use variables named `prompt`, `path`, `home`, or other
lowercase names that match zsh special variables will silently overwrite
shell state, causing confusing symptoms like the shell prompt changing to
arbitrary text.

## Context / Trigger Conditions
- Shell prompt changes to unexpected text after running a custom function
- `$PATH` or other environment variables get corrupted after a function call
- `read -r prompt` or `local prompt=...` inside a zsh function
- Works fine in bash but breaks in zsh
- Symptom appears *after* the function returns, not during execution

## Solution

### Root Cause
Zsh treats many special variables as **case-insensitive aliases**. These
pairs all refer to the same underlying value:

| Special (uppercase) | Also matches (lowercase) |
|---------------------|--------------------------|
| `PROMPT` / `PS1`    | `prompt`                 |
| `PATH`              | `path` (array form)      |
| `HOME`              | `home`                   |
| `CDPATH`            | `cdpath`                 |
| `FPATH`             | `fpath`                  |
| `MAILPATH`          | `mailpath`               |
| `MANPATH`           | `manpath`                |

Even `local prompt` does NOT protect you — zsh still links it to the
special `PROMPT` variable.

### Fix
Rename the variable to something that doesn't collide:

```zsh
# WRONG - clobbers $PROMPT
read -r prompt
local prompt="some value"

# CORRECT - use a different name
read -r user_input
local my_prompt="some value"
```

### Safe Naming Convention
Prefix function-local variables to avoid all collisions:
- `user_input`, `cmd_input` instead of `prompt`
- `file_path`, `target_path` instead of `path`
- `user_home`, `base_dir` instead of `home`

## Verification
After fixing, run `source ~/.zshrc` and execute the function. The shell
prompt should remain unchanged after the function returns.

```zsh
# Quick test: this should NOT change your prompt
test_var() { local my_var="hello"; echo "$my_var"; }
test_var
# Prompt should be normal

# This WILL break your prompt:
# bad_test() { local prompt="broken"; }
```

## Example

Before (broken):
```zsh
claudex() {
  printf "Enter prompt: "
  IFS= read -r prompt          # <-- Overwrites $PROMPT!
  some_command "$prompt"
}
# After running: shell prompt becomes the user's input text
```

After (fixed):
```zsh
claudex() {
  printf "Enter prompt: "
  IFS= read -r user_input      # <-- Safe variable name
  some_command "$user_input"
}
```

## Notes
- This is zsh-specific. Bash treats `prompt` and `PROMPT` as separate variables.
- The `typeset -l` / `typeset -u` modifiers are unrelated to this behavior.
- This also affects scripts sourced into zsh (not just functions).
- When porting bash functions to zsh, audit all variable names against the
  special variables list: `man zshparam` or `typeset +` to see all set params.
