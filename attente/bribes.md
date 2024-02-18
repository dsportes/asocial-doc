## Firebase tool

    npm install -g firebase-tools
    firebase --help

    // Pour se ré-authentifier quand il y a un problème d'authentification
    firebase login --reauth

    // Delete ALL collections
    firebase firestore:delete --all-collections -r -f

    // Déploiement / import des index et rules présents dans: 
    // `firestore.indexes.json  firestores.rules`
    firebase deploy --only firestore

    // Export des index
    firebase firestore:indexes > firestore.indexes.EXP.json

    // Emulators :
    firebase emulators:start
    firebase emulators:start --import=./emulators/bk1
    firebase emulators:export ./emulators/bk2 -f


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

