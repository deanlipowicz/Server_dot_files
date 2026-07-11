#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR="$HOME/.cache/bun-migration"
LOG_FILE="$CACHE_DIR/migration-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$CACHE_DIR"

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG_FILE"; }
abort() { log "FATAL: $*"; exit 1; }
warn()  { log "WARN: $*"; }

# Packages to skip (bun built-ins or Node-specific)
SKIP_PACKAGES=("npm" "corepack")

phase0_snapshot() {
  log "Phase 0: Pre-flight snapshot"

  npm list -g --depth=0 --json 2>/dev/null | python3 -c "
import json, sys
d = json.load(sys.stdin)
for k, v in d.get('dependencies', {}).items():
    print(f'{k}@{v[\"version\"]}')
" > "$CACHE_DIR/npm-globals-snapshot.txt" || abort "Failed to snapshot npm globals"

  echo "$PATH" | tr ':' '\n' | grep -i 'pi-node' > "$CACHE_DIR/path-snapshot.txt" || true

  log "Snapshots saved to $CACHE_DIR"
}

phase1_install_bun() {
  log "Phase 1: Install bun"

  if command -v bun &>/dev/null; then
    log "bun already installed: $(bun --version)"
    return 0
  fi

  log "Downloading and installing bun..."
  curl -fsSL https://bun.sh/install | bash || abort "bun install failed"

  # Source bun into current session PATH
  export PATH="$HOME/.bun/bin:$PATH"

  if command -v bun &>/dev/null; then
    log "bun installed: $(bun --version)"
  else
    abort "bun install completed but bun command not found"
  fi
}

phase2_migrate_globals() {
  log "Phase 2: Migrate global packages"

  local snapshot="$CACHE_DIR/npm-globals-snapshot.txt"
  local migrated=0
  local failed=0
  local skipped=0

  while IFS= read -r line; do
    local pkg_name="${line%@*}"
    local pkg_version="${line##*@}"

    # Check skip list
    local skip=false
    for skip_pkg in "${SKIP_PACKAGES[@]}"; do
      [[ "$pkg_name" == "$skip_pkg" ]] && skip=true && break
    done
    if $skip; then
      log "SKIP: $pkg_name (not needed with bun)"
      ((++skipped))
      continue
    fi

    log "Installing: $pkg_name@$pkg_version"
    if bun add -g "$pkg_name@$pkg_version" >> "$LOG_FILE" 2>&1; then
      bun pm trust -g --all 2>/dev/null || true
      ((++migrated))
    else
      warn "Failed to install: $pkg_name@$pkg_version"
      ((++failed))
    fi
  done < "$snapshot"

  log "Migration summary: $migrated installed, $failed failed, $skipped skipped"
}

phase3_verify_globals() {
  log "Phase 3: Verify global packages"

  local snapshot="$CACHE_DIR/npm-globals-snapshot.txt"
  local verified=0
  local unverified=0

  while IFS= read -r line; do
    local pkg_name="${line%@*}"

    # Skip same packages as Phase 2
    local skip=false
    for skip_pkg in "${SKIP_PACKAGES[@]}"; do
      [[ "$pkg_name" == "$skip_pkg" ]] && skip=true && break
    done
    $skip && continue

    local bin="$pkg_name"
    # Map packages whose binary name differs from npm package name
    [[ "$pkg_name" == "@earendil-works/pi-coding-agent" ]] && bin="pi"
    [[ "$pkg_name" == "vscode-langservers-extracted" ]] && bin="vscode-html-language-server"

    if "$bin" --version &>/dev/null; then
      log "VERIFIED: $pkg_name ($("$bin" --version 2>&1 | head -1))"
      ((++verified))
    elif "$bin" --help &>/dev/null; then
      log "VERIFIED (--help): $pkg_name"
      ((++verified))
    else
      warn "UNVERIFIED: $pkg_name (binary '$bin' not found or failed)"
      ((++unverified))
    fi
  done < "$snapshot"

  log "Verification summary: $verified passed, $unverified unchecked"
}

SHELL_BLOCK_START="# === BUN MIGRATION START ==="
SHELL_BLOCK_END="# === BUN MIGRATION END ==="

