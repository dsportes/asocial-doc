# Design général du _serveur_

Le design général permet selon l'option de configuration choisie,
- d'avoir un serveur HTTP unique assurant les services OP+PUBSUB,
- soit seulement le service OP,
- soit seulement le service PUBSUB.

Les sources sont hébergés dans github sous le nom de projet `asocial-srv`

### Installations prérequises
- `git`
- `node.js` (donc `npm`) par `nvm`, 
- `yarn`
- `SQLite` : `sqlite(.exe)` est utilisé pour effectuer des backup / restore
- `DBBrowser for SQLite`  pour charger le schémas, exécuter des scripts, parcourir les tables ...
- `VSCode`

- `firebase CLI` : pour les tests en Firestore / Storage de GCP
- `minio` : pour les tests S3

## Structure du folder de développement
`src/*`
- contient les modules de l'application détaillés ci-après.

`keys.json`
- données confidentielles de configuration hors git.

`index.js`
- amorce du service OP quand il est géré en _Cloud function_.

`index2.js`
- amorce du service PUBSUB quand il est géré en _Cloud function_.

**Folders / fichiers liés à VSCode**
- `.vscode .yarn .editorconfig .eslintignore .eslintrc.cjs`

**Folders / fichiers de données de test**
- `keys`: **hors git**, contient le certificat HTTPS du serveur en test `fullchain.pem privkey.pem` renouvelés assez fréquemment.
- `emulators/*`: sauvegarde des états internes des exécution d'émulation Firebase / Storage (GCP)
- `fsstorage/* fsstorageb/*`: storage de test en File-System
- `sqlite`: base de données de test SqLite:
  - `schema.sql` : script de création d'initialisation de la base.
  - `delete.sql` : script de reset des tables.
  - `test.db3` et 2 fichiers `wal` associés
  - `test1.bk test2.bk ...` : backups de la base dans des états privilégiés
  - `bk.sh bk.cmd` : shell scripts de backups de la base courante en `testX.bk`
  - `rst.sh rst.cmd` : shell scripts de restauration d'un textX.bk sur la base courante.

**Fichiers liés au test / déploiement de Firestore**
- `firebase.json` : configuration de test local
- `firebase-debug.log ui-debug.log`
- `firestore.indexes.json` : index Firestore
- `firestore.rules` : droits d'accès


**Fichier de configuration de minio pour tests S3 locaux**
- `minio.json`

**Autres folders / fichiers**
- `node_modules/*`
- `.gitignore` : fichiers à ne pas gérer dans git
- `package.json`
- `yarn.lock`
- `webpack.config.mjs` : pour génération d'un distribuable
- `README.md`
- `etc/*` : quelques fichiers temporaires pour mémoire
- `depl.sh ...` : shell scripts d'aide au déploiements.

## Modules du serveur
### Configuration: `src/config.mjs src/icon.mjs keys.json src/genicon.mjs`
La configuration _de base_ (options par défaut, mais incomplète) est inscrite dans `src/config.mjs`.

Elle est surchargée à l'exécution par la configuration spécifique donnée par l'administrateur technique exprimée dans `keys.json` qui contient:
- les clés d'authentification d'accès aux services externes (Google Firestore / Storage), S3, de connexion aux bases ...
- le hash de la clé d'authentification de l'administrateur technique,
- la clé de cryptage des données dans la base,
- les clés publique / privée VAPID de notification web-push.

En conséquence en raison de la confidentialité requise pour ces données sensibles, `keys.json` n'est pas disponible dans le dépôt git du serveur.
- en développement / déploiement, ce fichier est _crypté_ et devient le fichier `src/icon.mjs`
- au lancement de l'application serveur, `config.mjs` importe ce fichier, en décrypte le contenu et installe toutes ses entrées dans l'objet `config` du module `config.mjs`
- l'objet `config` est importé ensuite dans les autres modules en ayant besoin.

Le cryptage de keys.json en `src/icon.mjs` est assuré par la commande :

    node src/genicon.mjs

### Utilitaires
`src/api.mjs`
- module comprenant des constantes et des classes / fonctions utilitaires devant être strictement identiques entre le serveut et l'application Web.

`src/base64.mjs`
- module lui aussi identique en application Web et serveur, principalement pour uniformité d'API utilisé dans d'autres modules(l'application Web n'a pas accès à node).

`src/logger.mjs`
- gestion du log par Winston.

`src/util.mjs`
- fonctions utilitaires diverses (dont encryption).

### Module d'accès à la base de données
Les modules présentent exactement le même API externe: les autres modules ignorent quelle implémentation est utilisée, le choix étant fixé à la configuration.
- `src/dbSqlite.mjs`
- `src/dbFirestore.mjs`

