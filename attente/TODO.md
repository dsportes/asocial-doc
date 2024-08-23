## Bug

## Dev
Changement des ID dans api.mjs

Suppression d'une partition

Ralentissement des DL ???

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
- `dhdc` : date-heure de demande de chargement du fichier: ne pas tenter de le charger avant cette heure. Si 0, le fichier est chargé (nbr et exc sont absents).
- `nbr` : nombre d'essai de chargement. 
- `exc` : exception rencontrée lors de la dernière tentative de téléchargement.
- `key` : `id/ids` identifiant de la note à laquelle le fichier est ou était attaché.
- `nom` : nom du fichier dans son entrée dans Note.mfa
- `av` : `true` - garder cette version spécifiquement
- `avn` : `true` - garder la version la plus récente du fichier ayant ce nom


/* OP_TestRSA: 'Test encryption RSA'
args.token
args.id
args.data
Retour:
- data: args.data crypré RSA par la clé publique de l'avatar

export class TestRSA extends Operation {
  constructor () { super('TestRSA') }

  async run (id, data) { 
    try {
      const session = stores.session
      const args = { token: session.authToken, id, data }
      const ret = this.tr(await post(this, 'TestRSA', args))
      return this.finOK(ret.data)
    } catch (e) {
      await this.finKO(e)
    }
  }
}

OP_CrypterRaw: 'Test d\'encryptage serveur d\'un buffer long',
Le serveur créé un binaire dont,
- les 256 premiers bytes crypte en RSA, la clé AES, IV et l'indicateur gz
- les suivants sont le texte du buffer long crypté par la clé AES générée.
args.token
args.id
args.data
args.gz
Retour:
- data: "fichier" binaire auto-décryptable en ayant la clé privée RSA
OU la clé du site

export class CrypterRaw extends Operation {
  constructor () { super('CrypterRaw') }

  async run (id, data, gz, clesite) { 
    try {
      const session = stores.session
      const aSt = stores.avatar
      const args = { token: session.authToken, id, data, gz }
      const ret = this.tr(await post(this, 'CrypterRaw', args))
      const priv = clesite ? null : aSt.getAvatar(id).priv
      const res = await decrypterRaw(priv, clesite, ret.data, gz)
      return this.finOK(res)
    } catch (e) {
      await this.finKO(e)
    }
  }
}
*/

# Ngrok : tunnel pour accéder au `localhost` d'un site de DEV

Sur le site de DEV, un serveur HTTP peut être lancé et écouter le port 8443 par exemple.

Préalablement dans un terminal ou aura lancé les commandes:

    ngrok config add-authtoken MONTOKEN
    ngrok http http://localhost:8443
    ngrok http --domain=exactly-humble-cod.ngrok-free.app 8443

En retour il apparaît une URL https://...

Cette URL peut être utilisée n'importe où, en particulier depuis un mobile, pour joindre le serveur sur le localhost du site de DEV, grâce à un tunnel établi par Ngrok.

### Token d'authentification
Il a été généré à l'inscription sur le site Ngrok:
- login:
- pwd:

Le token est disponible sur le site.

De plus il est sauvé dans un fichier local lors de l'authentification.

Authtoken saved to configuration file: /home/daniel/snap/ngrok/179/.config/ngrok/ngrok.yml

____________________________________________

npx update-browserslist-db@latest