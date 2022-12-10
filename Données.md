# Boîtes à secrets - Modèle de données

## Identification des objets

Les clés AES et les PBKFD sont des bytes de longueur 32.

Un entier sur 53 bits est intègre en Javascript (15 chiffres décimaux). Il peut être issu de 6 bytes aléatoires.

Le hash (_integer_) d'un bytes est un entier intègre en Javascript multiple de 4.

Le hash (_integer_) d'un string est un entier intègre en Javascript.

Les date-heures _serveur_ sont exprimées en micro-secondes depuis le 1/1/1970, soit 52 bits (entier intègre en Javascript). Les date-heures fonctionnelles sont en milli-secondes.

### Nom complet d'un avatar / contact / groupe / tribu
Le **nom complet** d'un avatar / contact / groupe / tribu est un couple `[nom, rnd]`
- `nom` : nom lisible et signifiant, entre 6 et 20 caractères. Le nom `Comptable` est réservé.
- `rnd` : 32 bytes aléatoires. Clé de cryptage.
- A l'écran le nom est affiché sous la forme `nom@xyzt` (sauf `Comptable`) ou `xyzt` sont les 4 derniers caractères de l'id en base64.

**Dans les noms,** les caractères `< > : " / \ | ? *` et ceux dont le code est inférieur à 32 (donc de 0 à 31) sont interdits afin de permettre d'utiliser le nom complet comme nom de fichier.

**Ids des types d'objet majeurs :**
- l'`id` d'un avatar est le hash (_integer_) des bytes de `rnd`, SAUF pour le compte de nom réservé `Comptable` pour lequel, quel que soit le `rnd`, l'id est Number.MAX_SAFE_INTEGER (2^53 - 1 = 9007199254740990).
- l'`id` d'un contact est le hash (_integer_) des bytes de `rnd` + 1.
- l'`id` d'un groupe est le hash (_integer_) des bytes de `rnd` + 2.
- l'`id` d'une tribu est le hash (_integer_) des bytes de `rnd` + 3.

Le reste de la division par 4 de l'id d'un objet majeur donne son type: 0 : avatar, 1 : contact, 2 : groupe, 3 : tribu.

### Attributs génériques et version des rows
- `v` : version, entier.
- `dlv` : date limite de validité, en nombre de jours depuis le 1/1/2021.
- `vsh` : version du schéma de données. Si des données apparaissent, disparaissent ou changent, `vsh` est changé. Dans le code, application ou serveur), il est ainsi possible de transformer, a minima en mémoire, les données de `vsh` obsolète en données normalisées récentes.

Les rows des tables synchronisables ont une version `v`, de manière à pouvoir être chargés en session de manière incrémentale : pour chaque row la version est donc garantie croissante avec le temps.  
- utiliser une date-heure présente l'inconvénient de laisser une meta-donnée intelligible en base.
- utiliser un compteur universel a l'inconvénient de facilement deviner des liaisons entre objets : par exemple l'invitation à établir un contact entre A et B n'apparaît pas dans les rows eux-mêmes mais serait lisible si les rows avaient la même version. Crypter l'appartenance d'un avatar à un groupe alors qu'on peut la lire de facto dans les versions est un problème.
- utiliser un compteur par objet rend complexe la génération de SQL avec des filtres qui associent chaque objet à sa dernière version connue.

Tous les objets synchronisables sont identifiés, au moins en majeur, par une id de compte, d'avatar, de contact ou de groupe : d'où l'option de gérer **une séquence de versions**, pas par id de ces objets mais par hash de cet id.

La table `cv` ne suit pas cette règle et a une séquence unique afin de synchroniser tous les états d'existence et les cartes de visite de tous les objets majeurs. **Sa séquence de versions est 0.**

## Tables

