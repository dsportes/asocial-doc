# Architecture générale

L'ensemble est architecturé en:
- **une application Web** s'exécutant dans un browser et qui,
  - soumet des requêtes HTTP aux services centraux pour mise à jour des données dans la base et pour synchroniser son état interne avec l'état connu dans la base centrale,
  - reçoit des avis de mise de changement d'état dans la base centrale des données de son périmètre d'intérêt.
- **un service central OP** qui,
  - traite les opérations de consultation et mise à jour de la base de données,
  - informe le service central PUBSUB des ouvertures de session des applications Web,
  - informe le service PUBSUB des mises à jour des données suite aux traitement des opérations.
- **un service central PUBSUB** qui,
  - reçoit les _souscriptions_ des sessions de l'application en cours d'exécution et note pour chacune le périmètre des données qui l'intéressent,
  - reçoit du service OP les avis de changement des données correspondant à chaque opération traitée,
  - _publie_ aux browsers en exécution des avis de mise à jour des données qui les concernent.

### L'application Web
C'est une page Web téléchargeable depuis un site statique et s'exécutant dans un browser. 

A un instant donné il y a autant de **sessions** en exécution que de pages ouvertes par les utilisateurs dans leur(s) browser(s).

_Technologie_: HTML / SASS / Javascript s'appuyant sur _vuejs.org_ et _quasar.dev_ (sur couche de _vuejs_).

### Le service OP central
C'est un service HTTP pouvant avoir une ou plusieurs instances en exécution à un instant donné. 

Le service OP traite les opérations requises par les **sessions** de l'application Web en lisant / mettant à jour la base de données.

_Technologie_: Javascript avec _Node.js_

### Le service PUBSUB central
C'est un service HTTP n'ayant au plus qu'une instance en exécution. 

Le service PUBSUB est chargé de _pousser_ vers chacune des **sessions** de l'application les avis de modification des données qui la concerne afin de maintenir à jour ses données affichées.

_Technologie_: Javascript avec _Node.js_

### La base de données centrale**
Ses données sont stockées à l'occasion des opérations de mises à jour effectuées par une instance de service **OP**, qui est le seul à pouvoir accéder à la base.

Une base de données est virtuellement _partitionnée_ en espaces (jusqu'à 60), étanches entre eux, afin d'héberger techniquement plusieurs organisations dans une même base.

_Technologies_: SQL (SqLite, PostgreSQL ...) et NOSQL (Firestore de Google).

### Le service de Storage
C'est un service HTTP externe chargé de stocker les fichiers cryptés attachés aux notes. 

Le service OP effectue lui-même quelques transferts de fichiers mais est surtout chargé de délivrer aux sessions des URLs encodées / sécurisées de _download_ / _upload_ aux **sessions**. 

Les sessions accèdent directement au Storage pour tous leurs transferts de fichiers en utilisant les URLs générés par le service OP.

La structure du Storage est également partitionné en **espaces**, avec un espace comme _folder racine_ de la structure hiérachique de fichiers.

_Technologies_: File-System, Google Cloud Storage, Amazon S3.

### L'utilitaire UPLOAD de chargement local de fichiers
Les sessions peuvent télécharger cet utilitaire qui va s'exécuter localement sur leur poste: il permet de charger dans un répertoire local du poste le contenu, non crypté, d'une sélection de notes et de leurs fichiers attachés pour tout usage que l'utilisateur souhaite en faire.

_Technologie_: _node.js_

### L'utilitaire d'administration d'EXPORT d'un espace
L'export d'un espace de la base se fait en l'important dans une autre, éventuellement locale au poste de l'administrateur.

L'export d'un espace du Storage se fait en l'import dans un autre Storage, le cas échéant un répertoire du File-System local au poste de l'administrateur.

_Technologie_: _node.js_

### Langues

#### D'affichage
L'application Web est traductible: tous les textes apparaissant à l'écran figurent dans des dictionnaires. L'utilisateur peut changer de langue en cours de session.

#### Des logs
Pour l'application Web, les rares traces de log sont dans un mélange d'anglais (pour les modules externes) et de français (pour les modules internes).

Les logs des services sont gérés par le module _Winston_ et dans le cas d'un déploiement Google Cloud sont intégrés à son système de log. Les rares traces de log sont dans un mélange d'anglais (pour les modules externes) et de français (pour les modules internes).

# L'application Web
C'est une _page Web index.html_ standard, plus précisément une **_PWA Progressive Web App_** disponible depuis un site statique de type CDN par une URL comme:

  https://asocialapp.github.io/s2
 
Quand la page a été chargée une première fois, avec toutes les ressources requises par la page _index.html_, depuis un browser connecté à Internet par son URL, le browser en conserve l'image dans une mémoire dédiée au browser sur le poste (assuré par le script _service worker_ de l'application).

