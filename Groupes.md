@@Index général de la documentation - [index](./index.md)

# Groupes et membres des groupes
Un avatar peut créer un **groupe** dans le but de partager des notes avec des avatars invités dans le groupe et ayant accepté cette invitation.

Les notes **d'un groupe** ne sont accessibles qu'aux membres du groupe.

Les données d'un groupe, notes et fichiers attachés, sont cryptés par une clé spécifique du groupe que seuls les membres du groupe ont reçu à leur invitation.

### Hébergeur du groupe
Un groupe a un membre **hébergeur** : les volumes des notes du groupe sont contraints par les quotas du compte de cet avatar. L'hébergeur du groupe risque de voir l'intégralité de ses quotas consommés par un seul groupe gourmand / indélicat ... et pour s'en protéger il fixe pour le groupe deux maximums de volumes V1 et V2 que les notes du groupe ne peuvent pas dépasser.
- la création / mise à jour d'une note du groupe ne peut pas mener au dépassement de ces maximum, ni à dépasser les quotas du compte de l'avatar hébergeur.
- si les maximum sont révisés à la baisse en dessous des volumes actuels, les notes ne peuvent être que révisées à la baisse : réduction de leur texte, remplacement d'un fichier par un fichier moins volumineux, pas de création.

L'hébergeur d'un groupe peut décider de ne plus l'être :
- les notes ne peuvent plus ni être crées, ni modifiés en croissance.
- si aucun membre ne se propose à devenir hébergeur, le groupe s'auto-détruit au bout d'un certain temps.

### Niveau de _pouvoir_ des membres d'un groupe
- un membre **lecteur** ne peut que lire les notes du groupe.
- un membre **auteur** peut lire, créer, modifier les notes du groupe et ajouter des _contacts_ au groupe.
- un membre **animateur** _en plus d'être auteur_ peut,
  - inviter des _contacts_ à rejoindre le groupe,
  - résilier des membres du groupe, sauf ceux eux-mêmes animateurs
  
Le créateur d'un groupe en est le premier animateur.

Un animateur peut agir sur les pouvoirs des autres membres non animateurs :
- dégrader le pouvoir d'un membre de *auteur* à *lecteur*,
- promouvoir un *lecteur* en *auteur* ou *animateur*,
- promouvoir un *auteur* à *animateur*.

### Modes d'invitation
Certains groupes peuvent souhaiter être un groupe _fermé_ ou n'y entre que les contacts faisant l'unanimité : un _couple_ par exemple n'a pas forcément envie qu'un des deux membres prenne la liberté d'inviter qui il veut.

Pour gérer cet aspect, il existe deux modes d'invitation :
- _simple_ : dans ce mode (par défaut) un _contact_ du groupe peut-être invité par un animateur (un suffit).
- _unanime_ : dans ce mode il faut que _tous_ les animateurs aient validé l'invitation (le dernier ayant validé provoque la validation).
- pour passer en mode _unanime_ il suffit qu'un seul animateur le demande.
- pour revenir au mode _simple_ depuis le mode _unanime_, il faut que tous les animateurs aient validé ce retour.

### État de participation d'un membre à un groupe
Sauf le créateur du groupe qui est directement _actif_, chaque membre du groupe passe par les états suivants:
- contact, 
- invité,
- invité ayant refusé,
- actif,
- résilié,
- disparu / oublié.

##### Contact
L'avatar est inscrit dans la liste des membres du groupe, mais lui-même ne le sait pas. Les autres membres peuvent voir sa carte de visite et débattre à son sujet. Tout membre _auteur_ ou _animateur_ peut inscrire un de ses contacts comme contact du groupe.

##### Invité
Un animateur peut inviter un membre _contact_ en tant que lecteur, auteur ou animateur. Tant qu'il dans l'état _invité_ le membre peut être retourné à l'état _contact_ par un animateur (annulant son invitation).

Un membre _invité_ voit la liste des membres du groupe et leurs cartes de visite ainsi que la carte de visite du groupe mais n'accède pas aux notes.

##### Invité ayant refusé
Le membre a pris connaissance de son invitation et l'a décliné. Un animateur pourra l'inviter à nouveau plus tard.

##### Actif
Le membre _invité_ a accepté son invitation : il accède à toutes les notes du groupe, même celles écrites avant leur arrivée dans le groupe.

Un animateur peut le _résilier_, le membre peut s'auto-résilier.

##### Résilié
Le membre a, éventuellement pendant un temps très court, été _actif_. Il s'est auto-résilié ou un animateur l'a résilié.

Un animateur pourra le ré-inviter plus tard.

##### Disparu / oublié
Le compte du membre a disparu, le membre ne peut plus se connecter et sa carte de visite n'est plus accessible. Le membre a pu être auteur de certaines notes : on n'y retrouve plus son nom mais un index dans la liste des auteurs des notes.

Un animateur peut provoquer _l'oubli_ d'un membre ou d'un contact : pour le groupe c'est comme s'il avait disparu, sa carte de visite n'est plus visible. Un membre peut déclarer son propre oubli.

## Processus de création d'un groupe