### Modules d'accès au _Storage_
Les modules présentent exactement le même API externe: les autres modules ignorent quelle implémentation est utilisée, le choix étant fixé à la configuration.
- `src/storageFS.mjs` : storage sur File-System local
- `src/storageGC.mjs` : storage Google Cloud Storage
- `src/storageS3.mjs` : storage AWS/S3

### Outil en CLI
`src/tools.mjs`
- propose les commandes: export-db export-fs purge-db purge-fs
- la commande vapid génère un couple de clé publique / privée VAPID pour le push-web. La clé publique est à communiquer à la configuration de l'application Web.

### Module du service PUBSUB
`src/pubsub.mjs`
- enregistre les connexions des sessions, leurs _heartbeat_, leurs déconnexions.
- reçoit les avis de mise à jour des documents après chaque opération,
- publie aux sessions les avis de mise à jour des documents de leur périmètre.

### Amorce des _serveurs_ et _cloud functions_
`src/server.js`
- amorce d'un _serveur_ assurant les services OP+PUBSUB

`index.mjs`
- amorce _Cloud function_ d'un service OP seul.

Ces deux amorces importent src/cfgexpress.mjs qui configure express pour les URLs d'entrée.

`src/pubsub.js`
- amorce d'un _serveur_ n'assurant que le service PUBSUB.

`index2.mjs`
- amorce _Cloud function_ d'un service PUBSUB seul.

Ces deux amorces importent src/cfgexpress2.mjs qui configure express pour les seules URLs d'entrée du service PUBSUB.

`src/cfgexpress.mjs`
- configure les URLs d'entrée
- l'URL /op/... invoque une fonction operation qui,
  - instancie un objet de classe Operation correspondant à l'opération souhaitée,
  - l'initialise
  - invoque sa méthode run(args, dbp, storage),
    - arguments de la requête, providers d'accès à la base et provider du storage 
  - retourne son résultat comme retour du POST de la requête qui l'a déclenché,
  - récupère ses exceptions et gère le retour correspondant de la requête.

`src/cfgexpress2.mjs`
- configure les URLs d'entrée
- l'URL /pubsub/... invoque la fonction pubsub de notif.mjs.

### Service PUBSUB: module `src/notif.mjs`
Ce module expose trois entrées:
- `genLogin` : invoqué au login d'une session.
- `genNotif` : invoqué à une fin d'opération.
- `genHeartbeat` : invoqué par un appel heartBeat d'une application Web.

Ce module a la caractéristique d'avoir deux modes d'appel:
- **en simple appel de fonction**: dans un serveur OP+PUBSUB, le service OP appelle les méthodes genLogin genNotif.
- **en réception de requête HTTP**: dans un serveur PUBSUB ou une _Cloud function PUBSUB_ les appels sont reçus par requête HTTP.

Quand `notif.mjs` est invoqué sur l'une des fonctions `genLogin` ou `genNotif`,
- s'il détecte qu'il est mode _serveur OP+PUBSUB_ il invoque directement la méthode correspondante,
- sinon il génère une requête POST à destination du _serveur / Cloud function_ PUBSUB.

Ainsi vu du service OP, le fait que PUBSUB soit ou non hébergé dans le même serveur est opaque.

Les commentaires et le code de `notif.mjs` sont suffisants pour le comprendre (400 lignes de code).

### Les 5 modules du service OP
`src/modele.mjs` : documentation détaillée ci-après
- gestion d'une mémoire cache des documents espaces,
- gestion d'une mémoire cache des documents majeurs,
- classe Operation
  - gestion d'une mémoire cache des documents créés / accédés au cours d'UNE opération
  - gestion des phases d'exécution de l'opération: authentification, phase 1, phase 2 transactionnelle, phase 3, fin d'opération.

`src/gendoc.mjs`
- une classe Document (générique) à des méthodes applicables à tous les documents.
- chaque sous-classe correspond à un Document et comporte les méthodes de traitement spécifiques associés.
- les commentaires dans le code sont suffisants pour la compréhension.

`src/taches.mjs`
- les _tâches_ sont opérations qui ont été déclenchées par une opération mais s'exécutent en différé après la fin de l'opération l'ayant initiée. C'est la fonction de la classe `Tache` (commentée dans le code).
- le module contient aussi la méthode correspondante aux seules opérations différées. Elles sont commentées dans le code.

`src/operations3.mjs src/operations4.mjs`
- ces 2 modules ne sont distincts que pour des raisons de taille. 
- `operations3.mjs` est réservé aux opérations spéciales, création / gestion d'espace, de compte, synchronisation, etc.
- `operations4.mjs` correspond à toutes les autres opérations _normales_.
- chaque opération a une classe héritant de `Operation`:
  - son API (ses arguments) est documentée,
  - des commentaires explicitent le traitement.

La logique applicative est répartie entre:
- les classes Operation (`taches.mjs operations3.mjs operations4.mjs`),
- les classes Document (`gendoc.mjs`)

-----------------------------------------------------------

# API : opérations supportées par le serveur

