@@Index général de la documentation - [index](./index.md)

@@Introduction - [index](./README.md)

# Vue d'ensemble de l'application

Une organisation, association, des amis ... peut décider de créer et d'utiliser son propre réseau a-social et a choisi un hébergeur. Les personnes peuvent accéder à ce réseau depuis un navigateur par une URL comme https://monreseau.monhebergeur.net/app/

Ce serveur Web permet d'obtenir l'application et gère aussi un serveur d'arrière plan contrôlant les accès à la base centrale où les données de chaque réseau sont stockées.

## Avatars, notes, groupes
Pour pouvoir accéder à l'application une personne doit **se faire sponsoriser par une autre y ayant déjà un compte**. Un _sponsoring_ est identifié par une _phrase de sponsoring_ : sponsor et sponsorisé se sont concertés sur le nom du sponsorisé, par exemple `Charles` et la phrase qui reste secrète entre eux, par exemple `le hibou n'est pas chouette`. 

Le sponsorisé crée ensuite lui-même son compte en fournissant cette phrase de parrainage : si le sponsor l'a bien enregistrée, le sponsorisé déclare sa **phrase secrète de connexion**:
- elle a au moins 24 signes et reste uniquement dans la tête du titulaire, n'est enregistrée sous aucune forme nulle-part : elle pourra être changée à condition de pouvoir fournir celle actuelle.
- le début de la phrase, environ la première moitié, ne doit pas _ressembler_ au début d'une phrase déjà enregistrée afin d'éviter de tomber par hasard sur une phrase servant à connecter un autre compte.
- la phrase secrète crypte toutes les données du compte aussi bien dans la base centrale que dans les micro bases locales de chacun des navigateurs utilisés par le compte. Un piratage des appareils des titulaires des comptes ou de la base centrale centrale ne donnerait au _pirate_ que des informations indéchiffrables.

> _Revers de cette sécurité_ : si la personne titulaire d'un compte oublie sa **phrase secrète de connexion**, elle est ramenée à l'impuissance du pirate. Son compte s'autodétruira un jour et toutes ses données et notes disparaîtront.

### Avatars principal et secondaires
En créant son compte, le titulaire a créé son **avatar principal**. Un avatar dispose:
- d'un _numéro_ identifiant de 16 chiffres aléatoire et immuable ne portant aucune information utile.
- d'un **nom** lui-même aussi immuable, par exemple `Charles`.
- d'une **carte de visite** constituée d'une photo facultative et d'un court texte, par exemple `Charles III, roi des esturgeons et d’Écosse`, tous deux modifiables uniquement par son titulaire.

Ultérieurement le titulaire du compte pourra créer des **avatars secondaires**, chacun ayant un numéro, un nom et une carte de visite. Il pourra ensuite utiliser à son gré l'un ou l'autre de ses avatars, ayant de ce fait plusieurs personnalités.

> **Le titulaire du compte est le seul à pouvoir connaître la liste de ses avatars secondaires**: un autre compte connaissant deux avatars n'est jamais en mesure de savoir s'ils correspondent au même titulaire ou non et même l'administrateur technique du site ne peut pas s'affranchir de cette contrainte assise sur une cryptographie forte.

Un avatar _connaissant_ un autre avatar accède à son _identité complète_ à savoir son **nom** et **sa carte de visite** en plus de son numéro. Ces identités sont cryptées et ne sont échangées qu'entre des avatars l'ayant assumé consciemment.

> Comme dans la vraie vie **plusieurs avatars peuvent porter le même "nom"**, les homonymes sont possibles : à l'écran les 4 derniers chiffres du numéro identifiant permet certes de distinguer `Charles#9476` et `Charles#5432` mais ce sont surtout les cartes de visite de chacun qui donneront des informations pertinentes pour distinguer Charles "le _général_" de Charles "_le roi des esturgeons_".

### Notes
**Un note porte un texte** d'au plus 5000 caractères pouvant s'afficher avec un minimum de _décoration_, gras, italique, titres, listes ... Ce texte est modifiable.

**Des fichiers peuvent être attachés à une note** : beaucoup de types de fichiers (`.jpg .mp3 .mp4 .pdf ...`) s'affichent directement dans le navigateur. Il est possible d'ajouter et de supprimer des fichiers attachés à une note: plusieurs fichiers portant le même nom dans la note sont vus comme des révisions successives.

**Une note peut faire référence à UNE note _parent_** : les notes apparaissent à l'écran sous forme d'arbre. Les notes _racine_ n'en référence aucune autre, et in fine les notes _feuilles_ ne sont référencées par aucune autre.

