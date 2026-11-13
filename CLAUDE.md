# Papageno · consignes pour Claude Code

Papageno est un site de prévention en santé mentale, proposé sous deux formes : un site web et une appli installable (PWA). Les deux sont le même code.
Concept : un pop-up store de quartier, « la supérette des choses qu'on ne dit pas ». On y remplit un panier de ce que sa journée a coûté, on imprime un ticket de caisse anonyme, d'autres visiteurs le piochent dans un bocal et « rendent la monnaie » avec un mot doux.
Public : de l'ado isolé à la personne âgée seule. Ton chaleureux, humour doux, tutoiement, écriture inclusive avec point médian (seul·e).

Nom : « Papageno », écrit sans T. À l'oral, il se prononce « Papajéno » (j doux), jamais « Papaguéno ».

## Règles à ne jamais casser

- **Sécurité** : le 3114, le 15 et le 112 restent visibles partout. La détection des messages de détresse et la modération (signalement, masquage) restent en place.
- **Vie privée** : numéros et e-mails visibles uniquement par l'organisatrice. Aucune donnée inutile demandée.
- **Mineurs** : rencontres seulement avec accord parental et adulte accompagnant.
- **Créations originales uniquement** : aucun logo, personnage ou nom de marque existant (McDonald's, Burger King, Coca-Cola…).
- **Accessibilité** : textes lisibles (contraste suffisant), boutons assez grands pour le doigt (44 px minimum), tout utilisable au clavier, aucune information portée seulement par la couleur.
- **Soin** : le site ne remplace pas un soin. Il doit le dire clairement, mais sans lourdeur (« Papageno écoute, mais ne soigne pas »).

Si une demande entre en conflit avec ces règles, ne pas l'appliquer telle quelle : proposer une solution qui respecte la règle et l'expliquer.
Exemple : l'encadré 3114 cachait le panier du rayon Exclusif. Il n'a pas été supprimé : il a été déplacé dans le panier, et l'encadré du coin s'efface seulement tant que ce 3114-là est à l'écran.

## Organisation des fichiers (dossier `papageno-app/`)

| Fichier | Rôle |
|---|---|
| `index.html` | **tout le site** : HTML, CSS et JavaScript dans un seul fichier (~6 000 lignes), sans framework ni étape de construction |
| `sw.js` | service worker (fonctionnement hors connexion) |
| `manifest.webmanifest` | carte d'identité de l'appli |
| `icons/`, `screenshots/` | icônes (tortue) et captures pour l'installation |
| `vendor/matter.min.js` | physique du bocal (Matter.js, licence MIT) |
| `bienvenue.mp3`, `aurevoir.mp3` | voix d'accueil et d'au revoir |
| `musique/playlist-1/` | les 12 morceaux de la « Playlist 1 », signés Sono Mondo |
| `robots.txt` | bloque les moteurs de recherche pendant la phase de test |
| `LISEZ-MOI.txt` | mode d'emploi et historique des versions |

### Repères dans `index.html`

- **Scènes** : `#home` (la façade), `#store` (la boutique), `#exit` (la sortie, avec ticket, pensée et citation).
- **Rayons** : `#r-allee` (allée / plan), `#r-pause` (Café des Heureux), `#r-exclusif` (rayon 1, étals et panier), `#r-bocal` (rayon 2), `#r-caisse`, `#r-mine` (porte-monnaie), `#r-chiffres`, `#r-meet` (Rencontres), `#r-merci` (À bientôt).
- **Objets JavaScript principaux** :
  - `Store` : données ; aujourd'hui en `localStorage` ; le commentaire « Supabase » indique où brancher la vraie base.
  - `Caisse`, `Jar` / `JarUI` : le bocal.
  - `Sound` : le bouton Son.
  - `Welcome` : les voix.
  - `Radio`, `Sea` (« La mer »), `Playlist` / `PLAYLIST` : la radio.
  - `Portal`, `Motion` : les animations d'entrée et de sortie.
  - `AppUI` : le format téléphone (onglets, feuille « Plus »).
  - `Desk` : l'hôtesse d'accueil.
  - `toast()` : petits messages ; `setAisle()` : changer de rayon ; `goExit()` : sortir.
- **Réglages gardés sur l'appareil** : `papagenot-son`, `papagenot-anim` (l'ancien nom est conservé volontairement, ne pas renommer ces clés).
- **Couleurs** : variables CSS dans `:root` (`--ink`, `--paper`, `--butter`, `--tomato-deep`…). `--tomato` reste décoratif ; pour du texte, utiliser `--tomato-deep`.
- **Encadrés 3114** : `.care-bar` (encadré du coin, ordinateur et tablette), `.app-3114` (barre du haut sur téléphone), `.basket-care` (dans le panier du rayon Exclusif), `#exit-care`.
- **Format téléphone** : en dessous de 640 px, barre d'onglets en bas ; détails différents pour l'iPhone et pour Android via `html[data-os="ios"|"android"]`.
- **Animations** : le réglage « réduire les animations » est respecté (classe `.calm`, variable `reduced`).

