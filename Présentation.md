@@Index général de la documentation - [index](./index.md)

@@Introduction - [index](./README.md)

# Vue d'ensemble de l'application

Une organisation ou association formelle ou informelle peut décider de créer et d'utiliser son propre réseau a-social `monresau` et a choisi un hébergement. Les personnes peuvent accéder à ce réseau depuis un navigateur par une URL comme https://srv.monhebergeur.net/?monreseau

>Par économie un même hébergeur peut héberger plusieurs réseaux mais les données de chacun sont totalement étanches aux autres.

Outre le serveur Web hébergeant l'application, le site de l'hébergeur dispose d'un serveur _backend_ gérant la base de données de chaque réseau : par sécurité il ne traite que les opérations émises par l'application issue de son site Web.

>On ne considère par la suite qu'un seul réseau.

## Avatars, secrets, groupes et contacts
Pour pouvoir accéder à l'application une personne doit **se faire parrainer par une autre y ayant déjà un compte**. Un _parrainage_ est identifié par une _phrase de parrainage_ : parrain et filleul se sont concertés sur le nom souhaité par le filleul, par exemple `Charles` et la phrase qui reste secrète entre eux, par exemple `le hibou n'est pas chouette`. 

Le filleul peut créer son compte en fournissant cette phrase de parrainage et en déclarant sa **phrase secrète de connexion**:
- elle est constituée de 2 lignes d'au moins 16 caractères.
- elle reste uniquement dans la tête du titulaire, n'est enregistrée sous aucune forme nulle-part : elle peut être changée à condition de pouvoir fournir celle actuelle.
- elle crypte toutes les données du compte aussi bien dans la base centrale que dans les micro bases locales de chacun des navigateurs utilisés par le compte. Un piratage des appareils des titulaires des comptes ou de la base centrale centrale ne donnerait au _pirate_ que des informations indéchiffrables.

> _Revers de cette sécurité_ : si la personne titulaire d'un compte oublie sa **phrase secrète de connexion**, elle est ramenée à l'impuissance du pirate. Son compte s'autodétruira un jour et toutes ses données et secrets disparaîtront.

### Avatars principal et secondaires
En créant son compte, le titulaire a créé son **avatar principal**. Un avatar dispose:
- d'un _numéro_ identifiant de 15 chiffres aléatoire et immuable ne portant aucune information utile.
- d'un **nom** lui-même aussi immuable, par exemple `Charles`.
- d'une **carte de visite** constituée d'une photo facultative et d'un court texte, par exemple `Charles III, roi des esturgeons et d’Écosse`, tous deux modifiables uniquement par son titulaire.

Ultérieurement le titulaire du compte pourra créer des **avatars secondaires**, chacun ayant un numéro, un nom et une carte de visite. Il pourra ensuite utiliser à son gré l'un ou l'autre de ses avatars, ayant de ce fait plusieurs personnalités.

> **Le titulaire du compte est le seul à pouvoir connaître la liste de ses avatars**: un autre compte connaissant deux avatars n'est jamais en mesure de savoir s'ils correspondent au même titulaire ou non et même l'administrateur technique du site ne peut pas s'affranchir de cette contrainte assise sur une cryptographie forte.

Un avatar _connaissant_ un autre avatar accède à son _identité complète_ à savoir son **nom** et **sa carte de visite** en plus de son numéro. Ces identités sont cryptées et ne sont échangées qu'entre des avatars l'ayant assumé consciemment.

> Comme dans la vraie vie **plusieurs avatars peuvent porter le même "nom"**, les homonymes sont possibles : à l'écran la début du numéro identifiant permet certes de distinguer `Charles#9476` et `Charles#5432` mais ce sont surtout les cartes de visite de chacun qui donneront des informations pertinentes pour distinguer Charles "le _général_" de Charles "_le roi des esturgeons_".

### Secrets
**Un secret est un texte** d'au plus 5000 caractères pouvant être interprété avec un minimum de _décoration_, gras, italique, titres, listes ... Ce texte est modifiable.