> Un avatar peut se créer des notes **personnels**, les mettre à jour, les supprimer, les indexer par des mots clés personnels. Ces notes sont cryptées comme toutes les données des compte et seul le titulaire du compte a la clé de cryptage apte à les décrypter, laquelle ne pouvant être obtenue qu'en ayant fourni la phrase secrète en se connectant au compte.

### Groupes
Un avatar peut créer un **groupe** dont il sera le premier membre et _animateur_. Un groupe a un numéro interne, un nom immuable et une carte de visite. Un groupe a aussi une _ardoise_ portant quelques informations ou brèves partagées dans le groupe.

N'importe quel membre du groupe peut inscrire un des avatars qu'il connaît (par exemple des membres d'autres groupes dont il est membre) comme _contact_ du groupe : les autres membres peuvent ainsi discuter de ce contact et de l'opportunité à l'inviter à rejoindre le groupe.

Puis un animateur peut (ou non) _inviter_ un contact à rejoindre le groupe en tant que _simple lecteur_, _auteur_ ou _animateur_ : un lecteur n'a que les droits de lecture, un auteur peut créer et mettre à jour des notes du groupe et un animateur en plus d'être auteur peut inviter des avatars.

**Chaque membre du groupe peut créer, modifier et supprimer des notes du groupe.**
- ces notes sont cryptées par une clé aléatoire spécifique au groupe qui a été transmise lors de leur invitation au groupe.
- hormis les membres du groupe, personne ne peut accéder aux notes du groupe ni même savoir que le groupe existe.
- quand un nouveau membre accepte une invitation au groupe il a immédiatement accès à toutes les notes du groupe et quand il est résilié, ou s'est auto-résilié, il n'a plus accès à aucune de celles-ci.

Un membre peut attacher ses propres mots clés à un groupe afin de faciliter sa recherche quand il est membre de beaucoup de groupes.

Il peut aussi attacher ses propres mots clés aux notes du groupe pour sélectionner plus rapidement celles qu'il recherche, par centre d'intérêt, importance, etc.

### "Chats" entre avatars
Deux avatars peuvent disposer d'une _ardoise_ commune sur laquelle ils peuvent _chatter_ : l'ardoise est un simple texte commun modifiable à loisir par l'un ou l'autre.

Une fois créée une ardoise ne disparaît que quand les deux avatars qui la partagent ont disparu. Chacun peut effacer le texte de l'ardoise et chacun peut attacher au _chat_ ses propres mots clés (par exemple _poubelle_ ou _important_ ...) que l'autre ne voit pas.

Pour partager une ardoise de chat avec un avatar B, un avatar A doit connaître le **nom complet** de son interlocuteur B:
- c'est le cas pour les membres des groupes auxquels il participe,
- c'est le cas aussi pour son sponsor (et les autres sponsors de la même _tribu_ -voir plus avant ce qu'est une tribu),
- c'est enfin le cas quand l'avatar A a eu connaissance directe d'une **phrase de contact** de B.

#### Établissement d'un chat par une _phrase de contact_
B peut déclarer une _phrase de contact_, unique dans l'application et pas trop semblable à une déjà déclarée. Par exemple : `les courgettes sont bleues au printemps`
- B peut la changer ou la supprimer à tout instant.
- B peut communiquer, par un moyen de son choix, à A cette phrase. Dès lors A a connaissance du nom complet de B et peut ouvrir une ardoise de chat avec B. Il pourra aussi proposer à B d'intégrer un de ses groupes et plus si affinités ...

