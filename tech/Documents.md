@@Index général de la documentation [index](https://raw.githack.com/dsportes/asocial-doc/master/index.md)

# Données persistantes sur le serveur
Elles son réparties en deux catégories:
- les données stockées dans la _base_,
- les _fichiers_ présents dans le _Storage_.

## _Storage_
Il est à 3 niveaux `org/id/nf` :
- `org` : code l'organisation détentrice,
- `id` : id de l'avatar ou du groupe à qui appartient le fichier.
- `nf` : numéro (aléatoire) du fichier par rapport à son avatar / groupe.

Trois implémentations ont été développées:
- **File-System** : pour le test, les fichiers sont stockés dans un répertoire local.
- **Google Cloud Storage** : a priori il n'y a pas d'autres providers que Google qui propose ce service.
- **AWS/S3** : S3 est le nom de l'interface, plusieurs fournisseurs en plus d'Amazon le propose.

## _Base_
La base peut avoir plusieurs implémentations : un _provider_ est la classe logicielle qui gère l'accès à sa base selon sa technologie.

On distingue deux classe d'organisation techniques: **SQL** et **NOSQL+Data Sync**.

### SQL
Les données sont distribuées dans des **tables** `espaces avatars versions notes ...`
- une base SQL n'implémente pas de **Data Sync**.
- il faut un _serveur_ qui, en plus de servir les transactions de lecture / mises à jour, notifient les sessions clientes vivantes abonnées à ces mises à jour:
  - le serveur dispose de la liste des sessions clientes actives et pour chacune sait aux mises à jour de quels documents elle est _abonnée_.
  - le _serveur_ doit être _up_ a minima tant qu'une session cliente est active.
  - un _heartbeat_ régulier est envoyé par chaque session pour signaler qu'elle existe encore, même en l'absence de transaction.
  - si le serveur tombe _down_, toutes les sessions en cours sont de facto déconnectées 
- la première implémentation correspond à une base `Sqlite`, un serveur `node` et une notification **Data Sync** par WebSocket.

### NOSQL-Data Sync
Chaque table SQL correspond à une **collection de documents**, chaque document correspondant à un **row** de la table SQL de même nom que la collection.
- la base implémente un mécanisme de **Data Sync** par lequel une session peut directement demander à la base de lui notifier les mises à jour des documents qui l'intéresse, sans passer par un _serveur_ intermédiaire pour ce service.
- il faut a minima une _Cloud Function_ pour gérer les transactions de lecture / mises à jour:
  - le service correspondant peut être _up_ juste le temps d'une transaction et repasser _down_ en l'absence de sollicitation.
  - il peut être assuré dans un serveur qui reste _up_ en continu (du moins sur une longue durée).
- les sessions clientes sont insensibles à la tombée _down_ de la Cloud Function (ou du serveur). Les les abonnements ne sont gérés que par les sessions clientes et d'ailleurs la Function n'a pas de concept de _session cliente_. 
- la première implémentation correspond à une base Firestore et à une Google Cloud Function. 

> **Remarque:** entre une implémentation GCP Function et AWS Lambda, il n'y a apriori qu'une poignée de lignes de code de différence dans la configuration de l'amorce du service et bien entendu une procédure de déploiement spécifique.

## Équivalence SQL et NOSQL
Les _colonnes_ d'une table SQL correspondent aux _attributs / propriétés_ d'un document.
- en SQL la _clé primaire_ est une propriété attribut ou un couple de propriétés,
- en Firestore le _path_ d'un document contient cette propriété ou couple de propriétés.

## GC _garbage collector_
C'est un traitement de nettoyage qui est lancé une fois par jour. Il a plusieurs phases techniques:
- suppression de rows / documents obsolètes,
- détection des comptes à détruire par inutilisation,
- nettoyage des fichiers fantômes sur _Storage_,
- calcul de _rapports / archivages_ mensuels pouvant conduire à purger des données vivantes de la base.

En général c'est un service externe de **CRON** qui envoie journellement une requête de GC. Sur option ce peut être un déclenchement interne au serveur.

# Table / collection technique `singletons`
Ces quelques documents sont _purement techniques_:
- ils n'ont d'intérêt que d'audit par l'administrateur technique,
- ils sont _à la racine_ de la base, ne dépendent d'aucun espace,
- ils ne sont pas exportés,
- ils sont écrits, écrasés, jamais reluis ni détruits.
- ils sont facultatifs: la base est opérationnelle sans leur présence et c'est effectivement le cas pour une base _neuve_.

La collection `singletons` a un nombre fixe de documents représentant les derniers _rapports de GC_:
- `id` :
  - `1` : rapport du dernier _ping_ effectué sur la base.
  - `10-19` : rapports des phases du GC,
  - `20-29` : rapport de la dernière génération de rapports par le GC.
- `v` : estampille d'écriture en ms.
- `_data_` : sérialisation non cryptée des données traçant l'exécution d'une phase du dernier traitement journalier de GC (garbage collector), ou trace du _ping_.

Par exemple le _path_ en Firestore du dernier _ping_ est `singletons/1`.

# Espaces
Tous les autres documents comportent une colonne / attribut `id` dont la valeur détermine un partitionnement en _espaces_ cloisonnés : dans chaque espace aucun document ne référence un document d'un autre espace.

Un espace est identifié par `ns`, **un entier de 10 à 89**. Chaque espace à ses données réparties dans les collections / tables suivantes:
- `espaces syntheses` : un seul document / row par espace. Leur attribut `id` (clé primaire en SQL) a pour valeur le `ns` de l'espace. Path Firestore pour le `ns` 24 par exemple : `espaces/24` `syntheses/24`.
- tous les autres documents ont un attribut / colonne `id` de 16 chiffres dont les 2 premiers sont le `ns` de leur espace. Les propriétés des documents peuvent citer l'id d'autres documents mais sous la forme d'une _id courte_ dont les deux premiers chiffres ont été enlevés.

## Code organisation attaché à un espace
A la déclaration d'un espace sur un serveur, l'administrateur technique déclare un **code organisation**:
- ce code ne peut plus changer: lors d'une _exportation_ d'un espace on peut définir un autre code d'espace pour la cible de l'exportation.
- le Storage de fichiers comporte un _folder_ racine portant ce code d'organisation ce qui partitionne le stockage de fichiers.
- les connexions aux comptes citent ce _code organisation_.

## L'administrateur technique
Il a pour rôle majeur de gérer les espaces:
- les créer / les détruire,
- définir leurs quotas à disposition du Comptable de chaque espace: il existe trois quotas,
  - `q1` : nombre maximal autorisé des notes, chats, participations aux groupes,
  - `q2` : volume total autorisé des fichiers attachés aux notes.
  - `qc` : quota de calcul mensuel total en unité monétaire.
- ces quotas sont _indicatifs_ sans blocage opérationnel et servent de prévention à un crash technique pour excès de consommation de ressources.

Ses autres rôles sont :
- la gestion d'une _notification / blocage_ par espace, 
  - soit pour information technique importante, 
  - soit pour _figer_ un espace avant sa migration vers un autre (ou sa destruction).
- l'export de la _base_ d'un espace vers une autre,
- l'export des fichiers d'un espace d'un _Storage_ à un autre.

## Comptable de chaque espace
Pour un espace, `24` par exemple, il existe un compte d'id `2410000000000000` qui est le **Comptable** de l'espace. 

Le Comptable dispose des quotas globaux de l'espace attribués par l'administrateur technique. Il définit un certain nombre de **partitions de quotas** et confie la gestion de chacune à des comptes _délégués_ qui peuvent les distribuer aux comptes "O" affecté à leur partition.

Le rôle principal d'un _Comptable_ est,
- de partitionner les quotas attribués aux comptes "O"  de quotas et d'en ajuster les quotas,
- de déclarer les _délégués_ de chaque partition, le cas échéant de retirer ou d'ajouter la qualité de _délégué_ a un compte "O".
- de gérer des _notifications / blocages_ s'appliquant à des comptes "O" spécifiques ou à tous les comptes d'une partition.
- d'enregistrer les paiements des comptes A.

Le Comptable :
- ne peut pas se résilier lui-même,
- ne peut pas changer de partition de quotas, il est rattaché à la partition 1 de son espace qui ne peut pas être supprimée.
- ne peut pas supprimer son propre attribut _délégué_,
- accepte l'ouverture de **chats** avec n'importe quel compte "O" ou "A" qui en prend l'initiative.

# Tables / collections _techniques_ de nettoyage du _Storage_

L'écriture et la suppression de fichiers du _Storage_ ne sont pas soumises à la gestion transactionnelle du commit de la base. En conséquence, elles peuvent être,
- **marqués dans la base comme _en écriture sur Storage_**, puis une fois vraiment écrits, enregistrés comme tels dans la base. Mais si un problème technique intervient au mauvais moment, ils peuvent ne pas être marqués _écrits_ dans la base et être cependant présents dans le _Storage_: il faut périodiquement nettoyer ces fichiers _fantômes_ dont l'upload n'a pas été enregistré en base. C'est l'objet des documents `transferts`.
- **considérés comme _logiquement_ détruits dans la base**, mais n'ayant pas encore été physiquement purgés du _Storage_. Il faudra, un jour, achever d'effectuer ces _purges_ physiques du _Storage_. C'est l'objet des documents `fpurges`.

## Documents `transferts`
- `id` : identifiant _majeur_ du fichier, une id d'avatar ou de groupe.
- `ids` : identifiant du fichier relativement à son id majeure, son _numéro de fichier_.
- `v` : jour d'écriture, du début de _l'upload_.

Ces documents ne sont jamais mis à jour une fois créés, ils ont supprimés,
- en général quasi instantanément dès que _l'upload_ est physiquement terminé,
- par le GC qui considère qu'un upload ne peut pas techniquement être encore en cours à j+2 de son jour de début.

## Documents `fpurges`
- `id` : aléatoire, avec ns en tête,
- `_data_` : liste encodée,
  - soit d'un `id` d'un avatar ou d'un groupe, correspondant à un folder du _Storage_ à supprimer,
  - soit d'un couple `[id, ids]` identifiant UN fichier `ids` dans le folder `id` d'un avatar ou d'un groupe.

Ces documents ne sont jamais mis à jour une fois créés, ils ont supprimés par le prochain GC après qu'il ait purgé du _Storage_ tous les fichiers cités dans _data_.

## Documents `dpurges`
C'est un singleton par espace:
- `id` : ns de l'espace.
- `lids` : liste des id des avatars ou des groupes à purger.

Au cours d'une opération, on évite une opération longue de suppression de tous les sous-documents: ceci est effectué en différé par le GC pour tous les documents cités dans `dpurges`. La liste `lids` est mise à jour au fur et à mesure. 

# Table / documents d'un espace

## Entête d'un espace: `espaces syntheses`
Pour un espace donné, ce sont des singletons:
- `espaces` : `id` est le `ns` (par exemple `24`) de l'espace. Le document contient quelques données générales de l'espace.
  - Clé primaire : `id`. Path : `espaces/24`
- `syntheses` : `id` est le `ns` de l'espace. Le document contenant des données statistiques sur la distribution des quotas aux comptes "O" (par _partition_) et l'utilisation de ceux-ci.
  - Clé primaire : `id`. Path : `syntheses/24`

# Tables / collections _majeures_ : `partitions comptas avatars groupes`
Chaque collection a un document par `id` (clé primaire en SQL, second terme du path en Firestore).
- `partitions` : un document par _partition de quotas_ décrivant la distribution des quotas entre les comptes "O" attachés à cette partition.
  - `id` (sans le `ns`) est un numéro séquentiel `1..N`.
  - Clé primaire : `id`. Path : `partitions/0...x`
- `comptas` : un document par compte donnant les informations d'entête d'un compte (dont l'`id` est celui de son avatar principal). L'`id` courte sur 14 chiffres est le numéro du compte :
  - `10...0` : pour le Comptable.
  - `2x...y` : pour les autres comptes, `x...y` est un nombre aléatoire sur 13 chiffres.
  - Clé primaire : `id`. Path : `comptas/10...0` `comptas/2x...y`
- `avatars` : un document par avatar donnant les informations d'entête d'un avatar. L'`id` courte sur 14 chiffres est le numéro d'un avatar du compte :
  - `10...0` : pour l'avatar principal (et unique) du Comptable.
  - `2x...y` : pour les avatars principaux ou secondaires des autres comptes. `x...y` est un nombre aléatoire sur 13 chiffres.
  - Clé primaire : `id`. Path : `avatars/10...0` `avatars/2x...y`
- `groupes` : un document par groupe donnant les informations d'entête d'un groupe. L'`id` courte sur 14 chiffres est le numéro d'un groupe :
  - `3x...y` : `x...y` est un nombre aléatoire sur 13 chiffres.
  - Clé primaire : `id`. Path : `groupes/3x...y`

# Tables / sous-collections d'un avatar ou d'un groupe
- chaque **avatar** a 4 sous-collections de documents: `notes sponsorings chats tickets` (seul l'avatar Comptable a des tickets).
- chaque **groupe** a 3 sous-collections de documents: `notes membres chatgrs`.

Dans chaque sous-collection, `ids` est un identifiant relatif à `id`. 
- en SQL les clés primaires sont `id,ids`
- en Firestore les paths sont (par exemple pour la sous-collection note) : `sdocs/2.../notes/z...t`, `id` est le second terme du path, `ids` le quatrième.

- `notes` : un document représente une note d'un avatar ou d'un groupe. L'identifiant relatif `ids` est un nombre aléatoire.
- `sponsorings` : un document représente un sponsoring d'un avatar. Son identifiant relatif est _ns +  hash de la phrase_ de reconnaissance entre le sponsor et son sponsorisé.
- `chats` : un chat entre 2 avatars A et B se traduit en deux documents : 
  - l'un sous-document de A a pour identifiant secondaire `ids` un hash des clés de B et A.
  - l'autre sous-document de B a pour identifiant secondaire `ids` un hash des clés de A et B.
- `membres` : un document par membre avatar participant à un groupe. L'identifiant secondaire `ids` est l'indice membre `1..N`, ordre d'enregistrement dans le groupe.
- `chatgrs`: un seul document par groupe. `id` est celui du groupe et `ids` vaut toujours `1`.
- `tickets`: un document par ticket de crédit généré par un compte A. `ids` est un nombre aléatoire tel qu'il puisse s'éditer sous forme d'un code à 6 lettres majuscules (de 1 à 308,915,776).

# Périmètre d'un compte _Data Sync_
Le périmètre d'un compte délimite un certain nombre de documents:
- un compte n'a la visibilité en session UI que des documents de son périmètre.
- il ne peut s'abonner qu'à ceux-ci, si c'est sa session qui gère les abonnements. Si c'est le _serveur_ il n'abonne une session donnée d'un compte qu'aux documents du périmètre du compte.

Le _périmètre_ d'un compte ayant une id donnée est le suivant:
- le document `espaces` portant comme ns celui de l'id du compte.
- le document `synthèses` portant comme ns celui de l'id du compte.
- le document `comptas` portant cette id.
- les documents `avatars` des avatars principaux et secondaires du compte,
- les sous-documents `notes sponsorings chats tickets` de ces avatars.
- les documents `groupes` dont un des avatars du compte est membre actif.
- les sous-documents `notes membres chatgrs` de ces groupes.

Exceptions pour le Comptable:
- le Comptable peut voir tous les documents espaces synthèses et pas seulement ceux de _son_ espace.
- En plus de _son_ espace, le Comptable a accès à un instant donné à UN autre espace _courant_ (mais qui peut changer).

## Data Sync
Chaque session UI d'un compte dispose en mémoire de **tous** les documents de son périmètre.

Une session _synchronisée ou avion_ dispose de tous les documents de ce périmètre **sauf** son document syntheses.

Le mécanisme de Data Sync permet à la mémoire d'une session (et à sa base locale le cas échéant) de refléter au plus tôt l'état des documents du périmètre tel qu'il existe en base, **sauf** le document synthèses qui est chargé à la demande (pas en avion donc).

> Cet état en mémoire est en conséquence sujet à des évolutions constantes suite aux effets des opérations soumises au serveur, soit par la session elle-même, soit par n'importe quelle autre, du même compte ou de n'importe quel autre, et marginalement du GC.

## Tracking des créations et mises à jour
**Remarque:** il n'y a pas à proprement parlé de _suppressions_:
- un document sponsorings a une date limite de validité: le document est logiquement supprimé que cette date est dépassée.
- un document notes peut être _vide_, n'a plus de contenu, n'apparaît plus dans les vues, mais son document existe toujours.

Les documents `versions` sont chargés de ce tracking. Propriétés:
- `id` : _référence data sync_ d'un document `espaces comptas avatars groupes`.
- `v` : version, incrémentée de 1 à chaque mise à jour, soit du document maître, soit de ses sous-documents `notes sponsorings chats tickets membres chatgrs`
- `suppr` : jour de suppression.

La _référence data sync_ `rds` est une id aléatoire sur 16 chiffres avec les deux premiers correspondant au `ns`. **Elle est générée aléatoirement à la création d'un document** `espaces comptas avatars groupes` et y est stockée.

> **Remarque:** un serveur ne lit pas les documents `versions`, mais les créé et les met à jour. Seul le GC lit les `versions` mais uniquement celles supprimées depuis plus de N mois, pour les purger (en SQL ce n'est donc même pas une lecture, mais un simple `DELETE` avec une clause `WHERE` sur `suppr`).

**A l'ouverture d'une session UI**, dès qu'on dispose du périmètre des avatars et des groupes de son compte, on peut acquérir leurs `versions` et s'y abonner:
- ainsi muni pour chacun de `v`, on peut mettre à jour sa mémoire et sa base locale incrémentalement en ne demandant que les (sous) documents mis à jour postérieurement.
- quand il y a une marque `suppr`, une session peut supprimer l'avatar ou le groupe correspondant. Toutefois au bout de plus de N mois sans connexion sur ce poste (N de 6 à 24 mois), on considère qu'il n'est plus acceptable de procéder par mise à jour incrémentale et la base locale est remise à 0.
  - le GC purge les documents versions ayant une marque de suppression plus vieille de 6 à 24 mois (selon le paramètre configuré dans api.mjs ces données étant devenues inutiles.

**En cours de session UI après la phase de _connexion_,** on a connaissance de tous les documents de son propre périmètre et en conséquence de leur `rds`.
- une session peut s'abonner aux mises à jour des documents `versions` correspondant aux `rds` des documents de son périmètre.
- une session ne peut pas faute de connaître leur `rds`, s'abonner aux mises à jour des documents hors de son périmètre. Certes elle ne pourrait pas les lire mais si elle pouvait s'abonner à ceux-ci elle obtiendrait des informations sur l'activité des autres comptes, ce qu'on ne veut pas.

Les documents `sous-collections` d'un avatar (resp. d'un groupe) ont une version `v` qui est enregistrée en séquence croissante continue dans son `versions`. 
- Le `v` de `versions` est la plus haute version de tous les sous-documents de l'avatar (resp. du groupe) et de l'avatar (resp. du groupe) lui-même.

En cas de _suppression_ d'un avatar (resp. d'un groupe),
- la version `v` s'incrémente,
- `suppr` porte le jour de suppression: ceci permet aux sessions de se resynchroniser incrémentalement, (du moins pendant N mois) et de détecter le rétrécissement du périmètre du compte.

Les sessions recevant cette information peuvent,
- supprimer de leur mémoire (et base locale) le document et ses sous-documents correspondant,
- supprimer leur abonnement, qui ne recevrait d'ailleurs plus rien, la version n'évoluant plus.

**La constante `IDBOBS / IDBOBSGC` de `api.mjs`** donne le nombre de jours de validité d'une micro base locale IDB sans resynchronisation. Celle-ci devient **obsolète** (à supprimer avant connexion) `IDBOBS` jours après sa dernière synchronisation. Ceci s'applique à _tous_ les espaces avec la même valeur.

# Sponsoring des comptes, comptes _délégués_ d'une partition
## Comptes "O"
Tout compte "0" est attaché à une _partition_: ses quotas `qc q1 q2` sont prélevés sur ceux de sa partition.

Un compte "O" est créé par _sponsoring_,
- soit d'un compte "O" existant _délégué_ : 
- soit du Comptable qui a choisi de quelle partition il relève.

Les comptes "0" _délégués_ d'une partition peuvent:
- sponsoriser la création de nouveaux comptes "O", _délégués_ eux-mêmes ou non de cette partition.
- gérer la répartition des quotas entre les comptes "O" attachés à cette partition.
- gérer une _notification / blocage_ pour les comptes "O" attachés à leur partition.

## Comptes "A"
Un compte "A" est créé par _sponsoring_,
- soit d'un compte "A" existant qui à cette occasion fait _cadeau_ au compte sponsorisé d'un montant de son choix prélevé sur le solde monétaire du compte sponsor.
- soit par un compte "O" _délégué_ ou par le Comptable:
  - un cadeau de bienvenue de 2c est affecté au compte "A" sponsorisé (prélevé chez personne).

Un compta "A" définit lui-même ses quotas `q1` et `q2` (il les paye en tant _qu'abonnement_) et n'a pas de quotas `qc` (il paye sa _consommation_).

# Détail des tables / collections _majeures_ et leurs _sous-collections_
Ce sont les documents cible d'un esynchronisation entre sessions UI et base: `partitions comptas avatars groupes notes sponsorings chats tickets membres chatgrs`

## _data_
Tous les documents, ont une propriété `_data_` qui porte toutes les informations sérialisées du document.

`_data_` est crypté:
- en base _centrale_ par la clé du site qui a été générée par l'administrateur technique et qu'il conserve en lieu protégé comme quelques autres données sensibles (_token_ d'autorisation d'API, identifiants d'accès aux comptes d'hébegement ...).
- en base _locale_ par la clé K du compte.
- le contenu _décrypté_ est le même dans les deux bases et est la sérialisation d'un objet de classe correspondante.

## Propriétés _externalisées_ hors de _data_ : `id ids v` etc.
Elles le sont,
- soit parce que faisant partie de la clé primaire `id ids` en SQL, ou du path en Firestore,
- soit parce qu'elles sont utilisées dans des index, en particulier la version `v` du document.

### `id` et `ids` quand il existe
Ces propriétés sont externalisées et font partie de la clé primaire (en SQL) ou du path (en Firestore).

Pour un `sponsorings` la propriété `ids` est le hash de la phrase de reconnaissance :
- elle est indexée.
- en Firestore l'index est `collection_group` afin de rendre un sponsorings accessible par index sans connaître son _parent_ le sponsor.

## `v` : version d'un document. Tous sauf `syntheses`
Tous les documents sont _versionnés_,
- `syntheses` : `v` est une date-heure et n'a qu'un rôle informatif (ces documents ne sont pas synchronisés en sessions UI).
- **tous les autres documents ont un version de 1..n**, incrémentée de 1 à chaque mise à jour de son document, et pour `versions` de leurs sous-collections.

### `dlv` d'un compte: `comptas`
La `dlv` **d'un compte** désigne le dernier jour de validité du compte:
- c'est le **dernier jour d'un mois**.
- _**cas particulier**_: quand c'est le premier jour d'un mois, la `dlv` réelle est le dernier jour du mois précédent. Dans ce cas elle représente la date de fin de validité fixée par l'administrateur pour l'ensemble des comptes "O". En gros il a un financement des frais d'hébergement pour les comptes de l'organisation jusqu'à cette date (par défaut la fin du siècle).

La `dlv` d'un compte est inscrite dans la `comptas` du compte:
- la propriété est externalisée afin de permettre au GC de récupérer tous les comptes obsolètes à détruire.

## `dlv` : d'un `sponsorings` 
- jour au-delà duquel le sponsoring n'est plus applicable ni pertinent à conserver. Les sessions suppriment automatiquement à la connexion les sponsorings ayant dépassé leur `dlv` (idem pour les synchronisations).
- il y a des sponsorings avec une `dlv` dans le futur.
- dès dépassement du jour de `dlv`, un sponsorings est purgé (du moins peut l'être).

**Les `dlv` sont des propriétés indexées** afin de permettre au GC de les purger. En Firestore l'index est `collection_group` afin de s'appliquer aux sponsorings de tous les avatars.

### `vcv` : version de la carte de visite. `avatars chats membres`
Cette propriété est la version `v` du document au moment de la dernière mise à jour de la carte de visite. `vcv` est définie pour `avatars chats membres` seulement et elle est indexée.

### `dfh` : date de fin d'hébergement. `groupes`
La **date de fin d'hébergement** sur un groupe permet de détecter le jour où le groupe sera considéré comme disparu. A dépassement de la `dfh` d'un groupe, le GC fait disparaître le groupe inscrivant une `suppr` du jour dans son document `versions` et une version v à 999999 dans le document `groupes`.

### `hpc` : hash de la phrase de contact. `avatars`
Cette propriété de `avatars` est indexée de manière à pouvoir accéder à un avatar en connaissant sa phrase de contact.

### `hps1` : hash d'un extrait de la phrase secrète. `comptas`
Cette propriété de `comptas` est indexée de manière à pouvoir accéder à un compte en connaissant le `hps1` issu de sa phrase secrète.

### Propriétés techniques composites `id_v id_vcv`
**En Firestore** les documents des collections _majeures_ `partitions comptas avatars groupes versions` ont un ou deux attributs _techniques composites_ calculés et NON présents en _data_:
- `id_v` : un string `id/v` ou `id` est l'id sur 16 chiffres et `v` la version du document sur 9 chiffres.
- `id_vcv` pour les documents `avatars` seulement: un string `id/vcv` ou `id` est l'id sur 16 chiffres et `vcv` la version de la carte de visite de l'avatar sur 9 chiffres.

### Propriété `v` de `transferts`
Elle permet au GC de détecter les transferts en échec et de nettoyer le _storage_.
- en Firestore l'index est `collection_group` afin de s'appliquer aux fichiers des notes de tous les avatars et groupe.

# Cache locale des `espaces partitions comptas avatars groupes versions` dans un serveur
Un _serveur_ ou une _Cloud Function_ qui ne se différencient que par leur durée de vie _up_. 
- les `comptas` sont utilisées à chaque changement de volume ou du nombre de notes / chats / participations aux groupes.
- les `versions` sont utilisées à chaque mise à jour des avatars, de ses chats, notes, sponsorings.
- les `avatars groupes partitions` sont également souvent accédés.

**Les conserver en cache** par leur `id` est une solution naturelle: mais il peut y avoir plusieurs instances s'exécutant en parallèle. 
- Il faut en conséquence interroger la base pour savoir s'il y a une version postérieure et ne pas la charger si ce n'est pas le cas en utilisant un filtrage par `v`. 
- Ce filtrage se faisant sur l'index n'est pas décompté comme une lecture de document quand le document n'a pas été trouvé parce que de version déjà connue.
- En Firestore l'attribut calculé `id_v` permet d'effectuer ce filtrage (alors qu'en SQL l'index composé id / v est utilisable).

La mémoire cache est gérée par LRU (tous types de documents confondus) afin de limiter sa taille en mémoire.

# Clés et identifiants
## Le hash PBKFD
Son résultat fait 32 bytes. Long à calculer, son algorithme ne le rend pas susceptible d'être accéléré pae usage de CPU graphique. Il est considéré comme incassable par force brute.

## Les clés AES
Ce sont des bytes de longueur 32. Un texte crypté a une longueur variable :
- quand le cryptage est spécifié _libre_ le premier byte du texte crypté est le numéro du _salt_ choisi au hasard dans une liste pré-compilée : un texte donné 'AAA' ne donnera donc pas le même texte crypté à chaque fois ce qui empêche de pouvoir tester l'égalité de deux textes cryptés au vu de leurs valeurs cryptées.
- quand le cryptage est _fixe_ le numéro de _salt_ est 1 : l'égalité de valeurs cryptées traduit l'égalité de leur valeurs sources.

## Un entier sur 53 bits est intègre en Javascript
Le maximum 9,007,199,254,740,991 fait 16 chiffres décimaux si le premier n'est pas 9. Il peut être issu de 6 bytes aléatoires.

Le hash (_integer_) de N bytes est un entier intègre en Javascript.

Le hash (_integer_) d'un string est un entier intègre en Javascript.

## Dates et date-heures
Les date-heures sont exprimées en millisecondes depuis le 1/1/1970, un entier intègre en Javascript (ce serait d'ailleurs aussi le cas pour une date-heure en micro-seconde).

Les dates sont exprimées en `aaaammjj` sur un entier (géré par la class `AMJ`). En base ce sont des dates UTC, elles peuvent s'afficher en date _locale_.

## Clé RSA d'un avatar
La clé de cryptage (publique) et celle de décryptage (privée) sont de longueurs différentes. 

Le résultat d'un cryptage a une longueur fixe de 256 bytes. Deux cryptages RSA avec la même clé d'un même texte donnent deux valeurs cryptées différentes.

## Clé d'un avatar ou d'un groupe
Ces 32 bytes aléatoires sont la clé de cryptage de leur carte de visite:
- Le premier byte donne le _type_ de l'id, qu'on retrouve comme troisième chiffre de l'id :
  - 4 : avatar.
  - 5 : groupe,
- Les autres bytes sont aléatoires.

## Clé d'une partition
Elle a 32 bytes:
- byte 0 : 2.
- bytes 1 et 2 : numéro de la partition, numéro d'ordre de sa déclaration par le Comptable dans l'espace.
- autres bytes aléatoires.

> Depuis la _clé_ d'une partition, d'un avatar ou d'un groupe, une fonction simple retourne son `id` courte (sans `ns`).

> Une id **courte** est une id SANS les deux premiers chiffres de l'espace, donc relative à son espace.

## `rds` : _référence data sync_
C'est un id sur 16 chiffres:
- les deux premiers sont le `ns`,
- le troisième indique si c'est une référence,
  - 1 d'un espace
  - 2 d'une partition
  - 3 d'un compte
  - 4 d'un avatar
  - 5 d'un groupe.
- les 13 derniers chiffres sont aléatoires.

> Remarque: on trouve une propriété `rds`, **jamais indexée** donc toujours cryptée dans un _data_ dans les documents: `espaces partitions comptas avatars groupes`.

# Authentification

## L'administrateur technique
Il a une phrase de connexion dont le SHA de son PBKFD (`shax`) est enregistré dans la configuration d'installation. 
- Il n'a pas d'id, ce n'est PAS un compte.
- Une opération de l'administrateur est repérée parce que son _token_ contient son `shax`.

**Les opérations liées aux créations de compte ne sont pas authentifiées**, elles vont justement enregistrer leur authentification.  
- Les opérations de GC et celles de type _ping_ ne le sont pas non plus.  
- Toutes les autres opérations le sont.

## `sessionId`: dans le cas d'un serveur gérant le Data Sync par WebSocket 
`sessionId` est tirée au sort par la session juste avant tentative de connexion: elle est supprimée à la déconnexion. Elle est un identifiant des _sessions_ gérées par WebSocket.
- elle n'existe pas pour un serveur gérant une base **NOSQL-Data Sync**,
- elle n'existe pas pour une _Cloud Function_ au lieu d'un serveur.

## Token
Toute opération ayant à identifier son émetteur porte un `token` sérialisation encodée en base 64 de :
- `sessionId`, le cas échéant.
- Pour l'administrateur technique:
  - `shax` : SHA du PBKFD de sa phrase secrète.
- Pour un compte:
  - `org` : le code l'organisation qui permet au serveur de retrouver le `ns` associé.
  - `hps1` : hash (sur 14 chiffres) du PBKFD d'un extrait de la phrase secrète.
  - `hpsc` : hash (sur 14 chiffres) du PBKFD de la phrase secrète complète.

Le serveur recherche l'`id` du compte par `ns + hps1` (index de `comptas`)
- vérifie que `ns + hps1` est bien celui enregistré (indexé) dans `comptas` en `hps1`. Le `ns` sur les deux chiffres de tête permet de maintenir un partitionnement stricte entre espaces.
- vérifie que `hpsc` est bien celui enregistré dans `comptas`.
- s'il y a une `sessionId` le notifie au gestionnaire de WebSocket à titre de _heartbeat_ indiquant que la session est active.

# _Textes_ humainement interprétables
**Les photos des cartes de visites sont assimilées par la suite par simplification à des _textes_.**

Ces textes humainement interprétables sont toujours cryptés par des clés qu'un compte obtient,
- indirectement par sa clé K cryptée par sa phrase secrète,
- par des _contacts_ qui lui ont communiqué leur clé de carte de visite (contacts directs ou membre d'un groupe).
- par la clé d'un groupe dont la clé a été transmise lors de l'invitation.

On les trouvent en propriétés:
- `texte` **d'une carte de visite**: le début de la _première ligne_ donne un _nom_, le reste est un complément d'information.
- `apropos`, commentaire personnel d'un compte attaché à un avatar contact (chat ou membre d'un groupe) ou à un groupe.
- `texte` d'une note personnelle ou d'un groupe.
- `hashtags` liste de textes attachés par un compte à,
  - un avatar contact (chat ou membre d'un groupe),
  - un groupe dont il est ou a été membre ou au moins invité,
  - un note, personnelle ou d'un des groupes où il est actif et a accès aux notes.

Les textes sont gzippés ou non avant cryptage: c'est automatique dès que le texte a une certaine longueur (de fait les hashtags ne sont pas gzippés).

> **Remarque:** Le serveur ne voit **jamais en clair**, aucun texte, ni aucune clé susceptible de crypter un texte, ni la clé K des comptes, ni les _phrase secrètes_ ou _phrases de contacts / sponsorings_.

> Les textes sont cryptés / décryptés par une application UI. Si celle-ci est malicieuse / boguée, les textes sont illisibles mais finalement pas plus que ceux qu'un utilisateur qui les écrirait en idéogrammes pour un public occidental ou qui inscrirait  des textes absurdes.

# Sous-objet `notification`
Un objet _notification_ est immuable car en cas de _mise à jour_ il est en fait remplacé par un autre.

Type des notifications:
- 0 : de l'espace
- 1 : d'une partition
- 2 : d'un compte
- 3 : dépassement de quotas
- 4 : alerte de solde / consommation

Une notification a les propriétés suivantes:
- `nr`: restriction d'accès: 
  - 0 : pas de restriction
  - 1 : espace figé
  - 2 : espace clos
  - 3 : accès en lecture seule
  - 4 : accès minimal
  - 5 : actions accroissant le volume interdites.
- `dh` : date-heure de création.
- `texte`: 
  - le texte est en clair pour le type 0.
  - le texte de la notification est crypté pour les types 2 et 3 par la clé de la partition.
  - il n'y a pas de texte (juste un code en clair à la place) pour les types 3 et 4.

- `idSource`: id du délégué ayant créé cette notification pour un type 3.

**Remarque:** une notification `{ dh: ... }` correspond à la suppression de la notification antérieure (ni restriction, ni texte).

Un _dépassement de quotas Q1 / Q2_ entraîne une restriction (5).

Un _solde négatif (compte A)_ ou _une consommation excessive (compte O)_ entraîne une restriction (4). 

> Le document `comptas` a une date-heure de lecture `dhvu` qui indique _quand_ le titulaire du compte a lu les notifications. Une icône peut ainsi signaler l'existence d'une _nouvelle_ notification, i.e. une notification qui n'a pas été lue.

# Sous-objet carte de visite
Une carte de visite a 3 propriétés `{ vcv, photo, texte }`:
- `vcv`: version de la carte de visite, version du groupe ou de l'avatar au moment de sa dernière mise à jour.
- `photo`: photo cryptée par la clé de l'avatar ou groupe propriétaire.
- `texte`: texte (gzippé) crypté par la clé de l'avatar ou groupe propriétaire.

`nom` : il correspond aux 16 premiers caractères de la première ligne du texte. Ce nom est affiché partout ou l'avatar / groupe apparaît, suivi des 4 derniers chiffres de son id.

Les cartes de visite des avatars sont hébergés dans le document `avatars`, celles des groupes dans leurs documents `groupes`.

Les cartes de visites des avatars sont dédoublées dans d'autres documents:
- `membres` : chaque membre y dispose sa carte de visite.
- `chats` : chaque interlocuteur dispose de la carte de visite de l'autre.

## Mises à jour des cartes de visite des membres
- la première inscription se fait à l'ajout de l'avatar comme _contact_ du groupe.
- le rafraîchissement peut être demandé pour un groupe donné.
  - pour chaque membre, l'opération compare la version détenue dans le membre et la version détenue dans l'avatar. Cette vérification ne fait intervenir que des filtres sur les index si la version dans membre est à jour.
  - si la version de membre n'est pas à jour, elle est mise à jour. 
- en session, lorsque la page listant les membres d'un groupe est ouverte, elle peut envoyer une requête de rafraîchissement des cartes de visite.

### Mise à jour dans les chats
- à la mise à jour d'un chat, les cartes de visites des deux côtés sont rafraîchies si nécessaire.
- le rafraîchissement peut être demandé pour tous les chats d'un avatar donné.
  - pour chaque chat, l'opération compare la version détenue dans le chat et la version détenue dans l'avatar. Cette vérification ne fait intervenir que des filtres sur les index si la version dans chat est à jour.
  - si la version dans chat n'est pas à jour, elle est mise à jour. 
- en session, lorsque la page listant les chats d'un avatar est ouverte, elle peut envoyer une requête de rafraîchissement des cartes de visite.

# Documents `espaces`
_data_ :
- `id` : de l'espace de 10 à 89.
- `v` : 1..N
- `org` : code de l'organisation propriétaire.

- `rds` :
- `opt`:
  - 0: 'Pas de comptes "autonomes"',
  - 1: 'Le Comptable peut rendre un compte "autonome" sans son accord',
  - 2: 'Le Comptable NE peut PAS rendre un compte "autonome" sans son accord',
- `dlvat` : `dlv` de l'administrateur technique.
- `nbmi`: nombre de mois d'inactivité acceptable pour un compte O fixé par le comptable. Ce changement n'a pas d'effet rétroactif.
- `notif` : notification de l'administrateur. Texte crypté par la clé du Comptable.
- `t` : numéro de _profil_ de quotas dans la table des profils définis dans la configuration. Chaque profil donne un triplet de quotas `qc q1 q2` qui serviront de guide pour le Comptable qui s'efforcera de ne pas en distribuer d'avantage sans se concerter avec l'administrateur technique.

L'administrateur technique gère une `dlvat` pour l'espace : 
- c'est la date à laquelle l'organisation l'administrateur technique détruira les comptes "O". Cette information est disponible dans l'état de la session pour les comptes "O" (les comptes "A" n'étant pas intéressés).
- l'administrateur ne peut pas (re)positionner une `dlvat` à moins de `nbmi` mois du jour courant afin d'éviter les catastrophes de comptes supprimés sans que leur titulaire n'ait eu le temps de se reconnecter.
- par défaut, à l'initialisation elle vaut la fin du siècle.

L'opération de mise à jour d'une `dlvat` est une opération longue du fait du repositionnement des `dlv` des comptas égales à la `dlvat` remplacée:
- cette mise à jour porte sur le document `comptas` (et son document `versions` associé).
- elle s'effectue en N opérations enchaînées. Au pire en cas d'incident en cours, une partie des comptes auront leur `dlv` mises à jour et pas d'autres: l'administrateur technique doit manuellement relancer l'opération en surveillant sa bonne exécution complète.

**Le maintien en vie d'un compte "O" en l'absence de connexion** a le double inconvénient, 
- d'immobiliser des ressources peut-être pour rien,
- d'augmenter les coûts d'avance sur les frais d'hébergement.

Le Comptable fixe en conséquence un `nbmi` (de 3, 6, 12, 18, 24 mois) compatible avec ses contraintes mais évitant de contraindre les comptes à des connexion inutiles rien que pour maintenir le compte en vie, et surtout à éviter qu'ils n'oublient de le faire et voir leurs comptes automatiquement résiliés après un délai trop bref de non utilisation.

# Documents `partitions`
_data_:
- `id` : numéro d'ordre de création de la tribu par le Comptable.
- `v` : 1..N

- `rds` :
- `clepX` : clé de la partition cryptée par la clé K du comptable.
- `qc q1 q2` : quotas totaux de la tribu.
- `stn` : restriction d'accès de la notification _partition_: _0:aucune 1:lecture seule 2:minimal_
- `notifP`: notification de niveau _partition_ dont le texte est crypté par la clé de la partition.
- `tc` : table des comptes attachés à la partition. L'index `it` dans cette table figure dans la propriété `it` du `comptas` correspondant :
  - `idP` : id court du compte crypté par la clé de la partition.
  - `cledP` : si _délégué_, `cle` du compte délégué crypté par la cle de la partition.
  - `notifP`: notification de niveau compte dont le texte est crypté par la clé de la partition (`null` s'il n'y en a pas).
  - `stn` : restriction d'accès de la notification _compte_: _0:aucune 1:lecture seule 2:minimal_
  - `qc q1 q2` : quotas attribués.
  - `cj v1 v2` : consommation journalière, v1, v2: obtenus de `comptas` lors de la dernière connexion du compte, s'ils ont changé de plus de 10%. **Ce n'est donc pas un suivi en temps réel** qui imposerait une charge importante de mise à jour de `partitions / syntheses` à chaque mise à jour d'un compteur de `comptas` et des charges de synchronisation conséquente.

Un délégué (ou le Comptable) peut accéder à la liste des comptes de sa partition : pour un compte non délégué il n'a pas accès à leur carte de visite (sauf si l'avatar lui est connu par ailleurs).

Tout compte "O" a accès à sa partition: il n'a accès aux cartes de visite que des délégués.

L'ajout / retrait de la qualité de _délégué_ n'est effectué que par le Comptable au delà du choix initial établi au sponsoring par un _délégué_ ou le Comptable.

## Gestion des quotas totaux par _partitions_
La déclaration d'une partition par le Comptable d'un espace consiste à définir :
- une clé de cryptage `clep` générée aléatoirement à la création de la partition :
  - **les 2 premiers bytes donnent l'id de la partition**, son numéro d'ordre de création par le Comptable partant de de 1,
- un `code` signifiant pour le Comptable (dans son `comptas`).
- les sous-quotas `qc q1 q2` attribués.

`clep` est immuable, `code qc q1 q2` peuvent être mis à jour par le comptable.

# Documents `syntheses`
La mise à jour d'une partition est peu fréquente : une _synthèse_ est recalculée à chaque mise à jour de `stn, q1, q2` ou d'un item de `act`.

_data_:
- `id` : id de l'espace.
- `v` : date-heure d'écriture (purement informative).

- `tp` : table des synthèses des partitions de l'espace. L'indice dans cette table est l'id court de la partition. Chaque élément est la sérialisation de:
  - `qc q1 q2` : quotas de la partition.
  - `ac a1 a2` : sommes des quotas attribués aux comptes attachés à la partition.
  - `ca v1 v2` : somme des consommations journalières et des volumes effectivement utilisés.
  - `ntr0` : nombre de notifications partition sans restriction d'accès.
  - `ntr1` : nombre de notifications partition avec restriction d'accès _lecture seule_.
  - `ntr2` : nombre de notifications partition avec restriction d'accès _minimal_.
  - `nbc` : nombre de comptes.
  - `nbsp` : nombre de comptes _délégués_.
  - `nco0` : nombres de comptes ayant une notification sans restriction d'accès.
  - `nco1` : nombres de comptes ayant une notification avec restriction d'accès _lecture seule_.
  - `nco2` : nombres de comptes ayant une notification avec restriction d'accès _minimal_.

`ap[0]` est la somme des `ap[1..N]` calculé en session, pas stocké.

# Documents `comptas`
_data_ :
- `id` : numéro du compte, id de son avatar principal.
- `v` : 1..N.
- `hps1` : `ns` + hash du PBKFD d'un extrait de la phrase secrète (`hps1`).
- `dlv` : dernier jour de validité du compte.

- `rds` : 
- `hpsc`: hash du PBKFD de la phrase secrète complète (sans son `ns`).
- `kx` : clé K du compte, cryptée par le PBKFD de la phrase secrète complète.
- `dhvu` : date-heure de dernière vue des notifications par le titulaire du compte, cryptée par la clé K.
- `delegue` : 1: est _délégué_ de sa tribu.
- `clepK` : clé de la partition cryptée par la clé K du compte. Dans le cas de changement de partition forcé par le comptable, cette clé a une longueur de 256, elle est cryptée par la _clé publique RSA_ du compte.
- `it` : index du compte dans la table `ac` de sa partition. **0 si c'est un compte autonome**.
- `qv` : `{qc, q1, q2, nn, nc, ng, v2}`: quotas et nombre de groupes, chats, notes, volume fichiers. Valeurs courantes.

- `total`: pour un compte "A" seulement , total est le résultat, 
  - du cumul des crédits reçus depuis le début de la vie du compte (ou de son dernier passage en compte A), 
  - plus les dons reçus des autres,
  - moins les dons faits aux autres.
- `tickets`: pour un compte "A" seulement, liste des tickets cryptée par la clé K du compte `{ids, v, dg, dr, ma, mc, refa, refc, di}`.
  - juste après une conversion de compte "O" en "A", `credits` est vide.
- `compteurs` sérialisation non cryptée des quotas, volumes et coûts.

**Pour le Comptable seulement**
- `tp` : table des partitions : `{cik, qc, q1, q2}`.
  - `cik` : `{ clep, code }` crypté par la clé K du comptable
    - `clep` : clé de la partition.
    - `code` : texte très court pour le seul usage du comptable.
  - `q` : `[qc, q1, q2]` : quotas globaux de la partition.
  - `stn` : restriction d'accès.

La première partition d'`id` 1 est celle du Comptable et est indestructible.

**Remarques :**  
- Le document est mis à jour à minima à chaque mise à jour d'une note (`qv` et `compteurs`).
- La version `v` de `versions` associée à `comptas` lui est spécifique, ce n'est **PAS** la version de l'avatar principal du compte.
- Le fait d'accéder à `tp` permet d'obtenir la _liste des partitions existantes_ de l'espace. Le serveur peut ainsi recalculer la statistique de l'espace (agrégation des compteurs des partitions) en scannant ces partitions.

# Documents `versions`
_data_ :
- `id` : `rds` du document référencé.
- `v` : 1..N, plus haute version attribuée au document et à ses sous-documents.
- `suppr` : jour de suppression, ou 0 s'il est actif.

# Documents `avatars`
_data_:
- `id` : id de l'avatar.
- `v` : 1..N. Par convention, une version à 999999 désigne un **avatar logiquement détruit** mais dont les données sont encore présentes. L'avatar est _en cours de suppression_.
- `vcv` : version de la carte de visite afin qu'une opération puisse détecter (sans lire le document) si la carte de visite est plus récente que celle qu'il connaît.
- `hpc` : `ns` + hash du PBKFD d'un extrait de la phrase de contact.

**Données n'existant que pour un avatar principal**
- `mav` : map des avatars du compte. 
  - _clé_ : id court de l'avatar.
  - _valeur_ : `clé` de l'avatar crypté par la clé K du compte.

- `mpg` : map des participations aux groupes:
  - _clé_ : id du groupe
  - _valeur_: `{ clegK, lp }`
    - `clegK` : clé du groupe cryptée par la clé K du compte.
    - `lp`: map des participations: 
      - _clé_: id court de l'avatar.
      - _valeur_: indice `im` du membre dans la table `tmb` du groupe (`ids` du membre).

- `apropos` : map à propos des contacts (des avatars) et des groupes _connus_ du compte:
  - _cle_: `id` court de l'avatar ou du groupe,
  - _valeur_ : `{ hashtags, texte }` crypté par la clé K du compte.
    - `hashtags` : liste des hashtags attribués par le compte.
    - `texte` : commentaire écrit par le compte.

**Données disponibles pour tous les avatars**
- `rds` : 
- `pub` : clé publique RSA.
- `privk`: clé privée RSA cryptée par la clé K.
- `cva` : carte de visite de l'avatar `{v, photo, texte}`.
- `pck` : PBKFD de la phrase de contact crypté par la clé K (s'il y en a une).
- `clec` : `cle` de l'avatar cryptée par le PBKFD de la phrase de contact.

- `invits`: map des invitations en cours de l'avatar:
  - _clé_: `idav/idg` id de l'avatar invité / id du groupe.
  - _valeur_: `{clegP, cvg, im, ivpar, dh}` 
    - `clegP`: clé du groupe crypté par la clé publique RSA de l'avatar.
    - `cvg` : carte de visite du groupe (photo et texte sont cryptés par la clé du groupe `cleg`)
    - `im`: indice du membre dans la table `tmb` du groupe.
    - `ivpar` : indice `im` de l'invitant.
    - `dh` : date-heure d'invitation. Le couple `[ivpar, dh]` permet de retrouver l'item dans le chat du groupe donnant le message de bienvenue / invitation émis par l'invitant.

## Résiliation d'un avatar
Elle est effectuée en deux phases:
- **une transaction courte immédiate:**
  - marque du document `versions` d'id `rds` de l'avatar à _supprimé_ (`suppr` porte la date du jour).
  - marque la version `v` de l'avatar à 999999.
  - purge de ses documents `sponsorings`.
  - dès lors l'avatar est logiquement supprimé.
- **une _chaîne_ de transactions différées:**
  - une pour chaque chat de l'avatar: mise à jour de l'exemplaire de l'autre et purge du sien.
  - une pour chaque groupe auquel l'avatar participe:
    - mise à jour de la table `tmb`.
    - purge du document `membres`.
    - si le groupe n'a plus de membres actifs, le groupe est _logiquement détruit_:
      - marque du document `versions` d'id `rds` du groupe à _supprimé_ (`suppr` porte la date du jour).
      - marque la version `v` du groupe à 999999.
  - quand toutes ses transactions sont terminées, purge du document avatars.

La reprise de la chaîne des transactions différées est assurée par le GC, du moins bien entendu pour celles qui ne sont pas allés jusqu'au bout.

## Suppression d'un groupe
Elle intervient quand le groupe n'a plus de membres _actifs_.

C'est une chaîne de transactions différées:
- une pour chaque invitation en cours: mise à jour de l'avatar correspondant.
- purge des documents `membres notes chatgrs`.
- enfin une finale purgeant le document `groupes` lui-même.

La reprise de la chaîne des transactions différées est assurée par le GC, du moins bien entendu pour celles qui ne sont pas allés jusqu'au bout.

## Résiliation d'un compte
En une transaction la résiliation immédiate des avatars du compte est effectuée, ce qui lance une chaîne longue de transactions différées.

# Documents `tickets`
Ce sont des sous-documents de `avatars` qui n'existent **que** pour l'avatar principal du Comptable.

Il y a un document `tickets` par ticket de crédit généré par un compte "A" annonçant l'arrivée d'un paiement correspondant. Chaque ticket est dédoublé:
- un exemplaire dans la sous-collection `tickets` du Comptable,
- un exemplaire dans le document `comptas` du compte, dans la liste `tickets` cryptée par la clé K du compte A `{ids, dg, dr, ma, mc, refa, refc, di }`.

_data_:
- `id`: id du Comptable.
- `ids` : numéro du ticket
- `v` : version du ticket.

- `dg` : date de génération.
- `dr`: date de réception. Si 0 le ticket est _en attente_.
- `ma`: montant déclaré émis par le compte A.
- `mc` : montant déclaré reçu par le Comptable.
- `refa` : code court (32c) facultatif du compte A à l'émission.
- `refc` : code court (32c) facultatif du Comptable à la réception.
- `di`: date d'incorporation du crédit par le compte A dans son solde.

## Cycle de vie
#### Génération d'un ticket (annonce de paiement) par le compte A
- le compte A déclare,
  - un montant `ma` celui qu'il affirme avoir payé / viré.
  - une référence `refa` textuelle libre facultative à un dossier de _litige_, typiquement un _avoir_ correspondant à une erreur d'enregistrement antérieure.
- le ticket est généré et enregistré en deux exemplaires.

#### Effacement d'un de ses tickets par le compte A
En cas d'erreur, un ticket peut être effacé par son émetteur, _à condition_ d'être toujours _en attente_ (ne pas avoir de date de réception). Le ticket est physiquement effacé de `tickets` et de la liste `comptas.tickets`.

#### Réception d'un paiement par le Comptable
- le Comptable ne peut _que_ compléter un ticket _en attente_ (pas de date de réception) **dans le mois d'émission du ticket ou les deux précédents**. Au delà le ticket est _auto-détruit_.
- sur le ticket correspondant le Comptable peut remplir:
  - le montant `mc` du paiement reçu, sauf indication contraire par défaut égal au montant `ma`.
  - une référence textuelle libre `refc` justifiant une différence entre `ma` et `mc`. Ce peut être un numéro de dossier de _litige_ qui pourra être repris ensuite entre le compte A et le Comptable.
- la date de réception `dr` est inscrite, le ticket est _réceptionné_.
- le ticket est mis à jour dans `tickets` mais PAS dans la liste `comptas.tickets` du compte A: **le Comptable n'a PAS l'id du compte A** (sans parler de sa clé K).

#### Lorsque le compte A va sur sa page de gestion de ses crédits
- les tickets dont il possède une version plus ancienne que celle détenue dans `tickets` du Comptable sont mis à jour.
- les tickets émis un mois M toujours non réceptionnés avant la fin de M+2 sont supprimés.
- les tickets de plus de 2 ans sont supprimés. 

#### Incorporation du crédit dans le solde du compte A
- l'opération est automatique à la prochaine connexion du compte A postérieure à une _réception de paiement_. En cours de session, un bouton permet d'activer cette incorporation sans attendre la prochaine connexion.
- elle consiste à intégrer au solde du compte le montant d'un ticket _réceptionné_ (mais pas encore _incorporé au solde_)
- le plus faible des deux montants `ma` et `mc` est incorporé au solde de `comptas.credits`. En cas de différence de montants, une alerte s'affiche.
- la date d'incorporation `di` est mise à jour dans l'exemplaire du compte mais PAS par dans `tickets` du Comptable (qui donc ignore la propriété `di`).

**Remarques:**
- de facto dans `tickets` un document ne peut avoir qu'au plus deux versions.
- la version de création qui créé le ticket et lui donne son identifiant secondaire et inscrit les propriétés `ma` et éventuellement `refa` désormais immuables.
- la version de réception par le Comptable qui inscrit les propriétés `dr mc` et éventuellement `refc`. Le ticket devient immuable dans `tickets`.
- les propriétés sont toutes immuables.
- la mise à jour ultime qui inscrit `di` à titre documentaire ne concerne que l'exemplaire du compte.

#### Listes disponibles en session
Un compte "A" dispose de la liste de ses tickets sur une période de 2 ans, quelque soit leur statut, y compris ceux obsolètes parce que non réceptionnés avant fin M+2 de leur génération.

Le Comptable dispose en session de la liste des tickets détenus dans tickets. Cette liste est _synchronisée_ (comme pour tous les sous-documents).

#### Arrêtés mensuels
Le GC effectue des arrêtés mensuels consultables par le Comptable et l'administrateur technique. Chaque arrêté mensuel,
- récupère tous les tickets générés à M-3 et les efface de la liste `tickets`,
- les stocke dans un _fichier_ **CSV** crypté dans le fichier `T_202407` du Comptable. Ces fichiers:
  - ont une clé de cryptage propre aléatoire;
  - cette clé est cryptée deux fois:
    - par la clé publique du Comptable (qui peut donc l'obtenir par sa clé privée),
    - par la clé du site de l'administrateur technique.

Pour rechercher un ticket particulier, par exemple pour traiter un _litige_ ou vérifier s'il a bien été réceptionné, le Comptable,
- dispose de l'information en ligne pour tout ticket de M M-1 M-2,
- dans le cas contraire, ouvre l'arrêté mensuel correspondant au mois du ticket cherché qui est un fichier CSV basique.

#### Numérotation des tickets
L'ids d'un ticket est un entier de la forme : `aammrrrrrrrrrr`
- `aa` : année de génération,
- `mm` : mois de génération,
- `r...r` : aléatoire.

Un code à 6 lettres majuscules en est extrait afin de le joindre comme référence de _paiement_.
- la première lettre  donne le mois de génération du ticket : A-L pour les mois de janvier à décembre si l'année est paire et M-X pour les mois de janvier à décembre si l'année est impaire.
- les autres lettres correspondent à `r...r`.

Le Comptable sait ainsi dans quel _arrêté mensuel_ il doit chercher un ticket au delà de M+2 de sa date de génération à partir d'un code à 6 lettres désigné par un compte pour audit éventuel de l'enregistrement.

> **Personne, pas même le Comptable,** ne peut savoir quel compte "A" a généré quel ticket. Cette information n'est accessible qu'au compte lui-même et est cryptée par sa clé K.

# Documents `chats`
Un chat est une suite d'items de texte communs à deux avatars I et E:
- vis à vis d'une session :
  - I est l'avatar _interne_,
  - E est un avatar _externe_ connu comme _contact_.
- un item est défini par :
  - le côté qui l'a écrit (I ou E),
  - sa date-heure d'écriture qui l'identifie pour son côté,
  - son texte crypté par une clé de cryptage du chat connue seulement par I et E.

Un chat est dédoublé avec un exemplaire I et un exemplaire E:
- à son écriture, un item est ajouté des deux côtés.
- le texte d'un item écrit par I peut être effacé par I des deux côtés (mais pas modifié).
- I (resp. E) **peut effacer tous les items** I comme E de son côté: ceci n'impacte pas l'existence de ceux de l'autre côté.
- _de chaque côté_ la taille totale des textes de tous les items est limitée à 5000c. Les plus anciens items sont effacés afin de respecter cette limite.

Pour ajouter un item sur un chat, I doit connaître la clé de E : membre d'un même groupe, chat avec un autre avatar du compte, ou l'ayant obtenu depuis la phrase de contact de E.

## Clé d'un chat
La clé du chat `cc` est générée à la création du chat et l'ajout du premier item:
- côté I, cryptée par la clé K de I,
- côté E, cryptée par la clé publique de E. Dans ce cas à la première écriture de E celle-ci sera ré-encryptée par la clé K de E.

## Décompte des nombres de chats par compte
- un chat est compté pour 1 pour I quand la dernière opération qu'il a effectuée est un ajout: si cette dernière opération est un _raz_, le chat est dit _passif_ et compte pour 0.
- ce principe de gestion évite de pénaliser ceux qui reçoivent des chats non sollicités et qui les _effacent_.

## Résiliation / disparition de E
Quand un avatar ou un compte s'auto-résilie ou quand le GC détecte la disparition d'un compte par dépassement de sa date limite de validité, il _résilie_ tous ses avatars, puis le compte lui-même.

A la résiliation d'un avatar,
- tous ses chats sont accédés et l'exemplaire de E l'est aussi:
- s'il était _passif_, il devient _zombi_, n'a plus de _data_.
- sinon, son statut `st` passe à 2. E conserve le dernier état de l'échange, mais,
  - il ne pourra plus le changer, la carte de visite de I reste dans le dernier état connu,
  - il ne pourra plus qu'effectuer un _raz_, ce qui rendra l'exemplaire de son chat _zombi_.

## _data_ d'un chat
L'`id` d'un exemplaire d'un chat est le couple `id, ids`.

_data_ (de l'exemplaire I):
- `id`: id de I,
- `ids`: hash de l'id courte de E.
- `v`: 1..N.
- `vcv` : version de la carte de visite de E.

- `st` : deux chiffres `I E`
  - I : 0:passif, 1:actif
  - E : 0:passif, 1:actif, 2:disparu
- `cva` : `{v, photo, info}` carte de visite de E au moment de la création / dernière mise à jour du chat.
- `cc` : clé `cc` du chat cryptée par la clé K du compte de I ou par sa clé publique quand le chat vient d'être créé par E.
- `items` : liste des items `[{a, dh, l t}]`
  - `a` : 0:écrit par I, 1: écrit par E
  - `dh` : date-heure d'écriture.
  - `dhx` : date-heure de suppression.
  - `l` : taille du texte.
  - `t` : texte crypté par la clé du chat (vide s'il a été supprimé).

## Actions possibles (par I)
- _ajout d'un item_
  - si le chat n'existait pas, 
    - il est créé avec ce premier item dans `items`.
    - le nombre de chats dans `comptas.qv.nc` est incrémenté.
    - `st` de I vaut `10` et `st` de E vaut `01`.
  - l'item apparaît dans `items` de E (son `a` est inversé).
- _effacement du texte d'un item de I_
  - le texte de l'item est effacé des deux côtés.
  - il n'est pas possible pour I d'effacer le texte d'un item écrit par E.
- _raz_ : effacement total de l'historique des items (du côté I)
  - `items` est vidée du côté I.
  - `st` de I vaut `01` et `st` de E vaut `10` ou `00`.
  - le chat est dit _passif_ du côté I et ne redeviendra _actif_ qu'au prochain ajout d'un item par I.

> Un chat _passif_ pour un avatar reste un chat _écouté_, les items écrits par E arrivent, mais sur lequel I n'écrit pas. Il redevient _actif_ pour I dès que I écrit un item et ne redevient _passif_ que quand il fait un _raz_.

## Établir un _contact direct_ entre A et B
Si B veut ouvrir un chat avec A mais ne l'a pas en _contact_, n'en connaît pas la clé. S'il en connaît la _phrase de contact_, 
- il calcule le hash de la phrase de contact réduite,
- il demande par ce hash la clé de A cryptée par le PBKFD de cette phrase.

## Comptes "A" : dons par chat
Un compte "A" _donateur_ peut faire un don à un autre compte "A" _bénéficiaire_ en utilisant un chat:
- le montant du don est dans une liste préétablie.
- le crédit total du donateur (dans sa `comptas`) doit être supérieur au montant du don.
- sauf spécification contraire du donateur, le texte de l'item ajouté dans le chat à cette occasion mentionne le montant du don.
- le donateur est immédiatement débité.
- le bénéficiaire est immédiatement crédité dans sa `comptas`.

> Remarque: le chat avec don ne peut intervenir que si le chat est défini entre les deux avatars **principaux** des comptes.

# Documents `sponsorings`
P est le parrain-sponsor, F est le filleul-sponsorisé.

_data_:
- `id` : id de l'avatar sponsor.
- `ids` : `ns` + hash du PBKFD de la phrase réduite de parrainage, 
- `v`: 1..N.
- `dlv` : date limite de validité

- `st` : statut. _0: en attente réponse, 1: refusé, 2: accepté, 3: détruit / annulé_
- `pspk` : texte de la phrase de sponsoring cryptée par la clé K du sponsor.
- `bpspk` : PBKFD de la phrase de sponsoring cryptée par la clé K du sponsor.
- `dh`: date-heure du dernier changement d'état.
- `cle` : clé du sponsor crypté par le PBKFD de la phrase de sponsoring.
- `clep` : clé de sa partition (si c'est un compte "O") cryptée par le PBKFD de la phrase de sponsoring.
- `cv` : `{ v, photo, info }` du sponsor.
- `delegue` : vrai si le sponsorisé est lui-même _délégué_.
- `quotas` : `[qc, q1, q2]` quotas attribués par le sponsor.
  - pour un compte "A" `[0, 1, 1]`. Un tel compte n'a pas de `qc` et peut changer à loisir `[q1, q2]` qui sont des protections pour lui-même (et fixe le coût de l'abonnement).
- `don` : pour un compte autonome, montant du don.
- `dconf` : le sponsor a demandé à rester confidentiel. Si oui, aucun chat ne sera créé à l'acceptation du sponsoring.
- `ardx` : ardoise de bienvenue du sponsor / réponse du filleul cryptée par le PBKFD de la phrase de sponsoring.

**Remarques**
- la `dlv` d'un sponsoring peut être modifiée tant que le statut est _en attente_.
- Le sponsor peut annuler son `sponsoring` avant acceptation, en cas de remord son statut passe à 3.

**Si le filleul refuse le sponsoring :** 
- Il écrit dans `ardx` la raison de son refus et met le statut du `sponsorings` à 1.

**Si le filleul ne fait rien à temps :** 
- `sponsorings` finit par être purgé par `dlv`.

**Si le filleul accepte le sponsoring :** 
- Le filleul crée son compte / avatar principal et génère ses clé K et celle de son avatar principal, et le texte de carte de visite.
- pour un compte "O", l'identifiant de la partition à la quelle le compte est associé est obtenu de `clep`.
- la `comptas` du filleul est créée et créditée des quotas attribués par le sponsor pour un compte "O" et d'un `total` minimum pour un compte "A".
- pour un compte "O" le document `partitions` est mis à jour (quotas attribués), le filleul est mis dans la liste des comptes `tc` de `partitions`.
- un mot de remerciement est écrit par le filleul au parrain sur `ardx` **ET** ceci est dédoublé dans un chat filleul / sponsor créé à ce moment et comportant l'item de réponse,
  - pour un compte sponsorisé "A" si le sponsor ou le sponsorisé ont requis la confidentialité, le chat n'est pas créé: rien ne reliera les deux comptes.
  - sinon le chat est créé, le sponsor d'un compte "O" a toujours ses sponsorisés "O" dans ses contacts.
- le statut du `sponsoring` est 2.

# Documents `notes`
La clé de cryptage `cles` d'une note est selon le cas :
- *note personnelle d'un avatar A* : la clé K de l'avatar.
- *note d'un groupe G* : la clé du groupe G.

Pour une note de groupe, le droit de mise à jour d'une note d'un groupe est contrôlé par `im` qui indique quel membre (son `im`) a l'exclusivité d'écriture (sinon tous).

_data_:
- `id` : id de l'avatar ou du groupe.
- `ids` : identifiant relatif à son avatar.
- `v` : 1..N.

- `im` : exclusivité dans un groupe. L'écriture est restreinte au membre du groupe dont `im` est `ids`. 
- `v2` : volume total des fichiers attachés.
- `ht` :
  - note personnelle : liste des hashtags cryptée par la clé K du compte.
  - note de groupe : liste des hashtags cryptée par la clé du groupe.
- `htm` : pour une note de groupe seulement, hashtags des membres. Map:
    - _clé_ : `hgc` du compte de l'auteur,
    - _valeur_ : liste des hashtags cryptée par la clé K du compte.
- `l` : liste des _auteurs_ (leurs `im`) pour une note de groupe.
- `d` : date-heure de dernière modification du texte.
- `texte` : texte (gzippé) crypté par la clé de la note.
- `mfas` : map des fichiers attachés.
- `refs` : triplet `[id_court, ids, nomp]` crypté par la clé de la note, référence de sa note _parent_.

!!!TODO!!! : vérifier / préciser `nomp`

**_Remarque :_** une note peut être logiquement supprimée. Afin de synchroniser cette forme particulière de mise à jour le document est conservé _zombi_ (sa _data_ est `null`). La note sera purgée un jour avec son avatar / groupe.

**`hgc` du compte de l'auteur**
- un compte génère son `hgc` par le hash de son id crypté par sa clé K. 
- de cette façon tous les avatars d'un compte bénéficient des mêmes hashtags mais les autres membres n'ont pas moyen de savoir à quel membre attribuer le `hgc` correspondant.

## Map des fichiers attachés
- _clé_ `idf`: numéro aléatoire généré à la création. L'identifiant _externe_ est `id_court` du groupe / avatar, `idf`
- _valeur_ : `{ nom, info, dh, type, gz, lg, sha }` crypté par la clé S de la note.

**Identifiant de stockage :** `org/id_court/idf`
- `org` : code de l'organisation.
- `id_court` : id _court_ de l'avatar / groupe auquel la note appartient.
- `idf` : identifiant aléatoire du fichier.

En imaginant un stockage sur file-system,
- l'application a un répertoire racine par espace portant le code de l'organisation,
- il y un répertoire par avatar / groupe ayant des notes ayant des fichiers attachés,
- pour chacun, un fichier par fichier attaché.

_Un nouveau fichier attaché_ est stocké sur support externe **avant** d'être enregistré dans son document `notes`. Ceci est noté dans un document `transferts`. 
Les fichiers créés par anticipation et non validés dans un document `notes` comme ceux qui n'y ont pas été supprimés après validation de la note, sont retrouvés par le GC.

La purge d'un avatar / groupe s'accompagne de la suppression de son _répertoire_. 

La suppression d'une note s'accompagne de la suppressions de N fichiers dans un seul _répertoire_.

## Note rattachée à une autre
Le rattachement d'une note à une autre permet de définir un arbre des notes.
- une note d'un avatar A1 peut être rattachée:
  - soit à la racine A1, en fait elle n'est pas rattachée,
  - soit à une autre note de A1,
  - soit à une note de groupe: A1 peut ainsi commenter des notes d'un groupe par des notes qu'il sera seul à voir.
- une note d'un groupe G1 ne peut être rattachée qu'à une autre note du même groupe.

Les cycles (N1 rattachée à N2 rattachée à N3 rattachée à N1 par exemple) sont détectés et bloqués.

# Documents `groupes`
Un groupe est caractérisé par :
- son entête : un document `groupes`.
- son sous-document `chatgrs` (dont `ids` est `1`).
- ses membres: des documents `membres` de sa sous-collection `membres`.

## Membres d'un groupe: `im / ids`, la table `tmb`
Un membre est créé en étant déclaré _contact_ du groupe par un animateur ce qui lui affecte un _indice membre_ de 1 à N, attribué dans l'ordre d'inscription et sans réattribution (sauf cas particulier). Pour un groupe `id`, un membre est identifié par le couple `id / ids` (où `ids` est l'indice membre `im`). Le premier membre est celui du créateur du groupe et a pour indice 1.

Les _flags_ et l'id de chaque membre d'index `im` sont stockés dans `tmb[im]` dont les éléments comportent 8 bytes:
- _flags_ : les deux premiers bytes donnent les _flags_ du membre.
- _id_ : les 6 suivants donnent son id (courte).

## États _contact / actif / inconnu_
### Inconnu
Un membre _inconnu_ est un _ex membre_ qui a eu une existence et qui :
- soit a _disparu_. Le GC a détecté son absence ou il s'est auto-résilié.
- soit a fait l'objet d'une demande _d'oubli_ par le compte lui-même et dans certains cas par un animateur.
- il a un indice `im` :
  - s'il a été _actif_, `tmb[im]` vaut `true` par convention afin de prévenir prévient la réutilisation de l'indice im.
  - s'il n'a pas été _actif_, `tmb[im]` est `null`.
- il n'a plus de sous-documents `membres`, dans le groupe on ne connaît plus, ni son nom, ni l'id de son avatar.

### Contact
Quand um membre est un _contact_:
- il a un indice `im` et des flags associés.
- il a un document `membres` identifié par `[idg, im]` qui va donner sa clé et sa carte de visite.
- il est connu dans `groupes` dans `tmb` à l'indice `im`.
- **son compte ne le connaît pas**, il n'a pas le groupe dans sa liste de groupes.

### Contact invité
Un _contact_ peut avoir une _invitation_ en cours déclarée par un animateur (ou tous):
- son avatar connaît cette invitation qui est stockée dans la map `invits` de son document `avatars`.
- une invitation n'a pas de date limite de validité.
- une invitation peut être annulée par un animateur ou l'avatar invité lui-même.

### Actif
Quand un membre est _actif_:
- son indice `im` et son document `membres` restent ceux qu'il avait quand il était _contact_.
- **son compte le connaît**, son compte a le groupe dans sa liste de groupes `mpg`,
- le compte peut décider de redevenir _contact_, voire d'être _oublié_ du groupe (et devenir _inconnu_).
- un animateur peut supprimer tous les droits d'un membre _actif_ mais il reste _actif_ (bien que très _passif_ par la force des choses).

> Remarques:
> - Un membre ne devient _actif_ que quand son compte a explicitement **validé une invitation** déclarée par un animateur (ou tous).
> - Un membre _actif_ ne redevient _contact_ que quand lui-même l'a décidé.

### `im` attribués ou libres
La règle générale est de ne pas libérer un `im` pour un futur autre membre quand un membre disparaît ou est oublié. Cet indice peut apparaître dans la liste des auteurs d'une note, la ré-attribution pourrait porter à confusion sur l'auteur d'une note.

L'exception est _libérer_ un `im` à l'occasion d'un _oubli_ ou d'une _disparition_ quand **le membre n'a jamais eu accès aux notes en écriture**: son `im` n'a pas pu être référencé dans des notes.

### Table `tmb` : _flags_
Plusieurs _flags_ précisent le statut d'un membre:
- [AC] **est _actif_**
- [IN] **a une invitation en cours**
- [AN] **a accès aux notes**: un membre _actif_ décide s'il souhaite ou non accéder aux notes (il faut qu'il en ait le _droit_): un non accès allège sa session.
- [AM] **a accès aux membres**: un membre _actif_ décide s'il souhaite ou non accéder aux autres membres (il faut qu'il en ait le _droit_): un non accès allège sa session.

- _droits_ : initialement positionnés (ou non) à l'occasion de la première invitation, ces flags n'ont d'effet que quand le membre est actif. Un animateur peut les changer.
  - [DM] **d'accès à la liste des membres**.
  - [DN] **d'accès aux notes du groupe**.
  - [DE] **d'écriture sur les notes du groupe**.
  - [PA] **d'animer le groupe**. 
  - _Remarque_: un animateur sans droit d'accès aux notes peut déclarer une invitation et être hébergeur.

- _historique_
  - [HA] **a, un jour, été actif**
  - [HN] **avec accès aux notes**
  - [HM] **avec accès aux membres**
  - [HE] **avec possibilité d'écrire une note**

- _listes noires_
  - [NG] **est en liste noire sur demande du groupe**
  - [NC] **est en liste noire sur demande du compte**

Certains avatars ne devront plus être invités / ré-invités, ils sont en liste noire. La mise en liste noire peut être demandée par un animateur du groupe ou par le membre lui-même lorsqu'il demande à être oublié.

### Un membre _peut_ avoir plusieurs périodes d'activité
- il a été créé comme _contact_ puis a été invité et son invitation validée: il est _actif_.
- il peut demander à redevenir _simple contact_ : il n'accède plus ni aux notes ni aux autres membres, n'est plus hébergeur et souhaite ne plus voir ce groupe _inutile_ apparaître dans sa liste des groupes.
- en tant que _contact_ il peut être ré-invité, sauf s'il s'est inscrit dans la liste noire des avatars à ne pas ré-inviter. Puis il peut valider son invitation et commencer ainsi une nouvelle période d'activité.
- les flags _historiques_ permettent ainsi de savoir, si le membre a un jour été actif et s'il a pu avoir accès à la liste des membres, a eu accès aux notes et a pu en écrire.

#### Réapparition après _oubli_
Après un _oubli_ si l'avatar est de nouveau inscrit comme _contact_, il récupère un nouvel indice #35 par exemple et un nouveau document `membres`, son historique de dates d'invitation, début et fin d'activité sont initialisées. 

C'est une nouvelle vie dans le groupe. Les notes écrites dans la vie antérieure mentionnent toujours l'ancien `im` #12 que rien ne permet de corréler à #35.

## Modes d'invitation
- _simple_ : dans ce mode (par défaut) un _contact_ du groupe peut-être invité par **UN** animateur (un seul suffit).
- _unanime_ : dans ce mode il faut que **TOUS** les animateurs aient validé l'invitation (le dernier ayant validé provoquant l'invitation).
- pour passer en mode _unanime_ il suffit qu'un seul animateur le demande.
- pour revenir au mode _simple_ depuis le mode _unanime_, il faut que **TOUS** les animateurs aient validé ce retour.

Une invitation est enregistrée dans la map `invits` de l'avatar invité:
- _clé_: `idav/idg` id de l'avatar invité et du groupe.
- _valeur_: `{clegP, cvg, im, ivpar, dh}` 
  - `clegP`: clé du groupe crypté par la clé publique RSA de l'avatar.
  - `cvg` : carte de visite du groupe (photo et texte sont cryptés par la clé du groupe `cleg`)
  - `im`: indice du membre dans la table `tmb` du groupe.
  - `ivpar` : indice `im` de l'invitant.
  - `dh` : date-heure d'invitation. Le couple `[ivpar, dh]` permet de retrouver l'item dans le chat du groupe donnant le message de bienvenue / invitation émis par l'invitant.

## Hébergement par un membre _actif_
L'hébergement d'un groupe est noté par :
- `imh`: indice membre de l'avatar hébergeur. 
- `idhg` : id du **compte** de l'avatar hébergeur. Cette donnée est cachée aux sessions.
- `dfh`: date de fin d'hébergement qui vaut 0 tant que le groupe est hébergé. Les notes ne peuvent plus être mises à jour _en croissance_ quand `dfh` existe.

### Prise d'hébergement
- en l'absence d'hébergeur, c'est possible pour,
  - tout animateur,
  - en l'absence d'animateur: tout actif ayant le droit d'écriture, puis tout actif ayant accès aux notes, puis tout actif.
- s'il y a déjà un hébergeur, seul un animateur peut se substituer à condition que le nombre de notes et le V2 actuels ne le mette pas en dépassement de son abonnement.

### Fin d'hébergement par l'hébergeur
- `dfh` est mise la date du jour + 90 jours.
- le nombre de notes et le volume V2 de `comptas` sont décrémentés de ceux du groupe.

Au dépassement de dfh, le GC détruit le groupe.

## Data
_data_:
- `id` : id du groupe.
- `v` :  1..N, Par convention, une version à 999999 désigne un **groupe logiquement détruit** mais dont les données sont encore présentes. Le groupe est _en cours de suppression_.
- `dfh` : date de fin d'hébergement.

- `nn qn v2 q2`: nombres de notes actuel et maximum attribué par l'hébergeur, volume tortal des fichiers des notes actuel et maximum attribué par l'hébergeur.
- `idhg` : id du compte hébergeur (pas transmise en session).
- `imh` : indice `im` du membre dont le compte est hébergeur.
- `msu` : mode _simple_ ou _unanime_.
  - `null` : mode simple.
  - `[ids]` : mode unanime : liste des indices des animateurs ayant voté pour le retour au mode simple. La liste peut être vide mais existe.
- `tmb` : table des membres.
- `cvg` : carte de visite du groupe cryptée par la clé du groupe `{v, photo, info}`.

## Décompte des participations à des groupes d'un compte
- quand un avatar a accepté une invitation, il devient _actif_ et a une nouvelle entrée dans la liste des participations aux groupes (`mpg`) dans l'avatar principal de son compte.
- quand l'avatar décide de tomber dans l'oubli ou de redevenir simple contact, cette entrée est supprimée.
- le _nombre de participations aux groupes_ dans `comptas.qv.ng` du compte est le nombre total de ces entrées dans `mpg`.

# Documents `membres`
Un document `membres` est créé à la déclaration d'un avatar comme _contact_.

Le document `membres` est détruit,
- par une opération d'oubli.
- par la destruction de son groupe lors de la résiliation du dernier membre actif.

_data_:
- `id` : id du groupe.
- `ids`: identifiant, indice `im` de membre relatif à son groupe.
- `v` : 
- `vcv` : version de la carte de visite du membre.

- `ddi` : date de l'invitation la plus récente.
- **dates de début de la première et fin de la dernière période...**
  - `dac fac` : d'activité
  - `dln fln` : d'accès en lecture aux notes.
  - `den fen` : d'accès en écriture aux notes.
  - `dam fam` : d'accès aux membres.
- `flagsiv` : flags de l'invitation en cours.
- `inv` : . Liste des indices des animateurs ayant validé la dernière invitation.
- `cle` : clé de l'avatar membre crypté par la clé du groupe.
- `cva` : carte de visite du membre `{v, photo, info}` cryptée par la clé de l'avatar membre.

## Opérations

### Inscription comme contact
- recherche de l'indice `im` dans la table `tmb` du groupe pour l'id de l'avatar.
- s'il est en liste noire, refus.
- SI `im` n'existe pas,
  - c'est une première vie OU une nouvelle vie après oubli de la précédente.
  - un nouvel indice `im` lui est attribué en séquence s'il n'y en a pas de libre.
  - un row `membres` est créé.
- SI `im` existe,
  - si son _flag_ indique qu'il est en liste noire, refus.
  - sinon il était déjà _contact_.

### Invitation par un animateur
- si son _flag_ indique qu'il est en liste noire, refus.
- choix des _droits_ et inscription dans `invits` de l'avatar.
- vote d'invitation (en mode _unanime_):
  - si tous les animateurs ont voté, inscription dans `invits` de l'avatar.
  - si le vote change les _droits_, les autres votes sont annulés.
- `ddi` est remplie.

### Annulation d'invitation par un animateur
- effacement de l'entrée de l'id du groupe dans `invits` de l'avatar.

### Oubli par un animateur*
- pour un contact, pas invité: son slot est récupérable.
- le document `membres` est détruit.
  
### Refus d'invitation par le compte
- le groupe peut avoir disparu depuis le lancement de l'invitation.
- 3 options possibles:
  - rester en contact.
  - m'oublier,
  - m'oublier et me mettre en liste noire.
- son item dans `invits` de son avatar est effacé.

### Acceptation d'invitation par le compte
- le groupe peut avoir disparu depuis le lancement de l'invitation.
- dans l'avatar principal du compte un item est ajouté dans `mpg`,
- dans `comptas` le compteur `qv.ng` est incrémenté.
- `dac fac ...` sont mises à jour.
- son item dans `invits` de son avatar est effacé.
- flags `AN AM`: accès aux notes, accès aux autres membres.

### Modification des droits par un animateur
- flags `PA DM DN DE`

### Modification des accès membres / notes par le compte
- flags `AN AM`: accès aux notes, accès aux autres membres.

## Demande d'oubli par un compte**
- 3 options:
  - rester en _contact_
  - m'oublier: Entrée dans `mpg` du compte supprimée.
  - m'oublier et me mettre en liste noir.
- si le membre était le dernier _actif_, le groupe disparaît.
- la participation au groupe disparaît de `mpg` du compte.

# Documents `Chatgrs`
A chaque groupe est associé **UN** document `Chatgrs` qui représente le chat des membres d'un groupe. Il est créé avec le groupe et disparaît avec lui.

_data_
- `id` : id du groupe
- `ids` : `1`
- `v` : sa version.

- `items` : liste ordonnée des items de chat `{im, dh, lg, texte}`
  - `im` : indice membre de l'auteur,
  - `dh` : date-heure d'enregistrement de l'item,
  - `lg` : longueur du texte en clair de l'item. 0 correspond à un item effacé.
  - `texte` : texte (gzippé) crypté par la clé du groupe.

## Opérations
### Ajout d'un item
- autorisé pour tout membre actif ayant droit d'accès aux membres.
- le texte est limité à 300 signes.

### Effacement d'un item
- autorisé pour l'auteur de l'item ou un animateur du groupe.

### Sur invitation par un animateur
- le texte d'invitation est enregistré comme item, les autres membres du groupe peuvent ainsi le voir.

### Sur acceptation ou refus d'invitation
- le texte explicatif est enregistré comme item.

Un item ne peut pas être corrigé après écriture, juste effacé.

Le chat d'un groupe garde les items dans l'ordre ante-chronologique jusqu'à concurrence d'une taille totale de 5000 signes.

# Gestion des disparitions: `dlv` des comptes

Chaque compte a une **date limite de validité**:
- toujours une _date de dernier jour du mois_ (sauf exception par convention décrite plus avant),
- dans son `comptas`.

L'objectif des dlv est de permettre au GC de libérer les ressources correspondantes (notes, chats, ...) lorsqu'un compte n'est plus utilisé:
- **pour un compte A** la `dlv` représente la limite d'épuisement de son crédit mais bornée à `nnmi` mois du jour de son calcul.
- **pour un compte O**, la `dlv` représente la plus proche de ces deux limites,
  - un nombre de jours sans connexion (donnée par `nbmi` du document `espaces` de l'organisation),
  - la date `dlvat` jusqu'à laquelle l'organisation a payé ses coûts d'hébergement à l'administrateur technique (par défaut la fin du siècle). C'est la date `dlvat` qui figure dans le document `espaces` de l'organisation. Dans ce cas, par convention, c'est la **date du premier jour du mois suivant** pour pouvoir être reconnue.

> Remarque. En toute rigueur un compte A qui aurait un gros crédit pourrait ne pas être obligé de se connecter pour prolonger la vie de son compte _oublié / tombé en désuétude / décédé_. Mais il n'est pas souhaitable de conserver des comptes _morts_ en hébergement, même payé: ils encombrent pour rien l'espace.

## Calcul de la `dlv` d'un compte
La `dlv` d'un compte est recalculée à plusieurs occasions.

### Acceptation du sponsoring du compte
Première valeur calculée selon le type du compte.

### Connexion
La connexion permet de refaire des calculs en particulier en prenant en compte de nouveaux tarifs.
- pour un compte "A" c'est à cette occasion que sont intégrés les crédits récoltés par le Comptable.
- pour un compte "O" le changement de dlvat est aussi prise en compte.

C'est l'occasion majeure de prolonger la vie d'un compte.

### Don pour un compte "A": ça passe par un chat
La dlv du _donneur_ est recalculée sur l'instant: si le don est important, la date peut être significativement rapprochée.

Pour le récipiendaire celle-ci est recalculée et prolonge cette date.

### Enregistrement d'un crédit par le Comptable
Pour le destinataire du crédit:
- s'il est connecté à cet instant dans une session, il peut appuyer sur un bouton pour rafraîchir les lignes de crédits et intégrer les nouveaux crédits.
- sinon ceci s'effectuera automatiquement à la prochaine connexion du compte.

### Modification de l'abonnement d'un compte A
La `dlv` est recalculée à l'occasion de la nouvelle évaluation qui en résulte.

### Mutation d'un compte "O" en "A" et d'un compte "A" en "O"
La `dlv` est recalculée en fonction des nouvelles conditions.

## Changement des données dans l'espace d'une organisation
Il y a deux données: 
- `dlvat`: date limite de vie des comptes O, fixée par l'administrateur technique en fonction des contributions effectives reçues de l'organisation pour héberger ses comptes O.
- `nbmi`: nombre de mois d'inactivité acceptable fixé par le Comptable (3, 6, 9, 12, 18 ou 24). Ce changement n'a pas d'effet rétroactif.

> **Remarque**: `nbmi` est fixé par configuration par le Comptable _pour chaque espace_. C'est une contrainte de délai maximum entre deux connexions à un compte, faute de quoi le compte est automatiquement supprimé. La constante `IDBOBS` fixe elle un délai maximum (2 ans par exemple), _pour un appareil et un compte_ pour bénéficier de la synchronisation incrémentale. Un compte peut se connecter toutes les semaines et avoir _un_ poste sur lequel il n'a pas ouvert une session synchronisée depuis 3 ans: bien que tout à fait vivant, si le compte se reconnecte en mode _synchronisé_ sur **ce** poste, il repartira depuis une base locale vierge, sans bénéficier d'un redémarrage incrémental.

### Changement de `dlvat`
Si le financement de l'hébergement par accord entre l'administrateur technique et le Comptable d'un espace tarde à survenir, beaucoup de comptes O ont leur existence menacée par l'approche de cette date couperet. Un accord tardif doit en conséquence avoir des effets immédiats une fois la décision actée.

Par convention une `dlvat` est fixée au **1 d'un mois** et ne peut pas être changée pour une date  inférieure à M + 3 du jour de modification.

> Remarque: quand une `dlv` apparaît en `versions d'avatars / membres` au _1 d'un mois_, c'est qu'elle est la limite de vie `dlvat` fixée pour l'espace par l'administrateur technique.

L'administrateur technique qui remplace une `dlvat` le fait en plusieurs transactions pour toutes les `dlv` des `versions d'avatars / membres` égales à l'ancienne `dlvat`. La transaction finale fixe aussi la nouvelle `dlvat`. La valeur de remplacement est,
- la nouvelle `dlvat` (au 1 d'un mois) si elle est inférieure à `auj + nbmi mois`: c'est encore la `dlvat` qui borne la vie des comptes O (à une autre borne).
- sinon la fixe à `auj + nbmi mois` (au dernier jour d'un mois), comme si les comptes s'étaient connectés aujourd'hui.

_Remarque_: idéalement une transaction unique aurait été préférable puisque toutes les dlv relatives à un compte ne vont pas être changées dans la même transaction. Ceci ouvre la possibilité d'incohérences temporelles sur les dlv pour les comptes se connectant exactement au milieu de ce processus. Il a été supposé assez rapide pour que cet inconvénient relève du cas d'école sans impact opérationnel.

# Opérations GC

## `GCHeb` - Étape _fin d'hébergement_ et _fin de vie_ des comptes
Elle récupère les groupes dont la `dfh` OU la `dlv` est passée et les supprime (voir plus avant).

## `GCfvc` - Étape _fin de vie des comptes_
Suppression de tous les comptes dont la `dlv` est inférieure à la date du jour.


### `GCGro` : Détection des groupes orphelins et suppression des membres
L'opération récupère toutes les `id / ids` des documents `membres` dont la `dlv` de la forme `aaaammjj` est inférieure au jour courant.

Une transaction par document `groupes`:
- mise à jour des statuts des membres perdus,
- suppression de ses documents `membres`,
- si le groupe n'a plus de membres actifs, suppression du groupe:
  - la `dlv` de son document `versions` est mise à la veille (il est zombi).
  - la version du document `groupes` est 999999.

### `GCPag` - Étape _purge des sous-arbres avatars et groupes_
La liste des sous-arbres à purger est donnée dans dpurges. 

Chaque id est traitée et retiré de la liste dans dpurges.

### `GCPag` : purge des avatars et des groupes
L'opération récupère toutes les `id` des documents `versions` dont la `dlv` est de la forme `aaaammjj` et antérieure à aujourd'hui.
Dans l'ordre pour chaque `id`:
- par compte, une transaction de récupération du volume (si `comptas` existe encore, sinon c'est que ça a déjà été fait),
- purge de leurs sous-collections,
- purge de leur avatar / groupe,
- purge de leurs fichiers,
- HORS TRANSACTION forçage de la `dlv` du document `versions` à `aamm` d'aujourd'hui.

**Une transaction pour chaque compte :**
- son document `comptas` :
  - est lu pour récupérer `cletX it`;
  - si c'est un compte O, un document `gcvols` est inséré avec ces données : son `id` est celle du compte.
  - les `gcvols` seront traités par la prochaine ouverture de session du comptable de l'espace ce qui supprimera l'entrée du compte dans tribu (et de facto libérera des quotas).
  - le document `comptas` est purgé afin de ne pas récupérer le volume plus d'une fois.

### `GCFpu` : traitement des documents `fpurges`
L'opération récupère tous les items d'`id` de fichiers depuis `fpurges` et déclenche une purge sur le Storage.

Les documents `fpurges` sont purgés.

### `GCTra` : traitement des transferts abandonnés
L'opération récupère toutes les documents `transferts` dont les `dlv` sont antérieures ou égales à aujourd'hui.

Le fichier `id / idf` cité dedans est purgé du Storage des fichiers.

Les documents `transferts` sont purgés.

### `GCDlv` : purge des versions / sponsorings obsolètes
L'opération récupère tous les documents `versions` de `dlv` de la forme aamm antérieures à aujourd'hui - IDBOBSGC jours, bref les _très vielles versions zombi_ devenues inutiles à la synchronisation des bases locales.

L'opération récupère toutes les documents `sponsorings` dont les `dlv` sont antérieures à aujourd'hui. Ces documents sont purgés.

### `GCstc` : création des statistiques mensuelles des `comptas` et des `tickets`
La boucle s'effectue pour chaque espace:
- `comptas`: traitement par l'opération `ComptaStat` pour récupérer les compteurs du mois M-1. 
  - Le traitement n'est déclenché que si le mois à calculer M-1 n'a pas déjà été enregistré comme fait dans `comptas.moisStat` et que le compte existait déjà à M-1.
- `tickets`: traitement par l'opération `TicketsStat` pour récupérer les tickets de M-3 et les purger.
  - Le traitement n'est déclenché que le mois à calculer M-3 n'a pas déjà été enregistré comme fait dans `comptas.moisStatT` et que le compte existait déjà à M-3.
  - une fois le fichier CSV écrit en _storage_, les tickets de M-3 et avant sont purgés.

**Les fichiers CSV sont stockés en _storage_** après avoir été _crypter_ par `crypterRaw` qui:
- génère une clé AES pour le fichier, l'IV associé étant les 16 premiers bytes de cette clé,
- créé un item de 49 bytes: 32 pour la clé, 16 pour l'IV, 1 indiquant si le fichier est gzippé,
- crypte cet item:
  - c1: par la clé publique du Comptable de l'espace,
  - c2: par la clé k d'administration du site.
- retourne l'ensemble `c1 c2 fichier` (gzippé ou non) crypté, prêt à être écrit sur _storage_.

Les statistiques sont doublement accessibles par le Comptable ET l'administrateur technique du site.

## Lancement global quotidien
Le traitement enchaîne, en asynchronisme de la requête l'ayant lancé : 
- `GCHeb GCGro GCPag GCFpu GCTra GCDlv GCstc`

En cas d'exception de l'un deux, une seule relance est faite après une attente d'une heure.

> Remarque : le traitement du lendemain est en lui-même une reprise.

> Pour chaque opération, il y a N transactions, une par document à traiter, ce qui constitue un _checkpoint_ naturel fin.

# Décomptes des coûts et crédits

> **Remarque**: en l'absence d'activité d'une session la _consommation_ est nulle, alors que le _coût d'abonnement_ augmente à chaque seconde même sans activité.

On compte **en session** les downloads / uploads soumis au Storage.

On compte **sur le serveur** le nombre de lectures et d'écritures effectués dans chaque opération et **c'est remonté à la session** où:
- on décompte les 4 compteurs depuis le début de la session (ou son reset volontaire après enregistrement au serveur du delta par rapport à l'enregistrement précédent).
- pn envoie les incréments des 4 compteurs de consommation par l'opération `EnregConso` toutes les PINGTO2 (dans `api.mjs`) minutes.
  - pas d'envoi s'il n'y a pas de consommation à enregistrer mais envoi quand même au bout d'une demi-heure (pour activer un ping de survie).

Le tarif de base repris pour les estimations est celui de Firebase [https://firebase.google.com/pricing#blaze-calculator].

Le volume _technique_ moyen d'un groupe / note / chat est estimé à 8K. Ce chiffre est probablement faible, le volume _utile_ en Firestore étant faible par rapport au volume réel occupé avec les index ... D'un autre côté, le serveur considère les volumes utilisés en base alors que V1 / V2 vont être décomptés sur des quotas (des maximum rarement atteints).

## Classe `Tarif`
Un tarif correspond à,
- `am`: son premier mois d'application. Un tarif s'applique toujours au premier de son mois.
- `cu` : un tableau de 7 coûts unitaires `[u1, u2, ul, ue, um, ud]`
  - `u1`: 30 jours de quota q1 (250 notes / chats)
  - `u2`: 30 jours de quota q2 (100Mo)
  - `ul`: 1 million de lectures
  - `ue`: 1 million d'écritures
  - `um`: 1 GB de transfert montant.
  - `ud`: 1 GB de transfert descendant.

En configuration un tableau ordonné par `aaaamm` donne les tarifs applicables, ceux de plus d'un an n'étant pas utiles. 

L'initialisation de la classe `Tarif.init(...)` est faite depuis la configuration (UI comme serveur).

On ne modifie pas les tarifs rétroactivement, en particulier celui du mois en cours (les _futurs_ c'est possible).

La méthode `const t = Tarif.cu(a, m)` retourne le tarif en vigueur pour le mois indiqué.

## Objet quotas et volumes `qv` : `{ qc, q1, q2, nn, nc, ng, v2 }`
- `qc`: quota de consommation
- `q1`: quota du nombre total de notes / chats / groupes.
- `q2`: quota du volume des fichiers.
- `nn`: nombre de notes existantes.
- `nc`: nombre de chats existants.
- `ng` : nombre de participations aux groupes existantes.
- `v2`: volume effectif total des fichiers.

Cette objet est la propriété `qv` de `comptas`. 

## Objet consommation `conso` : `{ nl, ne, vm, vd }`
- `nl`: nombre absolu de lectures depuis la création du compte.
- `ne`: nombre d'écritures.
- `vm`: volume _montant_ vers le Storage (upload).
- `vd`: volume _descendant_ du Storage (download).

Cet objet rapporte une évolution de consommation. Paramètre de l'opération `EnregConso`.

## Unités
- T : temps.
- D : nombre de document (note, chat, participations à un groupe).
- B : byte.
- L : lecture d'un document.
- E : écriture d'un document.
- € : unité monétaire.

## Classe `Compteurs`
Cette classe donne les éléments de facturation et des éléments de statistique d'utilisation sur les les 12 derniers mois (mois en cours y compris).

**Propriétés:**
- `dh0` : date-heure de création du compte.
- `dh` : date-heure courante (dernier calcul).
- `qv` : quotas et volumes pris en compte au dernier calcul `{ qc, q1, q2, nn, nc, ng, v2 }`.
  - Quand on _prolonge_ l'état actuel pendant un certain temps AVANT d'appliquer de nouvelles valeurs, il faut pouvoir disposer de celles-ci.
- `vd` : [0..3] - vecteurs détaillés pour M M-1 M-2 M-3.
- `mm` : [0..18] - coût abonnement + consommation pour le mois M et les 17 mois antérieurs (si 0 pour un mois, le compte n'était pas créé).
- `aboma` : somme des coûts d'abonnement des mois antérieurs au mois courant depuis la création du compte.
- `consoma` : somme des coûts de consommation des mois antérieurs au mois courant depuis la création du compte.

Le vecteur `vd[0]` et le montant `mm[0]` vont évoluer tant que le mois courant n'est pas terminé. Pour les mois antérieurs `vd[i]` et `mm[i]` sont immuables.

### Dynamique
Un objet de class `Compteurs` est construit,
- soit depuis `serial`, la sérialisation de son dernier état,
- soit depuis `null` pour un nouveau compte.
- la construction recalcule tout l'objet: il était sérialisé à un instant `dh`, il est recalculé pour être à jour à l'instant t.
- **puis** il peut être mis à jour, facultativement, juste avant le retour du `constructor`, par:
  - `qv` : quand il faut mettre à jour les quotas ou les volumes,
  - `conso` : quand il faut enregistrer une consommation.

`const compteurs = new Compteurs(serial, qv, conso, dh)`
- `dh` est facultatif et sert en test pour effectuer des batteries de tests ne dépendants pas de l'heure courante.

### Vecteur détaillé d'un mois
Pour chaque mois M à M-3, il y a un **vecteur** de 14 (X1 + X2 + X2 + 3) compteurs:
- X1_moyennes et X2 cumuls servent au calcul au montant du mois
  - QC : moyenne de qc dans le mois (€)
  - Q1 : moyenne de q1 dans le mois (D)
  - Q2 : moyenne de q2 dans le mois (B)
  - X1 + NL : nb lectures cumulés sur le mois (L),
  - X1 + NE : nb écritures cumulés sur le mois (E),
  - X1 + VM : total des transferts montants (B),
  - X1 + VD : total des transferts descendants (B).
- X2 compteurs de _consommation moyenne sur le mois_ qui n'ont qu'une utilité documentaire.
  - X2 + NN : nombre moyen de notes existantes.
  - X2 + NC : nombre moyen de chats existants.
  - X2 + NG : nombre moyen de participations aux groupes existantes.
  - X2 + V2 : volume moyen effectif total des fichiers stockés.
- 3 compteurs spéciaux
  - MS : nombre de ms dans le mois - si 0, le compte n'était pas créé
  - CA : coût de l'abonnement pour le mois
  - CC : coût de la consommation pour le mois
  
Voir les  méthodes et getter commentées dans le code.

Le getter `get serial ()` retourne la sérialisation de l'objet afin de l'écrire dans la propriété `compteurs` de `comptas`.

**En session,** `compteurs` est recalculé,
- par `compile()` à la connexion et en synchro,
- explicitement a l'occasion d'une simulation en passant comme arguments `qv` et `conso`.

**En serveur,** des opérations peuvent faire évoluer `qv` de `comptas` de manière incrémentale. L'objet `compteurs` est construit (avec un `qv` -et `conso` s'il enregistre une consommation) puis sa sérialisation est enregistrée dans `comptas`:
- création / suppression d'une note ou d'un chat: incrément / décrément de nn / nc.
- prise / abandon d'hébergement d'un groupe: delta sur nn / nc / v2.
- création / suppression de fichiers: delta sur v2.
- enregistrement d'un changement de quotas q1 / q2.
- upload / download d'un fichier: delta sur vm / vd.
- enregistrement d'une consommation de calcul: delta sur nl / ne / vd / vm en passant l'évolution de consommation dans l'objet `conso`.

Le Comptable peut afficher le `compteurs` de n'importe quel compte A ou O.

Les sponsors d'une tranche ne peuvent faire afficher les `compteurs` _que_ des comptes de leur tranche.

A la connexion d'un compte O, trois compteurs statistiques sont remontés de `compteurs` dans sa `tribus`:
- `v1`: le volume V1 effectivement utilisé,
- `v2`: le volume V2 effectivement utilisé,
- `cj`: la consommation moyenne journalière (`consoj`).

Les compteurs ne sont remontés que si l'un des trois s'écarte de plus de 10% de la valeur connue dans sa `tribus`.

### Classe `Credits`
La propriété `credits` n'existe dans `comptas` que pour un compte A:
- elle est cryptée par la clé K du compte qui est seul à y accéder.
- toutefois elle est cryptée par la clé publique du compte juste après l'opération de passage d'un compte O à A.

**Propriétés:**
- `total` : total des crédits encaissés, plus les dons reçus, moins les dons effectués.
- `tickets`: liste des tickets générés par le compte.

### Documents `tickets`
Voir ci-avant la section correspondante.

### Mutation d'un compte _autonome_ en compte _d'organisation_
Le compte a demandé et accepté, de passer O. Son accord est traduit par le dernier item de son chat avec le sponsor ou le Comptable qui effectue l'opération: son texte est `**YO**`.

Le Comptable ou un sponsor désigne le compte dans ses contacts et vérifie:
- que c'est un compte A,
- que le dernier item écrit par le compte est bien `**YO**`.

Les quotas `qc / q1 / q2` sont ajustés par le sponsor / comptable:
- de manière à supporter au moins le volume actuels v1 / v2,
- en respectant les quotas de la tranche courante.

L'opération de mutation:
- inscrit le compte dans la tranche courante,
- dans `compteurs` du `comptas` du compte:
  - remise à zéro du total abonnement et consommation des mois antérieurs (`razma()`):
  - l'historique des compteurs et de leurs valorisations reste intact.
  - les montants du mois courant et des 17 mois antérieurs sont inchangés,
  - MAIS les deux compteurs `aboma` et `consoma` qui servent à établir les dépassements de coûts sont remis à zéro: en conséquence le compte va bénéficier d'un mois (au moins) de consommation _d'avance_.
- inscription d'un item de chat.

### Rendre _autonome_ un compte O
C'est une opération du Comptable et/ou d'un sponsor:
- selon la configuration de l'espace, l'accord du compte est requis si la configuration de l'espace l'a rendu obligatoire (item de chat avec `**YO**`)

L'opération de mutation:
- retire le compte de sa tranche.
- comme dans le cas ci-dessus, remise à zéro des compteurs total abonnement et consommation des mois antérieurs.
- un objet `ticket` par convention égal à `false` est créé. La prochaine connexion ou synchronisation du compte l'initialise et le crypte par la clé K:
  - `total` vaut un pécule de 2c, le temps de générer un ticket et de l'encaisser.
  - une liste `tickets` vide.

### Sponsoring d'un compte O
Rien de particulier : `compteurs` est initialisé. Sa consommation est nulle, de facto ceci lui donne une _avance_ de consommation moyenne d'au moins un mois.

### Sponsoring d'un compte A
`compteurs` est initialisé, sa consommation est nulle mais il bénéficie d'un _total_ minimal pour lui laisser le temps d'enregistrer son premier crédit.

Un objet `ticket` est créé dans `comptas` avec:
- un `total` de 2 centimes.
- une liste `tickets` vide.
- l'objet est crypté par la clé K du compte à l'acceptation du sponsoring.

# Annexe I: Discordances temporelles des données

## Discordances par détection tardive de disparitions
Un chat I / E peut référencer un avatar E alors que celui-ci a été détecté disparu par le GC.
- le GC ne peut pas connaître la liste des chats dans lesquels un avatar disparu est impliqué.
- l'avatar I ne détectera la disparition de E que lorsqu'en session il ouvrira la liste des chats et plus précisément fera rafraîchir la liste des CV.

Un avatar principal peut référencer dans la liste de ses participations aux groupes, un groupe détecté disparu par disparition / résiliation de son dernier membre actif.
- le GC n'ayant pas connaissance de l'avatar principal du compte d'un membre ne peut pas mettre à jour,
  - ni la liste des participations aux groupes des membres,
  - leurs invitations en cours.
- la disparition d'un groupe n'est détectée qu'à l'ouverture de la prochaine session (ou plus tôt par synchronisation, quand une session est active).

### Discordances temporaires en session sur les décomptes de chats et groupes
L'existence d'un chat décompté pour un compte est marqué,
- par l'existence de rows chats attachés à un de ses avatars,
- par le décompte `ng.nc` dans comptas du compte.

Les deux informations sont mises à jour sous contrôle transactionnel: les données persistantes sont toujours cohérentes entre elle.

En session, l'ordre dans lequel parviennent les mises à jour est aléatoire: mise à jour chats avant mise à jour `comptas` ou l'inverse.
- pendant un certain temps le nombre de chats comptés en session peut différer de celui détenu dans `comptas`.
- la situation se stabilise d'elle-même par synchronisation.
- il est difficile d'arriver à mettre en évidence cette discordance temporaire de décompte, par ailleurs sans conséquences réelles.

Le nombre de participations aux groupes est de même détenu dans deux rows: 
- `avatars` principal du compte: dans la map `mpg`,
- `comptas` du compte: propriété `qv.ng`.

La situation se stabilise d'elle-même, est difficile à observer et sans conséquences réelles.

Le troisième cas similaire est celui de l'existence d'une note supprimée (_zombi_) encore temporairement décomptée dans `comptas.qv.nn`.

**Conclusions**
- les décomptes dans `comptas.qv` et `avatars` ou `chats` ne sont pas réalignés: le décompte des coûts reste cohérent.
- dans la logique de gestion on tient compte des rows `avatars` et `chats` sans se préoccuper d'une possible discordance passagère des décomptes avec `comptas.qv`.
- la détection tardive éventuelle de disparitions est assumée:
  - avoir des groupes ou des chats décomptés à tort n'a pas d'impact de calcul des coûts puisque _l'abonnement_ se fait sur des quotas maximum, pas sur le nombre effectif de groupes et chats.
  - on assume que quelques chats _passifs_ de I ne soient pas supprimés alors que E a disparu parce que ceci ne peut être détecté qu'à l'ouverture de vue des chats. 

# Annexe II: déclaration des index

## SQL
`sqlite/schema.sql` donne les ordres SQL de création des tables et des index associés.

Rien de particulier : sont indexées les colonnes requérant un filtrage ou un accès direct par la valeur de la colonne.

## Firestore
`firestore.index.json` donne le schéma des index: le désagrément est que pour tous les attributs il faut indiquer s'il y a ou non un index et de quel type, y compris pour ceux pour lesquels il n'y en a pas.

**Les règles génériques** suivantes ont été appliquées:

_data_ n'est jamais indexé.

Il n'y a pas _d'index composite_. Toutefois en fait les attributs `id_v` et `id_vcv` calculés (pour Firestore seulement) avant création / mise à jour d'un document, sont des pseudo index composites mais simplement déclarés comme index:
- `id_v` est un string `id/v` où `id` est sur 16 chiffres et `v` sur 9 chiffres.
- `id_vcv` est un string `id/vcv` où `id` est sur 16 chiffres et `vcv` sur 9 chiffres.

Ces attributs apparaissent dans:
- tous les documents _majeurs_ pour `id_v`,
- `avatars chats membres` pour `id_vcv`.

En conséquence les attributs `id v vcv` ne sont **pas** indexés dans les documents _majeurs_.

`id` est indexée dans `gcvols` et `fpurges` qui n'ont pas de version `v` et dont l'`id` doit être indexée pour filtrage par l'utilitaire `export/delete`.

Dans les sous-collections versionnées `notes chats membres sponsorings tickets`: `id ids v` sont indexées. 

Pour `sponsorings` `ids` sert de clé d'accès direct et a donc un index **collection_group**, pour les autres l'index est simple.

Dans la sous-collection non versionnée `transferts`: `id ids` sont indexées mais pas `v` qui n'y existe pas.

`dlv` est indexée,
- simple sur `versions`,
- **collection_group** sur les sous-collections `transferts sponsorings membres`.

Autres index:
- `hps1` sur `comptas`: accès à la connexion par phrase secrète.
- `hpc` sur `avatars`: accès direct par la phrase de contact.
- `dfh` sur `groupes`: détection par le GC des groupes sans hébergement.

# Annexe III: IndexedDB dans les session UI

Un certain nombre de documents sont stockés en session UI dans la base locale IndexedDB et utilisés en modes _avion_ et _synchronisé_.
- `compte`: singleton d'`id` vaut '1'.
  - son contenu est la sérialisation de `{ id:..., k:... }` cryptée par la PBKFD de la phrase secrète complète.
  - `id` : id du compte (son avatar principal et de comptas).
  - `k` : 32 bytes de la clé K du compte.
- `tribus`: 'id',
- `comptas`: 'id'. De facto un singleton mais avec une clé qui n'est pas 1 (c'était une option plausible).
- `avatars`: 'id',
- `chats`: '[id+ids]',
- `sponsorings`: '[id+ids]',
- `groupes`: 'id',
- `membres`: '[id+ids]',
- `notes`: '[id+ids]',
- `tickets`: '[id+ids]'.

La clé _simple_ `id` en string est cryptée par la clé K du compte et encodée en base 64 URL.

Les deux termes de clés `id` et `ids` sont chacune en string crypté par la clé K du compte et encodée en base 64 URL.

Le format _row_ d'échange est un objet de la forme `{ _nom, id, ..., _data_ }`.

En IDB les _rows_ sont sérialisés et cryptés par la clé K du compte.

Il y a donc une stricte identité entre les documents extraits de SQL / Firestore et leurs états stockés en IDB

_**Remarque**_: en session UI, d'autres documents figurent aussi en IndexedDB pour,
- la gestion des fichiers locaux: `avnote fetat fdata loctxt locfic locdata`
- la mémorisation de l'état de synchronisation de la session: `avgrversions sessionsync`.

@@ L'application UI [uiapp](./uiapp.md)
