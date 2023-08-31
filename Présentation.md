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

# Maîtrise des ressources utilisées par l'application
Le coût d'usage de l'application pour une organisation n'est pas nul: les ressources techniques d'hébergement des données et de traitement de celles-ci ne sont pas gratuites.

Laisser les comptes utiliser sans contrainte l'espaces des notes et de leurs fichiers aboutirait à saturer inéluctablement les moyens techniques payés à l'hébergeur de l'application.

Ce chapitre explicite les moyens logiques mis en œuvre par l'application pour maîtriser les coûts induits par son utilisation par les comptes.

## Quotas de volumes autorisés
Le coût de _traitement_ des données, de leurs opérations de lecture et d'écriture a été inclus forfaitairement dans celui de stockage de celles-ci. C'est aussi le cas des coûts de transfert sur le réseau des textes des notes.

Le coût de transfert sur le réseau des fichiers a été pris en compte de deux manières:
- pour une inclusion forfaitaire au coût de stockage pour les cas usuels,
- par un ralentissement progressif des transferts volumineux systématiques. Exemple caricatural: télécharger sur son poste tous les jours tous les fichiers attachés à toutes les auxquelles on a accès. Cet usage _abusif_ aboutirait de facto à l'impossibilité de télécharger quoi que ce soit dans un délai raisonnable jusqu'à ce que l'usage redevienne _normal_.

> En conséquence, la maîtrise des coûts d'usage de l'application a été restreint **à maîtriser les volumes des textes des notes et des fichiers** qui leur sont attachés.

Il y a deux types de quotas :
- le quota Q1 fixe un maximum d'espace utilisable pour les textes des notes: _un_ Q1 correspond à 0,25Mo.
- le quota Q2 fixe un maximum d'espace utilisable pour les fichiers attachés aux notes: _un_ Q2 correspond à 25Mo.

L'ordre de grandeur des prix du marché, donne les coûts suivants en centimes d'euro annuel:

    un Q1 : 250 notes -> 0,45c/an
    un Q2 : 100Mo     -> 0,10c/an

    Pour un compte XXS ( 1 Q1 :   250n /  1 Q2 :  100Mo) ->   1,6c/an
    Pour un compte MD  ( 8 Q1 :  2000n /  8 Q2 :  800Mo) ->  13c/an
    Pour un compte XXL (64 Q1 : 16000n / 64 Q2 : 6,4Go ) -> 102c/an

> Les volumes V1 apparaissent environ 25 fois plus coûteux au méga-octet que les volumes V2, mais comme les fichiers peuvent être très volumineux, le coût d'utilisation dépend de ce que chacun met en textes des notes et en fichiers attachés.

> **Tout compte dispose de quotas Q1 et Q2** : les volumes effectivement utilisés ne peuvent pas dépasser les quotas attribués, sauf dans le cas où les quotas ont été réduits a posteriori en dessous des volumes actuellement utilisés.

Comme tout est anonyme même pour les fonctions d'administration techniques, la mise en place de _quotas préalables_ est un moyen efficace pour contenir l'inflation des volumes. Sans cette contrainte, quelques comptes pourraient siphonner toutes les ressources techniques sans qu'il sot possible de savoir à qui s'adresser pour rétablir une nécessaire modération ou le facturer.

## Coûts des lectures / écritures et transferts des fichiers

