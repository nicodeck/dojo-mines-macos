#!/bin/bash
# Prépare la machine pour le dojo et lance Claude Code.
# Relançable sans risque : chaque étape déjà faite est sautée.
set -euo pipefail
cd "$(dirname "$0")"

vert() { printf '\033[32m✓ %s\033[0m\n' "$1"; }
etape() { printf '\n\033[1m→ %s\033[0m\n' "$1"; }
erreur() { printf '\n\033[31m✗ %s\033[0m\n' "$1"; printf 'Lève la main, on vient t'"'"'aider.\n'; exit 1; }

ajouter_au_path() { # $1 : dossier à mettre dans le PATH, maintenant et dans les prochains terminaux
  export PATH="$1:$PATH"
  local ligne="export PATH=\"$1:\$PATH\""
  grep -qsF "$ligne" ~/.zshrc || echo "$ligne" >> ~/.zshrc
}

echo "Installation du dojo. Ça prend quelques minutes, ne ferme pas cette fenêtre."

etape "Outils de développement d'Apple (git)"
if xcode-select -p >/dev/null 2>&1; then
  vert "déjà installés"
else
  xcode-select --install >/dev/null 2>&1 || true
  echo "Une fenêtre s'est ouverte : clique sur « Installer » et attends la fin (5 à 15 minutes)."
  until xcode-select -p >/dev/null 2>&1; do sleep 10; done
  vert "installés"
fi

etape "Bun"
[ -d "$HOME/.bun/bin" ] && export PATH="$HOME/.bun/bin:$PATH"
if command -v bun >/dev/null; then
  vert "déjà installé ($(bun --version))"
else
  curl -fsSL https://bun.sh/install | bash >/dev/null || erreur "L'installation de Bun a échoué."
  ajouter_au_path "$HOME/.bun/bin"
  vert "installé ($(bun --version))"
fi

etape "Claude Code"
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"
if command -v claude >/dev/null; then
  vert "déjà installé"
else
  echo "Téléchargement en cours, sans barre de progression : patiente."
  curl -fsSL https://claude.ai/install.sh | bash >/dev/null || erreur "L'installation de Claude Code a échoué."
  ajouter_au_path "$HOME/.local/bin"
  command -v claude >/dev/null || erreur "Claude Code est installé mais introuvable."
  vert "installé"
fi

etape "Clé OpenRouter"
REGLAGES=.claude/settings.local.json

verifier_cle() { # $1 : clé. Réussit si OpenRouter l'accepte.
  local code
  code=$(printf 'header = "Authorization: Bearer %s"\n' "$1" \
    | curl -s -o /dev/null -w '%{http_code}' -K - https://openrouter.ai/api/v1/key) || return 1
  [ "$code" = 200 ]
}

cle_existante=""
[ -f "$REGLAGES" ] && cle_existante=$(bun -e "console.log((await Bun.file('$REGLAGES').json()).env?.ANTHROPIC_AUTH_TOKEN ?? '')")
if [ -n "$cle_existante" ] && verifier_cle "$cle_existante"; then
  vert "déjà configurée"
else
  cle=""
  if [ -f .env ]; then
    cle=$(sed -n 's/^OPENROUTER_API_KEY=//p' .env | tr -d "\"' \r")
    [ -n "$cle" ] && echo "Clé lue dans le fichier .env"
  fi
  while true; do
    if [ -z "$cle" ]; then
      printf 'Colle ta clé OpenRouter (elle ne s'"'"'affiche pas) puis appuie sur Entrée : '
      read -rs cle </dev/tty; echo
      cle=$(tr -d ' \r' <<<"$cle")
    fi
    if [[ ! "$cle" =~ ^sk-or-[A-Za-z0-9_-]+$ ]]; then
      echo "Ça ne ressemble pas à une clé OpenRouter (elle commence par sk-or-). Réessaie."
    elif verifier_cle "$cle"; then
      vert "clé valide"
      break
    else
      echo "OpenRouter refuse cette clé. Vérifie-la et réessaie."
    fi
    cle=""
  done
  printf '{\n  "env": {\n    "ANTHROPIC_AUTH_TOKEN": "%s"\n  }\n}\n' "$cle" > "$REGLAGES"
  chmod 600 "$REGLAGES"
  vert "clé enregistrée"
fi

etape "Dépôt git"
if [ ! -d .git ]; then
  git init -q
fi
if [ -z "$(git config user.name || true)" ]; then
  git config user.name "Élève du dojo"
  git config user.email "eleve@dojo.local"
fi
if ! git rev-parse HEAD >/dev/null 2>&1; then
  git add -A && git commit -qm "Point de départ du dojo"
fi
vert "prêt"

printf '\n\033[1;32mTout est prêt !\033[0m Pour relancer Claude Code plus tard : tape « claude » dans ce dossier.\n\n'
if [ -t 0 ] && [ -t 1 ]; then
  exec claude
fi
