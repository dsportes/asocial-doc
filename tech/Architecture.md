# Architecture générale

L'application est une application Web, une **_PWA Progressive Web App_**: 
- elle est doit être invoquée au moins une première fois depuis un navigateur connecté à Internet,
- elle pourra ensuite l'être depuis ce même navigateur sans connexion à Internet (en mode _avion_, consultation seulement).

Quatre grands composants contribuent à ce service :
- **un serveur HTTPS joignable sur Internet** par exemple sur l'URL https://asocial.demo.net.
- **une application UI d'interface utilisateur s'exécutant dans un navigateur** qui a été ouverte par l'URL https://asocial.demo.net (ou https://asocial.demo.net/app/index.html).
- **un site Web statique** principalement documentaire accessible depuis le navigateur à l'URL https://asocial.demo.net/www. Dépôt git `asocial-doc`.
- **un programme utilitaire de chargement local de fichiers** dans un répertoire local pouvant être téléchargé par Internet sous l'URL https://asocial.demo.net/upload (`upload.exe` pour la version Windows). 

### Principe de cryptage
Bien que le protocole de communication soit HTTPS, les données des comptes, les textes et fichiers de leurs notes, etc. sont **cryptées** dans l'application UI :
- le serveur ne reçoit **jamais** aucune information humainement interprétable en clair ni aucune clé de cryptage;
- les _meta-données_ liant les documents entre eux sont également cryptées dans la session UI.

Les quatre composants ont été développés / écrits sous `VSCode` et sont disponibles dans `github.com/dsportes` en _public_ (licence ISC).

# Le serveur
C'est un serveur Web en `node.js` (100% Javascript). Dépôt git `asocial-srv`.

Il reçoit les requêtes entrantes sur une URL fixée par l'administrateur technique. 

Quelques requêtes sont accessibles sans contrainte, typiquement par une URL depuis la barre d'adresse d'un navigateur ou `curl`:
- obtention de l'application UI `/` ou `/app/index.html` et ses ressources,
- accès au site Web documentaire `/www/...`,
- quelques requêtes techniques (`/ping` ...) .