**Des fichiers peuvent être attachés à un secret** : beaucoup de types de fichiers (`.jpg .mp3 .mp4 .pdf ...`) s'affichent directement dans le navigateur. Il est possible d'ajouter et de supprimer des fichiers attachés à un secret et de disposer de plusieurs fichiers portant un même nom dans le secret afin d'en gérer des révisions successives si souhaité.

> Un avatar peut se créer des secrets **personnels**, les mettre à jour, les supprimer, les indexer par des mots clés personnels. Ces secrets sont cryptés comme toutes les données des compte et seul le titulaire du compte a la clé de cryptage apte à les décrypter, laquelle ne pouvant être obtenue qu'en ayant fourni la phrase secrète en se connectant au compte.

### Contacts

> Si elle se limitait à ça, l'application ne permettrait que d'avoir ses propres petits secrets, cryptés connus de soi-même et dont les textes, les fichiers attachés et leur existence même, seraient totalement _privés_. C'est intéressant, mais les gens adorent partager des secrets c'est bien connu ...

**Un avatar dispose d'une liste de contacts**, d'autres avatars dont il connaît a minima le nom et la carte de visite. L'avatar principal d'un compte a **au moins un** contact : celui de l'avatar principal du compte qui l'a parrainé, lui-même ayant ce _filleul_ dans ces contacts.

Pour qu'un contact soit établi entre deux avatars il faut qu'ils l'acceptent tous deux: un contact est obligatoirement **mutuel**.

**Un contact une fois établi dure jusqu'à disparition des deux avatars en contact**. Toutes les données de contact sont cryptées par une clé tirée au sort et détenue cryptée uniquement par les deux avatars en contacts. Hormis les intéressés, personne, pas même l'administrateur de l'hébergement, n'a les moyens cryptographiques pour savoir qui est en contact avec qui.

**Deux avatars en contact partagent une _ardoise commune_** sur laquelle ils peuvent inscrire un texte d'au plus 250 caractères.

**Deux avatars en contact _peuvent_ partagés des secrets**, comme des secrets personnels, si ce n'est qu'ils sont deux à y avoir accès, à pouvoir les mettre à jour et les supprimer. 

Chacun des deux avatars en contact peut indexer les secrets partagés par ses propres mots clés, cette indexation étant inconnue de l'autre.

#### Rendez-vous
Outre le fait d'être contact par parrainage, deux avatars peuvent _prendre rendre-vous_ en s'étant échangé une phrase de reconnaissance, par exemple `la framboise est fragile cette année`.
- soit les personnes se sont rencontrées par ailleurs dans la vraie vie ou sur un réseau public quelconque et y ont défini en commun cette phrase,
- soit les deux avatars ont un _contact commun_ qui leur a proposé une phrase de reconnaissance.

Un des deux avatars entre le premier cette phrase, l'autre le fait ensuite un peu plus tard, mais pas trop la phrase a une durée de vie limitée. Ce faisant il accepte, ou refuse, l'établissement du contact mutuel. Les deux avatars ont désormais accès au nom et à la carte de visite de l'autre, partage une ardoise et, si c'est leurs souhaits, partagent des secrets.

### Groupes
Un avatar peut créer un **groupe** dont il sera le premier membre et _animateur_. Un groupe a un numéro interne, un nom immuable et une carte de visite.

