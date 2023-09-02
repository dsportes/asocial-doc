@@Index général de la documentation - [index](./index.md)

@@Introduction - [index](./README.md)

# Vue d'ensemble de l'application

Une organisation, association, des amis ... peut décider de créer et d'utiliser son propre réseau a-social et a choisi un hébergeur. Les personnes peuvent accéder à ce réseau depuis un navigateur par une URL comme https://monreseau.monhebergeur.net/

Ce serveur Web permet d'obtenir l'application et gère aussi un serveur d'arrière plan contrôlant les accès à la base centrale où les données de chaque organisation sont stockées.

## Avatars, notes, groupes
Pour pouvoir accéder à l'application une personne doit **se faire sponsoriser par une autre y ayant déjà un compte**. Un _sponsoring_ est identifié par une _phrase de sponsoring_ : sponsor et sponsorisé se sont concertés sur le nom du sponsorisé, par exemple `Charles` et la phrase qui reste secrète entre eux, par exemple `le hibou n'est pas chouette`. 

Le sponsorisé crée ensuite lui-même son compte en fournissant cette phrase de parrainage : si le sponsor l'a bien enregistrée, le sponsorisé déclare sa **phrase secrète de connexion**:
- elle a au moins 24 signes et reste uniquement dans la tête du titulaire, n'est enregistrée sous aucune forme nulle-part : elle pourra être changée à condition de pouvoir fournir celle actuelle.
- le début de la phrase, environ la première moitié, ne doit pas _ressembler_ au début d'une phrase déjà enregistrée afin d'éviter de tomber par hasard sur la phrase d'un autre compte.
- la phrase secrète crypte toutes les données du compte aussi bien dans la base centrale que dans les micro bases locales de chacun des navigateurs utilisés par le compte. Un piratage des appareils des titulaires des comptes ou de la base centrale centrale ne donnerait au _pirate_ que des informations indéchiffrables.

> _Revers de cette sécurité_ : si la personne titulaire d'un compte oublie sa **phrase secrète de connexion**, elle est ramenée à l'impuissance du pirate. Son compte s'autodétruira un jour et toutes ses données et notes disparaîtront.

### Avatars principal et secondaires
En créant son compte, le titulaire a créé son **avatar principal**. Un avatar dispose:
- d'un _numéro_ identifiant de 16 chiffres aléatoire et immuable ne portant aucune information utile.
- d'un **nom** lui-même aussi immuable, par exemple `Charles`.
- d'une **carte de visite** constituée d'une photo facultative et d'un court texte, par exemple `Charles III, roi des esturgeons et d’Écosse`, tous deux modifiables uniquement par son titulaire.

Ultérieurement le titulaire du compte peut créer des **avatars secondaires**, chacun ayant un numéro, un nom et une carte de visite. Il peut ensuite utiliser à son gré des circonstances l'un ou l'autre de ses avatars, ayant de ce fait plusieurs personnalités.

> **Le titulaire du compte est le seul à connaître la liste de ses avatars secondaires**: un autre compte connaissant deux avatars n'est jamais en mesure de savoir s'ils correspondent au même titulaire ou non et même l'administrateur technique du site ne peut pas s'affranchir de cette contrainte assise sur une cryptographie forte.

Selon la situation un avatar peut avoir connaissance d'un autre,
- parfois et rarement par son seul numéro (autant dire rien),
- son numéro et son nom,
- son numéro, son nom et **sa carte de visite cryptée**: dans ce dernier cas **c'est réciproque** et a été assumé / voulu explicitement de part et d'autre.

> Comme dans la vraie vie **plusieurs avatars peuvent porter le même "nom"**, les homonymes sont possibles : à l'écran les 4 derniers chiffres du numéro identifiant permet certes de distinguer `Charles#9476` et `Charles#5432` mais ce sont surtout les cartes de visite de chacun qui donneront des informations pertinentes pour distinguer Charles "le _général_" de Charles "_le roi des esturgeons_".

