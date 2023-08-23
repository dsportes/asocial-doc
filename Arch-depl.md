# Architecture générale et déploiements

# Architecture générale 
L'application est une application Web, plus précisément une _PWA Progressive Web App_ : 
- l'application est invoquée au moins une première fois depuis un navigateur moderne connecté à Internet,
- elle peut ensuite être invoquée depuis ce même navigateur sans être connecté à Internet mais avec des restrictions de service.

Quatre grands composants contribuent à ce service :
- **un serveur joignable sur Internet** par exemple sur l'URL https://asocial.demo.net : dépôt git `asocial-srv`
- **une application UI d'interface utilisateur s'exécutant dans un navigateur** qui a été ouverte par l'URL https://asocial.demo.net (ou https://asocial.demo.net/app): dépôt git `asocial-app`
- **un site Web statique** principalement documentaire accessible depuis le navigateur à l'URL https://asocial.demo.net/www. Dépôt gir `asocial-doc`.
- **un programme utilitaire de chargement local de fichiers** dans un répertoire local pouvant être téléchargé par Internet sous l'URL https://asocial.demo.net/upload (`upload.exe` pour la version Windows). Une fois téléchargé et lancé sur le poste où s'exécute le navigateur accédant à l'application, cet utilitaire permet de récupérer dans un répertoire local au poste les notes et leurs fichiers de la sélection opérée par l'utilisateur. L'utilitaire est facultatif, n'est utile que pour cette seule opération de transfert local et peut être arrêté quand cette opération est terminée. Dépôt git `upload`.

Bien que le protocole de communication soit HTTPS, les données des comptes, les textes et fichiers de leurs notes, etc. sont **cryptées** dans l'application UI : le serveur ne reçoit **jamais** aucune information sensible en clair ni aucune clé de cryptage.

Les quatre composants ont été développés / écrits sous `VSCode` et sont disponibles dans `github.com/dsportes` en _public_ (licence ISC).

## Le serveur joignable sur Internet
C'est un serveur Web en technologie `node.js`, écrite 100% en Javascript.

Il reçoit les requêtes entrantes sur une URL fixée par l'administrateur technique. 

Les requêtes, 
- d'obtention de l'application UI / ou /app,
- d'accès au site Web /www/...
- et quelques requêtes techniques (/ping ...) 

sont acceptées librement : appel direct par une URL dans un navigateur ou curl ou une page chargée depuis n'importe quel site.

En revanche les requêtes de l'application UI ne sont acceptées QUE si la page de cette application a été chargée depuis une des URLs acceptées par la configuration du serveur. Ce contrôle de _l'origine_ de l'application UI est capital : il protège le serveur d'un accès depuis une application UI _pirate_, non distribuée par le site officiel et bien identifié de distribution de l'application UI.

**Selon sa configuration, le serveur accède à une _base de données_** d'une des deux technologies suivantes:
- **SQL** : c'est une base de volume modeste stockant les informations sur les comptes et les textes de leur notes. La technologie `sqlite` a été utilisée mais une extension à d'autres produits serait développable à coût minime. L'administrateur technique du site met en place le backup en continu de cette base sur un site distant et sa reprise après sinistre en un temps limité.
- **Firestore** : cette base orientée _document_ NOSQL, est hébergée sur des sites multiples sécurisés et administrés par Google qui en assure la haute disponibilité à coût supportable.

**Selon sa configuration, le serveur accède à un _storage_** des fichiers attachés aux notes d'une des technologies suivantes:
- `fs` : **File-system**. Stockage dans un répertoire local proche du serveur. Utilisation en pratique limité aux tests.
- `gc` : **Google Cloud Storage**. Le stockage redondant est assuré par Google sur des sites externes spécialisés.
- `s3` : **Amazon S3**. S3 est le nom du protocole et plusieurs fournisseurs (en plus de Amazon) proposent ce type de services. Il existe même une application `minio` qui permet de mettre en œuvre son propre stockage sur le(s) serveur(s) de son choix.

