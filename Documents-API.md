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
      Document `config`
      Document `checkpoint`

    /Collection `gcvols`        
      Documents                   id

    /Collection `tribus`
      Documents                   id v iv dh dhb (dhb = dh quand la tribu est bloquée, sinon absente)
    
    /Collection `comptas`
      Documents                   id v iv idt idtb hps1 (idtb = idt quand le compte est bloqué)

    /Collection `versions`
      Documents                   id v iv dlv dfh (pour un groupe)

    /Collection `avatars`
      Document                    id v iv vcv ivc hpc
        /Collection `secrets`
          Documents               id ids v iv
        /Collection `transferts`
          Document `transfert`    id ids **dlv
        /Collection `sponsorings`
          Document `sponsoring`   id **ids v iv **dlv
        /Collection `chats`
          Documents               id ids v iv **dlv

    /Collection `groupes`
      Document `groupe`           id v iv
        /Collection `membres`
          Document membre         id ids v iv **dlv        
        /Collection `secrets`
          Document `secret`       id ids v iv         
        /Collection `transferts`  
          Document `transfert`    id ids **dlv

    Collection  Attrs non indexés     Attrs indexés     Attrs collectionGroup
    singletons  _data_
    gcvols      id _data_
    tribus      id v _data_           iv dh dhb
    comptas     id v _data_           iv idt idtb hps1
    versions    id v _data_           iv dlv dfh
    avatars     id v vcv hpc _data_   iv ivc
    groupes     id v _data_           iv

    secrets     id ids v _data_       iv
    transferts  id ids                                  dlv
    sponsorings id v _data_           iv                dlv ids
    chats       id ids v _data_       iv                dlv
    membres     id ids v _data_       iv                dlv

Tous les documents, ont un attribut _data_ (mais toujours {} pour `transferts`), qui porte les informations sérialisées du document.
- les attributs externalisés hors de _data_ le sont parce qu'ils sont utilisés comme identifiants et / ou champs indexés.
- les attributs `iv ivc idtb dhb` ne sont pas explicitement présents dans _data_ étant calculables depuis `id, v, vcv, dh, bloc`.

#### Documents d'une collection majeure
Les documents _majeurs_ sont ceux des collections `tribus comptas versions avatars groupes`.
- leur identifiant porte le nom `id` et est un entier.
- chaque document porte une version `v` : c'est un numéro séquentiel du nombre de mises à jours subies par le document lui-même et les documents de ses sous-collections.
  - le dernier numéro de version attribué de `tribus groupes` figure dans leur document.
  - le dernier numéro de version attribué pour `avatars comptas` figure dans le documents `comptas` qui détient ces numéros pour les avatars 0 à 7 du compte (avatar 0).

#### Documents d'une sous-collection d'un document majeur :
- `chats secrets transferts sponsorings` d'un **avatar**.
- `membres secrets transferts` d'un **groupe**.

Leur identifiant relatif à leur document majeur est `ids`.

#### Gestion des versions dans `versions`
- un document `avatar` d'id `ida` et les documents de ses sous collections `chats secrets transferts sponsorings` ont une version prise en séquence continue fixée dans le document `versions` ayant pour id `ida`.
- idem pour un document `groupe` et ses sous-collections `membres secrets transferts`.
- toute mise à jour provoque l'incrémentation de 1 du numéro de version dans `versions` et l'inscription de cette valeur comme version du document mis à jour.

Un document version gère aussi :
- `dlv` : la signature de vie de son avatar ou groupe.
- en _data_ pour un groupe :
  - `v1 q1` : volume et quota dee textes des secrets du groupe.
  - `v2 q2` : volume et quota dee fichiers des secrets du groupe.

#### Documents _synchronisables_ en session
Une session a une liste d'ids abonnées :
- l'id de son compte : quand un document compta change il est transmis à la session.
- les ids de ses groupes et avatars : quand un document versions ayant une des ids change, il est transmis à la session à titre de _notification_. C'est ensuite la tâche de synchronisation de la session qui ira chercher, par une transaction pour chaque document majeur, le document majeur et ses sous documents ayant des versions postérieures.

**Remarque :** en session ceci conduit au respect de l'intégrité transactionnelle pour chaque objet majeur mais pas entre objets majeurs dont les mises à jour pourraient être répercutées dans un ordre différent de celui opéré par le serveur.
- en SQL les notifications pourraient être regroupées par transaction et transmises dans l'ordre.
- en FireStore ce n'est pas possible : la session pose un écouteur sur des objets compta et version individuellement, l'ordre n'est pas garanti entre objets majeurs.

#### Id-version : `iv`
Un `iv` est constitué sur 15 chiffres :
  - en tête des 9 derniers chiffres de l'`id` du document majeur.
  - suivi sur 6 chiffres de `v`, numéro de la version.

Un `iv` permet de filtrer un document précis selon sa version. Il sert:
- **à gérer une mémoire cache dans le serveur des documents majeurs** récemment accédés : si la version actuelle est déjà en cache, le document _n'est pas_ chargé (seul l'index est accédé).
- **à remettre à jour en session _incrémentalement_ UN document majeur ET ses sous-documents** en ne chargeant à la connexion QUE les documents plus récents que la version de leur document majeur détenue dans la session.

Comme un `iv` ne comporte pas une `id` complète mais seulement ses 9 derniers chiffres, de temps en temps (mais très rarement) le filtrage _peut_ donner retourner des _faux positifs_ qu'il faut retirer du résultat en vérifiant leur `id` dans le document.

### `idt idtb` de comptas : d'une tribu / bloquées d'une tribu / bloquées (toutes tribus)
`idt` est l'id de la tribu du compte. Son indexation permet à un parrain de la tribu ou au comptable de récupérer,
- tous les comptes de la tribu, 
- ceux bloqués en utilisant `idtb`
  - d'une tribu : `idtb == ...`
  - toutes tribus : `idtb != 0`

#### `dh` et `dhb` sur `tribus`
Le comptable a des process de gestion des tribus:
- au début du process, il récupère toutes les tribus ayant un état plus récent que celui connu à la clôture du process précédent.
- il s'abonne à la collection tribus pour obtenir les mises à jour.
- à la fin du process, il arrête son abonnement mais conserve en session les tribus chargées.