phase4_configure_shell() {
  log "Phase 4: Configure shell"

  local zshrc="$HOME/.zshrc"

  # Check if already configured
  if grep -q "$SHELL_BLOCK_START" "$zshrc" 2>/dev/null; then
    log "Shell already configured (guard block found in $zshrc)"
    return 0
  fi

  cat >> "$zshrc" <<'SHELLEOF'

# === BUN MIGRATION START ===
# Ensure bun is in PATH (takes priority over any remaining Node/npm)
export PATH="$HOME/.bun/bin:$PATH"
# Aliases: npm, node, and npx now delegate to bun
alias npm='bun'
alias node='bun run'
alias npx='bunx'
# === BUN MIGRATION END ===
SHELLEOF

  if [[ $? -eq 0 ]]; then
    log "Shell configuration appended to $zshrc"
  else
    abort "Failed to write shell configuration to $zshrc"
  fi
}

PI_NODE_DIR="$HOME/.local/share/pi-node"
SHELL_FILES=("$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile")

phase5_remove_pinode() {
  log "Phase 5: Remove pi-node"

  # Remove pi-node directory tree
  if [[ -d "$PI_NODE_DIR" ]]; then
    log "Removing $PI_NODE_DIR"
    rm -rf "$PI_NODE_DIR" || warn "Failed to remove $PI_NODE_DIR (files may be locked)"
  else
    log "pi-node directory not found at $PI_NODE_DIR (already removed?)"
  fi

  # Remove pi-node init lines from shell config files
  for shell_file in "${SHELL_FILES[@]}"; do
    if [[ -f "$shell_file" ]] && grep -qi 'pi-node' "$shell_file" 2>/dev/null; then
      log "Removing pi-node lines from $shell_file"
      sed -i '/pi-node/Id' "$shell_file" || warn "Failed to clean $shell_file"
    fi
  done

  log "pi-node removed. Restart your shell or run: exec zsh"
}

phase6_generate_rollback() {
  log "Phase 6: Generate rollback script"

  local rollback="$HOME/bin/rollback-bun-migration.sh"
  local snapshot="$CACHE_DIR/npm-globals-snapshot.txt"
  local path_snapshot="$CACHE_DIR/path-snapshot.txt"

  cat > "$rollback" <<'ROLLBACK_HEADER'
#!/usr/bin/env bash
# Rollback: Reverse the npm-to-bun migration
# Generated by migrate-to-bun.sh
set -euo pipefail
echo "=== Bun Migration Rollback ==="

ROLLBACK_HEADER

  if [[ -f "$path_snapshot" && -s "$path_snapshot" ]]; then
    cat >> "$rollback" <<'PATH_RESTORE'
echo "Restoring pi-node PATH entries..."
echo "NOTE: pi-node must be reinstalled. PATH entries cannot be fully restored."
echo "      See: https://github.com/pi-node/pi"

PATH_RESTORE
  fi

  # Remove bun migration block from .zshrc
  cat >> "$rollback" <<BLOCK_REMOVE
echo "Removing bun migration block from ~/.zshrc..."
sed -i '/$SHELL_BLOCK_START/,/$SHELL_BLOCK_END/d' "\$HOME/.zshrc"
echo "Removing aliases from current session..."
unalias npm node npx 2>/dev/null || true

BLOCK_REMOVE

  if [[ -f "$snapshot" && -s "$snapshot" ]]; then
    cat >> "$rollback" <<NPM_RESTORE
echo "To restore npm global packages, reinstall pi-node/npm then run:"
echo "  while IFS= read -r line; do npm install -g \"\$line\"; done < $CACHE_DIR/npm-globals-snapshot.txt"

NPM_RESTORE
  fi

  cat >> "$rollback" <<'ROLLBACK_FOOTER'
echo "=== Rollback Complete ==="
echo "NOTE: bun is still installed. To remove: rm -rf ~/.bun"
ROLLBACK_FOOTER

  chmod +x "$rollback"
  log "Rollback script written: $rollback"
}

main() {
  log "=== NPM-to-Bun Migration Started ==="
  phase0_snapshot
  phase1_install_bun
  phase2_migrate_globals
  phase3_verify_globals
  phase4_configure_shell
  phase5_remove_pinode
  phase6_generate_rollback

  log ""
  log "=== Migration Complete ==="
  log "Log file: $LOG_FILE"
  log "Rollback: ~/bin/rollback-bun-migration.sh"
  log ""
  log "Post-migration smoke tests (run in a NEW shell):"
  log "  1. bun --version"
  log "  2. npm --version          (alias: should print bun version)"
  log "  3. node -e 'console.log(42)'  (alias: bun run)"
  log "  4. npx --help             (alias: bunx)"
  log "  5. bunx --help"
  log "  6. bash-language-server --version"
  log "  7. typescript-language-server --version"
  log "  8. tldr --version"
  log "  9. which node             (should be bun, not pi-node)"
  log " 10. which npm              (should be alias or bun)"
}

main "$@"
