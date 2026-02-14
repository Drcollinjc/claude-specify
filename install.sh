#!/usr/bin/env bash

set -euo pipefail

#==============================================================================
# claude-specify installer
#
# Usage:
#   ./install.sh install /path/to/project    Install plugin into a project
#   ./install.sh update  /path/to/project    Update an existing installation
#   ./install.sh uninstall /path/to/project  Remove plugin from a project
#
# Flags:
#   --force    Overwrite existing rules files during install/update
#==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$SCRIPT_DIR/plugin"
VERSION_FILE="$SCRIPT_DIR/VERSION"

# Plugin rules (process-enforcement, installed to .claude/rules/)
PLUGIN_RULES=(
    "implementation-enforcement.md"
    "session-workflow.md"
    "verification.md"
    "thinking.md"
)

# Plugin commands (installed to .claude/commands/)
PLUGIN_COMMANDS=(
    "specify.md"
    "clarify.md"
    "architecture.md"
    "plan.md"
    "tasks.md"
    "checklist.md"
    "analyze.md"
    "implement.md"
    "constitution.md"
)

#==============================================================================
# Helpers
#==============================================================================

log_info()    { echo "[specify] $1"; }
log_success() { echo "[specify] OK: $1"; }
log_warn()    { echo "[specify] WARN: $1" >&2; }
log_error()   { echo "[specify] ERROR: $1" >&2; }

get_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        cat "$VERSION_FILE"
    else
        echo "unknown"
    fi
}

usage() {
    echo "Usage: $0 <install|update|uninstall> /path/to/project [--force]"
    echo ""
    echo "Commands:"
    echo "  install    Install claude-specify into a project"
    echo "  update     Update an existing installation"
    echo "  uninstall  Remove claude-specify from a project"
    echo ""
    echo "Flags:"
    echo "  --force    Overwrite existing rules files (install/update only)"
    exit 1
}

#==============================================================================
# Install
#==============================================================================

do_install() {
    local target="$1"
    local force="$2"
    local version
    version=$(get_version)

    # Validate target is a directory
    if [[ ! -d "$target" ]]; then
        log_error "Target is not a directory: $target"
        exit 1
    fi

    # Validate plugin directory exists
    if [[ ! -d "$PLUGIN_DIR" ]]; then
        log_error "Plugin directory not found: $PLUGIN_DIR"
        exit 1
    fi

    log_info "Installing claude-specify v${version} into $target"

    # 1. Copy .specify/ tree
    if [[ -d "$target/.specify" ]]; then
        log_warn ".specify/ already exists — overwriting"
        rm -rf "$target/.specify"
    fi
    cp -R "$PLUGIN_DIR/.specify" "$target/.specify"
    log_success "Copied .specify/ (memory, rules, scripts, templates)"

    # 2. Copy commands to .claude/commands/
    mkdir -p "$target/.claude/commands"
    local cmd_count=0
    for cmd in "${PLUGIN_COMMANDS[@]}"; do
        if [[ -f "$PLUGIN_DIR/commands/$cmd" ]]; then
            cp "$PLUGIN_DIR/commands/$cmd" "$target/.claude/commands/$cmd"
            cmd_count=$((cmd_count + 1))
        else
            log_warn "Command file not found: $cmd"
        fi
    done
    log_success "Copied $cmd_count command files to .claude/commands/"

    # 3. Copy rules to .claude/rules/ (skip existing unless --force)
    mkdir -p "$target/.claude/rules"
    local rules_count=0
    local rules_skipped=0
    for rule in "${PLUGIN_RULES[@]}"; do
        if [[ -f "$PLUGIN_DIR/rules/$rule" ]]; then
            if [[ -f "$target/.claude/rules/$rule" ]] && [[ "$force" != "true" ]]; then
                log_warn "Rule exists, skipping (use --force to overwrite): .claude/rules/$rule"
                rules_skipped=$((rules_skipped + 1))
            else
                cp "$PLUGIN_DIR/rules/$rule" "$target/.claude/rules/$rule"
                rules_count=$((rules_count + 1))
            fi
        else
            log_warn "Rule file not found: $rule"
        fi
    done
    log_success "Copied $rules_count rule files to .claude/rules/ ($rules_skipped skipped)"

    # 4. Create specs/ directory
    mkdir -p "$target/specs"
    log_success "Created specs/ directory"

    # 5. Write version marker
    echo "$version" > "$target/.specify/.version"
    log_success "Wrote version marker: $version"

    # 6. Make bash scripts executable
    if [[ -d "$target/.specify/scripts/bash" ]]; then
        chmod +x "$target/.specify/scripts/bash/"*.sh
        log_success "Made bash scripts executable"
    fi

    echo ""
    log_info "Installation complete."
    log_info ""
    log_info "Installed:"
    log_info "  .specify/           Pipeline config (thesis, constitution, scripts, templates)"
    log_info "  .claude/commands/   ${cmd_count} pipeline commands (/specify, /plan, /implement, ...)"
    log_info "  .claude/rules/      ${rules_count} process-enforcement rules"
    log_info "  specs/              Feature specification directory"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Edit .specify/memory/product-principles.md with your product thesis"
    log_info "  2. Run /constitution to generate your engineering principles"
    log_info "  3. Start a feature with /specify"
}

