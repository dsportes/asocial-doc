# API : opérations supportées par le serveur

Les opérations sont invoquées sur l'URL du serveur : `https://.../op/MonOp1`
- **GET** : le vecteur des arguments nommés sont dans le queryString :
  ../op/MonOp1&arg1=v&&arg2=v2 ...
  Ils se retrouvent à disposition dans l'opération dans l'objet args :
  { **arg1**: V&, arg2: v2 }
- **POST** : le body de la requête est la sérialisation de l'array `[args, apitk]` :
  - `args` : `{ arg1: v1, arg2: v2 ... }`
  - `apitk` : string donnant l'autorisation du client à utiliser l'API. Cette information figure en configuration du serveur et côté client dans process.env.APITK qui a été forcée lors du build webpack.

### `args.token` : le jeton d'authentification du compte
Requis dans la quasi totalité des requêtes ce jeton est formé par la sérialisation de la map { sessionId, shax, hps1 } où :
- `sessionId` : identifiant aléatoire (string) de session générée par l'application pour s'identifier elle-même (et transmise sur WebSocket en implémentation SQL).
- `shax` : SHA256 du PBKFD de la phrase secrète en UTF-8.
- `hps1` : Hash (sur un entier _safe_ en Javascript) du SHA256 de l'extrait de la phrase secrète.

L'extrait consiste à prendre les bytes [0, 2, 4, 5, 8, 9, 12, 14, 18, 19, 23, 25, 28, 30] de la représentation en UTF-8 de la phrase complète.

### Headers requis
- `origin` : site Web d'où l'application Web a été chargée. Au cas ou origin ne peut pas être obtenu, c'est `referer` qui est considéré. Les origines autorisées sont listées.
- `x-api-version` : numéro de version de l'API pour éviter un accès par des sessions ayant été chargées par une application _retardée_ par rapport au serveur.

### Retour des requêtes
- status HTTP 200 : OK
- status HTTP 400 401 402 403 : exceptions trappées par le serveur ,:
  - 400 : F_SRV fonctionnelles
  - 401 : A_SRV assertions
  - 402 : E_SRV exception inattendue trappée dans le traitement
  - 403 : E_SRV exception inattendue NON trappée dans le traitement
  - le texte de l'erreur est un texte JSON : `{ code, args: [], stack }`
  - à détection au retour d'une requête, une exception AppExc est générée depuis ces données.
- autre statuts (500, 0 ...) : une exception AppExc est générée (E_SRV, 0, ex.message)

#### Retour OK d'un GET
- requêtes yo et yoyo : texte.
- autres : arrayBuffer (binaire).

#### Retour OK d'un POST
Le terme binaire est désérialisé, on en obtient une map dont les éléments sont :
- de manière générique :
  - `dh` : le getTime de l'exécution de la transaction,
  - `sessionId` : la valeur de sessionId passée dans le token en argument ou 666
  - les autres termes sont spécifiques du _retour_ de chaque opération.

## Opérations SANS authentification

### `yo` : ping du serveur
GET - pas d'arguments `../op/yo`

Ping du serveur SANS vérification de l'origine de la requête.

Retourne 'yo' + la date et l'heure UTC

### `yoyo` : ping du serveur
GET - pas d'arguments `../op/yoyo`

Ping du serveur APRES vérification de l'origine de la requête.

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

## Opérations authentifiées par l'administrateur

### `CreerEspace` : création d'un nouvel espace et du comptable associé
POST:
- `token` : jeton d'authentification du compte de **l'administrateur**
- `rowEspace` : row de l'espace créé
- `rowAvatar` : row de l'avatar du comptable de l'espace
- `rowTribu` : row de la tribu primitive de l'espace
- `rowTribu2` : row tribu2 de la tribu primitive avec l'entrée pour le compte comptable
- `rowCompta` : row du compte du comptable
- `rowVersion`: row de la version de l'avatar (avec sa dlv) 

Retour: rien si OK (sinon exceptions)

Règles de gestion à respecter par l'appelant
- tous les rows passés en argument doivent être cohérents entre eux et se rapporter au nouvel espace à créer. Rien n'est vérifiable ni vérifié  par l'opération.