>Il est recommandé que les phrases de contact aient une durée de vie le plus limité possible afin d'éviter que des personnes non destinataires ne s'invite (ce qui a toutefois un impact limité à la création d'un _chat_).

Dès qu'une ardoise de chat est ouverte, les cartes de visite des interlocuteurs sont échangées.

# Modes *synchronisé*, *incognito* et *avion*
Pour se connecter à son compte, le titulaire choisit d'abord sous quel **mode** sa session va s'exécuter: _synchronisé_, _avion_ ou _incognito_.

#### Mode _synchronisé_ 
C'est le mode préférentiel où toutes les données du compte sont stockées dans une micro base locale cryptée dans le navigateur puis mise à jour depuis le serveur central pour celles qui sont plus récentes. Durant la session la micro base locale est maintenue à jour, y compris lorsque d'autres sessions s'exécutent en parallèle sur d'autres navigateurs et mettent à jour les données du compte : par exemple quand une note de groupe est mise à jour par un autre membre du groupe.

La connexion ultérieure à un compte ainsi synchronisé est rapide, l'essentiel des données étant déjà dans le navigateur, seules quelques _nouveautés_ sont tirées du serveur central.

#### Mode _avion_
Pour que ce mode fonctionne il faut qu'une session antérieure en mode _synchronisé_ ait été exécutée dans ce navigateur. L'application présente à l'utilisateur l'état dans lequel étaient ses données à la fin de la dernière session synchronisée pour ce compte dans ce navigateur.

**L'application ne fonctionne qu'en lecture**, aucune mise à jour n'est possible. Aucun accès à Internet n'est effectué, ce qui est précieux _en avion_ ou dans les _zones blanches_ ou quand l'Internet est suspecté d'avoir des grandes oreilles indiscrètes : certes tout est crypté et illisible mais en mode avion personne ne peut même savoir que vous accédez à vos notes, votre appareil peut être physiquement isolé du Net.

En mode avion les fichiers attachés aux notes ne sont pas accessibles, **sauf** ceux qui ont été déclarés devoir l'être. Cette déclaration pour un compte s'effectue fichier par fichier pour chaque navigateur et ils sont mis à niveau à l'occasion de chaque session en mode _synchronisé_.

> Il est même conseillé de couper le réseau (le mode _avion_ sur un mobile), de façon à ce que l'ouverture de l'application ne cherche même pas à vérifier si une version plus récente est disponible.

#### Mode _incognito_
**Aucun stockage local n'est utilisé, toutes les données viennent du serveur central**, l'initialisation de la session est plus longue qu'en mode synchronisé. Aucune trace n'est laissée sur l'appareil (utile au cyber-café ou sur le mobile d'un.e ami.e) : certes les traces en question sont inutilisables car cryptées, mais il n'est pas poli d'encombrer la mémoire d'un appareil qu'on vous a prêté.

> Il est même conseillé d'utiliser le mode _page privée_ de votre navigateur, ainsi même le code de l'application sera effacé en fermant la page de l'application.

> **En utilisant des sessions synchronisées sur plusieurs appareils, on a autant de copies synchronisées de ses notes sur chacun de ceux-ci**, et chacun peut être utilisé en mode avion. Les copies ne sont pas exactement les mêmes, les _photographies_ de l'état des données du compte ne pouvant pas être effectuées exactement à la même micro seconde.

> **L'application invoquée depuis un navigateur y est automatiquement mémorisée** : au prochain appel, étant déjà présente en local, elle ne chargera éventuellement que le minimum nécessaire pour se mettre à niveau de la version logicielle la plus récente.

# Maîtrise des volumes par les quotas: le Comptable et les tribus
## Quotas de volumes autorisés
Il y a deux types de quotas :
- le quota V1 fixe un maximum d'espace utilisable pour les textes des notes.
- le quota V2 fixe un maximum d'espace utilisable pour les fichiers attachés aux notes.

> Les volumes V1 sont 10 fois plus coûteux au méga-octet que les volumes V2. Les fichiers pouvant facilement être très volumineux, le coût d'utilisation dépend de ce que chacun met en textes des notes et en fichiers attachés.

> **Tout compte dispose de quotas V1 et V2** : les volumes effectivement utilisés ne peuvent pas dépasser les quotas attribués, sauf dans le cas où les quotas ont été réduits a posteriori en dessous des volumes actuellement utilisés.

Comme tout est anonyme même pour les fonctions d'administration techniques, la mise en place de _quotas préalables_ est un moyen efficace pour contenir l'inflation des volumes. Sans cette contrainte, quelques comptes pourraient siphonner toutes les ressources techniques sans qu'il sot possible de savoir à qui s'adresser réellement pour rétablir une nécessaire modération.

## Le compte du "Comptable"
A l'installation d'un réseau, l'administrateur technique s'est concerté avec le demandeur de l'installation qui lui a donné une _phrase secrète provisoire_. Ainsi un compte un peu privilégié a été créé, le **Comptable** : ce dernier peut ainsi se connecter et s'empresser de changer la phrase secrète pour une nouvelle inconnue de l'administrateur technique.

Ce compte **Comptable** ne peut pas être supprimé, a un numéro fixe reconnaissable, a pour nom d'avatar principal `Comptable` et n'a pas de carte de visite. Il est par défaut connu de tous les futurs comptes.

C'est un compte _presque_ normal en ce sens qu'il peut avoir des notes, des chats, participer à des groupes, créer des avatars secondaires, etc. Mais il a quelques privilèges importants.

> Le **Comptable** n'a pas plus que les autres comptes les moyens cryptographiques de s'immiscer dans les notes des avatars des comptes : ce n'est en aucune façon un modérateur et n'a aucun moyen d'accéder aux contenus, pas plus qu'à l'identité des avatars et des comptes, exceptés ceux qu'il a en tant que compte _normal_.