Lors des prochains appels depuis ce même browser à cette URL, le browser,
- obtiendra du site CDN les seuls éléments nouveaux depuis le chargement précédent,
- si le browser n'est pas connecté à Internet, il utilisera la version la plus récente obtenue antérieurement permettant un fonctionnement _offline_(en mode _avion_, en consultation seulement).

L'application Web,
- gère l'interface utilisateur, la présentation à l'écran et la saisie des données.
- soumet des _opérations_ au service **OP**, une requête HTTP POST par opération.
- reçoit (par le browser) les avis _poussés_ émis par le service **PUBSUB**. Chaque avis déclare qu'un ou des documents de la session de l'application ont changé (une _opération_ `Sync` se charge ensuite de récupérer les _nouveaux_ contenus).

### Sessions de l'application dans UN browser donné
En chargeant la page de l'application dans un de ses onglets, **le browser ouvre une nouvelle _session_ de l'application**.

Cette session dure jusqu'à clôture de l'onglet ou chargement d'une autre page Web. 
- une session est universellement identifiée par l'attribution d'un identifiant aléatoire `rnd`.
- un _token_ `subscription` est récupéré / généré à l'ouverture de la session par le script _service worker_:
  - le token est doublement spécifique de l'application et du browser du poste.
  - sur un poste donné plusieurs sessions de l'application peuvent cohabiter dans le même browser: elles ont en conséquence le même jeton `subscription`.

### Connexions successives à un compte dans une session
Au cours d'une session, l'utilisateur peut se connecter et se déconnecter _successivement_ à un ou des comptes. 
- chaque _connexion_ est numérotée `nc` en séquence de 1 à N dans sa session.
- `sessionId` est le string `rnd.nc` qui identifie exactement la vie d'une connexion à un compte entre sa connexion et sa déconnexion dans un browser donné.

### Bases de données locales IDB du browser
A la connexion à un compte, l'application charge depuis le service OP (opération `Sync`) **tous** les documents de son périmètre:
- _presque_ tous, quelques documents ne sont chargés que quand un dialogue spécifique en a besoin.

Chaque compte s'étant connecté depuis le browser y dispose d'une petite base de données IDB interne au browser. Elle stocke les documents du périmètre de ce compte, cryptés, avec exactement le même contenu et format que sur la base de données centrale: c'est une copie des documents _du périmètre du compte_:
- **à l'ouverture d'une connexion**, seuls les documents ayant évolué sur le serveur par rapport à l'état connu dans la base IDB (ou ajoutés depuis la dernière connexion) sont téléchargés: cette phase peut s'en trouver grandement accélérée;
- **en cours de session**, toutes les mises à jour notifiées à la session des documents de son périmètre, sont enregistrées dans cette base locale. Au retour de chaque opération, la session récupère les avis de changements de _ses_ documents et les fait recharger par une requête `Sync` ce qui mettra à jour la base IDB locale du compte.