**Le coût des lectures des notes et chats se mesure en millier de note ou chat lus**. Il est influencé par:
- l'usage du mode _synchronisé_ ou _incognito_. Un compte ayant 1000 notes aura a minima 1000 lectures en _incognito_ à l'ouverture de la session mais probablement 10 fois moins en mode _synchronisé_ ou la majeure partie des notes étant inchangées depuis la dernière session ne seront pas relues.
- l'intensité de l'activité elle-même, le nombre de notes crées ou modifiées dans la session, et de chats écrits. Par exemple le stockage d'une note d'un groupe hébergé par un autre compte ne coûte rien (au compte hébergeur, si), mais sa modification intensive coûte au compte qui agit (pas à l'hébergeur du groupe).

> **Le coût du volume est récurrent chaque mois même sans se connecter** et ne dépend pas de ce qu'on fait en session: c'est de **_l'abonnement_**.
> **Le coût de lectures / écritures est nul en l'absence de connexion** mais dépend fortement du mode de connexion et du volume d'activité de la session: c'est de la **_consommation_**. 

**Le coût de transfert des fichiers (uploads / downloads) se mesure en GB transférés**. Il est influencé par:
- l'usage de copies locales de fichiers fréquemment lus et peu écrits: le coût de transfert est quasi nul.
- la lecture fréquente de fichiers très changeants.
- le _download_ fréquent d'une large sélection de notes sur un répertoire local du poste.

## Le compte du "Comptable"
A l'installation d'un réseau, l'administrateur technique s'est concerté avec le demandeur de l'installation qui lui a donné une _phrase secrète provisoire_. Un compte un peu privilégié a été créé, le **Comptable** : ce dernier se connecte et change la phrase secrète pour une nouvelle, qui elle sera inconnue de l'administrateur technique.

Le compte **Comptable** ne peut pas être supprimé, a un numéro fixe reconnaissable, a pour nom d'avatar principal `Comptable`, n'a pas de carte de visite mais est connu de tous les comptes.

C'est un compte _presque_ normal en ce sens qu'il peut avoir des notes, des chats, participer à des groupes, créer des avatars secondaires, etc. Mais il a le privilège important de gérer les quotas.

> Le **Comptable** n'a pas plus que les autres comptes les moyens cryptographiques de s'immiscer dans les notes des avatars des comptes et leurs chats: ce n'est en aucune façon un modérateur et il n'a aucun moyen d'accéder aux contenus, pas plus qu'à l'identité des avatars secondaires des comptes.

## Comptes (A) _autonome_ et (O) _de l'organisation_
### Compte _autonome_
Un compte _autonome_ fixe lui-même ses quotas Q1 et Q2 et peut les changer à son gré, mais pas en-dessous des volumes qu'il occupe effectivement.

**Il dispose d'un solde en _unité monétaire_**, par exemple en euros:
- le solde est crypté par la clé du compte: lui-seul le connaît.
- le solde est débité chaque jour du coût journalier des quotas Q1 et Q2 courants et de la consommation en lectures / écritures / transferts.
- le solde est crédité par un virement anonymisé:
  - le titulaire du compte génère un _ticket_ et, soit le cite en référence d'un virement qu'il effectue lui-même, soit le communique à un bienfaiteur qui fait le virement en le citant.
  - quand le Comptable reçoit un virement (de la banque ou par tout autre procédé), il enregistre le ticket cité en référence et le montant. Le solde du compte en est crédité à la prochaine connexion.
  - le _ticket_ étant enregistré crypté par la clé privée du compte, aucune corrélation ne peut être faite entre la source d'un virement et le compte qui en bénéficie.
- le solde peut aussi être crédité par un don, anonyme, d'un autre compte (ce qui débite le sien d'autant). 

Quand à la connexion d'un compte son solde est négatif, il est **restreint** à la seule lecture des informations, comme en mode avion, les mises à jours sont impossibles. Le compte à rebours de sa fin de vie démarre: un an plus tard il sera automatiquement détruit.

Quand le solde est négatif depuis plus de 60 jours, le compte est **bloqué**, les lectures et les mises à jours sont impossibles.

Dans les deux cas _restreint / bloqué_, le compte peut toutefois:
- chatter avec le Comptable,
- consulter son solde et l'état d'occupation de son espace,
- générer un _ticket_ pour faire créditer son solde par un virement et recevoir des dons d'autres comptes _autonomes_.

> Sauf le titulaire du compte quand il se connecte, nul ne peut savoir si un compte est _libre / restreint / bloqué_. **Nul ne peut bloquer / dissoudre un compte _autonome_**. 

#### A sa création une organisation **n'accepte pas** de comptes _autonomes_. 
- Le Comptable peut lever cette interdiction et les autoriser.
- Il peut aussi supprimer cette autorisation: cela n'a aucun effet sur les comptes _autonomes_ existants et ne vaut que pour les créations ultérieures.

## Compte _d'organisation_
Une organisation peut prendre en charge les coûts d'hébergement, pour tous ses membres ou certains d'entre eux, sans les faire contribuer aux charges correspondantes.

Le Comptable est le premier compte _d'organisation_ et ne peut, ni être fermé, ni devenir _autonome_, afin d'éviter qu'il ne se bloque lui-même.

Le Comptable dispose de quotas globaux Q1 / Q2 et d'un _budget_ global de consommation pour l'ensemble de l'organisation. Il peut découper ces quotas en _tranches_ et ajuster les attributions de quotas / budget à chaque tranche.

> Un _budget_ est une dotation monétaire qui chaque jour s'ajoute au solde d'un compte, quelle que soit son activité: le solde est décrémenté des _consommations_ en lectures / écritures et transferts.

**Un compte _d'organisation_ bénéficie _gratuitement_ de ses quotas** prélevés sur les quotas de la _tranche_ dans laquelle il a été créé et **n'a pas à alimenter un solde monétaire pour les conserver**.

### Gestion des quotas / budgets par _tranche_
Tout compte _d'organisation_ est dépendant de la tranche de quotas / budget de laquelle ses quotas ont été prélevés et son budget attribué.

#### Sponsor d'une tranche de quotas
Le Comptable peut attribuer / enlever un rôle de **_sponsor de sa tranche_** à un compte:
- un _sponsor_ peut sponsoriser un nouveau compte en lui attribuant des quotas et un budget prélevés sur la tranche qu'il gère (pas sur les siens): il peut aussi déclarer à ce moment le nouveau compte lui-même _sponsor_ de cette tranche.
- un `sponsor` peut augmenter / réduire les quotas et le budget des comptes liés à la tranche qu'il gère.
- un compte en excédent d'occupation effective de volume par rapport à ses quotas, devra supprimer / réduire des notes et leurs fichiers jusqu'à revenir dans ses quotas et pouvoir à nouveau augmenter son volume.
- le Comptable peut déclarer plus d'un compte _sponsor_ pour une tranche donnée.
- le Comptable peut aussi passer un compte _d'organisation_ d'une tranche à une autre.

