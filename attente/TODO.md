## Dev
ChargerGMS : ne charge pas chatgrs. Oubli ? (sync)

DisparitionMembre: nag pas mis à jour 0 / 1 ?

NouveauGroupe : son chatgrs n'est pas créé (on attend la première insertion d'un item)

Création d'un chat: il faut que le contact ne soit pas uniquement connu en tant que simple contact de groupes.

Vérifier les conditions de prise d'hébergement d'un groupe

Suppression d'un avatar / groupe sur note-store.js: vérifier / tester

### Meta-données sur le serveur
Certaines opérations sur le serveur, voient passer des _meta-liens_ temporairement à l'occasion d'une opération: un serveur pirate _pourrait_ les tracer au fil de l'eau.

Ça semble se limiter à l'enregistrement de dlv ou quelques opérations voit passer groupées des avatars et des membres.
- AvGrSignatures
- SetQuotas : ça change la dlv du compte A
- MuterCompte
- MajChat: quand il y a un don associé
- AjoutSponsoring: quand le sponsor est un compte A (don)
- MajCredits: le compte qui reçoit ses crédits à sa dlv qui change

## Doc
UI

Présentation ...

Aide en ligne

## Tests
Retester Firestore / Gc

Retester GAE

Retester S3

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