**La base IDB ne stocke pas par défaut les fichiers attachés aux notes** en raison du volume possiblement important correspondant. Toutefois, pour un browser donné, fichier par fichier, l'utilisateur peut les faire stocker localement. 

### Modes synchronisé, incognito, avion
**Le mode décrit ci-avant est celui _synchronisé_**: la base IDB reflète l'état des documents _du périmètre du compte connecté_ connu lors de la clôture de la session précédente. En cours de session l'état de la base IDB est le même que celui de la base centrale (légèrement retardé du fait des délais _faibles_ de synchronisation).
- les documents sont présents dans la mémoire de la session,
- les fichiers, quand ils ont été déclarés _visible en mode avion_ ne résident pas en mémoire mais uniquement dans la base IDB du compte. La demande de leur affichage évite, pour ces fichiers, un accès au _storage_ distant.

**En mode _incognito_** la base IDB du browser pour le compte n'est pas utilisée:
- en début de session à la connexion tous les documents _du périmètre du compte_ sont chargés depuis le service OP par l'opération `Sync`.
- en cours de session, les notifications reçues du serveur de mise à jour / ajout de documents, provoquent le chargement en mémoire de ceux-ci par l'opération `Sync`.

**En mode _avion_** la base IDB du browser pour le compte est utilisée pour restituer en mémoire le dernier état de la dernière session _synchronisée_ pour le compte.
- le serveur n'est pas accédé,
- les opérations de mises à jour sont bloquées,
- seul les fichiers déclarés _visibles en mode avion_ peuvent être consultés,
- l'utilisateur peut toutefois enregistrer des textes (des notes) et des fichiers dans la base locale pour en disposer dans une session ultérieure _synchronisée ou avion_.

### Le service PUBSUB peut _pousser_ au browser des messages
Ces messages sont des avis de changements de documents du périmètre du compte. Pour ce faire le service PUBSUB doit avoir connaissance de son jeton `subscription`: il récupère cette information à la connexion transmise par le service OP au service PUBSUB (requête `login`).
- le browser transmet à tous ses onglets ouverts sur l'application les notifications ainsi poussées. Chacune est porteuse du `sessionId` (`rnd.nc`) de la connexion concernée: seule la session concernée les traite, les autres (s'il y en a) les reçoivent, aussi, les ouvrent, en lisent le `sessionId` du contenu, constatent que ce n'est pas pour elles et les ignorent.

### Synchronisation vue <-> documents
- Les documents du périmètre de la session sont stockés dans un _espace mémoire réactif_.
- Toutes les _vues_ s'affichant à l'écran sont connectées à cette mémoire réactive.
- En conséquence toute évolution d'un document suite à une notification reçue en cours de session, provoque un rafraîchissement automatique et optimisé de l'affichage.

### Actions de l'utilisateur
L'utilisateur a plusieurs types d'actions possible à sa disposition:
- des actions de _navigation_ c'est à dire de _choix_ des documents ou partie des documents qu'il veut voir à l'écran (changer de _vue_);
- des actions de _saisie_ par l'utilisateur des paramètres des opérations, qui une fois satisfait de sa saisie déclenche une _validation_ qui soumet l'opération correspondante au service OP ...  
- ce qui en général provoque, après vérifications et calculs, des mises à jour de la base ...
- ce qui provoque en retour des avis de modification de documents du périmètre transmise au service PUBSUB ...
- qui détecte toutes les sessions intéressées par une au moins des modifications apportées ...
- qui envoie des avis de modifications aux browsers concernés ...
- qui, chacun, déclenche depuis sa session une opération `Sync` pour obtenir les documents modifiés ...
- ce qui provoque pour chacune la mise à jour _dans la mémoire réactive_ des documents qui l'intéressent ...
- ce qui peut provoquer la mise à jour des vues affichées si elles étaient associés aux paries de mémoire réactives correspondantes.