Un groupe est créé par un avatar qui lui attribue :
- un **nom** qui sera immuable et censé être a minima parlant pour ses membres.
- des volumes maximum V1 et V2 utilisables par les notes du groupe.

La création génère une clé de cryptage du groupe qui sert à crypter:
- les données du groupe et de ses membres,
- les notes et leurs fichiers attachés.

La clé est transmise aux membres lors de leur invitation.

L'avatar créateur a le pouvoir d'animation du groupe et en est hébergeur.

### Carte de visite d'un groupe

La **carte de visite** d'un groupe est modifiable par un animateur du groupe et comporte :
- une photo (logo, image ...) de petite dimension,
- un court texte décrivant l'objet du groupe.

Elle est mémorisée cryptée par la clé du groupe et est visible de tous les membres actifs du groupe.

### Ardoise du groupe
C'est un texte court, libre, partagé par les membres du groupes, pour y mettre des brèves, poser des questions, etc. C'est aussi sur l'ardoise qu'un invité mettra un mot de remerciement ou expliquera pourquoi il a décliné l'invitation.

### Mots clés d'un groupe
Un animateur peut définir des mots clés spécifiques du groupe qui pourront être attachés aux notes du groupe : ceci permet aux membres du groupe de partager des éléments communs d'indexation / filtrage des notes du groupe.

## Processus d'invitation d'un avatar à un groupe
Un animateur A peut _inviter_ un avatar pressenti :
- il fixe son niveau de pouvoir _lecteur_, _auteur_ ou _animateur_.
- il inscrit un mot de bienvenue sur l'ardoise.

L'avatar apparaît avec le statut *invité* dans la liste des membres.

L'avatar _invité_ voit apparaître dans sa liste des groupes un nouveau groupe où il apparaît comme _invité_ :
- il voit la carte de visite du groupe dont un court texte en donnant l'objet.
- il voit les membres du groupe, leurs cartes de visite et l'ardoise du groupe.
- il ne voit aucune note.
- il peut **refuser l'invitation**, en général avec un mot de courtoisie apparaissant sur l'ardoise à destination des autres membres du groupe. Il passe en statut *refusé*.
- il peut **accepter l'invitation**, en général avec un mot de courtoisie apparaissant sur l'ardoise à destination des autres membres du groupe. Il passe en état _actif_ et peut désormais
  - accéder aux notes et les indexer par des mots clés.
  - écrire sur l'ardoise du groupe s'il est au moins _auteur_.

Tout membre actif d'un groupe peut,
- s'auto-résilier,
- dégrader son propre pouvoir,
- _se faire oublier_ (s'auto-résilier et effacer sa carte de visite).

### Mots clés personnels et commentaire d'un membre
Tout membre actif du groupe peut :
- attacher à ce groupe des mots clés strictement personnels, qu'il sera seul à voir, afin de classer / filtrer ses groupes quand il participe à beaucoup d'entre eux.
- attacher à ce groupe un commentaire qui lui est propre, typiquement pour compléter le nom du groupe s'il n'est pas assez parlant pour lui.

## Archivage d'un groupe
Il est parfois souhaitable de considérer un groupe comme _archivé_, figé dans un état stable de référence, quitte à poursuivre des évolutions dans un groupe voisin. Un groupe peut être _protégé en écriture_ par un de ses animateurs : plus aucune note ne peut y être ajoutée / modifiée. Cette protection peut être levée par un animateur.

_Remarque_ : un groupe protégé contre l'écriture continue à avoir des mouvements de membres et ses notes peuvent être lues et copiées.

## Dissolution d'un groupe
Elle s'opère quand le dernier membre actif du groupe se résilie lui-même : toutes les notes sont détruites.

## Disparition d'un groupe
Quand le dernier membre actif d'un groupe passe en état _disparu_, le groupe s'auto-dissout, plus personne ne pouvant y accéder.

# En savoir plus ...
La clé de cryptage d'un groupe est générée à sa création. Le nombre de 16 chiffres identifiant le groupe est basé sur le _hash_ de cette clé.

### Synthèse des informations de l'enregistrement d'un groupe
- mode d'invitation _simple_ ou _unanime_.
- groupe protégé ou non contre la mise à jour, création, suppression de notes.
- hébergement :
  - jour de fin d'hébergement du groupe quand le groupe n'est plus hébergé.
  - avatar hébergeur quand il est hébergé.
- volumes actuels V1 et V2 occupés par les notes du groupe.
- volumes maximum V1 et V2 attribués par l'avatar hébergeur.
- liste des mots clés définis pour le groupe cryptée par la clé du groupe.
- ardoise du groupe.

### Synthèse des informations détenues pour chaque membre d'un groupe
Chaque membre a un index de membre qui l'identifie relativement au groupe.
- état du membre : _pressenti, invité, actif, refusé, résilié, disparu_.
- pouvoir du membre : _lecteur, auteur, animateur_.
- mots clés personnels attribués par le membre à propos du groupe.
- commentaire personnel du membre à propos du groupe.
- à propos de l'avatar membre, informations cryptées par la clé du groupe (lisibles donc par les autres membres) :
  - nom et clé de l'avatar.
  - carte de visite.
