@@Index général de la documentation [index](https://raw.githack.com/dsportes/asocial-doc/master/index.md)

# Données persistantes sur le serveur
Elles sont réparties en deux catégories:
- les données stockées dans la _base_,
- les _fichiers_ présents dans le _Storage_.

## _Storage_
Il est à 3 niveaux `org/id/nf` :
- `org` : code l'organisation détentrice,
- `id` : id de l'avatar ou du groupe à qui appartient le fichier.
- `idf` : identifiant aléatoire (universel) du fichier.

Trois implémentations ont été développées:
- **File-System** : pour le test, les fichiers sont stockés dans un répertoire local.
- **Google Cloud Storage** : a priori il n'y a pas d'autres providers que Google qui propose ce service.
- **AWS/S3** : S3 est le nom de l'interface, plusieurs fournisseurs en plus d'Amazon le propose.

## _Base_
La base peut avoir plusieurs implémentations : un _provider_ est la classe logicielle qui gère l'accès à sa base selon sa technologie.

On distingue deux classes d'organisation techniques: **SQL** et **NOSQL+Data Sync**.

**Data Sync** : mécanisme permettant de notifier une session UI qu'un document / row a changé sous l'effet d'opérations de mise à jour ou de suppression.

### SQL
Les données sont distribuées dans des **tables** `espaces avatars versions notes ...`
- une base SQL n'implémente pas de **Data Sync**. Il n'y pas de moyens pour une connexion cliente de se mettre en veille de mises à jour de certains rows.
- il faut un _serveur_ qui, en plus de servir les transactions de lecture / mises à jour, notifient les sessions clientes vivantes abonnées à ces mises à jour:
  - le serveur dispose de la liste des sessions clientes actives et pour chacune sait aux mises à jour de quels documents elle est _abonnée_.
  - le _serveur_ doit être _up_ a minima tant qu'une session cliente est active.
  - une session sans opérations depuis un certain temps est considérée comme disparue.
  - si le serveur tombe _down_, toutes les sessions en cours sont de facto déconnectées. 
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
  - `qc` : quota de calcul mensuel total en unités monétaires.
- ces quotas sont _indicatifs_ sans blocage opérationnel et servent de prévention à un crash technique pour excès de consommation de ressources.

Ses autres rôles sont :
- la gestion d'une _notification / blocage_ par espace, 
  - soit pour information technique importante, 
  - soit pour _figer_ un espace avant sa migration vers un autre (ou sa destruction).
- l'export de la _base_ d'un espace vers une autre,
- l'export des fichiers d'un espace d'un _Storage_ à un autre.

## Comptable de chaque espace
Pour un espace, `24` par exemple, il existe un compte d'id `2410000000000000` qui est le **Comptable** de l'espace.

## Comptes _normaux_
Il existe deux catégories de comptes:
- **les comptes "O", de l'organisation**, bénéficient de ressources _gratuites_ attribuées par la Comptable et ses _délégués_. En contrepartie de cette _gratuité_ un compte "O" peut être _bloqué_ par le Comptable et ses _délégués_ (par exemple en cas départ de l'organisation).
- **les comptes "A", autonomes**, achètent des ressources sous la forme d'un abonnement et d'une consommation. Tant qu'il est créditeur un compte "A" ne peut pas être bloqué.

> Les abonnements et consommations sont exprimées in fine en _unité monétaire_ virtuelle, le centime (c), dont l'ordre de grandeur est voisin d'un centime d'euro ou de dollar (le _cours_ exact étant fixé par chaque organisation).

### Comptes "O" : _partitions_
Le Comptable dispose des quotas globaux de l'espace attribués par l'administrateur technique. 
- Il définit un certain nombre de **partitions de quotas**.
- Il confie la gestion de chaque partition à des comptes _délégués_ qui peuvent distribuer des quotas de ressources aux comptes "O" affectés à leur partition.

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
- soit d'un compte "A" existant qui à cette occasion fait _cadeau_ au compte sponsorisé d'un montant de son choix prélevé sur son solde monétaire.
- soit par un compte "O" _délégué_ ou par le Comptable: un cadeau de bienvenue de 2c est affecté au solde du compte "A" sponsorisé (prélevé chez personne).

