# API : opérations supportées par le serveur

Les opérations sont invoquées sur l'URL du serveur : `https://.../op/MonOp1`
- **GET** : le vecteur des arguments nommés sont dans le queryString :
  `../op/MonOp1&arg1=v1&arg2=v2 ...`
  Ils se retrouvent à disposition dans l'opération dans l'objet `args` :
  { **arg1**: v1, arg2: v2 }
- **POST** : le body de la requête est la sérialisation de l'array `[args, apitk]` :
  - `args` : `{ arg1: v1, arg2: v2 ... }`
  - `apitk` : string donnant l'autorisation du client à utiliser l'API. Cette information figure en configuration du serveur et côté client dans `process.env.APITK` qui a été forcée lors du build webpack.

### `args.token` : le jeton d'authentification du compte
Requis dans la quasi totalité des requêtes ce jeton est formé par la sérialisation de la map `{ sessionId, shax, hps1 }`:
- `sessionId` : identifiant aléatoire (string) de session générée par l'application pour s'identifier elle-même (et transmise sur WebSocket en implémentation SQL).
- `shax` : SHA256 du PBKFD de la phrase secrète en UTF-8.
- `hps1` : Hash (sur un entier _safe_ en Javascript) du SHA256 de l'extrait de la phrase secrète.

L'extrait consiste à prendre certains bytes du début de la représentation en UTF-8 de la phrase complète précédée du code de l'organisation.

### Headers requis
- `origin` : site Web d'où l'application Web a été chargée. Au cas ou `origin` ne peut pas être obtenu, c'est `referer` qui est considéré. Les origines autorisées sont listées dans `config.mjs`.
- `x-api-version` : numéro de version de l'API pour éviter un accès par des sessions ayant été chargées par une application _retardée_ par rapport au serveur.

### Retour des requêtes
- status HTTP 200 : OK
- status HTTP 400 401 402 403 : exceptions trappées par le serveur ,:
  - 400 : F_SRV fonctionnelles
  - 401 : A_SRV assertions
  - 402 : E_SRV exception inattendue trappée dans le traitement
  - 403 : E_SRV exception inattendue NON trappée dans le traitement
  - le texte de l'erreur est un texte JSON : `{ code, args: [], stack }`
  - à détection au retour d'une requête, une exception `AppExc` est générée depuis ces données.
- autre statuts (500, 0 ...) : une exception `AppExc` est générée (E_SRV, 0, ex.message)

#### Retour OK d'un GET
- requête `/fs` : retour 'true' si le serveur implémente Firestore, 'false' s'il implémente SQL.
- requêtes `/op/yo` et `op/yoyo` : texte.
- autres requêtes : `arrayBuffer` (binaire).

#### Retour OK d'un POST
Le terme binaire est désérialisé, on en obtient une map dont les éléments sont :
- de manière générique :
  - `dh` : le getTime de l'exécution de la transaction,
  - `sessionId` : la valeur de sessionId passée dans le token en argument ou 666
  - les autres termes sont spécifiques du _retour_ de chaque opération.

## Opérations SANS authentification
### `fs` : mode du serveur
En fait N'EST PAS une opération.

GET - pas d'arguments `../fs`

Retour 'true' si le serveur implémente Firestore, 'false' s'il implémente SQL. Ceci évite dans le code de l'application d'avoir à configurer si la synchronisation est de type SQL (par WebSoket) ou Firestore, la découverte se faisant en runtime.

### `yo` : ping du serveur
GET - pas d'arguments `../op/yo`

Ping du serveur SANS vérification de l'origine de la requête.

Retourne 'yo' + la date et l'heure UTC

### `yoyo` : ping du serveur
GET - pas d'arguments `../op/yoyo`

Ping du serveur APRÈS vérification de l'origine de la requête.

Retourne 'yoyo' + la date et l'heure UTC

### `EchoTexte` : retourne le texte passé en argument
POST:
- `to` : délai en secondes avant retour de la réponse
- `texte` : texte à renvoyer en écho OU en détail de l'erreur fonctionnelle testée

Retour:
- `echo` : texte d'entrée retourné

### `ErreurFonc` : simule une erreur fonctionnelle
POST:
- `to` : délai en secondes avant retour de la réponse
- `texte` : détail de l'erreur fonctionnelle testée

Exception:
- `F_SRV 1` : en détail le texte passé en argument.

### `PingDB` : teste l'accès à la base de données
POST - pas d'arguments

Retour : 
- `OK` : true

Exception: si la base n'est pas accessible.

### `GetPub` : retoune la clé publique d'un avatar
POST:
- `id` : id de l'avatar

Retour:
- `pub` : clé publique de l'avatar ou null si l'avatar n'existe pas

### `ChercherSponsoring` : recherche sponsoring par le hash de sa phrase de contact
POST:
- `ids` : hash de la phrase de contact.

Retour:
- `rowSponsoring` : le row s'il existe

### ExistePhrase : cherche le hash d'une phrase et détermine son existence
POST:
- `ids` : hash de la phrase de contact / de connexion.
- `t` :
  - 1 : phrase de connexion (`hps1` de `comptas`)
  - 2 : phrase de sponsoring (`ids` de `sponsorings`)
  - 3 : phrase de contact (`hpc` de `avatars`)

Retour:
- `existe` : `true` si le hash de la phrase existe.

## Opérations authentifiées par l'administrateur

### Documents: les formats _row_ et _compilé_
Que ce soit en SQL ou en Firestore, l'insertion ou la mise à jour d'un document se fait depuis un _objet Javascript_ ou chaque attribut correspond à une propriété de l'objet. 

Par exemple un document tribus pour mise à jour en SQL ou Firestore est celui-ci : 

    { id: 3200...00, v: 4, _data_: (Uint8Array) }

Pour avoir le format _row_ une propriété _nom a été ajoutée : `{ _nom: 'tribus', id ... }`

Ce format _row_ est celui utilisé entre session UI et serveur, dans les arguments d'opérations et en synchronisation.

#### Format _compilé_
Les attributs _data_ contiennent toutes les propriétés sérialisées, celles externalisées `id v ...` et celles internes. 

- la fonction `tribu = compile(row)` désérialise le contenu de _data_ d'un objet row et retourne une instance `tribu` de la classe correspondant au nom (par exemple `Tribus` qui hérite de la classe `GenDoc`) avec les attributs externalisés `id v` et ceux internes sérialisés dans _data_. Si _data_ est `null`, il est reconstitué avec les seules propriétés externalisées et la propriété `_zombi` à `true`. Le serveur peut effectuer des calculs depuis tous les attributs.
- la méthode `row = tribu.toRow()` reconstitue un objet au format _row_ depuis une instance `tribu`.

En session UI le même principe est adopté avec deux différences : 
- `compile()` sur le serveur est **synchrone et unique** (il n'y a pas d'implémentations pour chaque sous-classe de `GenDoc`).
- en session `async compile()` est à écrire pour chaque classe : les méthodes effectuent des opérations de cryptage / décryptage asynchrones et de calculs de propriétés complémentaires spécifiques de chaque classe de document.
- en session il n'y a pas d'équivalent à `toRow()`. Pour des créations de document la construction s'effectue directement en format _row_ et non sur un objet qui serait sérialisé ensuite. 

### `CreerEspace` : création d'un nouvel espace et du comptable associé
POST:
- `token` : jeton d'authentification du compte de **l'administrateur**
- `rowEspace` : row de l'espace créé
- `rowSynthese` : row `syntheses` créé
- `rowAvatar` : row de l'avatar du comptable de l'espace
- `rowTribu` : row de la tribu primitive de l'espace
- `rowCompta` : row du compte du Comptable
- `rowVersion`: row de la version de l'avatar (avec sa dlv)
- `hps1` : hps1 de la phrase secrète

Retour: rien si OK (sinon exceptions)

Règles de gestion à respecter par l'appelant
- tous les rows passés en argument doivent être cohérents entre eux et se rapporter au nouvel espace à créer. Rien n'est vérifiable ni vérifié  par l'opération.

### `SetNotifG` : déclaration d'une notification à un espace par l'administrateur
POST:
- `token` : jeton d'authentification du compte de **l'administrateur**
- `ns` : id de l'espace notifié
- `notif` : sérialisation de l'objet notif, cryptée par la clé du comptable de l'espace. Cette clé étant publique, le cryptage est symbolique et vise seulement à éviter une lecture simple en base.
  - `idSource`: id du Comptable ou du sponsor, par convention 0 pour l'administrateur.
  - `jbl` : jour de déclenchement de la procédure de blocage sous la forme `aaaammjj`, 0 s'il n'y a pas de procédure de blocage en cours.
  - `nj` : en cas de procédure ouverte, nombre de jours après son ouverture avant de basculer en niveau 4.
  - `texte` : texte informatif, pourquoi, que faire ...
  - `dh` : date-heure de dernière modification (informative).

Retour: 
- `rowEspace` : le row espaces mis à jour.

### `SetEspaceT` : déclaration du profil de volume de l'espace par l'administrateur
POST:
- `token` : jeton d'authentification du compte de **l'administrateur**
- `ns` : id de l'espace notifié.
- `t` : numéro de profil de 0 à N. Liste spécifiée dans config.mjs de l'application.

Retour: rien

## Opérations authentifiées par un compte Comptable ou sponsor de sa tribu

### `AjoutSponsoring` : déclaration d'un nouveau sponsoring par le comptable ou un sponsor
POST:
- `token` : éléments d'authentification du comptable / compte sponsor de sa tribu.
- `rowSponsoring` : row Sponsoring, SANS la version (qui est calculée par le serveur).

Retour: rien

Exceptions:
- `F_SRV 7` : un sponsoring identifié par une même phrase (du moins son hash) existe déjà.

Assertion sur l'existence du compte.

Règles de gestion à respecter par l'appelant:
- le row sponsoring doit être cohérent.
- le compte déclarant doit être le Comptable ou un sponsor de la tribu.
- le serveur ne peut pas vérifier ces informations.

