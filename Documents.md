# Données persistantes sur le serveur

Les données persistantes sont gérées selon deux implémentations :
- **SQL** : les données sont distribuées dans des **tables** `espaces avatars versions notes ...`
- **Firestore** : chaque table SQL correspond à une **collection de documents**, chaque document correspondant à un **row** de la table SQL de même nom que la collection.

Les _colonnes_ d'une table SQL correspondent aux _attributs / propriétés_ d'un document.
- en SQL la _clé primaire_ est une propriété attribut ou un couple de propriétés,
- en Firestore le _path_ d'un document contient cette propriété ou couple de propriétés.

## Table / collection `singletons`
La collection singletons a un seul document `checkpoint` ayant les attributs suivants:
- `id` : qui vaut 1 (il _pourrait_ ultérieurement exister d'autres singletons 2 3 ...).
- `v` : sa version, qui est l'estampille en ms de sa dernière mise à jour.
- `_data_` : sérialisation non cryptée des données traçant l'exécution du dernier traitement journalier de GC (garbage collector).

Son _path_ en Firestore est `singletons/1`.

Le document `checkpoint` est réécrit totalement à chaque exécution du GC.
- son existence n'est jamais nécessaire et d'ailleurs lors de la première exécution il n'existe pas.
- il ne sert qu'à l'administrateur technique pour s'informer, en cas de doutes, du bon fonctionnement du traitement GC en délivrant quelques compteurs, traces d'exécution, traces d'erreurs.

## Espaces
Tous les autres documents comportent une colonne / attribut `id` dont la valeur détermine un partitionnement en _espaces_ cloisonnés : dans chaque espace aucun document ne référence un document d'un autre espace.

Un espace est identifié par `ns`, **un entier de 10 à 69**. Chaque espace à ses données réparties dans les collections / tables suivantes:
- `espaces syntheses` : un seul document / row par espace. Leur attribut `id` (clé primaire en SQL) a pour valeur le `ns` de l'espace. Path pour le `ns` 24 par exemple : `espaces/24` `syntheses/24`.
- tous les autres documents ont un attribut / colonne `id` de 16 chiffres dont les 2 premiers sont le `ns` de leur espace. Les propriétés des documents peuvent citer l'id d'autres documents mais sous la forme d'une _id courte_ dont les deux premiers chiffres ont été enlevés.

### Exportation / purge d'un espace
Un utilitaire permet, en se basant exclusivement sur la valeur de l'attribut `id` des documents:
- d'exporter un _espace_ d'une base (SQL ou Firestore) dans une autre en changeant éventuellement son `ns` (passant par exemple de `24` à `32`).
- purger les données d'un _espace_ d'une base.

### Code organisation attaché à un espace
A la déclaration d'un espace sur un serveur, l'administrateur technique déclare un **code organisation**:
- ce code ne peut plus changer.
- le Storage de fichiers comporte un _folder_ racine portant ce code d'organisation ce qui partitionne le stockage de fichiers.
- les connexions aux comptes citent ce _code organisation_: il préfixe les _phrases secrètes_ et de contact des comptes et avatars. Les PBKFD et autres hash stockés dans les documents en dépendent directement, ce qui exclut de pouvoir les changer.

> Un Storage pour une organisation peut être exporté dans un autre Storage:
- les fichiers sont physiquement recopiés,
- à cette occasion le code de l'organisation (la racine du Storage) peut être changé, celui de la _cible_ pouvant différer de celui de la _source_. Le changement de code a pour seul intérêt d'effectuer un cliché (pour _backup_ ou test).

### Tables / collections
#### Entête de l'espace: `espaces syntheses`
- `espaces` : `id` est le `ns` (par exemple `24`) de l'espace. Le document contient quelques données générales de l'espace.
  - Clé primaire : `id`. Path : `espaces/24`
- `syntheses` : `id` est le `ns` de l'espace. Le document contenant des données statistiques sur la distribution des quotas et l'utilisation de ceux-ci.
  - Clé primaire : `id`. Path : `syntheses/24`

#### Gestion de volumes disparus : `gcvols fpurges`
- `gcvols` : son `id` est celui de l'avatar principal d'un compte dont la disparition vient d'être détectée. Ses données donnent, cryptées pour le Comptable, les références permettant de restituer les volumes V1 et V2 de facto libérés par la disparition d'un compte O `id`. 
  - Clé primaire : `id`. Path : `gcvols/{id}`
- `fpurges` : son `id` est aléatoire, les deux premiers chiffres étant le `ns` de l'espace. Un document correspond à un ordre de purge dans le Storage des fichiers, soit d'un _répertoire_ entier (correspondant à un avatar ou un groupe), soit dans ce répertoire à une liste fermée de fichiers.
  - Clé primaire : `id`. Path : `fpurges/{id}`

Ces documents sont écrits une fois et restent immuables jusqu'à leur traitement qui les détruit:
- prochaine ouverture de session du Comptables pour les `gcvols`,
- prochain GC, étape `GCfpu`, pour les `fpurges`.

#### Collections / tables _majeures_ : `tribus comptas avatars groupes versions`
Chaque collection a un document par `id` (clé primaire en SQl, second terme du path en Firestore).
- `tribus` : un document par _tranche de quotas / tribu_ décrivant comment sont distribués les quotas de la tranche entre les comptes.
  - `id` (sans le ns) est un numéro séquentiel `1..N`.
  - Clé primaire : `id`. Path : `tribus/0...x`
- `comptas` : un document par compte donnant les informations d'entête d'un compte (dont l'`id` est celui de son avatar principal). L'`id` courte sur 14 chiffres est le numéro du compte :
  - `10...0` : pour le comptable.
  - `2x...y` : pour un compte, `x...y` est un nombre aléatoire sur 13 chiffres.
  - Clé primaire : `id`. Path : `comptas/10...0` `comptas/2x...y`
- `avatars` : un document par avatar donnant les informations d'entête d'un avatar. L'`id` courte sur 14 chiffres est le numéro d'un avatar du compte :
  - `10...0` : pour l'avatar principal du Comptable.
  - `2x...y` : pour un autre avatar que l'avatar principal du Comptable, `x...y` est un nombre aléatoire sur 13 chiffres.
  - Clé primaire : `id`. Path : `avatars/10...0` `avatars/2x...y`
- `groupes` : un document par groupe donnant les informations d'entête d'un groupe. L'`id` courte sur 14 chiffres est le numéro d'un groupe :
  - `3x...y` : `x...y` est un nombre aléatoire sur 13 chiffres.
  - Clé primaire : `id`. Path : `groupes/3x...y`
- `versions` : un document par avatar et par groupe donnant le numéro de version, numéro d'ordre de la dernière mise à jour pour l'avatar ou le groupe et toutes leurs sous-collections.
  - Clé primaire : `id`. Path : `versions/10...0` `versions/2x...y` `versions/3x...y`

#### Sous-collections de `versions`: `notes transferts sponsorings chats membres tickets`
Pour un document `versions/2x...y` il existe,
- pour une version _d'avatar_ (id: 1... ou 2...), 4 sous-collections de documents: `notes transferts sponsorings chats` et pour le seul Comptable une cinquième `tickets`.
- pour une version _de groupe_ (id: 3...), 3 sous-collections de documents: `notes transferts membres`.

Dans chaque sous-collection, `ids` est un identifiant relatif à `id`. 
- en SQL les clés primaires sont `id,ids`
- en Firestore les paths sont (par exemple pour la sous-collection note) : `versions/2.../notes/z...t`, `id` est le second terme du path, `ids` le quatrième.

- `notes` : un document représente une note d'un avatar ou d'un groupe. L'identifiant relatif `ids` est un nombre aléatoire.
- `transferts` : un document représente un transfert (upload) en cours d'un fichier d'une note d'un avatar ou d'un groupe. L'identifiant relatif `ids` est un nombre aléatoire. Un document transfert est créé immuable: il est détruit quand le transfert a été un succès ou constaté abandonné par le GC.
- `sponsorings` : un document représente un sponsoring d'un avatar. Son identifiant relatif est le hash de la phrase de reconnaissance entre le sponsor et son sponsorisé.
- `chats` : un chat entre 2 avatars A et B se traduit en deux documents : 
  - l'un sous-document de A a pour identifiant secondaire `ids` un hash des clés de B et A.
  - l'autre sous-document de B a pour identifiant secondaire `ids` un hash des clés de A et B.
- `membres` : un document par membre avatar participant à un groupe. L'identifiant secondaire `ids` est l'indice membre `1..N`, ordre d'enregistrement dans le groupe.
- `tickets`: un document par ticket de crédit généré par un compte A. ids est un nombre aléatoire tel qu'il s'éditer sous forme d'un code à 6 lettres majuscules (de 1 à 308,915,776).

La _disparition_ d'un avatar ou d'un groupe, se traduit par :
- son document `versions` ayant un statut de _zombi_, indiquant que l'avatar ou le groupe a disparu,
- la purge effective de son document `avatars` ou `groupes` et de sa sous-collection de `notes transferts chats sponsorings membres`. Cette purge peut être temporellement différée, la _vraie_ marque de disparition est l'état _zombi_ de leur document `versions`.
- la purge effective d'un document `versions` intervient un an après son passage en état _zombi_, le temps que toutes les connexions des comptes actifs aient pu prendre connaissance de cet état.

### L'administrateur technique
Il a pour rôle majeur de gérer les espaces:
- les créer / les détruire,
- définir leurs quotas à disposition du Comptable de chaque espace: il existe trois quotas,
  - `q1` : volume maximal autorisé des textes des notes,
  - `q2` : volume total autorisé des fichiers attachés aux notes.
  - `qc` : quota de calcul mensuel total en monétaires.
- ces quotas sont _indicatifs_ mais sans blocage opérationnel et servent de prévention à un crash technique pour excès de consommation de ressources.

Ses autres rôles sont :
- la gestion d'une _notification / blocage_ par espace, sauf pour information technique importante, soit pour figer un espace avant sa migration vers une autre base (ou sa destruction).
- le transfert d'un espace d'une base vers une autre,
- le transfert des fichiers d'un espace d'un Storage à un autre.

### Comptable de chaque espace
Pour un espace, `24` par exemple, il existe un compte `2410000000000000` qui est le **Comptable** de l'espace. 

Le Comptable dispose des quotas globaux de l'espace attribués par l'administrateur technique. Il définit un certain nombre de **tranches de quotas** et confie chacune de ses tranches à des comptes _sponsors_ qui peuvent les distribuer aux comptes O qu'ils ont sponsorisé.

Par convention on dénomme `tribu` l'ensemble des comptes O partageant une même tranche de quotas.

Le rôle principal d'un _Comptable_ est de:
- définir des tranches de quotas et d'en ajuster les quotas,
- de déclarer les _sponsors_ de chaque tranche, le cas échéant de retirer ou d'ajouter la qualité de _sponsor_ a un compte O.
- gérer des _notifications / blocages_ s'appliquant à des comptes spécifiques ou à tous les comptes d'une tranche.

Le Comptable :
- ne peut pas se résilier lui-même,
- ne peut pas changer de tranche de quotas, il est rattaché à la tranche 1 de son espace qui ne peut pas être supprimée.
- ne peut pas supprimer son propre attribut _sponsor_,
- accepte l'ouverture de **chats** avec n'importe quel compte qui en prend l'initiative.

#### Quotas d'une tranche
La déclaration d'une tranche par le Comptable d'un espace consiste à définir :
- une clé de cryptage `clet` générée aléatoirement à la création de la tranche :
  - **les 2 premiers bytes donnent l'id de la tribu**, son numéro d'ordre de création par le Comptable partant de de 1,
- un très court texte `info` signifiant pour le Comptable,
- les sous-quotas `qc q1 q2` attribués.

`clet` est immuable, `info qc q1 q2` peuvent être mis à jour par le comptable.

#### Comptes _sponsors_
Les quotas `qc q1 q2` attribués à chaque compte sont prélevés sur une tranche, en d'autres termes, tout compte O fait partie d'une _tribu_.

Un compte O ou A est créé par _sponsoring_,
- soit d'un compte existant _sponsor_ : 
  - pour un compte O, ses quotas sont prélevés dans la tranche de son sponsor.
  - un compta A définit lui-même ses quotas `q1` et `q2` (mais il les paye en tant qu'abonnement) et n'a pas de quotas `qc` (il paye sa consommation).
- soit du Comptable : pour un compte O c'est le Comptable qui a choisi de quelle tranche il relève.

Les comptes ayant un pouvoir de **sponsor** peuvent:
- sponsoriser la création de nouveaux comptes, _sponsor_ eux-mêmes ou non,
- pour les comptes O seulement,
  - gérer la répartition des quotas entre les comptes de leur tranche,
  - gérer une _notification / blocage_ pour les comptes de leur tranche.

## Détail des tables / collections

Tous les documents, ont une propriété _data_ qui porte toutes les informations sérialisées du document.

Certaines de ces propriétés sont externalisées hors de _data_,
- soit parce que faisant partie de la clé primaire `id ids` en SQL, ou du path en Firestore,
- soit parce qu'elles sont utilisées dans des index.

**En Firestore** les documents des collections _majeures_ `tribus comptas avatars groupes versions` ont un ou deux attributs _techniques_ calculés et NON présents en _data_:
- `id_v` : un string `id/v` ou `id` est l'id sur 16 chiffres et `v` la version du document sur 9 chiffres.
- `id_vcv` pour les documents `avatars` seulement: un string `id/vcv` ou `id` est l'id sur 16 chiffres et `vcv` la version de la carte de visite de l'avatar sur 9 chiffres.

### Gestion des versions dans `versions`
- un document `avatar` d'id `ida` et les documents de ses sous collections `chats notes transferts sponsorings tickets` ont une version prise en séquence continue fixée dans le document `versions` ayant pour id `ida`.
- idem pour un document `groupe` et ses sous-collections `membres notes transferts`.
- toute mise à jour du document maître (avatar ou groupe) et de leur sous-documents provoque l'incrémentation du numéro de version dans `versions` et l'inscription de cette valeur comme version du (sous) document mis à jour.

Un document `versions` gère :
- `v` : sa version (celle de l'avatar / groupe et leurs sous-collections).
- `dlv` : la date de fin de vie de son avatar ou groupe.
- en _data_ pour un groupe :
  - `v1 q1` : nombre de notes du groupe (actuel et maximal).
  - `v2 q2` : volume et quota des fichiers des notes du groupe.

Quand la `dlv` est non 0 et inférieure ou égale à la date du jour,
- le document est en état _zombi_ et traduit le fait que l'avatar ou le groupe a disparu.
- sa _data_ est null.
- sa version `v` ne changera plus.
- sa `dlv` sera ramenée à un an plus tôt, dès que les documents et sous-documents correspondants auront été effectivement purgés, puis restera inchangée jusqu'à la purge effective du document `versions` lui-même à cette date là.

### Documents _synchronisables_ en session
Chaque session détient localement le sous-ensemble des données de la portée bien délimitée qui la concerne: en mode synchronisé les documents sont stockés en base IndexedDB (IDB) avec le même contenu qu'en base centrale.

L'état en session est conservé à niveau en _s'abonnant_ à un certain nombre de documents et de sous-collections:
- (1) les documents `avatars comptas` de l'id du compte
- (2) le document `tribus` de l'id de leur tribu, tirée de (1)
- (3) les documents `avatars` des avatars du compte - listé par (1)
- (4) les documents `groupes` des groupes dont les avatars sont membres - listés par (3)
- (5) les sous-collections `notes chats sponsorings tickets` des avatars - listés par (3)
- (6) les sous-collections `membres notes` des groupes - listés par (4)
- (7) le document `espaces` de son espace.
- le comptable, en plus d'être abonné à sa tribu, peut temporairement s'abonner à **une** autre tribu _courante_.

Au cours d'une session au fil des synchronisations, la portée va donc évoluer depuis celle déterminée à la connexion:
- des documents ou collections de documents nouveaux sont ajoutés à IDB (et en mémoire de la session),
- des documents ou collections sont à supprimer de IDB (et de la mémoire de la session).

Une session a une liste d'ids abonnées :
- l'id de son compte : quand un document `compta` change il est transmis à la session.
- les ids de ses `groupes` et `avatars` : quand un document `versions` ayant une de ces ids change, il est transmis à la session. La tâche de synchronisation de la session va chercher le document majeur et ses sous documents ayant des versions postérieures à celles détenues en session.
- sa `tribu` actuelle (qui peut changer).
- implicitement le document `espaces` de son espace.
- **pour le Comptable** : en plus ponctuellement une seconde `tribu` _courante_.

**Remarque :** en session ceci conduit au respect de l'intégrité transactionnelle pour chaque objet majeur mais pas entre objets majeurs dont les mises à jour pourraient être répercutées dans un ordre différent de celui opéré par le serveur.
- en **SQL** les notifications _pourraient_ être regroupées par transaction et transmises dans l'ordre.
- en **FireStore** ce n'est pas possible : la session pose un écouteur sur des objets `espaces comptas tribus versions` individuellement, l'ordre d'arrivée des modifications ne peut pas être garanti entre objets majeurs.

En SQL :
- c'est le serveur qui détient la liste des abonnements de chaque session: les mises à jour transmises par WebSocket.

En Firestore :
- c'est la session qui détient la liste de ses abonnements, le serveur n'en dispose pas.
- la session pose un _écouteur_ sur chacun de ces documents.

Dans les deux cas c'est en session la même séquence qui traite les modifications reçues, sans distinction de comment elles ont été captées (message WebSocket ou activation d'un écouteur).

### Propriétés externalisées hors de _data_
#### `id` et `ids` (quand il existe)
Ces propriétés sont externalisées et font partie de la clé primaire (en SQL) ou du path (en Firestore).

Pour un `sponsorings` la propriété `ids` est le hash de la phrase de reconnaissance :
- elle est indexé.
- en Firestore l'index est `collection_group` afin de rendre un sponsorings accessible par index sans connaître son _parent_ le sponsor.

#### `v` : version d'un document
Tous les documents sont _versionnés_,
- **SAUF** `gcvols fpurges transferts` qui sont créés immuable et détruits par le premier traitement qui les lit (dont le GC). Ces documents ne sont pas synchronisés en sessions UI.
- **singletons syntheses** : `v` est une estampille (date-heure) et n'a qu'un rôle informatif : ces documents ne sont pas synchronisés en sessions UI.
- **tous les autres documents ont un version de 1..n**, incrémentée de 1 à chaque mise à jour de son document, et pour `versions` de leurs sous-collections.

En session UI pour chaque document ou sous-collection d'un document, le fait de connaître sa version permet,
- de ne demander la mise à jour que des documents plus récents de même id,
- à réception d'un row synchronisé de ne mettre à jour l'état en mémoire que s'il est effectivement plus récent que celui détenu.

#### `vcv` : version de la carte de visite
Cette propriété est la version `v` du document au moment de la dernière mise à jour de la carte de visite. `vcv` est définie pour `avatars chats membres` seulement.

#### `dlv` : **date limite de validité** 
Ces dates sont données en jour `aaaammjj` (UTC) et apparaissent dans : 
- (a) `versions membres`,
- (b) `sponsorings`,
- (c) `transferts`.

Un document ayant une `dlv` **antérieure au jour courant** est un **zombi**, considéré comme _disparu / inexistant_ :
- en session sa réception a pour une signification de _destruction / disparition_ : il est possible de recevoir de tels avis de disparition plusieurs fois pour un même document.
- il ne changera plus de version ni d'état, son contenu est _vide_, pas de _data_ : c'est un **zombi**.

**Sur _versions des avatars_ :**
- **jour auquel l'avatar sera officiellement considéré comme _disparu_**.
- la `dlv` (indexée) est reculée à l'occasion de l'ouverture d'une session pour _prolonger_ la vie de l'avatar correspondant.
- les `dlv` permettent au GC de récupérer tous les _avatars disparus_.

**Sur _membres_ :**
- **jour auquel l'avatar sera officiellement considéré comme _disparu ou ne participant plus au groupe_**.
- la `dlv` (indexée) est reculée à l'occasion de l'ouverture d'une session pour _prolonger_ la participation de l'avatar correspondant au groupe.
- les `dlv` permettent au GC de récupérer toutes les _participations disparues_ et in fine de détecter la disparition des groupes quand tous les participants actifs ont disparu.
- en Firestore l'index est `collection_group` afin de s'appliquer aux membres de tous les groupes.

**Sur _versions des groupes_ :**
- soit il n'y pas de `dlv` (0), soit la `dlv` est égale ou dépasse le jour courant : on ne trouve jamais dans une `versions` de groupe une `dlv` _future_ (contrairement aux `versions` des avatars et `membres`).
- pour _supprimer_ un groupe on lui fixe dans son `versions` une `dlv` du jour courant, il n'a plus de _data_, désormais _zombi et immuable_. Son `versions` sera purgé un an plus tard.

**Sur _sponsorings_:**
- jour à partir duquel le sponsoring n'est plus applicable ni pertinent à conserver. Les sessions suppriment automatiquement à la connexion les sponsorings ayant dépassé leur `dlv` (idem pour les synchronisations).
- il y a donc des sponsorings avec une `dlv` dans le futur : celle-ci peut être prolongée mais jamais avancée.
- dès atteinte du jour de `dlv`, un sponsorings est purgé (au moins purgeable).
- en Firestore l'index est `collection_group` afin de s'appliquer aux sponsorings de tous les avatars.

**Sur _transferts_:**
- **jour auquel il est considéré que le transfert tenté a définitivement échoué**.
- un `transferts` est _immuable_, jamais mis à jour : il est créé, supprimé explicitement ou purgé à atteinte de sa `dlv`.
- permet au GC de détecter les transferts en échec et de nettoyer le Storage.
- en Firestore l'index est `collection_group` afin de s'appliquer aux fichiers des notes de tous les avatars et groupe.

#### `dfh` : **date de fin d'hébergement** sur un document `groupes`
La **date de fin d'hébergement** sur un groupe permet de détecter le jour où le groupe sera considéré comme disparu. 

A dépassement de la `dfh` d'un groupe, le GC fait disparaître le groupe inscrivant une `dlv` du jour dans son document `versions`.

#### `hpc` : hash de la phrase de contact sur un document `avatars`
Cette propriété de `avatars` est indexée de manière à pouvoir accéder à un avatar en connaissant sa phrase de contact.

#### `hps1` : hash du début de la phrase secrète sur un document `comptas`
Cette propriété de `comptas` est indexée de manière à pouvoir accéder à un compte en connaissant sa phrase secrète (connexion).

#### Cache locale des `espaces comptas versions avatars groupes tribus` dans une instance d'un serveur
- les `comptas` sont utilisées à chaque mise à jour de notes.
- les `versions` sont utilisées à chaque mise à jour des avatars, de ses chats, notes, sponsorings.
- les `avatars groupes tribus` sont également souvent accédés.

**Les conserver en cache** par leur `id` est une bonne solution : mais en _FireStore_ (ou en SQL multi-process) il peut y avoir plusieurs instances s'exécutant en parallèle. Il faut en conséquence interroger la base pour savoir s'il y a une version postérieure et ne pas la charger si ce n'est pas le cas en utilisant un filtrage par `v`. Ce filtrage se faisant sur l'index n'est pas décompté comme une lecture de document quand le document n'a pas été trouvé parce que de version déjà connue.

En Firestore l'attribut calculé `id_v` permet d'effectuer ce filtrage (alors qu'en SQL l'index composé id / v est utilisable).

La mémoire cache est gérée par LRU (tous types de documents confondus).

## Généralités
**Les clés AES et les PBKFD** sont des bytes de longueur 32. Un texte crypté a une longueur variable :
- quand le cryptage est spécifié _libre_ le premier byte du texte crypté est le numéro du _salt_ choisi au hasard dans une liste pré-compilée : un texte donné 'AAA' ne donnera donc pas le même texte crypté à chaque fois ce qui empêche de pouvoir tester l'égalité de deux textes cryptés au vu de leur valeur cryptée.
- quand le cryptage est _fixe_ le numéro de _salt_ est 1 : l'égalité de valeurs cryptées traduit l'égalité de leur valeurs sources.

**Un entier sur 53 bits est intègre en Javascript** (9,007,199,254,740,991 soit 16 chiffres décimaux si le premier n'est pas 9). Il peut être issu de 6 bytes aléatoires.

Le hash (_integer_) de N bytes est un entier intègre en Javascript.

Le hash (_integer_) d'un string est un entier intègre en Javascript.

Les date-heures sont exprimées en millisecondes depuis le 1/1/1970, un entier intègre en Javascript (ce serait d'ailleurs aussi le cas pour une date-heure en micro-seconde).

Les dates sont exprimées en `aaaammjj` sur un entier (géré par la class `AMJ`). En base ce sont des dates UTC, elles peuvent s'afficher en date _locale_.

**Les clé RSA** sont de longueurs différentes pour la clé de cryptage (publique) et de décryptage (privée). Le résultat d'un cryptage a une longueur fixe de 256 bytes. Deux cryptages RSA avec la même clé d'un même texte donnent deux valeurs cryptées différentes.

#### Nom complet d'un avatar / groupe
Le **nom complet** d'un avatar / groupe est un couple `[nom, cle]`
- `nom` : nom lisible et signifiant, entre 6 et 20 caractères. Le nom `Comptable` est réservé. Le Comptable n'a pas de nom.
- `cle` : 32 bytes aléatoires. Clé de cryptage.
  - Le premier byte donne le _type_ de l'id, qu'on retrouve comme troisième chiffre de l'id :
    - 1 : comptable.
    - 2 : avatar.
    - 3 : groupe,
  - Les autres bytes sont aléatoires, sauf pour le Comptable où ils sont tous 0.
- A l'écran le nom est affiché sous la forme `nom@xyzt` (sauf `Comptable`) ou `xyzt` sont les 4 derniers chiffres de l'id.

**La clé d'une tribu** est composée par :
- byte 0 : 0,
- bytes 1 et 2 : numéro de la tribu, numéro d'ordre de sa déclaration par le Comptable,
- autres bytes aléatoires.

> Depuis la _clé_ d'une tribu, avatar, groupe on sait donc toujours recalculer son `id` et donc son `ns`.

> Une id **courte** est une id SANS les deux premiers chiffres de l'espace, donc relative à son espace.

**Dans les noms,** les caractères `< > : " / \ | ? *` et ceux dont le code est inférieur à 32 (donc de 0 à 31) sont interdits afin de permettre d'utiliser le nom complet comme nom de fichier.

### Authentification
L'administrateur technique a une phrase de connexion dont le hash est enregistré dans la configuration d'installation. Il n'a pas d'id. Une opération de l'administrateur est repérée parce que son _token_ donne ce hash.

Les opérations liées aux créations de compte ne sont pas authentifiées, elles vont justement enregistrer leur authentification.  
- Les opérations de GC et celles de type _ping_ ne le sont pas non plus.  
- Toutes les autres opérations le sont.

Une `sessionId` est tirée au sort par la session juste avant tentative de connexion : elle est supprimée à la déconnexion.

> **En mode SQL**, un WebSocket est ouvert et identifié par le `sessionId` qu'on retrouve sur les messages afin de s'assurer qu'un échange entre session et serveur ne concerne pas une session antérieure fermée.

> **En mode Firestore**, le serveur peut s'interrompre sans interrompre la session UI: les abonnements sont gérés dans la session UI, il n'y a pas de WebSocket et le token d'authentification permet d'identifier la session UI. En revanche le serveur du Firestore ne doit pas tomber.

Toute opération porte un `token` portant lui-même le `sessionId`:
- si le serveur retrouve dans la mémoire cache l'enregistrement de la session `sessionId` :
  - **il en obtient l'id du compte**,
  - il prolonge la `ttl` de cette session dans cette cache.
- si le serveur ne trouve pas la `sessionId`, 
  - soit il y en bien une mais ... dans un autre process, 
  - soit c'est une déconnexion pour dépassement de `ttl` de cette session.
  - Dans les deux cas l'authentification va être refaite depuis le `token` fourni et y fixer l'id du compte.

**`token`** : sérialisation encodée en base 64 de :
- `sessionId`
- `shax` : SHA de X (PBKFD de la phrase secrète complète).
- `hps1` : hash du PBKFD du début de la phrase secrète.

Le serveur recherche l'`id` du compte par `hps1` (index de `comptas`)
- vérifie que le SHA de `shax` est bien celui enregistré dans `comptas` en `shay`.
- inscrit en mémoire `sessionId` avec l'`id` du compte et un `ttl`.

# Détail des documents

### Sous-objet `notification`
De facto un objet notification est immuable: en cas de _mise à jour_ il est remplacé par un autre.

Il est crypté selon son type par 1) la clé du Comptable, 2-3) la clé de la tribu.

Type des notifications:
- 0 : de l'espace
- 1 : d'une tribu
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
- `texte`: texte de la notification.
- `idSource`: id du sponsor ayant créé cette notification pour un type 3.

**Remarque:** une notification `{ dh: ... }` correspond à la suppression de la notification antérieure (ni restriction, ni texte).

Un _dépassement de quotas Q1 / Q2_ entraîne une restriction (5).

Un _solde négatif (compte A)_ ou _une consommation excessive (compte O)_ entraîne une restriction (4). 

> Le document `comptas` a une date-heure de lecture qui indique _quand_ il a lu les notifications.

## Documents `espaces`
_data_ :
- `id` : de l'espace de 10 à 89.
- `v` : 1..N
- `org` : code de l'organisation propriétaire.
- `opt`:
  - 0: 'Pas de comptes "autonomes"',
  - 1: 'Le Comptable peut rendre un compte "autonome" sans son accord',
  - 2: 'Le Comptable NE peut PAS rendre un compte "autonome" sans son accord',
- `notif` : notification de l'administrateur, cryptée par la clé du Comptable.
- `t` : numéro de _profil_ de quotas dans la table des profils définis dans la configuration. Chaque profil donne un triplet de quotas `qc q1 q2` qui serviront de guide pour le Comptable qui s'efforcera de ne pas en distribuer d'avantage sans se concerter avec l'administrateur technique.

## Documents `gcvols`
_data_ :
- `id` : id du compte disparu.

- `cletX` : clé de la tribu cryptée par la clé K du Comptable.
- `it` : index d'enregistrement du compte dans cette tribu.

Un document `gcvols` est créé par le GC à la détection de la disparition d'un compte, son document `versions` étant _zombi_. Il accède à son document `comptas`, et y récupère `cletX it`. Après création du `gcvols`, le document `comptas`, désormais inutile, est purgé.

Le Comptable lors de sa prochaine ouverture de session, récupère tous les `gcvols` et les traite :
- il obtient l'`id` de la tribu en décryptant `cletX`, `it` lui donne l'indice du compte disparu dans la table `act` de cette tribu. 
- l'item `act[it]` est y détruit, ce qui de facto accroît les quotas attribuables aux autres.
- la synthèse de la tribu est mise à jour.

## Documents `tribu`
_data_:
- `id` : numéro d'ordre de création de la tribu.
- `v` : 1..N

- `cletX` : clé de la tribu cryptée par la clé K du comptable.
- `qc q1 q2` : quotas totaux de la tribu.
- `stn` : restriction d'accès de la notification _tribu_: _0:aucune 1:lecture seule 2:minimal_
- `notif`: notification de niveau tribu cryptée par la clé de la tribu.
- `act` : table des comptes de la tribu. L'index `it` dans cette table figure dans la propriété `it` du `comptas` correspondant :
  - `idT` : id court du compte crypté par la clé de la tribu.
  - `nasp` : si sponsor `[nom, cle]` crypté par la cle de la tribu.
  - `notif`: notification de niveau compte cryptée par la clé de la tribu (null s'il n'y en a pas).
  - `stn` : restriction d'accès de la notification _compte_: _0:aucune 1:lecture seule 2:minimal_
  - `qc q1 q2` : quotas attribués.
  - `cj v1 v2` : consommation journalière, v1, v2: obtenus de `comptas` lors de la dernière connexion du compte, s'ils ont changé de plus de 10%. **Ce n'est donc pas un suivi en temps réel** qui imposerait une charge importante de mise à jour de `tribus / syntheses` à chaque mise à jour d'un compteur de `comptas` et des charges de synchronisation conséquente.

Un sponsor (ou le Comptable) peut accéder à la liste des comptes de sa tranche : toutefois il n'a pas accès à leur carte de visite, sauf si l'avatar est connu par ailleurs, chats au moment du sponsoring ou ultérieur par phrase de contact, appartence à un même groupe ...

L'ajout / retrait de la qualité de `sponsor` n'est effectué que par le Comptable au delà du sponsoring initial par un sponsor.

## Documents `syntheses`
La mise à jour de tribu est de facto peu fréquente : une _synthèse_ est recalculée à chaque mise à jour de `stn, q1, q2` ou d'un item de `act`.

_data_:
- `id` : id de l'espace.
- `v` : date-heure d'écriture (purement informative).

- `atr` : table des synthèses des tribus de l'espace. L'indice dans cette table est l'id court de la tribu. Chaque élément est la sérialisation de:
  - `qc q1 q2` : quotas de la tribu.
  - `ac a1 a2` : sommes des quotas attribués aux comptes de la tribu.
  - `ca v1 v2` : somme des consommations journalières et des volumes effectivement utilisés.
  - `ntr0` : nombre de notifications tribu sans restriction d'accès.
  - `ntr1` : nombre de notifications tribu avec restriction d'accès _lecture seule_.
  - `ntr2` : nombre de notifications tribu avec restriction d'accès _minimal_.
  - `nbc` : nombre de comptes.
  - `nbsp` : nombre de sponsors.
  - `nco0` : nombres de comptes ayant une notification sans restriction d'accès.
  - `nco1` : nombres de comptes ayant une notification avec restriction d'accès _lecture seule_.
  - `nco2` : nombres de comptes ayant une notification avec restriction d'accès _minimal_.

`atr[0]` est la somme des `atr[1..N]` calculé en session, pas stocké.

## Documents `comptas`
_data_ :
- `id` : numéro du compte, id de son avatar principal.
- `v` : 1..N.
- `hps1` : le hash du PBKFD du début de la phrase secrète du compte.

- `shay`, SHA du SHA de X (PBKFD de la phrase secrète).
- `kx` : clé K du compte, cryptée par X (PBKFD de la phrase secrète courante).
- `dhvu` : date-heure de dernière vue des notifications par le titulaire du compte, cryptée par la clé K.
- `sp` : 1: est sponsor
- `cletX` : clé de la tribu cryptée par la clé K du comptable.
- `cletK` : clé de la tribu cryptée par la clé K du compte : si cette clé a une longueur de 256, elle est cryptée par la _clé publique RSA_ du compte (en cas de changement de tribu forcé par le comptable).
- `it` : index du compte dans la table `act` de sa tribu.
- `qv` : `{qc, q1, q2, nn, nc, ng, v2}`: quotas et nombre de groupes, chats, notes, volume fichiers. Valeurs courantes.
- `oko` : hash du PBKFD de la phrase de confirmation d'un accord pour passage de O à A ou de A à O.
- `credits` : pour un compte A seulement crypté par la clé K:
  - `total`: cumul des crédits reçus depuis le début de la vie du compte.
  - `tickets`: liste des tickets (`{ids, v, dg, dr, ma, mc, refa, refc, di}`).
  - juste après une conversion de compte O en A, `credits` est égal à `true`, une convention pour une création vierge.
- `compteurs` sérialisation non cryptée d'évolution des quotas, volumes et coûts.

**Pour le Comptable seulement**
-`atr` : table des tribus : `{clet, info, qc, q1, q2}` crypté par la clé K du comptable.
  - `clet` : clé de la tribu (donne aussi son id, index dans `act / astn`).
  - `info` : texte très court pour le seul usage du comptable.
  - `q` : `[qc, q1, q2]` : quotas globaux de la tribu.
- `astn` : table des restriction d'accès des notifications des tribus _0:aucune, 1:lecture seule, 2:accès minimal_.

La première tribu d'`id` 1 est la tribu _primitive_, celle du comptable et est indestructible.

**Remarques :**  
- Le document est mis à jour à minima à chaque mise à jour d'une note (`qv` et `compteurs`).
- La version de `comptas` lui est spécifique (ce n'est pas la version de l'avatar principal du compte).
- `cletX it` sont transmis par le GC dans un document `gcvols` pour notifier au Comptable, quel est le compte détecté disparu (donc de sa tribu).
- Le fait d'accéder à `atr` permet d'obtenir la _liste des tribus existantes_ de l'espace. Le serveur peut ainsi recalculer la statistique de l'espace (agrégation des compteurs des tribus) en scannant ces tribus.

## Documents `versions`
_data_ :
- `id` : id d'avatar / groupe
- `v` : 1..N, plus haute version attribuée aux documents de l'avatar / groupe dont leurs sous-collections.
- `dlv` : date de fin de vie, peut être future pour un avatar, est toujours dépassée pour un groupe. Date de purge définitive un an plus tard.
- `{v1 q1 v2 q2}`: pour un groupe, volumes et quotas des notes.

## Documents `avatars`
_data_:
- `id` : id de l'avatar.
- `v` : 1..N.
- `vcv` : version de la carte de visite afin qu'une opération puisse détecter (sans lire le document) si la carte de visite est plus récente que celle qu'il connaît.
- `hpc` : hash de la phrase de contact.

**Données n'existant que pour un avatar principal**
- `mck` : map des mots-clés du compte cryptée par la clé K -la clé est leur code 1-99- ("code": nom@catégorie).
- `mavk` : map des avatars du compte. 
  - _clé_ : hash de id court de l'avatar cryptée par la clé K du compte.
  - _valeur_ : couple `[nom clé]` de l'avatar crypté par la clé K du compte.
- `mpgk` : map des participations aux groupes des avatars du compte.
  - _clé_: `npgk`. hash du cryptage par la clé K du compte de `idg / idav`. Cette identification permet au serveur de supprimer une entrée de la map sans disposer de la clé K. `idg`: id courte du groupe, `idav`: id courte de l'avatar.
  - _valeur_: `{nomg, cleg, im, idav}` cryptée par la clé K.
    - `nomg`: nom du groupe,
    - `cleg`: clé du groupe,
    - `im`: indice du membre dans la table `flags / anag` du groupe.
    - `idav` : id (court) de l'avatar.
- `mcmemos` : map des couples `{mc, memo}` à propos des contacts (avatars) et groupes connus du compte:
  - _cle_: `id` crypté par la clé K du compte,
  - _valeur_ : `{ mc, memo }` crypté par la clé K du compte.
    - `mc` : mots clés du compte à propos du groupe.
    - `memo` : commentaire du compte à propos du groupe.

**Données disponibles pour tous les avatars**
- `pub` : clé publique RSA.
- `privk`: clé privée RSA cryptée par la clé K.
- `cva` : carte de visite cryptée par la clé _CV_ de l'avatar `{v, photo, info}`.
- `invits`: maps des invitations en cours de l'avatar:
  - _clé_: `ni`, numéro d'invitation. hash du cryptage par la clé du groupe de la clé _inversée_ de l'avatar. Ceci permet à un animateur du groupe de détruire l'entrée.
  - _valeur_: `{nomg, cleg, im}` cryptée par la clé publique RSA de l'avatar.
    - `nomg`: nom du groupe,
    - `cleg`: clé du groupe,
    - `im`: indice du membre dans la table `ast` du groupe.
- `pck` : PBKFD de la phrase de contact cryptée par la clé K.
- `napc` : `[nom, cle]` de l'avatar cryptée par le PBKFD de la phrase de contact.

_Remarque sur `mpgk.imp`_
- `imp` est l'im attribué au premier avatar du compte invité au groupe.
- les mots-clés attachés aux notes de ce groupe seront indexés par `imp`.
- plus d'un avatar du compte peuvent participer à un groupe donné, successivement ou en même temps. Les mots-clés attribués à une note seront les mêmes pour tous les avatars du groupe par souci de clarification. 

> **Mémos d'un compte**. Un compte peut attacher une liste de mots-clés et un mémo connu de lui seul à n'importe quel avatar ou groupe : ceci lui permet de filtrer des _contacts_ des _chats_ et des _groupes_ mais aussi d'y noter ce qu'il veut quelque soit le statut d'activité du contact ou du groupe.

### Cartes de visites des avatars
La création / mise à jour s'opère dans le document `avatars`.

**Mises à jour des cartes de visite des membres**
- la première inscription se fait à l'ajout de l'avatar comme _contact_ du groupe.
- en session, lorsque la page listant les membres d'un groupe est ouverte, elle envoie une requête au serveur donnant la liste des couples `[id, v]` des `ids` des membres et de leur version de carte de visite détenue dans le document `membres`.
- pour chacune ayant une version postérieure, le serveur la met à jour dans `membres`.
- ceci permet de voir en session des cartes de visite toujours à jour et d'éviter d'effectuer une opération longue à chaque mise à jour des cartes de visite par un avatar pour tous les groupes dont il est membre.

**Mise à jour dans les chats**
- à la mise à jour d'un chat, les cartes de visites des deux côtés sont rafraîchies (si nécessaire).
- en session au début d'un processus de consultation des chats, la session fait rafraîchir incrémentalement les cartes de visite qui ne sont pas à jour dans les chats: un chat ayant `vcv` en index, la nécessité de mise à jour se détecte sur une lecture d'index sans lire le document correspondant.

## Documents `tickets`
Ce sont des sous-documents de avatars qui n'existent **que** pour l'avatar principal du Comptable.

Il y a un document `tickets` par ticket de crédit généré par un compte A annonçant l'arrivée d'un paiement correspondant. Chaque ticket est dédoublé:
- un exemplaire dans la sous-collection `tickets` du Comptable,
- un exemplaire dans le documents `comptas` du compte A qui l'a généré, dans la liste `credits.tickets`, donc crypté par la clé K du compte A.

_data_:
- `id`: id du Comptable.
- `ids` : numéro du ticket
- `v` : version du ticket.

- `dg` : date de génération.
- `dr`: date de réception. Si 0 le ticket est _en attente_.
- `ma`: montant déclaré émis par le compte A.
- `mc` : montant déclaré reçu par le Comptable.
- `refa` : texte court (32c) facultatif du compte A à l'émission.
- `refc` : texte court (32c) facultatif du Comptable à la réception.
- `di`: date d'incorporation du crédit par le compte A dans son solde.

#### Cycle de vie
**Génération d'un ticket (annonce de paiement) par le compte A**
- le compte A déclare,
  - un montant `ma` celui qu'il affirme avoir payé / viré.
  - une référence `refa` textuelle libre facultative à un dossier de _litige_, typiquement un _avoir_ correspondant à une erreur d'enregistrement antérieure.
- le ticket est généré et enregistré en deux exemplaires.

**Effacement d'un de ses tickets par le compte A**
- en cas d'erreur, un ticket peut être effacé par son émetteur, _à condition_ d'être toujours _en attente_ (ne pas avoir de date de réception). Le ticket est physiquement effacé de `tickets` et de la liste `comptas.tickets`.

**Réception d'un paiement par le Comptable**
- le Comptable ne peut _que_ compléter un ticket _en attente_ (pas de date de réception) dans le mois d'émission du ticket ou le précédent. Au delà le ticket est _auto-détruit_.
- sur le ticket correspondant le Comptable peut remplir:
  - le montant `mc` du paiement reçu, sauf indication contraire par défaut égal au montant `ma`.
  - une référence textuelle libre `refc` justifiant une différence entre `ma` et `mc`. Ce peut être un numéro de dossier de _litige_ qui pourra être repris ensuite entre le compte A et le Comptable.
- la date de réception `dr` est inscrite, le ticket est _réceptionné_.
- le ticket est mise à jour dans `tickets` mais PAS dans la liste `comptas.credits.tickets` du compte A (le Comptable n'a pas la clé K du compte A).

**Lorsque le compte A va sur sa page de gestion de ses crédits,** 
- les tickets dont il possède une version plus ancienne que celle détenue dans tickets du Comptable sont mis à jour.
- les tickets émis un mois M toujours non réceptionnés avant la fin de M+1 sont supprimés.
- les tickets de plus de 2 ans sont supprimés. 

**Incorporation du crédit dans le solde du compte A**
- l'opération est automatique à la prochaine connexion du compte A postérieure à une _réception de paiement_. En cours de session, un bouton permet d'activer cette incorporation.
- elle consiste à intégrer au solde du compte le montant d'un ticket _réceptionné_ (mais pas encore _incorporé au solde_)
- le plus faible des deux montants `ma` et `mc` est incorporé au solde de `comptas.credits`. En cas de différence de montants, une alerte s'affiche.
- la date d'incorporation `di` est mise à jour dans l'exemplaire du compte mais PAS par dans `tickets` du Comptable (qui donc ignore la propriété `di`).

**Remarques:**
- de facto dans `tickets` un document ne peut avoir qu'au plus deux versions.
- la version de création qui créé le ticket et lui donne soon identifiant secondaire et inscrit les propriétés `ma` et éventuellement `refa` désormais immuables.
- la version de réception par le Comptable qui inscrit les propriétés `dr mc` et éventuellement `refc`. Le ticket devient immuable dans `tickets`.
- les propriétés sont toutes immuables.
- la mise à jour ultime qui inscrit `di` à titre documentaire ne concerne que l'exemplaire du compte A.

#### Listes disponibles en session
Un compte A dispose de la liste de ses tickets sur une période de 2 ans, quelque soit leur statut, sauf ceux auto-détruits parce que non réceptionnés avant fin M+1 de leur génération.

Le Comptable dispose en session de la liste des tickets détenus dans tickets. Cette liste est _synchronisée_ (comme pour tous les sous-documents).

#### Arrêtés mensuels
Le Comptable effectue des arrêtés mensuels. Chaque arrêté mensuel d'un mois M,
- récupère tous les tickets générés à M-1 et les efface de la liste `tickets`,
- les stocke dans un _fichier_ **CSV** dans la note `Tickets` du Comptable.

Pour rechercher un ticket particulier, par exemple pour traiter un _litige_ ou vérifier s'il a bien été réceptionné, le Comptable,
- dispose de l'information en ligne pour tout ticket de M et M-1,
- dans le cas contraire, ouvre l'arrêté mensuel correspondant au mois du ticket cherché qui est un fichier CSV basique.

#### Numérotation des tickets
L'ids d'un ticket est un entier de la forme : `aammrrrrrrrrrr`
- `aa` : année de génération,
- `mm` : mois de génération,
- `r...r` : aléatoire.

Un code à 6 lettres majuscules en est extrait afin de le joindre comme référence de _paiement_.
- la première lettre  donne le mois de génération du ticket : A-L pour les mois de janvier à décembre si l'année est paire et M-X pour les mois de janvier à décembre si l'année est impaire.
- les autres lettres correspondent à `r...r`.

Le Comptable sait ainsi dans quel _arrêté mensuel_ il doit chercher un ticket au delà de M+1 de sa date de génération à partir d'un code à 6 lettres désigné par un compte pour audit éventuel de l'enregistrement.

> **Personne, pas même le Comptable,** ne peut savoir quel compte A a généré quel ticket. Cette information n'est accessible qu'au compte A lui-même et est cryptée par sa clé K.

## Documents `chats`
Un chat est une suite d'items de texte communs à deux avatars I et E:
- vis à vis d'une session :
  - I est l'avatar _interne_,
  - E est un avatar _externe_ connu comme _contact_.
- un item est défini par :
  - le côté qui l'a écrit (I ou E),
  - sa date-heure d'écriture qui l'identifie pour son côté,
  - son texte crypté par une clé de cryptage connue seulement par I et E.

Un chat est dédoublé avec un exemplaire I et un exemplaire E:
- à son écriture, un item est ajouté des deux côtés.
- le texte d'un item écrit par I peut être effacé par I des deux côtés (mais pas modifié).
- I (resp. E) **peut effacer tous les items** I comme E de son côté: ceci n'impacte pas l'existence de ceux de l'autre côté.
- _de chaque côté_ la taille totale des textes de tous les items est limitée à 5000c. Les plus anciens items sont effacés afin de respecter cette limite.

Pour ajouter un item sur un chat, I doit connaître le `[nom, cle]` de E : membre du même groupe, chat avec un autre avatar du compte, ou obtenu en ayant fourni la phrase de contact de E.

La clé du chat `cc` a été générée à l'écriture du premier item:
- côté I, cryptée par la clé K de I,
- côté E, cryptée par la clé publique de E. Dans ce cas à la première écriture de E celle-ci sera ré-encryptée par la clé K de E.

**Décompte des nombres de chats par compte**
- un chat est compté pour 1 pour I quand la dernière opération qu'il a effectué est un ajout: si cette dernière opération est un _raz_, le chat est dit _passif_ et compte pour 0.
- ce principe de gestion évite de pénaliser ceux qui reçoivent des chats non sollicités et qui les _effacent_.

Quand son avatar E s'est auto-résilié, son document `versions` devient _zombi_. Son document `chats` a été détruit.

S'étant adressé à E, I a récupéré que E était détruit. 
- si le chat I était _passif_, le chat de I devient _zombi_ afin que cet état se propage aux autres sessions du compte et soit détecté en connexion (le _contact_ disparaît).
- sinon, le statut `r E` passe à 2. I conserve le dernier état de l'échange, mais,
  - il ne pourra plus le changer,
  - il ne pourra qu'effectuer un _raz_, ce qui rendra le chat _zombi_: de facto E n'écrira plus dessus et ça ne sert à rien d'écrire à un _disparu_.

Quand I a fait rafraîchir les cartes de visite dans sa session, ça lui retourne l'information de la disparition éventuelle de son _contact_.

L'`id` d'un exemplaire d'un chat est le couple `id, ids`.

_data_ (de l'exemplaire I):
- `id`: id de A,
- `ids`: hash du cryptage de `idI_court/idE_court` par la clé de I.
- `v`: 1..N.
- `vcv` : version de la carte de visite de E.

- `st` : deux chiffres `I E`
  - I : 0:passif, 1:actif
  - E : 0:passif, 1:actif, 2:disparu
- `cva` : `{v, photo, info}` carte de visite de E au moment de la création / dernière mise à jour du chat, cryptée par la clé de E.
- `cc` : clé `cc` du chat cryptée par la clé K du compte de I ou par la clé publique de I (quand le chat vient d'être créé par E).
- `nacc` : `[nom, cle]` de E crypté par la clé du chat.
- `items` : liste des items `[{a, dh, l t}]`
  - `a` : 0:écrit par I, 1: écrit par E
  - `dh` : date-heure d'écriture.
  - `l` : taille du texte.
  - `t` : texte crypté par la clé du chat (vide s'il a été supprimé).

**Actions possibles (par I)**
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

> Un chat _passif_ pour un avatar est un chat _écouté_, les items écrits par E arrivent, mais sur lequel I n'écrit pas. Il redevient _actif_ pour I dès que I écrit un item et ne redevient _passif_ que quand il fait un _raz_.

### Établir un _contact direct_ entre A et B
Supposons que B veuille ouvrir un chat avec A mais ne l'a pas en _contact_, n'en connaît pas le nom / clé.

A peut avoir communiqué à B sa _phrase de contact_ qui ne peut être enregistrée par A que si elle est, non seulement unique, mais aussi _pas trop proche_ d'une phrase de contact déjà déclarée.

B peut écrire un chat à A à condition de fournir cette _phrase de contact_:
- l'avatar A a mis à disposition son nom complet `[nom, cle]` crypté par le PBKFD de la phrase de contact.
- muni de ces informations, B peut écrire un chat à A qui fait désormais partie de ses contacts (et réciproquement une fois le chat de B reçu par A).
- le chat comportant le `[nom cle]` de B, A est en mesure d'écrire sur ce chat, même s'il ignorait auparavant le nom complet de B.

## Documents `sponsorings`
P est le parrain-sponsor, F est le filleul-sponsorisé.

_data_:
- `id` : id de l'avatar sponsor.
- `ids` : hash de la phrase de parrainage, 
- `v`: 1..N.
- `dlv` : date limite de validité

- `st` : statut. _0: en attente réponse, 1: refusé, 2: accepté, 3: détruit / annulé_
- `pspk` : phrase de sponsoring cryptée par la clé K du sponsor.
- `bpspk` : PBKFD de la phrase de sponsoring cryptée par la clé K du sponsor.
- `dh`: date-heure du dernier changement d'état.
- `descr` : crypté par le PBKFD de la phrase de sponsoring:
  - `na` : `[nom, cle]` de P.
  - `cv` : `{ v, photo, info }` de P.
  - `naf` : `[nom, cle]` attribué au filleul.
  - `sp` : vrai si le filleul est lui-même sponsor.
  - `clet` : clé de sa tribu, si c'est un compte O
  - `quotas` : `[qc, q1, q2]` quotas attribués par le sponsor.
    - pour un compte A `[0, 1, 1]`. Un compte A n'a pas de qc et peut changer à loisir `[q1, q2]` qui sont des protections pour lui-même (et fixe le coût de l'abonnement).
- `ardx` : ardoise de bienvenue du sponsor / réponse du filleul cryptée par le PBKFD de la phrase de sponsoring

**Remarques**
- la `dlv` d'un sponsoring peut être prolongée (jamais rapprochée). Le sponsoring est purgé par le GC quotidien à cette date, en session et sur le serveur, les documents ayant atteint cette limite sont supprimés et ne sont pas traités.
- Le sponsor peut annuler son `sponsoring` avant acceptation, en cas de remord son statut passe à 3.

**Si le filleul refuse le sponsoring :** 
- Il écrit dans `ardx` la raison de son refus et met le statut du `sponsorings` à 1.

**Si le filleul ne fait rien à temps :** 
- `sponsorings` finit par être purgé par `dlv`.

**Si le filleul accepte le sponsoring :** 
- Le filleul crée son compte / avatar principal: `naf` donne l'id de son avatar et son nom. Pour un compte O, l'identifiant de la tribu pour le compte sont obtenu de `clet`.
- la `comptas` du filleul est créée et créditée des quotas attribués par le parrain pour un compte O et du minimum pour un compte A.
- pour un compte O la `tribus` est mise à jour (quotas attribués), le filleul est mis dans la liste des comptes `act` de `tribus`.
- un mot de remerciement est écrit par le filleul au parrain sur `ardx` **ET** ceci est dédoublé dans un chat filleul / sponsor créé à ce moment et comportant l'item de réponse et l'item du sponsor.
- le statut du `sponsoring` est 2.

## Documents `notes`
La clé de cryptage `cles` d'une note est selon le cas :
- *note personnelle d'un avatar A* : la clé K de l'avatar.
- *note d'un groupe G* : la clé du groupe G.

Le droit de mise à jour d'une note est contrôlé par le couple `im p` :
- `im` : pour une note de groupe, indique quel membre (son `im`) a l'exclusivité d'écriture et le droit de basculer la protection.
- `p` indique si le texte est protégé contre l'écriture ou non.

**Note temporaire et permanente**
Par défaut à sa création une note est _permanente_. Pour une note _temporaire_ :
- son `st` contient la _date limite de validité_ indiquant qu'elle sera automatiquement détruite à cette échéance.
- une note temporaire peut être prolongée, tout en restant temporaire.
- par convention le `st` d'une note permanente est égal à `99999999`. Une note temporaire peut être rendue permanente par :
  - l'avatar propriétaire pour une note personnelle.
  - un des animateurs du groupe pour une note de groupe.
- **une note temporaire ne peut pas avoir de fichiers attachés**.

_data_:
- `id` : id de l'avatar ou du groupe.
- `ids` : identifiant relatif à son avatar.
- `v` : 1..N.

- `st` :
  - `99999999` pour un _permanent_.
  - `aaaammjj` date limite de validité pour un _temporaire_.
- `im` : exclusivité dans un groupe. L'écriture et la gestion de la protection d'écriture sont restreintes au membre du groupe dont `im` est `ids`. 
- `p` : _0: pas protégé, 1: protégé en écriture_.
- `v2` : volume total des fichiers attachés.
- `mc` :
  - note personnelle : vecteur des index de mots clés.
  - note de groupe : map sérialisée,
    - _clé_ : `hgc` du compte l'auteur (1 pour les mots clés du groupe),
    - _valeur_ : vecteur des index des mots clés attribués par le membre.
- `txts` : crypté par la clé de la note.
  - `d` : date-heure de dernière modification du texte.
  - `l` : liste des auteurs pour une note de groupe.
  - `t` : texte gzippé ou non.
- `mfas` : map des fichiers attachés.
- `refs` : triplet `[id_court, ids, nomp]` crypté par la clé de la note, référence de sa  note _parent_.

**_Remarque :_** une note peut être explicitement supprimée. Afin de synchroniser cette forme particulière de mise à jour pendant un an (le délai maximal entre deux login), le document est conservé _zombi_. Il sera purgé avec son avatar / groupe.

**Mots clés `mc`:**
- Note personnelle : `mc` est un vecteur d'index de mots clés. Les index sont ceux du compte et de l'organisation.
- Note de groupe : `mc` est une map :
  - _clé_ : `hgc` du compte l'auteur (1 pour les mots clés du groupe). hgc est le hash du cryptage de l'id du groupe par la clé K du compte. Ainsi tous ls avatars du même compte partagent les mêmes mots clés. 
  - _valeur_ : vecteur d'index des mots clés. Les index sont ceux personnels du compte du membre, ceux du groupe, ceux de l'organisation.

**Map des fichiers attachés :**
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

## Documents `transferts`
_data_:
- `id` : id du groupe ou de l'avatar du note.
- `ids` : `idf` du fichier en cours de chargement.
- `dlv` : date-limite de validité pour nettoyer les uploads en échec sans les confondre avec un en cours.

## Documents `groupes`
Un groupe est caractérisé par :
- son entête : un document `groupes`.
- la liste de ses membres : des documents `membres` de sa sous-collection `membres`.

### Membres d'un groupe: identifications [id, im] nag ni 
- **`im / ids`**: un membre est créé en étant déclaré _contact_ du groupe par un animateur ce qui lui affecte un _indice membre_ de 1 à N, attribué dans l'ordre d'inscription et sans réattribution (sauf cas particulier). Pour un groupe `id`, un membre est identifié par le couple `id / ids` (où `ids` est l'indice membre `im`). Le premier membre est celui du créateur du groupe et a pour indice 1.
  - le statut de chaque membre d'index `im` est stocké dans `ast[im]`.
- **`nag`** : numéro d'avatar dans le groupe. Hash du cryptage par la clé du groupe de la clé de l'avatar.
  - un même avatar peut avoir plus d'une vie dans un groupe, y être actif, redevenir simple contact, y être à nouveau invité puis actif ... Afin qu'il conserve toujours le même indice au cours de ses _vies_ successives, on mémorise son `nag` dans la table `ast` du groupe.
  - c'est aussi utilisé pour empêcher d'avoir à un instant donné deux membres avec deux indices différents pour le même avatar.
- **`ni`** : numéro d'invitation. hash du cryptage par la clé du groupe de la clé _inversée_ de l'avatar invité. Ce numéro permet à un animateur d'annuler une invitation faite et pas encore acceptée ou refusée.
- `npgk` : numéro de participation à un groupe: hash du cryptage par la clé K du compte de `idg / idav`. Ce numéro est la clé du membre dans la map `mpgk` de `comptas` du compte.

### États _contact / actif / inconnu_
#### Inconnu
Un membre _inconnu_ est un membre qui a eu une existence et qui :
- soit a _disparu_. Le GC a détecté son absence.
- soit a fait l'objet d'une demande _d'oubli_ par le compte lui-même et dans certains cas par un animateur.
- il a un indice `im` : les flags associés à cet indice rappellent très succinctement que ce membre a eu une vie.
- il n'a plus de row `membres`, dans le groupe on ne connaît plus, ni son nom, ni l'id de son avatar, ni son identifiant `nag` dans le groupe.

#### Contact
Quand um membre est un _contact_:
- il a un indice `im` et des flags associés.
- il a un row `membres` identifié par `[idg, im]` qui va donner son nom, sa clé, sa carte de visite.
- il est connu dans `groupes` par son `nag` dans la table `anag` à l'indice `im`.
- son compte ne le connaît pas, son compte n'a pas le groupe dans sa liste de groupes `mpgk` (du moins au titre de cet avatar),
- la `dlv` de son row `membres` est `20991231` (non significative),
- sa disparition n'est constatée incidemment que quand un membre actif fait rafraîchir les cartes de visites des membres du groupe et découvre à cette occasion qu'il a disparu.
- un _contact_ peut avoir une _invitation_ en cours déclarée par un animateur (ou tous):
  - son avatar connaît cette invitation qui est stockée dans la map `invits` du row `avatars`.
  - une invitation n'a pas de date limite de validité.
  - une invitation peut être annulée par un animateur ou l'avatar invité lui-même.

#### Actif
Quand un membre est _actif_:
- son indice `im`, son row `membres` et son `nag` sont ceux qu'il avait quand il était _contact_.
- son compte le connaît, son compte a le groupe dans sa liste de groupes `mpgk`,
- le compte peut décider de redevenir _contact_, voire d'être _oublié_ du groupe (et devenir _inconnu_).
- un animateur peut supprimer tous les droits d'un membre _actif_ mais il reste _actif_ (bien que très _passif_ par la force des choses).
- son row `membres` est signé à chaque connexion du compte de son avatar: sa `dlv` lui garantit d'être considéré comme vivant un an après sa dernière connexion. Le GC détecte un année d'inactivité du compte et la disparition est connue en fin de journée.

Remarques:
- Un membre ne devient _actif_ que quand son compte a explicitement **validé une invitation** déclarée par un animateur (ou tous).
- Un membre _actif_ ne redevient _contact_ que quand lui-même l'a décidé.

### Table `anag` du groupe
Par convention si `anag[im]` vaut 0, c'est que l'indice im est _libre_.

Le `nag`, numéro d'avatar dans le groupe (hash du cryptage par la clé du groupe de la clé de l'avatar),
- est inscrit à la première déclaration de l'avatar comme contact.
- est effacé quand le membre est détecté disparu ou a été oublié.

Pour un indice `im` cette table donne:
- le `nag` du membre correspondant s'il est connu (_contact_ ou _actif_).
- 1 si le membre est _inconnu_.

**`im` attribués ou libres**
La règle générale est de ne pas libérer un `im` pour un futur autre membre quand un membre disparaît ou est oublié. Cet indice peut apparaître,
- dans la liste des auteurs d'une note, la ré-attribution pourrait porter à confusion sur l'auteur d'une note.
- dans la liste des participations à un groupe d'un compte (`mpgk`).

L'exception est _libérer_ un `im` à l'occasion d'un _oubli_ ou d'une _disparition_ quand **le membre n'a jamais été actif**: son `im` n'a pas pu être référencé ailleurs.

#### Table `flags`
Chaque membre d'indice `im` a des flags dans le groupe `flags[im]`

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

**Un membre _peut_ avoir plusieurs périodes d'activité**
- il a été créé comme _contact_ puis a été invité et son invitation validée: il est _actif_.
- il peut demander à redevenir _simple contact_ : il n'accède plus ni aux notes ni aux autres membres, n'est plus hébergeur et souhaite ne plus voir ce groupe _inutile_ apparaître dans sa liste des groupes.
- en tant que _contact_ il peut être ré-invité, sauf s'il s'est inscrit dans la liste noire des avatars à ne pas ré-inviter. Puis il peut valider son invitation et commencer ainsi une nouvelle période d'activité.
- les flags _historiques_ permettent ainsi de savoir, si le membre a un jour été actif et s'il a pu avoir accès à la liste des membres, a eu accès aux notes et a pu en écrire.

#### Disparition versus oubli
Dans les deux cas ses `flags` sont à 0.

**La _disparition_** correspond au fait que l'avatar du membre n'existe plus, soit à sa demande, soit par détection du GC. Par principe même l'avatar ne ré-apparaîtra plus dans le groupe:
- son row `membres` est purgé.
- son `nag` est mis à 1, ou 0 si son `im` a été libéré, n'ayant jamais été _actif_.

**Un _oubli_** est explicitement demandé:
- soit par le membre lui-même quand il est actif,
- soit par un animateur quand il est _contact_ et en particulier à l'occasion de l'annulation de son invitation.
- son row `membres` est purgé.
- son `nag` est mis à 1 ou 0 si son `im` a été libéré, n'ayant jamais été _actif_.

Après un _oubli_ si l'avatar est de nouveau inscrit comme _contact_, il récupère un nouvel indice #35 par exemple et un nouveau document `membres`, son historique de dates d'invitation, début et fin d'activité sont initialisées. C'est une nouvelle vie dans le groupe. Les notes écrites dans la vie antérieure mentionnent toujours l'ancien `im` #12 que rien ne permet de corréler à #35.

### Listes `lna / lnc`: _listes noires des avatars ne pas (ré) inviter_
liste les `nag` des avatars qui ne devront plus être invités / ré-invités. Elle est alimentée:
- par un animateur dans `lna`.
- par l'avatar lui-même dans `lnc`.

### Modes d'invitation
- _simple_ : dans ce mode (par défaut) un _contact_ du groupe peut-être invité par **UN** animateur (un seul suffit).
- _unanime_ : dans ce mode il faut que **TOUS** les animateurs aient validé l'invitation (le dernier ayant validé provoquant l'invitation).
- pour passer en mode _unanime_ il suffit qu'un seul animateur le demande.
- pour revenir au mode _simple_ depuis le mode _unanime_, il faut que **TOUS** les animateurs aient validé ce retour.

Une invitation est enregistrée dans la map `invits` de l'avatar invité:
- _clé_: `ni`, numéro d'invitation.
- _valeur_: `{nomg, cleg, im}` cryptée par la clé publique RSA de l'avatar.
  - `nomg`: nom du groupe,
  - `cleg`: clé du groupe,
  - `im`: indice du membre dans la table ast du groupe.

Sauf en mode _avion_, le serveur peut délivrer une _fiche d'invitation_ donnant pour une invitation donnée,
- la carte de visite du groupe,
- les cartes de visite et noms du ou des animateurs ayant lancé l'invitation.

### Hébergement par un membre _actif_
L'hébergement d'un groupe est noté par :
- `imh`: indice membre de l'avatar hébergeur. 
- `idhg` : id du **compte** hébergeur crypté par la clé du groupe.
- `dfh`: date de fin d'hébergement qui vaut 0 tant que le groupe est hébergé. Les notes ne peuvent plus être mises à jour _en croissance_ quand `dfh` existe.

**Prise d'hébergement:**
- en l'absence d'hébergeur, c'est possible pour,
  - tout animateur,
  - en l'absence d'animateur: tout actif ayant le droit d'écriture, puis tout actif ayant accès aux notes, puis tout actif.
- s'il y a déjà un hébergeur, seul un animateur peut se substituer à condition que le nombre de notes et le V2 actuels ne le mette pas en dépassement de son abonnement.

**Fin d'hébergement par l'hébergeur:**
- `dfh` est mise la date du jour + 90 jours.
- le nombre de notes et le volume V2 de `comptas` sont décrémentés de ceux du groupe.

**Actions du GC à `dfh`, destruction du groupe:**
- le groupe peut avoir des contacts et des actifs mais pas d'hébergeur.
- il met le `versions` du groupe en _zombi_ (`dlv` à la date du jour).
  - au fil des connexions et des synchronisations, ceci provoquera le retrait du groupe des maps `mpgk` des comptes qui le référencent (ce qui peut prendre jusqu'à un an).
  - les invitations _pendantes_ tomberont lorsqu'elles seront acceptées ou refusées par l'avatar invité.
  - ce document sera purgé par le GC dans 365 jours.
- les documents `groupe notes membres` sont purgés par le GC.
  
**Fin d'hébergement suit à détection par le GC de la disparition de l'avatar hébergeur:**
- c'est le fait que la `dlv` dans `membres` est dépassée qui signale que l'avatar a disparu. 
- du fait de l'ordre des signatures, la disparition de son compte a été détectée avant: il n'y a donc pas de problèmes, ni de volumes, ni de quotas (qui ont été rendus pour un compte O à sa tranche par un document `gcvols`).
- dans le document `groupes`:
  - `dfh` est mise la date du jour + 90 jours.
  - `imh idhg` sont mis à 0 / null

_data_:
- `id` : id du groupe.
- `v` :  1..N, version du groupe de ses notes et membres.
- `dfh` : date de fin d'hébergement.

- `idhg` : id du compte hébergeur crypté par la clé du groupe.
- `imh` : indice `im` du membre dont le compte est hébergeur.
- `msu` : mode _simple_ ou _unanime_.
  - `null` : mode simple.
  - `[ids]` : mode unanime : liste des indices des animateurs ayant voté pour le retour au mode simple. La liste peut être vide mais existe.
- `flags` : table des flags des membres (12 bits sur un entier).
- `anag` : table des nag des membres.
- `lna` : liste noire _animateurs_ des `nag` des avatars à ne pas inviter / ré-inviter.
- `lnc` : liste noire _comptes_ des `nag` des avatars à ne pas inviter / ré-inviter.
- `mcg` : liste des mots clés définis pour le groupe cryptée par la clé du groupe.
- `cvg` : carte de visite du groupe cryptée par la clé du groupe `{v, photo, info}`.

**Décompte des participations à des groupes d'un compte**
- quand un avatar a accepté une invitation, il devient _actif_ et a une nouvelle entrée dans la liste des participations aux groupes (`mpgk`) dans l'avatar principal de son compte.
- quand l'avatar décide de tomber dans l'oubli ou de redevenir simple contact, cette entrée est supprimée.
- le _nombre de participations aux groupes_ dans `compas.qv.ng` du compte est le nombre total de ces entrées dans `mpgk`.
- la disparition d'un groupe détectée en session (synchro ou connexion) par son `versions` devenu _zombi_, provoque la disparition de son ou ses entrées dans `mpgk` et la décroissance correspondante de `qv.ng` (nombre de participations aux groupes).

## Documents `membres`
Un document `membres` est créé à la déclaration d'un avatar comme _contact_. Le compte ne _signe_ pas à la connexion dans son document membres tant qu'il n'est pas _actif_, sa `dlv` reste non significative 20991231.
- sa `dlv` reste aussi à 0 en tant que contact ayant une invitation, le membre n'étant toujours pas _actif_.
- traces de la présence de l'avatar dans le groupe: `dac fac ...`.

Le document `membres` est détruit,
- par une opération d'oubli.
- par la destruction de son groupe lors de la résiliation du dernier membre actif.
- par le GC détectant par la `dlv` que l'avatar a disparu (il ne signe plus dans cette `dlv`) et q'il est le dernier membre _actif_ de son groupe.

_data_:
- `id` : id du groupe.
- `ids`: identifiant, indice `im` de membre relatif à son groupe.
- `v` : 
- `vcv` : version de la carte de visite du membre.
- `dlv` : date de dernière signature + 365 lors de la connexion du compte de l'avatar membre du groupe.
- `ddi` : date de l'invitation la plus récente.
- **dates de début de la première et fin de la dernière période...**
  - `dac fac` : d'activité
  - `dln fln` : d'accès en lecture aux notes.
  - `den fen` : d'accès en écriture aux notes.
  - `dam fam` : d'accès aux membres.
- `flagsiv` : flags de l'invitation en cours.
- `inv` : dernière invitation. Liste des indices des animateurs ayant validé l'invitation.
- `nag` : `[nom, cle]` : nom et clé de l'avatar crypté par la clé du groupe.
- `cva` : carte de visite du membre `{v, photo, info}` cryptée par la clé du membre.

#### Opérations

**Inscription comme contact**
- si son `nag` est en `lna` ou `lnc`, refus.
- recherche de l'indice `im` dans la table `anag` du groupe pour le `nag` de l'avatar.
- SI `im` n'existe pas,
  - c'est une première vie OU une nouvelle vie après oubli de la précédente.
  - un nouvel indice `im` lui est attribué en séquence s'il n'y en a pas de libre.
  - un row `membres` est créé.
- SI `im` existait, _l'inscription en contact_ est en échec (existe déjà).

**Invitation par un animateur**
- si son `nag` est en `lna` ou `lnc`, refus.
- choix des _droits_ et inscription dans `invits` de l'avatar.
- vote d'invitation (en mode _unanime_):
  - si tous les animateurs ont voté, inscription dans `invits` de l'avatar.
  - si le vote change les _droits_, les autres votes sont annulés.
- `ddi` est remplie.

**Annulation d'invitation par un animateur**
- effacement de l'entrée `ni` dans `invits` de l'avatar.

**Oubli par un animateur**
- pour un contact, pas invité: son slot est récupérable.
- le document `membres` est détruit.
  
**Refus d'invitation par le compte**
- le groupe peut avoir disparu depuis le lancement de l'invitation.
- 3 options possibles:
  - rester en contact.
  - m'oublier,
  - m'oublier et ne plus m'inviter.
- son item dans `invits` de son avatar est effacé.

**Acceptation d'invitation par le compte**
- le groupe peut avoir disparu depuis le lancement de l'invitation.
- dans l'avatar principal du compte un item est ajouté dans `mpgk`,
- dans `comptas` le compteur `qv.ng` est incrémenté.
- `dac fac ...` sont mises à jour.
- son item dans `invits` de son avatar est effacé.
- flags `AN AM`: accès aux notes, accès aux autres membres.

**Modification des droits par un animateur**
- flags `PA DM DN DE`

**Modification des accès membres / notes par le compte**
- flags `AN AM`: accès aux notes, accès aux autres membres.

**Demande d'oubli par un compte**
- 3 options:
  - rester en _contact_
  - m'oublier: Entrée dans `mpgk` du compte supprimée.
  - m'oublier et ne pas me ré-inviter.
- si le membre était le dernier _actif_, le groupe disparaît.
- la participation au groupe disparaît de `mpgk` du compte.

## Mots clés, principes et gestion
Les mots clés sont utilisés pour :
- filtrer / caractériser à l'affichage les **chats** accédés par un compte.
- filtrer / caractériser à l'affichage les **groupes (membres)** accédés par un compte.
- filtrer / caractériser à l'affichage les **notes**, personnels ou partagés avec un groupe.

La **définition** des mots-clés (avatar et groupe) est une map :
- _clé_ : indice du mot-clé de 1 à 255,
- _valeur_ : texte `catégorie/label du mot-clé`.

Affectés à un membre ou note, c'est un array de nombres de 1 à 255 (Uin8Array).

Les mots clés d'indice,
- 1-99 : sont ceux d'un compte.
- 100-199 : sont ceux d'un groupe.
- 200-255 : sont ceux définis en configuration (généraux dans l'application).

# Gestion des disparitions

## Signatures des avatars dans `versions` et `membres`
Les comptes sont censés avoir au maximum 365 jours entre 2 connexions faute de quoi ils sont considérés comme `disparus`.

10 jours après la disparition d'un compte, 
- ses avatars secondaires vont être détectés disparus par le GC.
- ses membres dans les groupes auxquels il participe vont être détectés disparus par le GC ce qui peut entraîner la disparition de groupes n'ayant plus d'autres membres _actifs_.

Les `dlv` (date limite de validité,
- dans `versions` pour les avatars et groupes, 
- dans `membres`.

Elles sont exprimées par un entier `aaaammjj`et signalent que ce jour-là, l'avatar -le cas échéant le compte- ou le membre est considéré comme _disparu_.

A chaque connexion d'un compte, son avatar principal _prolonge_ les `dlv` de :
- son propre avatar et ses avatars secondaires dans leur document `versions`.
- des membres (sur `membres`) des groupes connus par ses avatars dans `lgrk`. 

Les `dlv` sont également fixées:
- pour un avatar, à sa création dans son `versions`.
- pour un membre d'un groupe, à l'acceptation de son invitation.

> Les `dlv` ne sont pas _prolongées_ si le compte fait l'objet d'une procédure de blocage.

**Règles:** 
- les `dlv` sont gérées par _décade_ : une `dlv` est toujours définie ou reculée à un multiple de 10 jours. Ceci évite de multiplier des mises à jour en cas de connexions fréquentes et de faire des rapprochements entre avatars / groupes en fonction de leur dernière date-heure de connexion.
- si l'avatar principal a sa `dlv` repoussée le 10 mars par exemple, ses autres avatars et ses membres seront reculés au 20 mars.
- les avatars secondaires seront en conséquence _non disparus_ pendant 10 jours alors que leur compte ne sera plus connectable:
  - sur un chat la carte de visite d'un avatar secondaire apparaîtra pendant 10 jours alors que le compte de _l'autre_ a déjà été détecté disparu.
  - les groupes pourront faire apparaître des membres pendant 10 jours alors que leur compte a déjà été détecté disparu.

### Disparition d'un compte
#### Effectuée par le GC
Le GC détecte la disparition d'un compte sur dépassement de la `dlv` dans le `versions` de son avatar principal :
- il ne connaît pas la liste de ses avatars secondaires qu'il détectera _disparu_ 10 jours plus tard.
- pour un compte O, le GC n'a pas accès à l'`id` de sa tribu et ne peut donc pas mettre à jour son élément `ast[it]` dans son document `tribus`:
  - il écrit en conséquence un document `gcvols` avec les informations tirées du document `comptas` du compte disparu (`cletX` clé de la tribu cryptée par la clé K du comptable, `it` index du compte dans sa tribu).
  - la prochaine connexion du Comptable scanne les `gcvols` et effectue la suppression de l'entrée `it` dans la tribu dont l'id est extraite de `cletX`.

La disparition d'un compte est un _supplément_ d'action par rapport à la _disparition_ d'un avatar secondaire.

#### Auto-résiliation d'un compte
Elle suppose une auto-résiliation préalable de ses avatars secondaires, puis de son avatar principal:
- pour un compte O l'opération de mise à jour du document `tribus` est lancée, la session ayant connaissance de l'`id` de la tribu et de l'indice `it` de l'entrée du compte dans `act` du document  `tribus`. Le mécanisme `gcvols` n'a pas besoin d'être mis en œuvre.

### Disparition d'un avatar
#### Sur demande explicite
Dans la même transaction :
- pour un avatar secondaire, le document `comptas` est mis à jour par suppression de son entrée dans `mavk`.
- pour un avatar principal, l'opération de mise à jour du document `tribus` est lancée, 
  - l'entrée du compte dans `act` du document `tribus` est détruite,
  - le document `comptas` est purgé.
- le document `versions` de l'avatar a sa `dlv` fixée à aujourd'hui et devient _zombi et immuable_. Ceci provoquera un peu plus tard la purge par le GC de avatars `chats notes sponsorings transferts`.
- pour tous les chats de l'avatar:
  - le chat E, de _l'autre_, est mis à jour: son `st` passe à _disparu_, sa `cva` passe à null.
- pour tous les groupes dont l'avatar est membre:
  - purge de son document `membres`.
  - mise à jour dans son document `groupes` du statut `ast` à _disparu_.
  - si c'était l'hébergeur du groupe, mise à jour des données de fin d'hébergement.
  - si c'était le dernier membre _actif_ du groupe:
    - dans le document `versions` du groupe, `dlv` est fixée à aujourd'hui et devient _zombi / immuable_, ce qui permet à une synchronisation avec une autre session (ou une connexion) de détecter la disparition du groupe.

Dans les autres sessions ouvertes sur le même compte :
- si c'est l'avatar principal, la session, 
  - est notifiée par un changement du document `tribus` (la disparition de `comptas` n'est pas notifiée -c'est une purge-).
  - constate dans le document `tribus` la disparition de l'entrée du compte par comparaison avec l'état connu antérieurement,
  - **la session est close** SANS mise à jour de la base IDB (les connexions en mode _avion_ restent possibles). 
- si c'est un avatar secondaire, la session,
  - est notifiée d'un changement du document `comptas` et détecte la suppression d'un avatar.
  - en mémoire ce qui est relatif à cet avatar : si c'était l'avatar courant, l'avatar primaire devient courant.
  - supprime toutes les entrées de IDB relatives à l'avatar.

Lors des futures connexions sur le même compte:
- si le compte n'existe plus la connexion ne peut pas avoir lieu en _synchronisé ou incognito_.
- en mode _synchronisé_ les avatars et groupes qui étaient en IDB et ne sont plus existants sont purgés de IDB.

Dans les autres sessions ouvertes sur d'autres comptes, la synchronisation fait apparaître:
- par `tribus` : un compte qui disparaît dans `tribus` entre l'état courant et le nouvel état,
- par `chats` : un statut _disparu_ et une carte de visite absente,
- par `versions` _zombi_ des groupes : détection des groupes disparus, ce qui entraîne aussi la suppression des documents `membres` correspondant en mémoire (et en IDB).

#### Effectuée par le GC
Le GC détecte la disparition d'un avatar par la `dlv` dans `versions` inférieure ou égale à aujourd'hui, état _zombi_ : **le compte a déjà disparu**.

**Conséquences :**
- il reste des chats référençant cet avatar et dont le statut n'est pas encore marqué _disparu_ (mais le GC n'y a pas accès).
- il reste des groupes dont le statut du membre correspondant n'est pas _disparu_ et des documents `membres` référençant un avatar (principal) disparu.

### Disparition d'un membre
#### Résiliation ou auto résiliation d'un membre
C'est une opération _normale_:
- purge de son document `membres`.
- mise à jour dans son document `groupes` de son statut dans `ast` à _disparu_.
- si c'était l'hébergeur du groupe, mise à jour des données de fin d'hébergement (dont ses volumes dans `comptas`).
- si c'était le dernier membre _actif_ du groupe :
  - `dlv` est mise à aujourd'hui dans le document `versions` du groupe, devient _zombi / immuable_. Ceci permet aux autres sessions de détecter la disparition du groupe.
  - les autres membres en `sta` (3 4 5) auront leur item dans leur `mpgk` supprimé.

#### Effectuée par le GC
Détection par la `dlv` inférieure à aujourd'hui (état _zombi_) du `membres`.
- suppression du document `membres`,
- mise à jour de son état dans le document `groupes`,
- si c'est le dernier actif, le groupe est supprimé:
  - `dlv` de `versions` du groupe est mise à aujourd'hui (devient zombi / immuable).
  - les autres membres détecteront la disparition du groupe par synchro ou à la prochaine connexion: ça supprimera leurs entrées dans `mpgk` dans leurs `comptas`.

### Chat : détection de la disparition de l'avatar E
A la connexion d'une session les chats avec des avatars E,
- qui s'est auto-dissous est détectée (le chat I est `zombi` et à une dlv). 
- dont la disparition a été gérée par le GC, ne sont **pas** détectés.

Lors d'une synchronisation de son chat (I), l'auto suppression de l'avatar E dans une autre session est détectée par l'état _zombi_ du chat (I).

Lors de l'ouverture de la page listant les _chats_ d'un de ses avatars, 
- la session peut faire rafraîchir les cartes de visite ce qui liste _aussi_ les avatars E ayant disparu (détectés par absence de du row `avatars`).
- lors de l'écriture d'un chat, la session reçoit aussi ce même avis de disparition éventuelle de l'avatar E.
- le _contact_ E est marqué _disparu_ en mémoire (le chat I y est supprimé ainsi qu'en IDB).

> Un _contact_ peut donc apparaître _à tort_ en session alors que l'avatar / compte correspondant a été résilié du fait, a) qu'il est un des comptes de la tribu de la session, b) qu'un chat est ouvert avec lui. Toutefois l'ouverture du chat ou de la page des chats, rétablit cette distorsion temporelle provisoire.

# Opérations GC
### Singleton `checkpoint` (id 1)
_data_ :
- `id` : 1
- `v` : date-time de sa dernière mise à jour ou 0 s'il n'a jamais été écrit.

- `start` : date-heure de lancement du dernier GC.
- `duree` : durée de son exécution en ms.
- `nbTaches` : nombre de taches terminées avec succès sur 6.
- `log` : trace des exécutions des tâches: {}
  - `nom` : nom.
  - `retry` : numéro de retry.
  - `start` : date-heure de lancement.
  - `duree` : durée en ms.
  - `err` : si sortie en exception, son libellé.
  - `stats` : {} compteurs d'objets traités (selon la tâche).

### Gestion des documents `versions` _zombi_
Un document `versions` zombi a une `dlv` antérieure à aujourd'hui : il faut purger toutes les sous-collections correspondantes, plus le document `avatars` ou `groupes` correspondant.

Afin d'éviter que le GC ne tente d'effectue à nouveau cette opération les jours suivants alors que ces documents ont déjà été purgés, la `dlv` du documents versions est reculée d'un an, sans changer de version: le nettoyage des sous-collections ne s'effectue donc que pour les versions ayant une `dlv` passée mais pas passée de plus d'un an.

In fine les documents `versions` dont la `dlv` est passée de plus de 2 ans sont purgées.

### `GCHeb` : traitement des fins d'hébergement
L'opération récupère toutes les ids des documents `groupes` où `dfh` est inférieure ou égale au jour courant.

Une transaction par groupe :
- dans le document `versions` du groupe, la `dlv` est positionnée à aujord'hui (devient zombi).

### `GCGro` : Détection des groupes orphelins et suppression des membres
L'opération récupère toutes les `id / ids` des documents `membres` dont la `dlv` est inférieure ou égale au jour courant.

Une transaction par document `groupes`:
- mise à jour des statuts des membres perdus,
- suppression de ces documents `membres`,
- si le groupe est orphelin (n'a plus de membres actifs), suppression du groupe:
  - la `dlv` de son document `versions` est mise à aujourd'hui (il est zombi).

### `GCPag` : purge des avatars et des groupes
L'opération récupère toutes les `id` des documents `versions` dont la `dlv` est postérieure auj - 365 et antérieure ou égale à auj.

Dans l'ordre pour chaque `id`:
- par compte, une transaction de récupération du volume (si `comptas` existe encore, sinon c'est que ça a déjà été fait),
- purge de leurs sous-collections,
- purge de leur avatar / groupe,
- purge de leurs fichiers,
- HORS TRANSACTION forçage de la `dlv` du document `versions` à aujourd'hui moins 2 ans.

**Une transaction pour chaque compte :**
- son document `comptas` :
  - est lu pour récupérer `cletX it`;
  - un document `gcvols` est inséré avec ces données : son `id` est celle du compte.
  - les `gcvols` seront traités par la prochaine ouverture de session du comptable de l'espace ce qui supprimera l'entrée du compte dans tribu (et de facto libèrera des quotas).
  - le document `comptas` est purgé afin de ne pas récupérer le volume plus d'une fois.

### `GCFpu` : traitement des documents `fpurges`
L'opération récupère tous les items d'`id` de fichiers depuis `fpurges` et déclenche une purge sur le Storage.

Les documents `fpurges` sont purgés.

### `GCTra` : traitement des transferts abandonnés
L'opération récupère toutes les documents `transferts` dont les `dlv` sont antérieures ou égales à aujourd'hui.

Le fichier `id / idf` cité dedans est purgé du Storage des fichiers.

Les documents `transferts` sont purgés.

### `GCDlv` : purge des versions / sponsorings obsolètes
L'opération récupère tous les documents `versions` de `dlv` antérieures à jour j - 2 ans. Ces documents sont purgés: ils ont fini d'être utile pour synchronisation.

L'opération récupère tous les documents `chats` et `notes` de `dlv` antérieures à jour j - 1 an. Ces documents sont purgés: ils ont fini d'être utile pour synchronisation.

L'opération récupère toutes les documents `sponsorings` dont les `dlv` sont antérieures ou égales à aujourd'hui. Ces documents sont purgés.

## Lancement global quotidien
Le traitement enchaîne, en asynchronisme de la requête l'ayant lancé : 
- `GCHeb GCGro GCPag GCFpu GCTra GCDlv`

En cas d'exception de l'un deux, une seule relance est faite après une attente d'une heure.

> Remarque : le traitement du lendemain est en lui-même une reprise.

> Pour chaque opération, il y a N transactions, une par document à traiter, ce qui constitue un _checkpoint_ naturel fin.

# Discordances temporelles des données

### Discordances par détection tardives de disparitions
Un chat I / E peut référencer un avatar E alors que celui-ci a été détecté disparu par le GC.
- le GC ne peut pas connaître la liste des chats dans lesquels un avatar disparu est impliqué.
- l'avatar I ne détectera la disparition de E que lorsqu'en session il ouvrira la liste des chats et plus précisément fera rafraîchir la liste des CV.

Un avatar principal peut réfrencer dans la liste de ses participations aux groupes, un groupe détecté disparu par dispation / résiliation de son dernier membre actif.
- le GC n'ayant pas connaissance de l'avatar principal du compte d'un memebre ne peut pas mettre à jour,
  - ni la liste des participations aux groupes des membres,
  - leurs invitations en cours.
- la disparition d'un groupe n'est détectée qu'à l'ouverture de la prochaine session (ou plus tôt par synchro, quand une session est active).

### Discordances temporaires en session sur les décomptes de chats et groupes
L'existence d'un chat décompté pour un compte est marqué,
- par l'existence de rows chats attachés à un de ses avatars,
- par le décompte `ng.nc` dans comptas du compte.

Les deux informations sont mises à jour sous contrôle transactionnel: les données persistentes sont toujours cohérentes entre elle.

En session, l'ordre dans lequel parvienent les mises à jour sont aléatoires:
- mise à jour chats avant mise à jour comptas ou l'inverse.
- pendant un certain temps le nombre de chats décomptés peut différer de celui détenu dans comptas.
- la situation se stabilise d'elle-même par synchronisation.
- il est difficile d'arriver à mettre en évidence cette discordance temporaire de décompte.

Le nombre de participations aux groupes est de même détenu dans deux rows: 
- avatar principal du compte, map mpgk,
- comptas du compte qv.ng.

La situation de-même se stabilise d'elle-même et n'est pas évidence à observer.

Le trosième cas similaire est celui de l'existence d'une note supprimée (_zombi_) encore temporairement décomptée dans `comptas.qv.nn`.

**Conclusions**
- les décomptes dans `comptas.qv` et `avatars` ou `chats` ne seront pas réalignés: le décompte des coûts reste cohérent.
- dans la logique de gestion on tient compte des rows `avatars` et `chats` sans se préoccuper d'une possible discordance passagère des décomptes avec `comptas.qv`.
- la détection tardive éventuelles de disparitions est assumée:
  - avoir des groupes ou des chats décomptés à tort n'a pas d'impact de calcul des coûts puisque _l'abonnement_ se fait sur des quotas maximum, pas sur le nombre effectif de groupes et chats.
  - on assume que quelques chats _passifs_ de I ne soient pas supprimés alors que E a disparu parce que ceci ne peut être détecté qu'à l'ouverture de vue des chats. 

# Index

## SQL
`sqlite/schema.sql` donne les ordres SQL de création des tables et des index associés.

Rien de particulier : sont indexées les colonnes requérant un filtrage ou un accès direct par la valeur de la colonne.

## Firestore
`firestore.index.json` donne le schéma des index: le désagrément est que pour tous les attributs il faut indiquer s'il y a ou non un index et de quel type, y compris pour ceux pour lesquels il n'y en a pas.

**Les règles génériques** suivantes ont été appliquées:

_data_ n'est jamais indexé.

Il n'y a pas _d'index composite_, mais en fait dans l'esprit les attributs `id_v` et `id_vcv` calculés (pour Firestore seulement) avant création / mise à jour d'un document, sont des pseudo index composites mais simplement déclarés comme index:
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

# IndexedDB dans les session UI

Un certain nombre de documents sont stockés en session UI dans la base locale IndexedDB et utilisés en modes _avion_ et _synchronisé_.
- compte: 'id' vaut '1'. Une seule instance du document `comptas`, celle de la session.
- tribus: 'id',
- comptas: 'id',
- avatars: 'id',
- chats: '[id+ids]',
- sponsorings: '[id+ids]',
- groupes: 'id',
- membres: '[id+ids]',
- notes: '[id+ids]',
- tickets: '[id+ids]'.

La clé _simple_ `id` en string est cryptée par la clé K du compte et encodée en base 64 URL.

Les deux termes de clés `id` et `ids` sont chacune en string crypté par la clé K du compte et encodée en base 64 URL.

Le format _row_ d'échange est un objet de la forme `{ _nom, id, ..., _data_ }`.

En IDB les _rows_ sont sérialisés et cryptés par la clé K du compte.

Il y a donc une stricte identité entre les documents extraits de SQL / Firestore et leurs états stockés en IDB

_**Remarque**_: en session UI, d'autres documents figurent aussi en IndexedDB pour,
- la gestion des fichiers locaux: `avnote fetat fdata loctxt locfic locdata`
- la mémorisation de l'état de synchronisation de la session: `avgrversions sessionsync`.

# Décomptes des coûts et crédits

On compte **sur le serveur le nombre de lectures et d'écritures** effectués dans chaque opération et c'est remonté à la session où:
- on décompte dans la session le nombre de lectures et écritures depuis le début de la session (ou son reset volontaire après enregistrement au serveur du delta par rapport à l'enregistrement précédent).
- la session envoie les incréments des 4 compteurs de consommation par l'opération `EnregConso` au bout de M minutes sans envoi (avec un minimum de R2 rows).

On compte **en session les downloads / uploads soumis au Storage**.

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
- `dh` : date-heure courante.
- `qv` : quotas et volumes du dernier calcul `{ qc, q1, q2, nn, nc, ng, v2 }`.
  - Quand on _prolonge_ l'état actuel pendant un certain temps AVANT d'appliquer de nouvelles valeurs, il faut pouvoir disposer de celles-ci.
- `vd` : [0..3] - vecteurs détaillés pour M M-1 M-2 M-3.
- `mm` : [0..18] - coût abonnement + consommation pour le mois M et les 17 mois antérieurs (si 0 pour un mois, le compte n'était pas créé).
- `aboma` : somme des coûts d'abonnement des mois antérieurs au mois courant depuis la création du compte.
- `consoma` : somme des coûts de consommation des mois antérieurs au mois courant depuis la création du compte.

Le vecteur `vd[0]` et le montant `mm[0]` vont évoluer tant que mois courant n'est pas terminé. Pour les mois antérieurs `vd[i]` et `mm[i]` sont immuables.

### Dynamique
Un objet `compteur` est construit,
- soit depuis la sérialisation de son dernier état,
- soit depuis `null` pour un nouveau compte.
- la construction recalcule tout l'objet: il était sérialisé à un instant `dh`, il est recalculé être à jour à l'instant t.
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
  
### Méthodes et getter publiques: TODO
- `cadeau (c)` : déclaration d'un "cadeau" de dépannage de la part du Comptable ou d'un sponsor pour permettre au compte de surmonter un excès transitoire de consommation.
- `razma ()` : lors de la transition O <-> A il faut remettre à 0 les coûts d'abonnement / consommation passés (en pratique ceux des mois antérieurs).
- `get totalAbo ()` retourne le coût d'abonnement en additionnant ceux du mois courant et des mois antérieurs.
- `get totalConso ()` retourne le coût de consommation en additionnant ceux du mois courant et des mois antérieurs.
- `get totalAboConso ()` retourne la somme des coûts d'abonnement et de consommation en additionnant ceux du mois courant et des mois antérieurs.
- `get consoj ()` retourne la moyenne _journalière_ de la consommation des mois M et M-1. Pour M le nombre de jours est le jour du mois, pour M-1 c'est le nombre de jours du mois.
- `get consoj4M ()` retourne la moyenne _journalière_ de la consommation sur le mois en cours et les 3 précédents. Si le nombre de jours d'existence est inférieur à 30, retourne `consoj`.
- `get qcj ()` retourne le quota `qc` ramené à la journée pour comparaison avec `consoj`.

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

La classe `Compteurs` est hébergée par `api.mjs` (module commun à UI et serveur).

Le Comptable peut afficher le `compteurs` de n'importe quel compte A ou O.

Les sponsors d'une tranche ne peuvent faire afficher les `compteurs` _que_ des comptes de leur tranche.

A la connexion d'un compte O, trois compteurs statistiques sont remontés de `compteurs` dans sa tribu:
- `v1`: le volume V1 effectivement utilisé,
- `v2`: le volume V2 effectivement utilisé,
- `cj`: la consommation moyenne journalière (`consoj`).

Les compteurs ne sont remontés que si l'un des trois s'écarte de plus de 10% de la valeur connue par la tribu.

### Classe `Credits`
La propriété `credits` n'existe dans `comptas` que pour un compte A:
- elle est cryptée par la clé K du compte qui est seul à y accéder.
- toutefois elle est cryptée par la clé publique du compte juste après l'opération de passage d'un compte O à A.

**Propriétés:**
- `total` : total des crédits encaissés.
- `tickets`: liste des tickets générés par le compte.

### Documents `tickets`
Voir ci-avant la section correspondante.

### Passage d'un compte A à O
- le compte a demandé ou accepté, de passer O. Son accord est traduit par une _phrase d'accord_ dont le hash du PBKFD est inscrit dans `oko` de comptas. Cette phrase est transmise au Comptable ou au sponsor par un chat.
- Le Comptable ou un sponsor désigne le compte dans ses contacts et cite cette phrase. Si elle est conforme, ça lance une opération qui:
  - inscrit le compte dans une tribu,
  - effectue une remise à zéro dans compteurs du compte du total abonnement et consommation des mois antérieurs (`razma()`):
    - l'historique des compteurs et de leurs valorisations reste intact.
    - les montants du mois courant et des 17 mois antérieurs sont inchangés,
    - MAIS les deux compteurs `aboma` et `consoma` qui servent à établir les dépassements de coûts sont remis à zéro: en conséquence le compte va bénéficier d'un mois (au moins) de consommation _d'avance_
  - efface `oko`.

### Rendre _autonome_ un compte O
C'est une opération du Comptable et/ou d'un sponsor selon la configuration de l'espace, qui n'a besoin de l'accord du compte (dans `oko` comme ci-dessus) que si la configuration de l'espace l'a rendu obligatoire.
- il est retiré de sa tribu.
- comme dans le cas ci-dessus, remise à zéro des compteurs total abonnement et consommation des mois antérieurs. Un _découvert_ est déclaré pour laisser le temps au compte d'enregistrer son premier crédit.
- `oko` est effacé.
- un objet `ticket` est créé avec:
  - un `total` nul.
  - une liste `tickets` vide.

### Sponsoring d'un compte O
Rien de particulier : `compteurs` est initialisé, sa consommation est nulle, de facto ceci lui donne une _avance_ de consommation moyenne d'au moins un mois.

### Sponsoring d'un compte A
`compteurs` est initialisé, sa consommation est nulle mais il bénéficie d'un _découvert_ minimal pour lui laisser le temps d'enregistrer son premier crédit.

Un objet `ticket` est créé dans `comptas` avec:
- un `total` de 2 centimes.
- une liste `tickets` vide.
- l'objet est crypté par la clé K du compte à l'acceptation du sponsoring.
