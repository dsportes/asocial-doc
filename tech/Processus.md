# Boîtes à Secrets - Processus et opérations

## Création d'un nouveau compte, avatar

### Enregistrement d'un parrainage

**Client**
- Construction du row `parrain`.
- Construction du row `avcontact`.
- Maj du row `avidcc` pour y ajouter le filleul.
- *Argument de l'opération*
  - `sid` : id de la session.
  - `idp` : avatar parrain. (figure dans les 2 av...)
  - `idf` : avatar filleul.

**Opération**
- vérification d'unicité sur le début de la phrase de reconnaissance.
- Stockage / maj des rows.

**Synchronisation** 
- Rows `av...` transmis aux sessions dont `idp` est l'un des avatars du compte.
- inscription de `idf` dans la liste des avatars contacts

### Modification / annulation d'un parrainage


### Création d'un nouveau compte sur invitation
**Client**  

**Phase 1 : obtention du row `parrain` sur opération de lecture**
- `dpb` : PBKFD2 du début de la phrase de reconnaissance.
- `pcbs` : SHA du PBKFD2 de la phrase de reconnaissance complète.

**Phase 2 : acceptation**
- Maj du row `parrain` : 
  - `st` : (1) passe à 1. (3) passe à 0 ou 1
- Tirage d'un couple de clés RSA.
- Maj du row `avcontact` de P : textes d'invitation et réponse
- Création du row `compte` : la liste des avatars est réduite à 1.
- Création des row `avcontact avidcc avrsa` de F.
- *Argument de l'opération*
  - `sid dpb pcbs` : id de la session et données d'authentification.
  - `idap` de l'avatar du parrain.
  - `idcf` du compte du filleul.
  - `idaf` de l'avatar du filleul.
  - `q1 q2 qm1 qm2` : quotas.

**Phase 2 : refus**
- Maj du row `parrain` : `st` : (1) passe à 2.
- Maj du row `avcontact` de P : textes d'invitation et réponse
- *Argument de l'opération*
  - `sid dpb pcbs` : id de la session et données d'authentification.
  - `idap` de l'avatar du parrain.

**Opération : acceptation**
- maj du row `avcontact` du parrain.
- Insertion des rows `compte avidc1 avcontact avrsa`.
- insertion du row `avgrvq` de `idaf` avec les quotas
- maj du du row `avgrvq` de `idap`
- insertion des deux signatures dans `sga sgc`

**Synchronisation**
- `avcontact` du _parrain_ transmis.
- si acceptation création d'une nouvelle session `sid` : `idcf, idaf`
- `avcontact` : row transmis à `sid`.
- `avidc1` : row transmis à `sid`.
- `compte` : row transmis à `sid`.

### Création d'un nouveau compte privilégié
**Client**  
- construction d'un row `compte` et `avidc1` (vide mais crypté).
- *Argument de l'opération*
  - `sid` : id de la session
  - `pcb` : phrase complète d'administration.
  - `idc` : id du compte.
  - `ida` : id de son avatar.
  - `q1 q2 qm1 qm2` : quotas.

**Opération**
- insertion du row `compte` et `avidc1`.
  - insertion du row `avgrvq` de `ida` avec les quotas.
  - maj du du row `avgrvq` de la banque.
  - insertion des deux signatures dans `sga sgc`.

**Synchronisation**
- création d'une nouvelle session `sid` : `idc, ida`.
- `compte` : row transmis à `sid`.
- `avidc1` : row transmis à `sid`.

### Changement de phrase secrète
**Client**
- constitution du row `compte` avec la nouvelle phrase secrète.
- saisie de l'antivol ?
- *Argument de l'opération*
  - `sid` : id de la session.

**Opération**
- maj du row `compte`.

**Synchronisation**
- compte : row transmis à `sid`.
- envoi d'un message de fermeture de session pour cause de changement de phrase secrète aux sessions du compte `idc`. Moyen de bloquer les sessions d'éventuels hackers ayant récupéré la phrase ... mais aussi possibilité pour un hacker de voler un compte ??? Enregistrement d'une question / réponse _antivol_ ?

**Client : synchronisation de compte**
- si session *synchro*, maj du *LocalStorage*. Traitement aussi à prévoir dans le processus de connexion.

### Nouvel avatar
**Client**
- maj du row `compte`
- *Argument de l'opération*
  - `sid` : id de la session.
  - `idc` : id du compte.
  - `ida` : id de son avatar.
  - `idq` : id de l'avatar du compte offrant les quotas.
  - `q1 q2 qm1 qm2` : quotas passés à l'avatar.

**Opération**
- stockage du row compte.
  - insertion du row `avgrvq` de `ida` avec les quotas.
  - maj du du row `avgrvq` de `idq`.

**Synchronisation**
- maj des sessions du compte `idc` avec ajout de `ida` dans le contexte de session.
- `compte` : row transmis à toute sessions du compte `idc`.

### Maj des mots clés du compte (et _antivol_ ?)


### Création / mise à jour d'une carte de visite

