@@Index général de la documentation - [index](./index.md)

# Groupes et membres des groupes
Un avatar peut créer un **groupe** dans le but de partager des secrets avec des avatars invités dans le groupe et ayant accepté cette invitation.

Les secrets **d'un groupe** ne sont accessibles qu'aux membres du groupe.

### Hébergeur du groupe
Un groupe a un membre **hébergeur** : les volumes des secrets du groupe sont contraints par les quotas de cet avatar. L'hébergeur du groupe risque de voir l'intégralité de ses quotas consommés par un seul groupe gourmand / indélicat ... et pour s'en protéger il fixe pour le groupe deux maximums de volumes V1 et V2 que les secrets du groupe ne peuvent pas dépasser.
- la création / mise à jour d'un secret du groupe ne peut pas mener au dépassement de ces maximum, ni à dépasser les quotas de l'avatar hébergeur.
- si les maximum sont révisés à la baisse en dessous des volumes actuels, les secrets ne peuvent être que révisés à la baisse : réduction de leur texte, remplacement d'un fichier par un fichier moins volumineux, pas de création.

L'hébergeur d'un groupe peut décider de ne plus l'être :
- les secrets ne peuvent plus ni être crées, ni modifiés en croissance.
- si aucun membre ne se propose à devenir hébergeur, le groupe s'auto-détruit au bout d'un certain temps.

### Niveau de _pouvoir_ des membres d'un groupe
- un membre **lecteur** ne peut que lire les secrets du groupe.
- un membre **auteur** peut lire, créer, modifier les secrets du groupe et pressentir de nouveaux membres.
- un membre **animateur** _en plus d'être auteur_ peut,
  - inviter des avatars pressentis à rejoindre le groupe,
  - résilier des membres du groupe, sauf ceux eux-mêmes animateurs
  
Le créateur d'un groupe en est le premier animateur.

Un animateur peut agir sur les pouvoirs des autres membres non animateurs :
- dégrader le pouvoir d'un membre de *auteur* à *lecteur*,
- promouvoir un *lecteur* en *auteur* ou *animateur*,
- promouvoir un *auteur* à *animateur*,

### État de participation d'un membre à un groupe
Sauf le créateur du groupe qui est directement _actif_, chaque membre du groupe passe par les états suivants:
- pressenti, 
- invité,
- refusé,
- actif,
- résilié,
- disparu.

##### Pressenti
L'avatar est inscrit dans la liste des membres du groupe, mais lui-même ne le sait pas. Les autres membres peuvent voir sa carte de visite et débattre à son sujet. Tout membre _auteur_ ou _animateur_ peut inscrire un de ses contacts ou un membre d'un autre groupe auquel il participe comme membre pressenti.

Les avatars potentiellement candidats à être pressenti, peuvent l'être à plusieurs titres : sont exclus les contacts non actifs, les membres de groupe ni actif ni résilié, et tous ceux ayant coché la cas _ne pas m'inviter_.

##### Invité
Un animateur peut inviter un membre pressenti, en tant que lecteur, auteur ou animateur. Tant qu'il dans l'état _invité_ le membre peut être retourné à l'état _pressenti_ par un animateur (annulant son invitation).

Un membre _invité_ voit la liste des membres du groupe et leurs cartes de visite ainsi que la carte de visite du groupe mais n'accède pas aux secrets.

##### Refusé
Le membre a pris connaissance de son invitation et l'a décliné. Un animateur pourra l'inviter à nouveau plus tard.

##### Actif
Le membre _invité_ a accepté son invitation :
- il accède à tous les secrets du groupe, même ceux écrits avant leur arrivée dans le groupe.
- il peut écrire sur les ardoises des autres membres s'il est au moins _auteur_ et toujours sur la sienne propre.

Un animateur peut le _résilier_, le membre peut s'auto-résilier.

##### Résilié
Le membre a, éventuellement pendant un temps très court, été _actif_. Il s'est auto-résilié ou un animateur l'a résilié.

Un animateur pourra le ré-inviter plus tard.

##### Disparu
Le compte du membre a disparu, le membre ne peut plus se connecter et sa carte de visite n'est plus accessible. Toutefoiçs comme le membre a pu être auteur de certains secrets, on peut retrouver son _nom_ dans la liste des auteurs des secrets.

## Processus de création d'un groupe

Un groupe est créé par un avatar qui lui attribue :
- un **nom** qui sera immuable et censé être a minima parlant pour ses membres.
- des volumes maximum V1 et V2 utilisables par les secrets du groupe.

La création génère une clé de cryptage du groupe qui sert à crypter:
- les données du groupe et de ses membres,
- les secrets du groupe.

La clé est transmise aux membres lors de leur invitation.

L'avatar créateur a le pouvoir d'animation du groupe et en est hébergeur.

### Carte de visite d'un groupe

La **carte de visite** d'un groupe est modifiable par un animateur du groupe et comporte :
- une photo (logo, image ...) de petite dimension,
- un court texte décrivant l'objet du groupe.

Elle est mémorisée cryptée par la clé du groupe et est visible de tous les membres actifs du groupe.

### Mots clés d'un groupe
Un animateur peut définir des mots clés spécifiques du groupe qui pourront être attachés aux secrets du groupe : ceci permet aux membres du groupe de partager des éléments communs d'indexation / filtrage des secrets du groupe.