En revanche toutes autres requêtes (en provenance de l'application UI) ne sont acceptées QUE si la page de cette application a été chargée depuis une des URLs acceptées par la configuration du serveur. Ce contrôle de _l'origine_ de l'application UI protège le serveur d'un accès depuis une application UI _pirate_, non distribuée par le site bien identifié de distribution de l'application UI.

### Base de données du serveur
La base a un volume modeste et stocke les informations relatives aux comptes dont les textes de leur notes ..., mais **pas** les fichiers attachés aux notes.

**Le serveur accède à SA _base de données_** par une classe _provider_ écrite pour chaque modèle de base de données souhaité.
- chaque _provider_ offre le même jeu d'une quarantaine de méthodes d'accès (environ 500 lignes de code),
- la signature en est identique pour tous les providers de sorte qu'utiliser l'un ou l'autre n'est qu'un choix de l'administrateur technique. Hors de ces classes, les autres ignorent la technologie de la base de données sous-jacente utilisée.

#### Provider `sqlite`
De manière générique à peu près toute base SQL peut être employée en n'adaptant que quelques détails de syntaxe et de connexion spécifiques.

L'administrateur technique du site doit mettre en place le backup en continu de cette base sur un site distant et sa reprise après sinistre.

#### Provider `firestore`
Cette base orientée _document_ NOSQL, est hébergée sur des sites multiples sécurisés et administrés par Google qui en assure la haute disponibilité et la sécurité.

Du fait de l'uniformité de l'interface d'accès, l'utilitaire `export-db` permet d'exporter une base vers une autre de technologie éventuellement différente.

> Remarque: l'export de `firestore` vers `firestore` est techniquement limité par les contraintes d'environnement d'API de Google (un seul `projectId` étant possible dans une exécution) mais on peut utiliser un double export `firestore -> sqlite` puis `sqlite -> firestore`.

#### Langue 
Quelques très rares textes gérés par le serveur apparaissent dans des traces techniques et sont généralement écrites en français pour un usage de développement / debug.

#### Logs
Les logs sont gérés par le module _Winston_ et dans le cas d'un déploiement Google App Engine sont intégrés au système de log de Google Cloud (sinon ce sont des logs sur fichiers classiques).

### Storage
Un _storage_ stocke les fichiers (cryptés) attachés aux notes.

Les fichiers sont chargés (_upload_) directement de l'application UI vers le _storage_, sans transiter par le serveur et sont de même téléchargés (_download_) directement du _storage_ vers l'application UI sans passer par le serveur. 

Chaque _provider_ est implémenté par une classe d'une dizaine de méthodes (environ 250 lignes de code), tous les providers implémentant le même interface.

Le choix du provider se fait à la configuration de l'installation par l'administrateur.

#### Provider `fs` - File-system
Le stockage s'effectue dans un répertoire local du serveur et son uUtilisation concrète se limite aux tests.

#### Provider `gc` - Google Cloud Storage
Le stockage redondant est assuré par Google sur des sites externes spécialisés.

#### Provider `s3` - Amazon S3
S3 est le nom du protocole et plusieurs fournisseurs (en plus de Amazon) proposent ce type de services. 

Il existe entre autre une application `minio` qui permet de mettre en œuvre son propre stockage sur le(s) serveur(s) de son choix.

Du fait de l'uniformité de l'interface d'accès, l'utilitaire `export-st` permet d'exporter un storage vers un autre de technologie éventuellement différente.

> Remarque: l'export de `gc` vers `gc` est techniquement limité par les contraintes d'environnement d'API de Google (un seul `projectId` étant possible dans une exécution) mais on peut utiliser un double export `gc -> fs` puis `fs -> gc`.

> Remarque: il est donc simple d'effectuer une photo d'un environnement de production vers un autre de test et le cas échéant d'ailleurs de permettre aux utilisateurs d'accéder au choix aux deux.

### GC _garbage collector_ quotidien
Ce traitement s'exécute automatiquement sur le serveur une fois par jour à des fins de nettoyage de données obsolètes et de détection de non utilisation de comptes.

Il intervient aussi pour nettoyer le _storage_.

C'est le seul traitement qui n'est pas sollicité par une requête reçue par le serveur HTTP.

## Synthèse
**Le serveur est _frontal_ de _sa_ base de données:** il n'y a que lui qui accède à cette base. Celle-ci est mise à jour par suite de l'exécution _d'opérations_ soumises par les sessions UI.
- toute opération est _atomique et consistante_, effectuée en totalité ou pas du tout, peut concerner plusieurs documents et garantit la cohérence fonctionnelle, le respect des règles, sur l'ensemble des documents.
- dans le cas du _provider firestore_, la base est gérée par un serveur _firestore_ distinct du serveur mais ceci ne change (presque) rien : c'est le serveur qui a l'exclusivité de mise à jour et de consultation. Toutefois le serveur _firestore_ a la capacité de _notifier_ directement les sessions de l'existence de mises à jour les concernant (sans passer par le serveur frontal).

**Le Storage est un serveur distinct** dont la logique de _serveur de fichiers_ n'est pas celle de l'application:
- les fichiers sont transférés directement entre sessions et storage (sans passer par le serveur frontal);
- la validation de l'existence des fichiers est assurée par le serveur frontal, ainsi que la soumission des ordres de suppression.

# Utilitaire de l'administrateur technique
Par commodité de développement, il est intégré au logiciel du serveur, lancé en ligne de commande dans un terminal avec pour premier argument le nom de l'utilitaire
- `export-db` : export de la partie de la base données relative à une organisation dans une autre base (ou la même).
- `export-st` : export des fichiers d'une organisation d'un _storage_ à un autre (ou le même).
- `purge-db` : purge des données d'une organisation dans une base.
- `purge-st` : purge des fichiers d'une organisation dans un storage.

# L'application UI
C'est une application Web (buildée en _Progressive Web App_) s'exécutant dans un browser. 

Elle est écrite (en Javascript / HTML / SASS) en utilisant la couche `vuejs.org` et au-dessus de celle-ci des composants de `quasar.dev`. Dépôt git `asocial-app`.

Les données affichées à l'écran,
- a) ont été initialement téléchargées à la connexion de l'utilisateur,
- b) puis sont synchronisées en cours de session à chaque fois que le serveur a détecté qu'elles avaient changé par rapport à la version détenue en session.