Un compta "A" définit lui-même ses quotas `qn` et `qv` (il les paye en tant _qu'abonnement_) et n'a pas de quotas `qc` (il paye sa _consommation_).

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
- `dlv` : jour d'écriture, du début de _l'upload_ + 1

Ces documents ne sont jamais mis à jour une fois créés, ils sont supprimés,
- en général quasi instantanément dès que _l'upload_ est physiquement terminé,
- sinon par le GC qui considère qu'un upload ne peut pas techniquement être encore en cours à j+2 de son jour de début.

## Documents `fpurges`
- `id` : aléatoire, avec `ns` en tête,
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

# Tables / collections _majeures_ : `partitions comptes comptis invits comptas avatars groupes`
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

### `ivits`
Un document _complémentaire_ de `comptes` (même id) qui donne la liste des invitations aux groupes pour les avatars du compte et en attente d'acceptation ou de refus.

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
### Phrase de création du comptable
- CC : PBKFD de la phrase complète - hCC son hash.
- CR : PBKFD d'un extrait de la phrase - hCR son hash.

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
- il peut s'abonner à certains ceux-ci dits _synchronisés_: une session d'un compte reçoit des _avis de changement_ (pas le contenu) de sous-ensemble de ces documents qui permettent à l'opération `Sync` de tirer les documents ayant changé.
  - sous-arbres synchronisés:
    - **1 espace** : racine et seul document du sous-arbre, un documents `espaces`.
    - **1 compte** : ce sous-arbre identifié par l'id du compte comporte trois documents: `comptes comptis invits`.
    - **N avatars**: il y un sous-arbre _avatar_ par avatar du compte. Le sous-arbre est identifié par l'id de l'avatar racine et comporte les documents `avatars notes sponsorings chats tickets`
    - **N groupes**: il y un sous-arbres _groupe_ par groupe dans lequel un des avatars du compte est actif. Le sous-arbre est identifié par l'id du groupe racine et comporte les documents`groupes notes membres chatgrs`
- documents du périmètre NON _synchronisés_
  - `syntheses partitions`: identifiés par le ns de l'espace.
  - comptas identifié par l'id du compte.
  - ces documents sont transmis aux sessions sur demande explicite.

Exception pour le Comptable: il peut voir **tous** les documents `partitions` de _son_ espace et pas seulement celui de _sa_ partition.

> Les documents d'un _périmètre_ sont sujet à des évolutions en cours de session suite aux effets des opérations soumises au serveur, 
- soit par la session elle-même, 
- soit par n'importe quelle autre, 
- du même compte ou de n'importe quel autre, et marginalement du GC.
- ses changements sont notifiés aux sessions UI quand ils concernent des documents synchronises d'un des _sous-arbres espace / compte / avatar /groupe_.

## Disponibilité en session UI
Une session d'un compte dispose en mémoire de tous les documents synchronisés de son compte:
- chargement initial en début de session,
- puis à réception des avis de changements, rechargement incrémental sélectif des documents ayant changé.

### Avis de changement: document `versions`
Un document _version_ trace une mise à jour, un changement de version d'un document ou plusieurs documents **d'UN** sous-arbre:
- (E) le document `espaces` du compte: 
  - son identifiant est celui de l'espace.
- (C) un des documents `comptes comptis invits` du sous-arbre _compte_: 
  - l'identifiant de l'avis est la propriété immuable `rds` du document `comptes`.
- (A) un ou plusieurs documents d'UN sous-arbre _avatar_: `avatars` **et ses sous-documents** `notes sponsorings chats tickets`.
  - l'identifiant de l'avis est la propriété immuable `rds` du document `avatars` racine du sous-arbre.
- (G) un ou plusieurs documents d'UN sous-arbre _groupe_: `groupes` **et ses sous-documents** `notes membres chatgrs`.
  - l'identifiant de l'avis est la propriété immuable `rds` du document `groupes` racine du sous-arbre.

#### Exemple
- mise à jour d'un chat #5 de l'avatar #13;
- le numéro de version associé au sous-arbre A#13 est incrémenté et passe par exemple de 123 à 124;
- le chat #5 prend pour version 124;
- si une session UI était synchronisée pour l'avatar #13 sur la version 112 par exemple, elle va obtenir tous les sous-documents de cet avatar (lui même inclus) de versions supérieure à 112 -qui ont donc changé depuis 112-. Désormais la session sera synchronisée sur la version 126 (la plus récente) pour cet avatar #13.
- elle n'a pas reçu les très nombreux sous-documents ayant une version antérieure à 112 (n'ayant donc pas changé par rapport à l'état connu en mémoire).

### Remarque
- (1) **en synchronisation directe par Firestore** des lectures sont toujours en attente `onSnapshot` sur "les documents `versions` dont l'id fait partie de la liste de ceux du périmètre":
  - un _callback_ est invoqué à chaque fois qu'un des documents `versions` de la liste change, son _numéro de version_ ayant été incrémenté par un traitement sur le serveur.
  - cet avis concerne donc son `espaces`, soit `compte comptis invits`, soit l'un des documents d'un avatar, soit l'un des documents d'un groupe.
- (2) **en synchronisation par le serveur**, celui-ci transmet par WebSocket un item qui a la forme d'un document `versions`. Le serveur voit passer tous les changements des `versions` et sait quelles sessions sont abonnées à quelles `versions`.

### Les _référence de synchronisation_ : `rds`
`rds` est un identifiant aléatoire sur 16 chiffres attribué à la création du document correspondant racine d'un sous-arbre. 
- les deux premiers chiffres sont le `ns` de l'espace,
- le troisième donne le nom du sous-arbre de documents cible,
  - 1 : `compte` (pour `comptes comptis invits`),
  - 2 : `avatar` (avatar et ses sous-documents)
  - 3 : `groupe` (groupe et ses sous-documents). 
- les 13 suivants sont aléatoires.

> `rds` est **un identifiant alternatif, en bijection avec l'id** du compte, de l'avatar ou du groupe. **Une session ne reçoit du serveur que les `rds` des documents de son périmètre**: elle peut ainsi lancer des lectures _onSnapshot_ sur les documents `versions` dont l'identifiant est un des `rds` de cette liste, et recevoir les avis de changements.

**Remarque:** Si au lieu des `rds` les versions avaient été identifiées directement par les ids des comptes / avatars / groupes, dans le cas (1) _Firestore_ une session ayant un logiciel malicieux _aurait pu_ poser des lectures _onSnapshot_ sur des `versions` de documents hors de son périmètre:
- certes le serveur ne lui aurait délivré aucun document hors de son périmètre,
- mais la session aurait pu en tirer des informations à propos de l'activité (ou l'absence d'activité) d'autres sessions d'autres comptes.
- n'ayant aucun moyen d'obtenir l'id alternative `rds` des comptes / avatars / groupes, cette activité d'espionnage est vouée à l'échec.

> **Les `rds` d'un périmètre sont tous concentrés dans le document `comptes`**: celui du compte et ceux de ses avatars et groupes auxquels un des avatars du compte participe. Ils sont redondés dans chacun des documents par commodité.

**Remarque: `espaces` n'a pas de `rds`**
- son `versions` est directement identifié par le `ns` de l'espace.
- donc des sessions _malicieuses_ peuvent obtenir une information sur le taux d'activité des espaces autres que le leur ... ce qui n'a aucune espèce d'intérêt. Les mises à jour de `espaces` sont fort rares (et de plus les autres espaces que le sien ne sont pas accessibles par une session UI).

## Tracking des créations et mises à jour
**Remarque:** il n'y a pas à proprement parlé de _suppressions_:
- un document `sponsorings` a une date limite de validité: le document est logiquement supprimé dès que cette date est dépassée.
- un document `notes` peut être _vide_, n'a plus de contenu et n'apparaît plus dans les vues, mais son document existe toujours en _zombi_.

Les documents `versions` sont chargés du tracking des mises à jour des documents du périmètre et des sous-documents de `avatars` et de `groupes`. Propriétés:
- `id` : `ns` + _référence data sync_ `rds` du document.
- `v` : version, incrémentée de 1 à chaque mise à jour, soit du document maître, soit de ses sous-documents `notes sponsorings chats tickets membres chatgrs`
- `suppr` : jour de _suppression_ du compte / avatar / groupe (considérés comme _zombi_)

> **Remarque:** Ce principe conduirait à conserver pour toujours la trace de très vielles suppressions. Pour éviter cette mémorisation éternelle sans intérêt, le GC lit les `versions` supprimées depuis plus de N mois pour les purger. Les sessions ont toutes eu le temps d'intégrer les disparitions correspondantes.

**La constante `IDBOBS / IDBOBSGC` de `api.mjs`** donne le nombre de jours de validité d'une micro base locale IDB sans resynchronisation. Celle-ci devient **obsolète** (à supprimer avant connexion) `IDBOBS` jours après sa dernière synchronisation. Ceci s'applique à _tous_ les espaces avec la même valeur.

> Les documents de tracking versions sont purgés `IDBOBSGC` jours après leur jour de suppression `suppr`.

# Détail des tables / collections _majeures_ et leurs _sous-collections_
Ce sont les documents faisant partie d'un périmètre d'un compte: `partitions comptes comptas comptis invits avatars groupes notes sponsorings chats tickets membres chatgrs versions`

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

# Cache locale des `espaces partitions comptes comptis invits comptas avatars groupes versions` dans un serveur
Un _serveur_ ou une _Cloud Function_ qui ne se différencient que par leur durée de vie _up_ ont une mémoire cache des documents:
- `comptes` accédés pour vérifier si les listes des avatars et groupes du compte ont changé.
- `comptis` accédés pour avoir les commentaires et hashtags attachés à ses avatars et groupes par un compte.
- `invits` accédé pour avoir les invitations en attente pour un compte.
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
- `ph`: **photo d'une carte de visite** encodée en base64 URL.
- `tx`: **texte d'une carte de visite**: le début de la _première ligne_ donne un _nom_, le reste est un complément d'information.
- `tx`: **texte d'un échange** sur un `chats` ou `chatgrs`.
- `tx`: **commentaire personnel d'un compte** attaché à un avatar contact (chat ou membre d'un groupe) ou à un groupe.
- `ht` : **hashtags**, suite de mots attachés par un compte à,
  - _un avatar_ (chat ou membre d'un groupe),
  - _un groupe_ dont il est ou a été membre ou au moins invité,
  - _une note_, personnelle ou d'un des groupes où il est actif et a accès aux notes.
- `texte` d'une note personnelle ou d'un groupe.

Les `texte / tx` sont gzippés ou non avant cryptage: c'est automatique dès que le texte a une certaine longueur.

> **Remarque:** Le serveur ne voit **jamais en clair**, aucun texte, ni aucune clé susceptible de crypter un texte, ni la clé K des comptes, ni les _phrase secrètes_ ou _phrases de contacts / sponsorings_.

> Les textes sont cryptés / décryptés par l'application UI. Si celle-ci est malicieuse / boguée, les textes sont illisibles mais finalement pas plus que ceux qu'un utilisateur qui les écrirait en idéogrammes pour un public occidental ou qui inscrirait  des textes absurdes.

# Sous-objet `notification`
Un objet _notification_ est immuable, en cas de _mise à jour_ il est remplacé par un nouveau.

Type des notifications:
- E : _de l'espace_. Elle concerne tous les comptes et est déclarée par l'administrateur du site.
- P : _d'une partition_. Elles concernent chacune tous les comptes "O" **d'une partition**. Elles sont déclarées, soit par le Comptable, soit par un de ses _délégués_ sur cette partition.
- C : _d'un compte_. Elles concernent chacune **un seul compte "O"**.

Une notification a les propriétés suivantes:
- `nr`: restriction d'accès: 
  - 1 : **aucune restriction**. La notification est informative (le texte peut annoncer une restriction imminente).
  - 2 : **restriction réduite**
    - E : espace figé
    - P : accès en lecture seule
    - C : accès en lecture seule
  - 3 : **restriction forte**
    - E : espace clos
    - P : accès minimal
    - C : accès minimal
- `dh` : date-heure de création.
- `texte`: il porte l'information explicative.
  - type E: en clair.
  - types P et C: crypté par la clé P de la partition.
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

Les cartes de visite des avatars sont hébergées dans le document `avatars`, celles des groupes dans leurs documents `groupes`.

Les cartes de visites des avatars sont dédoublées dans d'autres documents:
- `membres` : chaque membre y dispose sa carte de visite.
- `chats` : chaque interlocuteur dispose de la carte de visite de l'autre.

## Mises à jour des cartes de visite des membres
- la première inscription se fait à l'ajout de l'avatar comme _contact_ du groupe.
- le rafraîchissement peut être demandé pour un groupe donné.
  - pour chaque membre, l'opération compare la version détenue dans le membre et la version détenue dans l'avatar. Cette vérification ne fait intervenir que des filtres sur les index si la version dans `membres` est à jour.
  - si la version de `membres` n'est pas à jour, elle est mise à jour. 
- en session, lorsque la page listant les membres d'un groupe est ouverte, elle peut envoyer une requête de rafraîchissement des cartes de visite.

### Mise à jour dans les chats
- à la mise à jour d'un chat, les cartes de visite des deux côtés sont rafraîchies si nécessaire.
- le rafraîchissement peut être demandé pour tous les chats d'un avatar donné.
  - pour chaque chat, l'opération compare la version détenue dans le chat et la version détenue dans l'avatar. Cette vérification ne fait intervenir que des filtres sur les index si la version dans chat est à jour.
  - si la version dans chat n'est pas à jour, elle est mise à jour. 
- en session, lorsque la page listant les chats d'un avatar est ouverte, elle peut envoyer une requête de rafraîchissement des cartes de visite.

# Documents `versions`
Un document `versions` donne la plus haute version d'un sous-arbre:
- compte: `comptes, comptis invits`,
- avatar: `avatars notes sponsorings chats tickets`,
- groupe: `groupes notes membres`.

_data_ :
- `id` : `ns` + `rds` du document référencé.
- `v` : 1..N, plus haute version attribuée aux documents du sous-arbre.
- `suppr` : jour de suppression, ou 0 s'il est actif.

**C'est le seul document qu'une session client est habilitée à lire en direct de la base**, en particulier par une lecture `onSnapshot` qui invoque un _callback_ quand une mise à jour a été détectée (changement de version du sous-arbre).

Quand un document, un `chats` par exemple est mis à jour,
- l'opération lit le document `versions` de son sous-arbre:
  - lecture de l'avatar (racine du sous-arbre) de même `id` que le `chats`,
  - obtention du `rds` de cet avatar et lecture de `versions` ayant ce `rds` pour `id`,
- incrémentation de 1 de `v` de `versions`,
- la version `v` de chats prend cette valeur `v`,
- mise à jour de `versions` et `chats`.
- la version `v` est celle de tout le sous-arbre, la plus haute attribuée à un document du sous-arbre.

> Les lectures des documents NON synchronisées du périmètre du compte passent obligatoirement par le _serveur / Cloud Function_ afin d'être certain que la session cliente est habilitée à cette lecture en fonction de son authentification: ceci garantit que les données _hors périmètre_ d'un compte ne sont pas accessibles. Certaines propriétés de certains documents ne sont pas transmises aux sessions UI.

## Documents `espaces`
Ces documents sont créés par l'administrateur technique à l'occasion de la création de l'espace et du Comptable correspondant.

**Il est _synchronisé_:**
- à chaque mise à jour d'un document `espaces` le document `versions` **de même id** porte la nouvelle version.
- en session en mode _Firestore_ l'écoute `onSnapshot` du document `versions` portant l'id de l'espace permet d'être notifié de son évolution.
- la lecture effective du document vérifie l'habilitation à sa lecture et ne transmet que les propriétés autorisées.
- le fait de ne pas recours à un `rds` différent de l'id:
  - simplifie la procédure de synchronisation.
  - si une session _malicieuse_ se met à l'écoute de versions autres que celles de son espace, elle obtient une information sur la fréquence de mise à jour des autres espaces (très faible), sans pouvoir accéder à leurs contenus (soit une donnée quasiment sans intérêt).

**Les sessions sont systématiquement synchronisées à _leur_ espace.** Elles sont ainsi informées à tout instant d'un changement des notifications,
- E de l'espace lui-même,
- de leur partition (pour un compte "O").

> **Remarque**: les notifications C (de compte) sont portées par les documents `partitions` et `comptes` et sont synchronisées par lui. C'est aussi le cas des dépassements de seuils (`pcn pcv` pour les quotas, `pcc nbj` pour la consommation) qui remontent de `comptas` à `comptes` lors de franchissement de variation significative -5% ou 5 jours- (pas à chaque opération).

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
- `opt`: option des comptes autonomes.
- `nbmi`: nombre de mois d'inactivité acceptable pour un compte "O" fixé par le comptable. Ce changement n'a pas d'effet rétroactif.
- `tnotifP` : table des notifications de niveau _partition_.
  - _index_ : id (numéro) de la partition.
  - _valeur_ : notification (ou `null`), texte crypté par la clé P de la partition.

_Remarques:_
- `opt nbmi` : sont mis à jour par le Comptable. `opt`:
  - 0: 'Pas de comptes "autonomes"',
  - 1: 'Le Comptable peut rendre un compte "autonome" sans son accord',
  - 2: 'Le Comptable NE peut PAS rendre un compte "autonome" sans son accord',
- `tnotifP` : mise à jour par le Comptable et les délégués des partitions.

**Propriétés accessibles :**
- administrateur technique : toutes de tous les espaces.
- Comptable : toutes de _son_ espace.
- Autres comptes: celles de leur espace sauf `moisStat moisStatT dlvat nbmi`.

**Au début de chaque opération, l'espace est lu afin de vérifier la présence de notifications E et P** (éventuellement restrictives) de l'espace et de leur partition (pour un compte "O"):
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
- l'usage d'un `nbmi` à 3 mois se justifie par exemple pour un site de démonstration où les comptes sont fictifs et s'auto-détruisent rapidement.

> Il n'y a aucun moyen dans l'application pour contacter le titulaire d'un compte dans la _vraie_ vie, aucun identifiant de mail / téléphone, etc.

# Document `syntheses` d'un espace
Ces documents sont identifiés par le `ns` de leur espace. Ils ne sont pas synchronisés, les sessions UI les demandent explicitement,
- pour l'administrateur technique,
- pour le Comptable.

_data_:
- `id` : ns de son espace.
- `v` : version, numéro d'ordre de mise à jour.

- `dh` : date-heure de dernière mise à jour (à titre informatif).
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

Le document `syntheses` est mis à jour à chaque fois qu'un document `partitions` l'est: le `synth` de la partition est reporté dans l'élément d'indice correspondant de `tsp`. En cas de suppression d'une partition son entrée est supprimée.

# Documents `partitions` des partitions d'un espace
Une partition est créée par le Comptable qui peut la supprimer quand il n'y a plus de comptes attachés à elle. 
- L'identifiant d'une partition est un numéro d'ordre de 1 à N attribué en séquence par le Comptable à sa création.

**La clé P d'une partition** sert uniquement à crypter les textes des notifications de niveau _P partition_ ou C relatif à un compte.
- elle est générée à la création de la partition,
- elle est transmise aux comptes rattachés qui la détiennent dans la propriété `clePK`,
  - soit à leur création par sponsoring : elle est cryptée par la clé K du compte créé.
  - soit quand le compte change de partition (par le Comptable) ou passe de compte "A" à compte "O" par un délégué ou le Comptable: elle est cryptée par la clé publique RSA du compte.

**Un document partition est explicitement demandé** (pas d'abonnement) par une session,
- soit du Comptable,
- soit d'un délégué.
-  soit d'un compte "O" non délégué. Dans ce cas:  
  - dans la map `mcpt`, seules les entrées des délégués sont non null.
  - les compteurs de quotas / consommation d'un délégué sont à 0.
  - la `cleAP` est disponible ce qui permet de contacter les _délégués_ pour un _chat d'urgence_.

**Principales opérations**
- attachement / détachement d'un compte à une partition.
- attribution / retrait de son statut de délégué.
- pose / retrait d'une notification de niveau P ou C (pour un seul compte). La notification C est redondée dans le compte.
- modification des quotas globaux de la partition.
- modification des quotas attribués à un compte.

#### Incorporation des consommations des comptes
Les compteurs de consommation d'un compte extraits de `comptas` sont recopiés à l'occasion de la fin d'une opération:
- dans les compteurs `{ qc, qn, qv, pcc, pcn, pcv, nbj }` du document `comptes`,
- pour un compte "O" dans les compteurs `q: { qc qn qv c2m nn nc ng v }` de l'entrée du compte dans son document `partitions`.
  - en conséquence la ligne de synthèse de sa partition est reportée dans l'élément correspondant de son document `syntheses`.
- afin d'éviter des mises à jour trop fréquentes, la procédure de report n'est engagée qui si les compteurs `pcc pcn pcv` passe un cap de 5% ou que `nbj` passe un cap de 5 jours.

> **Remarque**: la modification d'un compteur de quotas `qc qn qv` provoque cette procédure de report `comptas -> comptes -> partitions -> syntheses` à chaque évolution et sans effet de seuil. 

_data_:
- `id` : numéro de partition attribué par le Comptable à sa création.
- `v` : 1..N

- `nrp`: niveau de restriction de la notification (éventuelle) de niveau _partition_ mémorisée dans `espaces` et dont le texte est crypté par la clé P de la partition.
- `q`: `{ qc, qn, qv }` quotas globaux attribués à la partition par le Comptable.
- `mcpt` : map des comptes "O" attachés à la partition. 
  - _clé_: id du compte.
  - _valeur_: `{ cleA, del, q }`
    - `notif`: notification du compte cryptée par la clé P de la partition (redonde celle dans compte).
    - `cleAP` : clé A du compte crypté par la clé P de la partition.
    - `del`: `true` si c'est un délégué.
    - `q` : `qc qn qv c2m nn nc ng v` extraits du document `comptas` du compte.
      - `c2m` est le compteur `conso2M` de compteurs, montant moyen _mensualisé_ de consommation de calcul observé sur M/M-1. 

`mcpt` compilé en session - Ajout à `q` :
  - `pcc` : pourcentage d'utilisation de la consommation journalière `c2m / qc`
  - `pcn` : pourcentage d'utilisation effective de qn : `nn + nc ng / qn`
  - `pcv` : pourcentage d'utilisation effective de qc : `v / qv`

**Un objet `synth` est calculable** (en session ou dans le serveur):
- `qt` : les totaux des compteurs `q` : (`qc qn qv c2m n (nn+nc+ng) v`) de tous les comptes,
- `ntf`: [1, 2, 3] - le nombre de comptes ayant des notifications de niveau de restriction 1 / 2 / 3. 
- `nbc nbd` : le nombre total de comptes et le nombre de délégués.
- _recopiés de la racine dans `synth`_ : `id nrp q`
- plus, calculés localement :
  - `pcac` : pourcentage d'affectation des quotas : `qt.qc / q.qc`
  - `pcan` : pourcentage d'affectation des quotas : `qt.qn / q.qn`
  - `pcav` : pourcentage d'affectation des quotas : `qt.qv / q.qv`
  - `pcc` : pourcentage d'utilisation de la consommation journalière `qt`.`c2m / q.qc`
  - `pcn` : pourcentage d'utilisation effective de `qn` : `qt.n / q.qn`
  - `pcv` : pourcentage d'utilisation effective de `qc` : `qt.v / q.qv`

## Documents `comptes`
Un document `comptes` est identifié par l'id du compte: il est **synchronisé en session par son `rds`** et y est toujours disponible à jour. Sa _lecture_ ne se fait que par l'opération `Sync`.

_data_ :
- `id` : numéro du compte = id de son avatar principal.
- `v` : 1..N.
- `hXR` : `ns` + `hXR`, hash du PBKFD d'un extrait de la phrase secrète.
- `dlv` : dernier jour de validité du compte.

- `rds`:
- `hXC`: hash du PBKFD de la phrase secrète complète (sans son `ns`).
- `cleKXC` : clé K cryptée par XC (PBKFD de la phrase secrète complète).
- `cleEK` : pour le Comptable, clé de l'espace cryptée par sa clé K à la création de l'espace pour le Comptable. Permet au comptable de lire les reports créés sur le serveur et cryptés par cette clé E.
- `privK` : clé privée RSA de son avatar principal cryptée par la clé K du compte.

- `dhvuK` : date-heure de dernière vue des notifications par le titulaire du compte, cryptée par la clé K.
- `qv` : `{ qc, qn, qv, pcc, pcn, pcv, nbj }`
  - `pcc, pcn, pcv, nbj` : remontés de `compta` en fin d'opération quand l'un d'eux passe un seuil de 5% / 5j, à la montée ou à la descente.
    - `pcc` : pour un compte O, pourcentage de sa consommation mensualisée sur M/M-1 par rapport à son quota `qc`.
    - `nbj` : pour un compta A, nombre de jours estimés de vie du compte avant épuisement de son solde en prolongeant sa consommation des 4 derniers mois et son abonnement `qn qv`.
    - `pcn` : pourcentage de son volume de notes / chats / groupes par rapport à son quota qn.
    - `pcv` : pourcentage de son volume de fichiers par rapport à son quota qv.
  - `qc qn qv` : mise à jour immédiate en cas de changement des quotas.
    - pour un compte "O" identiques à ceux de son entrée dans partition.
    - pour un compte "A", `qn qv` donné par le compte lui-même.
    - en cas de changement, les compteurs de consommation sont remontés. 
    - permet de calculer en session les alertes de quotas et de consommation.

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

# Documents `comptis`
Ils sont identifiés pat l'id de leur compte, créé et purgé avec lui. C'est une prolongation du document `comptes` portant des informations personnelles (texte et hashtags) à propos des avatars et groupes connus du compte.

**Ils sont synchronisés par le `rds` du compte:** la _lecture_ en session ne s'effectue que par l'opération `Sync`.

_data_:
- `id` : id du compte.
- `v` : version.

- `rds`:
- `mc` : map des contacts (des avatars) et des groupes _connus_ du compte,
  - _cle_: `id` court de l'avatar ou du groupe,
  - _valeur_ : `{ ht, tx }`. Hashtags et texte attribués par le compte.
    - `ht` : suite des hashtags séparés par un espace et cryptée par la clé K du compte.
    - `tx` : commentaire gzippé et crypté par la clé K du compte.

# Documents `invits`
Ils sont identifiés pat l'id de leur compte, créé et purgé avec lui. C'est une prolongation du document `comptes` portant la liste des invitations à des groupes adressées à un des avatars du compte.

**Ils sont synchronisés par le `rds` du compte:** la _lecture_ en session ne s'effectue que par l'opération `Sync`.

_data_:
- `id` : id du compte.
- `v` : version.

- `rds`:
- `invits`: liste des invitations en cours:
  - _valeur_: `{idg, ida, cleGA, cvG, ivpar, dh}`
    - `idg`: id du groupe,
    - `ida`: id de l'avatar invité
    - `cleGA`: clé du groupe crypté par la clé A de l'avatar.
    - `cvG` : carte de visite du groupe (photo et texte sont cryptés par la clé G du groupe).
    - `flags` : d'invitation.
    - `invpar` : `[{ cleAG, cvA }]`
      - `cleAG`: clé A de l'avatar invitant crypté par la clé G du groupe.
      - `cvA` : carte de visite de l'invitant (photo et texte sont cryptés par la clé G du groupe). 
    - `msgG` : message de bienvenue / invitation émis par l'invitant.

Pour un simple contact:
- `flags` est à 0
- `msgG` est null
- `invpar` reflète dans le cas des invitations unanimes, la liste des votants _pour_ à cet instant.

Un _contact_ peut se faire effacer des contacts du groupe et s'inscrire en liste noire.

# Documents `comptas`
**Ces documents de même id que leur compte est lu à chaque début d'opération et mis à jour par l'opération.**
- si ses compteurs `pcc, pcn, pcv, nbj` _ont changé d'ordre de grandeur_ (5% / 5j) ils sont reportés dans le document `comptes`: ce dernier ne devrait, statistiquement, n'être mis à jour que rarement en fin d'opération.

**Les documents ne sont PAS synchronisés.** La lecture est à la demande par les sessions, ce qui permet de vérifier qui le demande: compte lui-même, Comptable, un délégué de sa partition pour un compte "O".

_data_:
- `id` : numéro du compte = id de son avatar principal.
- `v` : 1..N. Sa version lui est spécifique.

- `qv` : `{qc, qn, qv, nn, nc, ng, v}`: quotas et nombre de groupes, chats, notes, volume fichiers. Valeurs courantes.
- `compteurs` sérialisation des quotas, volumes et coûts.
- _Comptes "A" seulement_
  - `solde`: résultat, 
    - du cumul des crédits reçus depuis le début de la vie du compte (ou de son dernier passage en compte A), 
    - plus les dons reçus des autres,
    - moins les dons faits aux autres.
  - `tickets`: map des tickets / dons:
    - _clé_: `ids`
    - _valeur_: `{dg, dr, ma, mc, refa, refc, di}`
  - `dons` : liste des dons effectués / reçus `[{ dh, m, iddb }]`
    - `dh`: date-heure du don
    - `m`: montant du don (positif ou négatif)
    - `iddb`: id du donateur / bénéficiaire (selon le signe de `m`).

# Documents `avatars`
Un compte a un avatar principal de même id que lui et peut avoir des avatars secondaires ayant chacun leur propre id.

_data_:
- `id` : id de l'avatar.
- `v` : 1..N. Par convention, une version à 999999 désigne un **avatar logiquement détruit** mais dont les données sont encore présentes. L'avatar est _en cours de suppression_.
- `vcv` : version de la carte de visite afin qu'une opération puisse détecter (sans lire le document) si la carte de visite est plus récente que celle qu'il connaît.
- `hZR` : `ns` + hash du PBKFD de la phrase de contact réduite.

- `rds` : pas transmis en session. Redondance du `rds` dans `mav` de son compte: beaucoup d'opérations de mise à jour du sous-arbre d'un avatar n'ont pas facilement accès à son compte (chats par exemple).
- `idc` : id du compte de l'avatar (égal à son id pour l'avatar principal).
- `cleAZC` : clé A cryptée par ZC (PBKFD de la phrase de contact complète).
- `pcK` : phrase de contact complète cryptée par la clé K du compte.
- `hZC` : hash du PBKFD de la phrase de contact complète.

- `cvA` : carte de visite de l'avatar `{id, v, photo, texte}`. photo et texte cryptés par la clé A de l'avatar.

- `pub privK` : couple des clés publique / privée RSA de l'avatar.

## Résiliation d'un avatar
Elle est effectuée en deux phases:
- **une transaction courte immédiate:**
  - marque le document `versions` de l'avatar à _supprimé_ (`suppr` porte la date du jour).
  - marque la version `v` de l'avatar à 999999.
  - purge ses documents `sponsorings`.
  - dès lors l'avatar est _logiquement_ supprimé.
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

- `rds`:
- `dg` : date de génération.
- `dr`: date de réception. Si 0 le ticket est _en attente_.
- `ma`: montant déclaré émis par le compte A.
- `mc` : montant déclaré reçu par le Comptable.
- `refa` : code court (32c) facultatif du compte A à l'émission.
- `refc` : code court (32c) facultatif du Comptable à la réception.
- `disp`: true si le compte était disparu lors de la réception.
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
- la date d'incorporation `di` est inscrite, le ticket est _réceptionné_.
- le ticket est mis à jour dans `tickets` et dans la liste `comptas.tickets` du compte A: **le compte A est crédité**.

#### Lorsque le compte A va sur sa page de gestion de ses crédits
- les tickets dont il possède une version plus ancienne que celle détenue dans `tickets` du Comptable sont mis à jour.
- les tickets émis un mois M toujours non réceptionnés avant la fin de M+2 sont supprimés.
- les tickets de plus de 2 ans sont supprimés.

**Remarques:**
- de facto dans `tickets` un document ne peut avoir qu'au plus deux versions.
- la version de création qui créé le ticket et lui donne son identifiant secondaire et inscrit les propriétés `ma` et éventuellement `refa` désormais immuables.
- la version de réception par le Comptable qui inscrit les propriétés `di mc` et éventuellement `refc`. Le ticket devient immuable dans `tickets`.
- les propriétés sont toutes immuables.

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

> **Personne, pas même le Comptable,** ne peut savoir quel compte "A" a généré quel ticket. Cette information n'est accessible qu'au compte lui-même et est cryptée par sa clé K (le serveur connaît cette information mais elle est cryptée par la clé du site).

# Documents `chats`
Un chat est une suite d'items de texte communs à deux avatars I et E:
- vis à vis d'une session :
  - I est l'avatar _interne_,
  - E est un avatar _externe_ connu comme _contact_.
- un item est défini par :
  - le côté qui l'a écrit (I ou E),
  - sa date-heure d'écriture qui l'identifie pour son côté,
  - sa date-heure de suppression s'il a été supprimé.
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
- `ids`: aléatoire.
- `v`: 1..N.
- `vcv` : version de la carte de visite de E.

- `rds`:
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
- vérification qu'il existe un sponsoring créé par `idE` et qu'il accepte le chat.
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

- `rds`:
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

- `rds`:
- `im` : exclusivité dans un groupe. L'écriture est restreinte au membre du groupe dont `im` est `ids`. 
- `vf` : volume total des fichiers attachés.
- `ht` : liste des hashtags _personnels_ cryptée par la clé K du compte.
  - En session, pour une note de groupe, `ht` est le terme de `htm` relatif au compte de la session.
- `htg` : note de groupe : liste des hashtags cryptée par la clé du groupe.
- `htm` : note de groupe seulement, hashtags des membres. Map:
    - _clé_ : id courte du compte de l'auteur,
    - _valeur_ : liste des hashtags cryptée par la clé K du compte.
    - non transmis en session.
- `l` : liste des _auteurs_ (leurs `im`) pour une note de groupe.
- `d` : date-heure de dernière modification du texte.
- `texte` : texte (gzippé) crypté par la clé de la note.
- `mfa` : map des fichiers attachés.
- `ref` : triplet `[id, ids]` référence de sa note _parent_:

**A propos de `ref`**:
- Pour un note de groupe:
  - absent: rattachement _virtuel_ au groupe lui-même.
  - `[id, ids]` : 
    - `id`: du groupe (de la note), 
    - `ids`: de la note du groupe à laquelle elle est rattachée (possiblement supprimée)
- Pour un note personnelle:
  - absent: rattachement _virtuel_ à l'avatar de la note.
  - `[id, ids]` : 
    - `id`: de l'avatar (de la note), 
    - `ids`: de la note de l'avatar à laquelle elle est rattachée (possiblement supprimée).
  - `[id, 0]` : 
    - `id`: d'UN GROUPE, 
    - rattachement _virtuel_ au groupe lui-même, possiblement disparu / radié.
  - `[id, ids]` : 
    - `id`: d'UN GROUPE, possiblement disparu / radié.
    - `ids`: de la note de ce groupe à laquelle elle est rattachée (possiblement supprimée).

**Une note peut être logiquement supprimée**. Afin de synchroniser cette forme particulière de mise à jour le document est conservé _zombi_ (sa _data_ est `null`). La note sera purgée un jour avec son avatar / groupe.

**Pour une note de groupe**, la propriété `htm` n'est pas transmise en session: l'item correspondant au compte est copié dans `ht`.

## Map des fichiers attachés
- _clé_ `idf`: numéro aléatoire généré à la création. L'identifiant _externe_ est `id_court` du groupe / avatar, `idf`
- _valeur_ : `{ nom, info, dh, type, gz, lg, sha }` 

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
- son (unique) sous-document `chatgrs` (dont `ids` est `1`).
- ses membres: des documents de sa sous-collection `membres`.

**Droits d'accès d'un membre.**

Um membre peut se _restreindre_ lui-même les accès suivants:
- [AM] : accès aux membres et au chat du groupe.
- [AN] : accès aux notes du groupe.

Il peut avoir les deux (cas général) ou n'en avoir aucun ce qui:
- limite son accès au groupe à la lecture de la carte de visite du groupe.
- pour un un animateur il peut être _hébergeur_.

Des droits d'accès sont conférés par un animateur (indépendamment de [AM] / [AN]):
- [DM] **d'accès à la liste des membres**.
- [DN] **d'accès en lecture aux notes du groupe**.
- [DE] **droits d'écriture sur les notes du groupe** (ce qui implique DN).

L'accès [AM] ([AN]):
- vrai: DES QUE le membre a le droit [DM], il accède aux membres. 
- faux: il n'accède pas aux membres **même s'il en le droit** par [DM].

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
- 0 : **radié**: c'est un ex-membre désormais _inconnu_, peut-être disparu, son id est perdu (`tid[im]` vaut 0).
- 1 : **contact** proposé pour une éventuelle invitation future par un membre ayant un droit d'accès aux membres.
  - l'avatar n'est pas au courant et ne peut rien faire dans le groupe.
  - les membres du groupe peuvent voir sa carte de visite.
  - un animateur peut le faire passer en état _invité_ ou _le radier_ (avec ou sans inscription en liste noire _groupe_).
- 2 / 3 : **pré-invité / invité**: 
  - 2 : **pré-invité : en attente de votes** quand un vote unanime est requis. Un ou plusieurs animateurs ont voté pour inviter le contact, mais pas tous.
    - l'avatar n'est pas au courant et ne peut rien faire dans le groupe.
    - les membres du groupe peuvent voir sa carte de visite.
    - les animateurs peuvent:
      - voter pour, effacer leur vote, changer les conditions d'invitation. Quand tous les animateurs ont voté pour, l'avatar devient _invité_.
      - _le radier_ (avec ou sans inscription en liste noire _groupe_) ou annuler l'invitation et le conserver comme simple contact.
  - 3 : **invité: en attente de réponse** quand le dernier animateur a voté (ou le premier pour les groupes à invitation simple), l'invitation a été transmise à l'avatar invité.
    - l'avatar proposé est au courant, il a une _invitation_ dans son compte (`invits`).
    - les membres du groupe peuvent voir sa carte de visite et les droits d'accès qui seront appliqués si l'avatar accepte l'invitation.
    - un animateur peut:
      - changer ses droits d'accès futurs.
      - _le radier_ (avec inscription en liste noire _groupe_) ou annuler l'invitation et le conserver comme simple contact.
    - l'avatar peut,
      - accepter l'invitation: il passera en état _actif_ ou _animateur_.
      - refuser l'invitation et _s'auto-radier_ (avec ou sans inscription en liste noire _compte_) ou redevenir simple contact.
- 4 / 5 : **actif** 
  - 4 : **non animateur**
    - l'avatar a le groupe enregistré dans son compte (`mpg`).
    - il peut:
      - changer son accès aux membres et aux notes (mais pas ses droits).
      - _s'auto-radier_ (avec on sans inscription en liste noire _compte_) ou redevenir simple contact.
    - un animateur peut:
      - changer ses droits d'accès (mais pas ses accès effectifs qui sont du ressort du membre).
      - le radier, avec ou sans inscription en en liste noire _groupe_ ou simplement le ramener en statut _contact_.
  - 5 : **animateur**. _actif_ avec privilège d'animation.
    - un autre animateur ne peut ni changer ses droits, ni le radier, ni lui retirer son statut d'animateur (mais lui-même peut le faire).

Le nombre de notes pris en compte dans la comptabilité du compte:
- est incrémenté de 1 quand il accepte une invitation,
- est décrémenté de 1 quand il est radié ou redevient simple contact.

Dès qu'un membre a un statut:
- un indice `im` lui est attribué en séquence du dernier attribué (taille de `tid`). 
- ses accès et droits sont consignés dans la table `flags` à l'indice `im`.
- il a un document `membres` associé: `ids`, l'identification relative du membre dans le groupe est son indice `im`.

## Radiations et inscriptions en liste noires `lng lnc`
La liste noire `lng` est la liste des id des membres que l'animateur ne veut plus voir réapparaître dans le groupe après leur radiation.

La liste noire `lnc` est la liste des id des membres qui se sont auto-radiés en indiquant ne jamais vouloir être connu du groupe à l'avenir.

Un animateur peut radier un membre, sauf les autres animateurs.

Un membre actif peut _s'auto-radier_:
- il ne verra plus le groupe dans sa liste des groupes.
- sans inscription en liste noire, il pourra ultérieurement être réinscrit comme contact ou réinvité comme s'il n'avait jamais participé au groupe.
- avec inscription en liste noire il pourra plus jamais ultérieurement être réinscrit comme contact ou réinvité.

A la radiation d'un membre d'indice `im`:
- son document `membres` est logiquement détruit (passe en _zombi_).
- il peut être inscrit dans les listes noires `lng lnc`.
- ses entrées dans `tid st flags` sont à 0.

Un membre actif peut décider de redevenir _simple contact_:
- il ne verra plus le groupe dans sa liste des groupes.
- une trace historique simplifiée de son existence subsiste: a) dans ses flags (HM HN HE), b) dans les dates importantes dans son document membre.