Les opérations sont invoquées sur l'URL du serveur : `https://.../op/MonOp1`
- **GET** : le vecteur des arguments nommés sont dans le queryString :
  `../op/MonOp1&arg1=v1&arg2=v2 ...`
  Ils se retrouvent à disposition dans l'opération dans l'objet `args` :
  { **arg1**: v1, arg2: v2 }
- **POST** : le body de la requête est la sérialisation de l'array `[args, apitk]` :
  - `args` : `{ arg1: v1, arg2: v2 ... }`
  - `apitk` : string donnant l'autorisation du client à utiliser l'API. Cette information figure en configuration du serveur et côté client dans `quasar.config.js / build / env / APITK` qui a été forcée lors du build webpack de l'application UI.

### `args.token` : le jeton d'authentification du compte
Requis dans la quasi totalité des requêtes ce jeton est formé par la sérialisation de la map `{ sessionId, shax, org, hps1 }`:
- `sessionId` : identifiant aléatoire (string) de session générée par l'application pour s'identifier elle-même (et transmise sur WebSocket en implémentation SQL).
- `org` : code de l'organisation.
- `shax` : SHA256 du PBKFD de la phrase secrète.
- `hps1` : Hash (sur un entier _safe_ en Javascript) du SHA256 de l'extrait de la phrase secrète.

> Remarque: le code `ns` ne figure pas en tête de `hps1`. A la connexion d'un compte celui-ci connaît son organisation pas son `ns`, il le récupère en retour, le serveur ayant lui la correspondance entre tous codes `org` et `ns`.

L'extrait d'une phrase secrète consiste à prendre certains bytes du début de la représentation en UTF-8 de la phrase complète.

### Headers requis
- `origin` : site Web d'où l'application Web a été chargée. Au cas ou `origin` ne peut pas être obtenu, c'est `referer` qui est considéré. Les origines autorisées sont listées dans `config.mjs`.
- `x-api-version` : numéro de version de l'API pour éviter un accès par des sessions ayant été chargées par une application _retardée_ par rapport au serveur.

### Retour des requêtes
- status HTTP 200 : OK
- status HTTP 400 401 402 403 : exceptions trappées par le serveur ,:
  - 400 : F_SRV fonctionnelles
  - 401 : A_SRV assertions
  - 402 : E_SRV exception inattendue trappée dans le traitement
  - 403 : E_SRV exception inattendue NON trappée dans le traitement
  - le texte de l'erreur est un texte JSON : `{ code, args: [], stack }`
  - à détection au retour d'une requête, une exception `AppExc` est générée depuis ces données.
- autre statuts (500, 0 ...) : une exception `AppExc` est générée (E_SRV, 0, ex.message)

#### Retour OK d'un GET
- requête `/fs` : retour 'true' si le serveur implémente Firestore, 'false' s'il implémente SQL (synchronisation par WebSocket).
- requêtes `/op/yo` et `/op/yoyo` : texte. 
  - `yo` est traitée _avant_ contrôle de l'origine et retourne `yo`.
  - `yoyo` est traitée _après_ contrôle de l'origine et retourne `yoyo`.
- autres requêtes : `arrayBuffer` (binaire).

#### Retour OK d'un POST
Le résultat binaire est désérialisé, on en obtient une map dont les éléments sont :
- de manière générique :
  - `dh` : le `getTime` de l'exécution de la transaction,
  - `sessionId` : la valeur de `sessionId` passée dans le token en argument ou 666.
- les autres termes sont spécifiques du _retour_ de chaque opération quand il y en a.

### Synthèse des URLs traitées
OPTIONS `/*`
- toutes les URLs sont concernées. Ne retourne rien mais est systématiquement invoquée par les browsers pour tester les accès cross-origin.

GET `/fs`
- Retour 'true' si le serveur implémente Firestore, 'false' s'il implémente SQL. Ceci évite dans le code de l'application d'avoir à configurer si la synchronisation est de type SQL (par WebSoket) ou Firestore, la découverte se faisant en runtime.

GET `/favicon.ico`
- retourne la favicon de l'application spécifiée en configuration.

GET `/robots.txt`
- retourne `'User-agent: *\nDisallow: /\n'`

GET `/ping`
- retourne en string la date et l'heure UTC.

GET `/`
- en déploiement mono-serveur et GAE, redirige vers `/app/index.html`

GET `/app/...`
- en déploiement mono-serveur et GAE, ce sont les URLs de l'application UI.

GET `/www/...`
- en déploiement mono-serveur et GAE, ce sont les URLs du site Web statique.
- pour des raisons de relativité d'URLs, `/www` renvoie sur `/www/index.html` qui est une redirection vers `/www/home.html`, la véritable entrée du site statique.

GET `/storage/...`
- utilisé pour télécharger un fichier quand le provider de storage est `fs` (ou `gc` en mode simulé). Retourne le fichier crypté en binaire `application/octet-stream`.

