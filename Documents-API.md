# Données persistantes sur le serveur

Présentation en Collections / Documents :
- tous les attributs **indexés** sont indiqués:
  - `id, ids` : les identifiants
  - `v` : numéro de version d'un document (entier croissant), `vcv` : pour la version de la carte de visite.
  - `dlv` : date limite de validité
  - `dfh` : date de fin d'hébergement
  - _attributs de statut_ permettant de filtrer les collections:  `iv ivc dh/dhb idt/idtb hps1 hpc`.
- les attributs _data_ (non indexés) contiennent des données sérialisées opaques.

## Structure générale

    Collections                   Attributs: ** indexé sur collection group

    /Collection `singletons`
      Document `checkpoint`
      Document `notif`

    /Collection `gcvols`        
      Documents                   id

    /Collection `tribus`
      Documents                   id v iv

    /Collection `tribu2s`
      Documents                   id v iv

    /Collection `comptas`
      Documents                   id v iv hps1

    /Collection `versions`
      Documents                   id v iv dlv

    /Collection `avatars`
      Document                    id v iv vcv ivc hpc
        /Collection `secrets`
          Documents               id ids v iv
        /Collection `transferts`
          Document `transfert`    id ids **dlv
        /Collection `sponsorings`
          Document `sponsoring`   id **ids v iv **dlv
        /Collection `chats`
          Documents               id ids v iv vcv ivc

    /Collection `groupes`
      Document `groupe`           id v iv dfh
        /Collection `membres`
          Document membre         id ids v iv vcv ivc **dlv        
        /Collection `secrets`
          Document `secret`       id ids v iv         
        /Collection `transferts`  
          Document `transfert`    id ids **dlv

    Collection  Attrs non indexés     Attrs indexés     Attrs collectionGroup
    singletons  _data_

    La _clé primaire_ est id:
    gcvols      id _data_
    tribus      id v _data_           iv
    tribu2s     id v _data_           iv
    comptas     id v _data_           iv hps1
    versions    id v _data_           iv dlv dfh
    avatars     id v vcv hpc _data_   iv ivc
    groupes     id v _data_           iv

    La _clé primaire_ est id+ids
    secrets     id ids v _data_       iv
    transferts  id ids                                  dlv
    sponsorings id v _data_           iv                dlv ids
    chats       id ids v _data_       iv                
    membres     id ids v _data_       iv                dlv

Tous les documents, ont un attribut _data_ (mais toujours {} pour `transferts`), qui porte les informations sérialisées du document.
- les attributs externalisés hors de _data_ le sont parce qu'ils sont utilisés comme identifiants et / ou champs indexés.
- les attributs `iv ivc` ne sont pas explicitement présents dans _data_ étant calculables depuis `id, v, vcv`.

#### Documents d'une collection majeure
Les documents _majeurs_ sont ceux des collections `tribus tribu2s comptas avatars groupes`.
- leur identifiant porte le nom `id` et est un entier.
- chaque document porte une version `v`:
  - `tribus` et `comptas` ont leur propre version gérée dans le document lui-même.
  - `avatars` et `groupes` ont leurs versions gérées par le document `versions` portant leur id (voir ci-dessous)

#### Gestion des versions dans `versions`
- un document `avatar` d'id `ida` et les documents de ses sous collections `chats secrets transferts sponsorings` ont une version prise en séquence continue fixée dans le document `versions` ayant pour id `ida`.
- idem pour un document `groupe` et ses sous-collections `membres secrets transferts`.
- toute mise à jour provoque l'incrémentation du numéro de version dans `versions` et l'inscription de cette valeur comme version du document mis à jour.

Un document `version` gère aussi :
- `dlv` : la signature de vie de son avatar ou groupe.
- en _data_ pour un groupe :
  - `v1 q1` : volume et quota dee textes des secrets du groupe.
  - `v2 q2` : volume et quota dee fichiers des secrets du groupe.

#### Documents d'une sous-collection d'un document majeur :
- `chats secrets transferts sponsorings` d'un **avatar**.
- `membres secrets transferts` d'un **groupe**.

Leur identifiant relatif à leur document majeur est `ids`.

#### Documents _synchronisables_ en session
Chaque session détient localement le sous-ensemble des données de la portée bien délimitée qui la concerne: en mode synchronisé les documents sont stockés en base IndexedDB (IDB) avec le même contenu qu'en base centrale.

L'état en session est conservé à niveau en _s'abonnant_ à un certain nombre de documents et de sous-collections:
- (1) les documents `avatars comptas` de l'id du compte
- (2) le document `tribus` de l'id de la tribu du compte - connu par (1)
- (3) les documents `avatars` des avatars du compte - listé par (1)
- (4) les documents `groupes` des groupes dont les avatars sont membres - listés par (3)
- (5) les sous-collections `secrets chats sponsorings` des avatars - listés par (3)
- (6) les sous-collections `membres secrets` des groupes - listés par (4)
- (7) le singleton `notif`.
- pour le comptable, abonnement à **toutes** les tribus.

Au cours d'une session au fil des synchronisations, la portée va donc évoluer depuis celle déterminée à la connexion:
- des documents ou collections de documents nouveaux sont ajoutés à IDB (et en mémoire de la session),
- des documents ou collections sont à supprimer de IDB (et de la mémoire de la session).

Une session a une liste d'ids abonnées :
- l'id de son compte : quand un document `compta` change il est transmis à la session.
- les ids de ses `groupes` et `avatars` : quand un document `version` ayant une de ces ids change, il est transmis à la session. La tâche de synchronisation de la session va chercher, par une transaction pour chaque document majeur, le document majeur et ses sous documents ayant des versions postérieures à celles détenues en session.
- sa `tribu tribu2` actuelle (qui peut donc changer) pour un compte normal.
- implicitement le singleton `notif`.
- **pour le Comptable** : en plus, 
  - implicitement toutes les `tribu`,
  - ponctuellement une `tribu2` _courante_.

**Remarque :** en session ceci conduit au respect de l'intégrité transactionnelle pour chaque objet majeur mais pas entre objets majeurs dont les mises à jour pourraient être répercutées dans un ordre différent de celui opéré par le serveur.
- en **SQL** les notifications pourraient être regroupées par transaction et transmises dans l'ordre.
- en **FireStore** ce n'est pas possible : la session pose un écouteur sur des objets `compta` et `version` individuellement, l'ordre ne peut pas être garanti entre objets majeurs.

#### Id-version : `iv`
Un `iv` est constitué sur 15 chiffres :
- en tête des 9 derniers chiffres de l'`id` du document majeur.
- suivi sur 6 chiffres de `v`, numéro de la version.

Un `iv` permet de filtrer un document précis selon sa version. Il sert:
- **à gérer une mémoire cache dans le serveur des documents majeurs** récemment accédés : si la version actuelle est déjà en cache, le document _n'est pas_ chargé (seul l'index est accédé pour vérification).
- **à remettre à jour en session _incrémentalement_ UN document majeur ET ses sous-documents** en ne chargeant à la connexion QUE les documents plus récents que la version de leur document majeur détenue dans la session.

Comme un `iv` ne comporte pas une `id` complète mais seulement ses 9 derniers chiffres, de temps en temps (mais très rarement) le filtrage _peut_ retourner des _faux positifs_ qu'il faut retirer du résultat en vérifiant leur `id` dans le document.

#### `dlv` et `dfh` : **date limite de validité** et **date de fin d'hébergement** 
Ces dates sont données en jour `aaaammjj` (UTC).

**Sur _avatars_ :**
- **jour auquel l'avatar sera officiellement considéré comme _disparu_.**
- les `dlv` permettent au GC de récupérer tous les _disparus_.

**Sur _membres_ :**
- sur _membres_ : les `dlv` sont indexées et permet au GC de savoir que le membre a disparu SANS avoir à chager le document.
- l'index est _groupe de collection_ afin de s'appliquer aux membres de tous les groupes.

**Sur _groupes_ :**
- jour de purge d'un `groupe` (qui est _zombi_ depuis un an).
- les groupes dont la `dlv` est antérieure au jour J sont considérés comme _disparu_. Leur document reste encore mais réduit a minima, sans _data_, est immuable et sera, un an plus tard, techniquement purgés.

**Sur _transferts_:**
- **jour auquel il est considéré que le transfert tenté a définitivement échoué**.
- permet au GC de détecter les transferts en échec et de nettoyer le Storage.
- l'index est _groupe de collection_ afin de s'appliquer aux fichiers des groupes comme des avatars.

**Sur _sponsorings_:**
- jour à partir duquel le sponsoring n'est plus applicable ni pertinent à conserver. Les sessions suppriment automatiquement à la connexion les sponsorings ayant dépassé leur `dlv` (idem pour les synchronisations).

**Sur _groupes_ `dfh` :**
- la **date de fin d'hébergement** sur un groupe permet au GC de mettre ce groupe en _zombi_ (disparu logiquement): sa `dlv` dans son `version` est mise à la date du jour + 365.

#### Index de groupes de collection: `dlv ids`
- `dlv` : **date limite de validité**:
  - sur _transferts_: permet au GC de détecter _tous_ les transferts définitivement échoués et de nettoyer le Storage.