#==============================================================================
# Update
#==============================================================================

do_update() {
    local target="$1"
    local force="$2"
    local version
    version=$(get_version)

    # Check .specify/.version exists (must be installed first)
    if [[ ! -f "$target/.specify/.version" ]]; then
        log_error "No existing installation found (missing .specify/.version)"
        log_error "Run '$0 install $target' first"
        exit 1
    fi

    local old_version
    old_version=$(cat "$target/.specify/.version")
    log_info "Updating claude-specify v${old_version} -> v${version} in $target"

    # 1. Overwrite .specify/ tree
    rm -rf "$target/.specify"
    cp -R "$PLUGIN_DIR/.specify" "$target/.specify"
    log_success "Updated .specify/ tree"

    # 2. Overwrite commands
    mkdir -p "$target/.claude/commands"
    local cmd_count=0
    for cmd in "${PLUGIN_COMMANDS[@]}"; do
        if [[ -f "$PLUGIN_DIR/commands/$cmd" ]]; then
            cp "$PLUGIN_DIR/commands/$cmd" "$target/.claude/commands/$cmd"
            cmd_count=$((cmd_count + 1))
        fi
    done
    log_success "Updated $cmd_count command files"

    # 3. Rules: skip existing unless --force
    mkdir -p "$target/.claude/rules"
    local rules_count=0
    local rules_skipped=0
    for rule in "${PLUGIN_RULES[@]}"; do
        if [[ -f "$PLUGIN_DIR/rules/$rule" ]]; then
            if [[ -f "$target/.claude/rules/$rule" ]] && [[ "$force" != "true" ]]; then
                log_warn "Rule exists, skipping (use --force to overwrite): .claude/rules/$rule"
                rules_skipped=$((rules_skipped + 1))
            else
                cp "$PLUGIN_DIR/rules/$rule" "$target/.claude/rules/$rule"
                rules_count=$((rules_count + 1))
            fi
        fi
    done
    log_success "Updated $rules_count rule files ($rules_skipped skipped)"

    # 4. Write version marker
    echo "$version" > "$target/.specify/.version"
    log_success "Updated version marker: $old_version -> $version"

    # 5. Make bash scripts executable
    if [[ -d "$target/.specify/scripts/bash" ]]; then
        chmod +x "$target/.specify/scripts/bash/"*.sh
    fi

    echo ""
    log_info "Update complete."
}

#==============================================================================
# Uninstall
#==============================================================================

do_uninstall() {
    local target="$1"

    if [[ ! -d "$target/.specify" ]]; then
        log_error "No .specify/ directory found in $target — nothing to uninstall"
        exit 1
    fi

    log_info "Uninstalling claude-specify from $target"

    # 1. Remove .specify/
    rm -rf "$target/.specify"
    log_success "Removed .specify/"

    # 2. Remove plugin commands (only known files)
    local cmd_count=0
    for cmd in "${PLUGIN_COMMANDS[@]}"; do
        if [[ -f "$target/.claude/commands/$cmd" ]]; then
            rm "$target/.claude/commands/$cmd"
            cmd_count=$((cmd_count + 1))
        fi
    done
    log_success "Removed $cmd_count command files"

    # 3. Remove plugin rules (only known files)
    local rules_count=0
    for rule in "${PLUGIN_RULES[@]}"; do
        if [[ -f "$target/.claude/rules/$rule" ]]; then
            rm "$target/.claude/rules/$rule"
            rules_count=$((rules_count + 1))
        fi
    done
    log_success "Removed $rules_count rule files"

    # 4. Clean up empty directories (but don't remove .claude/ if user has other files)
    rmdir "$target/.claude/commands" 2>/dev/null || true
    rmdir "$target/.claude/rules" 2>/dev/null || true
    rmdir "$target/.claude" 2>/dev/null || true

    # 5. Do NOT remove specs/ — that's user data
    if [[ -d "$target/specs" ]]; then
        log_info "Preserved specs/ directory (user data)"
    fi

    echo ""
    log_info "Uninstall complete."
}

#==============================================================================
# Main
#==============================================================================

main() {
    local action="${1:-}"
    local target="${2:-}"
    local force="false"

    # Parse --force flag from any position
    for arg in "$@"; do
        if [[ "$arg" == "--force" ]]; then
            force="true"
        fi
    done

    # Filter out --force from positional args
    local positional=()
    for arg in "$@"; do
        if [[ "$arg" != "--force" ]]; then
            positional+=("$arg")
        fi
    done

    action="${positional[0]:-}"
    target="${positional[1]:-}"

    if [[ -z "$action" ]] || [[ -z "$target" ]]; then
        usage
    fi

    # Resolve to absolute path
    target="$(cd "$target" 2>/dev/null && pwd)" || {
        log_error "Target directory does not exist: ${positional[1]}"
        exit 1
    }

    case "$action" in
        install)
            do_install "$target" "$force"
            ;;
        update)
            do_update "$target" "$force"
            ;;
        uninstall)
            do_uninstall "$target"
            ;;
        *)
            log_error "Unknown action: $action"
            usage
            ;;
    esac
}

main "$@"