PUT `/storage/...`
- utilisé pour uploader un fichier quand le provider de storage est `fs` (ou `gc` en mode simulé). Le fichier est crypté en binaire `application/octet-stream` dans le `body` de la requête.

POST `/op/...`
- les `opérations` de l'application détaillées ci-après.

## Opérations `/op/...`
Voir dans le code le commentaire de signature de chaque opération.

Les opérations sont les suivantes:
- OP_AboTribuC: 'Abonnement / désabonnement à la tranche courante',
- OP_McMemo: 'Changement des mots clés et mémo attachés à un contact ou groupe',
- OP_ExistePhrase: 'Test d\'existence d\'une phrase de connexion / contact / sponsoring',
- OP_MotsclesCompte: 'Changement des mots clés d\'un compte',
- OP_MajCv: 'Mise à jour de la carte de visite d\'un avatar',
- OP_MajCvGr: 'Mise à jour de la carte de visite d\'un groupe',
- OP_ChangementPS: 'Changement de la phrase secrete de connexion du compte',
- OP_ChangementPC: 'Changement de la phrase de contact d\'un avatar',
- OP_GetAvatarPC: 'Récupération d\'un avatar par sa phrase de contact',
- OP_AjoutSponsoring: 'Création d\'un sponsoring',
- OP_GetSponsoring: 'Recherche d\'un sponsoring',
- OP_PassifChat: 'Mise en état "passif" d\'un chat',
- OP_NouveauChat: 'Création d\'un "chat"',
- OP_MajChat: 'Mise à jour d\'un "chat".',
- OP_RafraichirCvs: 'Rafraîchissement des cartes de visite',
- OP_NouvelAvatar: 'Création d\'un nouvel avatar du compte',
- OP_NouvelleTribu: 'Création d\'une nouvelle tranche de quotas',
- OP_SetNotifGg: 'Inscription d\'une notification générale',
- OP_SetNotifT: 'Inscription / mise à jour de la notification d\'une tranche de quotas',
- OP_SetNotifC: 'Inscription / mise à jour de la notification d\'un compte',
- OP_SetAtrItemComptable: 'Mise à jour des quotas d\'une tranche de quotas',
- OP_SetSponsor: 'Changement pour un compte de son statut de sponsor de sa tranche de quotas',
- OP_SetQuotas: 'Fixation des quotas dùn compte dans sa tranche de quotas',
- OP_ChangerTribu: 'Transfert d\'un compte dans une autre tranche de quotas',
- OP_SetDhvuCompta: 'Mise à jour de la date-heure de "vu" des notifications d\'un compte',
- OP_GetCompteursCompta: 'Obtention des compteurs d\'abonnement / consomation d\'un compte',
- OP_GetTribu: 'Obtention d\'une tranche de quotas',
- OP_SetEspaceT: 'Attribution d\'un profil à l\'espace',
- OP_NouveauGroupe: 'Création d\'un nouveau groupe',
- OP_MotsclesGroupe: 'Insciption / mise à jour des mots clés d\'un groupe',
- OP_InvitationFiche: 'Récupération des informations d\'invitation à un groupe',
- OP_HebGroupe: 'Gestion / transfert d\'hébergement d\'un groupe',
- OP_NouveauMembre: 'Ajout d\'un nouveau contact à un groupe',
- OP_MajDroitsMembre: 'Mise à jour des droits d\'un membre sur un groupe',
- OP_OublierMembre: 'Oubli d\'un membre d\'un groupe',
- OP_ModeSimple: 'Demande de retour au mode simple ou unanime d\'invitation à un groupe',
- OP_ItemChatgr: 'Ajout d\'un item de dialogue à un "chat" de groupe',
- OP_InvitationGroupe: 'Invitation à un groupe',
- OP_AcceptInvitation: 'Acceptation d\'une invitation à un groupe',
- OP_NouvelleNote: 'Création d\'une nouvelle note',
- OP_NoteOpx: 'Suppression d\'une note',
- OP_MajNote: 'Mise à jour du texte d\'une note',
- OP_ExcluNote: 'Changement de l\'attribution de l\'exclusivité d\'écriture d\'une note',
- OP_McNote: 'Changement des mots clés attachés à une note par un compte',
- OP_RattNote: 'Gestion du rattachement d\'une note à une autre',
- OP_ChargerCvs: 'Chargement des cartes de visite plus récentes que celles détenues en session',
- OP_NouveauFichier: 'Enregistrement d\'un nouveau fichier attaché à une note',
- OP_DownloadFichier: 'Téléchargement d\'un fichier attaché à une note',
- OP_SupprFichier: 'Suppression d\'un fichier attaché à une note',
- OP_SupprAvatar: 'Suppression d\'un avatar du compte',
- OP_GC: 'Déclenchement du nettoyage quotidien',
- OP_GetCheckpoint: 'Obtention du rapport d\'exécution du dernier traitement de nettoyage quotidien',
- OP_GetSynthese: 'Obtention de la synthèse de l\'espace',
- OP_ForceDlv: 'TEST seulement: forçage de dlv / dfh',
- OP_SetEspaceOptionA: 'Changement de l\'option A de l\'espace',
- OP_PlusTicket: 'Génération d\'un ticket de crédit',
- OP_MoinsTicket: 'Suppression d\'un ticket de crédit',
- OP_RafraichirTickets: 'Obtention des nouveaux tickets réceptionnés par le Comptable',
- OP_RafraichirDons: 'Recalcul du solde du compte après réception de nouveaux dons',
- OP_EstAutonome: 'Vérification que le bénéficiaire envisagé d\'un don est bien un compte autonome',
- OP_ReceptionTicket: 'Réception d\'un ticket par le Comptable',
- OP_ConnexionCompte: 'Connexion à un compte',
- OP_AcceptationSponsoring: 'Acceptation d\'un sponsoring et création d\'un nouveau compte',
- OP_RefusSponsoring: 'Rejet d\'une proposition de sponsoring',
- OP_ProlongerSponsoring: 'Prolongation / annulation d\'un sponsoring',
- OP_CreerEspace: 'Création d\'un nouvel espace et de son comptable',
- OP_EchoTexte: 'Lancement d\'un test d\'écho',
- OP_ErreurFonc: 'Simulation d\'une erreur fonctionnelle',
- OP_PingDB: '"Ping" de la base distante',
- OP_TraitGcvols: 'Récupération des quotas libérés par les comptes disparus',
- OP_OnchangeVersion: 'Opération de synchronisation (changement de version)',
- OP_OnchangeCompta: 'Opération de synchronisation (changement de compta)',
- OP_OnchangeTribu: 'Opération de synchronisation (changement de tranche)',
- OP_OnchangeEspace: 'Opération de synchronisation (changement de espace)',
- OP_MuterCompte: 'Mutation dy type d\'un compte',
- OP_GetPub: 'Obtention d\'une clé publique',
- OP_TestRSA: 'Test encryption RSA',
- OP_CrypterRaw: 'Test d\'encryptage serveur d\'un buffer long',