Selon le choix de l'administrateur technique, le déploiement du ou des instances de serveurs peut s'effectuer:
- **sur un serveur classique**, par exemple une VM hébergée chez un hébergeur, avec l'usage d'un frontal de type nginx qui n'est indispensable que quand il y a plusieurs instances de serveurs et d'application UI à configurer et déployer.
- sur **Google App Engine (GAE)**. Dans ce cas la base de données est Firestore et logiquement le provider de storage est `gc` (plutôt que `s3`).

Les coûts, la sécurité et la charge d'administration diffèrent fortement d'une option à l'autre.

**Chaque instance** est préparée pour sa distribution :
- en ajustant la configuration dans le fichier `src/config.mjs`, en particulier en listant les _origines_ des applications UI acceptées,
- en préparant les quelques fichiers de _signature_ requis,
- **pour un déploiement GAE** en configurant de plus le fichier `app.yaml`,
- **pour les autres déploiements** en effectuant un _build_ `webpack` générant deux fichiers distribuables.

_Langue_ : quelques très rares textes gérés par le serveur apparaissent dans des traces techniques et sont généralement écrites en français pour un usage de développement / debug.

Les logs sont gérés par le module _Winston_ et dans le cas d'un déploiement GAE sont intégrés au système de log de Google Cloud (sinon ce sont des logs sur fichiers classiques).

## L'application UI
C'est une page Web développée en `Quasar`, une surcouche de composants au dessus de `vuejs`, écrite 100% en Javascript / css / HTML.

Cette application supporte un _build_ par webpack qui en délivre une application Web PWA de quelques (gros) fichiers distribuables sur un site hébergeur.

**L'application est à configurer avant _build_** dans le fichier `src/app/config.mjs` :
- plusieurs instances peuvent avoir la même configuration de la partie _profilage métier_;
- quelques valeurs en majuscules donnent des options (`DEV DEBUG BUILD APITK`) à changer, éventuellement, entre test et déploiement;
- `SRV` identifie le serveur à qui l'application doit s'adresser. 
  - **en test c'est un serveur local** qui délivre une build de test de l'applicatio UI (lancé par `quasar dev`),
  - l'application serveur est servie par un autre process / serveur, une autre URL.
  - **en déploiement**. Par simplification, quand l'application est chargée depuis le serveur lui-même (et non un autre serveur frontal comme `nginx`) cette adresse peut être laissée vierge, et dans ce cas la configuration d'une instance de l'application UI est nulle.

_Langue_
- tous les textes lisibles par l'utilisateur sont gérés par un composant I18n qui permet de les traduire dans différentes langues que l'utilisateur peut choisir par une icône dans sa barre supérieure.
- la traduction a été testée en français et en anglais: toutefois les 1500 textes utilisés sont écrits en français et restent à traduire en angalis, voire d'autres langues. Ces _dictionnaires_ font partie du source de l'application (ils ne sont pas externes).
- les panels d'aide en ligne font également partie du source de l'application ce qui permet de les utiliser en mode _avion_, déconnecté d'Internet. Ils sont aussi traduisibles en une autre langue que le français.

## Site Web documentaire
Il est géré dans `asocial-doc`.

Les _pages_ sont,
- écrites directement en HTML,
- écrites en MD et un script les traduits en HTML.