Les opérations de mises à jour sont soumises au serveur qui effectue la mise à jour de la base de données. Ces évolutions sont ensuite signalées aux sessions qui sont concernées. Ce qui s'affiche à l'écran, hormis temporairement en cours de saisie des données d'une opération, sont des données qui sont revenues du serveur.

## Base de données locale du browser
Cette petite base de données interne au browser, stocke pour chaque compte qui s'est connecté, les documents relatifs à ce compte, cryptés, avec exactement le même contenu et format que sur la base de données du serveur: c'est une copie des documents _intéressant un compte_:
- à l'ouverture d'une session, seuls les documents ayant évolué sur le serveur par rapport à l'état connu dans cette base locale (ou ajoutés depuis la dernière connexion) sont téléchargés: cette phase peut s'en trouver grandement accélérée;
- en cours de session, toutes les mises à jour notifiées à la session des documents qui la concerne, sont enregistrées dans cette base locale.

La base locale ne stocke pas par défaut les fichiers attachés aux notes en raison du volume possiblement important correspondant. Toutefois, fichier par fichier, l'utilisateur peut les faire stocker localement. 

### Modes synchronisé, incognito, avion
Le mode décrit ci-avant est celui _synchronisé_: la base locale reflète l'état des documents _intéressant la session du compte connecté_ connu lors de la clôture de la session précédente. En cours de session l'état de la base locale est le même que celui de la base du serveur (légèrement retardé du fait des délais _faibles_ de synchronisation).
- les documents sont présents dans la mémoire de la session,
- les fichiers, quand ils ont été déclarés _visible en mode avion_ ne résident pas en mémoire mais uniquement dans la base du browser. La demande de leur affichage évite, pour ces fichiers, un accès au _storage_ distant.

En mode _incognito_ la base locale du browser n'est pas utilisée:
- en début de session à la connexion tous les documents _intéressant le compte_ sont chargés depuis le serveur,
- en cours de session, les notifications reçues du serveur de mise à jour / ajout de documents, provoquent le chargement en mémoire de ceux-ci.

En mode _avion_ la base locale du browser est utilisée pour restituer en mémoire le dernier état de la dernière session _synchronisée_ pour le compte.
- le serveur n'est pas accédé,
- les opérations de mises à jour sont bloquées,
- seul les fichiers déclarés _visibles en mode avion_ peuvent être consultés,
- l'utilisateur peut toutefois enregistrées des textes (des notes) et des fichiers dans la base locale pour en disposer dans une session ultérieure _synchronisée ou avion_.

### Deux modes de _synchronisation_
Dans le mode _WebSocket_ le serveur détient pour chaque session la liste des identifiants définissant le périmètre des documents _intéressant le compte_:
- toute mise à jour / ajout de documents de ce périmètre provoque l'émission d'une notification à la session cliente concernée (en fait à _toutes_ celles concernées),
- chaque session demande les documents correspondants à réception de ces notifications.

Dans le mode _firestore_ chaque session a une requête _firestore_ à l'écoute des documents du périmètre d'intérêt de la session. C'est le serveur _firestore_ qui répond aux requêtes en écoute, la notification en résultant étant traitée comme dans le cas WebSocket.

> **Remarque**: les documents du _périmètre d'intérêt_ d'un compte peuvent changer, non seulement parce que la session elle-même a soumis des opérations de mise à jour, mais aussi sous l'effet d'opérations soumises par n'importe quelle autre session active: les vues à l'écran reflétant l'image de ces documents, il est normal de voir l'écran _bouger tout seul_ en l'absence de toute action.

## Synchronisation vue <-> documents
Les documents du périmètre de la session sont stockés dans un _espace mémoire réactif_.

Toutes les _vues_ s'affichant à l'écran sont connectées à cette mémoire réactive.

En conséquence toute évolution d'un document suite à une notification reçue en cours de session, provoque un rafraîchissement (automatique et optimisé) de l'affichage.

