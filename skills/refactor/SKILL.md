---
name: refactor
description: Use when someone asks to refactor code, clean up a codebase, improve code quality, or audit code health. Supports codebases of any size including 100k+ lines.
argument-hint: [path] [focus] [target-score]
---

## What This Skill Does

Efficiently refactors a codebase with objective quality scoring, structured execution, and an extensive final report. Scales to 100k+ line codebases via the Ralph loop pattern.

**When invoked, tell the user about these optional arguments:**
- **Path** — Target a specific file or directory (default: full codebase)
- **Focus** — Narrow to a category: `types`, `readability`, `performance`, `structure`, `tests`, `lint`
- **Target score** — Aim for a specific quality score on the 1–10 scale

If no arguments are provided, analyze and refactor the entire codebase with all categories.

---

## Quality Score Rubric

The quality score is a 1–10 composite backed by six sub-scores. Each sub-score is assessed independently.

| Sub-score | What it measures | Scoring guide |
|-----------|-----------------|---------------|
| **Readability** | Naming clarity, comments, cyclomatic complexity, function/file length | 1–3: inconsistent naming, no comments, long functions. 4–6: mostly clear, some long files. 7–9: clean naming, reasonable length, clear flow. 10: exemplary. |
| **Architecture/Structure** | Separation of concerns, modularity, dependency flow, circular deps | 1–3: god files, circular deps, no separation. 4–6: some structure, mixed concerns. 7–9: clear modules, good boundaries. 10: textbook. |
| **Type Safety** | Type coverage, `any` usage, strict mode, runtime type errors | 1–3: no types or mostly `any`. 4–6: partial coverage. 7–9: strong coverage, strict mode. 10: full coverage, zero `any`. |
| **Performance Risks** | N+1 queries, unbounded loops, memory leaks, missing indexes, bundle size | 1–3: obvious perf issues. 4–6: some risks. 7–9: well-optimized. 10: production-hardened. |
| **Test Health** | Coverage %, test quality, passing rate, edge case coverage | 1–3: no tests or mostly broken. 4–6: some tests, gaps. 7–9: solid coverage, passing. 10: comprehensive. |
| **Lint/Format** | Adherence to project linter/formatter, consistency across files | 1–3: no linter or widely ignored. 4–6: partial adherence. 7–9: consistent. 10: zero violations. |

**Composite score** = average of all six sub-scores, reported to one decimal place (e.g., 6.2 → 8.1).

When a sub-score cannot be assessed (e.g., Type Safety for a language without types), mark it as **N/A** and exclude from the average.

---

## Step-by-Step Workflow

### Phase 1: Environment Detection

Detect and document the following automatically:

1. **Language(s)** and their versions
2. **Frameworks** (React, Express, Django, etc.)
3. **Package manager** (npm, yarn, pnpm, pip, cargo, etc.)
4. **Monorepo/workspaces** setup (if applicable)
5. **Test commands** — look in `package.json` scripts, `Makefile`, CI config, etc.
6. **Linters/formatters** — ESLint, Prettier, Ruff, rustfmt, etc.
7. **CI config** — GitHub Actions, CircleCI, etc.
8. **Total LOC** — use `find . -name '*.ext' | xargs wc -l` or equivalent

### Phase 2: Build Baseline

Before any changes:

1. **Git status check** — Ensure working tree is clean. If not, warn the user and ask how to proceed.
2. **Run existing checks** — Execute test/lint/build commands. Record results as the baseline.
3. **Metrics snapshot** (best-effort):
   - Total LOC and file counts by language
   - Dependency hotspots (files with the most imports/importers)
   - Duplication detection (look for repeated patterns)
   - Complexity hotspots (largest files, deepest nesting)
4. **Build the do-not-touch list:**
   - `node_modules/`, `vendor/`, `.git/`, `dist/`, `build/`, `__pycache__/`
   - Generated files (protobuf, GraphQL codegen, etc.)
   - Third-party code, vendored dependencies
   - Anything in `.gitignore`
   - Lock files (`package-lock.json`, `yarn.lock`, etc.)

### Phase 3: Analyze & Score

1. Assess each of the 6 sub-score categories
2. Note specific issues found per category with file locations
3. Calculate composite quality score
4. Group issues by severity (critical / warning / suggestion)

### Phase 4: Size Check & Mode Decision

1. **If codebase > 100k lines** → Switch to **Ralph loop mode** (see Ralph Loop section below)
2. **Decide conversational vs. fire-and-forget:**
   - **Conversational** (recommend for): first-time refactors, codebases with no tests, critical systems, when many API-adjacent changes are likely
   - **Fire-and-forget** (recommend for): well-tested codebases, lint/format-only passes, small targeted refactors
3. Explain your recommendation and let the user choose

### Phase 5: Report Findings

Present to the user:

