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
  - une session sans opérations depuis un certain temps est considérée comme disparue.
  - si le serveur tombe _down_, toutes les sessions en cours sont de facto déconnectées 
- la première implémentation correspond à une base `Sqlite`, un serveur `node` et une notification **Data Sync** par WebSocket.

### NOSQL-Data Sync
Chaque table SQL correspond à une **collection de documents**, chaque document est équivalent à un **row** de la table SQL de même nom que la collection.
- la base implémente un mécanisme de **Data Sync** par lequel une session peut directement demander à la base de lui notifier les mises à jour des documents qui l'intéresse, sans passer par un _serveur_ intermédiaire pour ce service.
- il faut a minima une _Cloud Function_ pour gérer les transactions de lecture / mises à jour de type REST:
  - le service correspondant peut être _up_ juste le temps d'une transaction et repasser _down_ en l'absence de sollicitation.
  - il peut aussi de fait être assuré par un serveur qui reste _up_ en continu (du moins sur une longue durée).
- les sessions clientes sont insensibles à la tombée _down_ de la Cloud Function (ou du serveur). Les _abonnements_ ne sont gérés que par les sessions clientes (une _Cloud Function_ ne gère pas de _sessions clientes_). 
- la première implémentation correspond à une base Firestore et à une Google Cloud Function.

> **Remarque:** entre une implémentation GCP Function et AWS Lambda, il n'y a a priori qu'une poignée de lignes de code de différence dans la configuration de l'amorce du service mais une procédure de déploiement spécifique.

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

La collection `singletons` a un nombre fixe de documents représentant les derniers _rapports de GC_: /VERIF/
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
- tous les autres documents ont un attribut / colonne `id` de 16 chiffres dont les 2 premiers sont le `ns` de leur espace. Les propriétés des documents peuvent citer l'id _courte_ (sans les deux premiers chiffres) d'autres documents.

## Code organisation attaché à un espace
A la déclaration d'un espace sur un serveur, l'administrateur technique déclare un **code organisation**:
- ce code ne peut plus changer: lors d'une _exportation_ d'un espace on peut définir un autre code d'espace pour la cible de l'exportation.
- le Storage de fichiers comporte un _folder_ racine portant ce code d'organisation ce qui partitionne le stockage de fichiers.
- les connexions aux comptes citent ce _code organisation_.

## L'administrateur technique
Il a pour rôle majeur de gérer les espaces:
- les créer / les détruire,
- définir leurs quotas à disposition du Comptable de chaque espace: il existe trois quotas,
  - `qn` : nombre maximal autorisé des notes, chats, participations aux groupes,
  - `qv` : volume total autorisé des fichiers attachés aux notes.
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

Il existe deux catégories de comptes:
- **les comptes "O", de l'organisation**, bénéficient de ressources _gratuites_ attribuées par la Comptable et ses _délégués_. En contrepartie de cette _gratuité_ un compte "O" peut être _bloqué_ par le Comptable et ses _délégués_ (par exemple en cas départ de l'organisation).
- **les comptes "A", autonomes**, achètent des ressources sous la forme d'un abonnement et d'une consommation. Tant qu'il est créditeur un compte "A" ne peut pas être bloqué.

> Les abonnements et consommations sont exprimées in fine en _unité monétaire_ virtuelle, le centime (c), dont l'ordre de grandeur est voisin d'un centime d'euro ou de dollar (le _cours_ exact étant fixé par chaque organisation).

### Comptes "O" : _partitions_
Le Comptable dispose des quotas globaux de l'espace attribués par l'administrateur technique. 
- Il définit un certain nombre de **partitions de quotas**.
- Il confie la gestion de chaque partition à des comptes _délégués_ qui peuvent distribuer des quotas de ressources aux comptes "O" affectés à leur partition.

Tout compte "0" est attaché à une _partition_: ses quotas `qc q1 q2` sont prélevés sur ceux de sa partition.

Un compte "O",
- est attaché à une _partition_: ses quotas `qc q1 q2` sont prélevés sur ceux de sa partition. 
- est créé par _sponsoring_,
  - soit d'un compte "O" existant _délégué_,
  - soit du Comptable qui a choisi de quelle partition il relève.

Les comptes "0" _délégués_ d'une partition peuvent:
- sponsoriser la création de nouveaux comptes "O", _délégués_ eux-mêmes ou non de cette partition.
- gérer la répartition des quotas entre les comptes "O" attachés à cette partition.
- gérer une _notification / blocage_ pour les comptes "O" attachés à leur partition.

