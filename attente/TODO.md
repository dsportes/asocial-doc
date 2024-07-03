## Dev
Notes et Fichiers

Tâche de gestion des dlvat

GC: finaliser

Firebase

## Conversion de MD en HTML

  yarn add showdown

- le fichier md.css contient le CSS
- le résultat est un HTML de base mais bien formé.

    node md2html.js README
    
    (SANS extension .md)


## Remarques diverses
Dans `src/boot/i18.js` 
- ajouter `legacy: false,` sinon choix-langue ne s'initialise pas bien
- importer configStore pour récupérer la valeur initiale de la locale

Création du configStore qui va contenir la configuration
- chargement dans appconfig.js

choix-langue
- la liste des localeOptions est récupéré de configStore
- le modèle locale est la locale de i18n


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

### Build et Web server
quasar build -m pwa

Lancement du serveur npm http-server (en https avec les bons certificats) : httpsrv.cmd

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

## App UI
quasar.config.js

Section build

    env: {
      // Pour le mode SRV
        OPSRV: 'https://test.sportes.fr:8443/op/',

      // Pour le test local GCF
        OPSRV: 'http://localhost:8443/op/',

      // Ne sert pas si config.hasWS = false  
        WSSRV: 'wss://test.sportes.fr:8443/ws/'
    }

Debug classique depuis `Run>>>Start Debugging`

# Fichiers accessibles en mode avion

## Note.mfa : map des fichiers attachés à une note
- _clé_: `idf` - identifiant absolu aléatoire du fichier.
- _valeur_: `{ nom, dh, info, type, gz, lg, sha }`

Plusieurs fichiers peuvent avoir le même nom: ils sont considérés comme des versions successives, l'identifiant de la version est dh, la date-heure de l'opération l'ayant créé.
- dans la map, `nom/dh` est une clé.
- `info` est un code court facultatif qualifiant la version.
- l'item d'un `idf` donné est invariant après création.

## Class Ficav
Un document par fichier devant être accessible en mode avion:
- stockés en table `ficav` de IDB (inconnus du serveur).

- `id` : id du fichier (`idf` clé de `Note.mfa`)
- `dhdc` : date-heure de demande de chargement du fichier. Si 0, le fichier est chargé.
- `nbr` : nombre de ré-essai de chargement. 0 en cas de succès initial (exc est absent).
- `exc` : code de l'exception rencontrée lors de la dernière tentative de téléchargement.
- `key` : `id/ids` identifiant de la note à laquelle le fichier est ou était attaché.
- `nom` : nom du fichier dans son entrée dans Note.mfa
- `st` : statut
  - `0`: ne garder que cette version
  - `1`: supprimer ce fichier s'il existe un fichier de la même note plus récent de même nom.
  - `2`: garder cette version ET garder le fichier de la même note le plus récent de même nom. 
