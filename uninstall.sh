#!/usr/bin/env bash
set -euo pipefail
echo "Reverting to backups if they exist..."
for p in \
  "${HOME}/.config/nvim" \
  "${HOME}/.vim_runtime/my_configs.vim" \
  "${HOME}/.vim/my_configs.vim"
do
  if [ -e "${p}.bak" ]; then
    rm -rf "$p"
    mv -f "${p}.bak" "$p"
    echo "Restored: $p"
  fi
done
echo "Done."