### Modification de quotas pour un compte privilégié


### Don de quotas


## Création d'un groupe, invitation

### Création d'un groupe
**Client**
- maj de `avidc1`
- création d'un `avcontact`
- création de `grlmg`
- création d'un `grmembre`.
- *Argument de l'opération*
  - `sid` : de la session.
  - `ida` :
  - `idg` : id du groupe créé
  - `q1 q2`: quotas donnés (par `ida`)

**Opération**
- vérification de `v` sur `avidc1`.
- stockage des rows.
- maj des quotas entre `idg` et `ida`.
- signature du groupe `idg` dans `sgg`.

**Synchronisation**
- mise à jour des sessions des groupes (compte `idc`) avec ajout du groupe `idg`.
- `avidc1` sur ida
- `avcontact` sur ida
- `grlmg` sur idg
- `grmembre` sur idg

### Invitation à être membre d'un groupe
**Client**
- maj de `grlmg` pour `idm / nm` - `nc` est inconnu et le sera lors de l'acceptation de M.
- création d'un `avinvitgr` pour idm
- création d'un row `grmembre` pour idm (`idg / nm`)
- *Argument de l'opération*
  - `sid` : de la session.
  - `ida` :
  - `idm` :
  - `idg nm` : id du groupe

**Opération**
- vérification de `v` sur `grlmg`.
- stockage des rows `grlmg` `grmembre` `avinvitgr`.

**Synchronisation**
- mise à jour des sessions des groupes (compte `idc`) avec ajout du membre `idm` pour les cartes de visite à synchroniser.
- `grlmg` sur idg sur `ida` **et** sur `idm`. 
- `grmembre` sur idg sur `ida` **et** sur `idm`.
- ces deux rows vont apparaître comme nouveau en session, avec le statut d'invité pour l'avatar idm, d'où l'incitation à ce qu'il réponde.

### Acceptation de l'invitation à être membre
**Client**
- lecture de `avinvitgr`
- maj `avidcc` pour le groupe (ncg)
- maj `grlmg` pour ajouter `ncg` à l'entrée correspondant à idm.
- maj du row `grmembre` pour idm (statut et dnb)
- *Argument de l'opération*
  - `sid` : de la session.
  - `idm ncm` :
  - `idg nm` : id du groupe

**Opération**
- vérification de `v` sur `grlmg avidc1 grmembre`.
- stockage des rows `grlmg avidcc grmembre`.

**Synchronisation**
- `avidcc` sur idm
- `grlmg` sur idg
- `grmembre` sur idg

### Résiliation, changement de statut, notification par l'animateur 

### Auto résiliation d'un membre

## Invitation à être contact, mise à jour

### Création d'un contact simple
**Client**  
Le triplet `id cle pseudo` a été récupéré, soit sur un membre de groupe dont A est membre, soit sur une rencontre.  
- maj du row `avidcc` après génération d'un `cc`.
- création d'un row `avcontact`
- *Argument de l'opération*
  - `sid` : de la session.
  - `ida` :
  - `idb` :

**Opération**
- vérification de `v` sur `avidcc`.
- stockage des rows.

**Synchronisation**
- mise à jour des sessions des groupes (compte `idc`) avec ajout du contact `idb` dans leur liste de contacts pour carte de visite.
- `avidcc`
- `avcontact`

### Invitation par A de B à lier leurs contacts
**Client**
Création d'un row `avinvitct`.
- *Argument de l'opération*
  - `sid` : de la session.
  - `idb` :

**Opération**
- stockage du row `avinvitct`.

**Synchronisation**
- `avinvitct` sur idb.

### Acceptation par A de lier son contact avec B
**Client**
B n'était pas un contact de A
- création d'un row `avcontact` pour B
- création d'un `nc` pour B et maj `avidcc` pour le nc de B avec le cc reçu sur l'invitation.

B était déjà contact de A
- récupération de son nc et du cc de l'invitation.
- maj de `avidcc` pour y mettre le nouveau cc
- maj du `avcontact` de B avec dé-cryptage / cryptage de datac1 et datac2 par le nouveau cc communiqué par B

Lecture du row `avcontact` (nc de A dans B) de B et maj avec cryptage du `datac1` avec c2 valant le c1 de A.  
- *Argument de l'opération*
  - `sid` : de la session.
  - `ida ncb` :
  - `idb nca` :

**Opération**
- stockage des row `avidcc avcontact` de A.
- stockage des row `avcontact` de B.

**Synchronisation**
- `avidcc avcontact` (de A) sur ida.
- `avcontact` (de B) sur idb.

### Mise à jour du statut d'un contact C statut / tweet
**Client**  
- lecture du row `avcontact` (nc de A dans B) de B
- maj du row `avcontact` (nc de B dans A) de A
- maj du row `avcontact` (nc de A dans B) de B
- *Argument de l'opération*
  - `sid` : de la session.
  - `ida nb` : 
  - `idb nca` :

**Opération**
- vérification de `v` sur les `avcontact`.
- stockage des rows.