N'importe quel membre du groupe peut inscrire un des avatars qu'il connaît (soit de ses contacts, soit des membres d'autres groupes dont il est membre) comme _candidat_ au groupe : les autres memebres peuvent ainsi discuter de cette candidature.

Puis un animateur peut (ou non) _inviter_ un candidat à rejoindre le groupe en tant que _simple lecteur_, _auteur_ ou _animateur_ : un lecteur n'a que les droits de lecture, un auteur peut créer et mettre à jour des secrets du groupe et un animateur en plus d'être auteur peut inviter des avatars.

**Chaque membre du groupe dispose d'une ardoise** sur laquelle échanger des textes d'au plus 250 caractères avec les autres membres du groupe. Dans un groupe, chacun voit la liste de ses membres et leurs cartes de visite.

**Chaque membre du groupe peut créer, modifier et supprimer des secrets du groupe.**
- ces secrets sont cryptés par une clé aléatoire spécifique au groupe qui a été transmise lors de leur invitation au groupe.
- hormis les membres du groupe, personne ne peut accéder aux secrets ni même savoir que le groupe existe.
- quand un nouveau membre accepte une invitation au groupe il a immédiatement accès à tous les secrets du groupe et quand il est résilié, ou s'est auto-résilié, il n'a plus accès à aucun de ceux-ci.

Un membre peut attacher ses propres mots clés à un groupe faciliter sa recherche quand il est membre de beaucoup de groupes.

Il peut aussi attacher ses propres mots clés aux secrets du groupe pour sélectionner plus rapidement les secrets qu'il recherche, par centre d'intérêt, importance, etc.

# Modes *synchronisé*, *incognito* et *avion*
Pour se connecter à son compte, le titulaire choisit d'abord sous quel **mode** sa session va s'exécuter: _synchronisé_, _avion_ ou _incognito_.

#### Mode _synchronisé_ 
C'est le mode préférentiel où toutes les données du compte sont récupérées depuis une micro base locale cryptée dans le navigateur puis mise à jour depuis le serveur central pour celles qui sont plus récentes. Durant la session la micro base locale est maintenue à jour, y compris lorsque d'autres sessions s'exécutent en parallèle sur d'autres navigateurs et mettent à jour les données du compte : par exemple quand un secret de groupe est mis à jour par un autre membre du groupe.

La connexion ultérieure à un compte ainsi synchronisé est rapide, l'essentiel des données étant déjà dans le navigateur, seules quelques _nouveautés_ étant tirées du serveur central.

#### Mode _avion_
Pour que mode fonctionne il faut qu'une session antérieure en mode _synchronisé_ ait été exécutée dans ce navigateur. L'application présente à l'utilisateur l'état dans lequel étaient ses données à la fin de la dernière session pour ce compte dans ce navigateur.

**L'application ne fonctionne qu'en lecture**, aucune mise à jour n'est possible. Aucun accès à Internet n'est effectué, ce qui est précieux _en avion_ ou dans les _zones blanches_ ou quand l'Internet est suspecté d'avoir des grandes oreilles indiscrètes : certes tout est crypté et illisible mais en mode avion personne ne peut même savoir que vous accédez à vos secrets.

En mode avion les fichiers attachés aux secrets ne sont pas accessibles, **sauf** ceux qui ont été déclarés devoir l'être. Cette déclaration pour un compte s'effectue fichier par fichier pour chaque navigateur et ils sont mis à niveau à l'occasion de chaque session en mode _synchronisé_.

> Il est même conseillé de couper le réseau (le mode _avion_ sur un mobile), de façon à ce que l'ouverture de l'application ne cherche même pas à vérifier si une version plus récente est disponible.

#### Mode _incognito_
**Aucun stockage local n'est utilisé, toutes les données viennent du serveur central**, l'initialisation de la session est plus longue qu'en mode synchronisé. Aucune trace n'est laissée sur l'appareil (utile au cyber-café ou sur le mobile d'un.e ami.e) : certes les traces en question sont inutilisables car cryptées, mais il n'est pas poli d'encombrer la mémoire d'un appareil qu'on vous a prêté.

> Il est même conseillé d'utiliser le mode _page privée_ de votre navigateur, ainsi même le code de l'application sera effacé en fermant la page.

> **En utilisant des sessions synchronisées sur plusieurs appareils, on a autant de copies synchronisées de ses secrets sur chacun de ceux-ci**, et chacun peut être utilisé en mode avion. Les copies ne sont pas exactement les mêmes, les _photographies_ de l'état des données du compte ne pouvant pas être effectuées exactement à la même micro seconde.

> **L'application invoquée depuis un navigateur y est automatiquement mémorisée** : au prochain appel, étant déjà présente en local, elle ne chargera éventuellement que le minimum nécessaire pour se mettre à niveau de la version la plus récente.


