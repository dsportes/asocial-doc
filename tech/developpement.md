# Généralités

Le développement a été réalisé avec le studio `VScode`.

Installations préliminaires requises:
- `node`, installé par `nvm`.
- `yarn`.
- `webpack` est utilisé pour le packaging mais est installé directement dans les applications.

L'application Web est basée sur **Vue.js** (`vuejs.org`) avec la surcouche **Quasar** (`quasar.dev`).
- HTML et SASS (et non CSS),
- Javascript.
- `pinia` gère les _stores_.

Les _services_ sont du pur `Node.js` (Javascript), ainsi que l'utilitaire _upload_.

Le versioning est assuré sur github.com et par yarn

# Développement de l'application Web
Installer quasar CLI:

    yarn global add @quasar/cli

L'application est une **PWA** (Progressive Web App) avec gestion d'un service_worker.

Principaux modules requis:
- `core-js`
- `animate.css`
- `msgpack` : sérialisation / désérialisation d'bjets Javascript.
- `axios` : accès HTTP.
- `dexie` : accès aux bases IDB.
- `emoji-mart-vue-fast` : saisie d'emojis.
- `file-saver` : sauvegarde d'un fichier dans le browser.
- `mime2ext` : conversion de type MIME n code d'extensions de fichier.
- `vue-showdown` `github-markdown-css` : transformation d'un MD en HTML.
- `vue-advanced-cropper` : gestion locale d'une image (resize / crop).
- `pako` : compression / décompression GZIP de binaires.
- `simple-keyboard` : keyboard utilisable à la souris pour la saisie des phrases secrètes.
- `webcam-eaysy` : gestion de la webcam.
- `js-sha256` : hash SHA256 synchrone.
- `vue vue-i18n vue-router pinia` : modules de `vue`
- `quasar`

Lire le détail dans `package.json`

**Remarques pour i18n**. Dans `src/boot/i18.js` 
- ajouter `legacy: false,` sinon choix-langue ne s'initialise pas bien.
- importer `configStore` pour récupérer la valeur initiale de la locale.

### Fichier `quasar.config.js`
Les personnalisations majeures sont:
- `build.extendWebpack (cfg)` : règles pour le chargement des `.md .txt .svg`
- `devServer` : la configuration minimale (choix du port) pour le test.

#### Configuration de VScode pour le debug
Elle se fait dans `launch.json`. 
- Depuis VScode _>>> Run >>> Open configurations_

    {
    "version": "0.2.0",
    "configurations": [
        {
        "type": "chrome",
        "request": "launch",
        "name": "Quasar App: chrome",
        "url": "http://localhost:8081?doda",
        "webRoot": "${workspaceFolder}/src",
        "sourceMapPathOverrides": {
            "webpack://asocial/./src/*": "${webRoot}/*"
        }
        }
    ]
    }

Le build de test et le serveur de test se lancent par: `quasar dev -m pwa`

Voir le détail dans le document `applicationWeb.md`

# Développement Firestore
Il y a une dualité entre Firebase et Google Cloud Platform:
- `firestore, storage, functions et hostings` sont effectivement hébergés sur Google.
- la console Firebase propose une vue et des fonctions plus simples d'accès mais moins complètes.
- il faut donc parfois retourner à la console Google pour certaines opérations.

Consoles:

    https://console.cloud.google.com/
    https://console.firebase.google.com/

## CLI Firebase
https://firebase.google.com/docs/cli

Installation ou mise à jour de l'installation

    npm install -g firebase-tools

### Authentification

    firebase login

**MAIS ça ne suffit pas toujours,** il faut régulièrement se ré-authentifier:

    firebase login --reauth


### Delete ALL collections
Aide: firebase firestore:delete -

    firebase firestore:delete --all-collections -r -f

### Déploiement des index et rules
Les fichiers sont:
- firestore.indexes.json
- firestore.rules

    Déploiement (import)
    firebase deploy --only firestore:indexes

    Export des index dans firestore.indexes.json
    firebase firestore:indexes > firestore.indexes.EXP.json

### Emulator
Dans src/config.mjs remplir la section env:

    env: {
       // On utilise env pour EMULATOR
      STORAGE_EMULATOR_HOST: 'http://127.0.0.1:9199', // 'http://' est REQUIS
      FIRESTORE_EMULATOR_HOST: 'localhost:8080'
    },

Remarques:
- Pour storage: 
  - le nom de variable a changé au cours du temps. C'est bien STORAGE_...
  - il faut `http://` devant le host sinon il tente https
- Pour Firestore il choisit le port 8080. Conflit éventuel avec app par exemple.
- En cas de message `cannot determine the project_id ...`
  `export GOOGLE_CLOUD_PROJECT="asocial-test1"`

**Commandes usuelles:**

    Lancement avec mémoire vide:
    firebase emulators:start --project asocial-test1

    Lancement avec chargée depuis un import:
    firebase emulators:start --import=./emulators/bk1

    Le terminal reste ouvert. Arrêt par CTRL-C (la mémoire est perdue)

En cours d'exécution, on peut faire un export depuis un autre terminal:

    firebase emulators:export ./emulators/bk2 -f

**Consoles Web sur les données:**

    http://127.0.0.1:4000/firestore
    http://127.0.0.1:4000/storage

### Création d'un `service_account` Google
https://cloud.google.com/iam/docs/service-accounts-create

https://cloud.google.com/iam/docs/keys-create-delete#creating

Accéder au(x) service_account depuis la console
- `menu hamburger >> IAM & Admin >> Service Accounts`
- il y a 4 onglets. C'est l'onglet KEYS qui permet d'en générer un.
- Bouton `ADD KEY` et choisir `Create New Key`
- choisir le format JSON : ceci download le fichier.
- le sauvegarder en lieu sûr, il est impossible de le récupérer à nouveau.
  - on pourra seulement détruire cette clé,
  - en récréer une nouvelle comme décrit ci-dessus.

In fine, le json est intégré dans `src/keys.mjs` en syntaxe JS.

### `gcloud CLI` - CLI Google Cloud
https://cloud.google.com/sdk/docs/install


### demo-monprj
_Création_ au lancement de l'emulator

https://stackoverflow.com/questions/67781589/how-to-setup-a-firebase-demo-project


# Purgatoire
### Ne pas utiliser ADC
Auth gcloud ADC: mais c'est "temporaire"
- gcloud auth application-default login

Revoke ADC:
- gcloud auth application-default revoke 

OU : ça marche aussi, différence avec au-dessus ? ca dure encore moins longtemps !!!!
- gcloud auth application-default login --impersonate-service-account daniel.sportes@gmail.com

    Linux, macOS: 
    $HOME/.config/gcloud/application_default_credentials.json
    
    Windows:
    %APPDATA%\gcloud\application_default_credentials.json

Déploiement gcloud:
- gcloud app deploy --verbosity debug
- gcloud app logs tail

Variables env:
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/application_default_credentials.json"

export GOOGLE_APPLICATION_CREDENTIALS="$HOME/git/asocial-test1/config/service_account.json"

Powershell
$env:FIRESTORE_EMULATOR_HOST="[::1]:8680"
$env:FIRESTORE_EMULATOR_HOST="localhost:8080"

Linux
export FIRESTORE_EMULATOR_HOST="localhost:8080"