### `ProlongerSponsoring` : prolongation d'un sponsoring existant
Change la date limite de validité du sponsoring pour une date plus lointaine. Ne fais rien si le sponsoring n'est pas _actif_ (hors limite, déjà accepté ou refusé).
POST:
- `token` : éléments d'authentification du comptable / compte sponsor de sa tribu.
- `id ids` : identifiant du sponsoring.
- `dlv` : nouvelle date limite de validité `aaaammjj`ou 0 pour une  annulation.

Retour: rien

Assertion sur l'existence du sponsoring.

## Opération NON authentifiée de REFUS de connexion par un compte

### `RefusSponsoring` : refus de son sponsoring par le _sponsorisé_
Change le statut du _sponsoring_ à _refusé_. Ne fais rien si le sponsoring n'est pas _actif_ (hors limite, déjà accepté ou refusé).
POST:
- `ids` : identifiant du sponsoring, hash de la phrase de contact.
- `ardx` : justification / remerciement du _sponsorisé à stocker dans le sponsoring.

Retour: rien.

Exceptions:
- `F_SRV 8` : le sponsoring n'existe pas.

Assertion sur l'existence du compte sponsor.

## Opérations authentifiées de création de compte et connexion
**Remarques:**
- le compte _Administrateur_ n'est pas vraiment un compte mais simplement une autorisation d'applel des opérations qui le concernent lui seul. Lehash de sa phrase secrète est enregistrée dans la configuration du serveur.
- le compte _Comptable_ de chaque espace est créé par l'administrateur à la création de l'espace. Ce compte est normal. Sa phrase secrète a été donnée par l'administrateur et le comptable est invité à la changer au plus tôt.
- les autres comptes sont créés par _acceptation d'un sponsoring_ qui fixe la phrase secrète du compte qui se créé : après cette opération la session du nouveau compte est normalement active.
- les deux opérations suivantes sont _authentifiées_ et transmettent les données d'authentification par le _token_ passé en argument porteur du has de la phrase secrète: dans le cas de l'acceptation d'un sponsoring, la reconnaissance du compte précède de peu sa création effective.

### `AcceptationSponsoring` : création du compte du _sponsorisé_
POST:
- `token` : éléments d'authentification du compte à créer
- `rowCompta` : row du compte à créer.
- `rowAvatar` : row de son avatar principal.
- `rowVersion` : row de avatar en création.
- `idt` : id de sa tribu.
- `ids` : ids du sponsoring, hash de sa phrase de reconnaissance qui permet de retrouver le sponsoring.
- `rowChatI` : row chat _interne_ pour le compte en création donnant le message de remerciement au sponsor.
- `rowChatE` : row chat _externe_ pour le sponsor avec le même message. La version est obtenue par le serveur.
- `ardx` : texte de l'ardoise du sponsoring à mettre à jour (avec statut 2 accepté), copie du texte du chat échangé.
- `act`: élément de la map act de sa tribu
- **SI quotas à prélever** sur le COMPTE du sponsor,
- `it` : index de ce compte dans la tribu
- `q1 q2` : quotas attribués par le sponsor.

Retour: rows permettant d'initialiser la session avec le nouveau compte qui se trouvera ainsi connecté.
- `rowTribu`
- `rowChat` : le chat _interne_, celui concernant le compte.
- `credentials` : données d'authentification permettant à la session d'accéder au serveur de données Firestore.
- `rowEspace` : row de l'espace, informations générales / statistiques de l'espace et présence de la notification générale éventuelle.

Exceptions:
- `F_SRV, 8` : il n'y a pas de sponsoring ayant ids comme hash de phrase de connexion.
- `F_SRV, 9` : le sponsoring a déjà été accepté ou refusé ou est hors limite.

Assertions:
- existence de la tribu,
- existence de l'avatar du compte sponsor.

### ConnexionCompte : connexion authentifiée à un compte
Enregistrement d'une session et retour des données permettant à la session cliente de s'initialiser.

L'administrateur utilise cette opération pour se connecter mais le retour est différent.

POST:
- `token` : éléments d'authentification du compte.

Retour, sauf _administrateur_:
- `rowAvatar` : row de l'avatar principal du compte
- `rowCompta` : row compta du compte.
- `rowEspace` : row de l'espace (informations générales / statistques de l'espace et présence de la notification générale éventuelle.
- `credentials`: données d'authentification pour utilisation de l'API Firestore dans l'application cliente (absente en mode SQL)

Retour, pour _administrateur_:
- `admin` : `true` (permet en session de reconnaître une connexion d'administration).
- `espaces` : array des rows de tous les espaces.

## Opérations authentifiées pour un compte APRES sa connexion
Ces opérations permettent à la session cliente de récupérer toutes les données du compte afin d'initialiser son état interne.

### `GetEspace` : get de l'espace du compte de la session
POST:
- `token` : éléments d'authentification du compte.
- `ns` : id de l'espace.

Retour:
- `rowEspace`

### `GetSynthese` : retourne la synthèse de l'espace
POST:
- `token` : éléments d'authentification du compte.
- `ns` : id de l'espace.

Retour:
- `rowSynthse`

### `SetStats` : déclaration des statistiques de l'espace par son Comptable
A sa connexion, le **comptable** agrège les compteurs statistiques de **toutes les tribus de l'espace** et les soumet au serveur pour stockage dans le document de l'espace.

POST:
- `token` : jeton d'authentification du comptable de l'espace.
- `ns` : id de l'espace
- `stats` : sérialisation de l'objet portant les compteurs statistiques de l'espace:
  - `ntr` : nombre de tribus
  - `a1 a2` : somme des quotas _attribués aux comptes_ des tribus.
  - `q1 q2` : somme des quotas actuels des tribus
  - `nbc` : nombre de comptes.
  - `nbsp` : nombre de sponsors.
  - `ncoS` : nombres de comptes ayant une notification simple.
  - `ncoB` : nombres de comptes ayant une notification bloquante.

Retour: rien

### `GestionAb` : gestion des abonnements
Toutes les opérations permettent de modifier la liste des abonnements,
- `abPlus` : liste des avatars et groupes à ajouter,
- `abMoins` : liste des abonnements à retirer.

Cette opération permet de mettre à jour la liste des abonnements de la session alors qu'elle n'a aucune autre action à effectuer.

POST:
- `token` : éléments d'authentification du compte.
- `abPlus abMoins`.

Retour: rien.

### `GetAvatars` : retourne les documents avatar dont la version est postérieure à celle détenue en session
POST:
- `token` : éléments d'authentification du compte.
- `vcompta` : version de compta qui ne doit pas avoir changé depuis le début de la phase de connexion. Si la version actuelle de compta est postérieure, le retour de `OK` est false.
- `mapv` : map des avatars à charger.
  - _clé_ : id de l'avatar, 
  - _valeur_ : version détenue en session. Ne retourner l'avatar que si sa version est plus récente que celle-ci.

Retour:
- `OK` : si la version de compta n'a pas changé
- `rowAvatars`: array des rows des avatars dont la version est postérieure à celle indiquée en arguments.

### GetAvatar : retourne le row avatar le plus récent
POST:
- `token` : éléments d'authentification du compte.
- `id` : id de l'avatar

Retour:
- `rowAvatar`: row de l'avatar.

Assertion sur l'existence de l'avatar.

### `GetTribu` : retourne le row tribu le plus récent
Et optionnellement déclare cette tribu comme _courante_, c'est à dire abonne la session à cette tribu (après détection d'un changement de tribu).

POST:
- `token`: éléments d'authentification du compte.
- `id` : id de la tribu.
- `tribu2` : true si retourner tribu2 aussi.
- `setC`: si true, déclarer la tribu courante.

Retour:
- `rowtribu` : row de la tribu.
- `rowTribu2`

Assertions sur l'existence des rows tribu et tribu2.

### GetGroupe : retourne le row groupe le plus récent 
POST:
- `token`: éléments d'authentification du compte.
- `id` : id du groupe.

Retour:
- `rowGroupe`: row du groupe.

Assertion sur l'existence du row groupe.

### `GetGroupes` : retourne les documents groupes ayant une version plus récente que celle détenue en session
POST:
- `token`: éléments d'authentification du compte.
- `mapv` : map des versions des groupes détenues en session :
  - _clé_ : id du groupe  
  - _valeur_ : version détenue en session

Retour:
- `rowGroupes` : array des rows des groupes ayant une version postérieure à celle connue en session.

### `ChargerSecrets` : retourne les secrets de l'avatar / groupe id et de version postérieure à v
POST:
- `token` : éléments d'authentification du compte.
- `id` : de l'avatar ou du groupe
- `v` : version connue en session

Retour:
- `rowSecrets` : array des rows des secrets de version postérieure à v

### `ChargerChats` : retourne les chats de l'avatar id et de version postérieure à v
POST:
- `token` : éléments d'authentification du compte.
- `id` : de l'avatar
- `v` : version connue en session

Retour:
- `rowChats` : array des rows des chats de version postérieure à v

### `ChargerSponsorings` : retourne les sponsoring de l'avatar id et de version postérieure à v
POST:
- `token` : éléments d'authentification du compte.
- `id` : de l'avatar
- `v` : version connue en session

Retour:
- `rowSponsorings` : array des rows des sponsorings de version postérieure à v

### `ChargerMembres` : retourne les membres du groupe id et de version postérieure à v
POST:
- `token` : éléments d'authentification du compte.
- `id` : du groupe
- `v` : version connue en session

Retour:
- `rowMembres` : array des rows des sponsorings de version postérieure à v

### `ChargerGMS` : retourne le groupe id, ses membres et ses secrets, de version postérieure à v
POST:
- `token` : éléments d'authentification du compte.
- `id` : du groupe
- `v` : version connue en session

Retour: quand le groupe est _zombi, les row groupe, membres, secrets NE SONT PAS significatifs.
- `rowGroupe` : seulement si version postérieure à v. 
- `rowMembres` : array des rows membres de version postérieure à v.
- `rowSecrets` : array des rows des secrets de version postérieure à v.
- `vgroupe` : row version du groupe, possiblement _zombi.

**Remarque** : Le GC PEUT avoir faire disparaître un groupe (son row `versions` est _zombi) AVANT que les listes des groupes (`lgr`) dans les rows avatars membres n'aient été mises à jour. 