### Comptes "A"
Un compte "A" est créé par _sponsoring_,
- soit d'un compte "A" existant qui à cette occasion fait _cadeau_ au compte sponsorisé d'un montant de son choix prélevé sur le solde monétaire du compte sponsor.
- soit par un compte "O" _délégué_ ou par le Comptable: un cadeau de bienvenue de 2c est affecté au compte "A" sponsorisé (prélevé chez personne).

Un compta "A" définit lui-même ses quotas `q1` et `q2` (il les paye en tant _qu'abonnement_) et n'a pas de quotas `qc` (il paye sa _consommation_).

### Rôles du Comptable
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

Ces documents ne sont jamais mis à jour une fois créés, ils sont supprimés,
- en général quasi instantanément dès que _l'upload_ est physiquement terminé,
- sinon par le GC qui considère qu'un upload ne peut pas techniquement être encore en cours à j+2 de son jour de début.

## Documents `fpurges`
- `id` : aléatoire, avec ns en tête,
- `_data_` : liste encodée,
  - soit d'un `id` d'un avatar ou d'un groupe, correspondant à un folder du _Storage_ à supprimer,
  - soit d'un couple `[id, ids]` identifiant UN fichier `ids` dans le folder `id` d'un avatar ou d'un groupe.

Ces documents ne sont jamais mis à jour une fois créés, ils sont supprimés par le prochain GC après qu'il ait purgé du _Storage_ tous les fichiers cités dans _data_.

# Table / documents d'un espace

## Entête d'un espace: `espaces syntheses`
Pour un espace donné, ce sont des singletons:
- `espaces` : `id` est le `ns` (par exemple `24`) de l'espace. Le document contient quelques données générales de l'espace.
  - Clé primaire : `id`. Path : `espaces/24`
- `syntheses` : `id` est le `ns` de l'espace. Le document contenant des données statistiques sur la distribution des quotas aux comptes "O" (par _partition_) et l'utilisation de ceux-ci.
  - Clé primaire : `id`. Path : `syntheses/24`

# Tables / collections _majeures_ : `partitions comptes comptis comptas avatars groupes`
Chaque collection a un document par `id` (clé primaire en SQL, second terme du path en Firestore).

### `partitions`
Un document par _partition de quotas_ décrivant la distribution des quotas entre les comptes "O" attachés à cette partition.
  - `id` (sans le `ns`) est un numéro séquentiel `1..N`.
  - Clé primaire : `id`. Path : `partitions/0...x`

### `comptes`
Un document par compte donnant les clés majeures du compte, la liste de ses avatars et des groupes auxquels un de ses avatars participe. L'`id` courte sur 14 chiffres est le numéro du compte :
  - `10...0` : pour le Comptable.
  - `2x...y` : pour les autres comptes, `x...y` est un nombre aléatoire sur 13 chiffres.
  - Clé primaire : `id`. Path : `comptas/10...0` `comptas/2x...y`

### `comptis`
Un document _complémentaire_ de `comptes` (même id) qui donne des commentaires et hashtags attachés par le comptes aux avatars et groupes de sa connaissance.

### `comptas`
Un document par compte donnant ses compteurs de consommation et les quotas.

### `avatars`
Un document par avatar donnant les informations d'entête d'un avatar. L'`id` courte sur 14 chiffres est le numéro d'un avatar du compte :
  - `10...0` : pour l'avatar principal (et unique) du Comptable.
  - `2x...y` : pour les avatars principaux ou secondaires des autres comptes. `x...y` est un nombre aléatoire sur 13 chiffres.
  - Clé primaire : `id`. Path : `avatars/10...0` `avatars/2x...y`

### `groupes`
Un document par groupe donnant les informations d'entête d'un groupe. L'`id` courte sur 14 chiffres est le numéro d'un groupe :
  - `3x...y` : `x...y` est un nombre aléatoire sur 13 chiffres.
  - Clé primaire : `id`. Path : `groupes/3x...y`

# Tables / sous-collections d'un avatar ou d'un groupe
- chaque **avatar** a 4 sous-collections de documents: `notes sponsorings chats tickets` (seul l'avatar Comptable a des tickets).
- chaque **groupe** a 3 sous-collections de documents: `notes membres chatgrs`.

Dans chaque sous-collection, `ids` est un identifiant relatif à `id`. 
- en SQL les clés primaires sont `id,ids`
- en Firestore les paths sont (par exemple pour la sous-collection `notes`) : `versions/2.../notes/z...t`, `id` est le second terme du path, `ids` le quatrième.

### `notes`
Un document représente une note d'un avatar ou d'un groupe. L'identifiant relatif `ids` est un nombre aléatoire.

### `sponsorings`
Un document représente un sponsoring d'un avatar. Son identifiant relatif est _ns +  hash de la phrase_ de sponsoring entre le sponsor et son sponsorisé.

### `chats`
Un chat entre 2 avatars A et B se traduit en deux documents : 
  - l'un sous-document de A a pour identifiant secondaire `ids` un nombre aléatoire.
  - l'autre sous-document de B a pour identifiant secondaire `ids` un autre nombre aléatoire.

### `membres`
Un document par membre avatar participant à un groupe. L'identifiant secondaire `ids` est l'indice membre `1..N`, ordre d'enregistrement dans le groupe.

### `chatgrs`
Un seul document par groupe. `id` est celui du groupe et `ids` vaut toujours `1`.

### `tickets`
Un document par ticket de crédit généré par un compte A. `ids` est un nombre aléatoire tel qu'il puisse s'éditer sous forme d'un code à 6 lettres majuscules (de 1 à 308,915,776).

# Clés de cryptage
## Phrases
### Phrase secrète d'accès à un compte
- XC : PBKFD de la phrase complète - hXC son hash.
- XR : PBKFD d'un extrait de la phrase - hXR son hash.

### Phrase de sponsoring
- YC : PBKFD de la phrase complète - hYC son hash
- YR : PBKFD d'un extrait de la phrase - hYR son hash.

### Phrase de contact d'un avatar
- ZC : PBKFD de la phrase complète - hZC son hash.
- ZR : PBKFD d'un extrait de la phrase - hZR son hash.

## Clés
### S : clé du site
Fixée dans la configuration de déploiement du serveur par l'administrateur technique.
- **elle crypte les _data_ des documents**, c'est à dire l'ensemble des propriétés d'un document. Les propriétés externalisées en index / clé sont répliquées en clair en dehors de _data_.

### E : clé d'un espace
- attribuée à la création de l'espace par l'administrateur.
- clé partagée entre l'administrateur et le Comptable de l'espace.
- **crypte les rapports générés par le GC** de ce fait lisibles pour l'administrateur et le Comptable.

### K : clé principale d'un compte.
- attribuée à la création du compte par `AccepterSponsoring` ou `CreerEspace` pour le Comptable.
- propriété exclusive du compte.
- crypte ses notes et d'autres clés.

### A : clé d'un avatar
- attribuée à la création de l'avatar ou du compte pour l'avatar principal.
- **crypte les photo et texte de sa carte de visite**.
- crypte la clé G d'un groupe auquel l'avatar est invité.
- crypte la clé C d'un chat à la création du chat (pour l'exemplaire E).

### C : clé d'un chat
- attribuée aléatoirement à la création du chat.
- **crypte les textes du chat**.

### G : clé d'un groupe
- attribuée à la création du groupe.
- crypte les photo et texte de sa carte de visite, ses notes, les textes du chat du groupe.
- crypte la clé A d'un membre du groupe.

### P : clé d'une partition
- attribuée à la création de la partition par le Comptable et à la création de l'espace pour la partition primitive.
- crypte les textes des notifications d'une partition et les clés A des avatars principaux des comptes de la partition.

## Clé RSA d'un avatar
La clé de cryptage (publique) et celle de décryptage (privée) sont de longueurs différentes. 

Le résultat d'un cryptage a une longueur fixe de 256 bytes. Deux cryptages RSA avec la même clé d'un même texte donnent deux valeurs cryptées différentes.

Un avatar a un couple de clés privée / publique:
- la clé privée est stockée cryptée par la clé K du compte dans le document `avatars` et pour l'avatar principal seulement elle est redondée dans le document `comptes`.
- la clé publique est stockée en clair dans le document `avatars`.

## Documents stockant les clés, phrases et hash de phrases
### `espaces`
- `cleES` : clé E cryptée par la clé S.

### `comptes`
- `hXC`: hash du PBKFD de la phrase secrète complète.
- `hXR`: hash du PBKFD d'un extrait de la phrase secrète.
- `cleKXC` : clé K cryptée par XC.
- `cleEK` : Comptable seulement. Clé E cryptée par sa clé K.
- `privK` : clé privée RSA de son avatar principal cryptée par la clé K du compte.
- `cleAK` : _pour chaque avatar du compte_:  clé A de l'avatar cryptée par la clé K du compte.
- `cleGK` : _pour chaque groupe_ où un avatar est actif: clé G du groupe cryptée par la clé K du compte.
- _Comptes "O" seulement:_
  - `clePK` : clé P de la partition cryptée par la clé K du compte. Toutefois si cette clé a une longueur de 256, la clé P peut être décryptée par `privK`, ayant été cryptée par la clé publique de l'avatar principal du compte suite à une affectation à une partition APRÈS sa création (changement de partition, passage de compte A à O).

### `avatars`
- `cleAZC` : clé A cryptée par ZC.
- `cleGA` : _pour chaque groupe_ où l'avatar est invité.
- `pcK` : phrase de contact cryptée par la clé K du compte.
- `hZC` : hash du PBKFD de la phrase de contact complète.
- `hZR` : hash du PBKFD d'un extrait de la phrase de contact.
- `pub privK` : couple des clés publique / privée RSA de l'avatar.

### `sponsorings`
- `hYR`: hash du PBKFD de la phrase secrète réduite.
- `pspK` : phrase de sponsoring cryptée par la clé K du sponsor.
- `YCK` : PBKFD de la phrase de sponsoring cryptée par la clé K du sponsor.
- `hYC` : hash du PBKFD de la phrase de sponsoring,
- `cleAYC` : clé A du sponsor crypté par le PBKFD de la phrase de sponsoring.
- `clePYC` : clé P de la partition (si c'est un compte "O") cryptée par le PBKFD de la phrase de sponsoring (donne le numéro de partition).

### `chats`
- `cleCKP` : clé C du chat cryptée,
  - si elle a une longueur inférieure à 256 bytes par la clé K du compte de I.
  - sinon cryptée par la clé RSA publique de I.
- `cleEC` : clé A de l'avatar E cryptée par la clé du chat.

# Périmètre d'un compte
Le périmètre d'un compte délimite un certain nombre de documents:
- un compte n'a la visibilité en session UI que des documents de son périmètre.
- il peut s'abonner à certains ceux-ci dits _synchronisés_: une session d'un compte reçoit des _avis de changement_ (pas le contenu) de sous-ensemble de ces documents qui permettent à l'opération `sync` de tirer les documents ayant changé.
  - sous-ensembles synchronisés:
    - `espaces`
    - `comptes comptis`
    - `avatars notes sponsorings chats tickets`
    - `groupes notes membres chatgrs`
  - documents du périmètre NON _synchronisés_
    - `syntheses partitions comptas`

Le _périmètre_ d'un compte ayant une id donnée est le suivant:
- le document `espaces` portant comme `ns` celui de l'id du compte.
  - ce document est _synchronisé_ en tant que tel.
- le document `synthèses` portant comme `ns` celui de l'id du compte.
  - ce document n'est pas _synchronisé_ mais chargé à la demande.
- le document `partitions` de la partition d'un compte "O".
  - ce document n'est pas _synchronisé_ mais chargé à la demande.
- les documents `comptes comptis`  portant cette id.
  - ce couple de documents est _synchronisé_.
- le document `comptas` portant cette id.
  - ce document n'est pas _synchronisé_ mais chargé à la demande.
- les documents `avatars` des avatars principaux et secondaires du compte,
  - les sous-documents `notes sponsorings chats tickets` de ces avatars.
  - un document avatar et ses sous-documents forme un ensemble _synchronisé_.
- les documents `groupes` dont un des avatars du compte est membre actif.
  - les sous-documents `notes membres chatgrs` de ces groupes.
  - un document groupe et ses sous-documents forme un ensemble _synchronisé_.

Exception pour le Comptable: il peut voir **tous** les documents `partitions` de _son_ espace et pas seulement celui de sa partition.

> Les documents d'un _périmètre_ sont sujet à des évolutions en cours de session suite aux effets des opérations soumises au serveur, 
- soit par la session elle-même, 
- soit par n'importe quelle autre, 
- du même compte ou de n'importe quel autre, et marginalement du GC.
- ses changements sont, pour l'essentiel, notifiés aux sessions.

## Disponibilité en session UI
Une session d'un compte dispose en mémoire de tous les documents synchronisés de son compte:
- chargement initial en début de session,
- puis à réception des avis de changements, rechargement incrémental sélectif des documents ayant changé.

### Avis de changement: document `versions`
Un document _version_ trace une mise à jour, un changement de version d'un document ou ensemble de documents:
- (E) le document `espaces` du compte: 
  - son identifiant est celui de l'espace.
- (C) un des deux documents `comptes comptis` du compte: 
  - l'identifiant de l'avis est la propriété immuable `rds` du document `comptes`.
- (A) un document `avatars` **et ses sous-documents**:
  - l'identifiant de l'avis est la propriété immuable `rds` du document `avatars` tête de cet ensemble.
- (G) un document `groupes` **et ses sous-documents**:
  - l'identifiant de l'avis est la propriété immuable `rds` du document `groupes` tête de cet ensemble.

#### Exemple
- mise à jour d'un chat #5 de l'avatar #13;
- le numéro de version associé au sous-ensemble A#13 est incrémenté et passe par exemple de 123 à 124;
- le chat #5 prend pour version 124;
- si une session est synchronisée pour l'avatar #13 sur la version 112 par exemple, elle va obtenir tous les sous-documents de cet avatar (lui même inclus) de versions supérieure à 112 -qui ont donc changé depuis 112-. Désormais la session sera synchronisée sur la version 126 (la plus récente) pour cet avatar #13.
- elle n'a pas reçu les très nombreux sous-documents ayant une version antérieure à 112 (n'ayant donc pas changé par rapport à l'état connu en mémoire).

### Remarque
- (1) **en synchronisation directe par Firestore** des lectures sont toujours en attente `onSnapshot` sur "les documents `versions` dont l'id fait partie de la liste de ceux du périmètre":
  - les lectures reviennent à chaque fois que le document `versions` correspondant change, son _numéro de version_ ayant été incrémenté par un traitement sur le serveur.
  - cet avis concerne donc son `espaces`, soit `compte comptis`, soit l'un des documents d'un avatar, soit l'un des documents d'un groupe.
- (2) **en synchronisation par le serveur**, celui-ci transmet par WebSocket un item qui a la forme d'un document `versions`. Le serveur voit passer tous les changements des `versions` et sait quelles sessions sont abonnées à quelles `versions`.

### Les _référence de synchronisation_ : `rds`
- chaque **compte / avatar / groupe** à une _référence de synchronisation_ tirée au hasard et immuable, **un identifiant alternatif, en bijection avec l'id** du compte, de l'avatar ou du groupe.
- **la correspondance entre `rds / id` n'est jamais disponible en session** (les champs `rds` de `comptes avatars groupes` n'y sont pas remontés).
- **une session ne reçoit du serveur que la stricte liste des `rds` de son périmètre** (sans d'ailleurs savoir à quel avatar / groupe / compte chacun correspond): elle pourra lancer des lecture _onSnapshot_ sur les documents `versions` dont l'identifiant est un des `rds` de cette liste, et reçoit ainsi des avis de changements, savoir savoir _de quoi_. L'opération `sync` transmise au serveur a quant à elle l'information pour corréler `rds` et `id` des comptes / avatars / groupes. 

Si au lieu des `rds` les versions avaient été identifiées directement par les ids des comptes / avatars / groupes, dans le cas (1) _FireStore_ une session ayant un logiciel malicieux _aurait pu_ poser des lectures _onSnapshot_ sur des `versions` de documents hors de son périmètre:
- certes le serveur ne lui aurait délivré aucun document hors de son périmètre,
- mais la session aurait pu en tirer des informations à propos de l'activité (ou l'absence d'activité) d'autres sessions d'autres comptes.
- n'ayant aucun moyen d'obtenir l'id alternative `rds` des comptes / avatars / groupes, cette activité d'espionnage est vouée à l'échec.

**Remarque: `espaces` n'a pas de `rds`**
- son `versions` est directement identifié par le `ns` de l'espace.
- donc des sessions _malicieuses_ peuvent obtenir une information d'activité sur des espaces autres que le leur ... ce qui n'a aucune espèce d'intérêt. Les mises à jour de espaces sont fort rares (et de plus les autres espaces que le sien ne sont pas accessibles par une session).

## Tracking des créations et mises à jour
**Remarque:** il n'y a pas à proprement parlé de _suppressions_:
- un document `sponsorings` a une date limite de validité: le document est logiquement supprimé dès que cette date est dépassée.
- un document `notes` peut être _vide_, n'a plus de contenu et n'apparaît plus dans les vues, mais son document existe toujours en _zombi_.

Les documents `versions` sont chargés du tracking des mises à jour des documents du périmètre et des sous-documents de `avatars` et de `groupes`. Propriétés:
- `id` : _référence data sync_ `rds` du document.
- `v` : version, incrémentée de 1 à chaque mise à jour, soit du document maître, soit de ses sous-documents `notes sponsorings chats tickets membres chatgrs`
- `suppr` : jour de _suppression_ du compte / avatar / groupe (considérés comme _zombi_)

> **Remarque:** Ce principe conduirait à conserver pour toujours la trace de très vielles suppressions. Pour éviter cette mémorisation éternelle sans intérêt, le GC lit les `versions` supprimées depuis plus de N mois pour les purger. Les sessions ont toutes eu le temps d'intégrer les disparitions correspondantes.

**La constante `IDBOBS / IDBOBSGC` de `api.mjs`** donne le nombre de jours de validité d'une micro base locale IDB sans resynchronisation. Celle-ci devient **obsolète** (à supprimer avant connexion) `IDBOBS` jours après sa dernière synchronisation. Ceci s'applique à _tous_ les espaces avec la même valeur.

> Les documents de tracking versions sont purgés `IDBOBSGC` jours après leur jour de suppression `suppr`.

# Détail des tables / collections _majeures_ et leurs _sous-collections_
Ce sont les documents faisant partie d'un périmètre d'un compte: `partitions comptes comptas avatars groupes notes sponsorings chats tickets membres chatgrs versions`

## _data_
Tous les documents, ont une propriété `_data_` qui porte toutes les informations sérialisées du document.

`_data_` est crypté:
- en base _centrale_ par la clé du site qui a été générée par l'administrateur technique et qu'il conserve en lieu protégé comme quelques autres données sensibles (_token_ d'autorisation d'API, identifiants d'accès aux comptes d'hébergement ...).
- en base _locale_ par la clé K du compte.
- le contenu _décrypté_ est souvent le même dans les deux bases et est la sérialisation d'un objet de classe correspondante. Toutefois:
  - pour certains documents certaines propriétés sont marquées _non transmises en session_: dans ce cas elles sont _omises_ dans la sérialisation du _data_ qui remonte en session.

## Propriétés _externalisées_ hors de _data_ : `id ids v` etc.
Elles le sont,
- soit parce que faisant partie de la clé primaire `id ids` en SQL, ou du path en Firestore,
- soit parce qu'elles sont utilisées dans des index, en particulier la version `v` du document.

### `id` et `ids` quand il existe
Ces propriétés sont externalisées et font partie de la clé primaire (en SQL) ou du path (en Firestore).

Pour un `sponsorings` la propriété `ids` est le hash de la phrase de reconnaissance :
- elle est indexée.
- en Firestore l'index est `collection_group` afin de rendre un sponsorings accessible par index sans connaître son _parent_ le sponsor.

## `v` : version d'un document
**La version de 1..n** est incrémentée de 1 à chaque mise à jour,
- soit de son document lui-même: `espaces syntheses partitions comptas`, 
- soit du document `versions` de leurs sous-collections.
  - `comptes comptis`
  - `avatars notes sponsorings chats tickets`
  - `groupes chatgrs notes membres`

### Propriété `v` de `transferts`
Elle permet au GC de détecter les transferts en échec et de nettoyer le _storage_.
- en Firestore l'index est `collection_group` afin de s'appliquer aux fichiers des notes de tous les avatars et groupe.

### `dlv` d'un `comptes`
La `dlv` **d'un compte** désigne le dernier jour de validité du compte:
- c'est le **dernier jour d'un mois**.
- **cas particulier**: quand c'est le premier jour d'un mois, la `dlv` réelle est le dernier jour du mois précédent. Dans ce cas elle représente la date de fin de validité fixée par l'administrateur pour l'ensemble des comptes "O". En gros il a un financement des frais d'hébergement pour les comptes de l'organisation jusqu'à cette date (par défaut la fin du siècle).

La `dlv` d'un compte est inscrite dans le document `comptes` du compte: elle est externalisée pour que le GC puisse récupérer tous les comptes obsolètes à détruire.

## `dlv` d'un `sponsorings` 
- jour au-delà duquel le sponsoring n'est plus applicable ni pertinent à conserver. Les sessions suppriment automatiquement à la connexion les sponsorings ayant dépassé leur `dlv`.
- dès dépassement du jour de `dlv`, un sponsorings est purgé (du moins peut l'être).
- elles sont indexées pour que le GC puisse purger les sponsorings. En Firestore l'index est `collection_group` afin de s'appliquer aux sponsorings de tous les avatars.

### `vcv` : version de la carte de visite. `avatars chats membres`
Cette propriété est la version `v` du document au moment de la dernière mise à jour de la carte de visite: elle est indexée.

### `dfh` : date de fin d'hébergement. `groupes`
La **date de fin d'hébergement** sur un groupe permet de détecter le jour où le groupe sera considéré comme disparu. A dépassement de la `dfh` d'un groupe, le GC fait disparaître le groupe inscrivant une `suppr` du jour dans son document `versions` et une version v à 999999 dans le document `groupes`. /VERIF/

### `hZR` : hash de la phrase de contact. `avatars`
Cette propriété de `avatars` est indexée de manière à pouvoir accéder à un avatar en connaissant sa phrase de contact.

### `hXR` : hash d'un extrait de la phrase secrète. `comptes`
Cette propriété de `comptes` est indexée de manière à pouvoir accéder à un compte en connaissant le `hXR` issu de sa phrase secrète.

# Cache locale des `espaces partitions comptes comptis comptas avatars groupes versions` dans un serveur
Un _serveur_ ou une _Cloud Function_ qui ne se différencient que par leur durée de vie _up_ ont une mémoire cache des documents:
- `comptes` accédés pour vérifier si les listes des avatars et groupes du compte ont changé.
- `comptis` accédés pour avoir les commentaires et hashtags attachés à ses avatars et groupes par un compte.
- `comptas` accédés à chaque changement de volume ou du nombre de notes / chats / participations aux groupes.
- `versions` accédés pour gérer le Data Sync..
- `avatars groupes partitions` également fréquemment accédés.

**Les conserver en cache** par leur `id` est une solution naturelle: mais il peut y avoir plusieurs instances s'exécutant en parallèle. 
- Il faut en conséquence interroger la base pour savoir s'il y a une version postérieure et ne pas la charger si ce n'est pas le cas en utilisant un filtrage par `v`. 
- Ce filtrage se faisant sur l'index n'est pas décompté comme une lecture de document quand le document n'a pas été trouvé parce que de version déjà connue.

La mémoire cache est gérée par LRU (tous types de documents confondus) afin de limiter sa taille en mémoire.

# Clés et identifiants
## Le hash PBKFD
Son résultat fait 32 bytes. Long à calculer, son algorithme ne le rend pas susceptible d'être accéléré pae usage de CPU graphiques. Il est considéré comme incassable par force brute.

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

> Depuis la _clé_ d'une partition, d'un avatar ou d'un groupe, une fonction retourne son `id` courte (sans `ns`).

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
- `tx` **texte d'une carte de visite**: le début de la _première ligne_ donne un _nom_, le reste est un complément d'information.
- `ph` **photo d'une carte de visite** encodée en base64 URL.
- `tx` : texte d'un échange sur un `chats` ou `chatgrs`.
- `tx`, commentaire personnel d'un compte attaché à un avatar contact (chat ou membre d'un groupe) ou à un groupe.
- `ht` : hashtags, liste de mots attachés par un compte à,
  - un avatar contact (chat ou membre d'un groupe),
  - un groupe dont il est ou a été membre ou au moins invité,
  - un note, personnelle ou d'un des groupes où il est actif et a accès aux notes.
- `texte` d'une note personnelle ou d'un groupe.

Les `texte / tx` sont gzippés ou non avant cryptage: c'est automatique dès que le texte a une certaine longueur (de fait les hashtags ne sont pas gzippés).

> **Remarque:** Le serveur ne voit **jamais en clair**, aucun texte, ni aucune clé susceptible de crypter un texte, ni la clé K des comptes, ni les _phrase secrètes_ ou _phrases de contacts / sponsorings_.

> Les textes sont cryptés / décryptés par une application UI. Si celle-ci est malicieuse / boguée, les textes sont illisibles mais finalement pas plus que ceux qu'un utilisateur qui les écrirait en idéogrammes pour un public occidental ou qui inscrirait  des textes absurdes.


@@ L'application UI [uiapp](./uiapp.md)