### Notes
**Un note porte un texte** d'au plus 5000 caractères pouvant s'afficher avec un minimum de _décoration_, gras, italique, titres, listes ... Ce texte est modifiable.

**Des fichiers peuvent être attachés à une note** : beaucoup de types de fichiers (`.jpg .mp3 .mp4 .pdf ...`) s'affichent directement dans le navigateur. Il est possible d'ajouter et de supprimer des fichiers attachés à une note: plusieurs fichiers portant le même nom dans la note sont vus comme des révisions successives.

**Une note peut faire référence à UNE note _parent_** : les notes apparaissent à l'écran sous forme hiérarchique. Les notes _racine_ n'en référence aucune autre, et in fine les notes _feuilles_ ne sont référencées par aucune autre.

> Un avatar peut se créer des notes **personnels**, les mettre à jour, les supprimer, les indexer par des mots clés personnels. Ces notes sont cryptées comme toutes les données des compte et seul le titulaire du compte a la clé de cryptage apte à les décrypter, laquelle ne pouvant être obtenue qu'en ayant fourni la phrase secrète en se connectant au compte.

### Groupes
Un avatar peut créer un **groupe** dont il sera le premier membre et _animateur_. Un groupe a un numéro interne, un nom immuable et une carte de visite. Un groupe a aussi une _ardoise_ portant quelques informations ou brèves partagées dans le groupe.

