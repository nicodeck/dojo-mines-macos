# Dojo des Mines

1. Télécharge ce dépôt : bouton vert **Code** → **Download ZIP**, puis double-clique sur le
   zip dans tes Téléchargements pour l'ouvrir.
2. Ouvre l'app **Terminal**.
3. Tape `cd ` (avec un espace), glisse ce dossier dans la fenêtre du Terminal, puis appuie sur Entrée.
4. Tape `bash installer.sh` et appuie sur Entrée.
5. Quand le script le demande, colle la clé OpenRouter qu'on t'a donnée.

Le script installe ce qu'il faut et lance Claude Code. Pour le relancer plus tard : `claude`
dans ce dossier.

Dans Claude Code, commence par taper `/grill-me` suivi de ton idée de jeu.

Tu préfères mettre ta clé toi-même ? Crée un fichier `.env` dans ce dossier avec la ligne
`OPENROUTER_API_KEY=ta-clé`, puis lance `bash installer.sh`.