- `ids` : hash de la phrase de parrainage sur `sponsorings` afin de rendre un sponsorings accessible par index sans connaître le sponsor.

#### Cache locale des `comptas versions avatars groupes tribus` dans une instance d'un serveur
- les `comptas` sont utilisées à chaque mise à jour de secrets.
- les `versions` sont utilisées à chaque mise à jour des avatars, de ses chats, secrets, sponsorings.
- les `avatars groupes tribus` sont également souvent accédés.

**Les conserver en cache** par leur `id` est une bonne solution : mais en _FireStore_ il peut y avoir plusieurs instances s'exécutant en parallèle. Il faut en conséquence interroger la base pour savoir s'il y a une version postérieure et ne pas la charger si ce n'est pas le cas en utilisant un filtrage par `iv`. Ce filtrage se faisant sur l'index n'est pas décompté comme une lecture de document quand le document n'a pas été trouvé parce que de version déjà connue.

La mémoire cache est gérée par LRU (tous types de documents confondus)

## Généralités
Les clés AES et les PBKFD sont des bytes de longueur 32.

Un entier sur 53 bits est intègre en Javascript (15 chiffres décimaux). Il peut être issu de 6 bytes aléatoires.

Le hash (_integer_) d'un bytes est un entier intègre en Javascript.

Le hash (_integer_) d'un string est un entier intègre en Javascript.