# Maîtrise des volumes par les quotas: le Comptable et les tribus
## Quotas de volumes autorisés
Il y a deux types de quotas :
- le quota V1 fixe un maximum d'espace utilisable pour les textes des secrets.
- le quota V2 fixe un maximum d'espace utilisable pour les fichiers attachés aux secrets.

> Les volumes V1 sont 10 fois plus coûteux au méga-octet que les volumes V2 : mais les fichiers peuvent facilement être très volumineux. Le coût d'utilisation dépend de ce que chacun met en secrets et en fichiers attachés.

> **Tout compte dispose de quotas V1 et V2** qu'il peut répartir entre son avatar principal et ses avatars secondaires. Les volumes effectivement utilisés ne peuvent pas dépasser les quotas attribués.

Comme tout est anonyme même pour les fonctions d'administration techniques, la mise en place de _quotas préalables_ est le seul moyen pour contenir l'inflation des volumes qui sinon pourrait permettre à quelques comptes de siphonner toutes les ressources techniques sans qu'il sot possible de savoir à qui s'adresser réellement pour rétablir une nécessaire modération.

## Le compte du "Comptable"
A l'installation d'un réseau, son responsable a donné à l'administrateur de l'hébergement une _clé_ que ce dernier a inscrite dans la configuration de l'hébergement. La base centrale du réseau est vide et inutilisable.

Une seule opération est possible dans cet état: la création du compte du **Comptable** protégée par une phrase secrète inconnue de l'administrateur de l'hébergement. Le _brouillage_ de cette phrase doit correspondre à la _clé_ enregistrée par l'administrateur technique de l'hébergement afin de se prémunir contre une création frauduleuse.

Ce compte ne peut pas être supprimé, il a un numéro fixe reconnaissable et a pour nom d'avatar principal `Comptable`.

C'est un compte _presque_ normal en ce sens qu'il peut avoir des secrets, des contacts, participer à des groupes, créer des avatars secondaires, etc. Mais il a quelques privilèges importants.

> Le **Comptable** n'a pas plus que les autres comptes les moyens cryptographiques de s'immiscer dans les secrets des avatars des comptes : ce n'est en aucune façon un modérateur et n'a aucun moyen d'accéder aux contenus, pas plus qu'à l'identité des avatars et des comptes, exceptés ceux qu'il a en tant que compte _normal_.

### Les tribus
Le Comptable peut déclarer des **tribus** avec un code et un commentaire pour lui. Il attribue des quotas V1 et V2 à chaque tribu, de manière à ce que la somme des quotas attribués ne dépasse pas les quotas globaux convenus avec l'administrateur de l'hébergement en fonction de leurs accords sur la participation éventuelle aux coûts d'hébergement.

Le Comptable peut parrainer des comptes:
- il les affecte à une des tribus et leur donne des quotas prélevés sur les quotas de la tribu.
- le compte parrainé est en général un compte déclaré **parrain** de sa tribu, mais ce n'est pas obligatoire. Le Comptable peut retirer cet attribut _parrain_ (ou l'attribuer).

Un compte **parrain de sa tribu** peut parrainer des comptes filleuls, non parrains de la tribu car c'est un privilège du Comptable. A cette occasion des quotas sont attribués au filleul parrainé, ils sont prélevés sur les quotas de la tribu. Un parrain d'une tribu peut ensuite ajuster les quotas attribués aux filleuls.

> La gestion des quotas s'effectue donc à deux niveaux en décentralisant la maîtrise fine de ceux-ci au niveau des tribus.

**Quelques règles :**
- un parrain d'une tribu peut lister tous les comptes de sa tribu:
  - il n'en a que le numéro, sauf si le compte en question est un compte qu'il a parrainé lui-même ou avec qui il a établi un _contact_.
  - il peut lire la comptabilité des volumes de ces comptes, donc savoir comment les quotas de la tribu ont été affectés et pour chaque les volumes V1 et V2 effectivement occupés lors de leur dernière connexion.