> Quand le GC découvre la _disparition_ du compte d'un avatar membre, il s'opère l'équivalent d'une radiation sans mise en liste noire (mais l'avatar ne reviendra jamais).

## Création d'un membre
Le membre _fondateur_ du groupe a un _indice_ `im` 1 et est créé au moment de la création du groupe:
- dans la table `flags` à l'indice `im`: `DM DN DE AM AN HM HN HE`
  - il a _droit_ d'accès aux membres et aux notes en écriture,
  - ses accès aux membres et notes sont ouverts,
  - il a pour statut `st[1]` _animateur_.
- son id figure en `tid[1]`.

Les autres membres sont créés, lorsqu'ils sont soit proposés comme contact, soit invités.
- un indice `im` est pris en séquence, `tid[im]` contient leur id.
- leur document `membres` est créé. 
- _proposition de contact_: leurs flags sont à 0, son statut est à 1.
- _invitation_: 
  - des flags donnent les _droits_ futurs DM DN DE et _animateur_ selon le choix de l'animateur.
  - une **invitation** est insérée dans leur avatar.

> Réapparition d'un membre après _radiation sans liste noire_ par un animateur.
Un animateur peut radier un avatar sans le mettre en liste noire. L'avatar peut être réinscrit comme contact / réinvité plus tard et aura un nouvel indice et un nouveau document `membres`, son historique est vierge. 

## Modes d'invitation
- _simple_ : dans ce mode (par défaut) un _contact_ du groupe peut-être invité par **UN** animateur (un seul suffit).
- _unanime_ : dans ce mode il faut que **TOUS** les animateurs aient validé l'invitation (le dernier ayant validé provoquant l'invitation).
- pour passer en mode _unanime_ il suffit qu'un seul animateur le demande.
- pour revenir au mode _simple_ depuis le mode _unanime_, il faut que **TOUS** les animateurs aient validé ce retour.