Pour n'obtenir en début de process suivants que les tribus ayant changé depuis le dernier chargement (total ou incrémental), il filtre les tribus sur l'attribut `dh`, date-heure de dernière mise à jour.

`dhb` est la copie de `dh` QUAND le niveau de blocage n'est pas 0 : quand le comptable ne s'intéresse qu'aux tribus bloquées, il filtre sur `dhb` plutôt que `dh`.

De même pour `comptas`, `ivb` est égal à `iv` si le compte est bloqué afin que les parrains puisse travailler sur le sous-ensemble des comptes bloqués de leur tribu plutôt que sur tous.

#### `dlv` et `dfh` : **date limite de validité** et **date de fin d'hébergement** 
Les `dlv` sont passées sur la partie row externe à _data_ : en synchronisation aussi (puisque _data_ ne sera présente).

- sur _avatars et groupes_ :
  - **jour auquel l'avatar ou le groupe sera officiellement considéré comme _disparu_.**
  - sur une liste de membres, lors de l'écriture d'un chat, sur une carte de visite, les avatars _proches de leur date de disparition_ peuvent être affichés avec une marque particulière.
  - permettent au GC de récupérer tous les _disparus_.
  - sur _membres_ : pas indexés mais permettent de savoir que le membre a disparu SANS regarder dans _data_.
  - les groupes dont la `dlv` est antérieure au jour J sont considérés comme _disparu_. Leur document reste encore mais réduit a minima, sans _data_, est immuable et sera, un an plus tard, techniquement purgés.

- sur _transferts_:
  - **jour auquel il est considéré que le transfert tenté a définitivement échoué**.
  - permet au GC de détecter les transferts définitivement échoués et de nettoyer le Storage.
  - l'index est _groupe de collection_ afin de s'appliquer aux fichiers des groupes comme des avatars.

- sur _chats_:
  - jour à partir duquel le chat est considéré comme inactif et n'est donc plus, ni lu, ni écrit, par les sessions. Celles-ci suppriment automatiquement à la connexion les chats ayant dépassé leur `dlv`. Les synchronisations ont le même effet.

- sur _sponsorings_:
  - jour à partir duquel le parrainage n'est plus applicable. Les sessions suppriment automatiquement à la connexion les sponsorings ayant dépassé leur `dlv` (idem pour les synchronisations).

- `dfh` : la **date de fin d'hébergement** sur un groupe permet au GC de mettre ces groupes en _zombi_ (disparu logiquement) en forçant leur `dlv` à la date du jour (`dfh` disparaissant).

#### Index de groupes de collection: `dlv ids`
- `dlv` : **date limite de validité**:
  - sur _transferts_: permet au GC détecte les transferts définitivement échoués et nettoyer le Storage.
- `ids` : hash de la phrase de parrainage sur `sponsorings`.

#### Cache locale des `comptas versions avatars groupes tribus` dans une instance d'un serveur
- les `comptas` sont utilisées à chaque mise à jour de secrets.
- les `versions` sont utilisées à chaque mise à jour des avatars, de ses chats, secrets, sponsorings.
- les `avatars groupes tribus` sont également souvent accédés.

**Les conserver en cache** par leur `id` est une bonne solution : mais en FireStore il peut y avoir plusieurs instances s'exécutant en parallèle. Il faut en conséquence interroger la base pour savoir s'il y a une version postérieure et ne pas la charger si ce n'est pas le cas en utilisant un filtrage par `iv`.

La mémoire cache est gérée par LRU (tous types de documents confondus)

## Généralités
Les clés AES et les PBKFD sont des bytes de longueur 32.

Un entier sur 53 bits est intègre en Javascript (15 chiffres décimaux). Il peut être issu de 6 bytes aléatoires.

Le hash (_integer_) d'un bytes est un entier intègre en Javascript.

Le hash (_integer_) d'un string est un entier intègre en Javascript.

Les date-heures _serveur_ sont exprimées en micro-secondes depuis le 1/1/1970, soit 52 bits (entier intègre en Javascript). Les date-heures fonctionnelles sont en milli-secondes.

#### Nom complet d'un avatar / groupe / tribu
Le **nom complet** d'un avatar / groupe / tribu est un couple `[nom, cle]`
- `nom` : nom lisible et signifiant, entre 6 et 20 caractères. Le nom `Comptable` est réservé.
- `cle` : 32 bytes aléatoires. Clé de cryptage. Le premier byte donne le _type_ de l'id :
  - 0 : compte / avatar principal.
  - 1 : avatar secondaire.
  - 2 : groupe,
  - 3 : tribu.
- A l'écran le nom est affiché sous la forme `nom@xyzt` (sauf `Comptable`) ou `xyzt` sont les 4 premiers chiffres de l'id.

**Dans les noms,** les caractères `< > : " / \ | ? *` et ceux dont le code est inférieur à 32 (donc de 0 à 31) sont interdits afin de permettre d'utiliser le nom complet comme nom de fichier.

#### Les ids
**Singletons**
- il y a 2 singletons d'id respectives `config` et `gc`.

**Ids des documents majeurs `avatar` (sauf comptable), `groupe`, `tribu`:**
- le hash (_integer_) de la cle est un entier SAFE en Javascript : il est divisé par 10.
- un dernier chiffre (0 à 3) donne le _type_ de l'objet identifié.

**Compte de nom réservé `Comptable`**
- son id est Number.MAX_SAFE_INTEGER (2^53 - 1 = `9007199254740990`).
- sa clé est également fixe : [0, 255, 255 ...].
- son nom est réservé et non attribuable par les autres avatars.
- carte de visite constante fixée par la configuration.

**Sous-documents**
- l'id d'un `sponsoring`, rendez-vous est le hash de la phrase de reconnaissance.
- l'id d'un `chat` est un numéro `ids` aléatoire relatif à celui de son avatar.
- l'id d'un `secret` est un numéro `ids` aléatoire relatif à celui de son avatar ou groupe.
- l'id d'un `membre` est `ids` un indice croissant depuis 1 relatif à son groupe.

#### Les `dlv` : date limite de validité des avatars et groupes
A la connexion d'un compte, si sa `dlv` précédente a plus de 30 jours, il signe en inscrivant une `dlv` :
- par la date du jour son avatar principal (son compte) + 1 an.
- par une date aléatoire de 5 à 20 jours postérieure:
  - ses avatars secondaires,
  - pour chaque groupe dont il est membre,
    - le groupe lui-même si sa `dlv` a plus de 30 jours
    - som membre dans le groupe. Ainsi le groupe peut détecter la disparition de chaque membre et en gérer le statut en lisant son dds (non indexé).