- le comptable a la liste des tribus et pour chaque tribu peut connaître ces mêms informations.
- connaître une liste de comptes ne signifient en rien connaître la liste de leurs avatars secondaires.

### Les _ardoises_ des comptes sur leur tribu
Chaque compte dispose d'une **ardoise** sur sa tribu. Une telle ardoise va servir à régler un problème ou poser une question,
- pour un compte filleul auprès du ou des parrains de sa trbu, voire du Comptable lui-même.
- pour un compte parrain auprès du Comptable.

L'ardoise d'un compte pour sa tribu porte trois textes (datés) :
- celui qu'il a écrit lui-même,
- celui écrit par un des parrains de la tribu,
- celui écrit par le Comptable s'il est sollicité sur l'ardoise.

Chacun de ces trois interlocuteurs est porteur de l'indication, a) s'il a lu ou non l'ardoise dans sa dernière version, b) si à ses yeux le problème a été résolu ou l'information demandée apportée.

Quand tous considèrent qu'ils sont satisfaits, l'ardoise s'efface.

> L'ardoise permet aussi à un parrain (ou au Comptable) de prendre l'intiative d'inscrire son message sur l'ardoise d'un compte de sa tribu, ce qui sera notifié sur l'instant au compte (s'il a une session ouverte).

# Processus de blocage des tribus et des comptes

Le **Comptable** peut avoir diverses raisons de vouloir **bloquer** une tribu :
- **comptable**. La _tribu_ n'acquitte plus la part convenue du financement de l'hébergement.
- **volume**. Les quotas de la tribu doivent être révisés en baisse mais les volumes occupés excède la cible souhaitée.
- **organisation**. La _tribu_ est associée à une entité de l'organisation qui a été dissoute, injonction légale ...
- **autre**: suppression programmée de la tribu.

Un **parrain d'une tribu** peut avoir diverses raisons de vouloir **bloquer** un compte :
- **comptable**. Le _compte_ n'acquitte plus auprès de la tribu la cotisation convenue.
- **volume**. Les quotas du compte doivent être révisés en baisse mais les volumes occupés excède la cible souhaitée.
- **organisation**. Le _compte_ a quitté l'organisation qui exige que son compte soit bloqué.
- **autre**, décès ...

> Le Comptable peut aussi gérer le blocage d'un compte, les parrains ne peuvent plus alors y intervenir.

Un blocage, sauf exception, ne va pas directement interdire tout accès à un compte, ou à tous les comptes d'une tribu pour un blocage de niveau tribu: une graduation est définie.
- **(1)-Alerte informative**. Le compte continue à vivre normalement mais un panneau de pop-up s'affiche régulièrement au cours des sessions pour rappeler la raison de la procédure en cours et le temps restant avant d'atteindre les niveaux plus graves suivants.
- **(2)-Restriction de volume**. Le compte ne peut plus créer de secrets, ni mettre à jour des secrets avec un texte plus long, ni attacher un nouveau fichier à un secret plus volumineux que celui qu'il supprime à cette occasion. Bref le volume utilisé du compte ne peut _que_ baisser, typiquement jusqu'à ce qu'il atteigne la cible proposée.  
- **(3)-Passif (3)**. Le compte ne peut plus que consulter ses données (comme en mode _avion_) mais conserve la possibilité de communiquer avec les parrains de sa tribu et le comptable par son ardoise sur sa tribu.
- **(4)-Bloqué (4)**. Le compte est bloqué et son titulaire ne peut plus rien consulter. Il ne conserve que la possibilité de communiquer avec les parrains de sa tribu et le comptable par son ardoise sur sa tribu.

> **Quand une procédure de blocage est en cours sur un compte, le délai de _péremption_ du compte commence à courir**, comme si le titulaire du compte ne se connectait plus à l'application. Au bout d'un an sans activité, un compte disparaît. Ne pas intervenir par passivité pour régler une procédure de blocage en cours se termine toujours par une issue fatale pour le compte.