Bref ce qui se voit à l'écran dans une vue **est toujours** l'état connu dans la base centrale, aux délais techniques de synchronisation près.

### Langue
- tous les textes lisibles par l'utilisateur sont gérés par un composant `I18n` qui permet de les traduire dans différentes langues que l'utilisateur peut choisir par une icône dans sa barre inférieure.
- la traduction a été testée en français et en anglais: toutefois les 1500 textes utilisés sont écrits en français et restent à traduire en anglais, voire d'autres langues. Ces _dictionnaires_ font partie du source de l'application (ils ne sont pas externes) mais sont dans des fichiers bien distincts.
- les panels d'aide en ligne font également partie du source de l'application ce qui permet de les utiliser en mode _avion_, déconnecté d'Internet. Ils sont aussi traduisibles en une autre langue que le français.

# Le service OP des opérations - SES instances

Chaque instance de OP est un service HTTP traitant les opérations soumises par les sessions de l'application.
- une instance de OP est susceptible d'être lancée dès qu'une requête désignant son URL est émise.
- elle vit _un certain temps_ et peut traiter d'autres requêtes, en parallèle et / ou en séquence,
- elle s'arrête au bout d'un certain temps d'inactivité, c'est à dire _sans_ recevoir de requêtes.

**Plusieurs instances de OP peuvent être actives**, à l'écoute de requêtes, à un instant donné. Les requêtes (REST) émises par une session de l'application peuvent être traitées par n'importe laquelle des instances de **OP** actives avec deux conséquences:
- une instance de **OP** ne peut pas conserver en mémoire un historique fiable des requêtes précédentes issues de la même session.
- une instance de **OP** ne peut pas avoir connaissance de toutes les sessions actives.

**Les instances de OP accèdent à la base données de l'application**, en consultation et mise à jour (mais ne _poussent_ pas elles-mêmes de messages de notification aux sessions, cette tâche est effectuée par le service PUBSUB). A chaque transaction de mise à jour exécutée par une instance de OP:
- un objet `trlog` de la transaction est construit avec:
  - l'identifiant du compte sous lequel la transaction est effectuée,
  - le `sessionId` de la session émettrice de l'opération,
  - la liste des IDs des documents modifiés / créés / supprimés et leur version correspondante,
  - la liste des périmètres des comptes (en général 0 ou 1) mis à jour par l'opération.
- l'objet `trlog` (raccourci, sans les périmètres mis à jour) est retourné à la session appelante qui peut ainsi invoquer une requête de synchronisation `Sync` afin d'en obtenir les mises à jour de son état interne.
- l'objet `trlog` (complet) est transmis par une requête HTTP au service **PUBSUB** afin de notifier les autres sessions actives des effets de l'opération sur les documents qui les concernent.

**Principe de cryptage**
- Toutes les données humainement interprétables des comptes, cartes de visites, commentaires, chats, textes et fichiers de leurs notes, etc. sont **cryptées** dans l'application dans le browser.
- Il en est de même pour toutes les clés de cryptage qui sont générées dans l'application dans le browser et sont elles-mêmes cryptées avant d'être transmises aux services.
- Seuls les titulaires des comptes peuvent décrypter ces textes et clés du fait de la connaissance de leur phrase secrète, aucun administrateur ne peut y accéder, ni les intercepter sur le réseau, ni les lire dans la base ou le Storage.
- Les _meta-données_ liant les documents entre eux, par exemple l'appartenance d'un avatar à un groupe, sont gérées (et donc connues) des services OP et PUBSUB: toutefois elles ne sont pas lisibles dans la base de données où elles sont cryptées par une clé détenue par l'administrateur technique.

# Le service PUBSUB de gestion des sessions actives - UNE SEULE instance active

