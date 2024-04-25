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

On distingue deux classes d'organisation techniques: **SQL** et **NOSQL+Data Sync**.

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
- il faut a minima une _Cloud Function_ pour gérer les transactions de lecture / mises à jour de type REST:
  - le service correspondant peut être _up_ juste le temps d'une transaction et repasser _down_ en l'absence de sollicitation.
  - il peut aussi de fait être assuré par un serveur qui reste _up_ en continu (du moins sur une longue durée).
- les sessions clientes sont insensibles à la tombée _down_ de la Cloud Function (ou du serveur). Les les abonnements ne sont gérés que par les sessions clientes et d'ailleurs la _Function_ ne gère pas de _sessions clientes_. 
- la première implémentation correspond à une base Firestore et à une Google Cloud Function. 

> **Remarque:** entre une implémentation GCP Function et AWS Lambda, il n'y a a priori qu'une poignée de lignes de code de différence dans la configuration de l'amorce du service et bien entendu une procédure de déploiement spécifique.

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
- ils sont écrits, écrasés, jamais relus ni détruits.
- ils sont facultatifs: la base est opérationnelle sans leur présence et c'est effectivement le cas pour une base _neuve_.

La collection `singletons` a un nombre fixe de documents représentant les derniers _rapports de GC_:
- `id` :
  - `1` : rapport du dernier _ping_ effectué sur la base.
  - `10-19` : rapports des phases du GC,
  - `20-29` : rapports de la dernière génération de rapports par le GC.
- `v` : estampille d'écriture en ms.
- `_data_` : sérialisation non cryptée des données traçant l'exécution d'une phase du dernier traitement journalier de GC ou trace du _ping_.

Par exemple le _path_ en Firestore du dernier _ping_ est `singletons/1`.

# Espaces
Tous les autres documents comportent une colonne / attribut `id` dont la valeur détermine un partitionnement en _espaces_ cloisonnés : dans chaque espace aucun document ne référence un document d'un autre espace.

Un espace est identifié par `ns`, **un entier de 10 à 89**. Chaque espace à ses données réparties dans les collections / tables suivantes:
- `espaces syntheses` : un seul document / row par espace. Leur attribut `id` (clé primaire en SQL) a pour valeur le `ns` de l'espace. Path Firestore pour le `ns` 24 par exemple : `espaces/24` `syntheses/24`.
- tous les autres documents ont un attribut / colonne `id` de 16 chiffres dont les 2 premiers sont le `ns` de leur espace. Les propriétés des documents peuvent citer l'id _courte_ d'autres documents, sans les deux premiers chiffres.

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
- de partitionner les quotas attribués aux comptes "O" de quotas et d'en ajuster les quotas,
- de désigner les _délégués_ de chaque partition, le cas échéant de retirer ou d'ajouter la qualité de _délégué_ a un compte "O" de la partition.
- de changer un compte "O" de partition.
- de gérer des _notifications / blocages_ s'appliquant à des comptes "O" spécifiques ou à tous les comptes d'une partition.
- d'enregistrer les paiements des comptes A.
- de sponsoriser directement la création de nouveaux comptes.

Le Comptable est un compte "O" qui:
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

# Table / documents d'un espace

## Entête d'un espace: `espaces syntheses`
Pour un espace donné, ce sont des singletons:
- `espaces` : `id` est le `ns` (par exemple `24`) de l'espace. Le document contient quelques données générales de l'espace.
  - Clé primaire : `id`. Path : `espaces/24`
- `syntheses` : `id` est le `ns` de l'espace. Le document contenant des données statistiques sur la distribution des quotas aux comptes "O" (par _partition_) et l'utilisation de ceux-ci.
  - Clé primaire : `id`. Path : `syntheses/24`

# Tables / collections _majeures_ : `partitions comptes comptas avatars groupes`
Chaque collection a un document par `id` (clé primaire en SQL, second terme du path en Firestore).
- `partitions` : un document par _partition de quotas_ décrivant la distribution des quotas entre les comptes "O" attachés à cette partition.
  - `id` (sans le `ns`) est un numéro séquentiel `1..N`.
  - Clé primaire : `id`. Path : `partitions/0...x`
- `comptes` : un document par compte donnant les clés majeures du compte, la liste de ses avatars et des groupes auxquels un de ses avatars participe. L'`id` courte sur 14 chiffres est le numéro du compte :
  - `10...0` : pour le Comptable.
  - `2x...y` : pour les autres comptes, `x...y` est un nombre aléatoire sur 13 chiffres.
  - Clé primaire : `id`. Path : `comptas/10...0` `comptas/2x...y`
- `comptas` : un document par compte donnant les compteurs de consommation et les quotas.
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
- en Firestore les paths sont (par exemple pour la sous-collection note) : `versions/2.../notes/z...t`, `id` est le second terme du path, `ids` le quatrième.

- `notes` : un document représente une note d'un avatar ou d'un groupe. L'identifiant relatif `ids` est un nombre aléatoire.
- `sponsorings` : un document représente un sponsoring d'un avatar. Son identifiant relatif est _ns +  hash de la phrase_ de sponsoring entre le sponsor et son sponsorisé.
- `chats` : un chat entre 2 avatars A et B se traduit en deux documents : 
  - l'un sous-document de A a pour identifiant secondaire `ids` un hash de l'id courte de B.
  - l'autre sous-document de B a pour identifiant secondaire `ids` un hash de l'id courte de A.
- `membres` : un document par membre avatar participant à un groupe. L'identifiant secondaire `ids` est l'indice membre `1..N`, ordre d'enregistrement dans le groupe.
- `chatgrs`: un seul document par groupe. `id` est celui du groupe et `ids` vaut toujours `1`.
- `tickets`: un document par ticket de crédit généré par un compte A. `ids` est un nombre aléatoire tel qu'il puisse s'éditer sous forme d'un code à 6 lettres majuscules (de 1 à 308,915,776).

# Clés de cryptage
## Phrases
### Phrase secrète d'accès à un compte
- XC : PBKFD de la phrase complète - hXC son hash.
- XR : PBKFD de la phrase réduite - hXR son hash.

### Phrase de sponsoring
- YC : PBKFD de la phrase complète - hYC son hash
- YR : PBKFD de la phrase réduite - hYR son hash.

### Phrase de contact d'un avatar
- ZC : PBKFD de la phrase complète - hZC son hash.
- ZR : PBKFD de la phrase réduite - hZR son hash.

## Clés
### S : clé du site
Fixée dans la configuration de déploiement du serveur par l'administrateur technique. 

### E : clé d'un espace
- attribuée à la création de l'espace par l'administrateur.
- clé partagée entre l'administrateur et le Comptable de l'espace.
- crypte les rapports générés par le GC pour l'administrateur et le Comptable.

### K : clé principale d'un compte.
- attribuée à la création du compte par `AccepterSponsoring` ou `CreerEspace` pour le Comptable.
- propriété exclusive du compte.
- crypte ses notes.

### A : clé d'un avatar
- attribuée à la création de l'avatar ou du compte pour l'avatar principal.
- crypte sa carte de visite.
- crypte la clé G d'un groupe auquel l'avatar est invité.
- crypte la clé C d'un chat à la création du chat (pour l'exemplaire E).

### C : clé d'un chat
- attribuée aléatoirement à la création du chat.
- crypte le texte du chat.

### G : clé d'un groupe
- attribuée à la création du groupe.
- crypte sa carte de visite, ses notes, les textes deu chat du groupe.
- crypte la clé A d'un membre du groupe.

### P : clé d'une partition
- attribuée à la création de la partition par le Comptable et à la création de l'espace pour le partition primitive.
- crypte les notifications d'une partition et les clés A des comptes de la partition.

## Documents stockant les clés, phrases et hash de phrases
### `espaces`
- `cleES` : clé E cryptée par la clé S.

### `comptes`
- `hXC`: hash du PBKFD de la phrase secrète complète.
- `hXR`: hash du PBKFD de la phrase secrète réduite.
- `cleKXR` : clé K cryptée par XR.
- `clePA` : comptes O seulement. Clé P de sa partition cryptée par la clé A de son avatar principal.
- `cleEK` : Comptable seulement. Clé E cryptée par sa clé K.
- `cleAK` : _pour chaque avatar du compte_:  clé A de l'avatar cryptée par la clé K du compte.
- `cleGK` : _pour chaque groupe_ où un avatar est actif: clé G du groupe cryptée par la clé K du compte. 

### `avatars`
- `cleAZC` : clé A cryptée par ZC.
- `cleGA` : _pour chaque groupe_ où l'avatar est invité.
- `pcK` : phrase de contact cryptée par la clé K du compte.
- `hZR` : hash du PBKFD de la phrase de contact réduite.

### `sponsorings`
- `psK` : phrase de sponsorings cryptée par la clé K du compte.
- `hYR`: : hash du PBKFD de la phrase secrète réduite.

# Périmètre d'un compte _Data Sync_
Le périmètre d'un compte délimite un certain nombre de documents:
- un compte n'a la visibilité en session UI que des documents de son périmètre.
- il ne peut s'abonner qu'à ceux-ci, si c'est sa session qui gère les abonnements. Si c'est le _serveur_ il n'abonne une session donnée d'un compte qu'aux documents du périmètre du compte.

Le _périmètre_ d'un compte ayant une id donnée est le suivant:
- le document `espaces` portant comme `ns` celui de l'id du compte.
- le document `synthèses` portant comme `ns` celui de l'id du compte.
- le document `comptes`  portant cette id.
- le document `comptas` portant cette id.
- les documents `avatars` des avatars principaux et secondaires du compte,
  - les sous-documents `notes sponsorings chats tickets` de ces avatars.
- les documents `groupes` dont un des avatars du compte est membre actif.
  - les sous-documents `notes membres chatgrs` de ces groupes.

Exceptions pour le Comptable:
- le Comptable peut voir tous les documents `espaces synthèses` et pas seulement ceux de _son_ espace.
- En plus de _son_ espace, le Comptable a accès à un instant donné à UN autre espace _courant_ (mais qui peut changer).

## Data Sync
Chaque session UI d'un compte dispose en mémoire de **tous** les documents de son périmètre.

Une session _synchronisée ou avion_ dispose dans sa base locale de tous les documents de ce périmètre **sauf** son document `syntheses`.

Le mécanisme de Data Sync permet à la mémoire d'une session (et à sa base locale le cas échéant) de refléter au plus tôt l'état des documents du périmètre tel qu'il existe en base, **sauf** le document `synthèses` qui est chargé à la demande (pas en avion donc).

Voir l'annexe **Connexion et synchronisation**.

> Cet état est sujet à des évolutions en cours de session suite aux effets des opérations soumises au serveur, soit par la session elle-même, soit par n'importe quelle autre, du même compte ou de n'importe quel autre, et marginalement du GC.

## Tracking des créations et mises à jour
**Remarque:** il n'y a pas à proprement parlé de _suppressions_:
- un document `sponsorings` a une date limite de validité: le document est logiquement supprimé que cette date est dépassée.
- un document `notes` peut être _vide_, n'a plus de contenu, n'apparaît plus dans les vues, mais son document existe toujours.

Les documents `versions` sont chargés du tracking des mises à jour des documents du périmètre et des sous-documents de `avatars` et de `groupes`. Propriétés:
- `id` : _référence data sync_ `rds` du document.
- `v` : version, incrémentée de 1 à chaque mise à jour, soit du document maître, soit de ses sous-documents `notes sponsorings chats tickets membres chatgrs`
- `suppr` : jour de suppression.

> **Remarque:** Le GC lit les `versions` supprimées depuis plus de N mois pour les purger.

**La constante `IDBOBS / IDBOBSGC` de `api.mjs`** donne le nombre de jours de validité d'une micro base locale IDB sans resynchronisation. Celle-ci devient **obsolète** (à supprimer avant connexion) `IDBOBS` jours après sa dernière synchronisation. Ceci s'applique à _tous_ les espaces avec la même valeur.

> Les documents de tracking versions sont purgés `IDBOBSGC` jours après leur jour de suppression `suppr`.

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
- soit par un compte "O" _délégué_ ou par le Comptable: un cadeau de bienvenue de 2c est affecté au compte "A" sponsorisé (prélevé chez personne).