#### `dfh` : date de fin d'hébergement d'un groupe
Elle signale un changement de statut majeur du groupe et au bout d'un certain temps le groupe sera purgé par le batch de nettoyage.

### Authentification
- Les opérations liées aux créations de compte ne sont pas authentifiées, elles vont justement enregistrer leur authentification.  
- Les opérations de tests de type _ping_ ne le son pas non plus.  
- Toutes les autres opérations le sont.

>**En mode SQL**, un WebSocket a été ouvert identifié par une `sessionId` (un numéro de session tiré au sort par la session et qui change à chaque déconnexion) qu'on retrouve sur les messages afin de s'assurer qu'un échange entre session et serveur ne concerne pas une session antérieure fermée.

Toute opération porte un `token` portant lui-même un `sessionId`:
- si le serveur retrouve dans la mémoire cache l'enregistrement de la session `sessionId` :
  - **il en obtient l'id du compte**,
  - il prolonge la `ttl` de cette session dans cette cache.
- si le serveur ne trouve pas la `sessionId`, 
  - soit il y en bien une mais dans une autre instance, 
  - soit c'est une déconnexion pour dépassement de `ttl` de cette session.
  Dans les deux cas l'authentification va être refaite depuis le `token` fourni et y fixer l'id du compte.

**`token`** : sérialisation encodée en base 64 de :
- `sessionId`
- `shax` : SHA de X (PBKFD de la phrase secrète complète).
- `hps1` : hash du PBKFD de la ligne 1 de la phrase secrète.

Le serveur recherche l'id du compte par `hps1` (index de `comptas`)
- vérifie que le SHA de `shax` est bien celui enregistré dans `compta` en `shay`.
- inscrit en mémoire `sessionId` avec l'id du compte et un `ttl`.

### Purge des _disparus_
La purge d'une **tribus** est déclenchée explicitement par le comptable sur une tribu n'ayant plus de comptas.

La purge d'un **avatars** est une opération du batch quotidien sur dépassement de sa `dlv`:
- si c'est un avatar secondaire, son compte avatar primaire aura été purgé avant.
- la suppression s'effectue en deux temps : 
  - purge immédiate de l'avatar et inscription de l'avatar dans le singleton `gc` afin que la purge de ses secrets, chats, ... soit exécuté par le GC.
- ses membres dans les groupes peuvent ne pas avoir été purgés avant : un membre peut donc être _zombi_ (existant en tant que membre mais inexistant en tant qu'avatar).
- pour un avatar principal, la compta du compte donne l'id de la tribu ce qui permet au GC de créer un document `gcvol` avec les compteurs à créditer à la tribu par le comptable à sa prochaine connexion.

La purge d'un **groupe** intervient en deux temps : une fin d'hébergement peut en effet intervenir avant que tous les membres ne se soient résiliés:
- sur atteinte de limite sur `dlv` ou `dfh`, le document continue d'exister sans donnée, en état _zombi_. Les sessions vont détecter cet état au fil des connexions / synchronisations et progressivement enlever leurs références dans leur avatar. Le groupe est inscrit dans le singleton `gc` pour destruction ultérieure sans transaction des sous-collections `membres` et `secrets`.
- la `dlv` finit par purger un an plus tard le petit document groupe _zombi_ résiduel.

## Collection `singletons`

### Document `config`
Attribut opaque _data_ en JSON de manière à pouvoir être mis à jour par l'administrateur (ou par une page simpliste d'upload).

### Document `gc`
Attribut opaque _data_ : contient les informations de point de reprise du GC.

## Collection `gcvols`
Il y a autant de documents que de comptes ayant été détectés disparus et dont les quotas n'ont pas encore été rendus à leur tribu par une session du Comptable.

**Document:** - `id` : entier aléatoire
- `id` : entier aléatoire
- _data_ : 
  - compteurs récupérés du document `compta` du compte. `f1, f2, v1, v2`
  - `trcp` : `[nom, cle]` de la tribu qui doit récupérer les quotas crypté par la clé publique du comptable.

## Collection `tribus`
Cette collection liste les tribus déclarées sur le réseau et les fiches comptables des comptes rattachés à la tribu.

**Documents:** - `id` : numéro de la tribu  
Chaque document donne un descriptif de la tribu et la liste de ses parrains.
- `id` : numéro de la tribu 
- `v`
- `iv`
- `dh` : date-heure de mise à jour.
- `dhb` : copie de dh si la tribu est bloquée, sinon absente.
- _data_ : données de la tribu, dont la **liste de ses parrains** (nom, clé) et le descriptif de l'alerte.

### Collection `comptas`

**Documents:**  - `id` : numéro du compte
Un document par compte rattaché à sa tribu portant :
- ses compteurs d'occupation d'espace
- le descriptif de son alerte quand il y en a une.

**Attributs:**
- `id` : numéro du compte
- `v`
- `iv`
- `idtb` : copie de `idt` si le compte est bloqué, sinon absent.
- `idt` : id de la tribu actuelle.
- `hps1` : le hash du PBKFD de la ligne 1 de la phrase secrète du compte.
- _data_ :
  - `nat`: `[nom, clé]` de l'avatar principal du compte crypté par la clé de la tribu.
  - `shay` : le SHA du SHA de X (PBKFD de la phrase secrète).
  - _compteurs_,
  - _descriptif du blocage_ portée sur le compte,

**Remarques:**
- une session d'un compte :
  - est abonnée au document de sa `tribus`
  - est abonnée à son document `comptas`.
- une session du comptable s'abonne temporairement à la collection `tribus` durant une phase de gestion de la liste les tribus et d'une alerte tribu.
- une session d'un parrain (et du comptable) s'abonne temporairement à la collection `comptas` lors d'une phase d'audit des volumes et d'une gestion d'alerte compte.

### Collection `versions`

**Documents:**  - `id` : numéro d'un avatar ou d'un groupe

**Attributs:**
- `id` : id d'avatar / groupe.
- `v` : plus haute version attribuée aux documents de l'avatar / groupe.
- `dlv` : signature de vie.
- `dfh` : date de fin d'hébergement pour un groupe.
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
- `dlv` : date de dernière signature + 365.
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