L'instance **unique à un instant donné** est un serveur HTTP en charge:
- de garder en mémoire la liste des sessions _actives_ (connectées à un compte) de l'application et de conserver pour chacune d'elle son _périmètre_: la liste des IDs des documents qui l'intéresse.
- d'émettre des _messages de notification_ à toutes les sessions enregistrées dont un des documents de leur périmètre a évolué suite à une opération effectuée dans un instance OP.

**Les instances de OP envoient une requête `login` à chaque connexion** (réussie) à un compte d'une session en lui donnant les informations techniques de `subscription` (permettant à PUBSUB d'émettre des notifications à la session correspondante) ainsi que son _périmètre_.

**Chaque session _active_ dans un browser émet périodiquement (toutes les 2 minutes) un _heartbeat_,** une requête à PUBSUB avec son `sessionId`:
- un _heartbeat_ spécial de déconnexion est émis à la clôture de la connexion à un compte.
- au bout de 2 minutes sans avoir reçu un _heartbeat_ PUBSUB détruit le contexte de la session (considérée comme fermée).
- quand l'instance PUBSUB n'a pas reçu de requêtes depuis un certain temps, c'est qu'elle n'a plus connaissance de sessions actives: elle _peut_ s'arrêter (avec un état interne vierge). Une nouvelle instance sera lancée lors de la prochaine connexion à un compte (requête `login` émise par une instance de service OP).
  
L'instance PUBSUB n'est pas forcément _permanente_: il y en a une (seule) active dès lors qu'une session s'est connectée à un compte et le reste jusqu'à déconnexion de la dernière session active.

**A chaque transaction de mise à jour exécutée par une instance du service OP:** une requête `notif` au service PUBSUB est émise lui transmettant l'objet `trlog` de la transaction. PUSUB est ainsi en mesure,
- d'identifier toutes les sessions actives ayant un document de leur périmètre impacté (en ignorant la session origine de la transaction informée directement par OP),
- de mettre à jour le cas échéant les périmètres des comptes modifiés.
- d'émettre, de manière désynchronisée, à chacune de celles-ci la liste des IDs des documents mis à jour la concernant avec leurs versions (un objet `trlog` _raccourci_ construit spécifiquement pour chaque session),
- Chaque session ainsi _notifiée_ sait quels documents de son périmètre a changé et peut demander au service OP par une requête `Sync` les mises à jour associées.

**Le service PUBSUB n'a aucune mémoire persistante** et n'accède pas à la base de données: c'est un service de calcul purement en mémoire maintenant l'état des sessions actives.

**Quand le service PUBSUB est _down_** l'application reste fonctionnelle, mais:
- les sessions ne sont pas _notifiées_ des mises à jours opérées par les autres sessions.
- les sessions doivent, sur action explicite de l'utilisateur, demander des synchronisations _complètes_, vérifiant la version de tous les documents de leur périmètre.
- chaque transaction gérée par le service OP ne pourra pas joindre le service PUBSUB: le retour de la requête indiquera cette indisponibilité pour information de la session qu'elle est en mode dégradé _sans notification continue_ des effets des opérations des autres sessions impactant son périmètre.

# La base de données centrale 
Ses données sont stockées à l'occasion des opérations de mises à jour effectuées par une instance de service **OP**. 

Trois implémentations interchangeables correspondent à trois classes _providers_ présentant le même API, sont disponibles:
- **SQLite**: principalement pour les tests, ou pour une production de faible puissance sur un serveur géré.
- **PostgreSQL** (à faire): supportant plusieurs instances de services OP et pouvant être hébergé par un service géré.
- **Firestore** (Firebase), base NOSQL en service hébergé par Google Cloud Platform.

Une classe _provider_ est écrite pour chaque modèle de base de données souhaité.
- chaque _provider_ offre le même jeu d'une quarantaine de méthodes d'accès (environ 500 lignes de code),
- la signature en est identique pour tous les providers de sorte qu'utiliser l'un ou l'autre n'est qu'un choix de l'administrateur technique. 
- hors de ces classes, les autres ignorent la technologie de la base de données sous-jacente utilisée.

