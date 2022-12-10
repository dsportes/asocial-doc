@@Index général de la documentation - [index](./index.md)

# Contacts entre deux avatars
Un contact relie deux avatars :
- le _premier_ avatar est celui à l'initiative de la prise de contact,
- le _second_ avatar est celui contacté et ayant accepté ou refusé.

>L'avatar principal d'un compte a toujours au moins un contact dont il est _second_, l'avatar l'ayant parrainé y étant le _premier_. Les avatars secondaires d'un compte peuvent n'avoir aucun contact.

>Un contact relie deux avatars : quand un compte a deux avatars A1 et A2, les deux peuvent avoir pour contact un avatar C. Il existe bien 2 contacts, C voit deux contacts totalement distincts et n'a aucun moyen de savoir s'ils sont ou non avatars d'un même compte.

Hormis le cas d'un contact établi du fait du parrainage, un avatar A a deux moyens pour établir un contact avec un avatar C:
- solliciter C en tant que membre d'un même groupe que lui ou déjà contact d'un autre de ses avatars : dans ces deux cas, C est _déjà connu_ de A qui peut déjà lire sa carte de visite.
- prendre rendez-vous.

### _Prise de contact directe_ avec un avatar C déjà connu de A
A prend l'initiative cette prise de contact :
- A est le _premier_ avatar dans le contact, C est le _second_.
- A inscrit un petit mot de courtoisie pour C sur leur ardoise.
- A déclare les volumes maximum V1 et V2 qu'il accepte de consacrer aux secrets du contact.
  - A peut ainsi éviter d'avoir ses quotas trop largement impactés par des secrets pas forcément souhaités avec C. 
  - S'il déclare 0, il n'y aura pas de secrets partagés sur le contact : A et C ne communiqueront que par l'ardoise commune de leur contact.
- A peut cocher sa case _ne pas m'inviter_. Dans ce cas C ne pourra pas proposer A, ni comme membre d'un groupe, ni pour une prise de contact pour un autre de ses avatars.
- le contact est dans l'état **en attente**.

A la prochaine connexion de C, ou immédiatement s'il est connecté, C voit apparaître un nouveau contact, celui avec A, dans l'état **en attente**:
- C découvre la carte de visite de A et son petit mot de courtoisie sur l'ardoise.
- C peut **refuser le contact** qui passe en état **refusé** et inscrit un petit mot de courtoisie (ou non) à l'intention de A. C pourra revenir sur ce choix et accepter, pour autant que A n'ait pas supprimé le contact entre temps.
- C peut **accepter le contact** et,
  - mettre un petit mot de courtoisie (ou non) sur l'ardoise,
  - déclarer les volumes maximum V1 et V2 qu'il accepte de consacrer aux secrets du contact.
  - cocher sa case _ne pas m'inviter_. Dans ce cas A ne pourra pas proposer C, ni comme membre d'un groupe, ni pour une prise de contact pour un autre de ses avatars.
  - le contact passe en état **actif**.

>Remarque : A peut proposer un contact à C dont il a connaissance par ailleurs à plusieurs titres. Ne sont pas acceptés,
>- les membres d'un groupe n'étant pas _actif_ ou _résilié_ ou ayant la case _ne pas m'inviter_ cochée.
>- les contacts des autres avatars du compte n'étant pas _actif_ ou ayant la case _ne pas m'inviter_ cochée.
> En effet dans ces cas C n'a pas encore accepté, ou a explicitement déclaré ne pas vouloir être invitable.

### Prise de rendez-vous
A a connu le titulaire d'un compte en dehors du réseau, dans la vraie vie ou sur un réseau social, ou par l'intermédiaire d'un autre contact ou d'un _chat_ avec le Comptable. 

A va **prendre un rendez-vous** identifié par une phrase convenue, par exemple `Le lapin blanc d'Alice aime les framboises` : en effet A ne dispose pas de l'identité complète de C (sa carte de visite). 
- A est le _premier_ avatar dans le contact, C est le _second_.
- A donne le nom de C : C pourra au moins s'assurer _a minima_ que le rendez-vous le concerne bien. 
- A déclare, un petit mot de courtoise, des volumes maximum V1 et V2 à consacrer aux secrets du contact et coche ou non la case _ne pas m'inviter_.

Mais C ne peut pas être averti que A a pris rendez-vous, A ignorant à ce stade l'identifiant de C dans le réseau.  
C va alors prendre aussi rendez-vous en citant la même phrase  `Le lapin blanc d'Alice aime les framboises`. Au lieu de tomber sur la création d'un contact (qui a déjà été créé par A), il va tomber sur le formulaire d'acceptation ou de refus du contact:
- C découvre la carte de visite de A et le petit mot de courtoisie.
- comme dans la prise de contact directe C peut accepter ou refuser le contact.

##### C ne répond pas à la demande de rendez-vous de A
Le rendez-vous a une durée de vie limitée. Si C ne répond pas dans le délai maximal imparti, le contact passe en état **hors délai**.

A peut toutefois prolonger ce délai.

##### Cas d'un parrainage
Ce délai existe aussi : A voit ainsi dans ses contacts que sa proposition de parrainage est **hors délai** ou a été **refusée** avec en général un mot d'explication sur l'ardoise du contact.

## État d'un contact
Un contact peut avoir les états suivants :
- en attente,
- hors délai,
- refusé,
- actif,
- orphelin.

#### En attente
Dans cet état, A le _premier_ avatar du contact peut,
- **supprimer** le contact qui ne laisse aucune trace.
- **corriger** les informations (mot sur l'ardoise, quotas, case _ne pas m'inviter_).