Un secret est _supprimé_ quand sa _data_ est absente / null. La suppression est donc synchronisable par changement de la version `v` : il sera purgé lors de la purge de son avatar.

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
Un rendez-vous est identifié par une _phrase de reconnaissance_ convenue entre les deux avatars A et B ayant rendez-vous avec 2 objectifs :
- parrainage par A du compte de B.
- A ayant déposé son identité, B peut lui envoyer un chat ou l'inviter à un groupe.

Il y a un document par rendez-vous fixé par l'avatar.

**Documents:** - `ids`, hash de la phrase secrète de reconnaissance

**Attributs:**
- `id` : id de l'avatar ayant fixé le rendez-vous.
- `ids` : hash de la phrase secrète de reconnaissance
- `v`
- `dlv` : purge automatique des sponsorings.
- _data_ : données du rendez-vous.

### Sous-collection `chats`
Elle comporte un document par chat ouvert avec un avatar (externe, pas un avatar du compte)

**Documents:** - `ids`, numéro du chat pour l'avatar

**Attributs**
- `id` : id de son avatar.
- `ids` : numéro du chat pour l'avatar - hash des deux ids des avatars le partageant.
- `v`
- `iv`
- `dlv` : la dlv permet au GC de purger les chats. Dès qu'il y a une `dlv`, le chat est considéré comme inexistant autant en session que pour le serveur.
- _data_ : contenu du chat crypté par la clé de l'avatar. Contient le `[nom, clé]` de l'émetteur.

#### Avatars _externes_ E connaissant l'avatar A, chat entre avatars
- les membres des groupes dont A est membre.
- les parrains de sa tribu qui peuvent l'obtenir des documents `comptas`,
- le comptable pour la même raison.
- tout avatar C ayant conservé un chat émis par A.

Tout _avatar externe_ E connaissant A peut lui écrire un chat qui est dédoublé avec une copie pour A et une copie pour E.
- si A ne détruit pas un chat, il va disposer d'une liste de _contacts_ qui lui ont écrit.
- en supprimant le dernier chat avec E émis par E, A perd toute connaissance de E si c'était la seule raison pour laquelle il connaissait E.

## Collection `groupes`
Cette collections comporte un document par groupe existant.

**Documents :** - `id` : id du groupe
- `id` : id du groupe,
- `v`
- `iv`
- _data_ : données du groupe. Absent / null en état _zombi_ (les sous-collections ont déjà été purgées ou sont en cours de purge).

### Sous-collection `membres`
Elle comporte un document membre par membre.

**Documents:** 
- `ids`, indice du membre dans le groupe
- `id` : id du groupe.
- `ids`: indice de membre relatif à son groupe.
- `dlv` : date de dernière signature lors de la connexion du compte de l'avatar membre du groupe.
- `v`
- `iv`
- _data_ : données du membre. Contient en particulier [photo, info], la carte de visite de l'avatar.

### Sous-collection `secrets`
Elle compte un document par secret.

**Documents:** - `ids` numéro du secret pour le groupe.
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
## Document `gcvol`
_data_:
- `idt` : id de la tribu.
- `q1, q2, v1, v2`: quotas et volumes à rendre à la tribu.

## Document `tribu`
_data_:
- `id` : numéro de la tribu
- `v` : sa version
- `dh` : date-heure dernière modification.
- `dhb` : =dh quand la tribu est bloquée

- `ntk` : `[nom, rnd]` de la tribu crypté par la clé K du comptable.
- `infok` : commentaire privé du comptable crypté par la clé K du comptable.
- `nbc` : nombre de comptes actifs dans la tribu.
- `a1 a2` : sommes des volumes V1 et V2 déjà attribués comme forfaits aux comptes de la tribu.
- `r1 r2` : volumes V1 et V2 en réserve pour attribution aux comptes actuels et futurs de la tribu.
- `msps` : map des sponsors:
  - _clé_ : `id` du sponsor.
  - _valeur_ :
    - `na` : `[nom, rnd]` du sponsor crypté par la clé de la tribu.
    - `cv` : `{v, photo, info}` carte de visite cryptée par la clé CV du sponsor (le `rnd` ci-dessus).
  - l'ajout d'un parrain ne se fait que par le comptable mais un retrait peut s'effectuer aussi par un traitement de GC.
- `blocaget` : cryptée par la clé de la tribu : ("blocage" quand compilé)
  - `stn` : raison majeure du blocage : 0 à 9 repris dans la configuration de l'organisation.
  - `c`: 1 si positionné par le comptable (dans une tribu toujours 1)
  - `txt` : libellé explicatif du blocage.
  - `jib` : jour initial de la procédure de blocage
  - `lj` : `[j12 j23 j34]` : nb de jours de passage des niveaux de 1 à 2, 2 à 3, 3 à 4.
  - `dh` : date-heure de dernier changement du statut de blocage.

## Document `compta`
_data_:
- `id` : numéro du compte
- `idt` : id de la tribu
- `v` : version
- `hps1` : hash du PBKFD de la ligne 1 de la phrase secrète du compte.
- `shay` : SHA du SHA de X (PBKFD de la phrase secrète).
- `kx` : clé K du compte, cryptée par le PBKFD de la phrase secrète courante.
- `stp` : statut parrain (0: non, 1:oui).
- `mavk` : map des avatars du compte cryptée par sa clé K. 
  - _clé_ : id de l'avatar.
  - _valeur_ : `[nom clé]` : son nom complet.
- `nct` : `[nom, clé]` de la tribu crypté,
  - soit par la clé CV de l'avatar principal (figure dans `mavk`),
  - soit pour le Comptable par sa clé K (sa clé CV étant une constante publique).
- `nat`: `[nom, clé]` de l'avatar principal du compte crypté par la clé de la tribu. (un sponsor de la tribu peut ainsi lister les membres de la tribu)
- `compteurs`: compteurs sérialisés (non cryptés).
- `blocaget` : blocage du compte (cf `blocaget` de tribu).

**Remarques :**  
- Le document est mis à jour à minima à chaque mise à jour d'un secret.
- La version de `compta` lui est spécifique (ce n'est pas la version de l'avatar principal du compte).

## Document `version`
_data_ :
- `id` : id d'avatar / groupe
- `v` : plus haute version attribuée aux documents de l'avatar / groupe.
- `dlv` : signature de vie.
- `dfh` : date de fin d'hébergement pour un groupe.
- `iv`
- `{v1 q1 v2 q2}`: pour un groupe, volumes et quotas des secrets.