# Le Storage
C'est un service _externe_ de stockage de fichiers dont trois implémentations interchangeables (trois classes _providers_) ont été développées:
- **File-System** : pour le test, les fichiers sont stockés dans un répertoire local.
- **Google Cloud Storage** : a priori il n'y a pas d'autres providers que Google qui propose ce service.
- **AWS/S3** : S3 est le nom de l'interface, plusieurs fournisseurs en plus d'Amazon le propose.
  - L'application (libre) `minio` permet de mettre en œuvre son propre stockage S3 sur le(s) serveur(s) de son choix, ce qui permet de tester le provider S3 sans utiliser de service payant.

# L'utilitaire EXPORT de l'administrateur technique

Du fait de l'uniformité de l'interface d'accès, l'utilitaire `export-db` permet d'exporter une base vers une autre de technologie éventuellement différente.

Par commodité de développement, il est intégré au logiciel des services OP / PUBSUB. Il est lancé en ligne de commande dans un terminal avec pour premier argument le nom de l'utilitaire
- `export-db` : export de la partie de la base données relative à une organisation dans une autre base (ou la même).
- `export-st` : export des fichiers d'une organisation d'un _storage_ à un autre (ou le même).
- `purge-db` : purge des données d'une organisation dans une base.
- `purge-st` : purge des fichiers d'une organisation dans un storage.

> Remarque: l'export de base `firestore` vers `firestore` étant techniquement limité par les contraintes d'environnement d'API de Google (à vérifier !!!) il faut dans ce cas utiliser un double export `firestore -> sqlite` puis `sqlite -> firestore`.

> Remarque: l'export de Storage `gc` (Google Cloud) vers `gc` étant techniquement limité par les contraintes d'environnement d'API de Google (à vérifier !!!) il faut dans ce cas utiliser un double export `gc -> fs (File-System)` puis `fs -> gc`.

> Remarque: il est donc simple d'effectuer une photo d'un espace de production vers un autre de test et le cas échéant d'ailleurs de permettre aux utilisateurs d'accéder au choix aux deux.

# L'utilitaire de téléchargement de notes sur un poste: `upload` 

Cet utilitaire permet de stocker dans un répertoire local d'un poste (Windows / Linux) des notes et leurs fichiers attachés.

Une page Web standard n'est pas autorisée à écrire sur le système de fichier du poste, sauf quand l'utilisateur en donne l'autorisation et la localisation fichier par fichier: pour télécharger en local toutes les notes sélectionnées par l'utilisateur et leurs fichiers, ce qui peut représenter des centaines / milliers de fichiers et des Go d'espace, l'application UI fait appel à un micro-serveur HTTP `upload` qui s'exécute localement sur le poste.

Le source consiste en moins de 100 lignes de code écrite en `node.js` / Javascript.

`upload` peut être téléchargé par Internet (`upload.exe` pour la version Windows).

Une fois téléchargé et lancé sur le poste où s'exécute le browser accédant à l'application, ce micro serveur HTTP permet de récupérer (en clair) dans un répertoire local au poste les notes sélectionnées par l'utilisateur et leurs fichiers. 

# Variantes de mise en œuvre

**L'application Web** est buildée par Webpack puis est distribuée dans un service comme **GitHub Pages**, ou tout autre site statique Web ayant une URL d'accès et un accès HTTPS.

## Hébergement NON géré des services OP et PUBSUB
Typiquement, une VM, voire plusieurs VMs, hébergent les services OP et PUBSUB:
- pour PUBSUB, une seule instance doit être en exécution. Si la puissance requise devient trop forte, il faut procéder à un développement complémentaire sommairement décrit en Annexe.
- pour OP, plusieurs instances peuvent être lancées avec un front-end de distribution du traffic, typiquement NGINX. Toutefois le provider SQLite n'est plus possible, il faut choisir l'un des 2 autres (PostgreSQL ou Firestore).