## Documents
### Les formats _row_ et _compilé_
Que ce soit en SQL ou en Firestore, l'insertion ou la mise à jour d'un document se fait depuis un _objet Javascript_ ou chaque attribut correspond à une propriété de l'objet. 

Par exemple un document `tribus` pour mise à jour en SQL ou Firestore est celui-ci : 

    { id: 3200...00, v: 4, _data_: (Uint8Array) }

Pour avoir le format _row_ une propriété _nom a été ajoutée : `{ _nom: 'tribus', id ... }`

Ce format _row_ est celui utilisé entre session UI et serveur, dans les arguments d'opérations et en synchronisation.

#### Format _compilé_
Les attributs _data_ contiennent toutes les propriétés sérialisées, celles externalisées `id v ...` et celles internes. 

- la fonction `tribu = compile(row)` désérialise le contenu de _data_ d'un objet row et retourne une instance `tribu` de la classe correspondant au nom (par exemple `Tribus` qui hérite de la classe `GenDoc`) avec les attributs externalisés `id v` et ceux internes sérialisés dans _data_. Si _data_ est `null`, il est reconstitué avec les seules propriétés externalisées et la propriété `_zombi` à `true`. Le serveur peut effectuer des calculs depuis tous les attributs.
- la méthode `row = tribu.toRow()` reconstitue un objet au format _row_ depuis une instance `tribu`.

En session UI le même principe est adopté avec deux différences : 
- `compile()` sur le serveur est **synchrone et générique**.
- en session `async compile()` est à écrire pour chaque classe : les méthodes effectuent des opérations de cryptage / décryptage asynchrones et de calculs de propriétés complémentaires spécifiques de chaque classe de document.
- en session il n'y a pas d'équivalent à `toRow()`. Pour des créations de document la construction s'effectue directement en format _row_ et non sur un objet qui serait sérialisé ensuite. 

