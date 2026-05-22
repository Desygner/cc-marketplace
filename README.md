# Desygner Claude Code Marketplace

Plugins maintained by Desygner for Claude Code and OpenCode users. Each
plugin is a self-contained bundle of skills, slash commands, and optional
helper scripts.

## Plugins

| Plugin | What it does |
|---|---|
| [`ciao`](./plugins/ciao) | Drive your [Ciao](https://ciao.dev) projects from the terminal. Hand off prompts, list projects, run playbooks. |

## Install (Claude Code)

```
/plugin marketplace add Desygner/cc-marketplace
/plugin install ciao
```

## Install (OpenCode)

OpenCode reads skills from `~/.claude/skills/`, so anything you install
through Claude Code is automatically available to OpenCode too. If you only
use OpenCode, clone this repo into your OpenCode skills directory:

```
mkdir -p ~/.config/opencode/skills
git clone https://github.com/Desygner/cc-marketplace ~/.config/opencode/skills/cc-marketplace
```

## Updating

```
/plugin update ciao
```

Or `git pull` inside `~/.config/opencode/skills/cc-marketplace`.