Une invitation est enregistrée dans la liste `invits` du compte de l'avatar invité:
- `invits` du document `invits`: `[{idg, ida, cleGA, cvG, invpar, txtG}]`
  - `idg`: id du groupe,
  - `ida`: id de l'avatar
  - `cleGA`: clé du groupe crypté par la clé A de l'avatar.
  - `cvG` : carte de visite du groupe (photo et texte sont cryptés par la clé G du groupe).
  - `flags` : d'invitation. Animateur DM DN DE.
  - `invpar` : `[{ cleAG, cvA }]`
    - `cleAG`: clé A de l'avatar invitant crypté par la clé G du groupe.
    - `cvA` : carte de visite de l'invitant (photo et texte sont cryptés par la clé G du groupe). 
  - `msgG` : message de bienvenue / invitation émis par l'invitant.

Ces données permettent à l'invité de voir en session les cartes de visite du groupe et du ou des invitants ainsi que le texte d'invitation (qui figure également dans le chat du groupe). Le message de remerciement en cas d'acceptation ou de refus sera également inscrit dans le chat du groupe.

### Invitations en cours: `invits`
Cette map de `groupes` a une entrée par invitation _ouverte_ et pas encore ni acceptée ni refusée ni même totalement votée: `{ fl, li[] }`
- `fl` : flags d'invitation. Droits futurs DM DN DE et pouvoir d'animation.
- `li` :
  - liste des `im` des animateurs ayant voté l'invitation pour un mode unanime.
  - pour un mode d'invitation simple, il n'y a qu'un terme.

Quand l'invitation a été acceptée ou refusée, l'entrée correspondante dans `invits` est détruite.

Quand l'invitation est encore _en vote_ (statut 2), les listes `li` sont remises à jour quand un des animateurs cités n'est plus _actif animateur_.

## Un membre peut avoir plusieurs périodes d'activité
- il est inscrit une fois comme _contact_ puis est _invité_.
- il accepte l'invitation et devient actif.
- il décide de redevenir _simple contact_ (sans se radier): sa période d'activité se termine.
- il est à nouveau _invité_ et accepte son invitation: sa deuxième période d'activité commence.

Tant que le membre,
- ne s'est pas auto-radié,
- n'a pas été radié par un animateur,
- il conserve son indice `im`, son document `membres` et une trace des périodes d'activité:
  - ses flags `HM HN HE` indiquent sommairement s'il a eu _un jour_ accès aux membres, accès aux notes en lecture ou en écriture.
  - dans son document `membres`, les couples de dates de début de la première période et de fin de la dernière période d'activité, d'accès aux membres et aux notes en lecture ou écriture.

## Hébergement par un membre _actif_
L'hébergement d'un groupe est noté par :
- `imh`: indice membre de l'avatar hébergeur. 
- `idh` : id du **compte** de l'avatar hébergeur. **Cette donnée n'est pas transmise aux sessions**.
- `dfh`: date de fin d'hébergement qui vaut 0 tant que le groupe est hébergé. Les notes ne peuvent plus être mises à jour _en croissance_ quand `dfh` existe.