## Processus d'invitation d'un avatar à un groupe
Un animateur A peut _inviter_ un avatar pressenti :
- il fixe son niveau de pouvoir _lecteur_, _auteur_ ou _animateur_.
- il inscrit un mot de bienvenue sur son ardoise.

L'avatar apparaît avec le statut *invité* dans la liste des membres.

L'avatar _invité_ voit apparaître dans sa liste des groupes un nouveau groupe où il apparaît comme _invité_ :
- il voit la carte de visite du groupe dont un court texte en donnant l'objet.
- il voit les membres du groupe, leurs cartes de visite et leurs ardoises personnelles dans le groupe.
- ine voit aucun secret.
- il peut **refuser l'invitation**, en général avec un mot de courtoisie apparaissant sur son ardoise à destination des autres membres du groupe. Il passe en statut *refusé*.
- il peut** accepter l'invitation**, en général avec un mot de courtoisie apparaissant sur son ardoise à destination des autres membres du groupe. Il passe en état _actif_ et peut désormais
  - accéder aux secrets  et les indexer par des mots clés.
  - écrire sur les ardoises des autres membres s'il est au moins _auteur_ et toujours sur la sienne propre.

Tout membre actif d'un groupe peut,
- s'auto-résilier,
- dégrader son propre pouvoir.

### Mots clés personnels et commentaire d'un membre
Tout membre actif du groupe peut :
- attacher à ce groupe des mots clés strictement personnels, qu'il sera seul à voir, afin de classer / filtrer ses groupes quand il participe à beaucoup d'entre eux.
- attacher à ce groupe un commentaire qui lui est propre, typiquement pour compléter le nom du groupe s'il n'est pas assez parlant pour lui.

## Archivage d'un groupe
Il est parfois souhaitable de considérer un groupe comme _archivé_, figé dans un état stable de référence, quitte à poursuivre des évolutions dans un groupe voisin. Un groupe peut être _protégé en écriture_ par un de ses animateurs : plus aucun secret ne peut y être ajouté / modifié. Cette protection peut être levée par un animateur.

_Remarque_ : un groupe protégé contre l'écriture continue à avoir des mouvements de membres et ses secrets peuvent être copiés.

## Fermeture d'un groupe
Dans certaines situations quelques membres d'un groupe peuvent être réticents à partager des secrets, non pas avec les membres actuels qu'ils ont acceptés en acceptant l'invitation, mais vis à vis de membres futurs à qui ils ne font pas forcément confiance a priori sans les connaître.

La solution consiste pour un animateur à _fermer_ un groupe : les nouvelles invitations n'y sont plus possibles.

Pour rouvrir un groupe il faut que **tous** les animateurs aient _voté_ vouloir le rouvrir.

## Dissolution d'un groupe
Elle s'opère quand le dernier membre actif du groupe se résilie lui-même : tous les secrets sont détruits.

## Disparition d'un groupe
Quand le dernier membre actif d'un groupe passe en état _disparu_, le groupe s'auto-dissout, plus personne ne pouvant y accéder.

# En savoir plus ...
La clé de cryptage d'un groupe est générée à sa création. Le nombre identifiant est le _hash_ de cette clé (un entier sur 53 bits multiple de 4) + 2.

### Synthèse des informations de l'enregistrement d'un groupe
- groupe, _ouvert_ acceptant de nouveaux membres), _fermé_ n'en n'acceptant plus ou _en ré-ouverture_ (les animateurs votent).
- groupe protégé ou non contre la mise à jour, création, suppression de secrets.
- hébergement :
  - jour de fin d'hébergement du groupe par son hébergeur quand le groupe n'est plus hébergé.
  - numéro de l'avatar hébergeur crypté par la clé du groupe.
  - index du membre hébergeur dans le groupe.
- volumes actuels V1 et V2 occupés par les secrets du groupe.
- volumes maximum V1 et V2 attribués par l'avatar hébergeur.
- liste des mots clés définis pour le groupe cryptée par la clé du groupe.

### Synthèse des informations détenues pour chaque membre d'un groupe
Chaque membre a un index de membre qui l'identifie relativement au groupe.

- état du membre : _pressenti, invité, actif, refusé, résilié, disparu_.
- pouvoir du membre : _lecteur, auteur, animateur_.
- option _ne pas m'inviter_.
- en cas de ré-ouverture du groupe soumise au vote, a voté pour la réouverture.
- mots clés personnels attribués par le membre à propos du groupe.
- commentaire personnel du membre à propos du groupe crypté par la clé K du membre.
- à propos de l'avatar membre, informations cryptées par la clé du groupe (lisibles donc par les autres membres) :
  - nom et clé de l'avatar.
  - numéro interne de l'invitation.
  - numéro d'avatar du membre l'ayant pressenti.
- ardoise du membre vis à vis du groupe. Couple `[date-heure, texte]` crypté par la clé du groupe. Contient successivement,
  - le texte de courtoisie de l'invitation,
  - la réponse de l'invité ayant accepté ou décliné l'invitation,
  - puis les textes écrits par les membres (actifs et au moins auteurs) ou le membre lui-même.