#### Hors délai
Dans cet état, A le _premier_ avatar du contact peut,
- **supprimer** le contact qui ne laisse aucune trace.
- **prolonger** le contact qui repasse en état _en attente_ et éventuellement à cette occasion peut **corriger** les informations (mot sur l'ardoise, quotas, case _ne pas m'inviter_).

#### Refusé
Dans cet état, A le _premier_ avatar du contact peut, après avoir pris connaissance sur l'ardoise du contact de la motivation du refus par C,  **supprimer** le contact qui ne laisse aucune trace.

#### Actif
Le contact est désormais établi et ne peut plus être détruit sur initiative des avatars du contact.

Chacun peut :
- **corriger** les informations (mot sur l'ardoise, quotas, case _ne pas m'inviter_).
- écrire, lire, mettre à jour les secrets du contact dans le respect des quotas des deux avatars (du plus restrictif des deux).

#### Orphelin
L'un des deux contacts a _disparu_, il ne s'est pas connecté depuis plus d'un an.

Le contact resté en vie peut continuer à faire vivre le contact et en particulier faire vivre ses secrets mais il peut aussi le **supprimer** s'il ne voit plus d'intérêt à le conserver.

>Sauf les cas de **suppression** cités ci-dessus, un contact ne disparaît effectivement que quand ses deux avatars ont disparu, et qu'ils sont bien en peine de se connecter ! La disparition d'un contact va permettre de récupérer l'espace physique occupé par ses secrets. Détecter la disparition d'un contact par disparition de ses deux avatars est un défi technique puisque le lien entre un contact et chacun de ses avatars est crypté et que le serveur n'a pas les clés de cryptage. Voir pour ceux que ça intéresse la rubrique **Gestion des disparitions**.

## Synthèse des informations détenues sur un _contact_
A création du contact par son avatar _premier_, son numéro identifiant et la **clé de cryptage du contact** sont générés. La clé est communiquée au _premier_ avatar, puis au _second_, cryptée par leur clés personnelles respectives.

- **état** du contact.
- **origine** du contact :
  - _établi directement_,
  - _parrainage_ : la _phrase de parrainage_ est cryptée par la clé de cryptage du contact et lisible par le parrain tant que le contact est en attente.
  - _rendez-vous_ : la phrase de rendez-vous est cryptée par la clé de cryptage du contact et lisible par le premier avatar tant que le contact est en attente.
- **date limite de validité** : seulement en état _en attente_ et pour un contact initié par _parrainage_ ou _rendez-vous_.
- **premier avatar** :
  - son numéro identifiant et la clé de sa carte de visite (cryptés par la clé de cryptage du contact).
  - quotas maximum de volume V1 et V2 pour les secrets du contact.
  - case _ne pas m'inviter_.
  - mots clés personnels attribués par le premier avatar pour faciliter ses propres recherches / filtrages de ses contacts. Le second avatar n'en n'a pas connaissance.
- **second avatar** : mêmes informations.
- **ardoise** : texte d'au plus 250 signes, crypté par la clé de cryptage du contact, lisible et modifiable par les deux avatars.
- **volumes V1 et V2** occupés par les secrets du contact.

## Volumes des secrets d'un contact
### Cas _normal_, les deux avatars acceptent des secrets du contact
Les secrets du contact peuvent être crées, lus et mis à jour par les deux avatars.

Les volumes V1 et V2 de chaque secret sont décomptés sur les volumes V1 et V2 de chacun des avatars. La mise à jour ou la création d'un secret ne peut pas conduire,
- à dépasser les volumes maximaux définis sur le contact pour chacun des deux avatars,
- à dépasser les quotas V1 et V2 de chacun des avatars.

#### L'un des deux avatars décide de refuser le partage des secrets du contact
- cet avatar ne peut plus lire les secrets existants, ni les modifier, ni en créer de nouveaux.
- ses propres quotas sont crédités des volumes V1 et V2 des secrets du contact au moment de cette décision.

### Cas où un seul avatar accepte les secrets du contact
Les secrets du contact peuvent être crées, lus et mis à jour par ce seul avatar.

Les volumes V1 et V2 de chaque secret sont décomptés sur les volumes V1 et V2 de ce seul avatar. La mise à jour ou la création d'un secret ne peut pas conduire,
- à dépasser les volumes maximaux déclarés sur le contact par cet avatar,
- à dépasser les quotas V1 et V2 de l'avatar lui-même.

### Le second avatar décide d'accepter à nouveau le partage des secrets du contact
- il doit déclarer un volume maximal acceptable pour les secrets du contact supérieur au volume actuellement occupé.
- le volume occupé pour son avatar est augmenté des volumes des secrets du contact, sans dépasser ses quotas.
- il peut désormais lire, modifier et créer des secrets et accèdent à tous ceux existants sur le contact.

### Le seul contact acceptant de partager les secrets décide de ne plus les accepter
- les secrets du contact sont **détruits** : cet avatar ne peut plus lire les secrets existants, ni les modifier, ni en créer de nouveaux.
- ses propres quotas sont crédités des volumes V1 et V2 des secrets des contacts au moment de cette rupture.

## En savoir plus : identifiant et clé d'un _contact_
Un _contact_ est une entité à part entière ayant un identifiant et une **clé** de cryptage constituée de 32 octets (256 bits) tirés au sort à la création du _contact_. Elle crypte,
- les données **premier avatar**, **second avatar** et **ardoise** du _contact_
- les secrets du _contact_.

L'identifiant d'un avatar est le _hash_ de sa clé (un multiple de 4) + 1.

**_Remarque_** : la clé (et l'identifiant) d'un _contact_ d'un avatar est stockée cryptée par la clé K du compte de l'avatar dans la liste des contacts de l'enregistrement maître de l'avatar. Cette liste n'est donc accessible que dans l'application au cours d'une session connectée au compte de l'avatar (et n'est pas disponible sur le serveur, ni lisible dans la base centrale).