Sur le serveur, le _data_ de certains documents cités dans `GenDoc.rowCryptes` (pour l'instant seulement `comptas`) est crypté par la _clé du site_ fixée par l'administrateur:
- _data_ est décrypté après lecteur de la base,
- _data_ est encrypté avant écriture de la base.

### Opérations authentifiées de création de compte et connexion
**Remarques:**
- le compte _Administrateur_ n'est pas vraiment un compte mais simplement une autorisation d'appel des opérations qui le concernent lui seul. Le hash de sa phrase secrète est enregistrée dans la configuration du serveur `/keys/app_keys.json`.
- le compte _Comptable_ de chaque espace est créé par l'administrateur à la création de l'espace. Ce compte est normal. Sa phrase secrète a été donnée par l'administrateur et le comptable est invité à la changer au plus tôt.
- les autres comptes sont créés par _acceptation d'un sponsoring_ qui fixe la phrase secrète du compte qui se créé : après cette opération la session du nouveau compte est normalement active.
- ces opérations sont _authentifiées_ et transmettent les données d'authentification par le _token_ passé en argument porteur du hash de la phrase secrète: dans le cas de l'acceptation d'un sponsoring, la reconnaissance du compte précède de peu sa création effective.

### Opérations authentifiées pour un compte APRÈS sa connexion
Ces opérations permettent à la session cliente de récupérer toutes les données du compte afin d'initialiser son état interne.

# Design interne du serveur


# Annexe I: Providers Storage
Selon le même principe trois classes _provider_ gèrent le storage et ont un même interface. Par simplification elles figurent dans `src/storage.mjs`:
- `FsProvider` : un file-system local du serveur,
- `S3Provider` : un Storage S3 de AWS (éventuellement _minio_).
- `GcProvider` : un Storage Google Cloud Storage.

En pratique il n'y a pas de raisons à assurer un Storage `s3` sous GAE.

**Méthodes:**

    async ping ()
    getUrl (org, id, idf)
    putUrl (org, id, idf)
    async getFile (org, id, idf)
    async putFile (org, id, idf, data)
    async delFiles (org, id, lidf)
    async delId (org, id)
    async delOrg (org)
    async listFiles (org, id)
    async listIds (org)

Le **serveur** gère le storage pour:
- `del...` les suppressions,
  - suppressions individuelles de fichiers,
  - disparition d'un avatar,
  - traitement des _uploads_ perdus.
- `putFile` : pour enregistrer un rapport généré sur le serveur comme l'export CSV des compteurs d'abonnement / consommation.

L'utilitaire `export-st purge-st` utilise les providers,
- pour lister des fichiers (`listFiles listIds`),
- pour supprimer des fichiers (`delOrg`),
- pour transférer des fichiers (`getFile, putFile`).

En conséquence, sauf le cas très particulier des rapports générés sur le serveur, **le serveur n'utilise pas `getFile putFile`**:
- les sessions **accèdent directement** au storage pour upload / download : le contenu des fichiers ne transitent pas par le serveur.
- mais il n'est pas question de transmettre aux sessions les données d'authentification d'accès aux storages pour d'évidentes raisons de sécurité.
- pour permettre à une session de _lire / écrire_ un fichier, un provider génère sur demande du serveur (qui a les accréditations nécessaires) une URL de GET / PUT:
  - elle est fort complexe et contient un jeton d'accès valide pour CE fichier précis pendant une durée limitée.
  - la session emploie juste cette URL sur un simple GET HTTP (download) ou un PUT HTTP (upload).

Ainsi en toute sécurité les sessions échangent des contenus avec le storage (des fichiers attachés aux notes, plus rarement un rapport généré par le serveur), directement et sans que ce contenu ne transite par le serveur.

### Cas particulier du provider File-System
Ce provider ne sert que:
- en test local,
- pour des exports entre deux storages nécessitant un tampon intermédiaire faute de pouvoir techniquemnt utiliser deux instances du même type de storage (_Google Cloud Storage_ exigeant un seul `projectId`).

Dans ce cas le contenu d'un fichier en GET ou en PUT tansite par le serveur puisqu'il est lui-même serveur de storage sur un directory local du host supportant le serveur / utilitaire.

L'URL du serveur `https://.../storage/azer789...` en GET et en PUT est utilisé pour un download / upload:
- l'URL est décodée pour retrouver l'identification du fichier à 3 niveaux `org/id/fichier`,
- le provider courant de storage est sollicité pour effectuer un `getFile / putFile`.
- le contenu du fichier a transité par le serveur avant d'être redirigé vers / depuis le provider courant.

Tout provider doit implémenter `getUrl / putUrl` mais il peut toujours utiliser l'URL générique `https://.../storage/...`
- c'est moins performant puisque le contenu des fichiers va transiter par le serveur,
- ça marche toujours.

Le provider `GcProvider` (_Google Cloud Storage_) propose bien `getUrl / putURL` **MAIS pas en mode _emulator_** où le service est omis. 
- C'est pour celà que l'implémentation de `getUrl / putUrl` utilise l'URL générique et le transfert intermédiaire par le serveur, ce qui n'a aucune importance en test. 
- A noter qu'in fine les fichiers se retrouvent bien dans le storage émulé, ils ont juste fait un transit supplémentaire en mémoire dans le cas d'usage de _emulator_.

# Annexe II : plus d'information sur certains modules dans `src/`

## `api.mjs`
Ce module **est strictement le même** que `api.mjs` dans l'application Web afin d'être certain que certaines interprétations sont bien identiques de part et d'autres:
- quelques constantes exportées.
- les classes,
  - `AppExc` : format général d'une exception permettant son affichage en session, en particulier en supportant la traduction des messages.
  - `ID` : les quelques fonctions statiques permettant de déterminer depuis une id si c'est celle d'un avatar, groupe, tribu, ou celle du Comptable.
  - `Compteurs` : calcul et traitement des compteurs statistiques des compteurs statistiques des documents `comptas`.
  - `AMJ` : une date en jour sous la forme d'un entier `aaaammjj`. Cette classe gère les opérations sur ce format.

### `gendoc.mjs`
La classe `GenDoc` représente un document _générique_.

Une classe y est déclarée pour chaque collection / table de documents:
- elle hérite de `GenDoc`
- elle n'est porteuse que de quelques méthodes.

    Espaces Gcvols Tribus Tribu2s COmptas Versions Avataars Groupes
    Notes Transferts Sponsorings Chats Membres

### Fonction `compile (row) -> Objet`
Cette fonction aurait pu être déclarée static de `GenDoc` et a été écrite comme fonction pour raccourcir le texte d'appel très fréquent.

Chaque **row** d'une table SQL ou **document** Firestore apparaît sous deux formes :
- **row** : c'est l'objet Javascript directement stocké en tant que row d'une table SQL ou document Firestore.
- **objet compilé** : c'est une instance d'un des classes de document ci-dessus.

La méthode `compile()` retourne l'objet compilé depuis sa forme row et son nom symbolique : si l'argument row est null, le retour est null (sans levée d'exception).

### Méthode `GenDoc.toRow()`
Réciproquement depuis un objet `a` par exemple de classe `Avatars`, `a.toRow()` retourne sa forme **row** prête à être stockée en row SQL ou document Firestore.

La fonction `compile()` retourne la forme compilée (un objet de sa class spécifique) depuis un row, est dans l'esprit une méthode `statique` de GenDoc mais sous la forme d'une fonction pour commodité d'écriture.

Deux autres fonctions `decryptRow (op, row)` et `prepRow (op, row)` sont utilisés par les providers DB pour crypter / décrypter le _data_ d'un row des classes pour lesquelles le _data_ est crypté par la clé du site.

### Liste restrictive des attributs d'un row
Cette liste est fermée : pour chaque classe la liste exhaustive est donnée.
- `_nom` : nom symbolique de la classe dont est issue le row ('avatar', 'groupe', ...).
- `id` : l'id principale (et unique pour les objets majeurs).
- `ids` : l'id secondaire pour les `Notes Transferts Sponsorings Chats Membres`.
- `v` : sauf Gcvols. Version de l'objet.
- `vcv` : pour Avatars Chats Membres : version de la carte de visite.
- `dlv`: pour Versions Transferts Sponsorings Membres : date limite de validité (`aaaammjj`). A partir de cette date, le document n'est plus _valide_, il est sémantiquement _disparu_. En compilé l'attribut `_zombi` vaut `true`.
- `hps1` : sur Comptas, hash de la phrase secrète raccourcie.
- `dfh` : sur Groupes date de fin d'hébergement.
- `hpc` : sur Avatars, hash de la phrase de contact (pseudo plus ou moins temporaire).
- `_data_` : sérialisation de tous les attributs, dont ceux ci-dessus.

En forme compilé la propriété `_data_` n'est pas elle-même présente mais à la place tous les attributs de la classe sont présents.
- quand _data_ n'existe pas ou est null dans le format row, l'attribut _zombi de la classe correspondante vaut true.

En statique `GenDoc` donne aussi des listes de documents selon leurs modes de gestion afin de faciliter les traitements génériques en particulier d'export et des accès génériques (documents _majeurs-, documents _sous-collection d'un document majeur_) ...

### `modele.mjs`
Ce module comporte trois classes: `Cache Operation AuthSession`.

#### `Cache` : cache des objets majeurs `espaces tribus comptas avatars groupes`

Cet objet gére une mémoire cache des derniers documents demandés dans leur version la plus récente.

Le test pour savoir si la version détenue est la dernière s'effectue dans une transaction et permet de ne pas lire le document de la table ou de la collection si sa version n'est pas plus récente ce qui évite des lectures coûteuses inutiles (et coûteuses monaiterement en Firestore).

Cache gère aussi une mémoire cache de `checkpoint` le document de suivi du GC.

En stockant les document `espaces`, `Cache` fournit également le code de l'organisation d'un espace connu par son ns (son id).

##### `static getRow (op, nom, id)`
Obtient le row de la cache ou va le chercher.
- Si le row actuellement en cache est le plus récent on a évité une lecture effective et la méthode s'est limité à un filtre sur index qui ne coûte rien en FireStore et pas grand chose en SQL.
- Si le row n'était pas en cache ou que la version lue est plus récente IL Y EST MIS:
  - certes la transaction _peut_ échouer, mais au pire on a lu une version, pas forcément la dernière, mais plus récente.

##### `static async getEspaceLazy (op, ns)`
Retourne l'espace depuis celui détenu en cache. C'est seulement s'il a plus de PINGTO minutes d'âge qu'on vérifie sa version et qu'on la recharge le cas échéant.
PAR PRINCIPE, elle est retardée: convient pour checker une restriction éventuelle.

##### `static update (newRows, delRowPaths)`
Utilisée en fin de transaction pour enrichir la cache APRES le commit de la transaction avec tous les rows créés, mis à jour ou accédés (en ayant obtenu la _dernière_ version).

##### `static async getCheckpoint ()`
Retourne le dernier checkpoint enregistré parle GC.

##### `async setCheckpoint (obj)`
Enregistre en base et dans Cache le dernier objet de checkpoint défini par le GC.

##### `static async getEspaceOrg (op, org)`
Retourne le row compilé de l'espace obtenu par son code d'organisation.

##### `static async org (op, id)`
Retourne le code de l'organisation pour un ns donné.

#### `AuthSession`
Cette classe conserve une entrée par session authentifiée et en gère la disparition par défaut d'activité (heartbeat).

#### `Operation`
C'est la classe générique ancêtre des opérations. Chaque opération a une classe spécifique dans le module `operation.mjs` qui hérite de cette classe générique:
- authentification de l'opération,
- enchaînement des phases 1 2 et 3,
- enregistrement effectif des mises à jour en fin de phase-2 (juste avant commit de la transaction),
- signalement des mises à jour au module ws.mjs (en SQL) pour synchronisation WebSocket,
- retour du résultat.

Cette classe propose des méthodes d'interface vers les métodes des providers DB et vers l'accès à Cache: ce ne sont que des commodités syntaxiques.

Enfin cette classe expose aussi une dizaine de méthodes fonctionnelles ayant à être sollicitées depuis plus d'une opération.

_Remarque_: la logique aurait voulu que la classe `Operation` soit incrite dans le module `operations.mjs` : il a été préféré d'isoler le code générique dans un module à part, choix discutable certes mais qui se défend aussi.

Plus de détail en annexe.

# Annexe: détails à propos de la classe `Operation`
Le déclenchement d'une opération `MonOp` sur réception d'une requête `.../op/MonOp`,
- créé un objet `MonOp` héritant de `Operation`,
- invoque successivement :
  - sa méthode `phase1()` qui s'exécute hors de toute transaction, typiquement pour des contrôles d'argments,
  - sa méthode `phase2()` qui s'exécute dans le contexte d'une unique transaction.
  - sa `phase3()` qui s'exécute après le commit de la transaction pour certaines actions de nettoyge et / ou d'accès au storage.

Dans une transaction Firestore aucune lecture n'est autorisée dès qu'une mise à jour a été effectuée. Les mises à jour sont de ce fait _enregistrées et mises en attente_ au cours de la phase 2 et ne seront effectivement faites qu'après la phase 2.

En conséquence, 
- les opérations doivent prendre en compte que la modification d'un document n'est jamais perceptible dans la même transction par une lecture : le cas échéant si nécessaire stocker en mémoire de l'objet opération les mises à jour si elles participent de la logique de l'opération.
- une opération doit veiller à ne pas construire plusieurs mies à jour d'un même document dans des méthodes qui s'ignoreraient.

### Authentification avant `phase1()`
Chaque classe Operation spécifie un attribut authMode qui déclare comment interpréter l'attribut `token` reçu dans l'objet `args` (argments sérialisés reçu dans le body de la requête ou queryString de l'URL). Cet objet est disponible dans `this.args` :
- `authMode === 3` : SANS TOKEN, pings et accès non authentifiés (recherche phrase de sponsoring).
- `authMode === 2` : AVEC TOKEN, créations de compte. Elles ne sont pas encore enregistrées, elles vont justement enregistrer leur authentification.
- `authMode === 1` : AVEC TOKEN, première connexion à un compte : `this.rowComptas` et `this.compta` sont disponibles.
- `authMode undefined` : AVEC TOKEN, cas standard, vérification de l'authentification, voire enregistrement éventuel.

### Méthodes génériques disponibles en phase 1 et 2
`setRes(prop, val)`
- Fixe LA valeur de la propriété 'prop' du résultat (et la retourne).

`addRes(prop, val)`
- AJOUTE la valeur en fin de la propriété Array 'prop' du résultat (et la retourne).

### Méthodes génériques disponibles en phase 2
`insert (row)`
- Inscrit row dans les rows à insérer en phase finale d'écritue, juste après la phase 2.

`update (row)`
- Inscrit row dans les rows à mettre à jour en phase finale d'écritue, juste après la phase2 .

`delete (row) `
- Inscrit row dans les rows à détruire en phase finale d'écritue, juste après la phase 2.