### Les tribus
Le Comptable appartient de par sa création à une _tribu_ **Primitive**. Il peut surtout déclarer d'autres **tribus** avec un code et un commentaire pour lui. 
- Il attribue des quotas V1 et V2 à chaque tribu qui sont impératifs.
- La somme des quotas attribués et les volumes effectivement utilisés sur l'ensemble des tribus doit respecter les termes de l'accord avec l'administrateur technique du site en cas de participation aux coûts d'hébergement.

Le Comptable peut sponsoriser des comptes:
- il les affecte à une des tribus et leur donne des quotas prélevés sur les quotas de la tribu.
- le compte sponsorisé est en général un compte déclaré **sponsor** de sa tribu, mais ce n'est pas obligatoire. Le Comptable peut retirer cet attribut _sponsor_ à tout compte d'une tribu (ou l'attribuer).

Un compte **sponsor de sa tribu** peut sponsoriser de nouveaux comptes, sponsor ou non de la tribu.
- A cette occasion des quotas sont attribués au nouveau compte, ils sont prélevés sur les quotas de la tribu.
- Un sponsor d'une tribu peut ensuite ajuster les quotas attribués aux comptes (non sponsors eux-mêmes) de sa tribu: c'est à cette occasion qu'une réduction de quotas en-dessous des volumes déjà occupés peut intervenir.
- un compte en excédent par rapport à ses quotas, devra supprimer / réduire des notes et leurs fichiers jusqu'à revenir dans ses quotas et pouvoir à nouveau augmenter son volume. 

> La gestion des quotas s'effectue donc à deux niveaux en décentralisant la maîtrise fine de ceux-ci au niveau des tribus.

**Quelques règles :**
- un compte d'une tribu peut lister les autres comptes de sa tribu, plus exactement leurs _avatars principaux_.
  - il dispose de leur nom complet / carte de visite et peut ouvrir un chat avec eux.
- un **sponsor** de la tribu peut lire la comptabilité des volumes et un petit historique des volumes V1 et V2 effectivement occupés et transférés par chaque compte de la tribu.
- aucun compte, pas même le Comptable, ne peut connaître les avatars secondaires des comptes et n'a aucun moyen d'accéder à leurs notes.
- le Comptable dispose de plus de la liste des tribus et pour chaque tribu peut connaître ces mêmes informations.

## Notifications / blocages du Comptable et des sponsors
Une notification a un court message qui en explicite l'utilité. Une notification peut être :
- **simple** : elle se limite au texte informatif.
- **bloquante** : elle est associée à une _procédure de blocage_ du ou des comptes.

Un compte perçoit jusqu'à 3 notifications en cliquant sur l'indicateur des notifications:
- une **notification générale** de l'administrateur technique, s'adressant à tous les comptes de toutes les tribus.
- une **notification de tribu** du Comptable ou d'un sponsor de la tribu, s'adressant à tous les comptes de la tribu.
- une **notification de compte** du Comptable ou d'un sponsor, s'adressant à ce seul compte.

### Procédure de blocage
Une notification peut être assorti d'une procédure de blocage qui a 3 niveaux :
- **1-écritures bloquées** : le compte agit comme s'il était en mode _avion_ mais peut toutefois chatter avec le Comptable et les sponsors.
- **2-lectures et écritures bloquées** : le compte ne peut plus **que** chatter avec son sponsor ou le Comptable et n'a plus accès à ses autres données.
- **3-compte bloqué** (connexion impossible): cet état est rarement observable du compte ... puisqu'il ne peut pas se connecter. Si la situation se produit en cours de session, celle-ci est brutalement fermée.

La procédure de blocage spécifie combien de jours le niveau restera (1). La destruction du compte intervient à l'anniversaire de l'ouverture de la procédure.

Un **sponsor d'une tribu** peut avoir diverses raisons d'initier une notification bloquante :
- Le _compte ciblé_ n'acquitte plus auprès de la tribu la cotisation convenue.
- Les quotas du compte doivent être révisés en baisse mais les volumes occupés excède la cible souhaitée.
- Le _compte ciblé_ a quitté l'organisation qui exige que son compte soit bloqué.
- Autres, décès ...

Une fois le problème réglé, l'auteur d'une notification la supprime.

> Quand le Comptable a ouvert une procédure de blocage pour une tribu ou un compte, les sponsors ne peuvent plus alors y intervenir.

> **Quand une procédure de blocage est en cours sur un compte, le délai de _péremption_ du compte commence à courir**, comme si le titulaire du compte ne se connectait plus à l'application. Au bout d'un an sans activité, un compte disparaît. Ne pas intervenir par passivité pour régler une procédure de blocage en cours se termine toujours par une issue fatale pour le compte.