## Document `avatar`

**_data_  : données n'existant que pour un avatar principal**
- `mck` {} : map des mots-clés du compte cryptée par la clé K
- `memok` : mémo personnel du compte.

**_data_ : données disponibles pour les avatars primaires et secondaires**
- `id`, 
- `v`,
- `vcv` : version de la carte de visite afin qu'une opération puisse détecter (sans lire le document) si la carte de visite est plus récente que celle qu'il connaît.

- `cva` : carte de visite cryptée par la clé CV de l'avatar `{v, photo, info}`.
- `lgrk` : map :
  - _clé_ : `ni`, numéro d'invitation obtenue sur une invitation.
  - _valeur_ : cryptée par la clé K du compte de `[nomg, clég, im]` reçu sur une invitation.
  - une entrée est effacée par la résiliation du membre au groupe (ce qui l'empêche de continuer à utiliser la clé du groupe).
- `invits` : map des invitations en cours
  - _clé_ : `ni`, numéro d'invitation.
  - _valeur_ : cryptée par la clé CV de l'avatar `[nomg, clég, im]`.
  - une entrée est effacée par l'annulation de l'invitation du membre au groupe ou sur acceptation ou refus de l'invitation.
- `pck` : PBKFD de la phrase de contact cryptée par la clé K.
- `hpc` : hash de la phrase de contact.
- `napc` : `[nom, clé]` de l'avatar cryptée par le PBKFD de la phrase de contact.

**Invitation à un groupe**  
L'invitant connaît le `[nom, clé]` de l'invité qui est déjà dans la liste des membres en tant que pressenti. L'invitation consiste à :
- inscrire un terme `[nomg, cleg]` dans `invits` de son avatar (ce qui donne la clé du groupe à l'invité, donc accès à la carte de visite du groupe) en le cryptant par la clé de la carte de visite de l'invité,
- inscrire un `chat` de la part de l'invitant (ou ajouter un mot dans son chat).
- en cas de refus, l'invité donnera les raisons dans ce même `chat`.
- l'acceptation par l'avatar transfert l'entrée de `invits` dans `lgrk` en ré-encryptant l'entrée par la clé K.

## Document `chat`
Un chat est une ardoise commune à deux avatars A et B:
- pour être écrite par A :
  - A doit connaître le `[nom, cle]` de B : membre du même groupe, sponsor de la tribu, ou par donnée de la phrase de contact de B.
  - le chat est dédoublé, une fois sur A et une fois sur B.
  - dans l'avatar A, le contenu est crypté par la clé de A.
  - dans l'avatar B, le contenu est crypté par la clé de B.
- un chat a un comportement d'ardoise : chacun _écrase_ la totalité du contenu.
- si A essaie d'écrire à B et que B a disparu, la `dlv` est positionnée sur les deux exemplaires si elle ne l'était pas déjà.

**Suppression d'un chat**
- chacun peut supprimer son chat : par exemple A supprime son chat avec B
- côté A, la `dlv` du chat avec B est positionnée au jour courant + 365 (afin de permettre la synchronisation sur plusieurs sessions / appareils): c'est le GC quotidien qui le purgera.
- en session comme en serveur, dès qu'il y a une `dlv`, le chat est considéré comme inexistant.
- si B réécrit un chat à A, côté A la `dlv` du chat de B est remise à 0. Le chat _renaît_ (s'il avait été supprimé).

**Cartes de visite**
- à la création, puis à chaque mise à jour du texte, les cartes de visites sont remises à jour, si nécessaire.
- en session, l'ouverture de la page des chats d'un avatar rafraîchit les cartes de visite ayant changé de version.

_data_:
- `id`
- `ids` : identifiant du chat relativement à son avatar, hash de la concaténation des deux ids de A et B.
- `v`
- `dlv` : la dlv permet au GC de purger les chats. Dès qu'il y a une dlv, le chat est considéré comme inexistant autant en session que pour le serveur.

- `mc` : mots clés attribués par l'avatar au chat
- `cva` : `{v, photo, info}` carte de visite de _l'autre_ au moment de la création / dernière mise à jour du chat, cryptée par la clé CV de _l'autre_
- `contc` : contenu crypté par la clé CV de l'avatar _lecteur_.
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
P est le parrain-sponsor, F est le filleul.

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
- Le filleul crée son compte / avatar principal `naf` donne l'id de son avatar et son nom. Les infos de tribu pour le compte sont obtenu de `nct`.
- la `compta` du filleul est créée et créditée des quotas attribués par le parrain.
- la `tribu` est mise à jour (quotas / réserves), éventuellement le filleul est mis dans la liste des sponsors.
- un mot de remerciement est écrit par le filleul au parrain sur `ard` **ET** ceci est dédoublé dans un chat filleul / sponsor.
- le statut du `sponsoring` est 2.

## Document `secret`
Un secret est _supprimé_ quand sa _data_ est absente / null. La suppression est donc synchronisable par changement de la version `v` : il sera purgé lors de la purge de son avatar.

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
- par convention le `st` d'un secret permanent est égal à `99999`. Un temporaire peut être rendu permanent par :
  - l'avatar propriétaire pour un secret personnel.
  - un des animateurs pour un secret de groupe.
- un secret temporaire ne peut pas avoir de fichiers attachés.

_data_:
- `id` : id de l'avatar ou du groupe.
- `ids` : identifiant relatif à son avatar.
- `v` : sa version.

- `st` :
  - `99999` pour un _permanent_.
  - `dlv` pour un _temporaire_.
- `im` : exclusivité dans un groupe. L'écriture et la gestion de la protection d'écriture sont restreintes au membre du groupe dont `im` est `x`. 
- `p` : 0: pas protégé, 1: protégé en écriture.
- `v1` : volume du texte
- `v2` : volume total des fichiers attachés
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
- `refs` : couple `[id, ids]` crypté par la clé du secret référençant un autre secret _référence de voisinage_ qui par principe, lui, n'aura pas de `refs`).

**_Remarque :_** un secret peut être explicitement supprimé. Afin de synchroniser cette forme particulière de mise à jour pendant un an (le délai maximal entre deux login), le document est conservé _zombi_ avec un _data_ absente / null. Il ne sera purgé qu'avec son avatar / groupe.

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

En imaginant un stockage sur file system,
- il y a un répertoire par réseau,
- pour chacun, un répertoire par avatar / groupe ayant des secrets ayant des fichiers attachés,
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
- `imh`: indice membre de l'avatar hébergeur. `idhg` : id du **compte** hébergeur crypté par la clé du groupe.
- `dfh`: (dans `versions`) la date de fin d'hébergement qui vaut 0 tant que groupe est hébergé.

Le compte peut mettre fin à son hébergement:
- `dfh` indique le jour de la fin d'hébergement. Les secrets ne peuvent plus être mis à jour _en croissance_ quand `dfh` existe. 
- à `dfh`, le GC plonge le groupe en état _zombi_, _data_ et `dfh` sont absents / 0.
- `dlv` est mis à la date du jour + 365.
- les secrets et membres sont purgés.
- le groupe est _ignoré_ en session, comme s'il n'existait plus et est retiré au fil des login des maps `lgrk` des avatars qui le référencent (ce qui peut prendre jusqu'à un an).
- le document `groupe` sera effectivement détruit par le GC à `dlv`.
- ceci permet aux sessions de ne pas risquer de trouver un groupe dans des `lgrk` d'avatar sans `groupe` (sur dépassement de `dlv`, les login sont impossibles).

**Les membres d'un groupe** reçoivent lors de leur création (quand ils sont pressentis) un indice membre `ids` :
- cet indice est attribué en séquence : le premier membre est celui du créateur du groupe a pour indice 1.
- le statut de chaque membre d'index `ids` est stocké dans `ast[ids]`

_data_:
- `id` : id du groupe.
- `v` : version, du groupe, ses secrets, ses membres. 
- `iv`

- `stx` : 1-ouvert (accepte de nouveaux membres), 2-fermé (ré-ouverture en vote)
- `sty` : 0-en écriture, 1-protégé contre la mise à jour, création, suppression de secrets.
- `ast` : array des statuts des membres (dès qu'ils ont été pressentis) :
  - 10: pressenti, 
  - 20,21,22: invité en tant que lecteur / auteur / animateur, 
  - 30,31,32: actif (invitation acceptée) en tant que lecteur / auteur / animateur, 
  - 40: invitation refusée,
  - 50: suspendu, 
  - 0: disparu / oublié.
- `idhg` : id du compte hébergeur crypté par la clé du groupe.
- `imh` : indice `im` du membre dont le compte est hébergeur.
- `mcg` : liste des mots clés définis pour le groupe cryptée par la clé du groupe cryptée par la clé du groupe.
- `cvg` : carte de visite du groupe cryptée par la clé du groupe `{v, photo, info}`. 

## Document `membre`
_data_:
- `id` : id du groupe.
- `ids`: identifiant, indice de membre relatif à son groupe.
- `v`
- `dlv` : date de dernière signature + 365 lors de la connexion du compte de l'avatar membre du groupe.

- `ddi` : date de la dernière invitation
- `dda` : date de début d'activité (jour de la première acceptation)
- `dfa` : date de fin d'activité (jour de la dernière suspension)
- `npi` : 0: accepte d'être invité, 1: ne le souhaite pas.
- `vote` : vote de réouverture.
- `mc` : mots clés du membre à propos du groupe.
- `infok` : commentaire du membre à propos du groupe crypté par la clé K du membre.
- `datag` : données, immuables, cryptées par la clé du groupe :
  - `nom` `cle` : nom complet de l'avatar.
  - `ni` : numéro aléatoire d'invitation du membre. Permet de supprimer l'invitation et d'effacer le groupe dans son avatar (clé de `lgrk`).
	- `idi` : id du membre qui l'a _pressenti_.
- `cvm` : carte de visite du membre `{v, photo, info}` cryptée par la clé du membre.

### Cycle de vie
- un document `membre` existe dans tous les états SAUF 0 _disparu / oublié_.
- un auteur d'un secret `disparu / oublié`, apparaîtra avec juste un numéro (sans nom), sans pouvoir voir son membre dans le groupe.

**Pressenti suite à un premier contact par un membre du groupe**
- le membre du groupe qui l'a pressenti, lui a attribué un index (taille de `ast` du groupe) et a marqué le statut _pressenti_ dans cet `ast`.
- son id ne figure pas dans le `datag` d'un autre membre: un même avatar ne peut pas figurer plus d'une fois dans un groupe..
- dans `membre` seul `datag` est significatif. 

**Invité suite à une invitation par un animateur**
- invitation depuis un état _pressenti_ ou _suspendu_
- son statut dans `ast` passe à 20, 21, ou 22.
- dans `membre` `datag` et `ddi` sont significatifs.
- si `dda` ou `dfa`, 
  - c'est une ré-invitation après suspension : présent dans `lgrk` et dans `membre` `mc infok` peuvent être présents.

**Pressenti suite à un retrait d'invitation par un animateur**
- retrait invitation depuis un état _invité_
- son statut dans `ast` passe à 10.
- dans `membre` seuls `datag` et `ddi` sont significatifs. 

**Actif suite à l'acceptation d'une invitation par le membre**
- son statut dans `ast` passe à 30, 31, ou 32.
- dans membre :
  - `dda` : date de première acceptation est remplie si elle ne l'était pas.
  - toutes les propriétés sont significatives.
  - la carte de visite `cvm` est remplie.
- le groupe est inscrit dans l'avatar du membre (`lgrk`).

**Mises à jour des cartes de visite des membres**
- en session, lorsque la page listant les membres d'un groupe est ouverte, elle envoie une requête au serveur donnant la liste des couples [id, v] des ids des membres et de leur version de carte de visite détenue dans le row membre.
- pour chacune ayant une version postérieure, le serveur la met à jour dans membre.
- ceci permet de voir en session des cartes de visite toujours à jour et d'éviter d'effectuer une opération longue à chaque mise à jour de carte de visite par un avatar membre.

**Refus d'invitation par le membre**
- depuis un état _invité_.
- son statut dans `ast` passe à 40.
- si `dda` ou `dfa`, 
  - c'est une ré-invitation après suspension : présent dans `lgrk` et dans `membre` `mc infok` peuvent être présents.
- sinon il n'a jamais été actif, groupe absent de `lgrk`.
- dans `membre` rien ne change : `cvm` est toujours vide.

**Oubli**
- depuis un état _pressenti, invité, actif, suspendu_
- soit en tant que refus d'invitation, soit comme résiliation ou auto-résiliation forte, soit comme effacement après suspension.
- son statut dans `ast` passe à 0. Son index ne sera **jamais** réutilisé.
- son document `membre` est purgé. En session un document `membre` correspondant à un `ast` 0 dans son groupe, met le membre en _zombi.
- le groupe est effacé dans `lgrk` de son avatar.

**Suspension d'un membre**
- depuis un état _actif_. Auto-suspension ou par un animateur.
- son statut passe à _suspendu_ dans `ast` de son groupe.
- dans son document `membre` :
  - `dfa` est positionnée à la date du jour.
  - `cvm` est effacée et ne sera plus mise à jour.
- différences avec un état _pressenti_: l'avatar membre sait par `lgrk` qu'il a été actif dans le groupe, a encore des mots clés, une information et peut être ré-invité. Dans `membre` `npi, vote, cvm` sont absents.

**Disparitions d'un membre**
- un membre est _disparu_ quand sa `dlv` est dépassée.
- le GC quotidien le purge et met son statut à _disparu_ dans `ast` de son groupe.
- en session ou en serveur, dès que `dlv` est dépassée, le row est supposé inexistant (_zombi).
- pour le groupe il est donc _oublié_.
- son avatar principal ayant disparu et les avatars secondaires devant aussi disparaître, la présence dans lgrk n'est plus considéré.

## Objet `compteurs`
- `j` : **date du dernier calcul enregistré** : par exemple le 17 Mai de l'année A
- **pour le mois en cours**, celui de la date ci-dessus :
  - `v1 v1m` volume v1 des textes des secrets : 1) moyenne depuis le début du mois, 2) actuel, 
  - `v2 v2m` volume v2 de leurs pièces jointes : 1) moyenne depuis le début du mois, 2) actuel, 
  - `trm` cumul des volumes des transferts de pièces jointes : 14 compteurs pour les 14 derniers jours.
- **quotas v1 et v2** `q1 q2` : les plus élevés appliqués le mois en cours.
- `rtr` : ratio de la moyenne des tr / quota v2
- **pour les 12 mois antérieurs** `hist` (dans l'exemple ci-dessus Mai de A-1 à Avril de A),
  - `q1 q2` les quotas v1 et v2 appliqués dans le mois.
  - `r1 r2` le pourcentage du volume moyen dans le mois par rapport au quota: 1) pour v1, 2) por v2.
  - `r3` le pourcentage du cumul des transferts des pièces jointes dans le mois par rapport au volume v2.