### Prise d'hébergement
- en l'absence d'hébergeur, c'est possible pour,
  - tout animateur,
  - en l'absence d'animateur: tout actif ayant le droit d'écriture des notes, puis tout actif ayant accès aux notes, puis tout actif.
- s'il y a déjà un hébergeur, seul un animateur peut se substituer à l'hébergeur actuel.
- dans tous les cas c'est à condition que le nombre de notes `nn` et le volume de fichiers actuels `vf` ne le mette pas en dépassement de son abonnement.

### Fin d'hébergement par l'hébergeur
- `dfh` est mise la date du jour + 90 jours.
- le nombre de notes `ng` et le volume `v` de `comptas` sont décrémentés de ceux du groupe.

Au dépassement de `dfh`, le GC détruit le groupe.

## Data
_data_:
- `id` : id du groupe.
- `v` :  1..N, Par convention, une version à 999999 désigne un **groupe logiquement détruit** mais dont les données sont encore présentes. Le groupe est _en cours de suppression_.
- `dfh` : date de fin d'hébergement.

- `rds`: 
- `nn qn vf qv`: nombres de notes actuel et maximum attribué par l'hébergeur, volume total actuel des fichiers des notes et maximum attribué par l'hébergeur.
- `idh` : id du compte hébergeur (pas transmise aux sessions).
- `imh` : indice `im` du membre dont le compte est hébergeur.
- `msu` : mode _simple_ ou _unanime_.
  - `null` : mode simple.
  - `[ids]` : mode unanime : liste des indices des animateurs ayant voté pour le retour au mode simple. La liste peut être vide mais existe.
- `invits` : map `{ fl, li[] }` des invitations en attente de vote ou de réponse. Clé: `im` du membre invité.
- `tid` : table des ids courts des membres.
- `st` : table des statuts.
- `flags` : tables des flags.
- `lng` : liste noire _groupe_ des ids (courts) des membres.
- `lnc` : liste noire _compte_ des ids (courts) des membres.
- `cvG` : carte de visite du groupe, textes cryptés par la clé du groupe `{v, photo, info}`.

## Décompte des participations à des groupes d'un compte
- quand un avatar a accepté une invitation, il devient _actif_ et a une nouvelle entrée dans la liste des participations aux groupes (`mpg`) dans l'avatar principal de son compte.
- quand l'avatar est radié cette entrée est supprimée.
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