Un compta "A" définit lui-même ses quotas `q1` et `q2` (il les paye en tant _qu'abonnement_) et n'a pas de quotas `qc` (il paye sa _consommation_).

# Détail des tables / collections _majeures_ et leurs _sous-collections_
Ce sont les documents cible d'un synchronisation entre sessions UI et base: `partitions comptes comptas avatars groupes notes sponsorings chats tickets membres chatgrs versions`

## _data_
Tous les documents, ont une propriété `_data_` qui porte toutes les informations sérialisées du document.

`_data_` est crypté:
- en base _centrale_ par la clé du site qui a été générée par l'administrateur technique et qu'il conserve en lieu protégé comme quelques autres données sensibles (_token_ d'autorisation d'API, identifiants d'accès aux comptes d'hébergement ...).
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

### `dlv` d'un `comptes`
La `dlv` **d'un compte** désigne le dernier jour de validité du compte:
- c'est le **dernier jour d'un mois**.
- _**cas particulier**_: quand c'est le premier jour d'un mois, la `dlv` réelle est le dernier jour du mois précédent. Dans ce cas elle représente la date de fin de validité fixée par l'administrateur pour l'ensemble des comptes "O". En gros il a un financement des frais d'hébergement pour les comptes de l'organisation jusqu'à cette date (par défaut la fin du siècle).

La `dlv` d'un compte est inscrite dans le document `comptes` du compte: elle est externalisée pour que le GC puisse récupérer tous les comptes obsolètes à détruire.

## `dlv` d'un `sponsorings` 
- jour au-delà duquel le sponsoring n'est plus applicable ni pertinent à conserver. Les sessions suppriment automatiquement à la connexion les sponsorings ayant dépassé leur `dlv`.
- dès dépassement du jour de `dlv`, un sponsorings est purgé (du moins peut l'être).
- elles sont indexées pour que le GC puisse purger les sponsorings. En Firestore l'index est `collection_group` afin de s'appliquer aux sponsorings de tous les avatars.

### `vcv` : version de la carte de visite. `avatars chats membres`
Cette propriété est la version `v` du document au moment de la dernière mise à jour de la carte de visite: elle est indexée.

### `dfh` : date de fin d'hébergement. `groupes`
La **date de fin d'hébergement** sur un groupe permet de détecter le jour où le groupe sera considéré comme disparu. A dépassement de la `dfh` d'un groupe, le GC fait disparaître le groupe inscrivant une `suppr` du jour dans son document `versions` et une version v à 999999 dans le document `groupes`.

### `hZR` : hash de la phrase de contact. `avatars`
Cette propriété de `avatars` est indexée de manière à pouvoir accéder à un avatar en connaissant sa phrase de contact.

### `hXR` : hash d'un extrait de la phrase secrète. `comptes`
Cette propriété de `comptes` est indexée de manière à pouvoir accéder à un compte en connaissant le `hXR` issu de sa phrase secrète.

### Propriétés techniques composites `id_v id_vcv`
**En Firestore** les documents des collections _majeures_ `partitions comptes comptas avatars groupes versions` ont un ou deux attributs _techniques composites_ calculés et NON présents en _data_:
- `id_v` : un string `id/v` ou `id` est l'id sur 16 chiffres et `v` la version du document sur 9 chiffres.
- `id_vcv` pour les documents `avatars` seulement: un string `id/vcv` ou `id` est l'id sur 16 chiffres et `vcv` la version de la carte de visite de l'avatar sur 9 chiffres.

### Propriété `v` de `transferts`
Elle permet au GC de détecter les transferts en échec et de nettoyer le _storage_.
- en Firestore l'index est `collection_group` afin de s'appliquer aux fichiers des notes de tous les avatars et groupe.

# Cache locale des `espaces partitions comptes comptas avatars groupes versions` dans un serveur
Un _serveur_ ou une _Cloud Function_ qui ne se différencient que par leur durée de vie _up_ ont une mémoire cache des documents:
- `comptes` accédés pour vérifier si les listes des avatars et groupes du compte ont changé.
- `comptas` accédés à chaque changement de volume ou du nombre de notes / chats / participations aux groupes.
- `versions` accédés pour gérer le Data Sync..
- `avatars groupes partitions` également fréquemment accédés.

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

## Clé d'un avatar ou d'un groupe
Ces 32 bytes aléatoires sont la clé de cryptage de leur carte de visite:
- Le premier byte donne le _type_ de l'id, qu'on retrouve comme troisième chiffre de l'id : 1, 2, 3.
- Les autres bytes sont aléatoires.

## Clé d'une partition
Elle a 32 bytes:
- byte 0 : 2.
- bytes 1 et 2 : numéro de la partition, numéro d'ordre de sa déclaration par le Comptable dans l'espace.
- autres bytes aléatoires.

> Depuis la _clé_ d'une partition, d'un avatar ou d'un groupe, une fonction simple retourne son `id` courte (sans `ns`).

> Une id **courte** est une id SANS les deux premiers chiffres de l'espace, donc relative à son espace.

# Authentification

## L'administrateur technique
Il a une phrase de connexion dont le SHA de son PBKFD (`shax`) est enregistré dans la configuration d'installation. 
- Il n'a pas d'id, ce n'est PAS un compte.
- Une opération de l'administrateur est repérée parce que son _token_ contient son `shax`.

**Quelques opérations ne sont pas authentifiées**: 
- L'opération de création d'un compte `AccepterSponsorings`: par principe le compte n'est pas encore enregistré.
- Les opérations du GC,
- des opérations de nature _ping_ tests d'écho, tests d'erreur fonctionnelle.

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
  - `hXR` : hash (sur 14 chiffres) du PBKFD d'un extrait de la phrase secrète.
  - `hXC` : hash (sur 14 chiffres) du PBKFD de la phrase secrète complète.

Le serveur recherche le document `comptes` par `ns + hXR` (index de `comptes`). Le `ns` est connu par le code `org` figurant dans le token.
- vérifie que `hXC` est bien celui enregistré dans `comptes`.
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
Un objet _notification_ est immuable car en cas de _mise à jour_ il est remplacé par un nouveau.

Type des notifications:
- E : de l'espace
- P : d'une partition (comptes O)
- C : d'un compte (comptes O)
- Q : de dépassement de quotas
- X : d'excès de consommation (dépassement du solde pour un compte "A"). 

Une notification a les propriétés suivantes:
- `nr`: restriction d'accès: 
  - 1 : **aucune restriction**. La notification est informative mais peut annoncer une restriction imminente.
  - 2 : **restriction réduite**
    - E : espace figé
    - P : accès en lecture seule
    - C : accès en lecture seule
    - Q : actions accroissant le volume interdites
  - 3 : **restriction forte**
    - E : espace clos
    - P : accès minimal
    - C : accès minimal
    - X : accès minimal
- `dh` : date-heure de création.
- `texte`: il est crypté par: 
  - type E: la clé A du Comptable (que tous les comptes de l'espace ont).
  - types P et C par la clé P de la partition.
  - types Q et X: pas de texte, juste un code.
- `iddel`: id du délégué ayant créé cette notification pour un type P ou C quand ce n'est pas le Comptable.

**Remarque:** une notification `{ dh: ... }` correspond à la suppression de la notification antérieure (ni restriction, ni texte).

> Le document `comptes` a une date-heure de lecture `dhvuK` qui indique _quand_ le titulaire du compte a lu les notifications. Une icône peut ainsi signaler l'existence d'une _nouvelle_ notification, i.e. une notification qui n'a pas été lue.

# Sous-objet carte de visite
Une carte de visite a 4 propriétés `{ id, v, ph, tx }`:
- `id` : de l'avatar ou du groupe.
- `v`: version de la carte de visite, version du groupe ou de l'avatar au moment de sa dernière mise à jour.
- `ph`: photo cryptée par la clé A de l'avatar ou G du groupe propriétaire.
- `tx`: texte (gzippé) crypté par la clé A de l'avatar ou G du groupe propriétaire.

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

# Documents `versions`
Donne la plus haute version d'un document majeur `comptes / comptis` et pour `avatars` ou `groupes` et de leurs sous-documents.

_data_ :
- `id` : `ns` + `rds` du document référencé.
- `v` : 1..N, plus haute version attribuée au document et à ses sous-documents.
- `suppr` : jour de suppression, ou 0 s'il est actif.

C'est le seul document qu'une session client est habilitée à lire en direct de la base, en particulier par une lecture `onSnapshot` qui ne revient que quand une mise à jour a été opérée.

Les autres lectures passent obligatoirement par le _serveur / Cloud Function_ afin d'être certain que la session cliente est habilitée à cette lecture en fonction de son authentification: ceci garantit que les données _hors périmètre_ d'un compte ne sont pas accessibles.

## Pourquoi `rds` et pas `id` ?
`rds` est un identifiant aléatoire sur 16 chiffres attribué à la création du document correspondant. 
- les deux premiers chiffres sont le `ns` de l'espace,
- le troisième donne le nom du document,
  - 1 : `comptes`,
  - 2 : `avatars`;
  - 3 : `groupes`.
- les 13 suivants sont aléatoires.

Au lieu de `rds`, l'id aurait pu être utilisée mais **il aurait été possible à une session malicieuse d'interroger `versions` sur des id hors de son périmètre** et d'obtenir des informations sur _l'activité de mise à jour_ d'autres comptes, d'autres avatars que les siens, d'autres groupes que ceux accédés par ses avatars.

Voir le chapitre **Connexion et synchronisation**.

# Documents `espaces`
Cle S, notification générale, options.
_data_ :
- `id` : de l'espace de 10 à 89.
- `v` : 1..N
- `org` : code de l'organisation propriétaire.

- `rds`
- `cleES` : clé E cryptée par la clé S.
- `creation` : date de création.
- `moisStat` : dernier mois de calcul de la statistique des comptas.
- `moisStatT` : dernier mois de calcul de la statistique des tickets.
- `notif` : notification de l'administrateur technique. Texte NON crypté.
- `dlvat` : `dlv` de l'administrateur technique.
- `t` : numéro de _profil_ de quotas dans la table des profils définis dans la configuration. Chaque profil donne un triplet de quotas `qc q1 q2` qui serviront de guide pour le Comptable qui s'efforcera de ne pas en distribuer d'avantage sans se concerter avec l'administrateur technique.

**Mis à jour par le Comptable:**
- `opt`:
  - 0: 'Pas de comptes "autonomes"',
  - 1: 'Le Comptable peut rendre un compte "autonome" sans son accord',
  - 2: 'Le Comptable NE peut PAS rendre un compte "autonome" sans son accord',
- `nbmi`: nombre de mois d'inactivité acceptable pour un compte O fixé par le comptable. Ce changement n'a pas d'effet rétroactif.

L'administrateur technique gère une `dlvat` pour l'espace : 
- c'est la date à laquelle l'organisation l'administrateur technique détruira les comptes "O". Cette information est disponible dans l'état de la session pour les comptes "O" (les comptes "A" n'étant pas intéressés).
- l'administrateur ne peut pas (re)positionner une `dlvat` à moins de `nbmi` mois du jour courant afin d'éviter les catastrophes de comptes supprimés sans que leur titulaire n'ait eu le temps de se reconnecter.
- par défaut, à l'initialisation elle vaut la fin du siècle.

L'opération de mise à jour d'une `dlvat` est une opération longue du fait du repositionnement des `dlv` des comptes égales à la `dlvat` remplacée:
- cette mise à jour porte sur le document `comptes`.
- elle s'effectue en N opérations enchaînées. Au pire en cas d'incident en cours, une partie des comptes auront leur `dlv` mises à jour et pas d'autres: l'administrateur technique doit manuellement relancer l'opération en surveillant sa bonne exécution complète.

**Le maintien en vie d'un compte "O" en l'absence de connexion** a le double inconvénient, 
- d'immobiliser des ressources peut-être pour rien,
- d'augmenter les coûts d'avance sur les frais d'hébergement.

Le Comptable fixe en conséquence un `nbmi` (de 3, 6, 12, 18, 24 mois) compatible avec ses contraintes mais évitant de contraindre les comptes à des connexion inutiles rien que pour maintenir le compte en vie, et surtout à éviter qu'ils n'oublient de le faire et voir leurs comptes automatiquement résiliés après un délai trop bref de non utilisation.

# Documents `syntheses`
Synthèse des documents `partitions` de l'espace.

La mise à jour d'une partition est peu fréquente : une _synthèse_ au niveau de l'espace est recalculée à chaque mise à jour d'une des partitions de l'espace.

Ce document ne fait pas partie du périmètre synchronisable d'un compte mais peut être obtenu sur demande (pour autant que l'authentification le juge possible).

_data_:
- `id` : id de l'espace.
- `v` : date-heure d'écriture (purement informative).

- `tp` : table des synthèses des partitions de l'espace. L'indice dans cette table est l'id court de la partition. Chaque élément est la sérialisation de:
  - `qc qn qv` : quotas de la partition.
  - `ac an av` : sommes des quotas attribués aux comptes attachés à la partition.
  - `c n v` : somme des consommations journalières et des volumes effectivement utilisés.
  - `ntr0` : nombre de notifications partition sans restriction d'accès.
  - `ntr1` : nombre de notifications partition avec restriction d'accès 1.
  - `ntr2` : nombre de notifications partition avec restriction d'accès 2_.
  - `nbc` : nombre de comptes.
  - `nbd` : nombre de comptes _délégués_.
  - `nco0` : nombres de comptes ayant une notification sans restriction d'accès.
  - `nco1` : nombres de comptes ayant une notification avec restriction d'accès 1.
  - `nco2` : nombres de comptes ayant une notification avec restriction d'accès 2.

`tp[0]` est la somme des `tp[1..N]` calculé en session, pas stocké.

# Documents `partitions`
Niveau partition: 
- quotas, 
- notification et restriction d'accès.

Niveau de chaque compte "O" rattaché: 
- clés, 
- quotas et consommation, 
- notification et restriction d'accès.

_data_:
- `id` : numéro d'ordre de création de la partition par le Comptable.
- `v` : 1..N

- `rds`
- `qc qn qv` : quotas totaux de la partition.
- `clePK` : clé P de la partition cryptée par la clé K du comptable.
- `notif`: notification de niveau _partition_ dont le texte est crypté par la clé P de la partition.

- `ldel` : liste des clés A des délégués cryptées par la clé P de la partition.

- `tcpt` : table des comptes attachés à la partition. L'index `it` dans cette table figure dans la propriété `it` du document `comptes` correspondant :
  - `notif`: notification de niveau compte dont le texte est crypté par la clé P de la partition (`null` s'il n'y en a pas).
  - `cleAP` : clé A du compte crypté par la clé P de la partition.
  - `del`: `true` si c'est un délégué.
  - `q` : `qc qn qv c n v` extraits du document `comptas` du compte. 
    - En cas de changement de `qc qn qv` la copie est immédiate, sinon c'est effectué seulement lors de la prochaine connexion du compte.
    - `c` : consommation moyenne mensuelle lissée sur M et M-1 (`conso2M` de compteurs)
    - `n` : nn + nc + ng nombre de notes, chats, participation aux groupes.
    - `v` : volume de fichiers effectivement occupé.

L'ajout / retrait de la qualité de _délégué_ n'est effectué que par le Comptable au delà du choix initial établi au sponsoring par un _délégué_ ou le Comptable.

### Synchronisation
**La session d'un compte délégué** reçoit l'intégralité du document `partitions`.

**La session d'un compte NON délégué** reçoit le document `partitions` SAUF `tcpt`.
- le document `partitions` est amputé de tout ce qui est relatif aux autres comptes de la partition.
- les clés A des délégués sont disponibles, ils sont joignables et leurs cartes de visite accessibles sur demande.

## Gestion des quotas totaux par _partitions_
La déclaration d'une partition par le Comptable d'un espace consiste à définir :
- générer la clé P aléatoirement :
  - **les 2 premiers bytes donnent l'id de la partition**, son numéro d'ordre de création par le Comptable partant de de 1,
- un `code` signifiant pour le Comptable (dans son `comptes`).
- les sous-quotas `qc q1 q2` attribués.

# Documents `comptes`
- Phrase secrète, clés K P D, rattachement à une partition
- Avatars du compte
- Groupes accédés du compte

_data_ :
- `id` : numéro du compte = id de son avatar principal.
- `v` : 1..N.
- `hXR` : `ns` + `hXR`, hash du PBKFD d'un extrait de la phrase secrète.
- `dlv` : dernier jour de validité du compte.

- `rds`
- `hXC`: hash du PBKFD de la phrase secrète complète (sans son `ns`).
- `cleKXC` : clé K cryptée par XC (PBKFD de la phrase secrète complète).

_Comptes "O" seulement:_
- `clePA` : clé P de la partition cryptée par la clé A de l'avatar principal du compte.
- `rdsp` : `rds` (court) du documents partitions.
- `idp` : id de la partition (pour le serveur) (sinon 0)
- `del` : `true` si le compte est délégué de la partition.
- `it` : index du compte dans `tcpt` de son document `partitions`.

- `mav` : map des avatars du compte. 
  - _clé_ : id court de l'avatar.
  - _valeur_ : `{ rds, claAK }`
    - `rds`: de l'avatar (clé d'accès à son `versions`).
    - `cleAK`: clé A de l'avatar crypté par la clé K du compte.

- `mpg` : map des participations aux groupes:
  - _clé_ : id du groupe
  - _valeur_: `{ cleGK, rds, lp }`
    - `cleGK` : clé G du groupe cryptée par la clé K du compte.
    - rds: du groupe (clé d'accès à son `versions`)
    - `lp`: map des participations: 
      - _clé_: id court de l'avatar.
      - _valeur_: indice `im` du membre dans la table `tid` du groupe (`ids` du membre).

**Comptable seulement:**
- `cleEK` : Clé E de l'espace cryptée par la clé K.
- `tp` : table des partitions : `{c, qc, qn, qv}`.
  - `c` : `{ cleP, code }` crypté par la clé K du comptable
    - `cleP` : clé P de la partition.
    - `code` : texte très court pour le seul usage du comptable.
  - `qc, qn, qv` : quotas globaux de la partition.

La première partition d'`id` 1 est celle du Comptable et est indestructible.

# Documents `comptas`
- Quotas et occupations actuelles.
- Compteurs.
- Solde et tickets pour un compte A.
- A propos des autres.

_data_ :
- `id` : numéro du compte = id de son avatar principal.
- `v` : 1..N.

- `rds`
- `dhvuK` : date-heure de dernière vue des notifications par le titulaire du compte, cryptée par la clé K.
- `qv` : `{qc, qn, qv, nn, nc, ng, v}`: quotas et nombre de groupes, chats, notes, volume fichiers. Valeurs courantes.
- `compteurs` sérialisation des quotas, volumes et coûts.

_Comptes "A" seulement_
- `solde`: résultat, 
  - du cumul des crédits reçus depuis le début de la vie du compte (ou de son dernier passage en compte A), 
  - plus les dons reçus des autres,
  - moins les dons faits aux autres.
- `ticketsK`: liste des tickets cryptée par la clé K du compte `{ids, v, dg, dr, ma, mc, refa, refc, di}`.

- `apropos` : map à propos des contacts (des avatars) et des groupes _connus_ du compte,
  - _cle_: `id` court de l'avatar ou du groupe,
  - _valeur_ : `{ hashtags, texte }` cryptée par la clé K du compte.
    - `hashtags` : liste des hashtags attribués par le compte.
    - `texte` : commentaire écrit par le compte.

Juste après une conversion de compte "O" en "A", `ticketsK` est vide et le `solde` est de 2c.

# Documents `avatars`
- Phrase de contact.
- Carte de visite.
- Invitations.

_data_:
- `id` : id de l'avatar.
- `v` : 1..N. Par convention, une version à 999999 désigne un **avatar logiquement détruit** mais dont les données sont encore présentes. L'avatar est _en cours de suppression_.
- `vcv` : version de la carte de visite afin qu'une opération puisse détecter (sans lire le document) si la carte de visite est plus récente que celle qu'il connaît.
- `hZR` : `ns` + hash du PBKFD de la phrase de contact réduite.

- `rds` : pas transmis en session.
- `cleAZC` : clé A cryptée par ZC (PBKFD de la phrase de contact complète).
- `pcK` : phrase de contact complète cryptée par la clé K du compte.
- `hZC` : hash du PBKFD de la phrase de contact complète.

- `cvA` : carte de visite de l'avatar `{id, v, photo, texte}`. photo et texte cryptés par la clé A de l'avatar.

- `pub privK` : couple des clés publique / privée RSA de l'avatar.

- `invits`: map des invitations en cours de l'avatar:
  - _clé_: `idg` id court du groupe.
  - _valeur_: `{cleGA, cvG, ivpar, dh}` 
    - `cleGA`: clé du groupe crypté par la clé A de l'avatar.
    - `cvG` : carte de visite du groupe (photo et texte sont cryptés par la clé G du groupe).
    - `idiv` : id court de l'invitant.
    - `dh` : date-heure d'invitation. Le couple `[idiv, dh]` permet de retrouver l'item dans le chat du groupe donnant le message de bienvenue / invitation émis par l'invitant.

## Résiliation d'un avatar
Elle est effectuée en deux phases:
- **une transaction courte immédiate:**
  - marque du document `versions` de l'avatar à _supprimé_ (`suppr` porte la date du jour).
  - marque la version `v` de l'avatar à 999999.
  - purge de ses documents `sponsorings`.
  - dès lors l'avatar est logiquement supprimé.
- **une _chaîne_ de transactions différées:**
  - une pour chaque chat de l'avatar: mise à jour de l'exemplaire de l'autre et purge du sien.
  - une pour chaque groupe auquel l'avatar participe:
    - mise à jour de la table `tid`.
    - purge du document `membres`.
    - si le groupe n'a plus de membres actifs, le groupe est _logiquement détruit_:
      - marque du document `versions` du groupe à _supprimé_ (`suppr` porte la date du jour).
      - marque la version `v` du groupe à 999999.
  - quand toutes ses transactions sont terminées, purge du document `avatars`.

La reprise de la chaîne des transactions différées est assurée par le GC pour celles qui ne sont pas allés jusqu'au bout.

## Suppression d'un groupe
Elle intervient quand le groupe n'a plus de membres _actifs_.

C'est une chaîne de transactions différées:
- une pour chaque invitation en cours: mise à jour du documents `avatars` correspondant.
- purge des documents `membres notes chatgrs`.
- transaction finale purgeant le document `groupes` lui-même.

La reprise de la chaîne des transactions différées qui ne sont pas allés jusqu'au bout est assurée par le GC.

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
- `idc`: id du compte générateur. Cette donnée n'est pas transmise aux sessions.

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
- le plus faible des deux montants `ma` et `mc` est incorporé au solde de `comptas`. En cas de différence de montants, une alerte s'affiche.
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
- récupère tous les tickets générés à M-3 (par exemple `202407`) et les efface de la liste `tickets`,
- les stocke dans un _fichier_ **CSV** `T_202407` du Comptable. Ces fichiers sont cryptés par la clé E de l'espace connue de l'administrateur et du Comptable.

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
La clé C du chat est générée à la création du chat et l'ajout du premier item:
- côté I, cryptée par la clé K de I,
- côté E, cryptée par la clé `pub` de E.

## Décompte des nombres de chats par compte
- un chat est compté pour 1 pour I quand la dernière opération qu'il a effectuée est un ajout: si cette dernière opération est un _raz_, le chat est dit _passif_ et compte pour 0.
- ceux qui reçoivent des chats non sollicités et qui les _effacent_ ce principe de gestion évite de pénaliser .

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
- `ids`: aléatoire.
- `v`: 1..N.
- `vcv` : version de la carte de visite de E.

- `st` : deux chiffres `I E`
  - I : 0:passif, 1:actif
  - E : 0:passif, 1:actif, 2:disparu
- `idE idsE` : identifiant de _l'autre_ chat.
- `cvE` : `{id, v, photo, info}` carte de visite de E au moment de la création / dernière mise à jour du chat (textes cryptés par sa clé A).
- `cleCKP` : clé C du chat cryptée,
  - si elle a une longueur inférieure à 256 bytes par la clé K du compte de I.
  - sinon cryptée par la clé RSA publique de I.
- `cleEC` : clé A de l'avatar E cryptée par la clé du chat.
- `items` : liste des items `[{a, dh, l t}]`
  - `a` : 0:écrit par I, 1: écrit par E
  - `dh` : date-heure d'écriture.
  - `dhx` : date-heure de suppression.
  - `t` : texte crypté par la clé C du chat (vide s'il a été supprimé).

## Création d'un chat
**Sur création d'un compte par sponsoring**
- vérification qu'il existe un sponsoring créé par idE et qu'il accepte le chat.
- si le sponsorisé l'a souhaité.
- le chat est créé avec deux items: a) le mot de bienvenue du sponsor, b) la réponse du sponsorisé.

**Quand E est délégué de la partition de I**
- vérification que E est bien un délégué de la partition citée.
- I demande la clé RSA publique de E pour crypter la clé générée du chat.
- création avec un item.

**Quand E est membre d'un groupe G cité et I aussi**
- vérification que I accède aux membres de G et que E y est membre actif.
- I demande la clé RSA publique de E pour crypter la clé générée du chat.
- création avec un item.

**Quand I connaît la phrase de contact de E**
- vérification que E a bien cette phrase de contact et récupération de la cleA de E.
- I a calculé les hash des phrases de contact complète et réduite de E et obtenu en retour la clé A de E cryptée par le PBKFD de cette phrase de contact complète.
- I demande la clé RSA publique de E pour crypter la clé générée du chat.
- création avec un item.

Le nombre de chats dans la compta de I est incrémenté.

## Actions possibles (par I)
- _ajout d'un item_
  - l'item apparaît dans `items` de E (son `a` est inversé).
- _effacement du texte d'un item de I_
  - le texte de l'item est effacé des deux côtés.
  - il n'est pas possible pour I d'effacer le texte d'un item écrit par E.
- _raz_ : effacement total de l'historique des items (du côté I)
  - `items` est vidée du côté I.
  - `st` de I vaut `01` et `st` de E vaut `10` ou `00`.
  - le chat devient _passif_ du côté I.
- _faire un don_:
  Un compte "A" _donateur_ peut faire un don à un autre compte "A" bénéficiaire_ en utilisant un chat.
  - le chat avec don ne peut intervenir que si le chat est défini entre les deux avatars **principaux** des comptes.
  - le montant du don est dans une liste préétablie.
  - le solde du donateur (dans sa `comptas`) doit être supérieur au montant du don.
  - sauf spécification contraire du donateur, le texte de l'item ajouté dans le chat à cette occasion mentionne le montant du don.
  - le donateur est immédiatement débité.
  - le bénéficiaire est immédiatement crédité dans `solde` de sa `comptas`.

> Un chat _passif_ pour un avatar reste un chat _écouté_, les items écrits par E arrivent, mais sur lequel I n'écrit pas. Il redevient _actif_ pour I dès que I écrit un item et ne redevient _passif_ que quand il fait un _raz_.

# Documents `sponsorings`
P est le parrain-sponsor, F est le filleul-sponsorisé.

_data_:
- `id` : id de l'avatar sponsor.
- `ids` : `ns` + (hYR) hash du PBKFD de la phrase réduite de parrainage, 
- `v`: 1..N.
- `dlv` : date limite de validité

- `st` : statut. _0: en attente réponse, 1: refusé, 2: accepté, 3: détruit / annulé_
- `pspK` : texte de la phrase de sponsoring cryptée par la clé K du sponsor.
- `YCK` : PBKFD de la phrase de sponsoring cryptée par la clé K du sponsor.
- `hYC` : hash du PBKFD de la phrase de sponsoring,
- `dh`: date-heure du dernier changement d'état.
- `cleAYC` : clé A du sponsor crypté par le PBKFD de la phrase complète de sponsoring.
- `partitionId`: id de la partition si compte 0
- `clePYC` : clé P de sa partition (si c'est un compte "O") cryptée par le PBKFD de la phrase complète de sponsoring (donne le numéro de partition).
- `nomYC` : nom du sponsorisé, crypté par le PBKFD de la phrase complète de sponsoring.
- `del` : `true` si le sponsorisé est délégué de sa partition.
- `cvA` : `{ id, v, photo, info }` du sponsor, textes cryptés par sa cle A.
- `quotas` : `[qc, q1, q2]` quotas attribués par le sponsor.
  - pour un compte "A" `[0, 1, 1]`. Un tel compte n'a pas de `qc` et peut changer à loisir `[q1, q2]` qui sont des protections pour lui-même (et fixe le coût de l'abonnement).
- `don` : pour un compte autonome, montant du don.
- `dconf` : le sponsor a demandé à rester confidentiel. Si oui, aucun chat ne sera créé à l'acceptation du sponsoring.
- `dconf2` : le sponsorisé a demandé à rester confidentiel. Si oui, aucun chat ne sera créé à l'acceptation du sponsoring.
- `ardYC` : ardoise de bienvenue du sponsor / réponse du sponsorisé cryptée par le PBKFD de la phrase de sponsoring.
- `csp, itsp` : id du COMPTE sponsor et son it dans sa partition. Écrit par le serveur et NON communiqué aux sessions.

**Remarques**
- la `dlv` d'un sponsoring peut être modifiée tant que le statut est _en attente_.
- Le sponsor peut annuler son `sponsoring` avant acceptation, en cas de remord son statut passe à 3.

**Si le sponsorisé refuse le sponsoring :** 
- Il écrit dans `ardYC` la raison de son refus et met le statut du `sponsorings` à 1.

**Si le sponsorisé ne fait rien à temps :** 
- `sponsorings` finit par être purgé par `dlv`.

**Si le sponsorisé accepte le sponsoring :** 
- Le sponsorisé crée son compte:
  - donne les hXR et hXC issus de sa phrase secrète,
  - génère ses clés K et celle de son avatar principal,
  - donne le texte de carte de visite.
- pour un compte "O", l'identifiant de la partition à la quelle le compte est associé est obtenu de `clePYC`.
- la `comptas` du sponsorisé est créée et créditée des quotas attribués par le sponsor pour un compte "O" et d'un `solde` minimum pour un compte "A".
- pour un compte "O" le document `partitions` est mis à jour (quotas attribués), le sponsorisé est mis dans la liste des comptes `tcles / tcpt` de `partitions`.
- un mot de remerciement est écrit par le sponsorisé au sponsor sur `ardYC` **ET** ceci est dédoublé dans un chat sponsorisé / sponsor créé à ce moment et comportant l'item de réponse. Si le sponsor ou le sponsorisé ont requis la confidentialité, le chat n'est pas créé.
- le statut du `sponsoring` est 2.

# Documents `notes`
La clé de cryptage d'une note est selon le cas :
- *note personnelle d'un avatar A* : la clé K de l'avatar.
- *note d'un groupe G* : la clé du groupe G.

Pour une note de groupe, le droit de mise à jour d'une note d'un groupe est contrôlé par `im` qui indique quel membre (son `im`) a l'exclusivité d'écriture (sinon tous).

_data_:
- `id` : id de l'avatar ou du groupe.
- `ids` : identifiant aléatoire relatif à son avatar.
- `v` : 1..N.

- `im` : exclusivité dans un groupe. L'écriture est restreinte au membre du groupe dont `im` est `ids`. 
- `vf` : volume total des fichiers attachés.
- `ht` : liste des hashtags _personnels_ cryptée par la clé K du compte.
- `htg` : note de groupe : liste des hashtags cryptée par la clé du groupe.
- `htm` : NON TRANSMIS en session pour une note de groupe seulement, hashtags des membres. Map:
    - _clé_ : id courte du compte de l'auteur,
    - _valeur_ : liste des hashtags cryptée par la clé K du compte.
- `l` : liste des _auteurs_ (leurs `im`) pour une note de groupe.
- `d` : date-heure de dernière modification du texte.
- `texte` : texte (gzippé) crypté par la clé de la note.
- `mfa` : map des fichiers attachés.
- `ref` : triplet `[id_court, ids, nomp]` crypté par la clé de la note, référence de sa note _parent_.

!!!TODO!!! : vérifier / préciser `nomp`

**Une note peut être logiquement supprimée**. Afin de synchroniser cette forme particulière de mise à jour le document est conservé _zombi_ (sa _data_ est `null`). La note sera purgée un jour avec son avatar / groupe.

**Pour une note de groupe**, la propriété `htm` n'est pas transmise en session: l'item correspondant au compte est copié dans `ht`.

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
- ses membres: des documents de sa sous-collection `membres`.

## Membres d'un groupe: `im / ids`, les tables `tid flags`
Un membre est créé en étant déclaré _contact_ du groupe par un animateur ce qui lui affecte un _indice membre_ de 1 à N, attribué dans l'ordre d'inscription et sans réattribution (sauf cas particulier). Pour un groupe `id`, un membre est identifié par le couple `id / ids` (où `ids` est l'indice membre `im`). Le premier membre est celui du créateur du groupe et a pour indice 1.

Les _ids_ de chaque membre d'index `im` sont stockés dans `tid[im]`

Les _flags_ de chaque membre d'index `im` sont stockés dans `flags[im]`

## États _contact / actif / inconnu_
### Disparu
C'est un _ex membre_ qui a eu une existence et qui s'est auto-résilié ou dont le GC a détecté son absence.
- il avait un indice `im`: 
  - `flags[im]` vaut 0.
  - s'il n'a pas jamais eu _accès aux notes_, `tid[im]` est `0`, l'indice `im` est réutilisable.
  - sinon il faut prévenir la réutilisation de l'indice: `tid[im]` vaut `1` par convention.
- il n'a plus de sous-documents `membres`, dans le groupe on ne connaît plus, ni son nom, ni l'id de son avatar.
- son id ne figure plus dans les listes noires.

### Oublié
C'est un _ex membre_ qui a eu une existence et qui a fait l'objet d'une demande _d'oubli_ par le compte lui-même et dans certains cas par un animateur.
- il avait un indice `im`:
  - `flags[im]` vaut 0.
  - s'il n'a pas jamais eu _accès aux notes_ et n'est pas en _liste noire_, `tid[im]` est `0`, l'indice `im` est réutilisable.
  - sinon il faut prévenir la réutilisation de l'indice: `tid[im]` vaut `1` par convention.
- il n'a plus de sous-documents `membres`, dans le groupe on ne connaît plus, ni son nom, ni l'id de son avatar.
- **son id peut encore figurer dans les listes noires.**

### Contact
Quand um membre est un _contact_:
- il a un indice `im` et des flags associés.
- il a un document `membres` identifié par `[idg, im]` qui va donner sa clé et sa carte de visite.
- il est connu dans `groupes` dans `tid` à l'indice `im`.
- il peut avoir des flags dans `flags[im]`
- **son compte ne le connaît pas**, il n'a pas le groupe dans sa liste de groupes.

### Contact invité
Un _contact_ peut avoir une _invitation_ en cours déclarée par un animateur (ou tous):
- son avatar connaît cette invitation qui est stockée dans la map `invits` de son document `avatars`.
- une invitation n'a pas de date limite de validité.
- une invitation peut être annulée par un animateur ou l'avatar invité lui-même.
- il a au moins le flag [IN] dans `flags[im]`

### Actif
Quand un membre est _actif_:
- son indice `im` et son document `membres` restent ceux qu'il avait quand il était _contact_.
- **son compte le connaît**, son compte a le groupe dans sa liste de groupes `mpg`,
- le compte peut décider de redevenir _contact_, voire d'être _oublié_ du groupe (et devenir _inconnu_).
- un animateur peut supprimer tous les droits d'un membre _actif_ mais il reste _actif_ (bien que très _passif_ par la force des choses).
- il a au moins les flags [AC AH] dans `flags[im]`

> Remarques:
> - Un membre ne devient _actif_ que quand son compte a explicitement **validé une invitation** déclarée par un animateur (ou tous).
> - Un membre _actif_ ne redevient _contact_ que quand lui-même l'a décidé.

### En listes noires
Certains avatars ne devront plus être invités / ré-invités, ils sont en liste noire. La mise en liste noire peut être demandée par un animateur du groupe ou par le membre lui-même lorsqu'il demande à être oublié.

Le membre est en liste noire si son id apparaît dans une des deux listes:
- `lng` : liste noire sur demande du groupe.
- `lnc` : liste noire sur demande du compte.

### `im` attribués ou libres
La règle générale est de ne pas libérer un `im` pour un futur autre membre quand un membre disparaît ou est oublié. Cet indice peut apparaître dans la liste des auteurs d'une note, la ré-attribution pourrait porter à confusion sur l'auteur d'une note.

L'exception est _libérer_ un `im` à l'occasion d'un _oubli_ ou d'une _disparition_ quand **le membre n'a jamais eu accès aux notes en écriture**: son `im` n'a pas pu être référencé dans des notes. `tid[im]` est `0`.

### Table `flags / hists`
- _statut_ :
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

- `hists` : _historique_
  - [HA] **a, un jour, été actif**
  - [HN] **avec accès aux notes**
  - [HM] **avec accès aux membres**
  - [HE] **avec possibilité d'écrire une note**

### Un membre _peut_ avoir plusieurs _périodes d'activité_
- il a été créé comme _contact_ puis a été invité et son invitation validée: il est _actif_.
- il peut demander à redevenir _simple contact_ : il n'accède plus ni aux notes ni aux autres membres, n'est plus hébergeur et souhaite ne plus voir ce groupe _inutile_ apparaître dans sa liste des groupes.
- en tant que _contact_ il peut être ré-invité, sauf s'il s'est inscrit dans la liste noire des avatars à ne pas ré-inviter. Puis il peut valider son invitation et commencer ainsi une nouvelle période d'activité.
- les flags _historiques_ permettent ainsi de savoir, si le membre a un jour été actif et s'il a pu avoir accès à la liste des membres, a eu accès aux notes et a pu en écrire.

#### Réapparition après _oubli_
Après un _oubli_ si l'avatar, non inscrit en liste noire, est de nouveau inscrit comme _contact_, il récupère un nouvel indice #35 par exemple et un nouveau document `membres`, son historique de dates d'invitation, début et fin d'activité sont initialisées. 

C'est une nouvelle vie dans le groupe. Les notes écrites dans la vie antérieure mentionnent toujours l'ancien `im` #12 que rien ne permet de corréler à #35.

## Modes d'invitation
- _simple_ : dans ce mode (par défaut) un _contact_ du groupe peut-être invité par **UN** animateur (un seul suffit).
- _unanime_ : dans ce mode il faut que **TOUS** les animateurs aient validé l'invitation (le dernier ayant validé provoquant l'invitation).
- pour passer en mode _unanime_ il suffit qu'un seul animateur le demande.
- pour revenir au mode _simple_ depuis le mode _unanime_, il faut que **TOUS** les animateurs aient validé ce retour.

Une invitation est enregistrée dans la map `invits` de l'avatar invité:
- _clé_: `idg` id du groupe.
- _valeur_: `{cleGA, cvg, ivpar, dh}` 
  - `cleGA`: clé du groupe crypté par la clé A de l'avatar.
  - `cvG` : carte de visite du groupe (photo et texte sont cryptés par la clé G du groupe)
  - `ivpar` : indice `im` de l'invitant.
  - `dh` : date-heure d'invitation. Le couple `[ivpar, dh]` permet de retrouver l'item dans le chat du groupe donnant le message de bienvenue / invitation émis par l'invitant.

## Hébergement par un membre _actif_
L'hébergement d'un groupe est noté par :
- `imh`: indice membre de l'avatar hébergeur. 
- `idh` : id du **compte** de l'avatar hébergeur. **Cette donnée est cachée aux sessions**.
- `dfh`: date de fin d'hébergement qui vaut 0 tant que le groupe est hébergé. Les notes ne peuvent plus être mises à jour _en croissance_ quand `dfh` existe.

### Prise d'hébergement
- en l'absence d'hébergeur, c'est possible pour,
  - tout animateur,
  - en l'absence d'animateur: tout actif ayant le droit d'écriture, puis tout actif ayant accès aux notes, puis tout actif.
- s'il y a déjà un hébergeur, seul un animateur peut se substituer à condition que le nombre de notes et le V2 actuels ne le mette pas en dépassement de son abonnement.

### Fin d'hébergement par l'hébergeur
- `dfh` est mise la date du jour + 90 jours.
- le nombre de notes et le volume V2 de `comptas` sont décrémentés de ceux du groupe.

Au dépassement de `dfh`, le GC détruit le groupe.

## Data
_data_:
- `id` : id du groupe.
- `v` :  1..N, Par convention, une version à 999999 désigne un **groupe logiquement détruit** mais dont les données sont encore présentes. Le groupe est _en cours de suppression_.
- `dfh` : date de fin d'hébergement.

- `rds` : pas transmis en session.
- `nn qn vf qv`: nombres de notes actuel et maximum attribué par l'hébergeur, volume total actuel des fichiers des notes et maximum attribué par l'hébergeur.
- `idh` : id du compte hébergeur (pas transmise aux sessions).
- `imh` : indice `im` du membre dont le compte est hébergeur.
- `msu` : mode _simple_ ou _unanime_.
  - `null` : mode simple.
  - `[ids]` : mode unanime : liste des indices des animateurs ayant voté pour le retour au mode simple. La liste peut être vide mais existe.
- `tid` : table des ids courts des membres.
- `flags` : tables des flags.
- `hists` : tables des flags historiques.
- `lng` : liste noire _groupe_ des ids (courts) des membres.
- `lnc` : liste noire _compte_ des ids (courts) des membres.
- `cvG` : carte de visite du groupe, textes cryptés par la clé du groupe `{v, photo, info}`.

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
- `idm` : id de l'avatar membre
- `cleAG` : clé A de l'avatar membre cryptée par la clé G du groupe.
- `cvA` : carte de visite du membre `{v, photo, info}`, textes cryptés par la clé A de l'avatar membre.

## Opérations

### Inscription comme contact
- s'il est en liste noire, refus.
- recherche de l'indice `im` dans la table `tid` du groupe pour l'id de l'avatar.
- SI `im` n'existe pas,
  - c'est une première vie OU une nouvelle vie après oubli de la précédente.
  - un nouvel indice `im` lui est attribué en séquence s'il n'y en a pas de libre.
  - un row `membres` est créé.
- SI `im` existe, c'est qu'il était déjà un _contact_.

### Invitation par un animateur
- si son _flag_ indique qu'il est en liste noire, refus.
- choix des _droits_ et inscription dans `invits` de l'avatar.
- vote d'invitation (en mode _unanime_):
  - si tous les animateurs ont voté, inscription dans `invits` de l'avatar.
  - si le vote change les _droits_, les autres votes sont annulés.
- `ddi` est remplie.

### Annulation d'invitation par un animateur
- effacement de l'entrée de l'id du groupe dans `invits` de l'avatar.

### Oubli par un animateur (avec ou sans liste noire)
- inscription éventuelle en liste noire `lng`.
- s'il est _actif_ ou _invité_, refus.
- le document `membres` est détruit.
- s'il n'a jamais eu accès en écriture aux notes son slot `im` est réutilisable `tid[im]` est mis à `null`, sinon il est mis à `true`.

### Refus d'invitation par le compte
- Options possibles:
  - **rester en contact**. les _flags_ sont mis à jour.
  - **m'oublier** et me mettre en liste noire `lnc` ou non.
    - s'il n'a jamais eu accès en écriture aux notes son slot `im` est réutilisable `tid[im]` est mis à `null`, sinon il est mis à `true`.
    - le document `membres` est détruit.
- son item dans `invits` de son avatar est effacé.

### Acceptation d'invitation par le compte
- dans l'avatar principal du compte un item est ajouté dans `mpg`,
- dans `comptas` le compteur `qv.ng` est incrémenté.
- `dac fac ...` sont mises à jour.
- son item dans `invits` de son avatar est effacé.
- flags `AN AM`: accès aux notes, accès aux autres membres.

### Modification des droits par un animateur
- flags `PA DM DN DE`

### Modification des accès membres / notes par le compte
- flags `AN AM`: accès aux notes, accès aux autres membres.

## Fin d'activité dans le groupe demandée par le compte**
- Options possibles:
  - **rester en contact**. les _flags_ sont mis à jour.
  - **m'oublier** et me mettre en liste noire `lnc` ou non.
    - s'il n'a jamais eu accès en écriture aux notes son slot `im` est réutilisable `tid[im]` est mis à `null`, sinon il est mis à `true`.
    - le document `membres` est détruit.
- si le membre était le dernier _actif_, le groupe disparaît.
- la participation au groupe disparaît de `mpg` du compte.

# Documents `Chatgrs`
A chaque groupe est associé **UN** document `chatgrs` qui représente le chat des membres d'un groupe. Il est créé avec le groupe et disparaît avec lui.

_data_
- `id` : id du groupe
- `ids` : `1`
- `v` : sa version.

- `items` : liste ordonnée des items de chat `{id, dh, lg, texte}`
  - `id` : id du membre auteur,
  - `dh` : date-heure d'enregistrement de l'item,
  - `lg` : longueur du texte en clair de l'item. 0 correspond à un item effacé.
  - `texte` : texte (gzippé) crypté par la clé G du groupe.

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

# Data Sync
La mise à jour des documents `espaces partitions comptes comptas` est traquée directement par leur id:
- **en SQL/WebSocket:** 
  - l'objet de session du compte identifié par son `sessionId` détient les id de `espaces` (`ns`), `partitions` (si c'est un compte "O") et de `comptes`.
  - chaque mise à jour envoie le row sur le WebSocket `{_nom, id, v, _data_ }`.
- **en NOSQL:** la session cliente a 4 requêtes `onSnapshot` d'attente d'une mise à jour et reçoit en cas de mise à jour un row `{_nom, id, v, _data_ }` identique à celui reçu sur WebSocket.

**La mise à jour des sous-arbres d'un avatar ou d'un groupe** est traquée par leur `id` sur mise à jour de leur row `versions`. Le processus est identique à celui ci-dessus avec les différences suivantes:
- le row retourné ne porte quasiment rien comme information: `{ _nom ('versions'), id, v, suppr }`
- **en NOSQL** la session cliente a un nombre de requêtes `onSnapshot` variable: plusieurs id peuvent être spécifiées dans une liste mais celle-ci est limitée, nécessitant le cas échéant plusieurs requêtes.

Voir le chapitre **Connexion et Synchronisation**.

# Gestion des disparitions des comptes: `dlv` 

Chaque compte a une **date limite de validité**:
- toujours une _date de dernier jour du mois_ (sauf exception par convention décrite plus avant),
- propriété indexée de son `comptes`.

Le GC utilise le dépassement de dlv pour libérer les ressources correspondantes (notes, chats, ...) d'un compte qui n'est plus utilisé:
- **pour un compte A** la `dlv` représente la limite d'épuisement de son crédit mais bornée à `nbmi` mois du jour de son calcul.
- **pour un compte O**, la `dlv` représente la plus proche de ces deux limites,
  - un nombre de jours sans connexion (donnée par `nbmi` du document `espaces` de l'organisation),
  - la date `dlvat` jusqu'à laquelle l'organisation a payé ses coûts d'hébergement à l'administrateur technique (par défaut la fin du siècle). C'est la date `dlvat` qui figure dans le document `espaces` de l'organisation. Dans ce cas, par convention, c'est la **date du premier jour du mois suivant** pour pouvoir être reconnue.

> Remarque. En toute rigueur un compte "A" qui aurait un gros crédit pourrait ne pas être obligé de se connecter pour prolonger la vie de son compte _oublié / tombé en désuétude / décédé_. Mais il n'est pas souhaitable de conserver des comptes _morts_ en hébergement, même payé: ils encombrent pour rien l'espace.

## Calcul de la `dlv` d'un compte
La `dlv` d'un compte est recalculée à plusieurs occasions.

### Acceptation du sponsoring du compte
Première valeur calculée selon le type du compte.

### Connexion
La connexion permet de refaire les calculs en particulier en prenant en compte de nouveaux tarifs.
- pour un compte "A" c'est à cette occasion que sont intégrés les crédits récoltés par le Comptable.
- pour un compte "O" le changement de `dlvat` est aussi prise en compte.

C'est l'occasion majeure de prolongation de la vie d'un compte.

### Don pour un compte "A": passe par un chat
La `dlv` du _donneur_ est recalculée sur l'instant: si le don est important, la date peut être significativement rapprochée.

Pour le récipiendaire celle-ci est recalculée et prolonge la date.

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
- `dlvat`: date limite de vie des comptes "O", fixée par l'administrateur technique en fonction des contributions effectives reçues de l'organisation pour héberger ses comptes "O".
- `nbmi`: nombre de mois d'inactivité acceptable fixé par le Comptable (3, 6, 9, 12, 18 ou 24). Ce changement n'a pas d'effet rétroactif.

> **Remarque**: `nbmi` est fixé par configuration par le Comptable _pour chaque espace_. C'est une contrainte de délai maximum entre deux connexions à un compte, faute de quoi le compte est automatiquement supprimé. La constante `IDBOBS` fixe elle un délai maximum (2 ans par exemple), _pour un appareil et un compte_ pour bénéficier de la synchronisation incrémentale. Un compte peut se connecter toutes les semaines et avoir _un_ poste sur lequel il n'a pas ouvert une session synchronisée depuis 3 ans: bien que tout à fait vivant, si le compte se reconnecte en mode _synchronisé_ sur **ce** poste, il repartira depuis une base locale vierge, sans bénéficier d'un redémarrage incrémental.

### Changement de `dlvat`
Si le financement de l'hébergement par accord entre l'administrateur technique et le Comptable d'un espace tarde à survenir, beaucoup de comptes O ont leur existence menacée par l'approche de cette date couperet. Un accord tardif doit en conséquence avoir des effets immédiats une fois la décision actée.

Par convention une `dlvat` est fixée au **1 d'un mois** et ne peut pas être changée pour une date inférieure à M + 3 (nbmi ?) du jour de modification.

L'administrateur technique qui remplace une `dlvat` le fait en plusieurs transactions pour toutes les `dlv` des `comptes` égales à l'ancienne `dlvat`. La transaction finale fixe aussi la nouvelle `dlvat`. La valeur de remplacement est,
- la nouvelle `dlvat` (au 1 d'un mois) si elle est inférieure à `auj + nbmi mois`: c'est encore la `dlvat` qui borne la vie des comptes O (à une autre borne).
- sinon la fixe à `auj + nbmi mois` (au dernier jour d'un mois), comme si les comptes s'étaient connectés aujourd'hui.

_Remarque_: idéalement une transaction unique aurait été préférable mais elle pourrait être longue et entraînerait des blocages.

# Opérations GC
## `GCfvc` - Étape _fin de vie des comptes_
Suppression des comptes dont la `dlv` est inférieure à la date du jour.

La suppression d'un compte est en partie différée:
- ses avatars ont une version v à 999999,
- les groupes dont le nombre de membres actifs devient 0, ont leur version à 999999.

## `GCpav` - Étape _purge des avatars logiquement supprimés_
Pour chaque avatar dont la version est 999999, gestion des chats et purge des sous-documents `chats sponsoring notes avatars` et finalement du document `avatars` lui-même.

## `GCHeb` - Étape _fin d'hébergement_
Récupération des groupes dont la `dfh` est inférieure à la date du jour et suppression logique (version à 999999).

## `GCpgr` - Étape _purge des groupes logiquement supprimés_
Pour chaque groupe dont la version est 999999, gestion des invitations et participations puis purge des sous-documents **notes membres chatgrs** et finalement du document `groupes` lui-même

### `GCFpu` : traitement des documents `fpurges`
L'opération récupère tous les items d'`id` de fichiers depuis `fpurges` et déclenche une purge sur le Storage.

Les documents `fpurges` sont purgés.

### `GCTra` : traitement des transferts abandonnés
L'opération récupère toutes les documents `transferts` dont les `dlv` sont antérieures ou égales à aujourd'hui.

Le fichier `id / idf` cité dedans est purgé du Storage des fichiers.

Les documents `transferts` sont purgés.

### `GCspo` : purge des sponsorings obsolètes
L'opération récupère toutes les documents `sponsorings` dont les `dlv` sont antérieures à aujourd'hui. Ces documents sont purgés.

### `GCstc` : création des statistiques mensuelles des `comptas` et des `tickets`
La boucle s'effectue pour chaque espace:
- `comptas`: traitement par l'opération `ComptaStat` pour récupérer les compteurs du mois M-1. 
  - Le traitement n'est déclenché que si le mois à calculer M-1 n'a pas déjà été enregistré comme fait dans `comptas.moisStat` et que le compte existait déjà à M-1.
- `tickets`: traitement par l'opération `TicketsStat` pour récupérer les tickets de M-3 et les purger.
  - Le traitement n'est déclenché que le mois à calculer M-3 n'a pas déjà été enregistré comme fait dans `comptas.moisStatT` et que le compte existait déjà à M-3.
  - une fois le fichier CSV écrit en _storage_, les tickets de M-3 et avant sont purgés.

**Les fichiers CSV sont stockés en _storage_** après avoir été cryptés par la clé E de l'espace.

Les statistiques sont doublement accessibles par le Comptable ET l'administrateur technique du site.

## Lancement global quotidien
Le traitement enchaîne les étapes ci-dessus, en asynchronisme de la requête l'ayant lancé.

En cas d'exception dans une étape, une relance est faite après un certain délai afin de surmonter un éventuel incident sporadique.

> Remarque : le traitement du lendemain est en lui-même une reprise.

> Pour chaque opération, il y a N transactions, une par document à traiter, ce qui constitue un _checkpoint_ naturel fin.

# Décomptes des coûts et crédits

> **Remarque**: en l'absence d'activité d'une session la _consommation_ est nulle, alors que le _coût d'abonnement_ augmente à chaque seconde même sans activité.

On compte **en session** les downloads / uploads soumis au _Storage_.

On compte **sur le serveur** le nombre de lectures et d'écritures effectués dans chaque opération et **c'est remonté à la session** où:
- on décompte les 4 compteurs depuis le début de la session (ou son reset volontaire après enregistrement au serveur du delta par rapport à l'enregistrement précédent).
- on envoie les incréments des 4 compteurs de consommation par l'opération `EnregConso` toutes les PINGTO2 (dans `api.mjs`) minutes.
  - pas d'envoi s'il n'y a pas de consommation à enregistrer mais en mode _serveur_ (SQL) envoi quand même au bout d'une demi-heure à titre de _heartbeat_.

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

### Propriété `ticketsK`
Cettea propriété n'existe dans `comptas` que pour un compte A: elle est cryptée par la clé K du compte qui est seul à y accéder et est la liste des tickets générés par le compte.

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

### Sponsoring d'un compte "O"
Rien de particulier : `compteurs` est initialisé. Sa consommation est nulle, de facto ceci lui donne une _avance_ de consommation moyenne d'au moins un mois.

### Sponsoring d'un compte "A"
`compteurs` est initialisé, sa consommation est nulle mais il bénéficie d'un _total_ minimal pour lui laisser le temps d'enregistrer son premier crédit.

Dans `comptas` on trouve:
- un `solde` de 2 centimes.
- une liste `ticketsK` vide.

# Annexe I: déclaration des index

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

`id` est indexée dans `fpurges` qui n'a pas de version `v` et dont l'`id` doit être indexée pour filtrage par l'utilitaire `export/delete`.

Dans les sous-collections versionnées `notes chats membres sponsorings tickets`: `id ids v` sont indexées. 

Pour `sponsorings` `ids` sert de clé d'accès direct et a donc un index **collection_group**, pour les autres l'index est simple.

Dans la sous-collection non versionnée `transferts`: `id ids` sont indexées mais pas `v` qui n'y existe pas.

`dlv` est indexée,
- simple sur `versions`,
- **collection_group** sur les sous-collections `transferts sponsorings membres`.

Autres index:
- `hXR` sur `comptas`: accès à la connexion par phrase secrète.
- `hYR` sur `avatars`: accès direct par la phrase de contact.
- `dfh` sur `groupes`: détection par le GC des groupes sans hébergement.

# Annexe II: IndexedDB dans les session UI

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

# Annexe III : Connexion et Synchronisation

## L'objet DataSync
Cet objet sert:
- entre session et _serveur / Cloud Function_ a obtenir les documents resynchronisant la session avec l'état de la base.
- dans la base locale: à indiquer ce qui y est stocké et dans quelle version.

**Les états successifs _de la base_ sont toujours cohérents**: _tous_ les documents de _chaque_ périmètre d'un compte sont cohérents entre eux.

### État courant d'une session
Cet état en mémoire et le cas échéant base locale, est consigné dans un objet `DataSync`.

Dans cet état **chaque sous-arbre** d'un avatar ou d'un groupe du périmètre du compte est cohérent en lui-même, la mise à jour d'un sous-arbre a été assurée par une transaction: à chaque `id` d'un sous-arbre correspond une version `vs` (version session) qui est un cliché d'un état cohérent qui a existé (voire existe encore) en base centrale.

Chaque opération de remise à niveau de cet état est _partielle_ et concerne:
- les 4 documents `comptes espaces partitions comptas`,
- facultativement **UN** sous-arbre d'avatar ou de groupe cité par son id,
- retourne le `DataSync` image de l'état après ces mises à jour.

Cette image est dite _cohérente_ quand les versions des 4 documents et de tous les sous-arbres ont été relevées dans les compteurs `vc` au cours d'une transaction `Sync` avec **option C**: la date-heure _serveur_ a été également relevée (à titre informatif).

Au fil de l'eau une session reçoit des avis de mises à jour des 4 documents et des sous-arbres. En les appliquant systématiquement elle va _tendre_ à être _cohérente_, ses remises à niveaux vont _rattraper_ l'état de la base, mais il n'est pas possible de savoir si un état courant de DataSync **est** cohérent, ou **en transition vers** un état cohérent, sauf à demander à une transaction avec **option C** de le déterminer.


### Objet `DataSync`
Quintuplet `sync` : `{ id, rds, vs, vc, vb }`
- `id` : du document
- `rds` : du document.
- `vs` : version détenue par la session du document (comptes comptas espaces partitions) ou du sous-arbre (avatar et groupe).
- `vb` : version actuelle détenue en base.
- `vc` : version obtenue lors de la dernière transaction avec option C.

- `dh` : dernière date-heure d'évaluation par le serveur.
- `dhc` : date-heure de la dernière transaction avec option C.
- `compte` : son `sync`
- `compta` : son `sync`
- `espace` : son `sync`
- `partition` : son `sync` si c'est un compte "O"
- `avatars` : map de _clé_ id de l'avatar et de _valeur_ son `sync`.
- `groupes` : map de _clé_ id groupe et de _valeur_ son `sync`.

### Opération `Sync`
La session poste des _opérations de synchronisation_ `Sync` avec en argument,
- `optionC` ou non.
- `ida` (facultative) du sous-arbre à synchroniser.
- son `dataSync` actuel.

Une opération `Sync` ne retourne les mises à jour que d'un sous-périmètre puisque au plus UN sous-arbre peut être cité.

> Remarque: quand un compte n'a qu'un avatar et pas d'accès à des groupes, ce _sous-périmètre_ est le _périmètre_ complet.

Elle récupère les versions requises et les documents dont la version en base est supérieure à celle connue en session.

Avec `optionC` elle **interroge** les versions de **tous** les sous-arbres et les notent en `vc` dans l'objet `dataSync` avec le date-heure `dhc`.
- l'état en session peut être **incomplet**, les versions `vs` étant différentes des versions `vb`.

En _mode WebSocket_ l'opération inscrit tous les ids des documents / sous-arbres du périmètre auprès de la session WebSocket du compte.

La réponse comporte:
- **le `dataSync` mis à jour**. Par convention une version de base à -1, signifie _devenu hors périmètre_:
  - pour un groupe ou un avatar, le sous-arbre n'est plus référencé dans le document `comptes`.
  - pour `partitions`, le compte n'est plus un compte "O". Remarque: si le compte "O" a changé de délégué à NON délégué, l'objet mis à jour est significativement différent.
- les documents CCEP `comptes comptas espaces partitions`, pour ceux dont la version est différente de celle citée en `vs`.
- **des listes de sous-documents _manquants / mis à jour_**, une liste par type de document. 

#### Traitement en retour en session
Sont initialisées à vide :
- une liste de mises à jour de la base,
- une _mémoire tampon_ des documents non compilés.

**Premier appel `Sync` de la session**
Il peut y avoir sortie en exception sur échec d'authentification.

Le `dataSync` joint à la requête étant vide, les documents CCEP sont toujours présents: ils sont mis en _mémoire tampon_. 

Le document `comptes` est compilé,
- la clé K est décryptée depuis la phrase secrète de la session.
- en mode _synchronisé_,
  - si la base locale n'existait pas elle est créée.
  - l'item de _boot_ de la base locale est réécrit si la clé secrète a changé. 
- le `dataSync` de la base locale, s'il y en a un, est lu, décrypté et _fusionné_ avec celui de retour de `Sync`.

**Le traitement en session consiste ensuite à :**
- remplit la liste de mises à jour de la base.
  - à supprimer : les sous-arbres devenus hors-périmètre.
  - à supprimer : le document `partitions` si le compte n'est plus "O".
  - à ajouter : les documents CCEP apparus comme modifiés.
- **enregistre les mises à jour dans la base locale**, avec le dataSync et en une seule transaction.
- **si _NON WebSocket_ se met à l'écoute des mises à jour**:
  - si c'est le premier appel, de tous les documents et sous-arbres,
  - sinon: 
    - des nouveaux **sous-arbres** avatar et groupe apparus dans le périmètre, 
    - du nouveau document `partitions` en cas de changement de partition ou changement de type O/A,
- `compilation` des documents en _mémoire tampon_,
- **mise à jour des _stores_ des documents compilés** en une séquence sans interruption (sans `await`) afin que la vison graphique soit cohérente.

## Phases de connexion
!!! Liste des fichiers ayant une copie locale à synchroniser. !!!

### Mode _avion_
Phase unique:
- lecture de l'item de _boot_ de la base locale:
  - il permet d'authentifier le compte (et d'acquérir sa clé K),
  - lecture du `dataSync` de la base locale,
- mise en _mémoire tampon compilée_ depuis la base locale,
  - des documents CCEP.
  - des documents des sous-arbres.
- **mise à jour des _stores_ des documents compilés** en une séquence sans interruption (sans `await`) afin que la vison graphique soit cohérente.

### Mode _synchronisé_ et _incognito_
Le traitement de synchronisation au fil de l'eau est _suspendu_:
- il peut recevoir des avis de mise à jour dès maintenant,
- ces avis sont stockés dans la queue des mises à jour mais le traitement qui épuise cette queue n'est pas activé.

#### Première phase 
Elle consiste à soumettre une opération `Sync` avec `optionC` et un `datasync` vide. Voir ci-dessus que le traitement en retour est spécifique pour un premier appel Sync de la session.

#### Seconde phase 
L'état de `dataSync` est considérée comme une file d'attente de traitements successifs : pour chaque sous-arbre `ida` dont la version `vs` en `dataSync` est inférieure à leur version `vb`, soumission d'une opération `Sync` **sans** `optionC` et **avec** `ida`.

#### Phase finale
Ouverture du traitement de synchronisation au fil de l'eau.

## Synchronisation au fil de l'eau
Au fil de l'eau il parvient des notifications de mises à jour de _versions_. 

Une table _queue de traitements_ mémorise pour chaque document CCEP et sous-arbre, son `rds` et la version notifiée par l'avis de mise à jour. Elle regroupe ainsi des événements survenus très proches.

Les avis de mises à jour dont la version est inférieure ou égale à la version déjà détenue dans les _stores_ de la session, sont ignorés.

### Itération pour vider cette queue
Tant qu'il reste des traitements à effectuer, une opération `Sync` est soumise, sans `optionC`.
- le `dataSync` est celui courant,
- L'id du sous-arbre est:
  - `0` si l'avis de changement concerne un des documents CCEP.
  - `ida`, l'id du sous-arbre si la notification correspond à un sous-arbre.

Le traitement standard de retour,
- met la base locale en une transaction,
- met à jour les _store_ de la session sans interruption (sans `await`).

## Partition courante d'un Comptable
Une session Comptable peut parcourir toutes les partitions et pas seulement la sienne (#1).
- à un instant donné il peut avoir une _partition courante_ d'id non 1, celle qu'il consulte et met à jour.
- la session soumet une requête `GetPartitionC` et récupère le document `comptas` (ou pas). Voir ci-après.
  
Traitement du document partitions reçus:
- mise à jour du _store_ en mémoire.
- en mode _WebSocket_ SON abonnement spécifique `partitionC` référence le `rds` de cette partition. La session en recevra donc en plus l'avis de mise à jour par `versions`.
- en mode _NON WebSocket_ la session déclenche un `onSnapshot` spécifique pour `partitionC` (il peut changer souvent).
- dans les deux cas _pour la session émettrice_ l'avis de mise à jour devrait parvenir _après_ que le document `partitions` ait été enregistré dans le _store_ mémoire, son traitement sera ignoré.

## Le document `comptas` d'une session change quasiment à chaque opération
Une opération fait en général une lecture MAIS pas obligatoirement: si le document demandé est obtenu de la Cache du _serveur_ la consommation est nulle. Dans ce dernier cas:
- le document `comptas` n'est pas mis à jour et n'est PAS retourné par l'opération puisqu'inchangé.

**Si l'opération a eu au moins une consommation** et si l'espace n'est pas figé, le document `comptas` retourné en résultat est inscrit dans la _queue de traitement_: il sera intégré un peu plus tard de manière consistante en base locale et état mémoire.

**Quand l'espace est figé**, les mises à jour en base sont strictement prohibées: les consommations ne sont PAS enregistrées (cadeau). Cette situation a pour vocation à être transitoire le temps d'un export de la base et du _storage_.

## Bouton d'information de _cohérence_
Au fil de l'eau, savoir si l'état est cohérent ou non est coûteux en accès aux versions des sous-arbres (même si en général seul l'index est sollicité), mais surtout a très peu d'intérêt pratique.

L'information d'un état _incomplet_ est plus intéressante et s'affiche comme un voyant: c'est temporaire et n'apparaît qu'entre les phases 2-A et finale (pendant les phases 2-B).

La vérification de _cohérence_ consiste à lancer une phase 2-A / 2-B de synchronisation au fil de l'eau, mais avec une `optionC` sur le `Sync` initial.
- rien ne garantit qu'à la fin de la phase finale, de nouvelles mises à jour ne seront pas apparues depuis le début du traitement et que l'état _final_ soit _cohérent_.
- on peut certes reboucler, mais avec beaucoup de sous-arbres très sollicités,
  - en théorie ça peut ne jamais se terminer,
  - cet état ne dure que jusqu'à arrivée d'un avis d'une mise à jour du périmètre, soit en général pas bien longtemps pour un périmètre très actif.

Cette opération n'a de sens pratique que,
- si on interrompt volontairement la synchronisation pendant la recherche d'un état cohérent,
- qu'on retombe en mode _avion_ ou qu'on se déconnecte dès cet état atteint.

# Purgatoire
## Clé RSA d'un avatar
La clé de cryptage (publique) et celle de décryptage (privée) sont de longueurs différentes. 

Le résultat d'un cryptage a une longueur fixe de 256 bytes. Deux cryptages RSA avec la même clé d'un même texte donnent deux valeurs cryptées différentes.

@@ L'application UI [uiapp](./uiapp.md)

# Contributions

## Documents d'un compte: `compte compta compti`
### `compte` 
- identification, clé K, rds, hash de phrase secrète
- id de sa partition pour un compte O et sa clé clePK.
- mav / mpg

**Synchronisé par son `rds`:**
- évite la possibilité d'interprétation des fréquences de changements par un autre compte que le titulaire.
- oblige à deux écritures en cas de maj.
- _lecture_ seulement par l'opération `Sync`.

**Retourné à la session à chaque opération l'ayant mis à jour** (anticipation de synchronisation).

_data_ :
- `id` : numéro du compte = id de son avatar principal.
- `v` : 1..N.
- `hXR` : `ns` + `hXR`, hash du PBKFD d'un extrait de la phrase secrète.
- `dlv` : dernier jour de validité du compte.

- `rds` : `null` en session.
- `hXC`: hash du PBKFD de la phrase secrète complète (sans son `ns`).
- `cleKXC` : clé K cryptée par XC (PBKFD de la phrase secrète complète).
- `cleEK` : clé de l'espace cryptée par la clé K du compte, à la création de l'espace pour le Comptable. Permet au comptable de lire les reports créés sur le serveur et cryptés par cette clé E.
- `privK` : clé privée RSA de son avatar principal cryptée par la clé K du compte.

- `dhvuK` : date-heure de dernière vue des notifications par le titulaire du compte, cryptée par la clé K.
- `qv` : `{ qc, qn, qv, pcc, pcn, pcv, nbj }`
  - `pcc, pcn, pcv, nbj` : remontés de `compta` en fin d'opération quand l'un d'eux passe un seuil de 5% / 5j, à la montée ou à la descente.
    - `pcc` : pour un compte O, pourcentage de sa consommation mensualisée sur M/M-1 par rapport à son quota `qc`.
    - `nbj` : pour un compta A, nombre de jours estimés de vie du compte avant épuisement de son solde en prolongeant sa consommation des 4 derniers mois et son abonnement `qn qv`.
    - `pcn` : pourcentage de son volume de notes / chats / groupes par rapport à son quota qn.
    - `pcv` : pourcentage de son volume de fichiers par rapport à son quota qv.
  - `qc qn qv` : maj immédiate en cas de changement des quotas.
    - pour un compte O identiques à ceux de son entrée dans partition.
    - pour un compte A, qn qv donné par le compte lui-même.
    - en cas de changement, les compteurs de consommation sont remontés. 
  - permet de calculer `notifQ`, `notifX` (O), `notifS` (A)

_Comptes "O" seulement:_
- `clePK` : clé P de la partition cryptée par la clé K du compte. Si cette clé a une longueur de 256, la clé P a été cryptée par la clé publique de l'avatar principal du compte suite à une affectation à une partition APRÈS sa création (changement de partition, passage de compte A à O)
- `idp` : id de la partition (son numéro).
- `del` : `true` si le compte est délégué de la partition.
- `notif`: notification de niveau _compte_ dont le texte est crypté par la clé P de la partition (`null` s'il n'y en a pas).

- `mav` : map des avatars du compte. 
  - _clé_ : id court de l'avatar.
  - _valeur_ : `{ rds, claAK }`
    - `rds`: de l'avatar (clé d'accès à son `versions`). `null` en session.
    - `cleAK`: clé A de l'avatar crypté par la clé K du compte.

- `mpg` : map des participations aux groupes:
  - _clé_ : id du groupe
  - _valeur_: `{ rds, cleGK, lav }`
    - `rds`: du groupe (clé d'accès à son `versions`). `null` en session.
    - `cleGK` : clé G du groupe cryptée par la clé K du compte.
    - `lav`: liste de ses avatars participant au groupe.

**Comptable seulement:**
- `tpK` : table des partitions cryptée par la clé K du Comptable `[ {cleP, code }]`. Son index est le numéro de la partition.
  - `cleP` : clé P de la partition.
  - `code` : code / commentaire court de convenance attribué par le Comptable

### `compta`
**Ce document est lu à chaque début d'opération et mis à jour par l'opération.**
- si ses compteurs `pcc, pcn, pcv, nbj` _ont changé d'ordre de grandeur_ (5% / 5j) ils sont reportés dans le document `compte`: de ce fait ce dernier ne devrait, statistiquement, n'être mis à jour que rarement en fin d'opération.

**Non synchronisé:**
- lecture à la demande par les sessions, vérification de qui demande (compte, Comptable, un délégué).
- maj à chaque opération.
- répercussion éventuelle mais rare en fin d'opération sur compte.
- **retourné à la session** à chaque opération (pour information): ceci évite aussi une relecture explicite inutile dans une session.

_data_:
- `id` : numéro du compte = id de son avatar principal.
- `v` : 1..N.
- `qv` : `{qc, qn, qv, nn, nc, ng, v}`: quotas et nombre de groupes, chats, notes, volume fichiers. Valeurs courantes.
- `compteurs` sérialisation des quotas, volumes et coûts.
- _Comptes "A" seulement_
  - `solde`: résultat, 
    - du cumul des crédits reçus depuis le début de la vie du compte (ou de son dernier passage en compte A), 
    - plus les dons reçus des autres,
    - moins les dons faits aux autres.
  - `tickets`: map des tickets / dons:
    - _clé_: `ids`
    - _valeur_: `{dg, iddb, dr, ma, mc, refa, refc, di}`
  - `dons` : liste des dons effectués / reçus
    - `dh`: date-heure du don
    - `m`: montant du don (positif ou négatif)
    - `iddb`: id du donateur / bénéficiaire (selon le signe de `m`).

### `compti`
Information personnelle / commentaires à propos des avatars et groupes connus du compte.

**Synchronisé par rds du compte:** _lecture_ seulement par `Sync`.

_data_:
- `id` : id du compte.
- `v` : version.

- `mc` : map à propos des contacts (des avatars) et des groupes _connus_ du compte,
  - _cle_: `id` court de l'avatar ou du groupe,
  - _valeur_ : `{ ht, tx }`.
    - `ht` : liste des hashtags séparés par un espace attribués par le compte et cryptée par la clé K du compte.
    - `tx` : commentaire écrit par le compte gzippé et crypté par la clé K du compte.

## Sous-arbres avatar / groupe
Synchronisés par `rds` de l'avatar / groupe
- évite une analyse de trafic de maj par des comptes autres que le compte lui-même.
- _lecture_ par `Sync` uniquement:
  - sauf sponsorings qui peut être lu par un compte en création (par se clé de sponsoring).

## Documents `partitions` des partitions d'un espace
Une partition est créée par le Comptable qui peut la supprimer quand il n'y a plus de comptes attachés à elle. 
- L'identifiant d'une partition est un numéro d'ordre de 1 à N attribué en séquence par le Comptable à sa création.

**La clé P d'une partition** sert uniquement à crypter les textes des notifications de niveau partition ou relatif à un compte.
- elle est générée à la création de la partition,
- elle est transmise aux comptes rattachés qui la détiennent dans la propriété `clePK`,
  - soit à leur création par sponsoring : elle est cryptée par la clé K du compte créé.
  - soit quand le compte change de partition (par le Comptable) ou passe de compte "A" à compte "O" par un délégué ou le Comptable: elle est cryptée par la clé publique RSA du compte.

**Un document partition est explicitement demandé** (pas d'abonnement) par une session,
- soit du Comptable,
- soit d'un délégué.
- un compte non délégué n'a pas accès au document de sa partition: il ne peut que demander au serveur la liste des `cleA` des délégués (donc leur ids) ce qui lui permet de les contacter pour un _chat d'urgence_.

**Toute opération engagée par le Comptable ou un délégué** retourne la partition mise à jour. Ces opérations sont:
- attachement / détachement d'un compte.
- attribution / retrait de son statut de délégué.
- pose / retrait d'une notification de niveau P ou C (pour un seul compte). La notification C est dans le compte mais son `nr` figure ici, la notification P figure dans espaces mais son `nr` est répliqué dans `partitions`.
- modification des quotas globaux de la partition.
- modification des quotas attribués à un compte.

#### Incorporation des consommations des comptes
Les compteurs de consommation d'un compte extraits de `comptas` sont recopiés à l'occasion de la fin d'une opération:
- dans les compteurs `{ qc, qn, qv, pcc, pcn, pcv, nbj }` du document `comptes`,
- dans les compteurs `q: { qc qn qv c2m nn nc ng v }` de l'entrée du compte dans son document `partitions`.
  - par conséquence la ligne de synthèse de sa partition est reportée dans l'élément correspondant de son document `syntheses`.
- afin d'éviter des mises à jour trop fréquentes, la procédure de report n'est engagée qui si les compteurs `pcc pcn pcv` passe un cap de 5% ou que `nbj` passe un cap de 5 jours.

> **Remarque**: la modification d'un compteur de quotas `qc qn qv` provoque cette procédure de report `comptas / comptes / partitions / syntheses` sans effet de seuil. 

> Il en est de même quand le **niveau de restriction des notifications P C Q X** change.

_data_:
- `id` : numéro de partition attribué par le Comptable à sa création.
- `v` : 1..N

- `nrp`: niveau de restriction de la notification (éventuelle) de niveau _partition_ mémorisée dans `espaces` et dont le texte est crypté par la clé P de la partition.
- `q`: `{ qc, qn, qv }` quotas globaux attribués à la partition par le Comptable.
- `mcpt` : map des comptes attachés à la partition. 
  - _clé_: id du compte.
  - _valeur_: `{ nr, cleA, del, q }`
    - `nr`: niveau de restriction de la notification de niveau _compte_ (0 s'il n'y en a pas, 1 (sans restriction), 2 ou 3).
    - `notif`: notification du compte cryptée par la clé P de la partition (redonde celle dans compte).
    - `cleAP` : clé A du compte crypté par la clé P de la partition.
    - `del`: `true` si c'est un délégué.
    - `q` : `qc qn qv c2m nn nc ng v` extraits du document `comptas` du compte.
      - `c2m` est le compteur `conso2M` de compteurs, montant moyen _mensualisé_ de consommation de calcul observé sur M/M-1 (observé à `dhic`). 

`mcpt` compilé - Ajout à `q` :
  - `pcc` : pourcentage d'utilisation de la consommation journalière `c2m / qc`
  - `pcn` : pourcentage d'utilisation effective de qn : `nn + nc ng / qn`
  - `pcv` : pourcentage d'utilisation effective de qc : `v / qv`

**Un objet `synth` est calculable** (en session ou dans le serveur):
- `qt` : les totaux des compteurs `q` : (`qc qn qv c2m n (nn+nc+ng) v`) de tous les comptes,
- `ntf`: [1, 2, 3] - le nombre de comptes ayant des notifications de niveau de restriction 1 / 2 / 3. 
- `nbc nbd` : le nombre total de comptes et le nombre de délégués.
- _recopiés de la racine dans `synth`_ : `id nrp q`
- plus, calculés localement :
  - pcac : pourcentage d'affectation des quotas : qt.qc / q.qc
  - pcan : pourcentage d'affectation des quotas : qt.qn / q.qn
  - pcav : pourcentage d'affectation des quotas : qt.qv / q.qv
  - pcc : pourcentage d'utilisation de la consommation journalière qt.c2m / q.qc
  - pcn : pourcentage d'utilisation effective de qn : qt.n / q.qn
  - pcv : pourcentage d'utilisation effective de qc : qt.v / q.qv

## Document `synthese` d'un espace
Ce document est identifié par le ns de son espace. Il est demandé explicitement,
- soit par l'administrateur technique,
- soit par le Comptable.

_data_:
- `id` : ns de son espace.
- `v` : date-heure de dernière mise à jour (à titre informatif).

- `tsp` : table des _synthèses_ des partitions.
  - _index_: numéro de la partition.
  - _valeur_ : `synth`, objet des compteurs de synthèse calculés de la partition.
    - `id nbc nbd`
    - `ntfp[1,2,3]`
    - `q` : `{ qc, qn, qv }`
    - `qt` : { qc qn qv c2m n v }`
    - `ntf[1,2,3]`
    - `pcac pcan pcav pcc pcn pcv`

Une agrégation des `synth[i]` est calculée en session et stockée en `tsp[0]`.

Le document `syntheses` est mis à jour à chaque fois qu'un document partition l'est: le `synth` de la partition est simplement reporté dans l'élément d'indice correspondant de `tsp`. En cas de suppression d'une partition son entrée est supprimée.

## Documents `espaces`
Ce document est créé par l'administrateur technique à l'occasion de la création de l'espace et du Comptable correspondant.

**Il est _synchronisé_: **
- à chaque mise à jour d'un document `espaces` le document `versions` **de même id** porte la nouvelle version.
- en session en mode _Firestore_ l'écoute `onSnapshot` du document `versions` portant l'id de l'espace permet d'être notifié de son évolution.
- la lecture effective du document vérifie l'habilitation à sa lecture et ne transmet que les propriétés autorisées.
- le fait de ne pas recours à un `rds` différent de l'id:
  - simplifie la procédure de synchronisation.
  - si une session _malicieuse_ se met à l'écoute de versions autres que celles de son espace, elle obtient une information sur la fréquence de mise à jour des autres espaces (très faible), sans pouvoir accéder à leurs contenus (soit une donnée de très faible intérêt).

**Les sessions sont systématiquement synchronisées à _leur_ espace:**
- **elles sont ainsi informées à tout instant d'un changement de notification E de l'espace et P de leur partition**. 
  - Dans le cas _Firestore_ ceci se fait par lecture _onSnapshot_ de la collection `espaces`, filtrée par l'id de l'espace.
- **elles sont informées des notifications C (pour un compte O), Q et X par synchronisation à leur compte:**
  - les notifications de quota / consommation (Q et X) proviennent de dépassement de seuils de pourcentage (`pcn pcv` pour Q, `pcc nbj` pour X) qui remontent de `compta` à `compte` lors de franchissement de seuils (pas à chaque opération).

_data_ :
- `id` : de l'espace de 10 à 89.
- `v` : 1..N
- `org` : code de l'organisation propriétaire.

- `creation` : date de création.
- `moisStat` : dernier mois de calcul de la statistique des comptas.
- `moisStatT` : dernier mois de calcul de la statistique des tickets.
- `nprof` : numéro de profil d'abonnement.
- `dlvat` : `dlv` de l'administrateur technique.
- `cleES` : clé de l'espace cryptée par la clé du site. Permet au comptable de lire les reports créés sur le serveur et cryptés par cette clé E.
- `notifE` : notification pour l'espace de l'administrateur technique. Le texte n'est pas crypté.
- `notifP` : pour un délégué, la notification de sa partition.
- `opt`: option des comptes autonomes.
- `nbmi`: nombre de mois d'inactivité acceptable pour un compte O fixé par le comptable. Ce changement n'a pas d'effet rétroactif.
- `tnotifP` : table des notifications de niveau _partition_.
  - _index_ : id (numéro) de la partition.
  - _valeur_ : notification (ou `null`), texte crypté par la clé P de la partition.

Remarques:
- `opt nbmi` : sont mis à jour par le Comptable. `opt`:
  - 0: 'Pas de comptes "autonomes"',
  - 1: 'Le Comptable peut rendre un compte "autonome" sans son accord',
  - 2: 'Le Comptable NE peut PAS rendre un compte "autonome" sans son accord',
- `tnotif` : mise à jour par le Comptable et les délégués des partitions.

**Propriétés accessibles :**
- administrateur technique : toutes de tous les espaces.
- Comptable : toutes de _son_ espace.
- Délégués : sur leur espace seulement,
  - `id v org creation notifE opt`
  - la notification de _leur_ partition est recopiée de tnotifP[p] en notifP.
- Autres comptes: pas d'accès.

**Au début de chaque opération, l'espace est lu afin de vérifier la présence de notifications E et P** (éventuellement restrictives) de l'espace et de leur partition (pour un compte O):
- c'est une lecture _lazy_ : si l'espace a été trouvé en cache et relu depuis la base depuis moins de 5 minutes, on l'estime à jour.
- en conséquence, _quand il y a plusieurs serveurs en parallèle_, la prise en compte de ces notifications n'est _certaine_ qu'au bout de 5 minutes.

### `dlvat nbmi`
L'administrateur technique gère une `dlvat` pour l'espace : 
- c'est la date à laquelle l'administrateur technique détruira les comptes. Par défaut elle est fixée à la fin du siècle.
- l'administrateur ne peut pas (re)positionner une `dlvat` à moins de `nbmi` mois du jour courant afin d'éviter les catastrophes de comptes supprimés sans que leurs titulaires n'aient eu le temps de se reconnecter.

L'opération de mise à jour d'une `dlvat` est une opération longue du fait du repositionnement des `dlv` des comptes égales à la `dlvat` remplacée:
- cette mise à jour porte sur le document `comptes`.
- elle s'effectue en N opérations enchaînées. Au pire en cas d'incident en cours, une partie des comptes auront leur `dlv` mises à jour et pas d'autres: l'administrateur technique relance manuellement l'opération en surveillant sa bonne exécution complète.

**Le maintien en vie d'un compte en l'absence de connexion** a le double inconvénient, 
- d'immobiliser des ressources peut-être pour rien,
- d'augmenter les coûts d'avance sur les frais d'hébergement.

Le Comptable fixe en conséquence un `nbmi` (de 3, 6, 12, 18, 24 mois),
- évitant de contraindre les comptes à des connexions fréquentes rien que pour maintenir le compte en vie, 
- évitant que les comptes oublient de le faire et se voient automatiquement résiliés après un délai trop bref de non utilisation de leur compte.

> Il n'y a aucun moyen dans l'application pour contacter le titulaire d'un compte dans la _vraie_ vie, aucun identifiant de mail / téléphone, etc.

# Restrictions de fonctionnement
Elles se traduisent par le ralentissement / le blocage de certaines opérations (ou partie d'opération) selon l'état du compte et de l'espace.

`1-RAL1  2-RAL2` : Ralentissement des opérations
- Comptes O : compte.qv.pcc > 90% / 100%
- Comptes A : compte.qv.nbj < 20 / 10

`3-NRED` : Nombre de notes / chats /groupes en réduction
- compte.qv.pcn > 100

`4-VRED` : Volume de fichier en réduction
- compte.qv.pcv > 100

`5-LECT` : Compte en lecture seule (sauf actions d'urgence)
- Comptes 0 : espace.notifP compte.notifC de nr == 2

`6-MINI` : Accès minimal, actions d'urgence seulement
- Comptes 0 : espace.notifP compte.notifC de nr == 3

`9-FIGE` : Espace figé en lecture
- espace.notif.nr == 2

Les restrictions _graves_ (5 à 9) empêchent la prolongation de la `dlv` du compte.

# Documents `groupes`
Un groupe est caractérisé par :
- son entête : un document `groupes`.
- son sous-document `chatgrs` (dont `ids` est `1`).
- ses membres: des documents de sa sous-collection `membres`.

**Droits d'accès d'un membre.**

Um membre peut avoir les accès suivants:
- [AM] : accès aux membres et au chat du groupe.
- [AN] : accès aux notes du groupe.

Il peut avoir les deux (cas général) ou n'en avoir aucun ce qui:
- limite son accès au groupe à la lecture de la carte de visite du groupe.
- pour un un animateur il peut être _hébergeur_.

Des droits d'accès sont conférés par un animateur:
- [DM] **d'accès à la liste des membres**.
- [DN] **d'accès en lecture aux notes du groupe**.
- [DE] **droits d'écriture sur les notes du groupe** (ce qui implique DN).

L'historique synthétique est consigné par:
- [HM] **a eu un jour accès aux membres**
- [HN] **a eu un jour accès aux notes**
- [HE] **a eu un jour la possibilité d'écrire une note**

## Statut d'un membre dans le groupe: tables `st tid flags`
Ces trois tables sont synchrones: l'indice `im` d'un membre est le même pour les trois:
- `tid` : table des ids des membres.
- `st` : statut de ce membre.
- `flags`: accès et droits d'accès de ce membre.

> Ces tables s'étendent, les indices devenus inutiles ne sont pas réutilisés.

**Statut `st`:**
- 0 : **radié**: ce membre ne peut plus agir. Ses flags HM HN HE indiquent s'il a pu accéder un jour aux membres, aux notes ou en écrire. `tid[im]` vaut 0.
- 1 : **proposé** par un membre ayant un droit d'accès aux membres.
  - l'avatar proposé n'est pas au courant et ne peut rien faire dans le groupe.
  - les membres du groupe peuvent voir sa carte de visite.
  - un animateur peut le faire passer en état _invité_ ou _le radier_ (avec ou sans inscription en liste noire _groupe_).
- 2 : **invité** par un animateur.
  - l'avatar proposé est au courant, il a une _invitation_ dans son avatar.
  - les membres du groupe peuvent voir sa carte de visite et les droits d'accès qui seront appliqués si l'avatar accepte l'invitation.
  - un animateur peut:
    - changer ses droits d'accès futurs.
    - _le radier_ (avec ou sans inscription en liste noire _groupe_).
  - l'avatar peut,
    - accepter l'invitation: il passera en état 3 _actif_ ou 4 _animateur_.
    - refuser l'invitation et être _radié_ (avec ou sans inscription en liste noire _compte_).
- 3 : **actif** (non animateur)
  - l'avatar a le groupe enregistré dans son compte (`mpg`).
  - il peut:
    - changer son accès aux membres et aux notes (mais pas ses droits).
    - se radier lui-même avec on sans inscription en liste noire _compte_.
  - un animateur peut:
    - changer ses droits d'accès (mais pas ses accès effectifs qui sont du ressort du membre).
    - l'inscrire en liste noire _groupe_, ce qui ne change pas son statut mais empêchera de proposer / inviter cet avatar après qu'il se soit radié lui-même.
- 4 : **animateur**. _actif_ avec privilège d'animation.

Le nombre de notes pris en compte dans la comptabilité du compte:
- est incrémenté de 1 quand il accepte une invitation,
- est décrémenté de 1 quand il s'auto-radie.

Dès qu'un membre prend un statut de **1 à 4**:
- un indice `im` lui est attribué en séquence du dernier attribué (taille de `tid`). 
- ses accès et droits sont consignés dans la table `flags` à l'indice `im`.
- il a un document `membres` associé: `ids`, l'identification relative du membre dans le groupe est son indice `im`.

## Radiations et inscriptions en liste noires `lng lnc`
La liste noire `lng` est la liste des ids des membres que l'animateur ne veut plus voir réapparaître dans le groupe après leur radiation.

La liste noire `lnc` est la liste des ids des membres qui se sont auto-radiés en indiquant ne jamais vouloir être ni proposé, ni invité.

Un animateur peut radier un membre en statuts _proposé et invité_:
- il peut à cette occasion l'inscrire en liste noire du groupe pour bloquer d'ultérieures éventuelles propositions / invitations.

Un membre _actif_ ne peut plus être radié par un animateur, mais ce dernier:
- peut changer ses droits (sauf si le membre est lui-même animateur). Le cas échéant le membre ne voit plus du groupe que sa carte de visite.
- peut l'inscrire en liste noire du groupe pour éviter de le voir réapparaître quand le membre se sera auto-radié.

Un membre actif peut _s'auto-radier_:
- il ne verra plus le groupe dans sa liste des groupes.
- sans inscription en liste noire, il pourra ultérieurement être reproposé / réinvité comme s'il n'avait jamais participé au groupe.
- avec inscription en liste noire il pourra plus jamais ultérieurement être reproposé / réinvité.

A la radiation d'un membre d'indice `im`:
- son document `membres` est logiquement détruit (passe en _zombi_).
- peut être inscrit dans les listes noires `lng lnc`.
- ses entrées dans `tid st` sont à 0.
- dans `flags` son entrée mentionne les dernières valeurs de `HM HN HE` ce qui permet, non pas de savoir qui c'était, mais quels ont été ses accès au cours de sa vie avant radiation (O si son statut n'a jamais été actif).

> Quand le GC découvre la _disparition_ d'un avatar membre, il s'opère l'équivalent d'une radiation sans mise en liste noire (l'avatar ne reviendra jamais).

## Création d'un membre
Le membre _fondateur_ du groupe a un _indice_ `im` 1 et est créé au moment de la création du groupe:
- dans la table `flags` à l'indice `im`: `DM DN DE AM AN HM hN HE`
  - il a _droit_ d'accès aux membres et aux notes en écriture,
  - ses accès aux membres et notes sont ouverts,
  - il a pour statut `st[1]` _animateur_.
- son id figure en `tid[1]`.

Les autres membres sont créés, lorsqu'ils sont soit proposés, soit invité.
- un indice `im` est pris en séquence, `tid[im]` contient leur id.
- leur document `membres` est créé. 
- _proposition_: leurs flags sont à 0, son statut est à 1.
- _invitation_: 
  - leurs flags donnent les _droits_ futurs DM DN DE selon le choix de l'animateur.
  - une **invitation** est insérée dans leur avatar.

>Réapparition d'un membre après _radiation sans liste noire_ par un animateur 
Un animateur peut radier un avatar _proposé ou invité_ sans le mettre en liste noire. L'avatar peut être reproposé / réinvité plus tard et aura un nouvel indice et un nouveau document `membres`, son historique est vierge. 

## Modes d'invitation
- _simple_ : dans ce mode (par défaut) un _contact_ du groupe peut-être invité par **UN** animateur (un seul suffit).
- _unanime_ : dans ce mode il faut que **TOUS** les animateurs aient validé l'invitation (le dernier ayant validé provoquant l'invitation).
- pour passer en mode _unanime_ il suffit qu'un seul animateur le demande.
- pour revenir au mode _simple_ depuis le mode _unanime_, il faut que **TOUS** les animateurs aient validé ce retour.

Une invitation est enregistrée dans la map `invits` de l'avatar invité:
- _clé_: `idg` id du groupe.
- _valeur_: `{cleGA, cvG, cleAG, cvA, txtG}`
  - `cleGA`: clé du groupe crypté par la clé A de l'avatar.
  - `cvG` : carte de visite du groupe (photo et texte sont cryptés par la clé G du groupe).
  - `cleAG`: clé A de l'avatar invitant crypté par la clé G du groupe.
  - `cvA` : carte de visite de l'invitant (photo et texte sont cryptés par la clé G du groupe). 
  - `txtG` : message de bienvenue / invitation émis par l'invitant.

Ces données permettent à l'invité de voir en session les cartes de visite du groupe et de l'invitant ainsi que le texte d'invitation (qui figure également dans le chat du groupe). Le message de remerciement en cas d'acceptation ou de refus sera également inscrit dans le chat du groupe.

## Hébergement par un membre _actif_
L'hébergement d'un groupe est noté par :
- `imh`: indice membre de l'avatar hébergeur. 
- `idh` : id du **compte** de l'avatar hébergeur. **Cette donnée est cachée aux sessions**.
- `dfh`: date de fin d'hébergement qui vaut 0 tant que le groupe est hébergé. Les notes ne peuvent plus être mises à jour _en croissance_ quand `dfh` existe.

### Prise d'hébergement
- en l'absence d'hébergeur, c'est possible pour,
  - tout animateur,
  - en l'absence d'animateur: tout actif ayant le droit d'écriture des notes, puis tout actif ayant accès aux notes, puis tout actif.
- s'il y a déjà un hébergeur, seul un animateur peut se substituer à condition que le nombre de notes et le volume de fichiers actuels `vf` ne le mette pas en dépassement de son abonnement.

### Fin d'hébergement par l'hébergeur
- `dfh` est mise la date du jour + 90 jours.
- le nombre de notes et le volume V2 de `comptas` sont décrémentés de ceux du groupe.

Au dépassement de `dfh`, le GC détruit le groupe.

## Data
_data_:
- `id` : id du groupe.
- `v` :  1..N, Par convention, une version à 999999 désigne un **groupe logiquement détruit** mais dont les données sont encore présentes. Le groupe est _en cours de suppression_.
- `dfh` : date de fin d'hébergement.

- `rds` : pas transmis en session.
- `nn qn vf qv`: nombres de notes actuel et maximum attribué par l'hébergeur, volume total actuel des fichiers des notes et maximum attribué par l'hébergeur.
- `idh` : id du compte hébergeur (pas transmise aux sessions).
- `imh` : indice `im` du membre dont le compte est hébergeur.
- `msu` : mode _simple_ ou _unanime_.
  - `null` : mode simple.
  - `[ids]` : mode unanime : liste des indices des animateurs ayant voté pour le retour au mode simple. La liste peut être vide mais existe.
- `tid` : table des ids courts des membres.
- `st` : table des statuts.
- `flags` : tables des flags.
- `lng` : liste noire _groupe_ des ids (courts) des membres.
- `lnc` : liste noire _compte_ des ids (courts) des membres.
- `cvG` : carte de visite du groupe, textes cryptés par la clé du groupe `{v, photo, info}`.

## Décompte des participations à des groupes d'un compte
- quand un avatar a accepté une invitation, il devient _actif_ et a une nouvelle entrée dans la liste des participations aux groupes (`mpg`) dans l'avatar principal de son compte.
- quand l'avatar décide de s'auto-radier, cette entrée est supprimée.
- le _nombre de participations aux groupes_ dans `comptas.qv.ng` du compte est le nombre total de ces entrées dans `mpg`.

# Documents `membres`
Un document `membres` est créé à la déclaration d'un avatar comme _contact_.

Le document `membres` est détruit,
- par une opération de radiation.
- par la destruction de son groupe lors de la résiliation du dernier membre actif.

_data_:
- `id` : id du groupe.
- `ids`: identifiant, indice `im` de membre relatif à son groupe.
- `v` : 
- `vcv` : version de la carte de visite du membre.

- `ddi` : date d'invitation.
- `dac` : date de début d'activité
- **dates de début de la première et fin de la dernière période...**
  - `dln fln` : d'accès en lecture aux notes.
  - `den fen` : d'accès en écriture aux notes.
  - `dam fam` : d'accès aux membres.
- `inv` : Liste des im des animateurs ayant validé la dernière invitation.
- `cleAG` : clé A de l'avatar membre cryptée par la clé G du groupe.
- `cvA` : carte de visite du membre `{id, v, photo, info}`, textes cryptés par la clé A de l'avatar membre.

## Opérations

### Proposition
- s'il est en liste noire, refus.
- attribution de l'indice `im`.
- un row `membres` est créé.

### Invitation par un animateur
- choix des _droits_ et inscription dans `invits` de l'avatar.
- vote d'invitation (en mode _unanime_):
  - si tous les animateurs ont voté, inscription dans `invits` de l'avatar.
  - si le vote change les _droits_, les autres votes sont annulés.
- `ddi` est remplie dans `membres`.

### Annulation d'invitation par un animateur
- effacement de l'entrée de l'id du groupe dans `invits` de l'avatar.

### Radiation par un animateur (avec ou sans liste noire)
- le statut passe de 1-2 (sinon erreur) à 0.
- s'il était invité, effacement de l'entrée de l'id du groupe dans `invits` de l'avatar.
- inscription éventuelle en liste noire `lng`.
- le document `membres` devient _zombi_.

### Refus d'invitation par le compte
- mise à 0 du statut, des flags et de l'entrée dans tid.
- document `membres` mis en _zombi_
- Option liste noire: inscription dans `lnc`.
- son item dans `invits` de son avatar est effacé.

### Acceptation d'invitation par le compte
- dans l'avatar principal du compte un item est ajouté dans `mpg`,
- dans `comptas` le compteur `qv.ng` est incrémenté.
- `dac dln ... fam` de `membres` sont mises à jour.
- son item dans `invits` de son avatar est effacé.
- flags `AN AM`: accès aux notes, accès aux autres membres.
- statut à 3 ou 4.

### Modification des droits par un animateur
- flags `DM DN DE`

### Mise en liste noire groupe par un animateur
- le statut est actif.
- le membre est mis en liste noire `lng`.

### Modification des accès membres / notes par le compte
- flags `AN AM`: accès aux notes, accès aux autres membres.

## Radiation demandée par le compte**
- document membres mis en _zombi_.
- mis à 0 du statut, de l'entrée dans tid. Dans flags il ne reste que les HM HN HE.
- si le membre était le dernier _actif_, le groupe disparaît.
- la participation au groupe disparaît de `mpg` du compte.
- option liste noire: mise en liste noire `lnc`.
