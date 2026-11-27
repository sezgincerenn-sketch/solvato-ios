#!/usr/bin/env bash
# Claude Code "SessionStart" kancası: bulut oturumu temiz bir kopyayla başlar; doküman biçimleyicisi (Prettier) yoksa kurar.
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
if [ ! -d node_modules ]; then
  npm install --no-audit --no-fund --loglevel=error >/dev/null 2>&1 \
    && echo "Bağımlılıklar kuruldu (npm install)." \
    || echo "npm install başarısız; komutları çalıştırmadan önce elle dene."
fi
exit 0