## Façon de travailler

1. Avant toute modification : `git init` puis un commit de départ, si ce n'est pas déjà fait, pour pouvoir revenir en arrière.
2. Modifier `index.html` par petites touches ciblées ; ne pas tout réécrire, ne pas découper le fichier sans le demander.
3. Garder les textes de l'interface en français, au tutoiement, avec le ton maison.
4. Tester en local : `python3 -m http.server 8000` dans `papageno-app/`, puis ouvrir http://localhost:8000 (sur ordinateur, et en largeur 390 px pour le téléphone).
5. Vérifier à chaque changement :
   - un 3114 est visible sur chaque écran ;
   - rien n'est caché derrière un encadré ;
   - pas de défilement horizontal à 320 px ;
   - tout marche au clavier (Tab, Entrée, Échap) ;
   - aucune erreur dans la console ;
   - contraste du texte d'au moins 4,5:1.
6. À chaque nouvelle version mise en ligne : changer `VERSION` dans `sw.js` (actuellement `papageno-v10`, la prochaine sera `papageno-v11`), sinon les téléphones gardent l'ancienne version. Ajouter une ligne « Nouveautés » dans `LISEZ-MOI.txt`.

## Mise en ligne

**Dépôt GitHub privé** : `PaFlyKeNou/Papageno-` (branche `main`).
**Hébergement** : Cloudflare Pages — **https://papageno.pages.dev** (projet « papageno »).

### Workflow de déploiement (Git)

1. Modifier les fichiers dans `papageno-app/`.
2. Commit et push sur la branche `main`.
3. Cloudflare Pages détecte le push et déploie automatiquement.
   - Framework : aucun. Commande de build : aucune. Répertoire de sortie : `papageno-app`.

### Première mise en place (déjà faite si vous lisez ceci dans le dépôt)

- Créer le projet sur Cloudflare Pages via « Connect to Git » → dépôt `Papageno-` → branche `main` → framework « None » → build command vide → output directory `papageno-app`.
- Si un ancien projet « papageno » en téléchargement direct existe, le supprimer d'abord (Cloudflare ne convertit pas un projet direct-upload en Git).

Version de test : `<meta name="robots" content="noindex">` dans `index.html`, plus `robots.txt`. À retirer le jour du lancement public.

## Limites actuelles (prototype)

- Tout reste sur le téléphone de chaque visiteur : le bocal et les mots doux reçus sont simulés, personne ne lit vraiment les tickets.
- Prochaine grande étape : une base de données partagée (Supabase, hébergement en Europe, RGPD et données de santé). Elle permettra :
  - que les tickets passent vraiment d'un visiteur à l'autre ;
  - la modération humaine et automatique ;
  - un porte-monnaie ouvert par code ou QR code ;
  - l'espace organisatrice.
- La Playlist 1 a besoin d'internet (elle n'est pas gardée hors connexion).
