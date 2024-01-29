@@Index général de la documentation - [index](../index.md)

@@Introduction - [README](../README.md)

# Vue d'ensemble de l'application

Une organisation, association, quelques amis ... peut décider de créer et d'utiliser son propre **espace a-social**, par exemple `monasso`, et a choisi un hébergeur qui a donné l'identification du service correspondant par une URL comme `https://srv1.monhebergeur.net/` 

Un compte se connecte en ouvrant la page à cette adresse et donne: 
- `monasso` : le code de son organisation enregistrée par l'hébergeur, 
- `mabellephrasetressecrete` une phrase secrète d'au moins 24 signes qu'il est seul à connaître et n'est stockée en clair nulle part.
 
Ce serveur Web permet d'obtenir l'application et gère aussi un serveur d'arrière plan contrôlant les accès à la base centrale où les données de chaque organisation sont stockées.

>Sur une URL d'hébergement telle que ci-dessus, jusqu'à 70 organisations peuvent être hébergées, toutes soigneusement étanches les unes des autres. Ceci permet à l'hébergeur d'enregistrer une nouvelle organisation en moins d'une minute à partir du moment où la question de la participation aux frais d'hébergement technique a été agréée entre l'hébergeur et l'organisation.

>Une organisation n'est pas attachée à son hébergeur initial, il peut faire exporter ses données vers un autre, ce qui ne prend que le temps de la copie des données.

## Avatars, notes, groupes
Pour pouvoir accéder à l'application une personne doit **se faire sponsoriser par une autre y ayant déjà un compte**. Un _sponsoring_ est identifié par une _phrase de sponsoring_ : sponsor et sponsorisé se sont concertés sur le nom du sponsorisé, par exemple `Charles` et la phrase qui reste secrète entre eux, par exemple `le hibou n'est pas chouette`. 

Le sponsorisé crée ensuite lui-même son compte en fournissant cette phrase de parrainage et déclare sa **phrase secrète de connexion**:
- elle a au moins 24 signes et reste uniquement dans la tête du titulaire, n'est enregistrée sous aucune forme nulle-part : elle pourra être changée à condition de pouvoir fournir celle actuelle.
- une partie de la phrase, située vers principalement au début, ne doit pas _ressembler_ celle d'une autre phrase déjà enregistrée afin d'éviter de tomber par hasard sur la phrase d'un autre compte.
- la phrase secrète crypte toutes les données du compte aussi bien dans la base centrale que dans les micro bases locales de chacun des navigateurs utilisés par le compte. Un piratage des appareils des titulaires des comptes ou de la base centrale centrale ne donnerait au _pirate_ que des informations indéchiffrables.

> _Revers de cette sécurité_ : si la personne titulaire d'un compte oublie sa **phrase secrète de connexion**, elle est ramenée à l'impuissance du pirate. Son compte s'autodétruira un jour et toutes ses données et notes disparaîtront.

### Avatars principal et secondaires d'un compte
En créant son compte, le titulaire a créé son **avatar principal**. Un avatar dispose:
- d'un _numéro_ identifiant de 16 chiffres (dont 13 aléatoires) et immuable ne portant aucune information utile.
- d'un **nom** lui-même aussi immuable, par exemple `Charles`.
- d'une **carte de visite** facultative constituée d'une photo et / ou d'un court texte, par exemple `Charles III, roi des esturgeons et d’Écosse`, tous deux modifiables uniquement par son titulaire.

Ultérieurement le titulaire du compte peut créer des **avatars secondaires**, chacun ayant un numéro, un nom et une carte de visite facultative. Il peut ensuite utiliser à son gré des circonstances l'un ou l'autre de ses avatars, ayant de ce fait plusieurs personnalités.

> **Le titulaire du compte est le seul à connaître la liste de ses avatars secondaires**: un autre compte connaissant deux avatars n'est jamais en mesure de savoir s'ils correspondent au même titulaire ou non et même l'administrateur technique du site ne peut pas s'affranchir de cette contrainte assise sur une cryptographie forte.

Selon la situation un avatar peut avoir connaissance d'un autre avatar,
- parfois et rarement par son seul numéro (autant dire rien),
- son numéro et son nom,
- son numéro, son nom et **sa carte de visite cryptée**: dans ce dernier cas **c'est réciproque** et a été assumé / voulu explicitement de part et d'autre.

> Comme dans la vraie vie **plusieurs avatars peuvent porter le même "nom"**, les homonymes sont possibles : à l'écran les 4 derniers chiffres du numéro identifiant permet certes de distinguer `Charles#9476` et `Charles#5432` mais ce sont surtout les cartes de visite de chacun qui donneront des informations pertinentes pour distinguer Charles "le _général_" de Charles "_le roi des esturgeons_".

