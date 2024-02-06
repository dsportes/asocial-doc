## Dev
Création d'un chat: il faut que le contact ne soit pas uniquement connu en tant que simple contact de groupes.

GC : dlv dépassée sur membres. Si le membre est l'hébergeur, activer `dfh`. A vérifier.

Vérifier les conditions de prise d'hébergement d'un groupe

Suppression d'un avatar / groupe sur note-store.js: vérifier / tester

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

Lancement du serveur npm http-server (en https avec les bons certificats)

http-server D:\git\asocial-app\dist\pwa -p 8343 -C D:\git\asocial-test1\config\fullchain.pem -K D:\git\asocial-test1\config\privkey.pem -S -P https://test.sportes.fr:8343


# Dates limite de validité `dlv` des comptes
Chaque compte a une date limite dans son `versions` de son avatar principal, arrondie à la fin du mois, répétée dans les `versions` de ses avatars secondaires et ses `membres`.

**Maintien en vie d'un compte en l'absence de connexion**
- pour un compte O:
 - ressources mobilisées pour rien,
 - avance de frais d'hébergement.
- pour tous les comptes sur chaque appareil: synchronisation de bases locales très _anciennes_ obligeant à garder des versions _zombi_ très longtemps.

## Connexion d'un compte
- 60 jours avant `dlv`: alerte
- après `dlv`: connexion impossible.

## dlv
- sur `versions` des groupes, `notes` : crées avec `max`
- sur `versions` des avatars et `membres` avec celle calculée au login voire recalculée après (positive).
- sur `sponsorings` : celle fonctionnelle.

**État _zombi_:** : `dlv < auj`. Le _data_ est null, le row ne change plus de version.

## GC : purges sur dlv `20000101 < dlv < auj`
- _Remarque_: les `dlv` inférieures au début du siècle ne sont plus des dates mais des valeurs symboliques: 
  - `1` pour forcer la purge, 
  - `aamm` pour une date de purge.
- sur les `versions` des avatars (les `versions` des groupes vivants ont une `dlv` max): 
  - SI principal (il a un `comptas`).
    - pour un compte O, mise à jour de `tribus`, création d'un `gcvols`.
    - purge de `comptas`
  - purge de `avatars`. 
  - la `dlv` de son `versions` est **mise à 1** (son _data_ devient null).
- sur les `membres`
  - purge du `membres`
  - Groupe restant vivant: maj du groupe (flags 0): maj `versions` du groupe
  - Groupe disparaissant: la `dlv` de `versions` du groupe est **mise à 1** (son _data_ devient null).

**Groupes: dépassement de la `dfh`**. A la limite de vie sans hébergeur, le groupe est supprimé:
- la `dlv` de sa `versions` (qui était max) passe à 1 et devient donc _zombi_.
- dans l'étape suivante du GC, le sous-arbre du groupe sera purgée, et la dlv indiquera que la purge a eu lieu.

**La suppression d'une note** lui met une `dlv` à auj (elle devient _zombi_) et reste ainsi jusqu'à purge de leur avatar / groupe.

**Chat : constat de disparition de E:**
- la `cva` est supprimée
- statut changé: `STE = 2`
- `nacc cc` restent: on garde le nom du disparu et en conséquence les infos (texte / mot clés) qui lui étaient associés.
- reste ainsi jusqu'à purge de son avatar.

### Purge des sous-arbres avatars et groupes
- filtre `versions` de `dlv == 1`
- à la fin des purges: **la `dlv` passe à `AAMM`** (année et mois de la date courante). _data_ reste null, **la version ne change pas** elle reste immuable dans un état _zombi_.
- le row `versions` reste _zombi_ mais ne sera plus sélectionnable pour purge des sous-arbres.

**La durée de survie des versions en _zombi_** est _très longue_: le volume reste faible.
- ces rows ne servent plus qu'à resynchroniser la micro base locale d'un compte sur un poste, avec l'état courant après N jours sans synchronisation, c'est à dire sans connexion synchronisée.
- un donnée de configuration donne le nombre `idbObs` de jours de validité d'une micro base locale sans resynchronisation. Elle devient obsolète (donc à supprimer avant connexion) `idbObs` jours après sa dernière synchronisation.
- une étape (mensuelle) du GC purge les versions ayant une `dlv` obsolète.

## `dlv` des comptes A
Elle est recalculée:
- à la connexion.
- au changement des valeurs d'abonnement q1 / q2.
- au changement du total des crédits: incorporation et dons.

Elle est arrondie à la fin du mois et n'est restockée que si elle change de mois.

> Tant que le compte a du crédit, même s'il ne se connecte plus, son compte reste vivant: un gros crédit avec un abonnement faible pourrait garantir des décennies sans connexion.

## `dlv` des comptes O
Deux préoccupations:
- un compte O qui se ne connecte plus, désintéressé, décédé, immobilise des quotas qui pourraient être utiles à d'autres. 
- l'administrateur technique gère une `dlvat` pour l'espace : date à laquelle l'organisation l'administrateur technique détruira les comptes O. Cette information est disponible dans l'état de la session pour les comptes O (les comptes A n'étant pas intéressés).
  - l'administrateur ne peut pas (re)positionner une `dlvat` à moins de M+3 pour éviter les catastrophes de comptes qui deviendraient purgeables à prochaine connexion.

A la connexion, la `dlv` d'un compte est recalculée à la date la plus proche,
- `dlvat`,
- aujourd'hui plus `nbi` mois, fixé par le Comptable dans l'espace.

### Le Comptable
Il a une `dlv` max non modifiable.

Il a des quotas faibles et non modifiables:
- MD : en V1 : nombre de notes / chats / groupes (32000 chats tout de même)
- XS : en V2, il n'a pas à avoir ni beaucoup de notes, ni de gros fichiers attachés à ces notes.

Il n'a pas d'avatars secondaires.

## Dans espaces:
- `dlvat`: `dlv` de l'administrateur technique.
- `nbi`: nombre de mois d'inactivité acceptable pour un compte O fixé par le comptable. Ce changement n'a pas d'effet rétroactif.

### Changement de `dlvat`
Si le financement de l'hébergement par accord entre l'administrateur technique et le Comptable d'un espace tarde à survenir, beaucoup de comptes O ont leur existence menacée par l'approche de cette date couperet. Un accord tardif doit en conséquence avoir des effets immédiats une fois la décision actée.

Par convention une `dlvat` est fixée au 1 d'un mois, jamais modifiée pour être inférieure à M + 3.

Par convention une `dlv` de `versions d'avatars / membres` (d'un compte) est fixée dernier jour du mois. 

**Remarque**: quand une `dlv` apparaît en `versions d'avatars / membres` au 1 d'un mois, c'est qu'elle est la limite de vie fixée dans l'espace par l'administrateur technique.

L'AT qui remplace une `dlvat`, va remplacer en une transaction, toutes les `dlv` des `versions d'avatars / membres` égale à l'ancienne `dlvat` et fixe la nouvelle dans la même transaction. La valeur de remplacement est,
- la nouvelle `dlvat` (au 1 d'un mois) si elle est inférieure à `auj + nbi mois`: c'est encore la `dlvat` qui borne la vie des comptes O (à une autre borne).
- sinon la fixe à `auj + nbi mois` (au dernier jour d'un mois), comme si les comptes s'étaient connectés aujourd'hui.
