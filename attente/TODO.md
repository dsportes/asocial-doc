## Bug

## Dev
Tests s3

Ralentissement des DL ???

Déploiements:
- GAE
- CF OP
- CF PUBSUB

## Conversion de MD en HTML

  yarn add showdown

- le fichier md.css contient le CSS
- le résultat est un HTML de base mais bien formé.

    node md2html.js README
    
    (SANS extension .md)


## Remarques diverses

{
  // Use IntelliSense to learn about possible attributes.
  // Hover to view descriptions of existing attributes.
  // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
  "version": "0.2.0",
  "configurations": [
    {
      "type": "chrome",
      "request": "launch",
      "name": "Quasar App: chrome",
      "url": "https://localhost:8343",
      "webRoot": "${workspaceFolder}/src",
      "sourceMapPathOverrides": {
        "webpack://asocial/./src/*": "${webRoot}/*"
      }
    },
    {
      "type": "firefox",
      "request": "launch",
      "name": "Quasar App: firefox",
      "url": "https://localhost:8343",
      "webRoot": "${workspaceFolder}/src",
      "pathMappings": [
        {
          "url": "webpack://asocial/src",
          "path": "${workspaceFolder}/src"
        }
      ]
    }
  ]
}

# Mise en place de l'aide en ligne
Les ressources correspondantes sont toutes dans `/src/assets/help` :
- `_plan.json` : donne la table des matières des pages de l'aide.
- des images en PNG, JPG, SVG comme `dessin.svg`.
- les pages de texte en md : `codepage_lg-LG.md`
  - `codepage` est le _code_ la page.
  - `lg-LG` est la locale (`fr-FR` `en-EN` ...).
  - le _titre_ de la page est une traduction dans `/src/i18n/fr-FR/index.js`
    - son entrée est: `A_codepage: 'Le beau titre',`


### Plan de l'aide

    [
      { "id": "pa", "lp": ["presentation", "comptes", "coutshebergement", "page2"] },
      { "id": "av", "lp": []},
      { "id": "faq", "lp": ["page3"]},
      { "id": "dev", "lp": ["documents", "crypto"]}
    ]

Il donne la liste ordonné des racines dans l'arbre de l'aide. Chaque racine est décrite par:
- `id`: le _code_ de la page _racine,
- `lp`: la liste ordonnée des codes des pages _fille_.

### Conventions d'écriture des pages en markdown
**La page est découpée en _sections_**, chacune est identifiée par une ligne:

    # Titre de ma section

Avec un unique espace entre `#` et le texte du titre.

La partie **avant** la première ligne `# section...` est _l'introduction_.

Chaque section est présentée avec:
- une _expansion_ dépliable qui permet d'en voir juste le titre, puis le détail une fois dépliée,
- un _menu_ éventuel listant les autres pages de l'aide référencée.

#### Références vers d'autres pages de l'aide
Sauf dans l'introduction des lignes comme celle-ci:

    @@crypto

indique une référence vers une autre page de l'aide:
- `@@` en tête de la ligne,
- puis le code de la page référencée (sans espaces ni au début, ni à la fin).

#### Images
Les _images_ apparaissent sous l'une de ces formes:

    SVG dans img
    
    <img src="dessin.svg" width="64" height="64" style="background-color:white">
    
    PNG dans un img
    
    <img src="logo.png" width="96" height="96" style="background-color:white">
    
    Chargé depuis svg
    
    <img src="logo.svg" width="96" height="96" style="background-color:white">

Ce qui figure dans src est le nom du fichier de l'image dans `/src/assets/help`

Elle sera chargée en tant que ressource en base64 et le tag `<img...` réécrit. En cas d'absence c'est une image par défaut qui est prise.
- na pas oublier le _background_ pour les SVG et PNG.

#### Hyperliens
Un hyperlien est à exprimer par un tag <a>:

    <a href="http://localhost:4000/fr/pagex.html" target="_blank">Manuels</a>

Ne pas oublier target="_blank" sinon la page va s'ouvrir sur celle de l'application.

Toutefois si ce lien correspond à une page de manuel de la documentaion de l'application, on utile la convention suivante:

    <a href="$$/fr/pagex.html" target="_blank">Manuels</a>

Si la ligne commence exactement par `<a href="$$/` Le terme `$$` sera remplacé par l'URL de la documentation de l'application afin d'avoir une aide en ligne indépendante d'une localisation _en dur_.

Le fichier /public/etc/urls.json a cette forme:

    {
      "opurl" : "http://localhost:8443",
      "pubsuburl" : "http://localhost:8443",
      "docsurl" : "http://localhost:4000"
    }

Ce fichier est défini au déploiement, après _build_.

# GCP Functions
## Test local / debug
Auto-Attach: With Flag

Lancer en debug: npm run debug

    "debug" : "node --inspect node_modules/.bin/functions-framework --port=8443 --target=asocialGCF"

Lancer SANS debug: npm run start

    "start": "functions-framework --port=8443 --target=asocialGCF --signature-type=http"

.vscode/launch.json - Pas certain que ça serve, à revérifier

    {
      "version": "0.2.0",
      "configurations": [
        {
          "type": "node",
          "request": "attach",
          "name": "debug",
          "address": "localhost",
          "port": 9229
        }
      ]
    }


**Différence importante** pour le POST des opérations dans `cfgexpress.mjs` - `app.use('/op:operation ...)`
- Mode SRV: req.rawBody n'existe pas. On le construit depuis req.on
- Mode GCF: req.rawBody existe mais pas req.on

____________________________________________

npx update-browserslist-db@latest