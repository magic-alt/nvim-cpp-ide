#!/usr/bin/env bash
set -euo pipefail

REPO="magic-alt/nvim-cpp-ide"
DEST_NVIM="${HOME}/.config/nvim"
DEST_VIM1="${HOME}/.vim_runtime/my_configs.vim"
DEST_VIM2="${HOME}/.vim/my_configs.vim"

echo "[1/4] Backup old configs (if any)..."
[ -d "$DEST_NVIM" ] && mv -f "$DEST_NVIM" "${DEST_NVIM}.bak.$(date +%s)" || true

echo "[2/4] Clone repo..."
TMP_DIR="$(mktemp -d)"
git clone --depth 1 "https://github.com/${REPO}.git" "$TMP_DIR"

echo "[3/4] Install config.vim to common locations..."
mkdir -p "$DEST_NVIM"
cp -f "$TMP_DIR/config.vim" "$DEST_NVIM/init.vim"
mkdir -p "$(dirname "$DEST_VIM1")"
cp -f "$TMP_DIR/config.vim" "$DEST_VIM1"
mkdir -p "$(dirname "$DEST_VIM2")"
cp -f "$TMP_DIR/config.vim" "$DEST_VIM2"

echo "[4/4] Done. Open nvim/vim to bootstrap plugins (if any)."