Le fait d'être NON géré impose de consacrer de l'énergie à surveiller le bon fonctionnement et à relancer les services tombés. Toutefois la base de données peut elle être gérée, même si OP+PUBSUB ne l'est pas, et dispenser ainsi de la charge de sauvegarde / restauration / redémarrage.

## Hébergement géré par Cloud Functions de OP
Google, Amazon Web Services, Azure ... proposent ce service: une _cloud function_ est lancée dès qu'une requête fait appel à une opération de OP.

Sur Google, l'option Google App Engine (GAE) est également possible mais n'a vraiment d'intérêt que pour gérer conjointement OP+PUBSUB.

## Hébergement géré par Cloud Functions de PUBSUB
Google, Amazon Web Services, Azure ... proposent ce service qui **DOIT** être configuré pour n'avoir qu'une instance AU PLUS en exécution.

GAE est une option chez Google avec un paramétrage avec une instance au plus.

## SRV: OP + PUBSUB - UNE SEULE instance active à tout instant
SRV traite les deux services OP et PUBSUB dans une seule instance de serveur HTTP. Cette option est pertinente dans les cas suivants:
- en test local,
- dans une VM en contrôlant qu'il y n'y a bien qu'une seule instance active au plus à tout instant,
- dans une _Cloud Function_ ou _Server géré (GAE)_ avec un trafic suffisamment faible pour supporter une configuration garantissant qu'il n'y a jamais plus d'une instance active à un moment donné. 

Un déploiement GAE avec un faible trafic est probablement en dessous du seuil de facturation.

## Augmentation de la puissance
Pour le site distribuant l'application, pas de souci, les services gérés sur le marché sont tous assez puissants.

L'augmentation de puissance pour OP se fait en service géré en autorisant un plus grand nombre d'instances.

Concernant PUBSUB, si la puissance demandée excède ce que peut supporter une instance NodeJS, voir les possibilités de développement indiquées en annexe. Toutefois, PUBSUB n'effectue sur requête POST entrante QUE du travail en mémoire et des requêtes POST sortantes pour les notifications. Il faut vraiment un très gros traffic pour atteindre cette limite. 

## Service de base de données
Firestore est un service de Google, géré et de puissance extensible: la limite n'a pas pu être mesurée. Pour un trafic faible, le seuil de facturation peut ne pas être atteint.