```
## Refactor Analysis Report

**Codebase:** [path]
**Size:** [LOC] lines across [N] files
**Languages:** [detected]
**Frameworks:** [detected]

### Current Quality Score: X.X / 10

| Category | Score | Key Issues |
|----------|-------|------------|
| Readability | X.X | [summary] |
| Architecture | X.X | [summary] |
| Type Safety | X.X | [summary] |
| Performance | X.X | [summary] |
| Test Health | X.X | [summary] |
| Lint/Format | X.X | [summary] |

### Critical Issues (fix first)
- [issue with file location]

### Warnings
- [issue with file location]

### Suggestions
- [nice-to-have improvements]

### Do-Not-Touch List
- [paths excluded from refactoring]

### Recommended Mode: [Conversational / Fire-and-Forget]
[Reasoning]
```

### Phase 6: Plan & Confirm

1. Propose specific changes, prioritized by impact
2. Group changes by category and file
3. Estimate scope (number of files affected)
4. **Wait for user approval before proceeding**

### Phase 7: Create Backup Branch

Before making ANY code changes:

```bash
git checkout -b refactor/$(date +%Y%m%d-%H%M%S)
```

This ensures easy rollback regardless of what happens.

### Phase 8: Execute

Apply refactoring changes following these rules:

- Work through changes methodically, one category or file group at a time
- After each logical group of changes, run available checks (test/lint/build)
- If checks fail, fix or revert before moving on

### Phase 9: Verify

1. Run ALL test/lint/build commands that passed in the baseline
2. If tests didn't exist in baseline, run at minimum: typecheck, lint, build (or any available sanity command)
3. If no verification tools exist at all, report that **confidence is limited** and recommend the user add tests
4. Compare results against baseline — nothing should regress

### Phase 10: User Confirmation & Commit

1. Show the user a summary of all changes made
2. Show before/after quality scores with sub-score breakdown
3. **Only commit after the user explicitly confirms**
4. Use clear, descriptive commit messages per logical change group

### Phase 11: Extensive Final Report

Generate a comprehensive markdown report:

```
## Refactor Report

**Date:** [timestamp]
**Branch:** refactor/[timestamp]
**Codebase:** [path]

### Quality Score: Before → After
**Overall: X.X → Y.Y**

| Category | Before | After | Δ | What Changed |
|----------|--------|-------|---|--------------|
| Readability | X.X | Y.Y | +Z.Z | [specifics] |
| Architecture | X.X | Y.Y | +Z.Z | [specifics] |
| Type Safety | X.X | Y.Y | +Z.Z | [specifics] |
| Performance | X.X | Y.Y | +Z.Z | [specifics] |
| Test Health | X.X | Y.Y | +Z.Z | [specifics] |
| Lint/Format | X.X | Y.Y | +Z.Z | [specifics] |

### Changes Made
[grouped by category, with file paths and descriptions]

### Files Modified
[list of all files changed]

### Verification Results
- Tests: [pass/fail/none]
- Lint: [pass/fail/none]
- Build: [pass/fail/none]
- Confidence: [high/medium/limited]

### Recommendations
[anything the user should do next — add tests, address deferred issues, etc.]
```

---

## Ralph Loop Mode (100k+ Lines)

For very large codebases, use the Ralph loop pattern to avoid context rot and maximize token efficiency.

**How it works:**
1. Break the refactoring plan into small, independent, testable tasks
2. Write tasks to a `refactor-progress.md` file in the project root
3. Each iteration: read progress → pick next task → implement → test → commit if passing → update progress → restart with fresh context

**Progress file format:**

```markdown
# Refactor Progress

## Config
- Target: [path]
- Focus: [category or "all"]
- Branch: refactor/[timestamp]

## Tasks
- [x] Task 1 description (files: a.ts, b.ts)
- [x] Task 2 description (files: c.ts)
- [ ] Task 3 description (files: d.ts, e.ts)
- [ ] Task 4 description (files: f.ts)

## Completed Log
### Task 1 — [timestamp]
- Changed: [what]
- Tests: pass
- Committed: [hash]
```

**The loop script** is at `.claude/skills/refactor/scripts/ralph-loop.sh`. Run it with:

```bash
bash .claude/skills/refactor/scripts/ralph-loop.sh
```

The loop exits when all tasks are marked complete OR when a task fails verification 3 times in a row.

---

## Hard Guardrails

These are non-negotiable. Violating any of these should halt execution and ask the user:

1. **No public API changes** without explicit flag and callout to the user
2. **No schema or migration changes** unless the user explicitly opts in
3. **No dependency changes** (add, remove, or upgrade) unless the user approves
4. **Never change business logic** — if a change *might* affect runtime behavior, **stop and ask** before making it
5. **Never delete files** without asking
6. **Never commit broken code** — all checks must pass before commit
7. **Skip everything on the do-not-touch list**
8. **Respect `.gitignore`** completely
9. **Always create a backup branch** before any changes
10. **Always run verification** before and after — if no test suite exists, use typecheck/lint/build and report limited confidence

---

## Notes

- When the user provides a focus area, still report all sub-scores but only refactor the specified category
- If the codebase has no linter, formatter, or test suite, note this prominently and recommend additions in the final report
- For monorepos, ask the user which package(s) to target rather than refactoring everything
- Keep the main conversation context clean — delegate heavy file scanning and analysis to subagents when possible
- The quality score is a tool for communication, not a judgment — use it to show progress objectively