L'utilisateur a plusieurs types d'action possible à sa disposition:
- des actions de _navigation_ c'est à dire de _choix_ des documents ou partie des documents qu'il veut voir à l'écran;
- des actions de _saisie_ des paramètres des opérations, puis une fois satisfait de sa saisie il déclenche une _validation_ qui soumet l'opération correspondante au serveur ...  
- ce qui en général provoque des mises à jour de documents dans le serveur (dans sa base) ...
- ce qui provoque des notifications des sessions concernées ...
- ce qui provoque pour chacune la mise à jour _dans la mémoire réactive_ des documents qui l'intéressent ...
- ce qui peut provoquer la mise à jour des vues affichées si elles étaient associés aux paries de mémoire réactives correspondantes.

## Langue
- tous les textes lisibles par l'utilisateur sont gérés par un composant `I18n` qui permet de les traduire dans différentes langues que l'utilisateur peut choisir par une icône dans sa barre inférieure.
- la traduction a été testée en français et en anglais: toutefois les 1500 textes utilisés sont écrits en français et restent à traduire en anglais, voire d'autres langues. Ces _dictionnaires_ font partie du source de l'application (ils ne sont pas externes) mais sont dans des fichiers bien distincts.
- les panels d'aide en ligne font également partie du source de l'application ce qui permet de les utiliser en mode _avion_, déconnecté d'Internet. Ils sont aussi traduisibles en une autre langue que le français.

## Synthèse
L'application UI comporte plusieurs logiques:
- **le processus de connexion / synchronisation** pour initialiser et maintenir à jour sa _mémoire réactive de documents_.
- **la description des vues** et des liens qui les _attachent_ aux documents en mémoire réactive.
- **les commandes de _navigation_** permettant de choisir ce qu'on voit à l'écran.
- **les dialogues de _saisie_** des données paramètres des opérations souhaitées et la soumission de ces opérations.

# Téléchargement de notes sur un poste: `upload` 
Cet utilitaire permet de stocker dans un répertoire local d'un poste (Windows / Linux) des notes et leurs fichiers attachés. Dépôt git `upload`.

Une page Web standard n'est pas autorisée à écrire sur le système de fichier du poste, sauf quand l'utilisateur en donne l'autorisation et la localisation fichier par fichier : pour télécharger en local toutes les notes sélectionnées par l'utilisateu et leurs fichiers, ce qui peut représenter des centaines / milliers de fichiers et des Go d'espace, l'application UI fait appel à un micro-serveur HTTP `upload` qui s'exécute localement sur le poste.

Le source consiste en moins de 100 lignes de code écrite en `node.js` / Javascript.

`upload` peut être téléchargé par Internet sous l'URL https://asocial.demo.net/upload (`upload.exe` pour la version Windows). Dépôt git `upload`.

Une fois téléchargé et lancé sur le poste où s'exécute le navigateur accédant à l'application, ce micro serveur HTTP permet de récupérer (en clair) dans un répertoire local au poste les notes sélectionnées par l'utilisateur et leurs fichiers. 

# Espaces
Un _site_ constitué d'un **serveur** (et sa base de données) et d'un **storage**, peut héberger plusieurs organisations de manière totalement étanche entre elles.

