#!/bin/bash
# Ralph Loop for Large Codebase Refactoring
# Based on Geoffrey Huntley's Ralph Wiggum pattern
#
# This script automates iterative refactoring by running Claude in a loop,
# each iteration with fresh context. Progress is tracked in refactor-progress.md.
#
# Usage: bash .claude/skills/refactor/scripts/ralph-loop.sh [progress-file]
#
# The loop:
# 1. Reads progress file → picks next incomplete task
# 2. Invokes Claude to implement that single task
# 3. Runs verification (tests/lint/build)
# 4. If checks pass → commits + marks task complete
# 5. If checks fail → retries (max 3 per task)
# 6. Loops until all tasks done or stuck

set -euo pipefail

PROGRESS_FILE="${1:-refactor-progress.md}"
MAX_RETRIES=3
RETRY_COUNT=0
STUCK_TASK=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${BLUE}[ralph]${NC} $1"; }
success() { echo -e "${GREEN}[ralph]${NC} $1"; }
warn() { echo -e "${YELLOW}[ralph]${NC} $1"; }
error() { echo -e "${RED}[ralph]${NC} $1"; }

# Check prerequisites
if [ ! -f "$PROGRESS_FILE" ]; then
    error "Progress file not found: $PROGRESS_FILE"
    error "Run the refactor skill first to generate the progress file."
    exit 1
fi

if ! command -v claude &> /dev/null; then
    error "Claude CLI not found. Install it first: https://docs.anthropic.com/en/docs/claude-code"
    exit 1
fi

# Count tasks
total_tasks() {
    grep -c '^\- \[[ x]\]' "$PROGRESS_FILE" 2>/dev/null || echo 0
}

completed_tasks() {
    grep -c '^\- \[x\]' "$PROGRESS_FILE" 2>/dev/null || echo 0
}

remaining_tasks() {
    grep -c '^\- \[ \]' "$PROGRESS_FILE" 2>/dev/null || echo 0
}

next_task() {
    grep -m1 '^\- \[ \]' "$PROGRESS_FILE" 2>/dev/null | sed 's/^\- \[ \] //'
}

log "╔══════════════════════════════════════╗"
log "║       Ralph Loop — Refactor         ║"
log "╚══════════════════════════════════════╝"
log ""
log "Progress file: $PROGRESS_FILE"
log "Total tasks: $(total_tasks)"
log "Completed: $(completed_tasks)"
log "Remaining: $(remaining_tasks)"
log ""

while [ "$(remaining_tasks)" -gt 0 ]; do
    TASK=$(next_task)

    if [ -z "$TASK" ]; then
        success "No more tasks found. Done!"
        break
    fi

    # Detect if we're stuck on the same task
    if [ "$TASK" = "$STUCK_TASK" ]; then
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
            error "Task failed $MAX_RETRIES times, stopping: $TASK"
            error "Manual intervention required. Fix the issue and re-run."
            exit 1
        fi
        warn "Retry $RETRY_COUNT/$MAX_RETRIES for: $TASK"
    else
        STUCK_TASK="$TASK"
        RETRY_COUNT=0
    fi

    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "Task: $TASK"
    log "Progress: $(completed_tasks)/$(total_tasks)"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Build the prompt for Claude
    PROMPT="You are in Ralph loop mode for a codebase refactor.

Read the progress file at '$PROGRESS_FILE' for full context.

Your SINGLE task for this iteration:
$TASK

Instructions:
1. Read the progress file to understand the refactor plan and what's been done
2. Implement ONLY this one task
3. Run verification (tests/lint/build) as available
4. If verification passes:
   - Stage and commit changes with message: 'refactor: $TASK'
   - Mark this task as [x] in the progress file
   - Add an entry to the Completed Log section with timestamp and details
5. If verification fails:
   - Do NOT commit
   - Do NOT mark the task complete
   - Add a note about what failed to the progress file

GUARDRAILS (non-negotiable):
- No public API changes without stopping
- No schema/migration changes
- No dependency changes
- Never change business logic — if behavior might change, skip and note it
- Never delete files
- Only touch files relevant to this specific task"

    # Run Claude with the prompt (non-interactive, fresh context)
    if claude --print "$PROMPT" 2>/dev/null; then
        success "Iteration complete."
    else
        warn "Claude exited with non-zero. Checking progress..."
    fi

    # Brief pause between iterations
    sleep 2
done

log ""
log "╔══════════════════════════════════════╗"
log "║        Ralph Loop Complete           ║"
log "╚══════════════════════════════════════╝"
log ""
log "Total tasks: $(total_tasks)"
log "Completed: $(completed_tasks)"
log "Remaining: $(remaining_tasks)"

if [ "$(remaining_tasks)" -eq 0 ]; then
    success "All tasks completed successfully! 🎉"
else
    warn "Some tasks remain. Review $PROGRESS_FILE for details."
fi