> La gestion des quotas et des budgets des comptes _d'organisation_ s'effectue donc à deux niveaux en décentralisant la maîtrise fine de ceux-ci au niveau des tranches.

**Quelques règles :**
- un compte _non sponsor_ de sa tanche en connaît les sponsors, leurs carte de visite, et peut chatter avec eux (et d'ailleurs avec le Comptable).
- un compte _sponsor_ de sa tranche :
  - connaît tous les autres comptes dont les quotas et le budget sont imputés à sa tranche, mais pas forcément jusqu'au niveau _carte de visite_.
  - peut en lire la comptabilité des volumes et un petit historique des volumes V1 et V2 effectivement occupés et transférés et des consommations de lectures / écritures / transferts.
- aucun compte, pas même le Comptable, ne peut connaître les avatars secondaires des comptes et n'a aucun moyen d'accéder à leurs note et chats.

Le Comptable dispose de la liste des tranches (puisqu'il les as créées) et pour chacune dispose des mêmes possibilités qu'un sponsor de la tranche.

> Du fait qu'un compte _d'organisation_ est un invité sans contrainte de participation aux coûts d'hébergement, il est normal que l'organisation ait les moyens d'en contrôler l'usage.

### Notification et blocage des comptes _d'organisation_
**Une organisation peut avoir diverses raisons d'initier une procédure de blocage d'un compte _d'organisation_.** Par exemple,
- Le compte n'acquitte plus sa cotisation ou a quitté l'organisation.
- Les quotas ou le budget du compte doivent être révisés à la baisse mais les volumes occupés n'ont pas été réduits malgré des rappels amicaux et la consommation trop importante.
- Autres, décès ...

#### Notifications
Une notification a un court message qui en explicite la raison. Une notification peut être :
- **simple** : elle se limite au texte informatif.
- **restrictive** : le compte ne peut plus que lire ses données, comme s'il était en mode _avion_ mais peut toutefois chatter avec le Comptable et les sponsors de sa tranche.
- **bloquante** : le compte ne peut plus **que** chatter avec son sponsor ou le Comptable et n'a plus accès, même en lecture, à ses autres données.

Un compte _d'organisation_ perçoit jusqu'à 3 notifications en cliquant sur l'indicateur des notifications:
- une **notification générale** de l'administrateur technique, s'adressant à tous les comptes, de toutes tranches, et même aux comptes _autonomes_.
  - par exemple si l'administrateur technique doit opérer un transfert sur un autre hébergement, il va bloquer les comptes de l'organisation jusqu'à la fin de l'opération de transfert.
- une **notification de tranche** du Comptable ou d'un sponsor de sa tranche, s'adressant à tous les comptes d'organisation de la tranche (mais pas aux comptes _autonomes_ qui par principe ne sont liés à aucune tranche).
- une **notification personnelle** du Comptable ou d'un sponsor de sa tranche, s'adressant à lui-même spécifiquement (ne concerne pas les comptes _autonomes_).

Une notification **restrictive** spécifie combien de jours après son ouverture elle deviendra **bloquante**.

La destruction automatique du compte intervient à l'anniversaire de l'ouverture de la procédure restrictive / bloquante.

Une fois le problème réglé, l'émetteur d'une notification, Comptable ou sponsor, la supprime.

> Quand le Comptable a ouvert une procédure de blocage pour une tranche ou un compte, les sponsors de la tranche ne peuvent plus alors y intervenir.

# Annexe : les _espaces_
L'administrateur technique d'un site peut héberger techniquement sur le site jusqu'à 50 **espaces** numérotés de 10 à 69.

Tout ce qui précède se rapporte à UN espace et les utilisateurs ne peuvent avoir aucune perception des autres espaces hébergés par le même serveur technique.
- dans la base de données, les informations sont partitionnées par les deux premiers chiffres (majeurs) des identifiants.
- dans l'espace de stockage des fichiers, des sous-espaces sont séparés.

L'administrateur technique a ainsi la possibilité d'ouvrir _instantanément_ un nouvel espace pour une association ou organisation en faisant la demande. Cette ouverture crée le compte Comptable de l'espace, qui comme les autres n'a aucune perception de l'existence d'autres espaces. C'est à cette occasion que la phrase secrète du Comptable (de l'espace) a été fixée.

Le Comptable et l'administrateur technique se sont mis d'accord sur le volume utilisable et la participation éventuelle aux frais d'hébergement.

Toutefois si cet accord n'était pas respecté, l'administrateur technique a le moyen d'ouvrir une procédure de blocage vis à vis de l'ensemble des comptes de l'espace, menant le cas échéant jusqu'à leur clôture en cas d'absence de solution.