Les _ratios_ sont exprimés en pourcentage de 1 à 255% : mais 1 est le minimum (< 1 fait 1) et 255 le maximum.

## Mots clés, principes et gestion
Les mots clés sont utilisés pour :
- filtrer / caractériser à l'affichage les **groupes (membres)** accédés par un compte.
- filtrer / caractériser à l'affichage les **secrets**, personnels ou partagés avec un groupe.

La définition des mots-clés (avatar et groupe) est une map :
- _clé_ : indice du mot-clé de 1 à 255,
- _valeur_ : texte `catégorie/label du mot-clé`.

Affectés à un membre ou secret, c'est un array de nombre de 1 à 255 (Uin8Array)

## Signatures des avatars dans `avatar` et `membre` / `groupe`
Les comptes sont censés avoir au maximum 365 jours entre 2 connexions faute de quoi ils sont considérés comme disparus.

Les `dlv` (date limite de validité) sont exprimées en nombre de jours depuis le 1/1/2020 (un mercredi) : elles signalent que ce jour-là, l'avatar sera considéré comme _disparu_.

A chaque connexion d'un compte, son avatar principal _prolonge_ les `dlv` de :
- son propre avatar.
- ses avatars secondaires,
- des groupes et membres auxquels ses avatars sont invités ou actifs. Le fait de gérer une `dlv` par _membre_ permet aux lecteurs d'un groupe de détecter les disparus (ou _proche de leur disparition_) et de mettre à jour leur statut.