Les date-heures sont exprimées en milli-secondes depuis le 1/1/1970, un entier intègre en Javascript(ce serait d'ailleurs aussi le cas pour une date-heure en micro-seconde).

Les dates sont exprimées en `aaaammjj` sur un entier (géré par la class `AMJ`). En base ce sont des dates UTC, elles peuvent s'afficher en date _locale_.

#### Nom complet d'un avatar / groupe / tribu
Le **nom complet** d'un avatar / groupe / tribu est un couple `[nom, cle]`
- `nom` : nom lisible et signifiant, entre 6 et 20 caractères. Le nom `Comptable` est réservé.
- `cle` : 32 bytes aléatoires. Clé de cryptage. Le premier byte donne le _type_ de l'id (qu'on retrouve comme dernier chiffre de l'id) :
  - 0 : compte / avatar principal.
  - 1 : avatar secondaire.
  - 2 : groupe,
  - 3 : tribu.
- A l'écran le nom est affiché sous la forme `nom@xyzt` (sauf `Comptable`) ou `xyzt` sont les 4 premiers chiffres de l'id.

**Dans les noms,** les caractères `< > : " / \ | ? *` et ceux dont le code est inférieur à 32 (donc de 0 à 31) sont interdits afin de permettre d'utiliser le nom complet comme nom de fichier.

#### Les ids
**Singletons**
- il y a 2 singletons d'id respectives `checkpoint` `notif`.

**Ids des documents majeurs `avatar` (sauf comptable), `groupe`, `tribu`:**
- le hash (_integer_) de la clé est un entier SAFE en Javascript : il est divisé par 10.
- un dernier chiffre (0 à 3) donne le _type_ de l'objet identifié.

**Compte de nom réservé `Comptable`**
- son id est Number.MAX_SAFE_INTEGER (2^53 - 1 = `9007199254740990`) mais ramené à la dizaine inférieure.
- sa clé est également fixe : [0, 255, 255 ...].
- son nom est réservé et non attribuable par les autres avatars.
- pas de carte de visite : le comptable dispose de la notification globale s'il veut donner des précisions sur lui-même.

**Sous-documents**
- l'id d'un `sponsoring`, `ids` est le hash de la phrase de reconnaissance.
- l'id d'un `chat` est un numéro `ids` construit depuis la clé de _l'autre_ avatar du chat.
- l'id d'un `secret` est un numéro `ids` aléatoire relatif à celui de son avatar ou groupe.
- l'id d'un `membre` est `ids` un indice croissant depuis 1 relatif à son groupe.

#### Les `dlv` : sur avatars et membres, date de dernière signature + 1 an
A la connexion d'un compte, si sa `dlv` précédente a plus de 10 jours, il signe en inscrivant une `dlv` dans le document `version` de ses avatars:
- par la date du jour pour son principal (son compte) + 1 an.
- par une date `d2` de 10 jours postérieure: pour ses avatars secondaires.

La date `d2` est aussi celle mise dans chaque `membre` d'un groupe correspondant aux avatars du compte.

### Authentification
- Les opérations liées aux créations de compte ne sont pas authentifiées, elles vont justement enregistrer leur authentification.  
- Les opérations de tests de type _ping_ ne le sont pas non plus.  
- Toutes les autres opérations le sont.

Une `sessionId` est tirée au sort par la session juste avant tentative de connexion : elle est supprimée à la déconnexion.

> **En mode SQL**, un WebSocket est ouvert et identifié par le `sessionId` qu'on retrouve sur les messages afin de s'assurer qu'un échange entre session et serveur ne concerne pas une session antérieure fermée.

Toute opération porte un `token` portant lui-même le `sessionId`:
- si le serveur retrouve dans la mémoire cache l'enregistrement de la session `sessionId` :
  - **il en obtient l'id du compte**,
  - il prolonge la `ttl` de cette session dans cette cache.
- si le serveur ne trouve pas la `sessionId`, 
  - soit il y en bien une mais ... dans une autre instance, 
  - soit c'est une déconnexion pour dépassement de `ttl` de cette session.
  - Dans les deux cas l'authentification va être refaite depuis le `token` fourni et y fixer l'id du compte.

**`token`** : sérialisation encodée en base 64 de :
- `sessionId`
- `shax` : SHA de X (PBKFD de la phrase secrète complète).
- `hps1` : hash du PBKFD de la ligne 1 de la phrase secrète.

Le serveur recherche l'id du compte par `hps1` (index de `comptas`)
- vérifie que le SHA de `shax` est bien celui enregistré dans `compta` en `shay`.
- inscrit en mémoire `sessionId` avec l'id du compte et un `ttl`.

## Collection `singletons`

### Document `checkpoint`
Attribut opaque _data_ : contient les informations de point de reprise du GC.

### Document `notif`
Attribut opaque _data_ : sérialisé, non crypté

Ce texte est synchronisé par toutes les sessions connectées.

## Collection `gcvols`
Il y a autant de documents que de comptes ayant été détectés disparus et dont les quotas n'ont pas encore été rendus à leur tribu par une session du Comptable. C'est un avis de disparition d'un compte que seul le comptable peut décrypter et traiter pour mette à jour sa tribu.

**Document:** - `id` : entier aléatoire
- `id` : entier pseudo aléatoire, hash de `nctkc`.
- _data_ : 
  - compteurs récupérés du document `compta` du compte. `f1, f2, v1, v2`
  - `nctkc` : `[nom, cle]` de la tribu qui doit récupérer les quotas **crypté par la clé K du comptable**.
  - `nat` : `[nom, rnd]` du compte disparu crypté par la clé t de sa tribu (`cle` ci-dessus).

## Collection `tribus` et `tribu2s`
Cette collection liste les tribus déclarées sur le réseau et les fiches comptables des comptes rattachés à la tribu.

Le comptable est le seul qui,
- récupère à la connexion l'ensemble des tribus,
- est abonné aux modifications des tribus (pas seulement de la sienne).

Les données d'une tribu sont réparties sur 2 documents :
- `tribus` : une entête de synthèse,
- `tribu2s`: la liste des comptes de la tribu.

Le Comptable a en effet besoin :
- de toutes les synthèses des tribus,
- du détail ponctuellement pour une tribu courante de travail.

Toute modification d'un `tribu2s` implique une mise à jour du `tribus` de même id (l'inverse n'est pas vrai). `tribus` est le gestionnaire de version des deux documents et une mise à jour d'un `tribu2s` lui confère la même version que celle du `tribus` associé (et mis à jour).

**Documents:** - `id` : numéro de la tribu  
Chaque document donne un descriptif de la tribu et la liste de ses parrains.
- `id` : numéro de la tribu 
- `v`
- `iv`
- _data_ : données de la tribu, synthèse (`tribus`) ou liste des comptes (`tribu2s`).

### Collection `comptas`

**Documents:**  - `id` : numéro du compte
Un document par compte rattaché à sa tribu portant :
- ses compteurs d'occupation d'espace
- le descriptif de son alerte quand il y en a une.

**Attributs:**
- `id` : numéro du compte
- `v`
- `iv`
- `hps1` : le hash du PBKFD de la ligne 1 de la phrase secrète du compte.
- _data_ : il contient en particulier `shay`, le SHA du SHA de X (PBKFD de la phrase secrète).

### Collection `versions`

**Documents:**  - `id` : numéro d'un avatar ou d'un groupe

**Attributs:**
- `id` : id d'avatar / groupe.
- `v` : plus haute version attribuée aux documents de l'avatar / groupe.
- `dlv` : signature de vie + 365 (aaaammjj).
- `iv`
- _data_ :
  - `v1 q1 v2 q2`: pour un groupe

## Collection `avatars`
Cette collection a un document par avatar principal ou secondaire.

**Documents** - `id` : id de l'avatar
Deux variantes, l'avatar principal ayant des données supplémentaires. 

**Attributs:**
- `id` : id de l'avatar.
- `v` : version.
- `iv`
- `vcv` : version de la carte de visite.
- `ivc` : calculée comme iv (9 + 6 chiffres) mais la version est celle de la mise à jour de la carte de visite.
- `hpc` : hash de la phrase de contact.
- _data_ : sérialisation des autres attributs. **Un avatar principal / compte est reconnaissable par son `id`** et comporte des données supplémentaires dans _data_.

### Sous-collection `secrets`
Elle compte un document par secret.

**Documents** : `ids`, numéro de secret dans son avatar.
- `id` : id de son avatar.
- `ids` : identifiant relatif à son avatar.
- `v` : sa version.
- `iv`
- _data_ : données sérialisées du secret.

Un secret est _supprimé_ quand sa _data_ est absente / null. La suppression est donc synchronisable par changement de la version `v` : il est purgé lors de la purge de son avatar.

### Sous-collection `transferts`
Elle comporte un document par transfert de fichier en cours pour un secret de l'avatar.

L'upload d'un fichier est long. Ce document permet de gérer un commit à 2 phases:
- phase 1 : début de l'upload : insertion d'un document identifiant le fichier commençant à être uploadé,
- phase 2 : validation du fichier par le commit du document `secret` : suppression du document.

**Documents:** - `ids` identifiant du fichier relatif à l'avatar de son secret.

**Attributs:**
- `id` : id de son avatar.
- `ids` : id du fichier relatif à l'avatar de son secret
- `dlv` : date de validité permettant de purger les fichiers uploadés (ou pas d'ailleurs) sur échec du commit entre les phases 1 et 2. Ceci permet de faire la différence entre un upload en cours et un vieil upload manqué.

### Sous-collection `sponsorings`
Un rendez-vous est identifié par une _phrase de reconnaissance_ convenue entre les deux avatars A et B pour le sponsoring de B par A.

Il y a un document par sponsoring en cours.

**Documents:** - `ids`, hash de la phrase secrète de reconnaissance

**Attributs:**
- `id` : id de l'avatar ayant fixé le rendez-vous.
- `ids` : hash de la phrase secrète de reconnaissance
- `v`
- `iv`
- `dlv` : purge automatique des sponsorings.
- _data_ : données du rendez-vous.

### Sous-collection `chats`
Elle comporte un document par chat ouvert avec un avatar (externe, pas un avatar du compte)

**Documents:** - `ids`, numéro du chat pour l'avatar

**Attributs**
- `id` : id de son avatar.
- `ids` : numéro du chat pour l'avatar - hash de la clé de l'autre avatar le partageant.
- `v`
- `vcv`
- `iv`
- `ivc`
- _data_ : contenu du chat crypté par la clé de l'avatar. Contient le `[nom, clé]` de l'émetteur.

#### Avatars _externes_ E connaissant l'avatar A, chat entre avatars
- les membres des groupes dont A est membre.
- les comptes de sa tribu,
- tout avatar C ayant un chat avec A.

Le Comptable est un _faux_ avatar externe puisqu'il est connu par une constante: de ce fait il peut faire l'objet d'un chat, voire d'être contacté pour invitation à un groupe.

Tout _avatar externe_ E connaissant A peut lui écrire un chat qui est dédoublé avec une copie pour A et une copie pour E.
- si A ne détruit pas un chat, il va disposer d'une liste de _contacts_ qui lui ont écrit.
- en supprimant le dernier chat avec E émis par E, A perd toute connaissance de E si c'était la seule raison pour laquelle il connaissait E.

## Collection `groupes`
Cette collections comporte un document par groupe existant.

**Documents :** - `id` : id du groupe
- `id` : id du groupe,
- `v`
- `iv`
- `dfh` : date de fin d'hébergement. Le groupe s'auto détruit à cette date là (sauf si un compte a repris l'hébergement, `dfh` étant alors remise à 0)
- _data_ : données du groupe. Absent / null en état _zombi_ (les sous-collections ont déjà été purgées ou sont en cours de purge).

### Sous-collection `membres`
Elle comporte un document membre par membre.

**Documents:** 
- `id` : id du groupe.
- `ids`: indice de membre relatif à son groupe.
- `dlv` : date de dernière signature lors de la connexion du compte de l'avatar membre du groupe.
- `v`
- `iv`
- _data_ : données du membre. Contient en particulier [photo, info], la carte de visite de l'avatar.

### Sous-collection `secrets`
Elle compte un document par secret.

**Documents:**
- `id` : id du groupe.
- `ids` : identifiant relatif à son groupe.
- `v` : sa version.
- `iv`
- _data_ : données sérialisées du secret.

Un secret est _supprimé_ quand sa _data_ est absente / null. La suppression est donc synchronisable par changement de la version `v` : il sera purgé lors de la purge de son groupe.

### Sous-collection `transferts`
Elle comporte un document par transfert de fichier en cours pour un secret du groupe.

L'upload d'un fichier est long. Ce document permet de gérer un commit à 2 phases:
- phase 1 : début de l'upload : insertion d'un document identifiant le fichier commençant à être uploadé,
- phase 2 : validation du fichier par le commit du document `secret` : suppression du document.

**Documents:** 
- `ids` identifiant du fichier relatif au groupe de son secret.
- `id` : id de son groupe.
- `ids` : id du fichier relatif au groupe de son secret
- `dlv` : date de validité permettant de purger les fichiers uploadés (ou pas d'ailleurs) sur échec du commit entre les phases 1 et 2. Ceci permet de faire la différence entre un upload en cours et un vieil upload manqué.

# Détail des documents
## Sous-objets _génériques_
Ce sont des _structures_ qu'on peut trouver dans les _data_ de plusieurs documents,
- sérialisées,
- cryptées par une clé qui dépend du contexte où se trouve la structure.

Ce sont :
- `blocage` : décrit une procédure de blocage. Se trouve dans :
  - `tribu` : cryptée par la clé de la tribu, décrit la procédure de blocage en cours au niveau de la tribu.
  - `tribu2` : cryptée par la clé de la tribu, décrit la procédure de blocage en cours au niveau du compte.
- `notif` : décrit une _notification_, un avis plus ou moins important destiné soit à tous les comptes, soir à tous ceux d'une tribu, soit à un compte particulier.
  - _data_ du singleton `notif` : cryptée par la clé bien connue constante du Comptable, signale une notification globale pour tous les comptes.
  - _tribu_ : cryptée par la clé de la tribu:
    - `notifco` : notification issue du Comptable.
    - `notifsp` : notification issue d'un des sponsors de la tribu.
  - _tribu2_ : cryptée par la clé de la tribu:
    - `notifco` : notification issue du Comptable.
    - `notifsp` : notification issue d'un des sponsors de la tribu.

### `blocage`
- `sp`: id si créé / gérée par un sponsor (0 pour un blocage _tribu_). Lorsque le comptable a pris le contrôle sur une procédure de blocage de compte, un sponsor ne peut plus la modifier / remplacer / supprimer.
- `jib` : jour initial de la procédure de blocage sous la forme `aaaammjj`.
- `nja njl` : nb de jours passés en niveau _alerte_, et _lecture seule_.
- `dh` : date-heure de dernière modification (informative).

Il y a trois niveaux :
- **1-alerte** : simple annonce qu'une procédure est engagée, **mais** les comptes ne _signant_ plus leurs connexions, le compte est déjà engagée dans une procédure qui conduira, si rien n'est fait, à sa disparition un an après le début de la procédure.
- **2-lecture seule** : le compte ne peut plus que,
  -_lire_ toutes ses données,
  - _chatter_ avec le Comptable et les sponsors de sa tribu.
- **3-bloquée** : le compte ne peut plus que,
  - _lire_ sa propre comptabilité, les informations de blocage et les notifications. 
  - _chatter_ avec le Comptable et les sponsors de sa tribu.

Le _niveau_ d'un blocage dépend du jour d'observation. On en déduit aussi:
- le nombre de jours restant avant d'atteindre la date de fin du niveau et des niveaux suivants.
- le nombre de jours avant disparition du compte (dernier jour du niveau _bloqué_).

### `notif`
- `txt` : texte court de la notification.
- `dh` : date-heure d'inscription de la notification.
- `id` : id de l'auteur (0 c'est le comptable).
- `g` : `false`: normale, `true`: importante.

Une notification peut être remplacée par une autre plus récente et peut-être effacée.

Il existe donc 5 notifications pour un compte:
- générale,
- pour tous les comptes d'une tribu émise par le Comptable,
- pour tous les comptes d'une tribu émise par un sponsor,
- pour un seul compte désigné, émise par le Comptable,
- pour un seul compte désigné, émise par un sponsor de sa tribu.

Une autre forme de notification est gérée : le taux maximum d'utilisation du volume V1 ou V2 par rapport à son quota.

Le document `compta` a une date-heure de lecture qui indique _quand_ il a lu les notifications.

## Document `gcvol`
- `id` : entier pseudo aléatoire, hash de `nctkc`.
_data_:
- `nctkc` : `[nom, cle]` de la tribu qui doit récupérer les quotas **crypté par la clé K du comptable**.
- `nat`: `[nom, clé]` de l'avatar principal du compte crypté par la clé de la tribu.
- `q1, q2, v1, v2`: quotas et volumes à rendre à la tribu, récupérés sur le `compta` du compte détecté disparu.

Le comptable obtient l'id et la clé de la tribu en décryptant `nctkc`, ce qui lui permet d'obtenir le `[nom, clé]` de l'avatar disparu : il peut ainsi mettre à jour la `tribu`, supprimer le compte de la liste des comptes de la tribus dans `tribu2` et mettre à jour les compteurs de quotas déjà affectés au niveau de la tribu.

## Document `tribu`
Données de synthèse d'une tribu.

_data_:
- `id` : numéro de la tribu
- `v` : sa version

- `nctkc` : `[nom, rnd]` de la tribu crypté par la clé K du comptable.
- `infok` : commentaire privé du comptable crypté par la clé K du comptable.
- `notifco` : notification du comptable à la tribu (cryptée par la clé de la tribu).
- `notifsp` : notification d'un sponsor à la tribu (cryptée par la clé de la tribu).
- `blocaget` : blocage du niveau crypté par la clé de la tribu.
- `cpt` : sérialisation non cryptée des compteurs suivants:
  - `a1 a2` : sommes des quotas attribués aux comptes de la tribu.
  - `q1 q2` : quotas actuels de la tribu.
  - `nbc` : nombre de comptes.
  - `nbsp` : nombre de sponsors.
  - `cbl` : nombre de comptes ayant un blocage.
  - `nco[0, 1]` : nombre de comptes ayant une notification du comptable, par gravité.
  - `nsp[0, 1]` : nombre de comptes ayant une notification d'un sponsor, par gravité.

## Document `tribu2`
Liste des comptes d'une tribu.

_data_:
- `id` : numéro de la tribu
- `v` : sa version

- `mbtr` : map des membres de la tribu:
  - _clé_ : hash de la clé `rnd` du compte.
  - _valeur_ :
    - `na` : `[nom, rnd]` du compte crypté par la clé de la tribu.
    - `sp` : si `true` / présent, c'est un sponsor.
    - `q1 q2` : quotas attribués de volumes V1 et V2 (redondance dans l'attribut `compteurs` de `compta`)
    - `blocage` : blocage de niveau compte, crypté par la clé de la tribu.
    - `gco gsp` : gravités des `notifco` et `notifsp`.
    - `notifco` : notification du comptable au compte (cryptée par la clé de la tribu).
    - `notifsp` : notification d'un sponsor au compte (cryptée par la clé de la tribu).
    - `cv` : `{v, photo, info}`, carte de visite du compte cryptée par _sa_ clé (le `rnd` ci-dessus).

Le Comptable a la clé des tribus, c'est lui qui les créé et les supprime : elles sont cryptées dans `nctkc` de `compta`.

Tous les comptes connaissent le `nom, rnd` de leur tribu (donc leur id) : ce couple a été crypté par la clé CV du compte,
- soit à sa création,
- soit lors du changement de tribu d'un compte par le Comptable, ce dernier ayant obtenu du compte demandeur son `[nom, rnd]` dans le chat de demande de changement de tribu.

Un compte peut accéder à la liste des comptes de sa tribu. 

L'ajout / retrait de la qualité de `sponsor` n'est effectué que par le comptable.

### Synchronisations et versions
Les versions de tribu et tribu2 leur sont spécifiques et servent juste en synchronisation à garantir la progression sans retour dans le passé.

A la connexion d'une session, le chargement n'utilise pas la version (_comme si_ celle détenue en en IDB était 0).

**Synchronisation d'un compte standard**
- abonné à **une** id de tribu, reçoit les mises à jour de tribu et tribu2.

**Synchronisation du comptable**
- abonné à l'id de la tribu "primitive", en reçoit les mises à jour de `tribu` et `tribu2`.
- abonné par défaut à toutes les mises à jour de tribu (toutes).
- à la déclaration d'une tribu _courante_, début du processus sur _la_ page de détail de cette tribu,
  - reçoit le `tribu2` (sans considération de version),
  - devient abonné à cette `tribu2` (donc en plus de primitive),
  - à la fin du processus de travail sur cette tribu courante, sé désabonne.

## Document `compta`
_data_:
- `id` : numéro du compte
- `v` : version
- `hps1` : hash du PBKFD de la ligne 1 de la phrase secrète du compte : sert d'accès au row compta à la connexion au compte.
- `shay` : SHA du SHA de X (PBKFD de la phrase secrète). Permet de vérifier la détention de la phrase secrète complète.
- `kx` : clé K du compte, cryptée par le PBKFD de la phrase secrète courante.
- `mavk` : map des avatars du compte cryptée par la clé K du compte. 
  - _clé_ : id de l'avatar.
  - _valeur_ : `[nom clé]` : son nom complet.
- `nctk` : `[nom, clé]` de sa tribu crypté par la clé K du compte.
- `nctkc` : `[nom, clé]` de sa tribu crypté par la clé K **du Comptable**: 
- `napt`: `[nom, clé]` de l'avatar principal du compte crypté par la clé de la tribu.
- `compteurs`: compteurs sérialisés (non cryptés).
- `dhvu` : date-heure de dernière vue des notifications par le titulaire du compte, cryptée par la clé du compte.

**Remarques :**  
- Le document est mis à jour à minima à chaque mise à jour d'un secret.
- La version de `compta` lui est spécifique (ce n'est pas la version de l'avatar principal du compte).
- `napt nctkc` sont transmis par le GC dans un document `gcvols` pour notifier au Comptable, quel est le compte détecté disparu et sa tribu.

## Document `version`
_data_ :
- `id` : id d'avatar / groupe
- `v` : plus haute version attribuée aux documents de l'avatar / groupe.
- `dlv` : date de fin de vie pour un avatar, date de purge pour un groupe.
- `iv`
- `{v1 q1 v2 q2}`: pour un groupe, volumes et quotas des secrets.

## Document `avatar`

**_data_  : données n'existant que pour un avatar principal**
- `mck` : map des mots-clés du compte cryptée par la clé K -la clé est leur code 1-99- ("code": nom@catégorie).
- `memok` : mémo personnel du compte.

**_data_ : données disponibles pour les avatars primaires et secondaires**
- `id`, 
- `v`,
- `vcv` : version de la carte de visite afin qu'une opération puisse détecter (sans lire le document) si la carte de visite est plus récente que celle qu'il connaît.

- `pub` : clé publique RSA
- `privk`: clé privée RSA cryptée par la clé K.
- `cva` : carte de visite cryptée par la clé CV de l'avatar `{v, photo, info}`.
- `lgrk` : map :
  - _clé_ : `ni`, numéro d'invitation obtenue sur une invitation.
  - _valeur_ : cryptée par la clé K du compte de `[nomg, clég, im]` reçu sur une invitation.
  - une entrée est effacée par la résiliation du membre au groupe (ce qui l'empêche de continuer à utiliser la clé du groupe).
  - pour une invitation en attente _valeur_ est cryptée par la clé publique RSA de l'avatar
- `pck` : PBKFD de la phrase de contact cryptée par la clé K.
- `hpc` : hash de la phrase de contact.
- `napc` : `[nom, clé]` de l'avatar cryptée par le PBKFD de la phrase de contact.

**Invitation à un groupe**  
L'invitant connaît le `[nom, clé]` de l'invité qui est déjà dans la liste des membres en tant que pressenti. L'invitation consiste à :
- inscrire un terme `[nomg, cleg]` dans `lgrk` de son avatar (ce qui donne la clé du groupe à l'invité, donc accès à la carte de visite du groupe) en le cryptant par la clé publique RSA l'invité,
- inscrire un `chat` de la part de l'invitant (ou ajouter un mot dans son chat).
- en cas de refus, l'invité donnera les raisons dans ce même `chat`.
- l'acceptation par l'avatar transcode l'entrée de `lgrk` par la clé K.

### Cartes de visites
**Mise à jour: avatar et tribu**
- la création / mise à jour s'opère dans son `avatar` et dans `tribu2` (dans son élément).

**Mises à jour des cartes de visite des membres**
- la première inscription se fait à l'ajout de l'avatar comme _contact_ du groupe.
- en session, lorsque la page listant les membres d'un groupe est ouverte, elle envoie une requête au serveur donnant la liste des couples `[id, v]` des ids des membres et de leur version de carte de visite détenue dans le document `membre`.
- pour chacune ayant une version postérieure, le serveur la met à jour dans `membre`.
- ceci permet de voir en session des cartes de visite toujours à jour et d'éviter d'effectuer une opération longue à chaque mise à jour des cartes de visite par un avatar pour tous les groupes dont il est membre.

**Mise à jour dans les chats**
- à la mise à jour ou suppression d'un chat, les cartes de visites des deux côtés sont rafraîchies (si nécessaire).
- en session au début d'un processus de consultation des chats, la session fait rafraîchir incrémentalement les cartes de visite qui ne sont pas à jour dans les chats: un chat ayant `vcv` en index, la nécessité de mise à jour se détecte sur une lecture d'index sans lire le document correspondant.

## Document `chat`
Un chat est éternel, une fois créé il ne disparaît qu'à la disparition des avatars en cause.

Un chat est une ardoise commune à deux avatars I et E:
- vis à vis d'une session :
  - I est l'avatar _interne_,
  - E est un avatar _externe_ connu comme _contact_.
- pour être écrite par I :
  - I doit connaître le `[nom, cle]` de E : membre du même groupe, compte de la tribu, chat avec un autre avatar du compte, ou obtenu en ayant fourni la phrase de contact de E.
  - le chat est dédoublé, une fois sur I et une fois sur E.
- un chat a une clé de cryptage `cc` propre générée à sa création (première écriture):
  - cryptée par la clé K,
  - ou cryptée par la clé publique de l'avatar I (par exemple) : dans ce cas la première écriture de contenu de I remplacera cette clé par celle cryptée par K.
- un chat a un comportement d'ardoise : chaque écriture de l'un _écrase_ la totalité du contenu pour les deux. Un numéro séquentiel détecte les écritures croisées risquant d'ignorer la maj de l'un par celle de l'autre.
- si I essaie d'écrire à E et que E a disparu, le statut `st` de I vaut 1 pour informer la session.

L'id d'un chat est le couple `id, ids`. Du côté de A:
- `id`: id de A,
- `ids`: hash du cryptage de `idA/idB` par le `rnd` de A.

_data_:
- `id`
- `ids` : identifiant du chat relativement à son avatar, hash du cryptage de `idA/idB` par le `rnd` de A.
- `v`
- `vcv` : version de la carte de visite

- `st` : statut:
  - 0 : le chat est vivant des 2 côtés
  - 1 : _l'autre_ a été détecté disparu : 
- `mc` : mots clés attribués par l'avatar au chat
- `cva` : `{v, photo, info}` carte de visite de _l'autre_ au moment de la création / dernière mise à jour du chat, cryptée par la clé CV de _l'autre_.
- `cc` : clé `cc` du chat cryptée par la clé K du compte de I ou par la clé publique de I.
- `seq` : numéro de séquence de changement du texte.
- `contc` : contenu crypté par la clé `cc` du chat.
  - `na` : `[nom, cle]` de _l'autre_.
  - `dh`  : date-heure de dernière mise à jour.
  - `txt` : texte du chat.

### _Contact direct_ entre A et B
Supposons que B veuille ouvrir un chat avec A mais n'en connaît pas le nom / clé.

A peut avoir communiqué à B sa _phrase de contact_ qui ne peut être enregistrée par A que si elle est, non seulement unique, mais aussi _pas trop proche_ d'une phrase de contact déjà déposée.

B peut écrire un chat à A à condition de fournir cette _phrase de contact_:
- l'avatar A a mis à disposition son nom complet `[nom, clé]` crypté par le PBKFD de la phrase de contact.
- muni de ces informations, B peut écrire un chat à A.
- le chat comportant le `[nom clé]` de B, A est également en mesure d'écrire sur ce chat, même s'il ignorait avant le nom complet de B.

## Document `sponsoring`
P est le parrain-sponsor, F est le filleul-sponsorisé.

_data_
- `id` : id de l'avatar sponsor.
- `ids` : hash de la phrase de parrainage, 
- `v`
- `dlv` : date limite de validité

- `st` : statut. 0: en attente réponse, 1: refusé, 2: accepté, 3: détruit / annulé
- `pspk` : phrase de sponsoring cryptée par la clé K du sponsor.
- `bpspk` : PBKFD de la phrase de sponsoring cryptée par la clé K du sponsor.
- `descr` : crypté par le PBKFD de la phrase de sponsoring
  - `na` : `[nom, cle]` de P.
  - `cv` : `{ v, photo, info }` de P.
  - `naf` : `[nom, cle]` attribué au filleul.
  - `nct` : `[nom, cle]` de sa tribu.
  - `sp` : vrai si le filleul est lui-même sponsor (créé par le Comptable, le seul qui peut le faire).
  - `quotas` : `[v1, v2]` quotas attribués par le parrain.
- `ardx` : ardoise de bienvenue du sponsor / réponse du filleul cryptée par le PBKFD de la phrase de sponsoring

**Remarques**
- la `dlv` d'un sponsoring peut être prolongée. Le sponsoring est purgé par le GC quotidien après cette date, en session et sur le serveur, les rows ayant dépassé cette limite sont supprimés et ne sont pas traités.
- Le sponsor peut annuler son `sponsoring` avant acceptation, en cas de remord son statut passe à 3.

**Si le filleul refuse le sponsoring :** 
- Il écrit dans `ard` au parrain expliquant sa raison et met le statut du `sponsoring` à 1. 

**Si le filleul ne fait rien à temps :** 
- `sponsoring` finit par être purgé par `dlv`. 

**Si le filleul accepte le parrainage :** 
- Le filleul crée son compte / avatar principal: `naf` donne l'id de son avatar et son nom. Les infos de tribu pour le compte sont obtenu de `nct`.
- la `compta` du filleul est créée et créditée des quotas attribués par le parrain.
- la `tribu` est mise à jour (quotas attribués), le filleul est mis dans la liste des comptes dans `tribu2`.
- un mot de remerciement est écrit par le filleul au parrain sur `ard` **ET** ceci est dédoublé dans un chat filleul / sponsor.
- le statut du `sponsoring` est 2.

## Document `secret`
Un secret est _supprimé_ quand sa _data_ est absente / null. La suppression est donc synchronisable par changement de la version `v` : il sera purgé lors de la purge de son avatar ou groupe.

La clé de cryptage du secret `cles` est selon le cas :
- *secret personnel d'un avatar A* : la clé K de l'avatar.
- *secret d'un groupe G* : la clé du groupe G.

Le droit de mise à jour d'un secret est contrôlé par le couple `x p` :
- `x` : pour un secret de groupe, indique quel membre (son `im`) a l'exclusivité d'écriture et le droit de basculer la protection.
- `p` indique si le texte est protégé contre l'écriture ou non.

**Secret temporaire et permanent**
Par défaut à sa création un secret est _permanent_. Pour un secret _temporaire_ :
- son `st` contient la _date limite de validité_ indiquant qu'il sera automatiquement détruit à cette échéance.
- un secret temporaire peut être prolongé, tout en restant temporaire.
- par convention le `st` d'un secret permanent est égal à `99999999`. Un temporaire peut être rendu permanent par :
  - l'avatar propriétaire pour un secret personnel.
  - un des animateurs pour un secret de groupe.
- **un secret temporaire ne peut pas avoir de fichiers attachés**.

_data_:
- `id` : id de l'avatar ou du groupe.
- `ids` : identifiant relatif à son avatar.
- `v` : sa version.

- `st` :
  - `99999999` pour un _permanent_.
  - `aaaammjj` date limite de validité pour un _temporaire_.
- `im` : exclusivité dans un groupe. L'écriture et la gestion de la protection d'écriture sont restreintes au membre du groupe dont `im` est `ids`. 
- `p` : 0: pas protégé, 1: protégé en écriture.
- `v1` : volume du texte
- `v2` : volume total des fichiers attachés.
- `mc` :
  - secret personnel : vecteur des index de mots clés.
  - secret de groupe : map sérialisée,
    - _clé_ : `im` de l'auteur (0 pour les mots clés du groupe),
    - _valeur_ : vecteur des index des mots clés attribués par le membre.
- `txts` : crypté par la clé du secret.
  - `d` : date-heure de dernière modification du texte.
  - `l` : liste des auteurs pour un secret de groupe.
  - `t` : texte gzippé ou non.
- `mfas` : map des fichiers attachés.
- `refs` : couple `[id, ids]` crypté par la clé du secret référençant un autre secret _référence de voisinage_ qui par principe, lui, n'aura pas de `refs`.

**_Remarque :_** un secret peut être explicitement supprimé. Afin de synchroniser cette forme particulière de mise à jour pendant un an (le délai maximal entre deux login), le document est conservé _zombi_ avec un _data_ absente / null. Il sera purgé avec son avatar / groupe.

**Mots clés `mc`:**
- Secret personnel : `mc` est un vecteur d'index de mots clés. Les index sont ceux du compte et de l'organisation.
- Secret de groupe : `mc` est une map :
  - _clé_ : `im`, indice du membre dans le groupe. Par convention 0 désigne le groupe lui-même.
  - _valeur_ : vecteur d'index de secrets. Les index sont ceux personnels du membre, ceux du groupe, ceux de l'organisation.

**Map des fichiers attachés :**
- _clé_ `idf`: numéro aléatoire généré à la création. L'identifiant _externe_ est `id` du groupe / avatar, `idf`
- _valeur_ : `{ nom, info, dh, type, gz, lg, sha }` crypté par la clé S du secret.

**Identifiant de stockage :** `id/idf`
- `id` : id de l'avatar / groupe auquel le secret appartient.
- `idf` : identifiant aléatoire du fichier.

En imaginant un stockage sur file-system,
- l'application a son répertoire racine (par exemple son URL),
- il y un répertoire par avatar / groupe ayant des secrets ayant des fichiers attachés,
- pour chacun, un fichier par fichier attaché.

_Un nouveau fichier attaché_ est stocké sur support externe **avant** d'être enregistré dans son document `secret`. Ceci est noté dans un document `transfert` de la sous-collection `transferts` des transferts en cours. 
Les fichiers créés par anticipation et non validés dans un `secret` comme ceux qui n'y ont pas été supprimés après validation du secret, peuvent être retrouvés par un GC qui peut s'exécuter en lisant seulement les _clés_ de la map `mafs`.

La purge d'un avatar / groupe s'accompagne de la suppression de son _répertoire_. 

La suppression d'un secret s'accompagne de la suppressions de N fichiers dans un seul _répertoire_.

## Document `transfert`
- `id` : id du groupe ou de l'avatar du secret.
- `ids` : id relative à son secret (en fait à son avatar / groupe)
- `dlv` : date-limite de validité pour nettoyer les uploads en échec sans les confondre avec un en cours.

## Document `groupe`
Un groupe est caractérisé par :
- son entête : un document `groupe`.
- la liste de ses membres : des documents `membre` de sa sous-collection `membres`.
- la liste de ses secrets : des documents `secret` de sa sous-collection `secrets`.

L'hébergement d'un groupe est noté par :
- `imh`: indice membre de l'avatar hébergeur. 
- `idhg` : id du **compte** hébergeur crypté par la clé du groupe.
- `dfh`: date de fin d'hébergement qui vaut 0 tant que le groupe est hébergé.

Le compte peut mettre fin à son hébergement:
- `dfh` indique le jour de la fin d'hébergement. Les secrets ne peuvent plus être mis à jour _en croissance_ quand `dfh` existe. 
- à `dfh`, 
  - le GC plonge le groupe en état _zombi_, _data_ et `dfh` sont absents / 0.
  - `dlv`  dans le `version` du groupe est mis à la date du jour + 365.
  - les secrets et membres sont purgés.
  - le groupe est _ignoré_ en session, comme s'il n'existait plus. Il est retiré au fil des connexions et des synchronisations des maps `lgrk invits` des avatars qui le référencent (ce qui peut prendre jusqu'à un an).
  - le document `groupe` sera effectivement détruit par le GC à `dlv`.

**Les membres d'un groupe** reçoivent lors de leur création (quand ils sont inscrits en _contact_) un indice membre `ids` :
- cet indice est attribué en séquence : le premier membre est celui du créateur du groupe a pour indice 1.
- le statut de chaque membre d'index `ids` est stocké dans `ast[ids]`

**Modes d'invitation**
- _simple_ : dans ce mode (par défaut) un _contact_ du groupe peut-être invité par un animateur (un suffit).
- _unanime_ : dans ce mode il faut que _tous_ les animateurs aient validé l'invitation (le dernier ayant validé provoque la validation).
- pour passer en mode _unanime_ il suffit qu'un seul animateur le demande.
- pour revenir au mode _simple_ depuis le mode _unanime_, il faut que tous les animateurs aient validé ce retour.

**Oubli et disparition**
- la _disparition_ correspond au fait que l'avatar du membre n'existe plus, soit par non connexion au cours des 365 jours qui précèdent, soit par auto-résiliation de l'avatar.
- _l'oubli_ a été explicitement demandé, soit par le membre lui-même soit par un animateur. 
- dans les deux cas le membre est _effacé_, ni son nom, ni son identifiant, ni sa carte de visite ne sont accessibles.
- un membre _oublié / disparu_ n'apparaît plus que par #99 où 99 était son indice. Ainsi dans un secret, la liste des auteurs peut faire apparaître des membres existants (connus avec nom et carte de visite) ou des membres _disparus / oubliés_ avec juste leur indice.

_data_:
- `id` : id du groupe.
- `v` : version, du groupe, ses secrets, ses membres. 
- `iv`
- `dfh` : date de fin d'hébergement.

- `idhg` : id du compte hébergeur crypté par la clé du groupe.
- `imh` : indice `im` du membre dont le compte est hébergeur.
- `msu` : mode _simple_ ou _unanime_.
  - `null` : mode simple.
  - `[ids]` : mode unanime : liste des indices des animateurs ayant voté pour le retour au mode simple. La liste peut être vide mais existe.
- `pe` : 0-en écriture, 1-protégé contre la mise à jour, création, suppression de secrets.
- `ast` : array des statuts des membres (dès qu'ils ont été inscrits en _contact_) :
  - 10: contact, 
  - 20,21,22: invité en tant que lecteur / auteur / animateur, 
  - 30,31,32: **actif** (invitation acceptée) en tant que lecteur / auteur / animateur, 
  - 40: invitation refusée,
  - 50: résilié / suspendu, 
  - 0: disparu / oublié.
- `mcg` : liste des mots clés définis pour le groupe cryptée par la clé du groupe cryptée par la clé du groupe.
- `cvg` : carte de visite du groupe cryptée par la clé du groupe `{v, photo, info}`. 

## Document `membre`
_data_:
- `id` : id du groupe.
- `ids`: identifiant, indice de membre relatif à son groupe.
- `v`
- `vcv` : version de la carte de visite du membre
- `dlv` : date de dernière signature + 365 lors de la connexion du compte de l'avatar membre du groupe.

- `ddi` : date de la dernière invitation
- `dda` : date de début d'activité (jour de la première acceptation)
- `dfa` : date de fin d'activité (jour de la dernière suspension)
- `inv` : validation de la dernière invitation:
  - `null` : le membre n'a pas été invité où le mode d'invitation du groupe était _simple_ au moment de l'invitation.
  - `[ids]` : liste des indices des animateurs ayant validé la dernière invitation.
- `mc` : mots clés du membre à propos du groupe.
- `infok` : commentaire du membre à propos du groupe crypté par la clé K du membre.
- `datag` : données, immuables, cryptées par la clé du groupe :
  - `nom` `rnd` : nom complet de l'avatar.
  - `ni` : numéro aléatoire d'invitation du membre. Permet de supprimer l'invitation et d'effacer le groupe dans son avatar (clé de `lgrk invits`).
	- `idi` : indice du membre qui l'a inscrit en comme _contact_.
- `cva` : carte de visite du membre `{v, photo, info}` cryptée par la clé du membre.

### Cycle de vie
- un document `membre` existe dans tous les états SAUF 0 _disparu / oublié_.
- un auteur d'un secret `disparu / oublié`, apparaît avec juste un numéro (sans nom), sans pouvoir voir son membre dans le groupe.

#### Transitions d'état d'un membre:
- de contact : 
  - invitation -> invité
  - disparition -> disparu
  - demande d'oubli par un animateur -> disparu
- de invité :
  - refus -> invitation refusée
  - refus fort -> oubli
  - acceptation -> actif
  - retrait d'invitation par un animateur -> contact (`dfa` est 0) OU suspendu (`dfa` non 0, il a été actif)
  - disparition -> disparu
  - demande d'oubli par un animateur -> disparu
- de actif :
  - résiliation / auto-résiliation -> suspendu
  - résiliation / auto-résiliation forte -> disparu
  - disparition -> disparu
- de invitation refusée :
  - invitation -> invité
  - disparition -> disparu
  - demande d'oubli par un animateur -> disparu
- de suspendu :
  - invitation -> invité
  - disparition -> disparu
  - demande d'oubli par un animateur -> disparu
- de disparu / oubli : aucune transition (`membre` a été purgé)

**Simple contact inscrit par un membre du groupe**
- le membre du groupe qui l'a inscrit, lui a attribué un index (taille de `ast` du groupe) et a marqué le statut _contact_ dans cet `ast`.
- son id ne figure pas dans le `datag` d'un autre membre: un même avatar ne peut pas figurer plus d'une fois dans un groupe.
- dans `membre` seuls `datag cva` sont significatifs. 

**Invité suite à une invitation par un animateur**
- invitation depuis un état _contact_  _suspendu_ _refus d'invitation_
- son statut dans `ast` passe à 20, 21, ou 22.
- dans `membre` `datag cva ddi` sont significatifs.
- si `dda` ou `dfa`, 
  - c'est une ré-invitation après suspension : présent dans `lgrk` et dans `membre` `mc infok` peuvent être présents.
- le groupe est inscrit dans l'avatar du membre (`invits`).

**Retrait d'invitation par un animateur**
- depuis un état _invité_
- son statut dans `ast` passe à 
  - _suspendu_ : si `dfa` existe, c'était un ancien membre actif
  - _contact_ : `dfa` est 0, il n'a jamais été actif.
- dans `membre` seuls `datag cva ddi` sont significatifs. 

**Actif suite à l'acceptation d'une invitation par le membre**
- son statut dans `ast` passe à 30, 31, ou 32.
- dans membre :
  - `dda` : date de première acceptation est remplie si elle ne l'était pas.
  - toutes les propriétés sont significatives.
  - la carte de visite `cva` est remplie.
- le groupe est inscrit dans l'avatar du membre  dans `lgrk` et retiré de `invits`.

**Refus d'invitation par le membre**
- depuis un état _invité_.
- son statut dans `ast` passe à 40.
- si `dda` ou `dfa`, 
  - c'est une ré-invitation après suspension : présent dans `lgrk` et dans `membre` `mc infok` peuvent être présents.
- le groupe est retiré dans son avatar de `invits`.
- dans `membre` rien ne change.

**Oubli demandé par un animateur ou le membre lui-même**
- depuis un état _contact, invité, actif, suspendu_
- actions: 
  - refus d'invitation _forte_,
  - résiliation ou auto-résiliation _forte_, 
  - demande par un animateur.
- son statut dans `ast` passe à 0. Son index ne sera **jamais** réutilisé.
- son document `membre` est purgé.
- le groupe est effacé dans `lgrk invits` de son avatar.

**Résiliation d'un membre par un animateur ou auto résiliation**
- depuis un état _actif_.
- son statut passe à _suspendu_ dans `ast` de son groupe.
- dans son document `membre` :
  - `dfa` est positionnée à la date du jour.
- différences avec un état _contact_: l'avatar membre sait par `lgrk` qu'il a été actif dans le groupe, a encore des mots clés, une information et peut être ré-invité. Dans `membre` `npi, vote` sont absents.

**Disparitions d'un membre**
- voir la section _Gestion des disparitions_

## Objet `compteurs`
- `j` : **date du dernier calcul enregistré** : par exemple le 17 Mai de l'année A
- **pour le mois en cours**, celui de la date ci-dessus :
  - `q1 q2`: quotas actuels.
  - `v1 v2 v1m v2m`: volume actuel des secrets et moyens sur le mois en cours.
  - `trj` : transferts cumulés du jour.
  - `trm` : transferts cumulés du mois.
- `tr8` : log des volumes des transferts cumulés journaliers de pièces jointes 
  sur les 7 derniers jours + total (en tête) sur ces 7 jours.
- **pour les 12 mois antérieurs** `hist` (dans l'exemple ci-dessus Mai de A-1 à Avril de A),
  - `q1 q2` quotas q1 et q2 au dernier jour du mois.
  - `v1 v2` log des volumes moyens du mois (log de v1m v2m ci-dessus au dernier jour du mois)
  - `tr` log du total des transferts des pièces jointes dans le mois (log de trm à la fin du mois).

## Mots clés, principes et gestion
Les mots clés sont utilisés pour :
- filtrer / caractériser à l'affichage les **chats** accédés par un compte.
- filtrer / caractériser à l'affichage les **groupes (membres)** accédés par un compte.
- filtrer / caractériser à l'affichage les **secrets**, personnels ou partagés avec un groupe.

La définition des mots-clés (avatar et groupe) est une map :
- _clé_ : indice du mot-clé de 1 à 255,
- _valeur_ : texte `catégorie/label du mot-clé`.

Affectés à un membre ou secret, c'est un array de nombre de 1 à 255 (Uin8Array).

Les mots clés d'indice,
- 1-99 : sont ceux d'un compte.
- 100-199 : sont ceux d'un groupe.
- 200-255 : sont ceux définis en configuration (généraux dans l'application).

# Gestion des disparitions

## Signatures des avatars dans `version` et `membre`
Les comptes sont censés avoir au maximum 365 jours entre 2 connexions faute de quoi ils sont considérés comme `disparus`. 10 jours après la disparition d'un compte, 
- ses avatars secondaires vont être détectés disparus par le GC.
- ses membres dans les groupes auxquels il participe vont être détectés disparus par le GC ce qui peut entraîner la disparition de groupes n'ayant plus d'autres membres _actifs_.

Les `dlv` (date limite de validité) sont exprimées par un entier `aaaammjj`: elles signalent que ce jour-là, l'avatar -le cas échéant le compte- ou le membre sera considéré comme _disparu_.

A chaque connexion d'un compte, son avatar principal _prolonge_ les `dlv` de :
- son propre avatar et ses avatars secondaires dans leur document `version`.
- des membres (sur `membre`) auxquels ses avatars sont _actifs_. 

Les `dlv` sont également gérées:
- pour un avatar, à sa création.
- pour un membre d'un groupe, à l'acceptation de son invitation.

> Les `dlv` ne sont pas _prolongées_ si le document `tribu2s` de l'avatar principal ou de sa `tribus` font l'objet d'une procédure de blocage.

**Règles:** 
- les `dlv` sont gérées par _décade_ : une `dlv` est toujours définie ou reculée à un multiple de 10 jours.
- ceci évite de multiplier des mises à jour en cas de connexions fréquentes et de faire des rapprochements entre avatars / groupes en fonction de leur dernière date-heure de connexion.
- si l'avatar principal a sa `dlv` repoussée le 10 mars par exemple, ses autres avatars et ses membres seront reculés au 20 mars.
- les avatars secondaires seront en conséquence _non disparus_ pendant 10 jours alors que leur compte ne sera plus connectable :
  - sur un chat la carte de visite d'un avatar secondaire apparaîtra pendant 10 jours alors que le compte de _l'autre_ a déjà été détecté disparu.
  - les groupes pourront faire apparaître des membres pendant 10 jours alors que leur compte a déjà été détecté disparu.

### Disparition d'un compte
#### Effectuée par le GC
Le GC détecte la disparition d'un compte sur dépassement de la `dlv` de son avatar principal :
- il ne connaît pas la liste de ses avatars secondaires qu'il détectera _disparu_ 10 jours plus tard.
- le GC n'a pas accès à la connaissance de la tribu d'un compte et ne peut donc pas mettre à jour `tribu / tribu2`:
  - le GC ne peut ni lire ni supprimer l'entrée du compte dans `tribu2`, l'id de cette entrée nécessitant de connaître la clé du compte.
  - il écrit en conséquence un document `gcvol` avec les informations tirées du `compta` du compte disparu (id crypté de la tribu, quotas attribués au compte à rendre disponibles à sa tribu).
  - la prochaine connexion du Comptable scanne les `gcvol` et effectue la mise à jour des quotas attribués de la tribu du compte disparu en lui ajoutant ceux du compte trouvés dans `gcvol` (pour autant que le compte n'ait pas déjà été traité et retiré de `tribu2`).

La disparition d'un compte est un _supplément_ d'action par rapport à la _disparition_ d'un avatar secondaire.

#### Auto-résiliation d'un compte
Elle suppose une auto-résiliation préalable de ses avatars secondaires, puis de son avatar principal:
- l'opération de mise à jour de `tribu / tribu2` est lancée, la session ayant connaissance de l'id de la tribu et de l'entrée du compte dans tribu2. Le mécanisme `gccol` n'est pas mis en oeuvre.

### Disparition d'un avatar
#### Sur demande explicite
Dans la même transaction :
- pour un avatar secondaire, le document `compta` est mis à jour par suppression de son entrée dans `mavk`.
- pour un avatar principal, l'opération de mise à jour de `tribu / tribu2` est lancée, 
  - l'entrée du compte dans `tribu2` est détruite,
  - le document `compta` est purgé.
- les documents `avatar` et `version` sont purgés.
- dans le planning du GC l'id de l'avatar est inscrite pour purge de ses données.
- pour tous les chats de l'avatar:
  - le chat E, de _l'autre_, est mis à jour : son `st` passe à _disparu_, sa `cva` passe à null.
- pour tous les groupes dont l'avatar est membre:
  - purge de son document `membre`.
  - mise à jour dans son `groupe` du statut `ast` à _disparu_.
  - si c'était l'hébergeur du groupe, mise à jour des données de fin d'hébergement.
  - si c'était le dernier membre _actif_ du groupe:
    - pour tous les _invités_ suppression dans leur `avatar` de l'entrée de l'invitation dans `invits`.
    - purge du groupe puisque plus personne ne le référence (et donc qu'aucune session ne pouvait être dessus).
    - dans le planning du GC l'id du groupe est inscrite pour purge de ses données.

Dans les autres sessions ouvertes sur le même compte :
- si c'est l'avatar principal : 
  - la session est notifiée d'un changement de `tribu2`, 
  - y constate la disparition de l'entrée du compte,
  - **la session est close avec un avis de résiliation du compte** par une autre session et suppression de la base IDB. 
- si c'est un avatar secondaire :
  - la session est notifiée d'un changement de `compta` et détecte la suppression d'un avatar.
  - la session supprime en mémoire ce qui est relatif à cet avatar : si c'était l'avatar courant, l'avatar primaire devient courant. La page d'accueil est affichée si c'était une des pages dépendante de l'avatar courant qui l'était.
  - la session supprime toutes les entrées de IDB relatives à l'avatar.

Lors des futures connexions sur le même compte:
- si le compte n'existe plus la connexion de ne peut pas avoir lieu.
- en mode _synchronisé_ les avatars et groupes qui étaient en IDB et ne sont plus existants sont purgés de IDB.

Dans les autres sessions ouvertes sur d'autres comptes, la synchronisation fait apparaître :
- par `tribu2` : un compte qui disparaît dans `tribu2` entre l'état courant et le nouvel état,
- par `chat` : un statut _disparu_ et une carte de visite absente,
- par `groupe` : un membre disparu, ce qui entraîne aussi la suppression du document `membre` en mémoire (et en IDB).

#### Effectuée par le GC
Le GC détecte la disparition d'un avatar par dépassement de sa `dlv` : **le compte a déjà disparu**.

Rappel : si c'est un avatar principal,
- il inscrit un document pour traitement ultérieur par l'ouverture d'une session du Comptable (mise à jour `tribu / tribu2`).
- le document `compta` est purgé.

Avatars secondaire ou primaire :
- dans son planning l'id de l'avatar est inscrite pour purge de toutes ses données.

**Conséquences :**
- il reste des chats référençant cet avatar et dont le statut n'est pas encore marqué _disparu_ (mais le GC n'a pas accès).
- il reste des groupes dont le statut du membre correspondant n'est pas _disparu_,
- il reste des documents membres référençant un avatar (principal) disparu.

### Disparition d'un membre
#### Résiliation ou auto résiliation d'un membre
C'est une opération _normale_:
- purge de son document `membre`.
- mise à jour dans son `groupe` du statut `ast` à _disparu_.
- si c'était l'hébergeur du groupe, mise à jour des données de fin d'hébergement.
- si c'était le dernier membre _actif_ du groupe:
  - pour tous les _invités_ suppression dans leur `avatar` de l'entrée de l'invitation dans `invits`.
  - purge du `groupe` puisque plus personne ne le référence (et donc qu'aucune session ne pouvait être dessus).
  - dans le planning du GC l'id du groupe est inscrite pour purge de ses données.

#### Effectué par le GC
Le GC détecte un membre disparu par dépassement de sa `dlv` :
- purge de son document `membre`.
- si c'était le dernier membre _actif_ du groupe:
  - le document `groupe` passe en _zombi_ et sa `dlv` est positionnée de manière à être purgée dans un an quand toutes les synchronisations / connexions l'auront prise en compte.
  - dans son planning l'id du groupe est inscrite pour purge de ses données.
- si ce n'était PAS le dernier membre _actif_ du groupe:
  - dans `groupe` son statut `ast` passe à _disparu_.
  - si c'était l'hébergeur du groupe, mise à jour des données de fin d'hébergement (`dfh, idhg, imh`).

### Autres purges sur dépassement de `dlv`
La `dlv` est une date de **purge** dans les cas suivants:
- sur `version` d'un groupe : le groupe était en état _zombi_.
- sur `chat` : le chat était _supprimé_.
- sur `secret`: secret était _zombi_.
- sur `sponsoring` : il avait atteint limite de validité.

Sur `transfert`, déclenchement de l'opération pour suppression de fichiers dans le FileStore.

### Chat : détection de la disparition de l'avatar E
A la connexion d'une session les chats avec des avatars E disparus ne sont pas détectés.

Lors d'une synchronisation de son chat (I), l'auto suppression de l'avatar E dans une autre session est détecté par l'état _disparu_ de E inscrit sur le chat (I).

Lors de l'ouverture de la page listant les _chats_ d'un de ses avatars, 
- la session reçoit les CV mises à jour ET les avis de disparitions des contacts E.
- lors de l'écriture d'un chat, la session reçoit aussi ce même avis de disparition éventuelle de l'avatar E.
- le _contact_ E est marqué _disparu_ en mémoire (le chat I y est mis à jour ainsi qu'en IDB).
- si l'avatar disparu est un avatar principal ET de la même tribu, l'opération `DisparitionCompte` peut être lancée : elle requiert l'id de la tribu et le nom complet de l'avatar, infos disponibles dans la mémoire de la session. Ceci permet d'anticiper le retrait du compte de sa tribu sans devoir attendre l'ouverture de la prochaine session du comptable et le traitement des `gcvol`.

> Un _contact_ peut donc apparaître "à tort" en session alors que l'avatar / compte correspondant a été résilié du fait, a) qu'il est un des comptes de la tribu de la session, b) qu'un chat est ouvert avec lui. Toutefois l'ouverture du chat ou de la page des chats, rétablit cette distorsion temporelle provisoire.

# GC quotidien
Délais :
- N1 : 370 jours, un peu plus d'un an. Inactivité d'un compte.
- N2 : 90 jours. Délai de survie d'un groupe sans hébergeur.

Le GC quotidien a un _point de reprise_ enregistré dans le document singleton `checkpoint`.
- date du jour de GC
- array des date-heures de fin des étapes terminées.
- _purge1_ : liste des ids des avatars et groupes dont les **sous-collections** sont à purger.
- _purge2_ : liste des `[id, idf]` -`idf` peut être 0 si ce sont tous les fichiers du _folder_ qui sont concernés, des fichiers à purger dans le Storage.

Quand le GC est lancé,
- soit il part sur un nouveau traitement quotidien si le dernier a eu toutes ses étapes terminées et que le jour courant est postérieur au dernier jour du traitement.
- soit il part en reprise à l'étape qui suit la dernière terminée.

Le GC quotidien effectue les activités de nettoyage suivantes :

#### Etape 1
Une transaction pour chaque groupe ayant dépassé leur `dfh`:
- `dfh` : mise en état _zombi_ du `groupe`. Ce changement d'état est synchronisé. 
  - les sessions ouvertes et accédant à ces groupes, émettront ultérieurement une opération pour retirer le groupe de la liste des groupes de leur avatar.
  - les sessions s'ouvrant postérieurement feront la même opération au chargement initial.
- inscription de l'id du groupe,
  - dans la liste _purge1_.
  - dans la liste _purge2_ des _folder_ de fichiers externes à purger.

#### Etape 1b
Purge des documents ayant dépassé leur `dlv`.
- sur `groupe` : ils étaient _zombi_.
- sur `chat` : les chat étaient considérés comme _supprimé_.
- sur `secret`: ils étaient _zombi_.
- sur `sponsoring` : ils avaient dépassé leur limite de validité.
- sur `transferts` : inscription de ce fichier dans _purge2_.

#### Etape 1b
Une transaction pour chaque membre `id, ids` ayant dépassé sa `dlv`:
- dans son groupe `id`, `ast[ids]` est mis à 0, `v` est incrémentée et la synchronisation est effectuée.
- le `membre` est purgé.

#### Etape 2
Une transaction par avatar principal ayant dépassé sa `dlv` : voir ci-avant.

#### Etape 3
- purge progressive du FileStore des fichiers listés dans _purge2_ : `checkpoint` est mis à jour avec une liste raccourcie à chaque batch de suppressions.

#### Etape 4
- purge progressive des sous-collections des avatars et groupes listés dans _purge1_ : `checkpoint` est mis à jour avec une liste raccourcie à chaque batch de suppressions.

# Annexe I : requêtes génériques (5)
Requêtes s'appliquant,
- aux documents majeurs : tribus comptas avatars groupes
- aux sous-documents : 
  - d'un avatar : secrets transferts sponsorings chats
  - d'un groupe : secrets transferts membres

### Mises à jour d'un (sous) document (3)

ins / upd (set)
- d'un document ou sous-document

del
- d'un document / sous-document

### Lecture d'UN (sous) document (1)

get 0-1
- d'un (sous) document, conditionné ou non à être de version postérieure à v

### Lecture des documents d'une (sous) collection (1)

coll 0-N
- de N (sous) documents, conditionnés ou non à être de version postérieure à v

# Annex II : requêtes spécifiques (25)
### Lecture (9)
getCv 0-1
- lecture d'une CV [photo, info] d'UN `avatars`, conditionnée ou non à être de version postérieure à `v`

hps1 0-1
- lecture du document `comptas` ayant `hps1` == x

hpc 0-1
- lecture du document `avatars` ayant `hpc` == x

sponsorings 0-1 - collectionGroup
- lecture du document `sponsorings` d'une phrase donnée (`ids`)

comptaT 0-N
- `comptas` d'une tribu t

comptaB 0-N
- `comptas` bloquées

comptaTB 0-N
- `comptas` bloquées d'une tribu `t`

tribuD 0-N
- `tribus` mises à jour après `dh`

tribuDB 0-N
- `tribus` bloquées mises à jour après dh

tribuB 0-N
- `tribus` bloquées

### Lecture / écriture singletons (4)
lecture de `notif`

écriture de `notif`

lecture de `checkpoint`

écriture de `checkpoint`

### Lecture pour le GC (4)
dlvAvatars 0-N
- `dlv` >= jour j

dlvGroupes 0-N
- `dlv` >= jour J

dfhGroupes 0-N
- `dfh` >= jour J

dlvTransferts 0-N - collectionGroup
- `dlv` >= jour J

### Purge sous collection (5)
purgeSecrets

purgeTransferts

purgeSponsorings

purgeChats

purgeMembres

### Purge par `dlv` (3) - à `dlv` + 370 jours
purgeGroupes - collectionGroup

# Annexe I : implémentations
Deux implémentations sont disponibles : SQL et Firestore.

**SQL** : elle utilise une base de données `SQLite` comme support de données persistantes :
- elle s'exécute en tant que serveur HTTPS dans un environnement **node.js**.
- un serveur Web distinct sert l'application Web front-end.
- les backups de la base peuvent être stockés sur un Storage.
- le Storage des fichiers peut-être,
  - soit un file-system local du serveur,
  - soit un Storage S3 (éventuellement minio).
  - soit un Storage Google Cloud Storage.

**Firestore** : un stockage persistant Google Firestore
- en mode serveur, un GAE de type **node.js** sert de serveur
- le stockage est assurée par Firestore : l'instnace FireStore est découplée du GAE, elle a sa propre vie et sa propre URL d'accès. En conséquence elle _peut_ être accédée depuis n'importe où, et typiquement par un utilitaire d'administration sur un PC pour gérer un upload/download avec une base locale _SQLite_ sur le PC.
- le Storage est Google Cloud Storage

Un utilitaire **node.js** local peut accéder à un Firestore distant:
- exporte un Firestore distant (ou local de test) dans une base SQLite locale.
- importe dans un Firestore distant (ou local de test) vide une base SQLite locale.