- `rds`:
- `dpc` : date de premier contact.
- `ddi` : date de la dernière invitation (envoyée au membre, c'est à dire _votée_).
- **dates de début de la première et fin de la dernière période...**
  - `dac fac` : d'activité.
  - `dln fln` : d'accès en lecture aux notes.
  - `den fen` : d'accès en écriture aux notes.
  - `dam fam` : d'accès aux membres.
- `cleAG` : clé A de l'avatar membre cryptée par la clé G du groupe.
- `cvA` : carte de visite du membre `{id, v, photo, info}`, textes cryptés par la clé A de l'avatar membre.
- `msgG`: message d'invitation crypté par la clé G pour une invitation en attente de vote ou de réponse. 

> Un message d'invitation est aussi inscrit dans le chat du groupe ou figure aussi la réponse de l'invité. `msgG` est effacé après acceptation ou refus, mais pas les items correspondants dans le chat.

## Opérations
### Par un animateur:
- Inscription en contact - 0 -> 1

- Radiation d'un contact - 1 -> 0
- Invitation simple - 1 -> 3
- Annulation d'invitation - 2 / 3
  - et retour en contact -> 1
  - et radiation sans inscription en liste noire G -> 0
  - et radiation avec inscription en liste noire G -> 0
- Vote d'invitation - 2 
  - vote pour -> 2 ou 3
  - retrait d'un vote pour
- Modification des conditions d'invitation - 2 / 3. Pour le mode _unanime_ revient à 2 (votes annulés)
- Modification des droits d'accès - 4 / 5
- Radiation d'un membre actif - 4 / 5
  - et retour en contact -> 1
  - et radiation sans inscription en liste noire G -> 0
  - et radiation avec inscription en liste noire G -> 0

### Par le membre lui-même:
- Acceptation d'invitation - 3 -> 4 / 5
- Refus d'une invitation - 3 
  - et retour en contact -> 1
  - et radiation sans inscription en liste noire C -> 0
  - et radiation avec inscription en liste noire C -> 0
- Modification des accès membre / note et statut d'animateur - 4 / 5 -> 4 (si retrait animateur)
- Auto-radiation - 4 / 5
  - et retour en contact -> 1
  - et radiation sans inscription en liste noire C -> 0
  - et radiation avec inscription en liste noire C _> 0

### Inscription en contact
- s'il est en liste noire, refus.
- attribution de l'indice `im`.
- un row `membres` est créé.

### Invitation par un animateur
- choix des _droits_ et inscription dans `invits` du compte de l'avatar.
- vote d'invitation (en mode _unanime_):
  - si tous les animateurs ont voté, inscription dans `invits` du compte de l'avatar.
  - si le votant change les _droits_, les autres votes sont annulés.
- `ddi` est remplie dans `membres`.

### Annulation d'invitation par un animateur
- effacement de l'entrée de l'id du groupe dans `invits` du compte de l'avatar.

### Radiation par un animateur (avec ou sans liste noire)
- le statut passe de 1-2 (sinon erreur) à 0.
- s'il était invité, effacement de l'entrée de l'id du groupe dans `invits` de l'avatar.
- inscription éventuelle en liste noire `lng`.
- le document `membres` devient _zombi_.

### Refus d'invitation par le compte
- mise à 0 du statut, des flags et de l'entrée dans `tid`.
- document `membres` mis en _zombi_
- Option liste noire: inscription dans `lnc`.
- son item dans `invits` du compte de son avatar est effacé.

### Acceptation d'invitation par le compte
- dans l'avatar principal du compte un item est ajouté dans `mpg`,
- dans `comptas` le compteur `qv.ng` est incrémenté.
- `dac dln ... fam` de `membres` sont mises à jour.
- son item dans `invits` du compte de son avatar est effacé.
- flags `AN AM`: accès aux notes, accès aux autres membres.
- statut à 3 ou 4.

### Modification des droits par un animateur
- flags `DM DN DE`

### Radiation d'un actif par un animateur
- le statut est actif et deviendra 0 (radié) ou 1 (retour en contact).
- le membre est mis (ou non) en liste noire `lng`.
- cas de radiation: son document `membres` est mis en _zombi_.

### Modification des accès membres / notes par le compte
- flags `AN AM`: accès aux notes, accès aux autres membres.

## Radiation demandée par le compte**
- document `membres` mis en _zombi_.
- mis à 0 du statut, de l'entrée dans tid. Dans flags il ne reste que les HM HN HE.
- si le membre était le dernier _actif_, le groupe disparaît.
- la participation au groupe disparaît de `mpg` du compte.
- option liste noire: mise en liste noire `lnc`.

# Documents `Chatgrs`
A chaque groupe est associé **UN** document `chatgrs` qui représente le chat des membres d'un groupe. Il est créé avec le groupe et disparaît avec lui.

_data_
- `id` : id du groupe
- `ids` : `1`
- `v` : sa version.

- `items` : liste ordonnée des items de chat `{im, dh, dhx, t}`
  - `im` : im du membre auteur,
  - `dh` : date-heure d'écriture.
  - `dhx` : date-heure de suppression.
  - `t` : texte gzippé crypté par la clé G du groupe (vide s'il a été supprimé).

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

# Gestion des disparitions des comptes: `dlv` 

Chaque compte a une **date limite de validité**:
- toujours une _date de dernier jour du mois_ (sauf exception par convention décrite plus avant),
- propriété indexée de son document `comptes`.

Le GC utilise le dépassement de `dlv` pour libérer les ressources correspondantes (notes, chats, ...) d'un compte qui n'est plus utilisé:
- **pour un compte "A"** la `dlv` représente la limite d'épuisement de son crédit mais bornée à `nbmi` mois du jour de son calcul.
- **pour un compte "O"**, la `dlv` représente la plus proche de ces deux limites,
  - un nombre de jours sans connexion (donnée par `nbmi` du document `espaces` de l'organisation),
  - la date `dlvat` jusqu'à laquelle l'organisation a payé ses coûts d'hébergement à l'administrateur technique (par défaut la fin du siècle). C'est la date `dlvat` qui figure dans le document `espaces` de l'organisation. Dans ce cas, par convention, c'est la **date du premier jour du mois suivant** pour pouvoir être reconnue.

> Remarque. En toute rigueur un compte "A" qui aurait un gros crédit pourrait ne pas être obligé de se connecter pour prolonger la vie de son compte _oublié / tombé en désuétude / décédé_. Mais il n'est pas souhaitable de conserver des comptes _morts_ en hébergement, même payé: ils encombrent pour rien l'espace.

## Calcul de la `dlv` d'un compte
La `dlv` d'un compte est recalculée à plusieurs occasions.

### Acceptation du sponsoring du compte
Première valeur calculée selon le type du compte.

### Connexion
La connexion permet de refaire les calculs en particulier en prenant en compte de nouveaux tarifs.

C'est l'occasion majeure de prolongation de la vie d'un compte.

### Don pour un compte "A": passe par un chat
Les `dlv` du _donneur_ et du récipiendaire sont recalculées sur l'instant.

### Enregistrement d'un crédit par le Comptable
Pour le destinataire du crédit sa dlv est recalculée sur l'instant.

### Modification de l'abonnement d'un compte A
La `dlv` est recalculée à l'occasion de la nouvelle évaluation qui en résulte.

### Mutation d'un compte "O" en "A" et d'un compte "A" en "O"
La `dlv` est recalculée en fonction des nouvelles conditions.

## Changement des paramètres dans l'espace d'une organisation
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
Le lancement est quotidien et enchaîne les étapes ci-dessous, en asynchronisme de la requête l'ayant lancé.

En cas d'exception dans une étape, une relance est faite après un certain délai afin de surmonter un éventuel incident sporadique.

> Remarque : le traitement du lendemain est en lui-même une reprise.

> Pour chaque opération, il y a N transactions, une par document à traiter, ce qui constitue un _checkpoint_ naturel fin.

## `GCfvc` - Étape _fin de vie des comptes_
Suppression des comptes dont la `dlv` est inférieure à la date du jour.

La suppression d'un compte est en partie différée:
- les versions du `compte / avatars / groupes` sont marquées _suppr_ (ce qui les rend _logiquement supprimés), les documents `comptes comptis invits comptas` sont purgés.
- ses documents `avatars` ont une version v à 999999 (_suppression en cours_)
- ses documents `groupes` dont le nombre de membres actifs devient 0, ont leur version à 999999 (_suppression en cours_).

## `GCpav` - Étape _purge des avatars logiquement supprimés_
Pour chaque avatar dont la version est 999999, gestion des chats et purge des sous-documents `chats sponsoring notes avatars` et finalement du document `avatars` lui-même.

## `GCHeb` - Étape _fin d'hébergement_
Récupération des groupes dont la `dfh` est inférieure à la date du jour et suppression logique (version à 999999).

## `GCpgr` - Étape _purge des groupes logiquement supprimés_
Pour chaque groupe dont la version est 999999, gestion des invitations et participations puis purge des sous-documents **notes membres chatgrs** et finalement du document `groupes` lui-même.
- les membres _invités_ ont leurs avatars mis à jour (suppression de l'invitation).
- le membre hébergeur se voit restituer ses ressources.

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

# Décomptes des coûts et crédits

> **Remarque**: en l'absence d'activité de sessions la _consommation_ d'un compte est nulle, alors que le _coût d'abonnement_ augmente à chaque seconde même sans activité.

On compte **en session** les downloads / uploads soumis au _Storage_. /VERIF/

On compte **sur le serveur** le nombre de lectures et d'écritures effectués dans chaque opération:
- intégration dans le document `comptas` du compte, le cas échéant avec propagation au compte (voire partition) si le changement est significatif.
- retour à la session pour information où sont cumulés les 4 compteurs depuis le début de la session.

Le tarif de base repris pour les estimations est celui de Firebase [https://firebase.google.com/pricing#blaze-calculator].

Le volume _technique_ moyen d'un groupe / note / chat est estimé à 8K. Ce chiffre est probablement faible, le volume _utile_ en Firestore étant faible par rapport au volume réel occupé avec les index ... D'un autre côté, le serveur considère les volumes utilisés en base alors que n / v vont être décomptés sur des quotas (des maximum rarement atteints).

## Classe `Tarif`
Un tarif correspond à,
- `am`: son premier mois d'application. Un tarif s'applique toujours au premier de son mois.
- `cu` : un tableau de 6 coûts unitaires `[u1, u2, ul, ue, um, ud]`
  - `u1`: 30 jours de quota qn (250 notes / chats)
  - `u2`: 30 jours de quota qv (100Mo)
  - `ul`: 1 million de lectures
  - `ue`: 1 million d'écritures
  - `um`: 1 GB de transfert montant.
  - `ud`: 1 GB de transfert descendant.

En configuration un tableau ordonné par `aaaamm` donne les tarifs applicables, ceux de plus d'un an n'étant pas utiles. 

L'initialisation de la classe `Tarif.init(...)` est faite depuis la configuration (UI comme serveur).

On ne modifie pas les tarifs rétroactivement, en particulier celui du mois en cours (les _futurs_ c'est possible).

La méthode `const t = Tarif.cu(a, m)` retourne le tarif en vigueur pour le mois indiqué.

## Objet quotas et volumes `qv` : `{ qc, qn, qv, nn, nc, ng, v }`
- `qc`: quota de consommation
- `qn`: quota du nombre total de notes / chats / groupes.
- `qv`: quota du volume des fichiers.
- `nn`: nombre de notes existantes.
- `nc`: nombre de chats existants.
- `ng` : nombre de participations aux groupes existantes.
- `v`: volume effectif total des fichiers.

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
- `qv` : quotas et volumes pris en compte au dernier calcul `{ qc, qn, qv, nn, nc, ng, v }`.
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
- `dh` est facultatif et sert pour effectuer des batteries de tests ne dépendants pas de l'heure courante.

### Vecteur détaillé d'un mois
Pour chaque mois M à M-3, il y a un **vecteur** de 14 (X1 + X2 + X2 + 3) compteurs:
- moyennes et cumuls servent au calcul au montant du mois:
  - QC : moyenne de qc dans le mois (€)
  - QN : moyenne de qn dans le mois (D)
  - QV : moyenne de qv dans le mois (B)
  - NL : nb lectures cumulés sur le mois (L),
  - NE : nb écritures cumulés sur le mois (E),
  - VM : total des transferts montants (B),
  - VD : total des transferts descendants (B).
- compteurs de _consommation moyenne sur le mois_ qui n'ont qu'une utilité documentaire.
  - NN : nombre moyen de notes existantes.
  - NC : nombre moyen de chats existants.
  - NG : nombre moyen de participations aux groupes existantes.
  - V : volume moyen effectif total des fichiers stockés.
- 3 compteurs spéciaux
  - MS : nombre de ms dans le mois - si 0, le compte n'était pas créé
  - CA : coût de l'abonnement pour le mois
  - CC : coût de la consommation pour le mois

Le getter `get serial ()` retourne la sérialisation de l'objet afin de l'écrire dans la propriété `compteurs` de `comptas`.

**En session,** `compteurs` est recalculé par `compile()` à la connexion et en synchro,

**En serveur,** des opérations peuvent faire évoluer `qv` de `comptas`. L'objet `compteurs` est construit (avec un `qv` -et `conso` s'il enregistre une consommation) puis sa sérialisation est enregistrée dans `comptas`:
- création / suppression d'une note ou d'un chat: incrément / décrément de nn / nc.
- prise / abandon d'hébergement d'un groupe: delta sur nn / nc / v.
- création / suppression de fichiers: delta sur v.
- enregistrement d'un changement de quotas qn / qv.
- upload / download d'un fichier: delta sur vm / vd.
- enregistrement d'une consommation de calcul: delta sur nl / ne / vd / vm en passant l'évolution de consommation dans l'objet `conso`.

En session:
- le Comptable peut afficher le `compteurs` de n'importe quel compte "A" ou "O".
- les délégués d'une partition ne peuvent faire afficher les `compteurs` _que_ des comptes "O" de leur partition.

### Mutation d'un compte _autonome_ en compte _d'organisation_
Le compte a demandé et accepté, de passer O. Son accord est traduit par le dernier item de son chat avec le délégué ou le Comptable qui effectue l'opération: son texte est `**YO**`.

Le Comptable ou un délégué désigne le compte dans ses contacts et vérifie:
- que c'est un compte "A",
- que le dernier item écrit par le compte est bien `**YO**`.

Les quotas `qc / qn / qv` sont ajustés par le sponsor / comptable:
- de manière à supporter au moins le volume actuels n / v,
- en respectant les quotas de la partition courante.

L'opération de mutation:
- inscrit le compte dans la partition courante,
- dans `compteurs` du `comptas` du compte:
  - remise à zéro du total abonnement et consommation des mois antérieurs (`razma()`):
  - l'historique des compteurs et de leurs valorisations reste intact.
  - les montants du mois courant et des 17 mois antérieurs sont inchangés,
  - MAIS les deux compteurs `aboma` et `consoma` qui servent à établir les dépassements de coûts sont remis à zéro: en conséquence le compte va bénéficier d'un mois (au moins) de consommation _d'avance_.
- inscription d'un item de chat.

### Rendre _autonome_ un compte "O"
C'est une opération du Comptable et/ou d'un délégué:
- selon la configuration de l'espace, l'accord du compte est requis si la configuration de l'espace l'a rendu obligatoire (item de chat avec `**YO**`)

L'opération de mutation:
- retire le compte de sa partition.
- comme dans le cas ci-dessus, remise à zéro des compteurs total abonnement et consommation des mois antérieurs.
- dans `comptas`:
  - `solde` vaut un pécule de 2c, le temps de générer un ticket et de l'encaisser.
  - les listes des `tickets dons` sont vides.

### Sponsoring d'un compte "O"
Rien de particulier : `compteurs` est initialisé. Sa consommation est nulle, de facto ceci lui donne une _avance_ de consommation moyenne d'au moins un mois.

### Sponsoring d'un compte "A"
`compteurs` est initialisé, sa consommation est nulle mais il bénéficie d'un _solde_ minimal pour lui laisser le temps d'enregistrer son premier crédit.

Dans `comptas` on trouve:
- un `solde` de 2 centimes.
- des listes `tickets dons` vide.

# Connexion et Synchronisation au fil de l'eau d'une session UI
Principes:
- à la fin de la phase de _connexion_, 
  - tous les documents _synchronisés_ du périmètre du compte sont en mémoire et cohérents entre eux. 
    - 1 `espaces`
    - 1 sous-arbre `comptes comptis invits`
    - N sous-arbres `avatars ... notes sponsorings chats tickets`
    - M sous-arbres `groupes ... notes membres`
  - si la session est _synchronisée_ cet état est aussi celui de la base base locale IDB qui a été mise à jour de manière cohérente pour le compte, puis pour chaque avatar, chaque groupe.
- par la suite l'opération `Sync` maintient cet état.

> La création d'un compte par acceptation de sponsoring amène la session au même point que la _connexion_ ci-dessus.

> Les trois autres documents du périmètre du compte `syntheses partitions comptas` sont chargés à la demande.

## L'objet DataSync
Cet objet sert:
- entre session et _serveur / Cloud Function_ a obtenir les documents resynchronisant la session avec l'état de la base.
- dans la base locale: à indiquer ce qui y est stocké et dans quelle version.

**Les états successifs _de la base_ sont toujours cohérents**: _tous_ les documents de _chaque_ périmètre d'un compte sont cohérents entre eux.

L'état courant d'une session en mémoire et le cas échéant base locale, est consigné dans l'objet `DataSync` ci-dessous:
- chaque sous-arbre d'un avatar ou d'un groupe est _cohérent_ (tous les documents sont synchrones sur la même version `vs`),
- en revanche il peut y avoir (plus ou moins temporairement) des sous-arbres à jour par rapport à la base et d'autres en retard.

**L'objet `DataSync`:**
- compte: `{ rds, vs, vb }`
  - `vs` : numéro de version de l'image détenue en session
  - `vb` : numéro de version de l'image en base centrale
- avatars: Map des avatars du périmètre. 
  - Clé: id de l'avatar
  - Valeur: `{ rds, chg, vs, vb } `
    - `chg`: true si l'avatar a été détecté changé en base par le serveur
- groupes: : Map des groupes du périmètre. 
  - Clé: id groupe
  - Valeur: `{ rds, chg, vs, vb, ms, ns, m, n }`
    - `chg`: true si le groupe a été détecté changé en base par le serveur
    - `vs` : numéro de version du sous-arbre détenue en session
    - `vb` : numéro de version du sous-arbre en base centrale
    - `ms` : true si la session a la liste des membres
    - `ns` : true si la session a la liste des notes
    - `m` : true si en base centrale le groupe indique que le compte a accès aux membres
    - `n` : true si en base centrale le groupe indique que le compte a accès aux membres

**Remarques:**
- un `DataSync` reflète l'état d'une session, les `vs` (et `ms ns` des groupes) indiquent quelles versions sont connues d'une session.
- Un `DataSync` reflète aussi l'état en base centrale, les `vb` (et `m n` pour les groupes) indiquent quelles versions sont détenues dans l'état courant de la base centrale.
- Quand tous les `vb` et `vs` correspondant sont égales (et les couples `ms ns / m n` pour les groupes), l'état en session reflète celui en base centrale: il n'y a plus rien à synchroniser ... jusqu'à ce l'état en base centrale change et que l'existence d'une mise à jour soit signifiée à la session.

Chaque appel de l'opération `Sync` :
- transmet le `DataSync` donnant l'image connue en session,
- reçoit en retour,
  - le `DataSync` rafraîchi par le dernier état courant en base centrale.
  - le dernier état, s'il a changé, des documents `comptes comptis invits` du compte,
  - zéro, un ou plusieurs lots de mises de sous-arbres _avatar_ et _groupe_ entiers.

Pas forcément les mises à jour de **tous** les sous-arbres:
- le volume pourrait être trop important,
- le nombre de sous-arbres mis à jour dépend du volume de la mise à jour.
- en conséquence si le `DataSync` indique que tous n'ont pas été transmis, une opération `Sync` est relancée avec le dernier `DataSync` reçu.

**Cas particulier de la connexion,** premier appel de `Sync` de la session:
- c'est le serveur qui construit le `DataSync` depuis l'état du compte et les versions des sous-arbres **qu'il va tous chercher**.
- au retour, la session va récupérer (en mode _synchronisé_) le `maxim` de documents encore valides et présents dans IDB: 
  - elle lit depuis IDB le `DataSync` qui était valide lors de la fin de la session précédente et qui donne les versions `vs` (et `ms ns` pour les groupes),
  - elle lit depuis IDB l'état des sous-arbres connus afin d'éviter un rechargement total: les `vs` (et `ms ns`) sont mis à jour dans le DataSync.
  - le prochain appel de `Sync` ne provoquera des chargements _que_ de ce qui est nouveau et pas des documents ayant une version déjà à jour en session UI.

**Appels suivants de Sync**
- le `DataSync` reçu sur le serveur permet de savoir ce que la session connaît.
- si des avis de mises à jour sont parvenus, la liste de leur `rds` est passé à `Sync`: au lieu de relire toutes les versions de tous les sous-arbres `Sync` se contente de lire uniquement les versions des sous-arbres changés donnés par la liste des `rds` reçue de la session UI.

A chaque appel de `Sync`, les versions de` comptes comptis invits` sont vérifiées: en effet avant de transmettre les mises à jour des sous-arbres `Sync` s'enquiert auprès du document comptes:
- des sous-arbres n'ayant plus d'intérêt (avatars et groupes hors périmètre),
- des nouveaux sous-arbres (nouveaux avatars, nouveau groupes apparaissant dans le périmètre),
- pour les groupes si les accès _membres_ et _notes_ ont changé pour le compte.

### Synchronisation en session
Après la phase de _connexion_, l'état en mémoire est cohérent et stable, avec une tâche _d'écoute des changements_ active en permanence:
- en mode _Firebase_ des lectures _onSnapshot_ sont lancées sur tous les documents versions dont l'id est un des rds des documents du périmètre (compte / avatar / groupe):
  - un _callback_ survient à réception d'un _avis de changement de version_
    - soit LE document `espaces` a changé,
    - soit un ou plusieurs documents `comptes comptis invits` ont changé,
    - soit un ou plusieurs documents d'UN sous sous-arbre `avatars notes sponsorings chats tickets` identifié en majeur par l'id d'un avatar du périmètre ont changé,
    - soit un ou plusieurs documents d'UN sous-arbre `groupes notes membres` identifié en majeur par l'id d'un groupe du périmètre ont changé,
- en mode _Serveur_ ces avis sont reçus par WebSocket: le serveur voit passer toutes les mises à jour et connaît les périmètres de toutes les sessions.

Si le mode d'acquisition des avis de mises à jour diffère, le traitement qui s'en suit est identique.

**Remarques:**
- les avis de mise à jour des sous-arbre _compte_, sous-arbre _avatar_, sous-arbre _groupe_ peuvent parvenir dans un ordre différent de celui dans lequel les mises à jour sont intervenues;
- un avis de mise à jour de `espaces` est décorrélé des autres: il est traité isolément dès son arrivée.
- en revanche un avis sur comptes peut parvenir après un avis sur un de ses avatars: pour éviter cette discordance, l'état de compte est toujours relu (si nécessaire) à chaque `Sync`.
- il se _POURRAIT_ qu'un sous-arbre (complet) _avatar_ soit remis à jour AVANT un sous-arbre _groupe_, dans l'ordre inverse des opérations sur le serveur. Mais cette discordance entre la vue en session et la réalité,
  - va être temporaire,
  - est fonctionnellement quasi impossible à discerner,
  - n'a pas de conséquence sur la cohérence des données.

## Connexion en mode _avion_
Phase unique:
- lecture de l'item de _boot_ de la base locale:
  - il permet d'authentifier le compte (et d'acquérir sa clé K),
  - lecture du `DataSync` de la base locale,
- mise en _mémoire tampon compilée_ depuis la base locale,
  - des documents `espaces comptes comptis invits`.
  - des documents des sous-arbres _avatar_ et _compte_.
- **mise à jour des _stores_ des documents compilés** en une séquence sans interruption (sans `await`) afin que la vision graphique soit cohérente.

## Synchronisation au fil de l'eau
Au fil de l'eau il parvient des notifications de mises à jour de _versions_. 

Une table _queue de traitements_ mémorise pour chaque sous-arbre, son `rds` et la version notifiée par l'avis de mise à jour. Elle regroupe ainsi des événements survenus très proches.

Les avis de mises à jour dont la version est inférieure ou égale à la version déjà détenue dans les _stores_ de la session, sont ignorés.

### Itération pour vider cette queue
Tant qu'il reste des traitements à effectuer, une opération `Sync` est soumise:
- le `DataSync` est celui courant,
- L'id du sous-arbre est:
  - `0` si l'avis de changement concerne le sous-arbre _compte_.
  - `ida`, l'id du sous-arbre si la notification correspond à un sous-arbre.

Le traitement standard de retour,
- met à jour la base locale en une transaction,
- met à jour les _store_ de la session sans interruption (sans `await`).

# Annexe I: déclaration des index /VERIF/

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

# Tâches différées (_triggers_) et périodiques
Une opération effectue dans sa transaction les mises à jour immédiates de manière à ce que la cohérence des données soient garantie. En conséquence de ces transactions il peut rester des activités d'optimisation et / ou de nettoyage à exécuter qui peuvent être _différées_.

**Une tâche périodique** a pour objectif de détecter les changements d'états liés au simple passage du temps:
- compte résilié en raison d'une non-utilisation prolongée,
- sponsorings ayant dépassé leur date limite,
- production d'états mensuels.

**_Exemple:_**
- _transaction principale_: un groupe est supprimé. Dès cet instant toute opération tentant d'agir sur le groupe sortira en exception parce que le groupe n'existe plus.
- _tâche différée_: supprimer les invitations enregistrées dans le groupe des comptes dont un avatar était invité. Ceci évitera à ces comptes de récupérer une exception en acceptant / refusant une de ces invitations. Certes la cohérence aurait été conservée mais du point de vue de l'autre compte il apparaît une liste d'invitations dont certaines ne sont plus d'actualité, cette incohérence a intér^et à être la plus courte possible.

Un document `taches` enregistre toutes ces tâches différées:
- une opération _principale_ peut enregistrer des tâches sous contrôle transactionnel.
- un _démon_ est lancé s'il n'était pas en cours, qui va scruter `taches`, 
  - en extraire la plus ancienne en attente de traitement,
  - la traiter en une transaction, ce qui peut le cas échéant ajouter d'autres tâches,
  - in fine la retirer de `tâches`, ou pour une tâche périodique la réinscrire pour le lendemain typiquement.
  - puis rechercher la tâche suivante à exécuter et en cas d'absence se rendormir.

**Une tâche non périodique:**
- a un code opération (celle de son traitement),
- est associée à un espace: elle n'est pas candidate à l'exécution si son espace est figé ou clos.
- a un document cible identifié par id ou id / ids.
- est exécutée sous privilège administrateur et n'enregistre pas ses consommations,
- a une date-heure au plus tôt: quand une tâche a rencontré une exception, sa date-heure au plus tôt permet de laisser s'écouler un certain délai avant une nouvelle exécution.
- n'a pas de rapport de bonne exécution, la tâche étant détruite.
- elle a un rapport d'exception décrivant l'exception qui a interrompu sa dernière exécution.

**Une tâche périodique:**
- a un code opération (celle de son traitement),
- se réinscrit systématiquement pour plus tard en **début** de tâche afin de ne pas être lancée par deux démons de deux _serveurs / cloud function_ parallèle,
- est exécutée sous privilège administrateur et n'enregistre pas ses consommations.
- elle a un rapport d'exécution contient quelques compteurs informatifs.
- elle a un rapport d'exception décrivant l'exception qui a interrompu sa dernière exécution.

**Espace clos / figé**
- **une tâche non périodique n'est pas lancée** si son espace est clos ou figé.
- une tâche périodique teste dans son exécution l'état des espaces en fonction de chaque document qu'elle a à traiter, et ne traite que ceux dont l'espace n'est ni clos ni figé.

**Multi serveur / cloud function**: empêcher 2 serveurs de lancer la même tâche
- _début de tâche_: mise à jour de la date-heure au plus tôt. _Comme si_ la relance de la tâche était déjà planifiée.
- _fin de tâche_: purge de la tâche pour une tâche _non périodique_ et changement de l'heure de relance pour une tâche périodique.

**Articulation avec le GC**
- le GC est une pseudo-opération sollicitée de l'extérieur par une URL qui réveille le _démon_.
- en effet en l'absence de trafic, en l'absence du réveil du GC, des tâches non périodiques en exception pourraient n'être relancées que tardivement, des rapports mensuels ne pas être calculés à temps.

### L'administrateur dispose d'un accès aux tâches, et peut:
- voir la liste des tâches,
  - soit les tâches périodiques,
  - soit les tâches non périodiques _d'un espace_.
- voir le dernier compte-rendu d'exécution / exception d'une tâche.
- ajouter ou supprimer une tâche,
- réveiller le démon.

### Réveiller le _démon_ au démarrage du serveur ?
- pour un _serveur_ ça fait sens,
- pour une _cloud function_ c'est un overhead de lecture systématique de `taches`.


_data_
- `ns` : 0 pour une tâche périodique, sinon le ns de la tâche.
- `dh` : date-heure au plus tôt d'exécution.
- `op` : code de l'opération.
- `id / ids` : id de l'objet principal concerné, 0 pour un périodique.
- `report` : sérialisation du dernier rapport d'exécution / exception.

Tâche candidate:
- la plus petite dh avec dh supérieure à l'instant présent.
- dont le ns est 0 OU dans la liste des ns _ouverts_ (existants, non figé, non clos).

## Opérations inscrivant des tâches
### Suppression d'un groupe
- immédiatement:
  - mise à jour de la comptabilité du compte hébergeur (si besoin).
  - pour toutes les invitations en cours (et contacts), annule l'invitation dans invits du compte dont un avatar est invité / contact.
  - pour tous les membres actifs, supprime le groupe du `mpg` du compte.
  - purge des documents `comptes chatgrs`
  - `suppr` de `versions` du groupe.
- tâches différées:
  - `GRM`
  - `AGN AGF`

### Résiliation d'un avatar
- immédiatement:
  - mise à jour des statuts dans les groupes ou l'avatar est actif / invité / contact.
  - s'il était hébergeur, récupération des volumes dans la compta de son compte.
  - purge des `membres` correspondants.
  - le cas échéant, traitement immédiat de _suppression du groupe_.
  - purges des `sponsorings`
  - purge du document `avatars`
  - `suppr` de `versions` de l'avatar.
- tâches différées:
  - `AVC` : gestion et purges des chats de l'avatar.
  - `AGN AGF`

### Résiliation d'un compte
- immédiatement:
  - mise à jour des statuts dans les groupes où un des avatars est actif / invité / contact.
  - s'il était hébergeur, récupération des volumes dans la `comptas` de son compte.
  - purge des `membres` correspondants.
  - le cas échéant, traitement immédiat de _suppression du groupe_.
  - purges des `sponsorings`
  - purge des documents `comptes avatars`
  - `suppr` de `versions` du compte et des avatars.
- tâches différées:
  - `AVC` : Une tâche par avatar: gestion et purges des chats de l'avatar.
  - `AGN AGF` : Une tâche par avatar

## Liste des tâches non périodiques

### GRM : purge des membres d'un groupe supprimé
Arguments:
- `id` : id du groupe.

### AGN : purge des notes d'un groupe ou avatar supprimé
Arguments:
- `id` : id du groupe / avatar.

### AGF : purge d'un fichier supprimé OU des fichiers attachés aux notes d'un groupe ou avatar supprimé
Arguments:
- `id` : id du groupe / avatar.
- `ids` : ids du fichier si la suppression ne concerne que ce fichier.

_Remarque_: pour la suppression _d'un_ fichier, l'opération principale,
- en phase 2, inscrit la tâche AGF pour le fichier à supprimer,
- en phase 3 essaie de supprimer le fichier du _Storage_ et en cas de succès supprime la tâche AGF inscrite en phase 2. La tâche est, dans le cas favorable, supprimée _avant_ que le démon n'ait pu être réveillé (en fin de l'opération).

### AVC : gestion et purges des chats de l'avatar
Arguments:
- `id` : id de l'avatar.

Liste les chats de l'avatar et pour chacun:
- met à jour le statut / cv du `chatE` correspondant.
- purge le `chatI`

## Liste des tâches périodiques

### DFH : détection d'une fin d'hébergement
Filtre les groupes dont la `dfh` est dépassée:
- immédiatement pour chaque groupe _suppression du groupe_.

### DLV : détection d'une résiliation de compte
Filtre les comptes dont la `dlv` est dépassée:
- immédiatement pour chaque compte _suppression du compte_.

### TRA : traitement des transferts perdus
Filtre les transferts par `dlv`:
- immédiatement pour chaque transfert, purge dans le _Storage_

### VER : purge des versions supprimées depuis longtemps

### STC : statistique "mensuelle" des comptas (avec purges)

### STT : statistique "mensuelle" des tickets (avec purges)

## Protocole de création d'un espace et de son Comptable
**Par l'Administrateur Technique**: création d'un espace:
- choix du code de l'espace `ns` et de l'organisation org
- acquisition de la phrase de sponsoring du comptable T -> `TC` (son PBKFD) -> `hTC` (son hash)
- **Opération** `CreationEspace`
  - Arguments: `ns org TC hTC`
  - Traitement:
    - OK si: 
      - soit espace n'existe pas, 
      - soit espace existe et a un `hTC` : re-création avec une nouvelle phrase de sponsoring.
    - génération de la `cleE` de l'espace: -> `cleET` (par TC) et `cleES` (par clé système).
    - stocke dans l'espace: `hTC cleES cleET`. Il est _à demi_ créé, son Comptable n'a pas encore créer son compte.

**Par le Comptable**: création de son compte
- saisie de la phrase de sponsoring T -> `hTC TC`
- **Opération** `GetCleET`:
  - argument: `org hTC` (pour vérification)
  - retour: `cleET`
- saisie phrase secrète du compte: X -> `XC` -> `hXR hXC`
- génération de la clé K: -> `cleKXC` -> `cleEK`
- génération pub/priv: -> `privK pub`
- génération de la clé P de la partition 1: `clePK` -> `ck` `{cleP, code}` crypté par clé K
- **Opération** `CreationComptable`:
  - arguments: `org hTC` (pour vérification) `hXR hXC cleK clePK privK pub cleAP cleAK cleKXC clePA ck`
    - implicite: `id` du Comptable, génération `rds` du compte et de son avatar principal 
  - Traitement:
    - création de `compte compti compta` du Comptable
    - création de la `partition` 1 ne comprenant que le Comptable
    - création de son `avatar` principal (et pour toujours unique)
    - _dans son `espace`_: suppression de `hTC`

# Architecture

### APP: l'application
- **C'est une page Web téléchargeable depuis une URL** d'un site Web statique. Le script _service worker_ de l'application permet à chaque browser ayant chargé une fois l'application d'en conserver dans sa mémoire la page principale `index.html` et ses ressources (scripts, etc.). Lors d'une nouvelle ouverture de la page de l'application le browser,
  - si le site Web statique est joignable, ne recharge que les ressources changés par rapport à celles qu'il a en mémoire,
  - sinon utilise la pge et ses ressources chargées antérieurement sans utiliser le réseau (mode _avion_).
- **Chaque onglet d'un browser ouvre une nouvelle _session_ de l'application,** en chargeant cette page. La session dure jusqu'à clôture de l'onglet ou chargement d'une autre page Web. 
  - une session est universellement identifiée par l'attribution d'un identifiant aléatoire `rnd`.
  - un _token_ `subscription` est récupéré (ou généré) à l'ouverture de la session par le script _service worker_:
    - il est doublement spécifique de l'application et du browser du poste.
    - sur un poste donné plusieurs sessions de l'application dans le même browser ont en conséquence le même jeton `subscription`.
- **Au cours de cette session, l'utilisateur peut se connecter et se déconnecter _successivement_ à un ou des comptes.** 
  - chaque connexion est numérotée `nc` en séquence de 1 à N dans sa session.
  - `sessionId` est le string `rnd.nc` qui identifie exactement la vie d'une connexion à un compte entre sa connexion et sa déconnexion.
- **Une application externe au browser peut _pousser_ des messages de _notification_** en ayant connaissance du jeton `subscription`:
  - tous les onglets du même browser ouverts sur l'application reçoivent les notifications ainsi poussées. Chacune est porteuse du `sessionId` (`rnd.nc`) de la connexion concernée: seule celle-ci la traite, les autres la reçoive, l'ouvre, en lise le `sessionId` du contenu et l'ignore.

### OP: service des opérations - SES instances
- **Chaque instance de OP est un serveur HTTP traitant les opérations de lecture et de mise à jour des données soumises par les sessions de l'application**,.
  - une instance de OP est lancée dès qu'une requête désignant son URL est émise.
  - elle vit _un certain temps_, pouvant traiter d'autres requêtes,
  - elle s'arrête au bout d'un certain temps d'inactivité, c'est à dire _sans_ recevoir de requêtes.
- **Plusieurs instances de OP peuvent être actives**, à l'écoute de requêtes, à un instant donné.
- Les requêtes émises par une session de l'application peuvent être traitées par n'importe laquelle des instances de OP actives avec deux conséquences:
  - une instance de OP ne peut pas conserver en mémoire un historique fiable des requêtes précédentes issues de la même session.
  - une instance de OP ne peut pas avoir connaissance de toutes les sessions actives.
- **Les instances de OP accèdent à LA base données de l'application**, en consultation et mise à jour. Elles ne _poussent_ pas de messages de notification aux sessions.
- A chaque transaction de mise à jour exécutée par une instance de OP:
  - un `trlog` de la transaction est construit avec:
    - l'identifiant du compte sous lequel la transaction est effectuée,
    - le `sessionId` de la session émettrice de l'opération,
    - la liste des IDs des documents modifiés / créés / supprimés et leur version correspondante,
    - la liste des périmètre des comptes impactés.
  - le `trlog` (raccourci, sans les périmètres impactés) est retourné à la session appelante qui peut ainsi invoquer une requête de synchronisation `Sync` afin d'en obtenir les mises à jour de son état interne.
  - le `trlog` (complet) est transmis par une requête HTTP au service PUBSUB afin de notifier les autres sessions actives.

### PUBSUB: service de gestion des sessions actives - UNE SEULE instance active
- L'instance **unique à un instant donné** est un serveur HTTP en charge:
  - de garder en mémoire la liste des sessions actives (connectées à un compte) de l'application et de conserver pour chacune d'elle son _périmètre_: la liste des IDs des documents auxquels elle peut accéder.
  - d'émettre des _messages de notification_ à toutes les sessions enregistrées dont un des documents de leur périmètre a évolué suite à une opération effectuée dans un instance OP.
- **Les instances de OP envoient une requête `login` à chaque connexion** (réussie) à un compte d'une session en lui donnant les informations techniques de `subscription` (permettant à PUBSUB d'émettre des notifications à la session correspondante) ainsi que son _périmètre_.
- **Chaque session _active_ dans un browser émet toutes les 2 minutes un _heartbeat_,** une requête à PUBSUB avec son `sessionId`:
  - un _heartbeat_ spécial de déconnexion est émis à la clôture de la connexion.
  - au bout de 2 minutes sans avoir reçu un _heartbeat_ PUBSUB détruit le contexte de la session (considérée comme inactive).
- Quand l'instance PUBSUB n'a pas reçu de requêtes depuis un certain temps, c'est qu'elle n'a plus connaissance de sessions actives: elle peut être arrêtée (avec un état interne vierge). Une nouvelle instance sera lancée lors de la prochaine connexion à un compte reçue.
  - l'instance PUBSUB n'est donc pas _permanente_: il y en a une (seule) active dès lors qu'une session s'est connectée à un compte et le reste jusqu'à déconnexion de la dernière session active.
- **A chaque transaction de mise à jour exécutée par une instance de OP:**
  - une requête `notif` au service PUBSUB est émise lui transmettant le `trlog` de la transaction. PUSUB est ainsi en mesure,
    - d'identifier toutes les sessions actives ayant un document de leur périmètre impacté (en ignorant la session origine de la transaction informée directement par OP),
    - de mettre à jour le cas échéant les périmètres des comptes impactés.
    - d'émettre, de manière désynchronisée, à chacune de celles-ci la liste des IDs des documents mis à jour la concernant avec leurs versions (un `trlog` _raccourci_ construit spécifiquement pour chaque session),
  - Chaque session ainsi _notifiée_ sait quels documents de son périmètre a changé et peut demander au service OP par une requête `Sync` les mises à jour associées.
- **PUBSUB n'a aucune mémoire persistante**, n'accède pas à la base de données: c'est un service de calcul purement en mémoire maintenant l'état des sessions actives.

### SRV: CF + PUBSUB - UNE SEULE instance active à tout instant
SRV traite les deux services CF et PUBSUB dans une seule instance de serveur HTTP. Cette option est pertinente dans les cas suivants:
- en test local,
- dans une VM en contrôlant qu'il y n'y a bien qu'une seule instance active au plus à tout instant,
- dans une _Cloud Function_ ou _Server géré_ avec un trafic suffisamment faible pour supporter une configuration garantissant qu'il n'y a jamais plus d'une instance active à un moment donné. 

### PUBSUB _down_ : conséquences
L'application est fonctionnelle sans service PUBSUB:
- les sessions ne seront pas _notifiées_ des mises à jours opérées par les autre sessions.
- les sessions devront sur demande explicite de l'utilisateur (ou périodique automatique à une fréquence faible) opérer des synchronisations _complètes_, vérifiant la version de tous les documents de leur périmètre.
- chaque transaction gérée par le service OP ne pourra pas joindre PUBSUB: le retour de la requête indiquera cette indisponibilité pour information de la session qu'elle est en mode dégradée _sans notification continue_ des effets des opérations des autres sessions impactant son périmètre.

# Service PUBSUB

Ce service est constitué:
- d'une mémoire non persistante de l'état des sessions actives,
- de requêtes POST déclenchant ses opérations et des fonctions correspondantes pour les appels en structure SRV depuis le service OP.

### Objet `perimetre`
Cet objet décrit le périmètre d'un compte et est construit depuis un _compte_ (`get perimetre ()` des classes `Compte` dans APP et `Comptes` dans OP).
- `id`: ID du compte
- `vpe`: version du périmètre. C'est la version du compte à laquelle le périmètre a été changé pour la dernière fois, un compte pouvant changer sans que son _périmètre_ ne change.
- `lavgr`: liste des IDs des avatars du compte et des groupes accédés par le compte, triée par IDs croissantes.

`function equal(p1, p2)`
- retourne `true` si `p1` et `p2` (du même compte) ont même liste `lavgr`.

#### Méthode / requête `login`
Elle est invoquée par un requête HTTP ayant un objet argument ou paramètre crypté par la clé du site:
- `sessionId`: `rnd.nc` identifiant de la connexion dans la session appelante.
- `subscription`: token de suscription généré à l'initialisation de la session (en base 64).
- `perimetre`: liste les IDs des objets du périmètre du compte.

En déploiement OP distinct de PUBSUB, OP effectue une requête HTTP: si cette requête échoue (le service PUBSUB n'étant pas disponible) la requête `cnx` retourne un statut indiquant que la session n'est pas _notifiée_.

En déploiement SRV, la méthode est directement invoquée, sans avoir besoin de passer par une requête HTTP.

#### Requête `heartbeat`
Elle est invoquée en session toutes les deux minutes pour informer PUBSUB que la session est toujours active:
- `sessionId`: `rnd.nc` identifiant de la connexion dans la session appelante.
- `nhb`: numéro séquentiel du heartbeat.
  - 1..N: numéro d'appel successif. émis par la session.
  - 0: par convention, indique une déconnexion de la session émise par la session.

Retour: `KO`
- détection d'un heartbeat manquant, le précédent enregistré n'est pas `nhb - 1` (ou n'existe pas). La session n'est plus _notifiée_, elle est supprimée (si elle existait). 

Ces deux opérations:
- mettent à jour l'état mémoire de PUBSUB immédiatement et de manière atomique (non interruptible).
- n'émettent pas de message de _notification_.

#### Fin d'opération de mise à jour de OP `notif`
Lorsqu'une opération de mise à jour s'exécute dans OP, un certain nombre de documents sont mis à jour, leur version a changé: un objet `trlog` est créé.
- cet objet a une forme _longue_ qui est transmise à PUBSUB sur la méthode / requête `notif`.
  - le traitement par PUBSUB a une première phase _synchrone_ qui,
    - met à jour l'état mémoire des sessions,
    - prépare la liste des messages de notifications à envoyer: chaque message a pour structure un `trlog` de forme raccourcie.
  - la second phase est asynchrone et consiste à émettre tous les messages de notification préparés en phase 1.
  - la méthode / requête `notif` est courte vu du côté de l'appelant OP et ne diffère que de peu le retour de l'opération de mise à jour.
- l'objet `trlog` a une forme raccourcie quand il parvient dans les sessions:
  - la session appelante de l'opération: les mises à jour ayant concerné au moins un document du périmètre du compte (sauf exception ?).
  - les autres sessions enregistrées par PUBSUB _impactées_ c'est à dire ayant au moins un des documents de leur périmètre mis à jour par l'opération (possiblement aucune session). Chaque session recevra en message de notification un `trlog` raccourci.

En session on peut ainsi recevoir des `trlog` depuis deux sources:
- en résultat d'une opération de mise à jour soumise par la session elle-même,
- par suite d'une opération de mise à jour déclenchée par une autre session et parvenue en _notification_.

Le traitement ensuite est identique: une opération `Sync` sera émise vers OP afin d'obtenir les mises à jour des documents modifiés / créés / supprimés. 

### Objet `trlog`
- `sessionId`: `rnd.nc`. Permet de s'assurer que ce n'est pas une notification obsolète d'une connexion antérieure.
- `partId`: ID de la partition si c'est un compte "0", sinon ''.
- `vpa`: version de cette partition ou 0 si inchangée ou absente.
- `vce`: version du compte. (utile ?)
- `vci`: version du document `compti` s'il a changé, sinon 0.
- `lavgr`: liste `[ [idi, vi], ...]` des Couples des IDs des avatars et groupes ayant été impactés avec leur version.
- `lper`: **format long seulement**. `liste [ {...}, ...]` des `perimetre` des comptes ayant été impactés par l'opération (sauf celui de l'opération initiatrice).

### Mémoire de PUBSUB
Map `sessions`: clé: `rnd` de `sessionID`
- `nc`: nc de sessionID.
- `cid`: ID du compte.
- `nhb`: numéro d'ordre du dernier heartbeat.
- `dhhb`: date-heure du dernier heartbeat. Permet de purger les sessions inactives n'ayant pas émises de déconnexion explicite.
- `subscription`: token de subscription de la session.

Map `comptes`: clé: ID du compte
- `perimetre`: plus récent périmètre connu.
- `sessions`: set des `rnd` identifiant les sessions ayant pour `cid` celui de ce compte.

Map `xref`: clé : ID d'un avatar / groupe / partition
- `comptes`: set des IDs des comptes référençant cette ID.

Règles de gestion:
- les `comptes` dont le set des sessions est vide sont supprimés.
- les `xref` dont le set des comptes est vide sont supprimés.
- les `sessions` dont le `dhhb` + 2 minutes est dépassé sont supprimés (et en cascade potentiellement leur entrée dans comptes et les `xref` associés).

@@ L'application UI [uiapp](./uiapp.md)