### Notes personnelles
**Un note porte un texte** d'au plus 5000 caractères pouvant s'afficher avec un minimum de _décoration_, gras, italique, titres, listes ... Ce texte est modifiable.

**Des fichiers peuvent être attachés à une note** : beaucoup de types de fichiers (`.jpg .mp3 .mp4 .pdf ...`) s'affichent directement dans le navigateur. Il est possible d'ajouter et de supprimer des fichiers attachés à une note: plusieurs fichiers portant le même nom dans la note sont vus comme des révisions successives.

**Une note peut faire référence à UNE note _parent_** : les notes apparaissent à l'écran sous forme hiérarchique. Les notes _racine_ ne sont référencées par aucune autre et sont rattachées à un des avatars du compte.

> Un avatar peut créer des notes **personnelles**, les mettre à jour, les supprimer, les indexer par des mots clés personnels. Elles sont cryptées comme toutes les données des comptes et seul le titulaire du compte a, par l'intermédiaire de sa phrase secrète, la clé de cryptage apte à les décrypter.

### "Chats" entre avatars
Deux avatars _en contact_ (comment entrer en contact est vu plus avant) peuvent ouvrir un _chat_ dans lequel ils peuvent écrire des textes de moins de 5000 signes:
- un échange sur un chat ne peut plus y être modifié mais peut être supprimé par son auteur,
- le volume total des échanges sur le chat est limité à 5000 signes, les plus anciens échanges étant perdus en cas de dépassement de cette limite.

Une fois créé le chat ne disparaît que quand les deux avatars qui la partagent ont disparu.
- pour ne pas être importuné, l'un des 2 peut _raccrocher_ le chat, ne plus y écrire. L'autre peut toujours l'alimenter mais sans être certain d'être lu ...
- chacun peut attacher au _chat_ ses propres mots clés (par exemple _indésirable_ ou _important_ ...) que l'autre ne voit pas, et filtrer les chats en évitant ceux _raccrochés_ ou _indésirable_.

Pour partager une ardoise de chat avec un avatar B, un avatar A doit connaître son interlocuteur B par son nom complet c'est à dire avec _sa carte de visite_:
- B est membre d'un des groupes auxquels A participe (voir ci-après),
- B a sponsorisé A ou A a sponsorisé B, ce qui a créé entre eux un chat (sauf refus explicite de l'un ou l'autre),
- A a connaissance d'une **phrase de contact** de B.

#### Établissement d'un chat par une _phrase de contact_
B peut déclarer une _phrase de contact_, unique dans l'application et pas trop semblable à une déjà déclarée. Par exemple : `les courgettes sont bleues au printemps`
- B peut la changer ou la supprimer à tout instant.
- B peut communiquer, par un moyen de son choix, cette phrase à A qui peut ainsi ouvrir un chat avec B. A et B devenus contacts l'un de l'autre pourront aussi inviter, ou faire inviter, l'autre à un de ses groupes (voire plus si affinités).