La `dlv` est également gérée:
- pour un avatar: à sa création.
- pour un groupe: à sa création et à l'acceptation de l'invitation d'un membre.

>Les `dlv` ne sont pas _prolongées_ si le document `comptas` de l'avatar principal ou de sa `tribus` font l'objet d'une procédure de blocage.

**Règles:** 
- les `dlv` sont gérées par _décade_ : une `dlv` est toujours définie ou reculée à un multiple de 10 jours.
- ceci évite de multiplier des mises à jour en cas de connexions fréquentes et de faire des rapprochements entre avatars / groupes en fonction de leur dernière date-heure de connexion.
- si l'avatar principal a sa `dlv` repoussée à 1510 par exemple, ses autres avatars et ses membres / groupes seront reculés à 1520.
- les avatars secondaires seront en conséquence _non disparus_ pendant 10 jours alors que leur compte ne sera plus connectable :
  - les cartes de visite apparaîtront comme _disparues_ 10 jours avant leur `dlv` quand elles concernent un avatar secondaire.
  - les groupes pourront avoir des membres marqués _disparus_ 10 jours avant leur `dlv` quand ils se rapportent à un avatar secondaire.
  - les chats pourront pendant 10 jours être adressés à des avatars qui n'ont plus aucune possibilité de les lire.

## Disparition _explicite_ d'un avatar
Pour un avatar primaire, tous les avatars secondaires doivent être préalablement supprimés.

Pour un avatar secondaire, l'opération exécute :
- pour chaque groupe dont il est membre :
  - s'il est le dernier membre _actif_, le groupe est mis en _zombi_.
  - sinon, son statut est mis à _disparu_ et s'il était hébergeur, la date de fin d'hébergement est positionnée.
- l'avatar est retiré de la liste des avatars de son compte.
- l'avatar est purgé, ses sous-collections sont inscrites dans le singleton `gc` pour être purgées au prochain GC.

Pour un avatar principal, de plus :
- la comptabilité de sa tribu est créditée des quotas du compte supprimé.
- si le compte était parrain il est retiré de la liste.
- suppression de `comptas`.

## Récupération des quotas d'un compte détecté disparu par le GC
Le compte est détecté disparu par le GC sur sa `dlv`. Le GC consulte la compta du compte avant de la purger et écrit un document `gcvols` identifié par le cryptage du `[nom, clé]` de la tribu par la clé publique du comptable.