Un script de _déploiement_ permet de générer le folder à déployer avec les pages en HTML (plutôt qu'en MD) et les images utilisées sans déployer les quelques fichiers techniques de script ou les sources MD des pages générées.

_Langue_
- les pages sont nativement écrites en français.
- au fil du temps elles seront traduites en anglais, voire en d'autres langues.

## L'utilitaire upload
Cet utilitaire est un micro serveur Web qui reçoir en entrée des fichiers et en copie le contenu dans un folder local au choix de l'utilisateur. 

Une page Web standard n'est pas autorisée à écrire sur le système de fichier du poste, sauf quand l'utilisateur en donne l'autorisation et la localisation fichier par fichier : pour télécharger en local toutes les notes et leurs fichiers sélectionnées par l'utilisateur, ce qui peut représenter des centaines / milliers de fichiers et des Go d'espace, l'application UI fait donc appel au micro-serveur Web upload.

Le source consiste en moins de 100 lignes de code écrite en node.js / Javascript.

Un _build_ permet de récupérer deux exécutables, un pour Linux, l'autre Windows, autonomes: ils embarquent un ru-time node.js qui dispense l'utilisateur d'une installation un peu technique.

# Développement / déploiement

> Le fichier de configuration de l'application serveur (`src/config.mjs`) est décrit en détail en annexe du document `API-Serveur.md`.

## Projet Google
L'utilisation d'un projet Google ne se justifie que si on utilise au moins l'un des deux dispositifs `Firestore` `Cloud Storage`. Une implémentation uniquement `SQL` et `S3` par exemple n'en n'a pas besoin.

Depuis son compte Google, dans Google Console `https://console.cloud.google.com/`, on peut créer un nouveau projet : dans notre cas `asocial-test1`. Ce projet doit accéder aux environnements / APIs:
- **App Engine**. Même si finalement on n'utilise pas GAE, ceci fournit des ressources et en particulier un `session_account` qui sera utilisé par la suite, ce qui évite d'en créer un spécifique qui ne serait pas utilisable en cas de décision de déployer GAE.
- **Firestore**
- **Cloud Storage**

Le menu hamburger en haut à gauche permet de sélectionner tous les produits et surtout d'épingler ceux qu'on utilise:
- **APIs & Service**
- **Billing**: c'est là qu'on finit par donner les références de sa carte bancaire.
- **IAM & Admin** : voir ci-dessous.
- **App Engine**
- **Firestore** : voir ci-dessous.
- **Cloud Storage** : voir ci-dessous.
- **Logging** : pour explorer les logs App engine.
- Security (?)

**Firestore**
- _Data_ : permet de visualiser les données.
- _Indexes_ : il n'y a que des index SINGLE FIELD. Les _exemptions_ apparaissent, on peut les éditer une à une et en créer mais on ne peut pas (du moins pas vu comment) en exporter les définitions : ceci justifie l'utilisation de Firebase qui le permet.
- _Rules_ : idem pour la visualisation / édition mais pas l'import / export.

**Cloud Storage**
- _Buckets_ : on peut y créer des buckets et les visiter. Il n'a pas été possible d'utiliser avec Firebase un autre bucket que celui qu'il créé par défaut `asocial-test1.appspot.com`/

**IAM & Admin**
- _Service accounts_ : il y a en particulier le _service account_ créé par App Engine `asocial-test1@appspot.gserviceaccount.com` et que nous utilisons. Quand on choisit un des service accounts, le détail apparaît. En particulier l'onglet `KEYS` (il y a une clé active) qui va permettre d'en créer une pour nos besoins.

## Projet Firebase
Il faut en créer un dès qu'on utilise au moins l'un des deux dispositifs `Firestore` `Cloud Storage`. 
- possibilité d'importer / exporter les index et rules de Firestore,
- possibilité d'utiliser l'API Firebase Web (module `src/app/fssync.mjs` de l'application UI),
- utilisation des _emulators_ qui permettent de tester en local.

La console a cette URL : https://console.firebase.google.com/

A la création d'un projet il faut le lier au projet Google correspondant: les deux partagent le même _projectId_ `asocial-test1`. (processus flou à préciser).

## CLIs
Il y en a un pour Google `gcloud` et un pour Firebase `firebase`. Les deux sont nécessaires sur un poste de développement. Voir sur le Web leurs installations et documentation de leurs fonctions.

### `firebase`
Install de firebase CLI :
https://firebase.google.com/docs/cli?hl=fr#update-cli

    npm install -g firebase-tools
    firebase --help

Quelques commandes `firebase` souvent employées:

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

### Utilisation et authentification `gcloud`
Page Web d'instruction: https://cloud.google.com/sdk/docs/install?hl=fr

#### Utilisation de ADC
ADC permet de s'authentifier pour pouvoir utiliser les librairies. Cette option (il y en a d'autres) est systématiquement mise en avant par Google pour sa _simplicité_ mais finalement pose bien des problèmes.

Les commandes principales sont les suivantes:
- login _temporaire_ sur un poste:
  `gcloud auth application-default login`
- révocation sur ce poste:
  `gcloud auth application-default revoke`

Ceci dépose un fichier `application_default_credentials.json`
- Linux, macOS dans: `$HOME/.config/gcloud/`
- Windows dans: `%APPDATA%\gcloud\`

#### Problèmes
L'authentification donnée sur LE poste est _temporaire_ : absolument n'importe quand, d'un test à l'autre, un message un peu abscons vient signaler un problème d'authentification. Il faut se souvenir qu'il suffit de relancer la commande ci-dessus.

La librairie d'accès à Cloud storage ne se satisfait pas de cette authentification, a minima pour la fonction indispensable `bucket.getSignedUrl` : celle-ci requiert une authentification par _service account_ dès lors ADC n'est plus une option de _simplicité_ mais d'ajout de complexité puisqu'il de toutes les façons à gérer un service account.

En production ? Google dit que App Engine fait ce qu'il faut pour que ça marche tout seul. Voire, mais pour le service account requis pour créer un storage, il a été permis d'en douter.

Et quand on n'utilise pas App Engine ? Il faut utiliser une clé de service account et la passer en variable d'environnement.

#### Solution : créer un _service account_
En fait comme vu ci-avant il y en a un pré-existant `asocial-test1@appspot.gserviceaccount.com`

Dans le détail de ce service l'onglet `KEYS` permet de créer une clé: en créer une (en JSON). Il en résulte un fichier `service_account.json` qu'il faut sauvegarder en lieu sûr et pas dans git: il contient une clé d'authentification utilisable en production. Cette clé,
- ne peut PAS être récupérée depuis la console Google,
- mais elle peut y être révoquée en cas de vol,
- en cas de perte, en créer une autre, révoquer la précédente et ne pas perdre la nouvelle.

Pour être authentifié il faut que la variable d'environnement `GOOGLE_APPLICATION_CREDENTIALS` en donne le path.

**Remarques:**
- il n'a pas été possible de donner le contenu de cette clé en paramètres lors de la création de l'objet d'accès à Firesore: `new Firestore(arg)` est censé accepter dans `arg` cette clé mais ça n'a jamais fonctionné, même quand le fichier `application_default_credentials.json` a été supprimé de `$HOME/.config/gcloud/`.
- il FAUT donc que le path de fichier figure dans la variable d'environnement `GOOGLE_APPLICATION_CREDENTIALS` au moment de l'exécution: ceci est fait au début du module `src/server.js` en utilisant le `service_account.json` dans le répertoire `./config` (qui est ignoré par git).
- pour le déploiement, ce fichier fait partie des 4 à déployer séparément sur le serveur (voir plus avant).
- _pour information seulement_: il _semble_ que le contenu soit accepté par la création d'un accès au storage Google Cloud : dans `src/storage.mjs` le code qui l'utilise est commenté mais peut être réactivé si l'usage d'une variable d'environnement pourrait être supprimé. Mais l'intérêt est quasi nul puisque la génération d'une variable d'environnement dans `server.js` représente une ligne de code.

### Authentification `firebase`
L'API WEB de Firebase n'est PAS utilisé sur le serveur, c'est l'API Firestore pour `Node.js` qui l'est.

L'application UI utilise l'API Web de Firebase (la seule disponible en Web et de formalisme différent de celle de Google Firestore) pour gérer la synchronisation des mises à jour. En particulier les fonctions :
`getFirestore, connectFirestoreEmulator, doc, getDoc, onSnapshot`

L'objet `app` qui conditionne l'accès à l'API est initialisé par `const app = initializeApp(firebaseConfig)`.
- le paramètre `firebaseConfig` ci-dessus est un objet d'authentification qui a été transmis par le serveur afin de ne pas figurer en clair dans le source et sur git. Ce paramètre dépend bien sur du site de déploiement.

##### Obtention de `firebase_config.json`
- Console Firebase
- >>> en haut `Project Overview` >>> roue dentée >>> `Projet Settings`
- dans la page naviguer jusqu'au projet et le code à inclure (option `Config`) apparaît : `const firebaseConfig = { ...`
- le copier, le mettre en syntaxe JSON et le sauver sous le nom `firebase_config.json`, en sécurité hors de git. Il sera à mettre pour exécution dans `./config`

### Authentification S3
Le provider de storage `S3Provider` a besoin d'un objet de configuration du type ci-dessous (celle de test avec `minio` comme fournisseur local S3):

    {
      credentials: {
        accessKeyId: 'access-asocial',
        secretAccessKey: 'secret-asocial'
      },
      endpoint: 'http://localhost:9000',
      region: 'us-east-1',
      forcePathStyle: true,
      signatureVersion: 'v4'
    }

Un fichier JSON nommé `s3_config.json` est recherché dans `./config` (à côté des autres fichiers contenant des clés privées) afin de ne pas exposer les autorisations d'accès S3 dans un fichier disponible sur git.

## Emulators de Firebase
Cet utilitaire permet de travailler, en test, localement plutôt que dans une base / storage distant payant.

Pour tester de nouvelles fonctionnalités on peut certes tester en environnement SQL / File-system : mais pour tester que la couche technique de base (dans `src/modeles.mjs src/storage.mjs` du serveur) offre bien des services identiques quelqu'en soit l'option choisie Firebase / SQL ou le provider de storage file-sytem / S3 / Google Cloud, il faut bien utiliser Firestore et Cloud Storage.

L'émulateur est lancé par:

    firebase emulators:start
    firebase emulators:start --import=./emulators/bk1

Dans le premier cas tout est vide. Dans le second cas on part d'un état importé depuis le folder `./emulators/bk1`

Tout reste en mémoire mais on peut exporter l'état en mémoire par:

    firebase emulators:export ./emulators/bk2 -f

**La console de l'emulator** est accessible par http://localhost:4000

Voir la page Web: https://jsmobiledev.com/article/firebase-emulator-guide/

**Attention**: Google mentionne _son_ emulator dans la page https://cloud.google.com/firestore/docs/emulator?hl=fr
- ça ne prend en compte que Firestore et pas Cloud Storage,
- l'usage n'a pas été couronné de succès.

A ce jour prendre celui de Firebase.

### Contraintes
- Firebase n'a pas implémenté _toutes_ les fonctionnalités. Il y a du code qui contourne ce problème dans `src/storage.mjs` :
  - la création du storage ne prend pas en compte l'option `cors` (`constructor de la class GcProvider`),
  - `getSignedUrl` n'est pas utilisable avec l'émulator : contournement dans `getUrl` et `putUrl`.
- en run-time le code tient compte du mode `emulator` qui est donné par un booléen dans `src/config.mjs`.
- dans l'application UI l'initialisation dans `src/app/fssync.mjs` méthode `open()` tient compte du mode `emulator`:
  - l'application UI obtient en retour de connexion d'une session, l'objet requis `firebaseConfig` et le booléen `emulator`.
  - auparavant l'usage de l'URL `./fs` a retourné 'true' ou 'false' selon que le serveur est en mode Firestore (true) ou SQL (false).

Sur le serveur deux variables d'environnement sont requises :
- `FIRESTORE_EMULATOR_HOST="localhost:8080"`
- `STORAGE_EMULATOR_HOST="http://127.0.0.1:9199"`

Attention pour la seconde, 
- le Web donne un autre nom: bien utiliser celui ci-dessus,
- `http://` est indispensable, sinon un accès `https` est essayé et échoue.

Ces deux variables sont générées en interne dès le début de `src/server.js` quand le booléen `emulator` a été trouvé dans la configuration, ce qui évite de les gérer en test et de les exclure en production.

## BUGS rencontrés et contournés: `cors` `403`
Pour information, les fonctions de download / upload d'un fichier d'une note ont d'abord échoué en Google Cloud storage : l'URL générée étant rejetée pour cause `same origin`.

Ce type de problème n'apparaît que dans une invocation dans un browser pour une page chargée depuis un site Web. En conséquence ça n'apparaît pas,
- en copiant directement une URL dans la barre d'adresse,
- en utilisant `curl`.

Il n'y a que le serveur qui puisse résoudre le problème.

Pour Google Cloud storage on peut passer à l'initialisation du storage un objet d'options `cors` qui spécifie de quelles origines les URLs sont acceptées. Par chance `'*'` a été accepté : sinon il faut passer en configuration une liste d'origines autorisées.

A noter que dans `emulator`, cette option n'étant pas implémentée, il a fallu contourner par en chargement / déchargement par le serveur (ce qui n'est ps un problème en test, mais en serait un en production).

Pour générer une URL signée, sur PUT, il faut spécifier le `content-type` des documents envoyés sur PUT. `application/octet-stream` fait l'affaire MAIS encore faut-il émettre ce `content-type` du côté application UI dans l'appel du PUT (`src/app/net.mjs`), ce qui n'avait pas été fait (laissé vide) et a provoqué une erreur `403` pas très représentative de la situation.

### Variable d'environnement `GOOGLE_CLOUD_PROJECT`
Assez systématiquement une librairie se plaint : `cannot determine the project_id ...`

C'est parce que la variable d'environnement `GOOGLE_CLOUD_PROJECT` n'a pas été initialisée avec le code du projet.

Pour éviter cet oubli cette variable est générée par `src/server.js` en fonction de la valeur trouvée dans `src/config.mjs`.

## Environnements DEV / PROD

Le folder `./config` est ignoré par git et contient au plus 5 fichiers:
- `fullchain.pem privkey.pem` : le certificat HTTPS du site. Ces fichiers sont renouvelés avec `letsencrypt` tous les 3 mois et ne sont pas à rendre public.
- `firebase_config.json service_account.json s3_config.json` : voir ci-avant. Ils n'ont pas à être renouvelés mais ne doivent surtout pas être rendus public.

En développement le folder `./config` est à ce path, en production il peut être ailleurs: ce path relatif figure dans `src/config.mjs >>> pathconfig`

### Paths
D'autres paths sont cités dans `src/config.mjs` et peuvent différer en développement et en production:
- `pathapp: './app'` Localisation relative du folder de l'application UI quand elle est servie par le serveur.
- `pathconfig: './config'` Localisation relative du folder contenant les 5 fichiers de configuration.
- `pathsql: './sqlite/test1.db3'` Localisation relative de la base SQL en déploiement SQL.
- `pathlogs: './logs'` Localisation du folder contenant les logs.

Quand le provider de storage est `fs` (file-system), sa configuration mentionne aussi un path. C'est plutôt une option d'environnement de test.

### Logs
Ils sont gérés par Winston: 
- sauf pour App engine `combined.log error.log` : le path est fixé dans `src/config.mjs >>> pathlogs` mais les noms sont en dur dans` src/server.js`.
- pour App Engine, c'est redirigé vers les logs de App Engine.

`firestore.debug.log ui-debug.log` sont des logs produits par emulator en DEV.

### Autres Fichiers apparaissant à la racine en DEV
- `firebase.json` : utilisé par emulator et les opérations CLI de Firebase.
- `firestore.indexes.json firestore.indexes.EXP.json firestore.rules` : index et rules de Firestore, utilisé par CLI Firebase pour les déployer en production.
- `app.yaml` : pour le déploiement sur App Engine.

### Folders spécifiquement utilisés en DEV
- `config`
- `storage` : storage des providers `fs` (file_system)
- `sqlite`
  - `*.db3` : des bases de test.
  - `delete.sql` : script pour RAZ d'une base
  - `schema.sql` : script de création d'une base db3
  - `schema.EXP.sql` : script exporté depuis une base existante par la commande `sqlite3 test1.db3 '.schema' > schema.EXP.sql` dans le folder `sqlite`.

### Rappel : variables d'environnement
Elles sont générées par `src/seveur.js` en fonction de `src/config.mjs` : elles n'ont pas à être gérées extérieurement.

    FIRESTORE_EMULATOR_HOST="localhost:8080"
    STORAGE_EMULATOR_HOST="http://127.0.0.1:9199"
    GOOGLE_CLOUD_PROJECT="asocial-test1"
    GOOGLE_APPLICATION_CREDENTIALS="./config.service_account.json"

# Déploiements
Il existe deux déploiements _simples_:
- **Google App Engine** (GAE): un répertoire de déploiement est préparé et la commande `gcloud app deploy` effectue le déploiement sur le projet correspondant.
- **Mono serveur node** (MSN): un répertoire de déploiement est préparé puis est transféré sur le site récepteur par ftp typiquement.

Il est aussi possible d'avoir des **déploiements multi serveurs** pour l'application UI et des serveurs `Node.js` multiples.

### APITK
Une application _pirate_ lancée depuis un browser qui a chargé une page d'application UI _pirate_, va échouer à invoquer des opérations, son `origin` n'étant pas dans la liste des origines autorisées par le serveur.

Mais supposons une application _pirate_ en node.js qui reprend correctement le protocole :
- elle peut positionner un `header` `origin` avec la valeur attendue par le serveur,
- elle peut se connecter et exécuter des opérations normales mais en lui transmettant de mauvais arguments (puisqu'elle est _pirate_).

C'est pour ça qu'une _clé d'API_ `APITK` a été définie, et cachée autant que faire se peut: cette clé est fournie à chaque appel d'opération.

Cette clé est définie au déploiement et n'est donc pas donnée aux pirates.

Elle figure toutefois en runtime de l'application UI, donc est lisible quelque part en debug d'une application officielle. Encore faut-il savoir la trouver, ce qui a été rendu un peu complexe.

## Déploiements simples: processus commun
Il est bien entendu possible de déployer sur plusieurs projets GAE, chacun ayant alors son répertoire de déploiement dénommé ci-après %DEPL%.

**L'application UI %APP% doit être buildée:**
- en général il n'y a pas à ajuster `quasar.config.js` sauf si `APITK` a changé.
- dans src/app/config.mjs :
  - définir la variable `SRV`: en test elle a une valeur pour que l'application générée par quasar dev pointe vers le serveur de test. **En GAE il suffit de commenter sa ligne**.
  - changer la valeur de `BUILD` pour la voir apparaître à l'écran pour contrôle de la bonne évolution de version.
- lancer la commande `npm run build:pwa` (ou `quasar build -m pwa`): ceci créé le folder `/dist/pwa` avec l'application compactée.

**L'application upload (folder %UPLOAD%) doit avoir été buildée.**
Il en résulte deux fichiers `upload upload.exe` à copier dans le répertoire `%DEPL%/www`. Lire son `README.md` pour quelques détails.

### Créer / ajuster le folder %DEPL%
Sa structure est la suivante:
- `/config` : reçoit les fichiers de configuration.
- `/www` :
  - le fichier `index.html` est une redirection vers `/www/home.html`, la _vraie_ page d'entrée. (source: `%SRV%/www/index.html`).
  - `upload upload.exe` sont des liens symboliques vers `%UPLOAD%/dist/upload` et `%UPLOAD%/dist/upload.exe` 
  - les autres fichiers proviennent de `%DOC%` et y ont été copiés par un script local de `%DOC%`.
- `/app` : lien symbolique vers la distribution de l'application UI (`%APP%/dist/pwa`).

### Déploiement _Google App Engine_ (GAE)
C'est App Engine qui build l'application.

**Remarques importantes**
- le fichier `src/server.js` **DOIT** avoir une extension `.js`. Les imports dans les autres modules doivent donc être `import { ctx, ... } from './server.js'`
- dans `package.json`:
  - `"type": "module",` est **impératif**.
  - `"scripts": { "start": "node src/server.js" }` et pas de `"build": ...`.

Au pire, enlever les `"devDepencies"` de package.json selon le message d'erreur à propos de webpack émis par GAE.

Le fichier `src/config.mjs` est à adapter pour le déploiement GAE. En pratique, un seul flag en tête `true/false` permet de le passer du mode développement au mode GAE. A minima:
- `rooturl: 'asocial-test1.ew.r.appspot.com',` sinon les opérations entrantes sont refoulées.
- `origins: [ 'localhost:8343' ],` ne gêne pas, `rooturl` est ajouté à la liste des origines acceptées.

Le script `depl.sh` :
- recopie les fichiers de configuration `service_account.json` et `firebase_config.json` dans `%DEPL%/config`
- recopie www/index.html dans `%DEPL%/index.html`
- recopie le folder `src` dans `%DEPL%/src`
- recopie les deux fichiers `package.json app.yaml` dans `%DEPL%`.

Ouvrir un terminal dans `%DEPL%` et frapper la commande `gcloud app deploy --verbosity debug` : ça dure environ 2 minutes (pas la première fois qui beaucoup plus longue, jusqu'à 15 minutes). `verbosity` est facultatif.

Dans un autre terminal `gcloud app logs tail` permet de voir les logs de l'application quand ils vont survenir.

Les logs complets s'obtienne depuis la console Google du projet (menu hamburger en haut à gauche `>>> Logs >>> Logs Explorer`).

### Déploiement _mono serveur node_ (MON)
Il faut créer / ajuster le répertoire `%DEPL%` comme décrit ci-avant.

**Il faut effectuer un build de `%SRV%` :**
- dans `package.json`:
  - `"type": "module",` ne doit **PAS être présent** (le renommer `"typeX"`).
- commande de build `npx webpack`
- deux fichiers ont été créés dans `dist`: `app.js app.js.LICENSES.txt`
- dans `%DEPL%` faire un lien symbolique vers ces deux fichiers.

**Sur le Site distant** on doit trouver, hors du folder qui va recevoir le déploiement, par exemple dans le folder au-dessus:
- `../sqlite.db3` : le fichier de la base données. Dans `%SRV%/src/config.mjs` l'entrée `pathsql: '../sqlite.db3'` doit pointer vers ce fichier;
- `../logs` : le folder des logs. Dans `%SRV%/src/config.mjs` l'entrée `pathslogs: '../logs'` doit pointer vers ce folder.

En résumé à titre d'exemple **sur le site distant**:

    asocial
      sqlite.db3
      logs/
      run/
        config/ ...
        www/ ...
        app/ ...
        app.js
        app.js.LICENSES.txt

Il faut transférer par ftp le contenu du répertoire local `%DEPL%` dans le répertoire distant `asocial/run`.

Le serveur se lance dans `asocial/run` par `node app.js`

### Déploiement multi serveurs
Les trois composantes,
- instances d'application UI,
- instances d'applications serveur node,
- espace statique www,

sont gérées / déployées séparément.

Un server `nginx` gère autant de serveurs virtuels qu'il y a d'application UI:
- chacune est buildée avec un paramétrage spécifique;
- a minima dans `src/app/config.mjs` la variable `SRV` donne l'URL de **SON** serveur.

Il en résulte autant de builds et donc de déploiements à effectuer pour les applications UI.

Il faut également builder chaque instance d'application serveur:
- son PORT d'écoute (`src/config.mjs / port`) est différent. 
- `rooturl` _peut_ être limité au _host name_ si elle n'est pas utilisée par le provider de storage configuré.
- `origins` doit être configuré pour n'accepter les requêtes QUE de l'instance d'application UI spécifiée.

Il y a autant de serveurs `node` à lancer qu'il y a d'instances de serveurs définies.

Le déploiement demande en conséquence un script spécifique pour enchaîner sans risque d'erreurs les altérations de `config.mjs`, les builds (UI et serveur) et les recopies dans les folders de déploiement. 

Il faut aussi scripter les envois ftp aux bonnes localisations sur le(s) site(s) de production.