### `SetNotifG` : déclaration d'une notification à un espace par l'administrateur
POST:
- `token` : jeton d'authentification du compte de **l'administrateur**
- `ns` : id de l'espace notifié
- `notif` : sérialisation de l'objet notif, cryptée par le rnd du comptable de l'espace. Ce rnd étant public, le cryptage est symbolique et vise seulement à éviter une lecture simple en base.
  - `idSource`: id du Comptable ou du sponsor, par convention 0 pour l'administrateur.
  - `jbl` : jour de déclenchement de la procédure de blocage sous la forme `aaaammjj`, 0 s'il n'y a pas de procédure de blocage en cours.
  - `nj` : en cas de procédure ouverte, nombre de jours après son ouverture avant de basculer en niveau 4.
  - `texte` : texte informatif, pourquoi, que faire ...
  - `dh` : date-heure de dernière modification (informative).

Retour: rien

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
- le compte _Administrateur_ n'est pas vraiement un compte mais simplement une autorisation d'applel des opérations qui le concernent lui seul. Lehash de sa phrase secrète est enregistrée dans la configuration du serveur.
- le compte _Comptable_ de chaque espace est créé par l'administrateur à la création de l'espace. Ce compte est normal. Sa phrase secrète a été donnée par l'administrateur et le comptable est invité à la changer au plus tôt.
- les autres comptes sont créés par _acceptation d'un sponsoring_ qui fixe la phrase secrète du compte qui se créé : après cette opération la session du nouveau compte est normalement active.
- les deux opérations suivantes sont _autnentifiées_ et transmettent les données d'authenfication par le _token_ passé en argument porteur du has de la phrase secrète: dans le cas de l'acceptation d'un sponsoring, la reconnaissance du compte précède de peu sa création effective.

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
- `mbtrid` : id de son élément `mbtr` dans tribu2. Cet id est le hash de la clé `rnd` du membre.
- `mbtre` : élément de la map `mbtr` dans tribu2 associé au compte créé.
- `quotas` : `[v1, v2]` quotas attribués par le sponsor.

Retour: rows permettant d'initialiser la session avec le nouveau compte qui se trouvera ainsi connecté.
- `rowTribu`
- `rowTribu2`
- `rowChat` : le chat _interne_, celui concernant le compte.
- `credentials` : données d'authentification permettant à la session d'accéder au serveur de données Firestore.
- `rowEspace` : row de l'espace (informations générales / statistques de l'espace et présence de la notification générale éventuelle.

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
- insertion du row membre, maj groupe

Retour:
- KO : true si l'indice im est déjà attribué.


## Purgatoire : opérations pas encore ou plus utilisées

### `ChargerCvs` : retourne les cartes de visite dont les versions sont postérieures à celles détenues en session
(PAS UTILISE)

POST:
- `token` : éléments d'authentification du compte.
- `mcv` : map,
  - _clé_ : id, 
  - _valeur_ : version détenue en session (ou 0).

Retour:
- `rowCvs` : array des row Cv `[{ _nom: 'cvs', id, _data_ } ...]`
  _data_ : `{v, photo, info}` sérialisé et crypté par la clé de son avatar.


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

# Annexe II : requêtes spécifiques (25)
TODO : à reprendre complètement.

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

# Annexe III : implémentations
Deux implémentations sont disponibles : SQL et Firestore.

## SQL
Elle utilise une base de données `SQLite` comme support de données persistantes :
- elle s'exécute en tant que serveur HTTPS dans un environnement **node.js**.
- le serveur sert aussi l'application Web front-end : quelques fichiers après build par _webpack_.
- une session de l'application est connectée par WebSocket qui lui notifie les mises à jour compta, tribu et versions (avatar et groupe) qui la concerne et auxquelles elle s'est _abonnée_.
- les backups de la base peuvent être stockés sur un Storage.
- le Storage des fichiers peut-être,
  - soit un file-system local du serveur,
  - soit un Storage S3 (éventuellement minio).
  - soit un Storage Google Cloud Storage.

Un utilitaire **node.js** peut extraire et charger un seul espace.

## Firestore + GAE (Google App Engine)
Le stockage persistant est Google Firestore.
- en mode serveur, un GAE de type **node.js** sert de serveur
- le stockage est assurée par Firestore : l'instance FireStore est découplée du GAE, elle a sa propre vie et sa propre URL d'accès. En conséquence elle _peut_ être accédée depuis n'importe où, et typiquement par un utilitaire d'administration sur un PC pour gérer un upload/download avec une base locale _SQLite_ sur le PC.
- une session de l'application reçoit de Firestore les mises à jour sur les compta, tribu et versions qui la concerne, par des requêtes spécifiques.
- le Storage est Google Cloud Storage

Un utilitaire **node.js** local peut accéder à un Firestore distant:
- exporte un Firestore distant (ou local de test) dans une base SQLite locale.
- importe dans un Firestore distant (ou local de test) vide une base SQLite locale.
- opérations effectuées globalement ou pour un seul espace.