Il existe sur le marché des offres de PostgreSQL géré mais leur coût de départ est élevé (de l'ordre de 20€ mensuels): si le trafic est très important, c'est un coût à comparer avec celui de Firestore.

> Il est également possible d'effectuer le développement d'autres _providers_ d'accès à une base de données NOSQL, typiquement celles proposées par Azure et AWS, qui, a priori, sont réalisables en raison de la proximité de leurs API avec l'API de Firestore.

## Service de Storage
L'offre du marché est importante entre Google et Amazon Web Service, mais aussi toutes les offres compatibles S3. 

Il n'apparaît pas concevable d'atteindre la limite de puissance de ses offres. 

Les sessions accèdent directement au service de Storage: le service OP se limite à fournir pour chaque échange une URL d'accès temporaire et spécifique du fichier concerné, le lourd échange est ensuite directement opéré entre le browser de l'utilisateur et le service de Storage.

Si le volume est faible, le seuil de facturation chez Google peut ne pas être atteint.

# Les _espaces_

Un _site_ est constitué d'un service OP, d'un service PUBSUB, de sa base de données et de son storage.

Chaque site a,
- son _administrateur technique_, ayant sa phrase secrète de connexion qu'il est seul à connaître en clair,
- une _clé technique de cryptage spécifique du site_ pour crypter les données en base de données (mais qui ne permet en rien d'accéder aux données cryptées par les comptes). Seul l'administrateur technique en connaît la source en clair.

**UN _site_ peut héberger plusieurs organisations (jusqu'à 60) de manière totalement étanche entre elles.**

**Une organisation est identifiée par un code** de 4 à 8 lettres ou chiffres ou - comme `monorg`:
- à la connexion un utilisateur fournit le code de son organisation et sa phrase secrète.
- dans le _storage_ chaque organisation a un _folder_ portant le nom de l'organisation. Autre expression plus exacte les noms des fichiers des notes de l'organisation `monorg` commencent tous par `monorg/...`.

En base de données chaque organisation est identifiée par un code `ns` (_name space_) un signe `0-9 a-z A-Z` qui préfixe les identifiants des documents en base.

**Conséquences**
- **on peut exporter une base** en lui changeant son couple _ns / org_:  `1 monorg` en un autre `4 monorg2`.
- **on peut exporter un storage** `monorg` en `monorg2`, les fichiers étant copiés à l'identique mais avec un nom qui commence par `monorg2/...` au lieu de `monorg/...`
- on peut purger une base de données d'un `ns` donné (`1` par exemple).
- on peut purger un espace de nom `monorg` donné.

Il est simple de procéder à l'exportation d'une organisation depuis un _site_ vers un autre _site_, de technologie différente ou non pour la base de données et le storage, et administrée par une entité complètement différente et autonome du _site_ source.

Il est aussi simple de _prendre une photo_ à un instant donné d'un espace `1` par exemple et de l'exporter sur un espace `2` à des fins d'audit, d'archivage ou de debug.
- pendant l'export, l'espace source est figé par l'administrateur technique en lecture seule pour disposer d'un cliché cohérent, il est ensuite rouvert à la mise à jour à la fin de l'export.

# Annexe : _ES6_ versus _CommonJs_

Les logiques de l'application UI comme du serveur sont écrites en Javascript: la question se pose donc du système de modularisation choisi.

Les deux systèmes de gestion de modules co-existent avec une certaine difficulté:
- **ES6** est désormais le standard: les modules ne présentant que la forme `require()` de CommonJs se raréfient mais existent encore.
- **CommonJs** était le système de gestion de modules de Node.js avant la normalisation ES6.

**L'application a été centrée sur ES6** avec quelques contorsions vis à vis des modules étant resté en CommonJs sans offrir d'importation ES6.

### Application UI
Un seul module est concerné: `pako`.

Un seul source `src/boot/appconfig.js` effectue à l'initialisation de l'application un `require('pako')` et met le résultat à disposition du module `src/app/util.mjs`.

Hormis cette ligne, les autres scripts de l'application sont ES6 (`.mjs`).

### Services
Le fichier de démarrage `src/server.js` est un module ES6, malgré son extension `.js`:
- le déploiement Google App Engine (GAE) **exige** que ce soit un `.js` et que `package.json` ait une directive `"type": "module"`.
- pour les tests usuels, il faut `"type": "module"`.
- MAIS pour un déploiement **NON GAE**, un build `npx webpack` est requis et cette dernière directive **DOIT** être enlevée ou renommée `"typeX"`.

_Remarques pour le build du serveur pour déploiement NON GAE_
- `webpack.config.mjs` utilise le mode `import` plutôt que `require` (les lignes pour CommonJs sont commentées).
- une directive spécifique dans la configuration `webpack.config.mjs` a été testée pour que `better-sqlite3` fonctionne en ES6 après build par webpack. Mais ça n'a pas fonctionné et `better-slite3` reste chargé par un `require` dans `src/loadreq.mjs` (qui ne sert qu'à ça).

> Remarque : il n'existe que 3 entorses à ES6 et la présence de `require`: 
- a) `pako` dans l'application Web : fichier `src/boot/appconfig.js`,
- b) `better-sqlite3` dans le service OP : fichier `src/loadreq.mjs`.
- c) `web-push` dans le service PUBSUB : fichier `src/notif.mjs`.