A sa prochaine connexion, la session du comptable lit la collection `gcvols` et pour chaque document:
- identifie la tribu en décryptant `trcp`,
- met à jour les compteurs de quotas alloués / libres,
- détruit le document.

# GC quotidien
Délais :
- N1 : 370 jours, un peu plus d'un an. Inactivité d'un compte.
- N2 : 90 jours. Délai de survie d'un groupe sans hébergeur.

Le GC quotidien a un _point de reprise_ enregistré dans le document singleton `checkpoints`.
- date du jour de GC
- array des date-heures de fin des étapes terminées.
- _purge1_ : liste des ids des avatars et groupes dont les **sous-collections** sont à purger.
- _purge2_ : liste des `[id, idf]` des fichiers à purger dans le Storage.

Quand le GC est lancé,
- soit il part sur un nouveau traitement quotidien si le dernier a eu toutes ses étapes terminées et que le jour courant est postérieur au dernier jour du traitement.
- soit il part en reprise à l'étape qui suit la dernière terminée.

Le GC quotidien effectue les activités de nettoyage suivantes :

#### Etape 1
Une transaction pour chaque groupe ayant dépassé leur `dfh` ou leur `dlv`:
- mise en état _zombi_ du groupe. Ce changement d'état est synchronisé. 
  - les sessions ouvertes et accédant à ces groupes, émettront une opération pour retirer le groupe de la liste des groupes de leur avatar.
  - les sessions s'ouvrant postérieurement feront la même opération au chargement initial
- inscription de l'id du groupe dans la liste _purge1_.
- inscription des couples `id, idf` dans la liste _purge2_ des fichiers externes à purger.

#### Etape 1b
Une transaction pour chaque membre `id, ids` ayant dépassé leur `dlv`:
- dans son groupe `id`, `ast[ids]` est mis à 0, `v` est incrémentée et la synchronisation est effectuée.
- le membre est purgé.

#### Etape 2
Une transaction par avatar principal ayant dépassé sa `dlv`
- suppression de l'avatar et de la compta.
- création d'un `gcvol` pour que le comptable puisse récupérer les quotas lors de sa prochaine connexion.
- inscription de l'id de l'avatar dans la liste _purge1_.
- inscription des couples `id, idf` dans la liste _purge2_ des fichiers externes à purger.
- pas de synchronisation.

#### Etape 3
Pour chaque document de `dlv` obsolète de `transferts`, inscription de ce fichier dans _purge2_.

#### Etape 4
- purge progressive des fichiers listés dans _purge2_ : `gc` est mis à jour avec une liste raccourcie à chaque batch de suppressions.
- purge progressive des sous-collections des avatars et groupes listés dans _purge1_ : `gc` est mis à jour avec une liste raccourcie à chaque batch de suppressions.

**_Remarque_** : l'avatar principal d'un compte est toujours détruit physiquement avant ses avatars secondaires puisqu'il apparaît plus ancien que ses avatars dans l'ordre des signatures. Le compte n'étant plus accessible par son avatar principal, ses avatars secondaires ne seront plus signés ni les groupes auxquels ils accédaient.

# Synchronisations des sessions
Chaque session détient localement le sous-ensemble des données de la portée bien délimitée qui la concerne: en mode synchronisé les documents sont stockés en base IndexedDB (IDB) avec le même contenu qu'en base centrale.

L'état en session est conservé à niveau en _s'abonnant_ à un certain nombre de documents et de sous-collections:
- (1) les documents `avatars comptas` de l'id du compte
- (2) le document `tribus` de l'id de la tribu du compte - connu par (1)
- (3) les documents `avatars` des avatars du compte - listé par (1)
- (4) les documents `groupes` des groupes dont les avatars sont membres - listés par (3)
- (5) les sous-collections `secrets chats sponsorings` des avatars - listés par (3)
- (6) les sous-collections `membres secrets` des groupes - listés par (4)

Au cours d'une session au fil des synchronisations, la portée va donc évoluer depuis celle déterminée à la connexion:
- des documents ou collections de documents nouveaux sont ajoutés à IDB (et en mémoire de la session),
- des documents ou collections sont à supprimer de IDB (et de la mémoire de la session).

### Cas du comptable pour les tribus
La session ne s'abonne à la collection `tribus` qu'au début d'un processus de gestion des tribus, puis se désabonne à la fin du processus.
- si ce processus reprend, la session rafraîchit son état en mémoire par une requête incrémentale sur la version des tribus et se réabonne.

### Cartes de visites
**Les cartes de visite des membres des groupes** auxquels la session participe sont mémorisées (en autant d'exemplaires que de groupes auxquels un membre appartient), dans le document membre: les sous-collections `membres` étant synchronisées, les cartes de visite sont à jour.

**Chaque avatar a des chats avec d'autres avatars:**
- à la connexion, une session liste les chats existants et met à jour IDB et son état mémoire avec les nouvelles versions des cartes de visite. IDB conserve les cartes de visites des interlocuteurs de chat des avatars.
- il n'y a pas d'abonnements sur ces cartes de visites, elles peuvent être nombreuses et l'information reste _indicative_.
- au début d'un processus de consultation des chats, la session _peut_ faire rafraîchir incrémentalement les cartes de visite (toujours sans abonnement).

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
lecture de `config`

écriture de `config`

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
Deux implémentations sont disponibles :
- **SQL** : elle utilise une base de données SQLite comme support de données persistantes :
  - elle s'exécute sur un serveur HTTPS dans un environnement **node.js**.
  - un serveur Web distinct sert l'application Web front-end.
  - les backups de la base sont par exemple stockés sur un Storage.
  - le Storage des fichiers peut-être,
    - soit un file-system local du serveur,
    - soit un Storage S3 (éventuellement minio).
    - soit un Storage Google Cloud Storage.
- **Firestore** : un stockage persistant Google Firestore
  - en mode serveur, un GAE de type node.js sert de serveur
  - son stockage est assurée par le Firestore.
  - le Storage est Google Cloud Storage

Un utilitaire **node.js** local peut accéder à un Firestore distant:
- exporte un Firestore distant (ou local de test) dans une base SQLite locale.
- importe dans un Firestore distant (ou local de test) vide une base SQLite locale.