> Il est recommandé que les _phrases de contact_ aient une durée de vie le plus limité possible afin d'éviter que des personnes non souhaitées n'ouvrent un chat (ce qui a toutefois un impact limité, on n'est pas obligé de la lire!).

Dès qu'un chat est ouvert entre A et B, leurs cartes de visite sont mutuellement visibles.

### Groupes
Un avatar peut créer un **groupe** dont il sera le premier membre _actif_ et y aura un pouvoir _d'animateur_. Un groupe a,
- un numéro interne, un nom immuable et une carte de visite (comme un avatar).
- un **chat partagé par les membres du groupe**.
- un **espace de notes partagées** entre les membres du groupes qui peuvent les lire et les éditer.

Um avatar du groupe a plusieurs états:
- **simple contact**: il a été inscrit comme contact du groupe mais lui-même ne le sait pas et ne connaît pas le groupe.
- **contact invité**: un membre ayant pouvoir d'animateur a invité le contact à devenir membre actif: s'il accepte il devient membre actif, sinon il retourne à l'état de simple contact. Nul ne devient membre actif à son insu, il faut l'accepter explicitement.
- **membre actif**: il peut participer à la vie du groupe.

#### Accès aux membres et / ou aux notes
Un membre actif reçoit lors de son invitation des _droits_:
- **d'accès aux autres membres** et au chat (ou non),
- **d'accès aux notes** en lecture, en lecture et écriture ou pas du tout.

> Certains groupes peuvent être créés à la seule fin d'être un répertoire de contacts identifiés avec possibilités de chat. Personne n'y lit / écrit de notes.

> Certains groupes peuvent être créés autour d'un animateur ayant seul connaissance des membres du groupe, mais où les notes de discussion sont partagées et de facto anonymes.

#### Quelques règles simples:
- seul um membre actif **ayant pouvoir d'animateur** peut,
  - donner / retirer l'accès aux autres membres et au chat à un membre actif donné,
  - donner / retirer l'accès aux notes à un membre actif donné, 
  - donner un pouvoir d'animateur à un membre actif qui n'en n'a pas,
  - inviter un contact à devenir membre actif, avec ou sans accès aux autres membres et au chat, avec ou sans accès aux notes, avec ou sans pouvoir d'animateur,
  - décider _d'oublier_ un simple contact qui n'apparaîtra plus dans le groupe.
- **tout membre actif** peut,
  - inscrire comme simple contact un des avatars de sa connaissance,
  - se retirer à lui-même le droit d'accès aux autres membres et notes,
  - décider de redevenir simple contact, voir d'être _oublié_ par le groupe (ne figurant même plus comme simple contact).

> Un _animateur_ ne peut pas changer les droits d'un autre _animateur_ (sauf à lui-même).

> Un _animateur ne peut pas résilier un membre actif indésirable_ mais peut lui retirer (s'il n'est pas _animateur_) ses droits d'accès aux autres membres et aux notes, donc de facto lui interdire tout accès au groupe.

Tout membre actif d'un groupe ayant accès aux membres accèdent de fait à leurs cartes de visites:
- il peut ouvrir un chat avec n'importe quel membre. Toutefois si ce membre est un simple contact (n'a pas -encore- accepté formellement d'invitation), il ne peut pas le faire, sauf s'il le connaît par ailleurs, actif dans un autre groupe ...

#### Notes du groupe
- elles sont cryptées par une clé aléatoire spécifique au groupe qui a été transmise lors de l'invitation au groupe.
- hormis les membres actifs du groupe ayant droit d'accès aux notes, personne ne peut accéder aux notes du groupe ni même savoir que le groupe existe.
- quand un nouveau membre accepte une invitation au groupe avec droits d'accès aux notes, il a immédiatement accès à toutes les notes existantes du groupe. S'il redevient simple contact ou perd son droit d'accès aux notes, il n'a plus accès à aucune de celles-ci.
- pour écrire / modifier / supprimer une note du groupe, il faut avoir le droit d'accès en écriture aux notes.
- chaque note est signée par la succession des membres qui y sont intervenu.

Tout membre peut attacher ses propres mots clés à un groupe afin de faciliter sa recherche quand il est membre de beaucoup de groupes: les autres membres ne savant pas quels sont ces mot clés.
- un _animateur_ peut toutefois attacher des mots clés spécifiques du groupe à une note, ceux-ci étant visibles de tous.

Une note de groupe peut être rattachée à une autre note parent du groupe, ce qui fait apparaître visuellement à l'écran une hiérarchie.
- un avatar peut attacher une note personnelle à une note de groupe pour la compléter / commenter: toutefois il sera seul à la voir (puisqu'elle est _personnelle_).

#### Membre _hébergeur_ d'un groupe
Celui-ci s'est dévoué pour supporter les coûts d'abonnement de stockage (nombres de notes et volume des fichiers) des notes du groupe.
- il fixe des maximum à ne pas dépasser afin de protéger ses propres dépenses,
- il peut cesser d'berger le groupe, un autre membre prenant la suite.

# Modes *synchronisé*, *incognito* et *avion*
Pour se connecter à son compte, le titulaire d'un compte choisit d'abord sous quel **mode** sa session va s'exécuter: _synchronisé_, _avion_ ou _incognito_.

#### Mode _synchronisé_ 
C'est le mode préférentiel où toutes les données du périmètre d'un compte sont stockées dans une micro base locale cryptée dans le navigateur puis remises à niveau depuis le serveur central à la connexion d'une nouvelle session. Durant la session la micro base locale est maintenue à jour, y compris lorsque d'autres sessions s'exécutent en parallèle sur d'autres navigateurs et mettent à jour les données du compte : par exemple quand une note de groupe est mise à jour par un autre membre du groupe.

La connexion ultérieure à un compte ainsi synchronisé est rapide, l'essentiel des données étant déjà dans le navigateur, seules quelques _nouveautés_ sont tirées du serveur central.

#### Mode _avion_
Pour que ce mode fonctionne il faut qu'une session antérieure en mode _synchronisé_ ait été exécutée dans ce navigateur. L'application présente à l'utilisateur l'état dans lequel étaient ses données à la fin de la dernière session synchronisée pour ce compte dans ce navigateur.

**L'application ne fonctionne qu'en lecture**, aucune mise à jour n'est possible. Aucun accès à Internet n'est effectué, ce qui est précieux _en avion_ ou dans les _zones blanches_ ou quand l'Internet est suspecté d'avoir de grandes oreilles indiscrètes : certes tout est crypté et illisible mais en mode avion personne ne peut même savoir que l'application a été ouverte, l'appareil peut être physiquement isolé du Net.

En mode avion les fichiers attachés aux notes ne sont pas accessibles, **sauf** ceux qui ont été déclarés devoir l'être. Cette déclaration pour un compte s'effectue fichier par fichier pour chaque navigateur et ils sont mis à niveau à l'ouverture de chaque session en mode _synchronisé_ (puis en cours de session).

> Il est conseillé de couper le réseau (le mode _avion_ sur un mobile), de façon à ce que l'ouverture de l'application ne cherche même pas à vérifier si une version plus récente est disponible.

#### Mode _incognito_
**Aucun stockage local n'est utilisé, toutes les données viennent du serveur central**, l'initialisation de la session est plus longue qu'en mode synchronisé. Aucune trace n'est laissée sur l'appareil (utile au cyber-café ou sur le mobile d'un.e ami.e) : certes les traces en question sont inutilisables car cryptées, mais il n'est pas poli d'encombrer la mémoire d'un appareil qu'on vous a prêté.

> Il est conseillé d'ouvrir l'application dans une  _fenêtre privée_ du navigateur, ainsi même le code de l'application sera effacé en fermant la page de l'application.

> **En utilisant des sessions synchronisées sur plusieurs appareils, on a autant de copies synchronisées de ses notes et chats sur chacun de ceux-ci**, et chacun peut être utilisé en mode avion. Les copies ne sont pas exactement les mêmes, les _photographies_ de l'état des données du compte ne pouvant pas être effectuées exactement à la même seconde.

> **L'application invoquée depuis un navigateur y est automatiquement mémorisée** : au prochain appel, étant déjà présente en local, elle ne chargera éventuellement que le minimum nécessaire pour se mettre à niveau de la version logicielle la plus récente.

# Répartition des coûts d'hébergement de l'application

Le coût d'usage de l'application pour une organisation correspond aux coûts d'hébergement des données et de traitement de celles-ci. Selon les techniques et les prestataires choisis, les coûts unitaires varient mais existent dans tous les cas.

#### Espace de _base de données_ et espace de _fichiers_ (Storage)
Ces deux espaces ont des coûts unitaires très différents (facteur de 1 à 25). Les fichiers sont stockés dans des _Storage_, des espaces techniques ayant une gestion très spécifique mais économique, et de plus soumis à peu d'accès (mais de lus fort volume).

#### Abonnement
Il correspond aux coûts récurrents mensuels pour un compte même quand il ne se connecte pas. Par simplification ils ont été résumés ainsi:
- **Nombre total de documents sur la base de données**: `nn + nc + ng`
  - **(nn) nombre de notes** personnelles et notes d'un groupe hébergé par le compte,
  - **(nc) nombre de chats personnels** créés, 
  - **(ng) nombre de participations actives aux groupes**.
- **Volume des fichiers attachés aux notes** stocké sur un _Storage_.

Pour obtenir le coût correspondant à ces deux volumes il est pris en compte, non pas _le volume effectivement utilisé à chaque instant_ mais **les _volumes maximaux_** fixés pour le compte (qui lui est possible d'utiliser).

> Les volumes _effectivement utilisés_ ne peuvent pas dépasser les volumes maximaux de l'abonnement, sauf dans le cas où ceux-ci ont été volontairement réduits a posteriori en dessous des volumes actuellement utilisés.

#### Consommation de calcul
Les coûts de _calcul_ correspondent directement à l'usage effectif fait de l'application quand une session d'un compte est ouverte. Ils dépendent de _l'activité_ du titulaire du compte et de la façon dont il se sert de l'application. Le coût de calcul est la somme de 4 facteurs, chacun ayant son propre tarif:
- **(nl) nombre de _lectures_** (en base de données): nombre de notes lues, de chats lus, de contacts lus, de membres de groupes lus, etc. **Lu** signifie extrait de la base de données. Pour un même service apparent, le coût des _lectures_ peut différer fortement par utilisation du mode _synchronisé_ (en mode _avion_ il est par principe nul).
- **(ne) nombre _d'écritures_** (en base de données): outre quelques écritures techniques indispensables, il s'agit principalement des mises à jour des données, notes, chats, cartes de visite, commentaires personnels, etc.
- **(vd) volume _descendant_** (download) de fichiers téléchargés depuis le _Storage_.
- **(vm) volume _montant_** (upload) de fichiers envoyés dans le _Storage_. Chaque création / mise à jour d'un fichier est décompté dans ce volume.

> **Remarque par anticipation: les comptes O (_de l'organisation_) ont une _limite de coût mensuel de calcul_.**. Si le coût de consommation sur le mois en cours et le précédent dépasse cette limite ramenée au prorata des jours de ces deux mois, le compte subit une _restriction d'accès_.

### Coût total
Le coût total est la somme des coûts induits par chacun des 6 compteurs valorisés par leur coût unitaire: `m1*u1 + m2*u2 + nl*cl + ne*ce + vd*cd + vm*cm`
- `m1` = _volume maximal_ de la somme `nn + nc + ng`
- `m2` = _volume maximal_ des fichiers attachés aux notes.
- `nl ne` : nombres de lectures et d'écritures,
- `vd vm` : volume descendant et montant.

## Le Comptable, les comptes _A_ et _O_
Une organisation peut avoir des modes de fonctionnement différenciés:
- soit un mode où chaque compte est libre de son abonnement et de sa consommation mais les paye.
- soit un mode ou l'organisation paye globalement l'hébergement pour ses _adhérents_ mais en contrepartie,
  - peut contraindre leur abonnement / consommation afin de maîtriser ses dépenses,
  - peut bloquer les comptes, par exemple de ceux quittant l'organisation et qui n'ont plus à bénéficier d'un tel service gratuit, ni à avoir accès aux notes et aux chats avec les adhérents.
- enfin un mode mixte avec cohabitation de comptes _autonomes_ et de comptes _d'organisation_.

### Le compte du "Comptable"
_Le Comptable_ désigne une personne plus ou moins virtuelle, voire un petit groupe de personnes physiques qui:
- a négocié avec le prestataire hébergeur représenté par le terme _administrateur technique_ les conditions et le prix de l'hébergement.
- est en charge de contrôler le mode de création des comptes et le cas échéant l'attribution de _forfaits_ gratuits pour les comptes O, c'est à dire pris en charge par l'organisation.

C'est un compte de l'organisation _presque_ normal en ce sens qu'il peut avoir des notes, des chats, participer à des groupes, créer des avatars secondaires, etc. 
- **Il a le privilège important de gérer les forfaits gratuits attribués par l'organisation**.
- Il a lz privilège de déclarer si l'organisation accepte ou non des comptes autonomes et lui-m^me peut sponsoriser des comptes autonomes.

> Le **Comptable** n'a pas plus que les autres comptes les moyens cryptographiques de s'immiscer dans les notes des avatars des comptes et leurs chats: ce n'est en aucune façon un modérateur et il n'a aucun moyen d'accéder aux contenus, pas plus qu'à l'identité des avatars secondaires des comptes.

### Compte _autonome_ "A"
**Un compte _autonome_ fixe lui-même, son niveau d'abonnement**, c'est à dire ses _volumes maximum_ et peut les changer à son gré, mais pas en-dessous des seuils déjà occupés.

Un compte autonome a des compteurs de consommation qu'il ne peut que constater.

> **Nul ne peut bloquer / résilier un compte _autonome_**, mais le compte peut se bloquer lui-même s'il n'a pas été crédité suffisamment pour couvrir ses coûts **d'abonnement et de consommation**.

Il dispose à cet effet d'un compteur de **crédits** qui lui donne le cumul de tous les crédits qu'il a récupérés et enregistrés depuis l'ouverture de son compte ou depuis qu'il est devenu compte _autonome_, diminués toutefois des crédits qu'il a offert à d'autres comptes _A_ amis ou à l'occasion d'un sponsoring.

Pour enregistrer un crédit, le compte:
- génère un _ticket_,
- effectue un paiement (ou fait effectuer un paiement par un tiers) portant en référence ce ticket. C'est le Comptable qui fixe comment recevoir ces paiements et sous quelle forme.
- le Comptable inscrit les paiements reçus avec leur montant et numéro de ticket.
- à la prochaine connexion (ou appui sur un bouton) le compte augmente le cumul de ses crédits de tous les paiements reçus par le Comptable.
- ce mécanisme garantit l'anonymat du paiement qui ne peut pas être corrélé à son compte.

Comme le compte dispose à tout instant de la somme des coûts d'abonnement et de consommation depuis le début de la vie du compte (ou depuis qu'il est _devenu compte autonome_), il en résulte **un solde qui doit normalement être positif** et enclenche une restriction d'accès s'il est négatif.

> Avant de devenir _négatif_ le solde d'un compte a été _faiblement positif_. Le compte en est averti lors de sa connexion avec le nombre de jours _estimé_ avant de devenir négatif si son profil de consommation reste voisin de celui constaté sur les 4 mois antérieurs.

Un compte _A_ peut être _sponsorisé_:
- par le Comptable qui lui offre un petit crédit de bienvenue (supporté par l'organisation).
- par un autre compte _A_ qui lui offre un crédit pris sur le sien propre.
- le crédit initial laisse le temps au nouveau compte de faire parvenir un paiement au Comptable.

### Compte _d'organisation_ "O"

**Un compte _d'organisation_ bénéficie _gratuitement_**:
- _d'un _abonnement_ c'est à dire d'un _nombre maximal total_ de notes / chats / groupes et d'un _volume maximal total_ pour les fichiers attachés aux notes.
- _d'une limite de coûts mensuel de calcul_ destinée à couvrir les coûts de _lectures / écritures de notes, chats, etc._ et de _transfert_ de fichiers. **Le compte subit une restriction d'accès** si sa consommation sur le mois en cours et le précédent (rapportée à l'année) dépasse cette limite.

> **Un compte _O_ peut être bloqué par l'organisation**, en n'ayant plus qu'un accès _en lecture seule_, voire un accès _minimal_.

> **Une organisation peut avoir de multiples raisons pour bloquer un compte**: départ de l'organisation, décès, adhésion à une organisation concurrente ou ayant des buts opposés, etc. selon la charte de l'organisation.

### Gestion des abonnements et limites de calcul par _tranche_
Le Comptable dispose pour distribution aux comptes _O_,
- d'un _volume maximal total_ pour les notes, chats, groupes,
- d'un _volume maximal total_ pour les fichiers attachés aux notes,
- d'une _limite maximale totale des coûts annuels de calcul_. 

**Il découpe ces _volumes et limites_ en _tranches_** et est en charge de les ajuster au fil du temps.
- dans chaque _tranche_ le Comptable désigne des _comptes sponsors_ à qui il délègue la distribution des _volumes maximaux et limites de calcul_ aux comptes rattachés à la tranche.
- tout compte O _d'organisation_ est attachée à **une tranche**. Le Comptable peut le basculer d'une tranche à une autre.

### Basculement d'un compte A en O et inversement
Le Comptable ou un sponsor d'un tranche, peut transformer un compte _O_ de cette tranche en compte _A_:
- avec ou sans son accord selon l'option choisie par le Comptable pour l'organisation.
- le compte acquiert une liberté totale (il ne peut plus être bloqué) mais en contrepartie paie son abonnement / consommation.

Le Comptable ou un sponsor d'un tranche, peut transformer un compte _A_ qui en fait la demande en compte _O_ de la tranche du sponsor:
- le compte n'a plus à payer son accès,
- en contrepartie il est contraint en volume et en activité et peut être bloqué.

**A sa création une organisation **n'accepte pas** de comptes _autonomes_. 
- Le Comptable peut lever cette interdiction et en autoriser la création,
- il peut aussi supprimer cette autorisation: cela n'a aucun effet sur les comptes _autonomes_ existants et ne vaut que pour les créations ultérieures.
- enfin il précise si le passage de compte O à compte A est soumis à l'accord du compte.

## Notifications et restrictions d'usage des comptes
Une _notification_ est un message important dont la présence est signalée par une icône dans la barre d'entête de l'écran et parfois par un affichage lors de la connexion d'un compte, voire d'une _pop up_ en cours de session quand elle est liée à une restriction d'accès du compte.

Une _notification_ peut être porteuse d'une restriction d'accès: les actions du compte ne sont plus totalement libres, voire sévèrement limitées.

### Notification de l'administrateur technique: accès _figés_ et _clos_
L'administrateur peut émettre une notification, le cas échéant déclarant un espace _figé_ ou _clos_:
- le texte informatif est soit simplement informatif, soit explicite les raisons de la restriction:.
- **espace figé** : l'espace est en lecture seule.
- **espace clos** : il n'y a plus de données. Le texte indique à quelle URL / code d'organisation les comptes vont trouver l'espace transféré (s'il y en a un).

L'administrateur technique a la capacité:
- de figer temporairement un espace, par exemple:
  - pendant la durée technique nécessaire à son transfert sur un autre hébergeur,
  - en le laissant en ligne et permettant aux comptes de consulter une image archivée pendant que l'opération technique se poursuit.
- de clôturer un espace en laissant une explication, voire une solution, aux comptes (où l'espace a-t-il été transféré).

### Notification pour les comptes O: accès _lecture seule_ et _minimal_ 
Ces notifications peuvent être émises par le Comptable et les sponsors de la tranche de quotas du compte. 

Ce peut être une simple information ponctuelle et ciblée plus ou moins large, ne soumettant pas les comptes à des restrictions d'accès, mais elle peut aussi être porteuse d'une _restriction_:
- Restriction d'accès en _lecture seulement_,
- Restriction d'accès _minimal_.

Ces notifications peuvent avoir deux portées:
- _tous_ les comptes O d'une tranche,
- _un_ compte O spécifique.

### Notification de la surveillance automatique de la consommation
- pour un compte A: solde (crédits - coûts).
- pour un compte O: comparaison entre la consommation sur le mois en cours et le précédent  et la limite de consommation mensuelle.

Il y a restriction d'accès _minimal_ quand,
- **compte A) le solde est _négatif_**.
  - Toutefois le compte peut générer un _ticket de crédit_ qui sera enregistré par le Comptable.
- **compte O) la consommation du mois en cours et précédent est _excessive_**, elle dépasse la _limite de consommation mensuelle moyenne_.
  - Toutefois, le Comptable ou un sponsor de la tranche de quotas peut augmenter ces quotas.

### Notification de la surveillance automatique des dépassements des volumes maximaux
Cette notification s'applique aux comptes O et A.
- Notification sans restriction d'accès quand les volumes maximaux sont _approchés_.
- Notification avec restriction aux opérations diminuant les volumes quand les maximum sont dépassés.

> Lire plus de détails dans le document **Couts-Hebergement**.

# Annexe : les _espaces_
L'administrateur technique d'un site peut héberger techniquement sur le site jusqu'à 70 **espaces** numérotés de 10 à 89.

Tout ce qui précède se rapporte à UN espace et les utilisateurs ne peuvent avoir aucune perception des autres espaces hébergés par le même serveur technique.
- dans la base de données, les informations sont partitionnées par les deux premiers chiffres (majeurs) des identifiants.
- dans l'espace de stockage des fichiers, des sous-espaces sont séparés.

L'administrateur technique a ainsi la possibilité d'ouvrir _instantanément_ un nouvel espace pour une association ou organisation en faisant la demande. Cette ouverture crée le compte Comptable de l'espace, qui comme les autres n'a aucune perception de l'existence d'autres espaces. C'est à cette occasion que la phrase secrète du Comptable (de l'espace) a été fixée.

Le Comptable et l'administrateur technique se sont mis d'accord sur le volume utilisable et la participation éventuelle aux frais d'hébergement.

Toutefois si cet accord n'était pas respecté, l'administrateur technique a le moyen d'ouvrir une procédure de blocage vis à vis de l'ensemble des comptes de l'espace, menant le cas échéant jusqu'à leur clôture en cas d'absence de solution.
