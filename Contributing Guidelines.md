# Contributing Guidelines

**Repository**: https://github.com/levox00/RobloxHub

Welcome! This document outlines the development workflow and contribution process for this project.

## Core Principles

- Always work on the latest code: Before making any changes, always pull the newest version from main.
- Feature isolation: All new features, games, fixes, or significant changes must be developed in dedicated branches.
- Main branch protection: The main branch is considered stable. It is only updated when a feature is explicitly confirmed working.

## Development Workflow

### 1. Start with a Fresh Pull
Before doing anything, always run:

git pull origin main --rebase

### 2. Create a Feature Branch
Use one of the following naming conventions:

- feature/<description>     (example: feature/player-movement)
- game/<game-name>          (example: game/roguelike-prototype)
- fix/<bug-name>            (example: fix/collision-detection)
- refactor/<component>
- docs/ or chore/

Example:
git checkout -b feature/new-combat-system

### 3. Make Changes
- Keep changes focused and atomic.
- Write clear, descriptive commit messages (present tense).
  Good: "Add dash ability with cooldown"
  Bad: "updated stuff"

### 4. Push Your Work
git push -u origin feature/new-combat-system

After pushing, inform the project owner (or your AI agent) about the branch and what was implemented.

### 5. Merging to Main
Do not merge to main yourself.

The main branch should only be updated when the project owner explicitly confirms with phrases such as:
- "that last update works"
- "merge to main"
- "push to main"
- or names the specific feature ("the inventory system works", "combat is good now", etc.)

Once confirmed, the AI agent (or contributor) may merge the feature branch into main.

## Git Best Practices
- Never force-push to main (--force).
- Keep the repository clean (update .gitignore, remove unused files, etc.).
- Maintain clear documentation in README.md.
- Test your changes before requesting a merge.

## AI Agent / Hermes Instructions
If you are an AI coding assistant (Hermes or similar) working on this repository:

1. Always pull latest changes before writing or editing files.
2. Never push directly to main without explicit confirmation from the owner.
3. Create and work on properly named feature branches.
4. Follow clean commit practices.
5. Keep the project well-organized, especially when working with multiple games or prototypes.

## Questions?
Feel free to open an issue or ask the project maintainer directly.

Thank you for contributing!