N'importe quel membre du groupe peut inscrire un des avatars qu'il connaît comme _contact_ du groupe : les autres membres peuvent ainsi discuter de ce contact et de l'opportunité à `l'inviter` à rejoindre le groupe.

Puis un animateur peut _inviter_ un contact à rejoindre le groupe en tant que _simple lecteur_, _auteur_ ou _animateur_ : un lecteur n'a que les droits de lecture, un auteur peut créer et mettre à jour des notes du groupe et un animateur en plus d'être auteur peut inviter des avatars.

L'invité ne fera partie du groupe qu'après avoir accepté l'invitation et il peut la refuser. Nul ne fait partie d'un groupe sans l'avoir **explicitement** voulu.

Tous les membres d'un groupe accèdent à la carte de visite de tous les membres.

**Chaque membre du groupe peut créer, modifier et supprimer des notes du groupe.**
- ces notes sont cryptées par une clé aléatoire spécifique au groupe qui a été transmise lors de leur invitation au groupe.
- hormis les membres du groupe, personne ne peut accéder aux notes du groupe ni même savoir que le groupe existe.
- quand un nouveau membre accepte une invitation au groupe il a immédiatement accès à toutes les notes du groupe et quand il est résilié, ou s'est auto-résilié, il n'a plus accès à aucune de celles-ci.
- pour écrire / modifier / supprimer une note du groupe, il faut en être un membre _animateur_ ou _auteur_ (un _lecteur_ ne peut que lire).

Un membre peut attacher ses propres mots clés à un groupe afin de faciliter sa recherche quand il est membre de beaucoup de groupes.

Il peut aussi attacher ses propres mots clés aux notes du groupe pour sélectionner plus rapidement celles qu'il recherche, par centre d'intérêt, importance, etc.

Comme pour une note personnelle une note de groupe peut être rattachée à une note parent du groupe, ce qui fait apparaître visuellement à l'écran une hiérarchie.

### "Chats" entre avatars
Deux avatars en contact peuvent ouvrir une _ardoise de chat_ commune sur laquelle ils peuvent écrire un texte de moins de 5000 signes, modifiable à loisir par l'un ou l'autre.

Une fois créée une ardoise ne disparaît que quand les deux avatars qui la partagent ont disparu. Chacun peut effacer le texte de l'ardoise et chacun peut attacher au _chat_ ses propres mots clés (par exemple _poubelle_ ou _important_ ...) que l'autre ne voit pas.

Pour partager une ardoise de chat avec un avatar B, un avatar A doit connaître son interlocuteur B par son nom complet c'est à dire avec _sa carte de visite_:
- B est membre d'un des groupes auxquels A participe,
- B a sponsorisé A ou A a sponsorisé B,
- B est un compte _sponsor_ avec qui A partage la même tranche de quotas -voir plus avant le détail sur ce concept-,
- A a connaissance d'une **phrase de contact** de B.

#### Établissement d'un chat par une _phrase de contact_
B peut déclarer une _phrase de contact_, unique dans l'application et pas trop semblable à une déjà déclarée. Par exemple : `les courgettes sont bleues au printemps`
- B peut la changer ou la supprimer à tout instant.
- B peut communiquer, par un moyen de son choix, cette phrase à A qui peut ainsi ouvrir une ardoise de chat avec B. Il pourra aussi proposer à B d'intégrer un de ses groupes et plus si affinités ...

> Il est recommandé que les _phrases de contact_ aient une durée de vie le plus limité possible afin d'éviter que des personnes non souhaitées ouvrent une ardoise de chat (ce qui a toutefois un impact limité, on n'est pas obligé de la lire!).

Dès qu'une ardoise de chat est ouverte entre A et B, leurs cartes de visite sont mutuellement visibles.

# Modes *synchronisé*, *incognito* et *avion*
Pour se connecter à son compte, le titulaire choisit d'abord sous quel **mode** sa session va s'exécuter: _synchronisé_, _avion_ ou _incognito_.

#### Mode _synchronisé_ 
C'est le mode préférentiel où toutes les données du compte sont stockées dans une micro base locale cryptée dans le navigateur puis remises à niveau depuis le serveur central à la connexion d'une nouvelle session. Durant la session la micro base locale est maintenue à jour, y compris lorsque d'autres sessions s'exécutent en parallèle sur d'autres navigateurs et mettent à jour les données du compte : par exemple quand une note de groupe est mise à jour par un autre membre du groupe.

La connexion ultérieure à un compte ainsi synchronisé est rapide, l'essentiel des données étant déjà dans le navigateur, seules quelques _nouveautés_ sont tirées du serveur central.

#### Mode _avion_
Pour que ce mode fonctionne il faut qu'une session antérieure en mode _synchronisé_ ait été exécutée dans ce navigateur. L'application présente à l'utilisateur l'état dans lequel étaient ses données à la fin de la dernière session synchronisée pour ce compte dans ce navigateur.

**L'application ne fonctionne qu'en lecture**, aucune mise à jour n'est possible. Aucun accès à Internet n'est effectué, ce qui est précieux _en avion_ ou dans les _zones blanches_ ou quand l'Internet est suspecté d'avoir de grandes oreilles indiscrètes : certes tout est crypté et illisible mais en mode avion personne ne peut même savoir que vous accédez à vos notes, votre appareil peut être physiquement isolé du Net.

En mode avion les fichiers attachés aux notes ne sont pas accessibles, **sauf** ceux qui ont été déclarés devoir l'être. Cette déclaration pour un compte s'effectue fichier par fichier pour chaque navigateur et ils sont mis à niveau à l'ouverture de chaque session en mode _synchronisé_ (puis en cours de session).

> Il est conseillé de couper le réseau (le mode _avion_ sur un mobile), de façon à ce que l'ouverture de l'application ne cherche même pas à vérifier si une version plus récente est disponible.

#### Mode _incognito_
**Aucun stockage local n'est utilisé, toutes les données viennent du serveur central**, l'initialisation de la session est plus longue qu'en mode synchronisé. Aucune trace n'est laissée sur l'appareil (utile au cyber-café ou sur le mobile d'un.e ami.e) : certes les traces en question sont inutilisables car cryptées, mais il n'est pas poli d'encombrer la mémoire d'un appareil qu'on vous a prêté.

> Il est conseillé d'utiliser le mode _page privée_ de votre navigateur, ainsi même le code de l'application sera effacé en fermant la page de l'application.

> **En utilisant des sessions synchronisées sur plusieurs appareils, on a autant de copies synchronisées de ses notes sur chacun de ceux-ci**, et chacun peut être utilisé en mode avion. Les copies ne sont pas exactement les mêmes, les _photographies_ de l'état des données du compte ne pouvant pas être effectuées exactement à la même micro seconde.

> **L'application invoquée depuis un navigateur y est automatiquement mémorisée** : au prochain appel, étant déjà présente en local, elle ne chargera éventuellement que le minimum nécessaire pour se mettre à niveau de la version logicielle la plus récente.

# Répartition des coûts d'hébergement de l'application
Le coût d'usage de l'application pour une organisation correspond aux coûts d'hébergement des données et de traitement de celles-ci. Selon les techniques et les prestataires choisis, les coûts unitaires varient mais existent dans tous les cas.

#### Abonnement
Il correspond aux coûts récurrents mensuels pour un compte même quand il ne se connecte pas. Par simplification ils ont été résumés ainsi:
- **(V1) Volume des données sur la base de données**. Il est calculé par la multiplication d'un facteur forfaitaire par le nombre de,
  - **(nn) notes** personnelles et notes d'un groupe hébergé par le compte,
  - **(nc) chats** en ligne, 
  - **(ng) participations aux groupes**.
- **(V2) Volume des fichiers attachés aux notes** stocké sur un _Storage_.

Pour obtenir le coût correspondant à ces deux volumes il est pris en compte, non pas _le volume effectivement utilisé à chaque instant_ mais **les _quotas_ Q1 et Q2** choisis par le compte, c'est à dire **l'espace maximal** auquel il s'abonne et qui a été réservé à cet effet.

> Les volumes _effectivement utilisés_ ne peuvent pas dépasser les quotas attribués, sauf dans le cas où les quotas ont été volontairement réduits a posteriori en dessous des volumes actuellement utilisés.

#### Consommation de calcul
Ces coûts de _calcul_ correspondent directement à l'usage fait de l'application quand une session d'un compte est ouverte. Il dépend de _l'usage_ du titulaire du compte, de son activité et de la façon dont il se sert de l'application. Le coût de calcul est la somme de 4 facteurs, chacun ayant son propre tarif:
- **(nl) nombre de _lectures_** (en base de données): nombre de notes lues, de chats lus, de contacts lus, de membres de groupes lus, etc. **Lu** signifie extrait de la base de données. Pour un même service apparent, le coût des _lectures_ peut différer fortement typiquement en utilisant le mode _synchronisé_, voire _avion_ où est par principe même nul.
- **(ne) nombre _d'écritures_** (en base de données): outre quelques écritures techniques indispensables, il s'agit principalement des mises à jour des données, notes, chats, cartes de visite, commentaires personnels, etc.
- **(vd) volume _descendant_** (download) de fichiers téléchargés depuis le _Storage_.
- **(vm) volume _montant_** (upload) de fichiers envoyés dans le _Storage_. Chaque création / mise à jour d'un fichier est décompté dans ce volume.

### Coût total
La valorisation des coûts est simplement la somme des coûts induits par chacun des 6 compteurs valorisés par leur coût unitaire: `q1*u1 + q2*u2 + nl*cl + ne*ce + vd*cd + vm*cm`
- `q1` = _quota_ maximal de la somme `nn + nc + ng`

#### Solde monétaire d'un compte
Chaque compte a un _solde_ qui résulte,
- **en crédit :** 
  - soit de ce qu'il a versé ou fait verser monétairement au comptable de l'organisation,
  - soit de ce que lui a crédité automatiquement l'organisation chaque seconde quand celle-ci prend en charge le coût de fonctionnement du compte.
- **en débit :** les coûts de consommation à chaque consommation effective à chaque opération, PLUS, le coût d'abonnement sur chaque seconde.

## Le Comptable, les comptes _A_ et _O_

### Le compte du "Comptable"
_Le Comptable_ désigne une personne plus ou moins virtuelle, voire un petit groupe de personnes physiques qui:
- a négocié avec un hébergeur représenté par le terme _administrateur technique_ les conditions et le prix de l'hébergement.
- est en charge de contrôler le mode de création des comptes et le cas échéant l'attribution de _forfaits_ gratuits pour certains comptes.

C'est un compte _presque_ normal en ce sens qu'il peut avoir des notes, des chats, participer à des groupes, créer des avatars secondaires, etc. **Il a le privilège important de gérer les quotas / forfaits gratuits**.

> Le **Comptable** n'a pas plus que les autres comptes les moyens cryptographiques de s'immiscer dans les notes des avatars des comptes et leurs chats: ce n'est en aucune façon un modérateur et il n'a aucun moyen d'accéder aux contenus, pas plus qu'à l'identité des avatars secondaires des comptes.

### Compte _autonome_ "A"
Un compte _autonome_ fixe lui-même ses quotas Q1 et Q2 et peut les changer à son gré, mais pas en-dessous des volumes qu'il occupe effectivement.

> **Nul ne peut bloquer / dissoudre un compte _autonome_**, mais le compte peut se bloquer lui-même s'il ne couvre pas les frais d'utilisation de son compte

**Il gère son solde en _unité monétaire_**, par exemple en euros:
- **le solde est crypté par la clé du compte**: lui-seul le connaît.
- **le solde est débité à chaque instant** des coûts _d'abonnement_ liés aux quotas qu'il a fixé et des coûts de _consommation_, lectures / écritures / transferts faits.
- **le solde est crédité de manière _anonyme_.**
- **le solde peut aussi être crédité par un don, anonyme, d'un autre compte** et **par des _dons_ du Comptable**. 

Quand à la connexion d'un compte son solde est négatif, l'accès du compte à l'application est  **restreint**.

> Avant de devenir _négatif_ le solde d'un compte a été _faiblement positif_. Le compte en est averti lors de sa connexion avec le nombre de jours _estimé_ avant de devenir négatif si son profil de consommation reste voisin de celui des 2 mois antérieurs.

A sa création par _sponsoring_ un compte A peut être déclaré _sponsor_ lui-même, c'est à dire avoir le droit de sponsoriser lui-même de nouveaux comptes A.

### Compte _d'organisation_ "O"
**Un compte _d'organisation_ bénéficie _gratuitement_**:
- _d'un _abonnement_ c'est à dire de **quotas** de notes / chats et de volume de fichiers,
- _d'une dotation de fonctionnement_ renouvelée à chaque instant destinée à couvrir les coûts de _lectures / écritures de notes, chats, etc._ et de _transfert_ de fichiers.

> **Un compte O peut être bloqué par l'organisation**, en n'ayant plus qu'un accès _restreint_ (en gros en lecture seulement), voire un accès _minimal_.

> **Une organisation peut avoir de multiples raisons pour bloquer un compte**: départ de l'organisation, décès, adhésion à une organisation concurrente ou ayant des buts opposés, etc. selon la charte de l'organisation.

### Gestion des quotas / dotations par _tranche_
Le Comptable dispose de quotas globaux Q1 / Q2 et d'une _dotation_ globale de consommation pour l'ensemble de l'organisation. 

**Il découpe ces quotas / dotations en _tranches_** et est en charge d'en ajuster la répartition au fil du temps.

Tout compte O _d'organisation_ est créé dépendant d'une tranche de laquelle ses quotas ont été prélevés et sa dotation attribuée.

Dans chaque _tranche_ le Comptable a des _sponsors_ à qui il délègue la distribution des quotas et dotations aux comptes rattachés à la tranche.

### Compte A ou O ?
**A sa création une organisation **n'accepte pas** de comptes _autonomes_. 
- Le Comptable peut lever cette interdiction et en autoriser la création,
  - soit réservé à lui-même,
  - soit la déléguer aux sponsors.
- Il peut aussi supprimer cette autorisation: cela n'a aucun effet sur les comptes _autonomes_ existants et ne vaut que pour les créations ultérieures.

> Si un compte A paie lui-même son activité, en contre-partie il ne peut pas être bloqué par l'organisation: ceci dépend vraiment du profil de chaque organisation.

## Notifications et restrictions d'usage des comptes
Une _notification_ est un message important  dont la présence est signalée par une icône dans la barre d'entête de l'écran et parfois par un affichage lors de la connexion d'un compte, voir d'une _pop up_ en cours de session quand elle est liée à une restriction d'accès du compte.

Une _notification_ peut être porteuse d'une restriction d'accès: les actions du compte ne sont plus totalement libres, voire sévèrement limitées.

### Notification de l'administrateur technique: accès _figés_ et _clos_
L'administrateur peut émettre une notification, le cas échéant porteuse déclarant un espace _figé_ ou _clos_:
- le texte informatif est soit simplement informatif, soit explicite les raisons de la restriction:.
- **espace figé** : l'espace est en lecture seule.
- **espace clos** : il n'y a plus de données. Le texte indique à quelle URL / code d'organisation les comptes vont trouver l'espace transféré (s'il y en a un).

L'administrateur technique a ainsi les moyens:
- de figer temporairement un espace, par exemple:
  - pendant la durée technique nécessaire à son transfert sur un autre hébergeur,
  - en le laissant en ligne et permettant aux comptes de consulter une image archivée pendant que l'opération technique se poursuit.
- de clôturer un espace en laissant une explication, voire une solution, aux comptes (où l'espace a-t-il été transféré).

### Notification pour les comptes O: accès _lecture seule_ et _minimal_ 
Ces notifications peuvent être émise par le Comptable et des sponsors. Ce peut être une simple information ponctuelle et ciblée plus ou moins large, ne soumettant pas les comptes à des restrictions d'accès:
- Restriction d'accès en _lecture seulement_,
- Restriction d'accès _minimal_.

Ces notifications peuvent avoir deux portées:
- _tous_ les comptes O d'une tranche,
- _un_ compte O spécifique.

### Notification automatique par surveillance du solde
Cette notification s'applique aux comptes O et A.
- Notification sans restriction d'accès quand le solde est _faiblement positif_.
- Notification avec accès _minimal_ quand le solde est _négatif_.

### Notification automatique par surveillance des dépassements des quotas
Cette notification s'applique aux comptes O et A.
- Notification sans restriction d'accès quand les quotas sont _approchés_.
- Notification avec restriction aux opérations _décroissantes_ quand les quotas sont dépassée.

> Lire plus de détails dans le document **Couts-Hebergement**.

# Annexe : les _espaces_
L'administrateur technique d'un site peut héberger techniquement sur le site jusqu'à 50 **espaces** numérotés de 10 à 69.

Tout ce qui précède se rapporte à UN espace et les utilisateurs ne peuvent avoir aucune perception des autres espaces hébergés par le même serveur technique.
- dans la base de données, les informations sont partitionnées par les deux premiers chiffres (majeurs) des identifiants.
- dans l'espace de stockage des fichiers, des sous-espaces sont séparés.

L'administrateur technique a ainsi la possibilité d'ouvrir _instantanément_ un nouvel espace pour une association ou organisation en faisant la demande. Cette ouverture crée le compte Comptable de l'espace, qui comme les autres n'a aucune perception de l'existence d'autres espaces. C'est à cette occasion que la phrase secrète du Comptable (de l'espace) a été fixée.

Le Comptable et l'administrateur technique se sont mis d'accord sur le volume utilisable et la participation éventuelle aux frais d'hébergement.

Toutefois si cet accord n'était pas respecté, l'administrateur technique a le moyen d'ouvrir une procédure de blocage vis à vis de l'ensemble des comptes de l'espace, menant le cas échéant jusqu'à leur clôture en cas d'absence de solution.