Chaque site a,
- son _administrateur technique_, ayant sa phrase secrète de connexion qu'il est seul à connaître en clair,
- une _clé technique de cryptage spécifique du site_ pour certains cryptages techniques (mais qui ne permet en rien d'accéder aux données cryptées par les comptes). Seul l'administrateur technique en connaît la source en clair.
- un brouillage de ces deux clés est enregistré dans le fichier de configuration technique `keys/app_keys.json`. Pour exporter seule la forme brouillée est requise.

**Une organisation est identifiée par un code** de 4 à 8 lettres ou chiffres ou - comme `monorg`:
- à la connexion un utilisateur fournit le code de son organisation et sa phrase secrète.
- dans le _storage_ chaque organisation a un _folder_ portant le nom de l'organisation. Autre expression plus exacte les noms des fichiers des notes de l'organisation `monorg` commencent tous par `monorg/...`.

En base de données chaque organisation est identifiée par un code `ns` (_name space_) valant de `10` à `69`:
- le document de la collection `espaces` d'id `12` par exemple donne la correspondance entre ce numéro `12` et le nom de l'organistion `monorg`.
- un autre document de la collection `syntheses` a aussi pour identifiant ce numéro `12`.
- tous les autres documents ont, soit un identifiant principal _id_, soit un couple d'identifiants principal et secondaire _id ids_.
- les identifiants principaux ont 16 chiffres, les deux premiers étant le `ns` attribué à l'organisation dans la base.
- quelques documents (collections `comptas avatars sponsorings`) ont une propriété indexée qui porte aussi une valeur de 16 chiffres dont les 2 premiers sont le `ns` de l'organisation.
- toutes les autres propriétés des documents référençant un autre document par son id, ne porte qu'une id à 14 chiffres (sans le ns).

**Conséquences**
- **on peut exporter une base** en lui changeant son couple `12 monorg` en un autre `24 monorg2`:
  - le document exporté `espaces` contient la correspondance `24 monorg2`
  - les id des documents exportés (et les quelques propriétés indexées), sont exportées en remplaçant les deux premiers chiffres `12` par `24`.
  - la base de données destinataire peut être accédée par des utilisateurs donnant à la connexion `monorg2` comme organisation (et même phrase secrète): ils voient les données dans le même état qu'avec leur connexion avec `monorg`.
- **on peut exporter un storage** `monorg` en `monorg2`, les fichiers étant copiés à l'identique mais avec un nom qui commence par `monorg2/...` au lieu de `monorg/...`
- on peut purger une base de données d'un `ns` donné (12 par exemple).
- on peut purger un espace de nom `monorg` donné.

Il est simple de procéder à l'exportation d'une organisation vers un autre site, de technologie différente ou non pour la base de données et le storage, et adminsitrée par une entité complètement différente et autonome de celle source.

Il est aussi simple de _prendre une photo_ à un instant donné d'un espace 12 par exemple et de l'exporter sur un espace 24 à des fins d'audit, d'archivage ou de debug.
- pendant l'export, l'espace source est figé par l'administrateur technique en lecture seule pour disposer d'un cliché cohérent, il est ensuite réouvert à la mise à jour à la fin de l'export.

# Annexe : _ES6_ versus _CommonJs_
Les logiques de l'application UI comme du serveur sont écrites en Javascript: la question se pose donc du système de modularisation choisi.

Ces deux systèmes de gestion de modules co-existent avec une certaine difficulté:
- **ES6** est désormais le standard: les modules ne présentant que la forme `require()` de CommonJs se raréfient mais existent encore.
- **CommonJs** était le système de gestion de modules de Node.js avant la normalisation ES6.

**L'application a été centrée sur ES6** avec quelques contorsions vis à vis des modules étant resté en CommonJs sans offrir d'importation ES6.

### Application UI
Un seul module est concerné: `pako`.

Un seul source `src/boot/appconfig.js` effectue à l'initialisation de l'application un `require('pako')` et met le résultat à disposition du module `src/app/util.mjs`.

Hormis cette ligne, les autres scripts de l'application sont ES6 (`.mjs`).

### Application Serveur
Le fichier de démarrage `src/server.js` est un module ES6, malgré son extension `.js`:
- le déploiement GooGle App Engine (GAE) **exige** que ce soit un `.js` et que `package.json` ait une directive `"type": "module"`.
- pour les tests usuels, il faut `"type": "module"`.
- MAIS pour un déploiement **NON GAE**, un build `npx webpack` est requis et cette dernière directive **DOIT** être enlevée ou renommée `"typeX"`.

_Remarques pour le build du serveur pour déploiement NON GAE_
- `webpack.config.mjs` utilise le mode `import` plutôt que `require` (les lignes pour CommonJs sont commentées).
- une directive spécifique dans la configuration `webpack.config.mjs` a été testée pour que `better-sqlite3` fonctionne en ES6 après build par webpack. Mais ça n'a pas fonctionné et `better-slite3` reste chargé par un require() dans `src/loadreq.mjs` (qui ne sert qu'à ça).

> Remarque : il n'existe donc que 2 entorses à ES6 et la présence de `require`: 
- a) pour `pako` dans l'application UI : fichier `src/boot/appconfig.js`,
- b) `better-sqlite3` dans le serveur : fichier `src/loadreq.mjs`.