**Synchronisation**
- `avcontact` de A
- `avcontact` de B

### Suppression d'un contact simple C
**Client**  
- maj du row `avidcc`
- suppression du row `avcontact`.
- *Argument de l'opération*
  - `sid` : de la session.
  - `idc` : id du contact
  - `ida` :

**Opération**
- vérification de `v` sur `avidcc`.
- stockage de `avidcc`, suppression de `avcontact`.

**Synchronisation**
- `avidcc`
- `avcontact` (suppression)

### Focus sur un groupe ???
Pour mettre à jour la liste des membres en session dont la carte de visite est synchronisée.  
Ou sur un avatar ?  
Avec maj à l'occasion de création de contact ?  


## Création, mise à jour et partage de secrets

## Suppressions d'un avatar, d'un compte

## GC

# (Re) Synchronisation
Ne concerne que les modes *synchro* et *incognito*.

#### Authentification d'un compte
Dès qu'un compte a été authentifié sur le client par récupération du row `compte` auprès du serveur dans l'objet `Compte`, 
- en mode *synchro* : 
    - le nom de la base IDB étant désormais connu, la base est ouverte. Le _LocalStorage_ peut être mis à jour si la phrase secrète a changé (l'utilisateur ayant saisi la nouvelle).
    - l'objet `Compte` est sauvegardé sur IDB.
    - l'intégralité de la base est chargée en mémoire.
- en mode *incognito*, l'état de la mémoire se résume à l'objet `Compte`.

**Le processus de synchronisation** peut commencer. Il consiste à :
- amener en mémoire tous les objets relatifs au compte (sauf les secrets longs pour les groupes pour lesquels c'est facultatif),
- maintenir dans le serveur un objet `Session` représentant la spécification des rows qu'il faut synchroniser.
- recevoir au fil de l'eau par WebSocket dans le poste client les rows (créés / modifiés / supprimés) relatifs au compte,
    - transformer ces rows en objets mémoire,
    - en mode *synchro* sauvegarder ces objets sur IDB,
    - mettre à jour l'état de la mémoire.

**En cas de rupture du WebSocket de synchronisation**, il faut re-synchroniser la session cliente à partir de son état mémoire courant, c'est à dire enclencher à nouveau le processus long de synchronisation en considérant que l'objet `Compte` est en mémoire. Il n'est peut-être pas à jour mais le processus de synchronisation prévoit ce cas.

#### Création d'un compte
La création d'un compte est un processus court qui aboutit in fine à la récupération d'un objet Compte qui est sauvegardé sur IDB en mode *synchro*. On se trouve donc dans le même état qu'après authentification d'un compte existant vis à vis de la synchronisation.

#### Tables à synchroniser sur le client (IDB)

`compte` (idc) : authentification et données d'un compte  

**Fil AV** : structure des avatars
- `avidcc` (ida) : identifications et clés c1 des contacts d'un avatar  
- `avcontact` (ida, nc) : données d'un contact d'un avatar    
- `avinvitct` () (idb) : invitation adressée à B à lier un contact avec A  
- `avinvitgr` () (idm) : invitation à M à devenir membre d'un groupe G  
- `rencontre` (hps1) ida : communication par A de son identifications complète à un compte inconnu  

**Fil GR** : structure des groupes
- `grlmg` (idg) : liste des id + nc + c1 des membres du groupe  
- `grmembre` (idg, nm) : données d'un membre du groupe  

**Fil CV** : cartes de visite
- `cvsg` (id) : carte de visite d'un avatar ou groupe  

**Fil TS** : secrets
- `secret` (ida / idg) : données d'un secret

Les rows / objets des tables des fils **AV** et **AS** ont pour version un numéro pris dans une séquence spécifique de l'avatar alors que pour les autres c'est la séquence _universelle_.

#### Fils de synchronisation
La synchronisation est un processus long, en plusieurs *fils*, dont on doit suivre (et peut suivre en session cliente) l'état d'avancement. Fil par fil l'état de synchronisation passe de :
- à faire : un numéro de version de départ indique le plus haut numéro de version déjà présent en mémoire.
- en cours :  la requête d'obtention incrémentale des rows a été lancée mais son résultat pas encore traité.
- terminée : le numéro de version indique la version courante au moment de la sélection.
- intégrée : les mises à jours au fil de l'eau par WebSocket ont été intégrées.

Le fil **AV** par exemple correspond à la demande de tous les rows des tables du fil filtrée sur l'identification de l'avatar en une seule transaction qui retourne en plus des rows le numéro de version maximal pour cet avatar.

Dès le début du processus de synchronisation, le serveur va connaître la liste des compte / avatars / groupes intéressant la session cliente : celle-ci peut en conséquence commencer à recevoir par WebSocket des mises à jour concernant des fils dont la synchronisation n'est pas encore terminée. Ces rows sont mis en queue pour le fil en question et ne seront effectivement traités qu'au moment où la requête de synchronisation aura été terminée.

- chaque avatar a 4 fils : AV CV AS TS
- chaque groupe a 