### `ChargerTribus` : retourne les tribus de l'espace
Pour le comptable seulement

POST:
- `token` : éléments d'authentification du compte.
- `mvtr` : map des versions des tribus détenues en session
  _clé_ : id de la tribu,
  _valeur_ : version détenue en session.

Retour :
- `rowTribus`: array des rows des tribus de version postérieure à v.
- `delids` : array des ids des tribus disparues.

### `ChargerASCS` : retourne l'avatar, ses secrets, chats et sponsorings, de version postérieure à v
POST:
- `token` : éléments d'authentification du compte.
- `id` : de l'avatar.
- `v` : version connue en session.

Retour:
- `rowSecrets` : arrays des rows des secrets chats sponsorings de version postérieure à v
- `rowChats` :
- `rowSponsorings` : 
- `rowAvatar` : seulement si de version postérieure à v.
- `vavatar` : PEUT être _zombi. Dans ce cas les autres rows n'ont pas de signification.

### `SignaturesEtVersions` : signatures des groupes et avatars
Si un des avatars a changé de version, retour en `OK` `false` : la liste des avatars doit être la même que celle précédemment obtenue en session.

Signature par les `dlv` passées en arguments des row `versions` des avatars et membres (groupes en fait).

Retourne les `versions` des avatars et groupes de la session.

POST:
- `token` : éléments d'authentification du compte.
- `vcompta` : version de compta qui ne doit pas avoir changé
- `mbsMap` : map des membres des groupes des avatars :
  - _clé_ : id du groupe  
  - _valeur_ : `{ idg, mbs: [ids], dlv }`
- `avsMap` : map des avatars du compte 
  - `clé` : id de l'avatar
  - `valeur` : `{v (version connue en session), dlv}`
- `abPlus` : array des ids des groupes auxquels s'abonner

Retour:
- `OK` : true / false si le compta ou un des avatars a changé de version.
- `versions` : map pour chaque avatar / groupe de :
  - _clé_ : id du groupe ou de l'avatar.
  - _valeur_ :
    - `{ v }`: pour un avatar.
    - `{ v, vols: {v1, v2, q1, q2} }` : pour un groupe.

Assertions sur les rows compta, avatars, versions.

