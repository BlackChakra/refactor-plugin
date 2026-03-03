# Refactor Plugin for Claude Code

A comprehensive codebase refactoring skill with objective quality scoring, structured execution, and Ralph loop support for codebases of any size — including 100k+ lines.

## Installation

**Local testing:**
```bash
claude --plugin-dir ./refactor-plugin
```

**From GitHub:**
```bash
/plugin add your-username/refactor-plugin
```

## Usage

**Direct invocation:**
```
/refactor:refactor [path] [focus] [target-score]
```

**Natural language (auto-detected):**
- "Refactor this codebase"
- "Clean up this code"
- "Improve code quality"

### Arguments (all optional)

| Argument | Description | Example |
|----------|-------------|---------|
| `path` | Target file or directory | `src/api/` |
| `focus` | Category to focus on | `types`, `readability`, `performance`, `structure`, `tests`, `lint` |
| `target-score` | Quality score to aim for (1–10) | `8` |

## What It Does

1. **Detects** your environment — languages, frameworks, test runners, linters, CI
2. **Builds a baseline** — runs existing checks, snapshots metrics (LOC, complexity, duplication)
3. **Scores quality** across 6 categories with a 1–10 rubric:
   - Readability · Architecture · Type Safety · Performance · Test Health · Lint/Format
4. **Plans** prioritized refactoring changes
5. **Creates a backup branch** (`refactor/<timestamp>`) before any changes
6. **Executes** changes — direct for small codebases, [Ralph loop](https://ghuntley.com/ralph/) for 100k+ lines
7. **Verifies** nothing broke (tests, lint, build)
8. **Commits** only after you confirm
9. **Generates an extensive report** with before/after sub-scores

## Guardrails

- No public API changes without explicit approval
- No schema/migration changes unless opted in
- No dependency changes without approval
- Never changes business logic — stops and asks if behavior might be affected
- Always creates a backup branch before changes
- Never commits broken code

## Ralph Loop (Large Codebases)

For codebases over 100k lines, the skill auto-switches to the Ralph loop pattern — an iterative bash loop that:
- Breaks refactoring into small, independent tasks
- Runs each task with fresh AI context (no context rot)
- Commits passing changes, retries failures (max 3x)
- Tracks progress in an external markdown file

## License

MIT