- `versions` (id) : table des prochains numéros de versions et autres singletons (id value)
- `avrsa` (id) : clé publique d'un avatar
- `trec` (id) : transfert de fichier en cours (uploadé mais pas encore enregistré comme fichier d'un secret)

**Tables synchronisables**

- `compte` (id) : authentification et liste des avatars d'un compte
- `prefs` (id) : données et préférences d'un compte
- `compta` (id) : ligne comptable d'un avatar
- `cv` (id) : statut d'existence, signature et carte de visite des avatars, contacts et groupes
- `avatar` (id) : données d'un avatar et liste de ses contacts et groupes
- `couple` (id) : données d'un contact entre deux avatars
- `groupe` (id) : données d'un groupe
- `membre` (id, im) : données d'un membre d'un groupe
- `secret` (id, ns) : données d'un secret d'un avatar, d'un couple ou d'un groupe
- `contact` (phch) : parrainage ou rendez-vous de A0 vers un A1 à créer ou inconnu
- `invitgr` (id, ni) : **NON persistante en IDB**. invitation reçue par un avatar à devenir membre d'un groupe
- `invitcp` (id, ni) : **NON persistante en IDB**. invitation reçue par un avatar à devenir membre d'un couple
- `chat` (id, dh) : chat d'un compte avec les comptables.
- `tribu` (id) : données et compteurs d'une tribu.

## Table: `versions` - CP : `id`
L'id vaut 0 (possibilité d'utiliser 1 ... ultérieurement pour d'autres usages).

La colonne `v` est un array d'entiers : le compteur N s'applique aux objets majeurs dont le reste de la division de son id par 99 + 1 vaut N. Le compteur 0 est par convention celui de la séquence universelle utilisée pour `cv`.

>Le nombre de collisions n'est pas vraiment un problème : détecter des proximités entre avatars / groupes dans ce cas devient un exercice très incertain (fiabilité de 1 sur 99).

Table :

    CREATE TABLE "versions" (
    "id"  INTEGER,
    "v"  BLOB,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;

## Table : `tribu` - CP `id`. Informations d'une tribu
Les tribus sont crées et purgées par le comptable.

Table : 

    CREATE TABLE "tribu" (
    "id"	INTEGER,
    "v"		INTEGER,
    "nbc" INTEGER,
    "f1"  INTEGER,
    "f2"  INTEGER,
    "r1"  INTEGER,
    "r2"  INTEGER,
    "datak"	BLOB,
    "mncpt" BLOB,
    "datat"	BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;

- `id` : id de la tribu.
- `v`
- `nbc` : nombre de comptes actifs dans la tribu.
- `f1 f2` : sommes des volumes V1 et V2 déjà attribués comme forfaits aux comptes de la tribu.
- `r1 r2` : volumes V1 et V2 en réserve pour attribution aux comptes actuels et futurs de la tribu.
- `datak` : cryptée par la clé K du comptable :
  - `[nom, rnd]`: nom immuable et clé de la tribu.
  - `info` : commentaire privé du comptable.
- `mncpt` : map des noms complets des parrains:
  - _valeur_ : `[nom, rnd]` crypté par la clé de la tribu
  - _clé_ : `id`du parrain.
  - l'ajout d'un parrain ne se fait que par le comptable mais un retrait peut s'effectuer aussi par un traitement de GC
- `datat` : cryptée par la clé de la tribu :
  - `st` : raison majeure du blocage : 0 à 9 repris dans la configuration de l'organisation.
  - `c`: 1 si positionné par le comptable (dans une tribu toujours 1)
  - `txt` : libellé explicatif du blocage.
  - `jib` : jour initial de la procédure de blocage
  - `lj` : `[j12 j23 j34]` : nb de jours de passage des niveaux de 1 à 2, 2 à 3, 3 à 4.
  - `dh` : date-heure de dernier changement du statut de blocage.
- `vsh`

## Table: `trec` - CP `id idf`. Transfert de fichier en cours
L'upload d'un fichier est long. Cette table permet de gérer un commit à 2 phases:
- phase 1 : début de l'upload : insertion d'un row identifiant le fichier commençant à être uploadé,
- phase 2 : validation du fichier par le commit de l'objet Secret : suppression du row.
- `dlv` donne une date de validité permettant de purger les fichiers uploadés (ou pas d'ailleurs) sur échec du commit entre les phases 1 et 2. Ceci permet de faire la différence entre un upload en cours et un vieil uploadé manqué.

Table:

    CREATE TABLE IF NOT EXISTS "trec" (
      "id"	INTEGER,
      "idf" INTEGER,
      "dlv" INTEGER,
      PRIMARY KEY("id", "idf")
    );
    CREATE INDEX "dlv_trec" ON "trec" ( "dlv" );

## Table : `compte` - CP `id`. Authentification d'un compte
_Phrase secrète_ : une ligne 1 de 16 caractères au moins et une ligne 2 de 16 caractères au moins.  
`pcb` : PBKFD de la phrase complète (clé X) - 32 bytes.  
`dpbh` : hashBin (53 bits) du PBKFD du début de la phrase secrète (32 bytes).

Table :

    CREATE TABLE "compte" (
    "id"	INTEGER,
    "v"		INTEGER,
    "dpbh"	INTEGER,
    "pcbh"	INTEGER,
    "kx"  BLOB,
    "stp"  INTEGER,
    "nctk"  BLOB,
    "nctpc"  BLOB,
    "chkt"  INTEGER,
    "mack"  BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
    CREATE UNIQUE INDEX "dpbh_compte" ON "compte" ( "dpbh" );

- `id` : id de l'avatar primaire du compte.
- `v` :
- `dpbh` : hashBin (53 bits) du PBKFD du début de la phrase secrète (32 bytes). Pour la connexion, l'id du compte n'étant pas connu de l'utilisateur.
- `pcbh` : hashBin (53 bits) du PBKFD de la phrase complète pour quasi-authentifier une connexion avant un éventuel échec de décryptage de `kx`.
- `kx` : clé K du compte, cryptée par la X (phrase secrète courante).
- `stp` : statut parrain (0: non, 1:oui).
- `nctk` : nom complet `[nom, rnd]` de la tribu crypté,
  - soit par la clé K du compte,
  - soit par la clé publique de son avatar primaire après changement de tribu par le comptable.
- `mack` {} : map des avatars du compte cryptée par la clé K. 
  - _Clé_: id,
  - _valeur_: `[nom, rnd, cpriv]`
    - `nom rnd` : nom et clé de l'avatar.
    - `cpriv` : clé privée asymétrique.
- `vsh`

**Remarques :** 
- un row `compte` ne peut être modifié que par une transaction du compte (mais peut être purgé par le traitement journalier de détection des disparus).
- il est synchronisé lorsqu'il y a plusieurs sessions ouvertes en parallèle sur le même compte depuis plusieurs sessions de browsers.
- chaque mise à jour vérifie que `v` actuellement en base est bien celle à partir de laquelle l'édition a été faite pour éviter les mises à jour parallèles intempestives.
- le row `compte` change rarement : seulement à l'occasion de l'ajout / suppression d'un avatar, d'un changement de phrase secrète et d'un changement de tribu.

## Table : `prefs` - CP `id`. Préférences et données d'un compte
Afin que le row compte qui donne la liste des avatars ne soit mis à jour que rarement, les données et préférences associées au compte sont mémorisées dans une autre table :
- chaque type de données porte un code court :
  - `mp` : mémo personnel du titulaire du compte.
  - `mc` : mots clés du compte.
  - ... `fs` : ultérieurement filtres des secrets (par exemple).
- le row est juste un couple `[id, map]` où map est la sérialisation d'une map ayant :
  - une entrée pour chacun des codes courts ci-dessus : la map est donc extensible sans modification du serveur.
  - pour valeur la sérialisation cryptée par la clé K du compte de l'objet Javascript en donnant le contenu.
- le row est chargé lors de l'identification du compte, conjointement avec le row `compte`.
- une mise à jour ne correspond qu'à un seul code court afin de réduire le risque d'écrasements entre sessions parallèles.

Table :

    CREATE TABLE "prefs" (
    "id"	INTEGER,
    "v"		INTEGER,
    "mapk" BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
	
- `id` : id du compte.
- `v` :
- `mapk` {} : map des préférences.
  - _clé_ : code court (`mp, mc ...`)
  - _valeur_ : sérialisation cryptée par la clé K du compte de l'objet JSON correspondant.
- `vsh`

## Table `avrsa` : CP `id`. Clé publique RSA des avatars
Cette table donne la clé RSA (publique) obtenue à la création de l'avatar : elle permet d'inviter un avatar à être contact ou à devenir membre d'un groupe.

Table :

    CREATE TABLE "avrsa" (
    "id"	INTEGER,
    "clepub"	BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
	
- `id` : id de l'avatar.
- `clepub` : clé publique.
- `vsh`

## Table: `cv` : CP `id`. Répertoire des objets majeurs : avatars, contacts, groupes
Cette table a trois objectifs :
- détenir la `dds` **date de dernière signature** de chaque objet qualifiant le dernier jour où il était _vivant / utile_ c'est à dire référencée à l'ouverture d'une session de l'application. Un compte cible d'une procédure de blocage ne signe plus, sa disparition physique est déjà programmée (mais pas certaine, la procédure peut être levée).
- détenir `x` **l'état d'existence** de l'objet, 0-existant, 1-suppression logique, N-suppression terminée. N indique aussi quand le row pourra être purgé, ne servant plus à rien.
- détenir la **_carte de visite_**, quand il y en a une, des avatars et groupes.
- la version `v` permet de synchroniser cv en session et d'en propager, le statut d'existence et les évolutions de carte de visite.

Table :

    CREATE TABLE "cv" (
    "id"	INTEGER,
    "v" INTEGER,
    "x" INTEGER,
    "dds" INTEGER,
    "cv"	BLOB,
    "vsh" INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
    CREATE INDEX "id_v_cv" ON "cv" ( "id", "v");
    CREATE INDEX "dds_cv" ON "cv" ( "dds" ) WHERE "dds" > 0;
    CREATE INDEX "x_cv" ON "cv" ( "x" ) WHERE "x" = 1;
	
- `id` : id de l'avatar / du couple / du groupe.
- `v` : version du dernier changement de `x` ou `cv` (PAS de `dds`). Les versions sont prises dans la séquence 0, tous les objets partagent donc pour leur `cv` la même séquence de version dans le répertoire. Les sessions peuvent ainsi requérir en début de session.
- `x` : statut de disparition :
  - 0 : existant
  - 1 : inexistant logiquement mais la purge complète des objets demandée au GC quotidien n'a pas encore été faite.
  - J : inexistant logiquement et purges des objets terminées. `J > 1` : **le row** `cv` est à purger définitivement le jour J + 500.
- `dds` : **date de dernière signature** de l'avatar / contact / groupe (dernière connexion). 
- `cv` : **carte de visite** cryptée par la clé de l'objet.
- `vsh`

#### Abonnements aux objets majeurs
Les sessions s'abonnent à la liste des avatars / contacts / groupes qui délimitent l'espace de données du compte :
- _central_ : **soit pour l'objet intégralement** : les avatars du compte, les groupes accédés par le compte, les contacts ou figurent un de leurs avatars,
- _annexe_ : **soit pour les seules données d'existence / carte de visite** : les _avatars_ membres des groupes cités ci-dessus et des contacts cités ci-dessus.

Quand un row de `cv` est modifié (`x` et / ou `cv`), le row est retourné pour synchronisation de la session : c'est ainsi que celle-ci prend connaissance de la disparition de ses objets centraux et annexes (membres de groupe / conjoints de contacts).

#### Réactions en session aux avis de destruction d'objets
Pour les avatars du compte, les groupes auxquels le compte participe et les contacts d'un de ses avatars, les objets en session sont supprimés, ainsi que les objets dépendants (secrets, membres). Ils sont aussi supprimés de la base IDB.

Concernant les autres avatars _externes_ (pas du compte), ils apparaissent :
- soit comme conjoint d'un contact,
- soit comme membre d'un groupe.

A réception de ces notifications,
- les cartes de visite sont supprimées et le statut disparu rendu apparent (impact sur les vues).
- une opération est lancée pour mettre à jour, si nécessaire, les statuts des membres et conjoints concernés.

## Table: `avatar` : CP `id`. Données d'un avatar
Chaque avatar a un row dans cette table :
- la liste de ses groupes (avec leur nom et clé).
- la liste des contacts dont il fait partie (avec leur clé).

Table :

    CREATE TABLE "avatar" (
    "id"   INTEGER,
    "v"  	INTEGER,
    "lgrk" BLOB,
    "lcck"  BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
    CREATE INDEX "id_v_avatar" ON "avatar" ( "id", "v" );

- `id` : id de l'avatar
- `v` :
- `lgrk` : map :
  - _clé_ : `ni`, numéro d'invitation (aléatoire 4 bytes) obtenue sur `invitgr`.
  - _valeur_ : cryptée par la clé K du compte de `[nom, rnd, im]` reçu sur `invitgr`.
  - une entrée est effacée par la résiliation du membre au groupe ou sur refus de l'invitation (ce qui l'empêche de continuer à utiliser la clé du groupe).
- `lcck` : map :
  - _clé_ : `ni`, numéro pseudo aléatoire. Hash de (`cc` en hexa suivi de `0` ou `1`).
  - _valeur_ : clé `cc` cryptée par la clé K de l'avatar cible (le hash donne son id).
- `vsh`

La lecture de `avatar` permet d'obtenir,
- la liste des groupes dont il est membre (avec leur nom, id et clé),
- la liste des couples dont il fait partie (avec leur id et clé).

## Table: `compta` : CP `id`. Ligne comptable de l'avatar d'un compte
Il y a une ligne par avatar avec ses compteurs de quotas / usage de volumes V1 et V2.

Un avatar principal a des données supplémentaires:
- `t` : la tribu du compte (0 pour un avatar secondaire).
- `datat` : cryptées par la clé de la tribu les données de blocage par du compte par le comptable ou un parrain. Données absentes en absence de blocage.
- `sta` : le statut de l'ardoise du compte associée à sa tribu.
- `ard1, ard2 ard3` : cryptées par la clé de la tribu, les données inscrites sur l'adoise. En général absentes.

#### Données de l'ardoise
L'ardoise sert à résoudre un problème ou obtenir une réponse à une question entre le compte, le / les parrains de sa tribu et le comptable.
- si la situation traitée demande que le comptable soit informé et possiblement intervienne, l'indicateur `c` vaut 1 (sinon 0)
- le compte peut inscrire dans `ard1` un texte `t` à la date-heure `dh` avec son nom complet `na` (tous les parrains et le comptable ne le connaît pas forcément).
- un parrain de nom complet `na` peut inscrire dans `ard2` un texte `t` à la date-heure `dh`.
- le comptable peut (quand `c` vaut 1), inscrire dans `ard3` un texte `t` à la date-heure `dh`.

Trois indicateurs `i1` (pour le compte), `i2` (pour un parrain de la tribu), `i3` (pour le comptable) traduisent la position de chaque interlocuteur vis à vis de l'ardoise :
- `0` : l'ardoise **n'a pas été lue**, du moins dans sa dernière mise à jour.
- `1` : l'ardoise **a été lue** mais le sujet reste à traiter du point de l'interlocuteur.
- `2` : l'ardoise **a été lue et le sujet est clos** du point de vue de l'interlocuteur

Quand un des 3 interlocteurs inscrit / met à jour son message, les indicateurs des 2 autres repassent à 0. 
- un statut `(c i1 i2 i3)` valant `(1 2 2 2)` signifie que tout le monde est d'accord pour considérer le sujet comme clos et l'ardoise est effacée.
- de même pour un statut `(0 2 2 x)` : le sujet ne concerne pas / plus le comptable et les deux autres sont d'accord pour considérer le sujet comme réglé.

Ce statut `sta` `(c i1 i2 i3)` est indexé et permet à chacun des interlocteurs de savoir facilement s'il y a une ardoise, si elle a été lue dans sa dernière version et si le sujet porté est considéré comme réglé et par qui.

**Usages:**
- pour un **compte filleul**: le row compta est synchronisé en session qui peut afficher à tout instant l'évolution du statut de l'ardoise (lue, effacée ...).
- pour un **compte parrain**:
  - à la connexion : une requête rapporte le nombre d'ardoises existantes de la tribu existantes et le nombre d'entre elles non lues par le / les parrains. Cet indicateur s'affiche en session mais n'est pas synchronisé.
  - sur demande en cours de session, l'indicateur peut être recalculé et mis à jour. 
  - un rapport (liste des rows `compta`) peut être obtenu pour tous les comptes de la tribu ou seulement ceux ayant une ardoise ouverte.
- pour le **comptable**:
  - à la connexion : une requête rapporte le nombre d'ardoises existantes, toutes tribus confondues, et le nombre d'entre elles non lues par le comptable. Cet indicateur s'affiche en session mais n'est pas synchronisé.
  - sur demande en cours de session, l'indicateur peut être recalculé et mis à jour. Il peut aussi être obtenu pour une tribu donnée.
  - un rapport (liste des rows `compta`) peut être obtenu pour tous les comptes d'une tribu ou seulement ceux ayant une ardoise ouverte, ou toutes tribus confondues ayant une ardoise sollicitant le comptable (lue ou non par lui).

Table :

    CREATE TABLE "compta" (
    "id"	INTEGER,
    "t"	INTEGER,
    "v"	INTEGER,
    "datat"  BLOB,
    "data"	BLOB,
    "sta" INTEGER,
    "ard1" BLOB,
    "ard2" BLOB,
    "ard3" BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
    CREATE INDEX "st_compta" ON "compta" ( "st" ) WHERE "st" > 0;
    CREATE INDEX "ard_compta" ON "compta" ( "t", "sta" ) WHERE "sta" > 0;

- `id` : de l'avatar.
- `t` : id de la tribu pour un avatar primaire (0 pour un secondaire). Par convention l'avatar principal du comptable (qui n'a pas de tribu) à `1` dans `t`.
- `v` :
- `datat` : seulement pour un avatar primaire, cryptée par la clé de la tribu :
  - `st` : raison majeure du blocage : 0 à 9 repris dans la configuration de l'organisation.
  - `c`: 1 si positionné par le comptable (dans une tribu toujours 1)
  - `txt` : libellé explicatif du blocage.
  - `jib` : jour initial de la procédure de blocage
  - `lj` : `[j01 j12 j23 j34]` : nb de jours de passage des niveaux 0 à 1, 1 à 2, 2 à 3, 3 à 4.
  - `dh` : date-heure de dernier changement du statut de blocage.
- `data`: compteurs sérialisés (non cryptés)
- `sta` : statut de l'ardose `(c i1 i2 i3)`
- `ard1 ard2 ard3` : textes cryptés par la clé de la tribu :
  - `t dh na`
- `vsh` :

**datat**
- le Comptable peut s'arroger le droit de gérer un blocage personnel.
- dans ce cas `c` vaut 1 et un parrain ne peut plus gérer le blocage, jusqu'à ce que le Comptable enlève éventuellement cet indicateur.
- un parrain ne peut pas gérer le blocage d'un autre parrain, seulement ceux des comptes non parrain de la même tribu.

**data**
- `j` : **la date du dernier calcul enregistré** : par exemple le 17 Mai de l'année A
- **pour le mois en cours**, celui de la date ci-dessus :
  - `v1 v1m` volume v1 des textes des secrets : 1) moyenne depuis le début du mois, 2) actuel, 
  - `v2 v2m` volume v2 de leurs pièces jointes : 1) moyenne depuis le début du mois, 2) actuel, 
  - `trm` cumul des volumes des transferts de pièces jointes : 14 compteurs pour les 14 derniers jours.
- **forfaits v1 et v2** `f1 f2` : les plus élevés appliqués le mois en cours.
- `rtr` : ratio de la moyenne des tr / forfait v2
- **pour les 12 mois antérieurs** `hist` (dans l'exemple ci-dessus Mai de A-1 à Avril de A),
  - `f1 f2` les forfaits v1 et v2 appliqués dans le mois.
  - `r1 r2` le pourcentage du volume moyen dans le mois par rapport au forfait: 1) pour v1, 2) por v2.
  - `r3` le pourcentage du cumul des transferts des pièces jointes dans le mois par rapport au volume v2 du forfait.
- `s1 s2` : pour un avatar primaire, total des forfaits attribués aux secondaires.
- `v1c v2c` : total des v1 et v2 pour tous les avatars du compte constaté lors de la dernière connexion.

Les _ratios_ sont exprimés en pourcentage de 1 à 255% : mais 1 est le minimum (< 1 fait 1) et 255 le maximum.

## Table: `couple` : CP id. Contact entre deux avatars A0 et A1
Deux avatars A0 et A1 sont en **contact** dès lors que A0 a pris contact avec A1.

Un **contact** est créé avec :
- la clé `cc` cryptant les données communes dont les secrets du contact.
- l'`id` qui est le hash de cette clé.
- le nom et la clé de A0.
- a minima le nom de A1 (pas toujours sa clé qui peut ne pas être connue avant acceptation de A1).

Un contact est connu dans chaque avatar A0 et A1 par une entrée dans leurs maps respectives `lcck` : 
- les clés dans ces maps sont des numéros _d'invitation_ : hash de (`cc` en hexa suivi de `0` (pour A0) ou `1` (pour A1)).
- la valeur est la `clé` crypté par la clé K du compte de l'avatar.

**Un contact a un nom en interne** formé de l'accolement des deux noms de A0 et A1 : il est donc bien immuable. Même dans le cas d'un rendez-vous ou d'un parrainage, A0 doit fournir le _nom exact_ de l'avatar qu'il contacte à défaut d'avoir sa clé (donc pas son id).

Quand A0 et A1 sont tous deux _disparu_, le contact disparaît.

**Prolongation**
- pour un parrainage ou un rendez-vous, la prolongation ne peut s'effectuer qu'avant la fin de la `dlv`.
- la `dlv` est modifiée sur les rows `contact` et `couple`.

Table :

    CREATE TABLE "couple" (
    "id"   INTEGER,
    "v"  	INTEGER,
    "st"  INTEGER,
    "npi" INTEGER,
    "v1"  INTEGER,
    "v2"  INTEGER,
    "mx10"  INTEGER,
    "mx20"  INTEGER,
    "mx11"  INTEGER,
    "mx21"  INTEGER,
    "dlv"	INTEGER,
    "datac"  BLOB,
    "phk0"	BLOB,
    "infok0"	BLOB,
    "infok1"	BLOB,
    "mc0"	BLOB,
    "mc1"  BLOB,
    "ardc"	BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
    CREATE INDEX "id_v_couple" ON "couple" ( "id", "v" );

- `id` : id du contact
- `v` :
- `st` : quatre chiffres `p o 0 1` : phase / état
  - `p` : phase - (1) en attente, (2) hors délai, (3) refusé, (4) actif, (5) orphelin.
  - `o` : origine du contact: (0) direct, (1) parrainage, (2) rencontre.
  - `0` : pour A0 - (0) pas de partage de secrets, (1) partage de secrets, (2) disparu.
  - `1` : pour A1 -
- `npi` : `0 10 01 11` : options ne pas inviter de A0 et A1.
- `v1 v2` : volumes actuels des secrets.
- `mx10 mx20` : maximum des volumes autorisés pour A0
- `mx11 mx21` : maximum des volumes autorisés pour A1
- `dlv` : date limite de validité éventuelle de prise de contact.
- `datac` : données cryptées par la clé `cc` du couple :
  - `x` : `[nom, rnd], [nom, rnd]` : nom et clé d'accès à la carte de visite respectivement de A0 et A1.
- `phk0` : phrase de parrainage / rencontre cryptée par la clé K du parrain (sera détruite après acceptation / refus hors délai).
- `infok0 infok1` : commentaires personnels cryptés par leur clé K, respectivement de A0 et A1.
- `mc0 mc1` : mots clé définis respectivement par A0 et A1.
- `ardc` : ardoise commune cryptée par la clé cc. [dh, texte]
- `vsh` :

Dans un contact il y a deux avatars, l'initiateur et l'autre : `im` **l'indice membre** d'un avatar dans un de ses contacts est par convention,
- `1` s'il est initiateur `datac.x[0]`,
- `2` dans l'autre cas `datac.x[1]`,
- la valeur 0 n'est pas utilisée.

_Remarques_
- pour un compte parrain, la liste de ses filleuls est la liste des contacts ayant par convention un mot clé `Filleul`.
- pour un compte filleul: son parrain de création a par convention le mot clé `Parrain`. 

## Table: `contact` : CP `phch`. Parrainage ou rendez-vous
Les rows `contact` ne sont pas synchronisés en session : ils sont,
- lus sur demande par A1,
- supprimés physiquement éventuellement par A0 sur remord ou prolongés par mise à jour de la `dlv`.

Ceci couvre les deux cas de parrainage et de rendez-vous.
- pour un parrainage : c'est sur la page de login que le filleul peut accéder à son parrainage, l'accepter ou le refuser.
- pour un rendez-vous : c'est sur la page de l'avatar souhaitant se rendre à un rendez-vous qu'un bouton permet de créer (si c'est le premier) ou d'accéder (si c'est le second) aux détails du contact pour accepter ou refuser.
- dans les deux cas (acceptation / refus) le row `contact` est détruit.

**En cas de non réponse, le GC détruit le row après dépassement de la `dlv`.**

Table :

    CREATE TABLE "contact" (
    "phch"   INTEGER,
    "dlv"	INTEGER,
    "datax"  BLOB,
    "vsh" INTEGER,
    PRIMARY KEY("phch");
    CREATE INDEX "dlv_contact" ON "contact" ( "dlv" );

- `phch` : hash de la phrase de contact convenue entre le parrain A0 et son filleul A1 (s'il accepte)
- `dlv`
- `datax` : cryptée par le PBKFD de la phrase de contact:
  - `cc` : clé du couple (donne son id).
  - `naf` : nom complet de A1 pour première vérification immédiate en session que la phrase est a priori bien destinée à cet avatar. Le nom de A1 figure dans le nom du couple après celui de A0.
  - Pour un parrainage seulement
    - `nct` : `[nom, rnd]` nom complet de la tribu.
    - `parrain` : vrai si le compte parrainé est parrain (créé par le Comptable, le seul qui peut le faire)
    - `forfaits` : `[f1, f2]` quotas attribués par le parrain.
  - Pour une rencontre seulement
    - `idt` : id de la tribu de A0 SEULEMENT SI A0 en est parrain.
- `vsh` :

#### _Parrainage_
- Le parrain peut détruire physiquement son `contact` avant acceptation / refus (remord).
- Le parrain peut prolonger la date-limite de son contact (encore en attente), sa `dlv` est augmentée.

**Si le filleul refuse le parrainage :** 
- L'ardoise du `couple` contient une justification / remerciement du refus, état _refusé_, la phrase de contact est effacée du contact.
- Le row `contact` est supprimé. 

**Si le filleul ne fait rien à temps :** 
- Lors du GC sur la `dlv`, le row `contact` sera supprimé par GC de la `dlv`,
- la phrase de contact est effacée du row `couple`. 

**Si le filleul accepte le parrainage :** 
- Le filleul crée son compte et son premier avatar (dans `couple.datac.x[1]` vaut `[nom, rnd]` qui donne l'id de son avatar et son nom). Les infos de tribu pour le compte sont obtenu de `contact`.
- la ligne `compta` du filleul est créée et créditée des quotas attribués par le parrain.
- la ligne `tribu` est mise à jour (quotas / réserves).
- le row `couple` est mis à jour (état _actif_), l'ardoise renseignée, les volumes maximum sont fixés.

#### _Rendez-vous_ initié par A0 avec A1
- A0 peut détruire physiquement son contact avant acceptation / refus (remord).
- A0 peut prolonger la date-limite de la rencontre (encore en attente), sa `dlv` est augmentée.

**Si A1 refuse :** 
- L'ardoise du `couple` contient une justification / remerciement du refus, état _refusé_.
- Le row `contact` est supprimé. 

**Si A1 ne fait rien à temps :** 
- Lors du GC sur la `dlv`, le row `contact` sera supprimé par GC de la `dlv`. 

**Si A1 accepte :** 
- le row `couple` est mis à jour (état _actif_), l'ardoise renseignée, les données `[nom, rnd]` sont définitivement fixées (`nom` l'était déjà). Les volumes maximum sont fixés.

## Table: `groupe` : CP: `id`. Entête et état d'un groupe
Un groupe est caractérisé par :
- son entête : un row de `groupe`.
- la liste de ses membres : des rows de `membre`.
- la liste de ses secrets : des rows de `secret`.

L'hébergemnet d'un groupe est noté par :
- `imh`: indice membre de l'avatar hébergeur.
- `dfh`: la date de fin d'hébergement qui vaut 0 tant que groupe est hébergé.

Le compte peut mettre fin à son hébergement:
- `dfh` indique le jour de la fin d'hébergement.
- les secrets ne peuvent plus être mis à jour en croissance.
- à `dfh` + N jours, le GC plonge le groupe en état _zombi_
  - `dfh` vaut 99999 et toutes les propriétés autres que `id v` sont 0 / null.
  - les secrets et membres sont purgés.
  - le groupe est _ignoré_ en session, comme s'il n'existait plus et est retiré au fil des login des maps `lgrk` des avatars qui le référencent (ce qui peut prendre jusqu'à un an).
  - le row `groupe` sera effectivement détruit par le GC quotidien seulement sur dépassement de `dds`.
  - ceci permet aux sessions de ne pas risquer de trouver un groupe dans des `lgrk` d'avatar sans row `groupe` (sur dépassement de `dds`, les login sont impossibles).

**Les membres d'un groupe** reçoivent lors de leur création (opération de création d'un contact d'un groupe) un indice membre `im` :
- cet indice est attribué en séquence : le premier membre est celui du créateur du groupe a pour indice 1.
- les rows membres ne sont jamais supprimés, sauf par purge physique à la suppression logique de leur groupe.

Table :

    CREATE TABLE "groupe" (
    "id"  INTEGER,
    "v"   INTEGER,
    "dfh" INTEGER,
    "st"  INTEGER,
    "mxim"  INTEGER,
    "imh"  INTEGER,
    "v1"  INTEGER,
    "v2"  INTEGER,
    "f1"  INTEGER,
    "f2"  INTEGER,
    "mcg"   BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id")
    ) WITHOUT ROWID;
    CREATE INDEX "dfh_groupe" ON "groupe" ( "dfh" ) WHERE "dfh" > 0;
    CREATE INDEX "id_v_groupe" ON "groupe" ( "id", "v" );

- `id` : id du groupe.
- `v` :
- `dfh` : date (jour) de fin d'hébergement du groupe par son hébergeur
- `st` : `x y`
    - `x` : 1-ouvert (accepte de nouveaux membres), 2-fermé (ré-ouverture en vote)
    - `y` : 0-en écriture, 1-protégé contre la mise à jour, création, suppression de secrets.
- `mxim` : dernier `im` de membre attribué.
- `idhg` : id du compte hébergeur crypté par la clé du groupe.
- `imh` : indice `im` du membre dont le compte est hébergeur.
- `v1 v2` : volumes courants des secrets du groupe.
- `f1 f2` : forfaits attribués par le compte hébergeur.
- `mcg` : liste des mots clés définis pour le groupe cryptée par la clé du groupe cryptée par la clé du groupe.
- `vsh`

## Table: `membre` : CP `id nm`. Membre d'un groupe
Pour ajouter un membre _pressenti_ à un groupe il faut donner son indice `im` qui doit être égal à `mxim` du groupe + 1 : ceci prémunit contre des enregistrements parallèles d'un même avatar en tant que membre pressenti. L'opération boucle jusqu'à ce que ça soit le cas.

Table

    CREATE TABLE "membre" (
    "id"  INTEGER,
    "im"	INTEGER,
    "v"		INTEGER,
    "st"	INTEGER,
    "npi" INTEGER,
    "vote"  INTEGER,
    "mc"  BLOB,
    "infok" BLOB,
    "datag"	BLOB,
    "ardg"  BLOB,
    "vsh"	INTEGER,
    PRIMARY KEY("id", "im"));
    CREATE INDEX "id_v_membre" ON "membre" ( "id", "v" );

- `id` : id du **groupe**.
- `im` : indice du membre dans le groupe.
- `v` :
- `st` : `x p i`
  - `x` : 0:pressenti, 1:invité, 2:actif (invitation acceptée), 3: refusé (invitation refusée), 4: résilié, 5: disparu.
  - `p` : 0:lecteur, 1:auteur, 2:animateur.
- `npi` : 0: accepte d'être invité, 1: ne le souhaite pas.
- `vote` : vote de réouverture.
- `mc` : mots clés du membre à propos du groupe.
- `infok` : commentaire du membre à propos du groupe crypté par la clé K du membre.
- `datag` : données, immuables, cryptées par la clé du groupe :
  - `nom, rnd` : nom complet de l'avatar.
  - `ni` : numéro d'invitation du membre dans `invitgr`. Permet de supprimer l'invitation et d'effacer le groupe dans son avatar (clé de `lgrk`).
	- `idi` : id du membre qui l'a _envisagé_.
- `ardg` : ardoise du membre vis à vis du groupe, couple `[dh, texte]` crypté par la clé du groupe.
- `vsh`

**Remarques**
- les membres de statut _invité_ et _actif_ peuvent accéder à la liste des membres et à leur _ardoise_ : ils ont la clé du groupe dans leur row `avatar`.
- les membres _actif_ accèdent aux secrets. En terme de cryptographie, les membres invités _pourraient_ aussi en lecture (ils ont reçu la clé dans l'invitation) mais le serveur l'interdit.
- les membres des statuts _pressenti, refusé, résilié, disparu_ n'ont pas / plus la clé du groupe dans leur row `avatar` (`lgrk`). `infok` est null.
- un membre _résilié_ peut être réinvité, le numéro d'invitation `ni` est réutilisé.
- le row `membre` d'un membre subsiste quand il est _résilié, disparu_ pour information historique du groupe: sa carte de visite est toutefois inaccessible quand il est _disparu_.

## Table: `invitgr` : CP `id ni`. Invitation d'un avatar M par un animateur A à un groupe G
Un avatar A connaît la liste des groupes dont il est membre par son row `avatar` qui reprend les identités des groupes cryptées par la clé K du compte.

Une invitation est un row qui **notifie** une session d'un avatar M qu'il a été inscrit comme membre invité d'un groupe :
- elle porte l'id de l'invité.
- elle porte un numéro d'invitation aléatoire qui permettra aux animateurs du groupe de _résilier_ l'accès de A au groupe en détruisant la référence au groupe dans le row avatar de A.
- elle porte le couple `nom rnd` identifiant le groupe et sa clé crypté par la clé publique de l'avatar.

Dans une session de M dès que cette invitation parvient, soit par synchronisation, soit au chargement initial, la session poste une opération `regulGr` qui va inscrire dans le row avatar de M le nouveau groupe `nom rnd im` mais crypté par la clé K du compte de M. Ceci détruit l'invitation devenu inutile.

    CREATE TABLE "invitgr" (
    "id"  INTEGER,
    "ni" INTEGER,
    "datap" BLOB,
    PRIMARY KEY ("id", "ni"));

- `id` : id du membre invité.
- `ni` : numéro d'invitation.
- `datap` : crypté par la clé publique du membre invité. `[nom, rnd, im]` : nom complet du groupe (donne sa clé) + indice de l'invité dans le groupe.

## Table `invitcp` : CP `id ni`. Invitation d'un avatar B par un avatar A à former un couple C
Un avatar connaît la liste des couples dont il fait partie par son row `avatar` qui reprend les clés de ces couples cryptées par la clé K du compte.

Une invitation est un row qui **notifie** une session d'un avatar B qu'il a été inscrit comme second membre du couple :
- elle porte l'id de l'invité.
- elle porte son numéro d'invitation en complément d'identification.
- elle porte `cc` la clé du couple cryptée par la clé publique de l'avatar B.

Dans une session de B dès que cette invitation parvient, soit par synchronisation, soit au chargement initial, la session poste une opération `regulCp` qui va inscrire dans le row avatar de B la clé du nouveau couple `cc` mais crypté par la clé K du compte de B. Ceci détruit l'invitation devenu inutile.

    CREATE TABLE "invitcp" (
    "id"  INTEGER,
    "ni" INTEGER,
    "datap" BLOB,
    PRIMARY KEY ("id", "ni"));

- `id` : id du membre invité.
- `ni` : numéro d'invitation pseudo aléatoire. Hash de (`cc` en hexa suivi de `0` ou `1` selon que ça s'adresse au membre 0 ou 1 du couple).
- `datap` : clé du couple cryptée par la clé publique du membre invité.

## Table `secret` : CP `id ns`. Secret
Un secret est identifié par:
- `id` : l'id du propriétaire (avatar / contact / groupe),
- `ns` : numéro complémentaire aléatoire.

La clé de cryptage du secret `cles` est selon le cas :
- (0) *secret personnel d'un avatar A* : la clé K de l'avatar.
- (1) *secret d'un couple d'avatars A0 et A1* : la clé `cc` de leur `couple`.
- (2) *secret d'un groupe G* : la clé du groupe G.

Le droit de mise à jour d'un secret est contrôlé par le couple `xxxp` :
- `xxx` indique quel avatar a l'exclusivité d'écriture et le droit de basculer la protection :
  - pour un secret personnel, x est implicitement l'avatar détenteur du secret.
  - pour un secret de couple, 1 ou 2.
  - pour un secret de groupe, x est `im` l'indice du membre.
- `p` indique si le texte est protégé contre l'écriture ou non.

**Secret temporaire et permanent**
Par défaut à sa création un secret est _permanent_. Pour un secret _temporaire_ :
- son `st` contient la _date limite de validité_ indiquant qu'il sera automatiquement détruit à cette échéance.
- un secret temporaire peut être prolongé, tout en restant temporaire.
- par convention le `st` d'un secret permanent est égal à `99999`. Un temporaire peut être rendu permanent par :
  - l'avatar propriétaire pour un secret personnel.
  - les deux avatars pour un secret de couple.
  - un des animateurs pour un secret de groupe.

Table :

    CREATE TABLE "secret" (
    "id"  INTEGER,
    "ns"  INTEGER,
    "v" INTEGER,
    "x" INTEGER,
    "st"  INTEGER,
    "xp" INTEGER,
    "v1"  INTEGER,
    "v2"  INTEGER,
    "mc"   BLOB,
    "txts"  BLOB,
    "mfas"  BLOB,
    "refs"  BLOB,
    "vsh" INTEGER,
    PRIMARY KEY("id", "ns");
    CREATE INDEX "id_v_secret" ON "secret" ("id", "v");

- `id` : id du groupe ou de l'avatar.
- `ns` : numéro du secret.
- `x` : jour de suppression (0 si existant).
- `v` :
- `st` :
  - `99999` pour un *permanent*.
  - `dlv` pour un _temporaire_.
- `xp` : _xxxp_ (`p` reste de la division par 10)
   - `xxx` : exclusivité : l'écriture et la gestion de la protection d'écriture sont restreintes au membre du groupe dont `im` est `x`. Pour un secret de contact : 1 ou 2.
    - `p` : 0: pas protégé, 1: protégé en écriture.
- `v1` : volume du texte
- `v2` : volume total des fichiers attachés
- `mc` :
  - secret personnel : vecteur des index de mots clés.
  - secret de contact : map sérialisée,
    - _clé_ : `im` de l'auteur (1 ou 2),
    - _valeur_ : vecteur des index des mots clés attribués.
  - secret de groupe : map sérialisée,
    - _clé_ : `im` de l'auteur (0 pour les mots clés du groupe),
    - _valeur_ : vecteur des index des mots clés attribués par le membre.
- `txts` : crypté par la clé du secret.
  - `d` : date-heure de dernière modification du texte
  - `l` : liste des auteurs (pour un secret de contact ou de groupe).
  - `t` : texte gzippé ou non
- `mfas` : map des fichiers attachés.
- `refs` : couple `[id, ns]` crypté par la clé du secret référençant un autre secret _référence de voisinage_ qui par principe, lui, n'aura pas de `refs`).
- `vsh`

**_Remarque :_** un secret peut être explicitement supprimé. Afin de synchroniser cette forme particulière de mise à jour pendant un an (le délai maximal entre deux login), le row est conservé jusqu'à la date `x` + 400 avec toutes les colonnes (sauf `id ns x v`) à 0 / null.

**Mots clés `mc`:**
- Secret personnel : `mc` est un vecteur d'index de mots clés. Les index sont ceux du compte et de l'organisation.
- Secret de contact: `mc` est une map a deux entrée `1 2`, une pour A0 et A1 du contact. La valeur est le vecteur des mots clés attribué par l'avatar A0 ou A1. Les index des mots clés sont ceux personnels de l'avatar et ceux de l'organisation.
- Secret de groupe : `mc` est une map :
  - _clé_ : im, indice du membre dans le groupe. Par convention 0 désigne le groupe lui-même.
  - _valeur_ : vecteur d'index de secrets. Les index sont ceux personnels du membre, ceux du groupe, ceux de l'organisation.

**Map des fichiers attachés :**
- _clé_ `idf`: numéro aléatoire généré à la création. L'identifiant _externe_ est `id, idf`
- _valeur_ : `{ nom, info, dh, type, gz, lg, sha }` crypté par la clé S du secret.

**Identifiant de stockage :** `reseau/sid/idf`  
- `reseau` : code du réseau.
- `sid` : id du secret en base64 URL : identifiant de l'avatar / contact / groupe auquel le secret appartient.
- `idf` : identifiant aléatoire du fichier

En imaginant un stockage sur file system,
- il y a un répertoire par réseau,
- pour chacun, un répertoire par avatar / contact / groupe ayant des secrets ayant des fichiers attachés,
- pour chacun, un fichier par fichier attaché.

_Un nouveau fichier attaché_ est stocké sur support externe **avant** d'être enregistré dans son row `secret`. Ceci est noté dans la table `trec` des transferts en cours. 
Les fichiers créés par anticipation et non validés dans un `secret` comme ceux qui n'y ont pas été supprimés après validation du secret, peuvent être retrouvés par un GC qui peut s'exécuter en lisant seulement les _clés_ de la map `mafs`.

La suppression d'un avatar / contact / groupe s'accompagne de la suppression de son _répertoire_. 

La suppression d'un secret s'accompagne de la suppressions de N fichiers dans un seul _répertoire_.

## Mots clés, principes et gestion

Les mots clés sont utilisés pour :
- filtrer / caractériser à l'affichage les **contacts** d'un compte.
- filtrer / caractériser à l'affichage les **groupes** accédés par un compte.
- filtrer / caractériser à l'affichage les **secrets**, personnels, partagés avec un contact ou d'un groupe.

# Gestion des disparitions / résiliations
## Signatures des avatars, contacts et groupes
Les comptes sont censés avoir au maximum N0 jours (400) entre 2 connexions faute de quoi ils sont considérés comme disparus.

Les `dds` (date de dernière signature) sont exprimées en nombre de jours depuis le 1/1/2021 : elles signalent que ce jour-là, l'avatar, le contact, le groupe était *vivant / utile / référencé*. Pour éviter des rapprochements entre eux, la *vraie* date de signature peut être entre 0 et 30 jours *avant*.

A chaque connexion d'un compte, son avatar principal signe dans `cv` si la `dds` actuelle n'est pas _récente_ (si elle est récente, aucune signature n'est mise à jour) :
- pour lui-même : jour de signature tiré aléatoirement entre j-28 et j-14.
- jour de signature tiré aléatoirement pour chacun entre j-14 et j.
  - pour ses avatars secondaires,
  - pour ses contacts,
  - pour les groupes auxquels ses avatars sont invités ou actifs.

Il y a aussi des signatures en plus de la connexion à un compte :
- pour un avatar: à sa création.
- pour un contact: à sa création par A0 et à l'acceptation par A1.
- pour un groupe: à sa création et à l'acceptation d'une invitation d'un membre.

>Les signatures n'ont pas lieu si le row `compta` de l'avatar principal ou de sa tribu font l'objet d'une procédure de blocage.

**La fin d'hébergement d'un groupe** provoque l'inscription de la date du jour dans la propriété `dfh` du row `groupe` (sinon elle est à zéro).

## Disparition _explicite_ d'un avatar
Pour un avatar primaire, tous les avatars secondaires doivent être préalablement supprimés.

Pour un avatar secondaire, l'opération exécute :
- pour chaque contact,
  - si l'autre partie du contact existe, le statut de l'avatar est juste mis à _orphelin_
  - sinon le contact est supprimé logiquement (le x de son row cv est à 1).
- pour chaque groupe dont il est membre :
  - s'il est le dernier membre _actif_, le groupe est supprimé logiquement (le x de son row cv est à 1).
  - sinon, son statut est mis à _disparu_ et s'il était hébergeur, la date de fin d'hébergement est positionnée.
- la comptabilité de l'avatar principal est créditée des quotas de l'avatar supprimé.
- l'avatar est retiré de la liste des avatars de son compte.
- l'avatar est supprimé logiquement (le x de son row cv est à 1).
- suppression des rows `avatar compta`.

Pour un avatar principal, l'opération exécute :
- pour chaque contact,
  - si l'autre partie du contact existe, le statut de l'avatar est juste mis à _orphelin_
  - sinon le contact est supprimé logiquement (le x de son row cv est à 1).
- pour chaque groupe dont il est membre :
  - s'il est le dernier membre _actif_, le groupe est supprimé logiquement (le x de son row cv est à 1).
  - sinon, son statut est mis à _disparu_ et s'il était hébergeur, la date de fin d'hébergement est positionnée.
- la comptabilité de la tribu est créditée des quotas de l'avatar supprimé (en fait du compte).
- l'avatar est supprimé logiquement (le x de son row cv est à 1).
- suppression des rows `compte prefs avatar compta`.

Ces opérations sont longues bien que beaucoup de nettoyages soient différés sur le GC quotidien.

## Disparition d'un groupe par auto-résiliation _explicite_ de son dernier membre
- suppression logique du groupe (le x de son row cv est à 1).
- si l'avatar était hénergeur du groupe, la comptabilité de l'avatar est créditée des volumes du groupe.

## Disparition d'un contact par auto-résiliation _explicite_ de son dernier conjoint
- suppression logique du contact (le x de son row cv est à 1).
- si l'avatar partageait les secrets, la comptabilité de l'avatar est créditée des volumes du contact.

## GC quotidien
Délais :
- N1 : 400 jours, un peu plus d'un an. Inactivité d'un compte.
- N2 : 100 jours. Délai de survie d'un groupe sans hébergeur.

Le GC quotidien a un _point de reprise_ enregistré dans `versions` sous l'id 1. Sérialisation de :
- date du jour de GC
- 4 date-heure de fin des 4 étapes.

Quand le GC est lancé,
- soit il part sur un nouveau traitement quotidien si le dernier a eu ses 4 étapes terminées et que le jour courant est postérieur au dernier jour du traitement.
- soit il part en reprise à l'étape qui n'avait pas été terminée.

Le GC quotidien effectue les activités de nettoyage suivantes :
- **étape 1** : 1 transaction, la fin marque que l'étape 1 est finie.
  - suppressions logiques des rows dans `cv`, des groupes ayant dépassé leur `dfh` de N2 jours : `x` passe à 1, `cv` à null.
  - synchronisation de cette suppression logique, des sessions peuvent être ouvertes et accéder à ces groupes. Chaque session émettra **une opération pour retirer le groupe de sa liste des groupes**, soit en synchronisation, soit à la connexion.
- **étape 2** : sans synchronisation.
  - suppressions logiques des rows dans `cv` sur dépassement de leur `dds` de N1 jours : `x` passe à `1`, `cv` à null.
  - quand c'est la cv d'un avatar principal (un compte), réaffectation à sa tribu et décrémentation du compteur de compte actif.
  - purge physique des rows `contact` ayant une date-limite de validité `dlv` dépassée.
  - fin d'étape 2 enregistrée.
- **étape 3** : sans synchronisation. Pour chaque objet dont l'id est en suppression logique,
  - purge de tous ses fichiers sur support externe (1 appel par objet supprime tous les fichers de l'objet).
  - fin d'étape 3 enregistrée.
- **étape 4** : sans synchronisation. Pour chaque objet dont l'id est en suppression logique,
  - purges physiques des rows `compte prefs avatar avrsa compta groupe membre couple secrets`.
  - fin d'étape 4 enregistrée.
- **étape 5** : sans synchronisation.
  - Pour chaque row de `dlv` obsolète de `trec`, transferts finalement non validés en table `secret`:
    - suppression du fichier sur support externe,
    - suppression du row dans `trec`.
  - fin d'étape 5 enregistrée.

**_Remarque_** : l'avatar principal d'un compte est toujours détruit physiquement avant ses avatars secondaires puisqu'il apparaît plus ancien que ses avatars dans l'ordre des signatures. Le compte n'étant plus accessible par son avatar principal, ses avatars secondaires ne seront plus signés ni les groupes et contacts auxquels ils accédaient.

### Opérations provoquées sur synchronisation / connexion avec réception de row cv dont x est > 0
Ils agissent comme des avis de disparition:
- (a) cv de l'avatar externe d'un contact : opération de mise à jour du statut de disparition de l'autre conjoint du contact.
- (b) cv d'un avatar membre d'un groupe : opérations de mise à jour du statut du membre à _disparu_.
- (c) cv de groupe détecté disparu: opérations pour retirer ce groupe de la liste des groupes accédés par les avatars du compte.
- _Remarque_ : pas de traitement pour un cv de contact détecté disparu le cas est traité par (a).

**Remarque pour (a) et (b)**
La disparition de A0 ou A1 d'un couple ou d'un membre est constatée en session quand sa carte de visite est demandée / rafraîchie : elle revient alors à `null` avec un statut _disparu_.
- cette constatation n'est pas pérenne sur le long terme: au bout d'un certain temps, la carte de visite ne revient plus du tout du serveur et il est impossible à une session de discerner si c'est parce qu'elle est inchangée ou disparue.
- chaque session constatant une carte de visite _disparu_ pour A0 / A1 d'un contact ou un membre d'un groupe, fait inscrire sur le serveur le statut _disparu_ sur le contact (`st0` ou `st1` à 2) ou le membre :
  - ceci évite aux autres sessions de procéder à la même opération.
  - les cartes de visite ne sont plus demandées par les sessions (ce qui réduit le trafic et les recherches inutiles en base centrale).