### `EnleverGroupesAvatars` : retirer pour chaque avatar de la map ses accès aux groupes listés par numéro d'invitation
POST:
- `token` : éléments d'authentification du compte.
- `mapIdNi` : map
  - _clé_ : id d'un avatar
  - _valeur_ : array des `ni` (numéros d'invitation) des groupes ciblés.
  
Retour: rien.

### `RetraitAccesGroupe` : retirer l'accès à un groupe pour un avatar
POST:
- `token` : éléments d'authentification du compte.
- `id` : id de l'avatar.
- `ni` : numéro d'invitation du groupe pour cet avatar.

Retour: rien.

### `DisparitionMembre` : enregistrement du statut disparu d'un membre dans son groupe
Après détection de la disparition d'un membre.

POST:
- `token` : éléments d'authentification du compte.
- `id` : id du groupe
- `ids` : ids du membre

Retour: rien.

## Opérations du cycle de vie HORS phase de connexion et synchronisations

### `RafraichirCvs` : rafraîchir les cartes de visite, quand nécessaire
Mises à jour des cartes de visite, quand c'est nécessaire, pour tous les chats et membres de la cible.

POST:
- `token` : éléments d'authentification du compte.
- `cibles` : array de : 

    {
      idE, // id de l'avatar
      vcv, // version de la carte de visite détenue
      lch: [[idI, idsI, idsE] ...], // liste des chats
      lmb: [[idg, im] ...] // liste des membres
    }

Retour:
- `nbrech` : nombre de mises à jour effectuées.

Assertions sur l'existence des avatars et versions.

### `MemoCompte` : changer le mémo du compte
POST:
- `token` : éléments d'authentification du compte.
- `memok` : texte du mémo crypté par la clé k

Retour: néant.

Assertion d'existence de l'avatar principal et de sa `versions`.

### `MotsclesCompte` : changer les mots clés du compte
POST:
- `token` : éléments d'authentification du compte.
- `mck` : map des mots clés cryptée par la clé k.

Retour: rien.

Assertion d'existence de l'avatar principal et de sa `versions`.

### `ChangementPS` : changer la phrase secrète du compte
POST:
- `token` : éléments d'authentification du compte.
- `hps1` : dans compta, `hps1` : hash du PBKFD de l'extrait de la phrase secrète du compte.
- `shay` : SHA du SHA de X (PBKFD de la phrase secrète).
- `kx` : clé K cryptée par la phrase secrète

Retour: rien.

Assertion sur l'existence du compte (compta).

### `MajCv` : mise à jour de la carte de visite d'un avatar
Dans l'avatar lui-même et si c'est l'avatar principal du compte dans son entrée de tribu2.

POST:
- `token` : éléments d'authentification du compte.
- `id` : id de l'avatar dont la Cv est mise à jour
- `v` : version de l'avatar incluse dans la Cv.
- `cva` : `{v, photo, info}` crypté par la clé de l'avatar.
  - SI C'EST Le COMPTE, pour dupliquer la CV,
    `idTr` : id de sa tribu (où dupliquer la CV)
    `hrnd` : clé d'entrée de la map `mbtr` dans tribu2.

Retour:
- `OK` : `false` si la carte de visite a changé sur le serveur depuis la version connue en session. Il faut reboucler sur la requête jusqu'à obtenir true.

Assertion sur l'existence de l'avatar de son row versions et de la tribu2.

### `GetAvatarPC` : information sur l'avatar ayant une phrase de contact donnée
POST:
- token : éléments d'authentification du compte.
- hpc : hash de la phrase de contact

Retour: 
- `cvnapc` : `{cv, napc}` si l'avatar ayant cette phrase a été trouvée.
  - `cv` : `{v, photo, info}` crypté par la clé de l'avatar.
  - `napc` : `[nom, rnd]` de l'avatar crypté par le PBKFD de la phrase.

### `ChangementPC` : changement de la phrase de contact d'un avatar
POST:
- `token` : éléments d'authentification du compte.
- `id` : de l'avatar.
- `hpc` : hash de la phrase de contact (SUPPRESSION si null).
- `napc` : [nom, rnd] de l'avatar crypté par le PBKFD de la phrase.
- `pck` : phrase de contact cryptée par la clé K du compte.

Retour: rien.

Assertion sur l'existence de l'avatar et de sa `versions`.

### `NouveauChat` : création d'un nouveau Chat
POST:
- `token` : éléments d'authentification du compte.
- `idI idsI` : id du chat, côté _interne_.
- `idE idsE` : id du chat, côté _externe_.
- `ccKI` : clé cc du chat cryptée par la clé K du compte de I.
- `ccPE` : clé cc cryptée par la clé **publique** de l'avatar E.
- `contcI` : contenu du chat I (contient le [nom, rnd] de E), crypté par la clé cc.
- `contcE` : contenu du chat E (contient le [nom, rnd] de I), crypté par la clé cc.

Retour:
- `st` : 
  0 : E a disparu
  1 : chat créé avec le contenu contc.
  2 : le chat était déjà créé, retour de chatI avec le contenu qui existait
- `rowChat` : row du chat I créé (sauf st = 0).

Assertions sur l'existence de l'avatar I, sa `versions`, et le cas échéant la `versions` de l'avatar E (quand il existe).

### `MajChat` : mise à jour d'un Chat
POST:
- `token` : éléments d'authentification du compte.
- `idI idsI` : id du chat, côté _interne_.
- `idE idsE` : id du chat, côté _externe_.
- `ccKI` : clé cc du chat cryptée par la clé K du compte de I. _Seulement_ si en session la clé cc était cryptée par la clé publique de I.
- `contcI` : contenu du chat I (contient le [nom, rnd] de E), crypté par la clé cc.
- `contcE` : contenu du chat E (contient le [nom, rnd] de I), crypté par la clé cc.
- `seq` : numéro de séquence à partir duquel `contc` a été créé.

Retour:
- `st` : 
  1 : chat mis à jour avec le contenu `contc`.
  2 : le chat existant a un contenu plus récent que celui sur lequel était basé `contc`. Retour de chatI.
- `rowChat` : row du chat I.

Assertions sur l'existence de l'avatar I, sa `versions`, et le cas échéant la `versions` de l'avatar E (quand il existe).

### `MajMotsclesChat` : changer les mots clés d'un chat
POST:
- `token` : éléments d'authentification du compte.
- `mc` : u8 des mots clés
- `id ids` : id du chat

Retour: rien.

Assertions sur le chat et la `versions` de l'avatar id.

### `NouvelAvatar` : création d'un nouvel avatar 
POST:
- `token` : éléments d'authentification du compte.
- `rowAvatar` : row du nouvel avatar.
- `rowVersion` : row de la version de l'avatar.
- `kx vx`: entrée dans `mavk` (la ma liste des avatars du compte) de compta pour le nouvel avatar.

Retour: rien.

Assertion sur l'existence du compte.

### `MajMavkAvatar` : mise à jour de la liste des avatars d'un compte
POST:
- `token` : éléments d'authentification du compte.
- `lp` : liste _plus_, array des entrées `[kx, vx]` à ajouter dans la liste (`mavk`) du compte.
- `lm` : liste _moins_ des entrées `[kx]` à enlever.

Retour: rien.

Assertion sur l'existence du compte.

### `NouvelleTribu` : création d'une nouvelle tribu par le comptable
POST: 
- `token` : éléments d'authentification du comptable.
- `rowTribu` : row de la nouvelle tribu.
- `rowTribu2` : row de la nouvelle tribu2.

Retour: rien.

### `SetAttributTribu` : déclaration d'un attribut d'une tribu
Les deux attributs possibles sont :
- `infok` : commentaire privé du comptable crypté par la clé K du comptable.
- `notif` : notification de la tribu (cryptée par la clé de la tribu).

POST:
- `token` : éléments d'authentification du compte.
- `id` : id de la tribu
- `attr` : nom de l'attribut `infok` ou `notif`.
- `val` : nouvelle valeur de l'attribut.

Retour: rien.

Assertion sur l'existence de la tribu.

### `SetQuotasTribu` : déclaration des quotas d'une tribu par le comptable
POST:
- `token` : éléments d'authentification du compte.
- `id` : id de la tribu
- `q1 q2` : quotas de volume V1 et V2.

Retour: rien.

Assertion sur l'existence de la tribu.

### `SetAttributTribu2` : déclaration d'un attribut d'une entrée de tribu2 QUI IMPACTE tribu
Ne concerne pas la _carte de visite_ gérée par ailleurs. Pour l'instant :
- `sp` : si `true` / présent, c'est un sponsor.

 POST:
- `token` : éléments d'authentification du compte.
- `id` : id de la tribu
- `hrnd`: clé de l'élément du compte dans la map des comptes de tribu2 (`mbtr`).
- `attr` : nom de l'attribut (`sp`).
- `val` : valeur de l'attribut.

Retour: rien.

Assertion sur l'existence de la tribu et de tribu2.

### `SetQuotasCompte` : déclaration des quotas d'un compte par un sponsor de sa tribu
POST:
- `token` : éléments d'authentification du sponsor.
- `idc` : id du compte sponsorisé.
- `id` : id de sa tribu.
- `hrnd` : clé de son entrée dans la map des membres de la tribu (mbtr de tribu2).
- `q1 q2` : ses nouveaux quotas de volume V1 et V2.

Retour: rien.

Assertion sur l'existence de la tribu et de tribu2.

### `SetNotifC` : notification d'un compte par un sponsor ou le Comptable
Inscription dans tribu2 de la notification et recalcul de la synthèse dans tribu.

POST:
- `token` : éléments d'authentification du comptable ou du sponsor.
- `id` : id de la tribu
- `hrnd` : clé de son entrée dans la map des membres de la tribu (mbtr de tribu2).
- `notif`: notification du compte.
- `ntfb` : `true` si la notification est _bloquante_.

Retour: rien.

Assertion sur l'existence de la tribu et de tribu2.

### `SetDhvuCompta` : enregistrement de la date-heure de _vue_ des notifications dans une session
POST: 
- `token` : éléments d'authentification du compte.
- `dhvu` : date-heure cryptée par la clé K.

Retour: rien.

Assertion sur l'existence du compte.

### `MajNctkCompta` : mise à jour de la tribu d'un compte 
POST: 
- `token` : éléments d'authentification du compte.
- `nctk` : `[nom, rnd]` de la la tribu du compte crypté par la clé K du compte.

Retour: rien.

Assertion sur l'existence du compte.

### `GetCompteursCompta` : retourne les "compteurs" d'un compte
POST:
- `token` : éléments d'authentification du compte demandeur.
- `id` : id du compte dont les compteurs sont à retourner.

Retour:
- `compteurs` : objet `compteurs` enregistré dans `compta`.

Assertion sur l'existence du compte.

### `ChangerTribu` : changer un compte de tribu par le Comptable
POST:
- `token` : éléments d'authentification du comptable.
- `id` : id du compte qui change de tribu.
- `trIdav` : id de la tribu quittée
- `trIdap` : id de la tribu intégrée
- `hrnd` : clé de son entrée dans la map des membres de la tribu (`mbtr` de tribu2).
- `mbtr` : entrée mbtr dans sa nouvelle tribu.
- _Données concernant `compta` :_
  - `nctk` : `[nom, clé]` de la tribu crypté par la clé de la carte de visite de l'avatar principal du compte.
  - `nctkc` : `[nom, clé]` de la tribu crypté par la clé K **du Comptable**: 
  - `napt` : `[nom, clé]` de l'avatar principal du compte crypté par la clé de la tribu.

Retour: rien.

Assertions sur l'existence du compte et de ses tribus _avant_ et _après_.

## Opérations authentifiées sur la gestion des groupes

### `MajCvGr` : déclaration de la carte de visite d'un groupe
POST:
- `token` : éléments d'authentification du compte.
- `id` : id du groupe dont la carte de visite est mise à jour.
- `v` : version du groupe incluse dans la carte de visite. Si elle a changé sur le serveur, retour `OK` `false`.
- `cvg` : carte de visite du groupe {v, photo, info} crypté par la clé du groupe.

Retour:
- `OK` : si `false`, la version a changé (mises à jour concurrentes), reboucler sur la requête.

Assertions sur le groupe et sa `versions`.

### `NouveauGroupe` : création d'un nouveau groupe
POST:
- `token` : éléments d'authentification du compte.
- `rowGroupe` : row du groupe créé.
- `rowMembre` : row membre de l'avatar créateur dans ce groupe.
- `id` : id de l'avatar créateur
- `quotas` : [q1, q2] attribué au groupe.
- `kegr` : clé dans la map des groupes de l'avatar créateur (`lgrk`). Hash du `rnd` inverse de l'avatar crypté par le `rnd` du groupe.
- `egr` : élément de `lgrk` dans l'avatar créateur.

Retour: rien.

Assertions sur l'existence de l'avatar et de sa `versions`.

### `MotsclesGroupe` : déclaration des mots clés du groupe
POST:
- `token` : éléments d'authentification du compte.
- `mcg` : map des mots clés cryptée par la clé du groupe.
- `idg` : id du groupe.

Retour: rien.

Assertions sur l'existence du groupe et de sa `versions`.

### `ArdoiseGroupe` : mise à jour de l'ardoise du groupe
POST:
- `token` : éléments d'authentification du compte.
- `ardg` : texte de l'ardoise crypté par la clé du groupe.
- `idg` : id du groupe.

Retour: rien.

Assertions sur l'existence du groupe et de sa `versions`.

### `HebGroupe` : déclaration d'hébergement d'un groupe
POST: 
- `token` : éléments d'authentification du compte.
- `t` : type d'opération :
  - 1 : changement des quotas, 
  - 2 : prise d'hébergement, 
  - 3 : transfert d'hébergement.
- `idd` : (3) id du compte de départ en cas de transfert.
- `ida` : id du compte (d'arrivée en cas de prise / transfert).
- `idg` : id du groupe.
- `idhg` : (2, 3) id du compte d'arrivée en cas de transfert CRYPTE par la clé du groupe
- `q1 q2` : quotas attribués.

1-Cas changement de quotas :
- les volumes et quotas sur compta a sont inchangés.
- sur la version du groupe, q1 et q2 sont mis à jour.
2-Prise hébergement :
- les volumes v1 et v2 sont pris sur le groupe.
- les volumes (pas les quotas) sont augmentés sur compta a.
- sur la version du groupe, q1 et q2 sont mis à jour.
- sur le groupe, idhg est mis à jour.
3-Cas de transfert :
- les volumes v1 et v2 sont pris sur le groupe.
- les volumes (pas les quotas) sont diminués sur compta d.
- les volumes (pas les quotas) sont augmentés sur compta a.
- sur la version du groupe, q1 et q2 sont mis à jour.
- sur le groupe, idhg est mis à jour.

Retour: rien.

Assertions sur l'existence du groupe et de sa `versions` ainsi que le ou les comptes impactés selon le type de l'opération.

### `FinHebGroupe` : déclaration de fin d'ébergement d'un groupe
POST:
- `token` : éléments d'authentification du compte.
- `id` : id du compte.
- `idg` : id du groupe.
- `dfh` : date de fin d'hébergement.

Traitement :
- les volumes v1 et v2 sont récupérés sur le groupe.
- les volumes (pas les quotas) sont diminués sur la compta du compte.
- sur le groupe :
  - `dfh` : date du jour + N jours
  - `idhg, imh` : 0

Retour: rien.

Assertions sur l'existence du groupe et de sa `versions` ainsi que le compte.

### `NouveauMembre` : déclaration d'un nouveau membre (contact)
POST:
- `token` : éléments d'authentification du compte.
- `id` : id du contact devenant membre (de statut contact).
- `idg` : id du groupe.
- `im` : 
  - soit l'indice de l'avatar dans ast/nag s'il avait déjà participé, 
  - soit ast.length.
- `nig` : hash du `rnd` du membre crypté par le `rnd` du groupe. Permet de vérifier l'absence de doublons.
- `ardg` : texte de l'ardoise du groupe crypté par la clé du groupe. Si null, le texte actuel est inchangé.
- `rowMembre` : row membre du membre créé.

Traitement: 
- vérification que le statut ast n'existe pas (ou est 0) pour ce contact.
- insertion du row membre, mise à jour du groupe

Retour:
- KO : true si l'indice im est déjà attribué.

### `MajInfoMembre` : mise à jour du commentaire d'un membre
POST:
- `token` : éléments d'authentification du compte.
- `id` : id du groupe.
- `ids` : ids du membre.
- `infok` : texte d'information du membre à propos du groupe, crypté par la clé K du compte.

Retour: rien.

Assertion sur l'existence du membre et de la version du groupe.

### `MajMCMembre` : mise à jour des mots clés d'un membre à propos du groupe
POST:
- `token` : éléments d'authentification du compte.
- `id` : id du groupe.
- `ids` : ids du membre.
- `mc` : vecteur des mots clés.

Retour: rien.

Assertion sur l'existence du membre et de la version du groupe.

### `ModeSimple` : gestion du dode simple / unanime d'un groupe
POST:
- token : éléments d'authentification du compte.
- id : id du groupe
- ids : ids du membre demandant le retour au mode simple. Si 0, c'est la demande de retour au mode unanime.

Le mode redevient _simple_ quand TOUS les animateurs ont exprimé leur souhait de revenir au mode simple. Il s'agit d'un anamiateur déclarant vouloir rester au mode unanime pour que le mode reste _unanime_ et que les votes exprimés pour le retour au mode simple soient annulés.

Retour: rien.

Assertion sur l'existence du groupe et de la version du groupe.

### `StatutMembre` : changement de statut d'un membre d'un groupe
POST:
- `token` : éléments d'authentification du compte.
- `id` : id du groupe.
- `ids` : ids du membre cible.
- `ida` : id de l'avatar du membre cible.
- `idc` : id du COMPTE de ida, en cas de fin d'hébergement par résiliation / oubli.
- `ima` : ids (imdice membre) du demandeur de l'opération.
- `idh` : id du compte hébergeur.
- `kegr` : clé du membre dans la liste des groupes de l'avatar (lgrk). Hash du rnd inverse de l'avatar crypté par le rnd du groupe.
- `egr` : (invitations seulement) élément de l'avatar invité dans cette liste, crypté par la clé RSA publique de l'avatar.
- `laa` : 0:lecteur, 1:auteur, 2:animateur
- `ardg` : ardoise du groupe cryptée par la clé du groupe. null si inchangé.
- `dlv` : pour les acceptations d'invitation, _signature_ du compte pour l'accès au groupe.
- `fn` : fonction à appliquer
  - 0 - maj de l'ardoise seulement, rien d'autre ne change
  - 1 - invitation
  - 2 - modification d'invitation
  - 3 - acceptation d'invitation
  - 4 - refus d'invitation
  - 5 - modification du rôle laa (actif)
  - 6 - résiliation
  - 7 - oubli

Retour: `code` : code d'anomalie: 
- 1 - situation inchangée, c'était déjà l'état actuel
- 2 - changement de laa impossible, membre non actif
- 3 - refus d'invitation impossible, le membre n'est pas invité
- 4 - acceptation d'invitation impossible, le membre n'est pas invité
- 5 - modification d'invitation impossible, le membre n'est pas invité
- 7 - le membre est actif, invitation impossible
- 8 - le membre a disparu, opération impossible

Assertion sur la version du groupe (quand le groupe existe).

# Design interne du serveur

Les deux modes SQL et Firestore sont implémentés dans tous les modules, le choix est exprimé en configuration mais géré en runtime.

## Mode SQL
L'implémentation utilise une base de données `SQLite` comme support de données persistantes :
- elle s'exécute en tant que serveur HTTPS dans un environnement **node.js**.
- le serveur sert aussi l'application Web front-end : quelques fichiers après build par _webpack_.
- une session de l'application est connectée par WebSocket qui lui notifie les mises à jour des documents `espaces comptas tribus et versions` (avatar et groupe) qui la concerne et auxquelles elle s'est _abonnée_.
- les backups de la base peuvent être stockés sur un Storage.

## Mode Firestore + GAE (Google App Engine)
Le stockage persistant est Google Firestore.
- en mode serveur, un GAE de type **node.js** sert de serveur.
- le stockage est assurée par Firestore : l'instance FireStore est découplée du GAE, elle a sa propre vie et sa propre URL d'accès. En conséquence elle _peut_ être accédée depuis n'importe où, et typiquement par un utilitaire d'administration sur un PC pour gérer un upload/download avec une base locale _SQLite_ sur le PC.
- une session de l'application reçoit de Firestore les mises à jour sur les espaces comptas tribus versions qui la concerne, par des requêtes spécifiques `onSnapshot` adressées directement à Firestore (sans passer par le serveur).

Dans les deux cas le Storage des fichiers peut-être,
- soit `fs` : un file-system local du serveur,
- soit `s3` : un Storage S3 de AWS (éventuellement minio).
- soit `gc` : un Storage Google Cloud Storage.

En pratique il n'y a pas de raisons fortes à assurer un Storage `s3` sous GAE.

## Modules dans `src/`

### `server.mjs`
Point d'entrée du serveur:
- initialisation du logger Winston, un peu différent en mode SQL et Firestore.
- si les arguments de la ligne de commande sont `export delete storage`, se déroute sur le module `export.mjs`.

**Actions:**
- détection de la configuration et initialisation de l'accès SQL ou Firestore et du Storage choisi dans la configuration. Ces données d'initialisation figure dans l'objet exporté `ctx`.
- lancement de l'écoute Express:
  - traitement local des URLs simples: `/fs /favicon /robots.txt`.
  - traitement des requêtes `OPTIONS`.
  - route les requêtes `/storage/...` vers le module `storage.mjs`.
  - met en forme les requêtes `/op/...` les vérifie et les route vers le module `operations.mjs` qui a les classes de traitement.
- initialise les écoutes et réceptions de messages WebSocket dans le cas de l'implémentation SQL.

### `config.mjs`
Donne directement les options de configuration qui sont accessibles par simple import.

Les données sont aussi disponibles pour convenance dans `ctx.config`.

Détail de la configuration en annexe.

### `api.mjs`
Ce module est strictement le même queapi.mjs dans l'application UI afin d'être certain que certaines interprétation sont bien identiques de part et d'autres:
- quelques constantes exportées.
- les classes,
  - `AppExc` : format général d'une exception permettant son affichage en session, en particulier en supportant la traduction des messages.
  - `ID` : les quelques fonctions statiques permettant de déterminer depuis une id si c'est celle d'un avatar, groupe, tribu, ou celle du Comptable.
  - `Compteurs` : calcul et traitement des compteurs statistiques des compteurs statistiques des documents `comptas`.
  - `AMJ` : une date en jour sous la forme d'un entier aaaammjj. Cette classe gère les opérations sur ce format.

### `base64.mjs`
Module présent aussi dans l'application UI, donnant une implémentation locale de la conversion bytes / base64 afin d'éviter de dépendre de celle de Node et d'avoir deux procédés un en Web et l'autre en Node.

### `util.mjs`
Quelques fonctions générales qu'il fallait bien mettre quelque part.

### `webcrypto.mjs`
L'interface des rares fonctions cryptograpiques requises sur le serveur avec leur implémentation par Node.

### `ws.mjs`
Gestion des WebSocket ouverts avec les sessions UI en mode SQL:
- gère l'ouverture / enregistrement d'une session,
- stocke pour chaque session la liste de ses abonnements,
- à chaque fin de transaction dispatche sur les WebSocket des sessions les _row_ mis à jour qui les intéresse et envoie le message aux sessions UI,
- gère un heartbeat sur les sockets pour détecter les sessions perdues.

### `export.mjs`
Utilitaires `export delete storage`.

`export` : services d'exportation d'un espace sur un autre espace, de SQL vers SQL, de FS vers SQL.

`delete` : suppression d'un espace.

`storage` : exporte le storgae d'un espace dans un autre.

### `storage.mjs`
Trois classes gérant le storage selon son type fs s3 gc avec le même interface vu des opérations.

### `modele.mjs`
Données :
- la classe `Cache` conservant en static une mémoire cache des objets majeurs accédés. Détail ci-après.
- la class `GenDoc` représentant un document _générique_ et ses méthodes d'accès. Détail ci-après.
- la classe `Operation` : chaque opération est une instance héritant de cette classe générique. Quelques méthodes utilisées par plus d'une classe d'opération s'y retrouve.

### `operations.mjs`
Toutes les opérations de l'API figurant ci-avant dans ce document (qui héritent de Operation décrite dans `modele.mjs`).

## `Cache` : cache des objets majeurs `espaces tribus comptas avatars groupes`

Cet objet gére une mémoire cache des derniers documents demandés dans leur version la plus récente.

Le test pour savoir si la version détenue est la dernière s'effectue dans une transaction et permet de ne pas lire le document de la table ou de la collection si sa version n'est pas plus récente ce qui évite des lectures coûteuses inutiles (et coûteuses monaiterement en Firestore).

Cache gère aussi une mémoire cache de `checkpoint` le document de suivi du GC.

En stockant les document `espaces`, `Cache` fournit également le code de l'organisation d'un espace connu par son ns (son id).

### `static getRow (transaction, nom, id)`
Obtient le row de la cache ou va le chercher.
- Si le row actuellement en cache est le plus récent on a évité une lecture effective et la méthode s'est limité à un filtre sur index qui ne coûte rien en FireStore et pas grand chose en SQL.
- Si le row n'était pas en cache ou que la version lue est plus récente IL Y EST MIS:
  - certes la transaction _peut_ échouer, mais au pire on a lu une version, pas forcément la dernière, mais plus récente.

### `static update (newRows, delRowPaths)`
Utilisée en fin de transaction pour enrichir la cache APRES le commit de la transaction avec tous les rows créés, mis à jour ou accédés (en ayant obtenu la _dernière_ version).

### `static async getCheckpoint ()`
Retourne le dernier checkpoint enregistré parle GC.

### `async setCheckpoint (obj)`
Enregistre en base et dans Cache le dernier objet de checkpoint défini par le GC.

### `async org (id)`
Retourne le code de l'organisation pour une id donnée (un ns).

## La classe `GenDoc`
### Fonction `compile (row) -> Objet`
Cette fonction aurait pu être déclarée static de `GenDoc` et a été écrite comme fonction pour raccourcir le texte d'appel très fréquent.

Chaque **row** d'une table SQL ou **document** Firestore apparaît sous deux formes :
- **row** : c'est l'objet Javascript directement stocké en tant que row d'une table SQL ou document Firestore.
- **objet compilé** : c'est une instance de la classe de document :

    Espaces Gcvols Tribus Tribu2s COmptas Versions Avataars Groupes
    Notes Transferts Sponsorings Chats Membres

Ces classes héritent de la classe générique `GenDoc`.

Les noms symboliques sont ceux des classes ci-dessus avec une minuscule au lieu d'une majuscule en tête.

La méthode `compile()` retourne l'objet compilé depuis sa forme row et son nom symbolique : si l'argument row est null, le retour est null (sans levée d'exception).

### Méthode `GenDoc.toRow()`
Réciproquement depuis un objet `a` par exemple de classe `Avatars`, `a.toRow()` retourne sa forme **row** prête à être stockée en row SQL ou document Firestore.

### Liste restrictive des attributs d'un row
Cette liste est fermée : pour chaque classe la liste exhaustive est donnée.
- `_nom` : nom symbolique de la classe dont est issue le row ('avatar', 'groupe', ...).
- `id` : l'id principale (et unique pour les objets majeurs).
- `ids` : l'id secondaire pour les `Notes Transferts Sponsorings Chats Membres`.
- `v` : sauf Gcvols. Version de l'objet.
- `vcv` : pour Avatars Chats Membres : version de la carte de visite.
- `dlv`: pour Versions Transferts Sponsorings Membres : date limite de validité (`aaaammjj`). A partir de cette date, le document n'est plus _valide_, il est sémantiquement _disparu_. En compilé l'attribut `_zombi` vaut `true`.
- `hps1` : sur Comptas, hash de la phrase secrète raccourcie.
- `dfh` : sur Groupes date de fin d'hébergement.
- `hpc` : sur Avatars, hash de la phrase de contact (pseudo plus ou moins temporaire).
- `_data_` : sérialisation de tous les attributs, dont ceux ci-dessus.

En forme compilé la propriété `_data_` n'est pas elle-même présente mais à la place tous les attributs de la classe sont présents.
- quand _data_ n'existe pas ou est null dans le format row, l'attribut _zombi de la classe correspondante vaut true.

### Méthodes statiques _publiques_ de `GenDoc`
Elles offrent les accès,
- soit en SQL aux tables,
- soit en Firestore aux collections et sous-collections de documents.

Chaque méthode _publique_ invoque l'une des deux méthodes _privées_ correspondant aux implémentations SQL et Firecstore.

Des méthodes _privées_ utilitaires existent pour chacun des deux modes.

`static async getV (transaction, nom, id, v)`
- pour les collections _majeures_ retourne le row de nom donné, pour cette id si sa version est postérieure à v.

`static async get (transaction, nom, id, ids)`
- pour les sous-collections, retourne le row de nom donné pour cette id et cette ids sans considérer sa version (donc la plus récente).

`static async getAvatarVCV (transaction, id, vcv)`
- retourne l'avatar compilé d'id donnée si la version de sa carte de visite est postérieure à vcv.

`static async getChatVCV (transaction, id, ids, vcv)`
- retourne le chat compilé si sa carte de visite est antérieure à vcv (bref, n'est pas à jour).

`static async getMembreVCV (transaction, id, ids, vcv)`
- retourne le membre compilé si sa carte de visite est antérieure à vcv (bref, n'est pas à jour).

`static async getVersionsDlv (dlvmin, dlvmax)`
- retourne **l'array des id** des `versions` dont la dlv est entre min et max incluses. 

`static async getMembresDlv (dlvmax)`
- retourne **l'array des id** des `membres` dont la dlv est inférieure ou égale à dlvmax.

`static async getGroupesDfh (dfh)`
- retourne l'array des id des `groupes` dont la fin d'hébergement est inférieure ou égale à dfh

`static async coll (transaction, nom)`
- retourne tous les rows de la collection de nom donné, tous espaces confondus.

`static async collNs (transaction, nom, ns)`
- retourne tous les rows de la collection de nom donné, pour l'espace ns.

`static async scoll (transaction, nom, id, v)`
- retourne tous les rows de la sous-collection de nom donné (`notes transferts membres sponsorings chats`) de version postérieure à v.

`static async delScoll (nom, id)`
- purge, hors transaction, tous les documents de la sous-collection de nom et d'id donné.

`static async delAvGr (id)`
- purge, hors transaction, le groupe ou l'avatar d'id donné.

`static async getComptaHps1 (transaction, hps1)`
- retourne le row `comptas` dont l'attribut hps1 est celui donné en argument (accès par le hash de la phrase secrète raccourcie).

`static async getAvatarHpc (transaction, hpc)`
- retourne le row `avatars` dont l'attribut hpc est celui donné en argument (accès par le hash de la phrase de contact raccourcie).

`static async getSponsoringIds (transaction, ids)`
- retourne le row `sponsorings` dont l'attribut ids est celui donné en argument (accès par le hash de la phrase de sponsorings raccourcie).

`static async getGcvols (ns)`
- retourne tous les rows gcvols de l'espace ns donné (pour traitement à la fin de la phase de connexion du Comptable de l'espace).

`static async setVdlv (id, dlv)`
- force la dlv, hors transaction et sans changer la version v, du document `versions` d'id donné (utilisé par le GC).

## Classe `Operation`
Le déclenchement d'une opération `MonOp` sur réception d'une requête `.../op/MonOp`,
- créé un objet `MonOp` héritant de `Operation`,
- invoque successivement :
  - sa méthode `phase1()` qui s'exécute hors de toute transaction, typiquement pour des contrôles d'argments,
  - sa méthode `phase2()` qui s'exécute dans le contexte d'une unique transaction.

Dans une transaction Firestore aucune lecture n'est autorisée dès qu'une mise à jour a été effectuée. Les mises à jour sont de ce fait _enregistrées et mises en attente_ au cours de la phase 2 et ne seront effectivement faites qu'après la phase 2.

En conséquence, les opérations doivent prendre en compte que la modification d'un document n'est jamais perceptible dans la même transction par une lecture : le cas échéant si nécessaire stocker en mémoire de l'objet opération les mises à jour si elles participent de la logique de l'opération.

### Authentification avant `phase1()`
Chaque classe Operation spécifie un attribut authMode qui déclare comment interpréter l'attribut `token` reçu dans l'objet `args` (argments sérialisés reçu dans le body de la requête ou queryString de l'URL). Cet objet est disponible dans `this.args` :
- `authMode === 3` : SANS TOKEN, pings et accès non authentifiés (recherche phrase de sponsoring).
- `authMode === 2` : AVEC TOKEN, créations de compte. Elles ne sont pas encore enregistrées, elles vont justement enregistrer leur authentification.
- `authMode === 1` : AVEC TOKEN, première connexion à un compte : `this.rowComptas` et `this.compta` sont disponibles.
- `authMode undefined` : AVEC TOKEN, cas standard, vérification de l'authentification, voire enregistrement éventuel.

### Méthodes génériques disponibles en phase 1 et 2
`setRes(prop, val)`
- Fixe LA valeur de la propriété 'prop' du résultat (et la retourne).

`addRes(prop, val)`
- AJOUTE la valeur en fin de la propriété Array 'prop' du résultat (et la retourne).

### Méthodes génériques disponibles en phase 2
`insert (row)`
- Inscrit row dans les rows à insérer en phase finale d'écritue, juste après la phase 2.

`update (row)`
- Inscrit row dans les rows à mettre à jour en phase finale d'écritue, juste après la phase2 .

`delete (row) `
- Inscrit row dans les rows à détruire en phase finale d'écritue, juste après la phase 2.

### Méthodes `async` de lecture
Selon la méthode,
- retourne UN row (ou null) ou un array de rows (possiblement vide).
- quand le dernier paramètre `assert` est true, au lieu de retourner null, lève une exception A_SRV (assertion).

async getAllRowsEspace ()

async getRowEspace (id, assert)
- de Cache

async getAllRowsTribu ()

async getRowTribu (id, assert)
- de Cache

async getRowSynthese (id, assert)
- de Cache

async getRowCompta (id, assert)
- de Cache

async getRowVersion (id, assert, nonZombi)
- de Cache.
- génère une assert si le rowVersion est zombi et l'argument `nonZombi` à true.

async getRowAvatar (id, assert)
- de Cache

async getRowGroupe (id, assert)
- de Cache

async getAllRowsNote(id, v)

async getRowNote (id, ids, v, assert)

async getAllRowsChat(id, v)

async getRowChat (id, ids, v, assert)

async getAllRowsSponsoring(id, v)

async getRowSponsoring (id, ids, v, assert)

async getAllRowsMembre(id, v)

async getRowMembre (id, ids, v, assert)

async setFpurge (idag, lidf) 
- créé, hors transaction, un document `Fpurge` pour un avatar / groupe idag et une liste éventuelle restrictive de fichiers.
- Retourne l'id générée

async unsetFpurge (id)
- supprime, hors transaction, un document `fpurges`.

async listeFpurges ()
- retourne une array des rows `fpurges` existants.

async listeTransfertsDlv (dlv)
- retourne une array des couples [id, ids] des documents `transferts` ayant une dlv inférieure ou égale à celle passée en argument.

async purgeTransferts (id, ids)
- purge hors transaction le document transfert.

async purgeDlv (nom, dlv)
- purge hors transaction les sponsorings ou versions (selon le nom en argument) ayant une dlv inférieure ou égale à dlv.

### Méthodes invoquées depuis plus d'une opération
`async majVolumeGr (idg, dv1, dv2, simu, assert)`
- Met à jour les volumes du groupe.
- Refuse si le volume est en expansion et qu'il dépasse le quota.
- si l'objet `versions` du groupe n'existe pas, une exception est levée (par une assert).
- Son changement de version et update est fait SAUF si simu est true.
- Retourne la version du document `versions`.

`async majCompteursCompta (idc, dv1, dv2, vt, ex, assert)`
- Si `ex` lève une exception en cas de dépassement de quota
- si l'objet `comptas` n'existe pas, une exception est levée (par une assert).
- Retourne `compta` ou null s'il n'y avait rien à faire.

`async MajSynthese (tribu, noupd)`
- Met à jour le document syntheses de l'espace suite à la mise à jour d'une tribu.
- si noupd, le this.update de la synthèse n'est pas effectuée car il y en a une autre à effectuer ensuite.

# Annexe : la configuration dans `config.mjs`
`rooturl: 'https://test.sportes.fr:8443'`
- L'URL d'appel du serveur. Est utilisé pour faire des liens d'upload / download de fichiers

`port: 8443`  
- Numéro de port d'écoute du serveur. En GAE ce paramètre est inutilisé (c'est la variable process.env.PORT qui le donne), en mode 'passenger' également, mais ça ne nuit pas d'en mettre un.

`origins: ['https://192.168.5.64:8343', 'https://test.sportes.fr:8443']`  
- Liste des origines autorisées. Si la liste est vide, l'origine n'est pas contrôlée.

`projectId: 'asocial-test1'`
- requis en usage Firestore / Google Cloud storage: ne gêne pas d'en mettre un dans les autres cas.

`admin:  ['tyn9fE7zr...=']`
- Hash du PBKFD de la phrase secrète de l'administrateur technique.

`ttlsessionMin: 60`
- durée de vie en minutes d'une session sans activité (mode SQL seulement).

`apitk: 'VldNo2aLLvXRm0Q'  `
- Jeton d'autorisation d'accès à l'API. Doit figurer à l'identique dans la configuration de déploiement (`quasar.config.js` de l'aplication UI.

Interprétation des URLs:   
- `prefixop: '/op'` : il n'y a pas de raisons de le changer.
- `prefixapp: '/app'` : commenter la ligne si le serveur ne doit pas servir les URLs statiques de l'application UI.

`pathapp: './app'`
- si le serveur sert aussi les pages de l'application UI, folder ou cette application est distribuée.

`pathsql: './sqlite/test1.db3'`
- si le mode est SQL, path de l'emplecement de la base Sqlite.

`pathlogs: './logs'`
- path ou ranger les logs, sauf en déploiement GAE.

`favicon: 'favicon.ico'`
- si la favicon n'est pas celle par défaut, nom de son fichier dans le folder de configuration. Sinon commenter la ligne.

`pathconfig: './config'`
- Le répertoire de configuration doit contenir jusqu'à 5 fichiers:
  - le certificat SSL : `fulchain.pem privkey.pem`. Sauf en déploiement GAE et _passenger_.
  - `service_acount.json` : indispensable pour Firestore et provider de storage `gc`.
  - `firebase_config.json` : indispensable pour Firestore.
  - `s3_config.json` : indispensable si le provider de storage est `s3`.
  - `favicon.ico` : seulement si favicon est spécifié.

`firestore: false`  
- si `false` le mode SQL est activé, sinon c'est le mode Firestore.

`gae: false`
- true pour un déploiement Google App Engine.

`emulator: false`
- `false` si l'émulateur Firestore n'est pas utilisé (accès à la base réelle). Si `true` les deux entrées suivantes sont requises:
  - `firestore_emulator: 'localhost:8080'`
  - `storage_emulator: 'http://127.0.0.1:9199'` - 'http://...' est REQUIS.

`storageprovider: 'fsb'`
- code du provider de storage gérant le stockage des fichiers.
- il y a 3 types de providers implémentés:
  - `fs` : sur File-system local (pour les tests en pratique),
  - `s3` : interface S3 de AWS (dont l'implémentation minio),
  - `gc` : interface Google Colud storage
- le code `fsb` correspond à :
  - une implémentation `fs`,
  - une entrée de configuration `fsbconfig` dans ce fichier.

`fsaconfig: { rootpath: './wwwb' }`
- configuration file-sytem:
  - `rootpath` : localisation du folder hébergeant les fichiers.

`s3config: { bucket: 'asocial' }`
- pour un provider de stockage `s3`, nom du bucket.

`gcconfig: { bucket: 'asocial-test1.appspot.com' }`
- pour un provider de stockage `gc`, nom du bucket. Ce nom est celui utilisé par défaut par Firebase ce qui facilite les tests.

# Développement / déploiement : remarques

## Projet Google
L'utilisation d'un projet Google ne se justifie que si on utilise au moins l'un des deux dispositifs `Firestore` `Cloud Storage`. Une implémentation uniquement SQL et S3 par exemple n'en n'a pas besoin.

Depuis son compte Google, dans Google Console `https://console.cloud.google.com/`, on peut créer un nouveau projet : dans notre cas `asocial-test1`. Ce projet doit accéder aux environnements / APIs:
- **App Engine**. Même si finalement on n'utilise pas GAE, ceci fournit des ressources et en particulier un `session_account` qui sera utilisé par la suite, ce qui évite d'en créer un spécifique qui ne serait pas utilisable en cas de décision de déployer GAE.
- **Firestore**
- **Cloud Storage**

Le menu hamburger en haut à gauche permet de sélectionner tous les produits et surtout d'épingler ceux qu'on utilise:
- **APIs & Service**
- **Billing**: c'est là qu'on finit par donner les références de sa carte bancaire.
- **IAM & Admin** : voir ci-dessous.
- **App Engine**
- **Firestore** : voir ci-dessous.
- **Cloud Storage** : voir ci-dessous.
- **Logging** : pour explorer les logs App engine.
- Security (?)

**Firestore**
- _Data_ : permet de visualiser les données.
- _Indexes_ : il n'y a que des index SINGLE FIELD. Les _exemptions_ apparaissent, on peut les éditer une à une et en créer mais on ne peut pas (du moins pas vu comment) en exporter les définitions : ceci justifiera l'utilisation de Firebase qui le permet.
- _Rules_ : idem pour la visualisation / édition mais pas l'import / export.

**Cloud Storage**
- _Buckets_ : on peut y créer des buckets et les visiter. Il n'a pas été possible d'utiliser avec Firebase un autre bucket que celui qu'il créé par défaut `asocial-test1.appspot.com`/

**IAM & Admin**
- _Service accounts_ : il y a en particulier le _service account_ créé par App Engine `asocial-test1@appspot.gserviceaccount.com` et que nous utilisons. Quand on choisit un des service accounts, le détail apparaît. En particulier l'onglet KEYS (il y a une clé active) qui va permettre d'en créer une pour nos besoins.

## Projet Firebase
Il faut en créer un dès qu'on utilise au moins l'un des deux dsipositifs `Firestore` `Cloud Storage`. 
- possibilité d'importer / exporter les index et rules de Firestore,
- possibilité d'utiliser l'API Firebase Web (module `src/app/fssync.mjs` de l'application UI),
- utilisation des _emulators_ qui permettent de tester en local.

La console a cette URL : https://console.firebase.google.com/

A la création d'un projet il faut le lier au projet Google correspondant: les deux partagent le même _projectId_ `asocial-test1`. (processus flou à préciser).

## CLIs
Il y en a un pour Google `gcloud` et un pour Firebase `firebase`. Les deux sont nécessaires sur un poste de développement. Voir sur le Web leurs installations et documentation de leurs fonctions.

### `firebase`
Install de firebase CLI :
https://firebase.google.com/docs/cli?hl=fr#update-cli

    npm install -g firebase-tools
    firebase --help

Quelques commandes `firebase` souvent employées:

    // Pour se ré-authentifier quand il y a un problème d'auth
    firebase login --reauth

    // Delete ALL collections
    firebase firestore:delete --all-collections -r -f

    // Deploiement / import des index et rules présents dans: 
    // `firestore.indexes.json  firestores.rules`
    firebase deploy --only firestore

    // Export des index
    firebase firestore:indexes > firestore.indexes.EXP.json

    // Emulators :
    firebase emulators:start
    firebase emulators:start --import=./emulators/bk1
    firebase emulators:export ./emulators/bk2 -f

### Utilisation et authentification `gcloud`
Page Web d'instruction: https://cloud.google.com/sdk/docs/install?hl=fr

#### Utilisation de ADC
ADC permet de s'authentifier pour pouvoir utiliser les librairies. Cette option (il y en a d'autres) est systématiquement mise en avant par Google pour sa _simplicité_ mais finalement pose bien des problèmes.

Les commandes principales sont les suivantes:
- login _temporaire_ sur un poste:
  `gcloud auth application-default login`
- révocation sur ce poste:
  `gcloud auth application-default revoke`

Ceci dépose un fichier `application_default_credentials.json`
- Linux, macOS dans: `$HOME/.config/gcloud/`
- Windows dans: `%APPDATA%\gcloud\`

#### Problèmes
L'authentification donnée sur LE poste est _temporaire_ : absolument n'importe quand, d'un test à l'autre, un message un peu abscon vient signaler un problème d'authentification. Il faut se souvenir qu'il suffit de relancer la commande ci-dessus.

La librairie d'accès à Cloud storage ne se satisfait pas de cette authentification, a minima pour la fonction indispensable `bucket.getSignedUrl` : celle-ci requiert une authentification par _service account_ dès lors ADC n'est plus une option de _simplicité_ mais d'ajout de complexité puisqu'il de toutes les façons gérer un service account.

En production ? Google dit que App Engine fait ce qu'il faut pour que ça marche tout seul. Voire, mais pour le service account requis pour créer un storage, il est permis d'en douter.

Et quand on n'utilise pas App Engine ? Il faut utiliser une clé de service account et la passer en variable d'environnement.

#### Solution
Il faut créer un service account : en fait comme vu ci-avant il y en a un pré-existant `asocial-test1@appspot.gserviceaccount.com`

Dans le détail de ce service l'onglet KEYS permet de créer une clé: en créer une (en JSON). Il en résulte un fichier `service_account.json` qu'il faut sauvegarder en lieu sûr et pas dans git: il contient une clé d'authentification utilisable en production. Cette clé,
- ne peut PAS être récupérée depuis la console Google,
- mais elle peut y être révoquée en cas de vol,
- en cas de perte, en créer une autre, révoquer la précédente et ne pas perdre la nouvelle.

Pour être authentifié il faut que la variable d'environnement `GOOGLE_APPLICATION_CREDENTIALS` en donne le path.

**Remarques:**
- il n'a pas été possible de donner le contenu de cette clé en paramètres lors de la création de l'objet d'accès à Firesore: `new Firestore(arg)` est censé accepter dans `arg` cette clé mais ça n'a jamais fonctionné, même quand le fichier `application_default_credentials.json` a été supprimé de `$HOME/.config/gcloud/`.
- il FAUT donc que le path de fichier figure dans la variable d'environnement `GOOGLE_APPLICATION_CREDENTIALS` au moment de l'exécution: ceci est fait au début du module `src/server.mjs` en utilisant le `service_account.json` dans le répertoire `./config` (qui est ignoré par git).
- pour le déploiement ce fichier fait partie des 4 à déployer séparément sur le serveur (voir plus avant).
- en revanche il _semble_ que le contenu puisse bien être accepté par la création d'un accès au storage Google Cloud : dans `src/storage.mjs` le code qui l'utilise est commenté mais peut être réactivé si l'usage d'une variable d'environnement devait être prohibé.

### Authentification `firebase`
L'API WEB de Firebase n'est PAS utilisé sur le serveur, c'est l'API Firestore pour Node.js qui l'est.

L'application UI utilise l'API Web de Firebase (la seule disponible en Web et de formalisme différent de celle de Google Firestore) pour gérer la synchronisation des mises à jour. En particulier les fonctions :
`getFirestore, connectFirestoreEmulator, doc, getDoc, onSnapshot`

L'objet `app` qui conditionne l'accès à l'API est initialisé par `const app = initializeApp(firebaseConfig)`.
- le paramètre `firebaseConfig` ci-dessus est un objet d'authentification qui a été transmis par le serveur afin de ne pas figurer en clair dans le source et sur git. Ce paramètre dépend bien sur du site de déploement.

##### Obtention de `firebase_config.json`
- Console Firebase
- >>> en haut `Project Overview` >>> roue dentée >>> `Projet Settings`
- dans la page naviguer jusqu'au projet et le code à inclure (option `Config`) apparaît : `const firebaseConfig = { ...`
- le copier, le mettre en syntaxe JSON et le sauver sous le nom `firebase_config.json`, en sécurité hors de git. Il sera à mettre pour exécution dans `./config`

### Authentification S3
Le provider de storage S3Provider a besoin d'un objet de configuration du type (celle de test avec `minio` comme fournisseur local S3):

    {
      credentials: {
        accessKeyId: 'access-asocial',
        secretAccessKey: 'secret-asocial'
      },
      endpoint: 'http://localhost:9000',
      region: 'us-east-1',
      forcePathStyle: true,
      signatureVersion: 'v4'
    }

Un fichier JSON nommé `s3_config.json` est recherché dans `./config` (à côté des autres fichiers contenant des clé privées) afin de ne pas exposer les autorisations d'accès S3 dans un fichier disponible sur git.

## Emulators de Firebase
Cet utilitaire permet de travailler, en test, localement plutôt que dans une base / storage distant payant.

Pour tester de nouvelles fonctionnalités on peut certes tester en environnement SQL / File-system : mais pour tester que la couche technique de base (dans `src/modeles.mjs src/storage.mjs` du serveur) offre bien des services identiques quelqoitl'option Firebase / SQL ou le provider de storage file-sytem / S3 / Google Cloud, il faut bien utiliser Firestore et Cloud Storage.

L'émulateur est lancé par:

    firebase emulators:start
    firebase emulators:start --import=./emulators/bk1

Dans le premier cas tout est vide. Dans le second cas on part d'un état importé depuis le folder `./emulators/bk1`

Tout reste en mémoire mais on peut exporter l'état en mémoire par:

    firebase emulators:export ./emulators/bk2 -f

**La console de l'emulator** est accessible par http://localhost:4000

Voir la page Web: https://jsmobiledev.com/article/firebase-emulator-guide/

**Attention**: Google mentionne _son_ emulator dans la page https://cloud.google.com/firestore/docs/emulator?hl=fr
- ça ne prend en compte que Firestore et pas Cloud Storage,
- l'usage n'a pas été couronné de succès.

A ce jour prendre celui de Firebase.

### Contraintes
- Firebase n'a pas implémenté _toutes_ les fonctionnalités. Il y a du code qui contourne ce problème dans `src/storage.mjs` :
  - la création du storage ne prend pas en compte l'option `cors` (`constructor de la class GcProvider`),
  - `getSignedUrl` n'est pas utilisable avec l'émulator : contournement dans `getUrl` et `putUrl`.
- en run-time le code tient compte du mode `emulator` qui est donné par un booléen dans `src/config.mjs`.
- dans l'application UI l'initialisation dans `src/app/fssync.mjs` méthode `open()` tient compte du mode emulateur:
  - l'application UI obtient en retour de connexion d'une session, l'objet requis `firebaseConfig` et le booléen `emulator`.
  - auparavant l'usage de l'URL `./fs` a retourné 'true' ou 'false' selon que le serveur est en mode Firestore (true) ou SQL (false).

Deux variables d'environnement sont requises :
- FIRESTORE_EMULATOR_HOST="localhost:8080"
- STORAGE_EMULATOR_HOST="http://127.0.0.1:9199"

Attention pour la seconde, 
- le Web donne un autre nom: bien utiliser celui ci-dessus,
- `http://` est indispensable, sinon un accès https est essayé et échoue.

Ces deux variables sont générées en interne dès le début de `src/server.mjs` quand le booléen `emulator` a été trouvé dans la configartion, ce qui évite de les gérer en test et des exclure en production.

## BUGS rencontrés et contounés: `cors` `403`
Pour information, les fonctions de download / upload d'un fichier d'une note ont d'abord échoué en Google Cloud storage : l'URL générée étant rejetée pour cause `same origin`.

Ce type de problèmes n'apparaît que dans une invocation dans un browser pour une page chargée depuis un site Web. En conséquence ça n'apparaît pas,
- en copiant directement une URL dans la barre d'adresse,
- en utilisant `curl`.

Il n'y a que le serveur qui peut résoudre le problème.

Pour Google Cloud storage on peut passer à l'initialisation du storage un objet d'options `cors` qui spécifie de quelles origines les URLs sont acceptées. Par chance `'*'` a été accepté : sinon il faut passer en configuration une liste d'origines autorisées.

A noter que dans `emulator`, cette option n'étant pas implémentée, il a fallu contourner par en chargement / déchargement par le serveur (ce qui n'est ps un problème en test, mais en serait un en production).

Pour générer une URL signée, sur PUT, il faut spécifier le content-type des documents envoyés sur PUT. `application/octet-stream` fait l'affaire MAIS encore faut-il émettre ce content-type du côté application UI dans l'appel du PUT (`src/app/net.mjs`), ce qui n'avait pas été fait (laissé vide) et a provoqué une erreur `403` pas très représentative de la situation.

### Variable d'environnement `GOOGLE_CLOUD_PROJECT`
Assez systématiquement une librairie se plaint : `cannot determine the project_id ...`

C'est parce que la variable d'environnement `GOOGLE_CLOUD_PROJECT` n'a pas été initialisée avec le code du projet.

Pour éviter cet oubli cette variable est générée par `src/server.mjs` en fonction de la valeur trouvée dans `src/config.mjs`.

## Environnements DEV / PROD

Le folder `./config` est ignoré par git et contient au plus 5 fichiers:
- `fullchain.pem privkey.pem` : le certificat HTTPS du site. Ces fichiers sont renouvelés avec `letsencrypt` tous les 3 mois et ne sont pas à rendre public.
- `firebase_config.json service_account.json s3_config.json` : voir ci-avant. Ils n'ont pas à être renouvelés mais ne doivent surtout pas être rendus public.

En développement le folder `./config` est à ce path, en production il peut être ailleurs: ce path relatif figure dans `src/config.mjs >>> pathconfig`

### Paths
D'autres paths sont cités dans `src/config.mjs` et peuvent différer en développement et en production:
- `pathapp: './app'` Localisation relative du folder de l'application UI quand elle est servie par le serveur.
- `pathconfig: './config'` Localisation relative du folder contenant les 5 ficheirs de configuration.
- `pathsql: './sqlite/test1.db3'` Localisation relative de la base SQL en déploiement SQL.
- `pathlogs: './logs'` Localisation du folder contenant les logs.

Quand le provider de storage est fs (file-system), sa configuration mentionne aussi un path. C'est plutôt une option d'environnement de test.

### Logs
Ils sont gérés par Winston: 
- sauf pour App engine `combined.log error.log` : le path est fixé dans `src/config.mjs >>> pathlogs` et les noms sont en dur dans` src/server.mjs`.
- pour App Engine, c'est redirigé vers les logs de App Engine.

`firestore.debug.log ui-debug.log` : produits par emulator en DEV.

### Autres Fichiers apparaissant à la racine en DEV
- `firebase.json` : utilisé par emulator et les opérations CLI de Firebase.
- `firestore.indexes.json firestore.indexes.EXP.json firestore.rules` : index et rules de Firestore, utilisé par CLI Firebase pour les déployer en production.
- `app.yaml` : pour le déploiement sur App Engine.

### Folders spécifiquement utilisés en DEV
- `config`
- `www wwwb` : storage des providers fs / fsb (file_system)
- `sqlite`
  - `*.db3` : des bases de test.
  - `delete.sql` : script pour RAZ d'une base
  - `schema.sql` : script de création d'une base db3
  - `schema.EXP.sql` : script exporté depuis une base existante par la commande `sqlite3 test1.db3 '.schema' > schema.EXP.sql` dans le folder `sqlite`.

### Rappel : variables d'environnement
Elles sont générées par `src/seveur.mjs` en fonction de `src/config.mjs` : elles n'ont pas à être gérées extérieurement.
- FIRESTORE_EMULATOR_HOST="localhost:8080"
- STORAGE_EMULATOR_HOST="http://127.0.0.1:9199"
- GOOGLE_CLOUD_PROJECT="asocial-test1"
- GOOGLE_APPLICATION_CREDENTIALS="./config.service_account.json"

## Déploiment et `src/config.mjs`
git met en place l'environnement de DEV : le fichier `src/config.mjs` est générique, d'ailleurs en fait celui de DEV et doit être adapté **à chaque site de déploiement**.

La commande `npm run build` créé dans `./dist` les fichiers à déployer.

Pour chaque déploiement à effectuer:
- utiliser un folder spécifique.
- y recopier les fichiers du folder `dist` généré par le build du serveur.
- y recopier, à la localisation prévue (typiquement `./app`), les fichiers du folder `dist` généré par le build de l'application UI.
- dans le folder `./config` (en général), copier les fichiers d'authenfication `service_account.json firebase_config.json s3_config.json` et `fullchain.pem privkey.pem` (sauf App Engine).

En conséquence il faut établir dans un folder spécifique de chaque type déploiement:
- les fichiers `config.mjs` et les 5 du folder `./config` correspondant à ce déploiement,
- exécuter un build pour le déploiement et y recopier les fichiers.

L'application UI est égelement configurable selon le déploiement choisi:
- `src/app/config.mjs` et `quasar.config.mjs` dépendent du déploiement,
- son build `quasar build -m pwa` est donc également spécifique du site déployé, le résultat étant à recopier dans le folder spécifique du déploiement

L'ensemble peut être scripté.

Le déploiement effectif s'effectue différemment selon App Engine ou un site entièrement géré.
