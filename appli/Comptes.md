@@Index général de la documentation - [index](./index.md)

# Les comptes et leurs avatars

Un compte (sauf le Comptable) est toujours _sponsorisé_ par :
- soit un compte _sponsor_ de sa tribu : le compte _sponsorisé_ sera de la même tribu et en sera ou non _sponsor_ lui-même selon ce que le sponsor aura décidé en déclarant son sponsoring.
- soit le _Comptable_ : le compte sera de la tribu fixée par le Comptable et sera ou non _sponsor_ de cette tribu selon l'option choisie par le Comptable.

> Le Comptable peut ultérieurement donner ou retirer l'attribut _sponsor de sa tribu_ d'un compte. Le Comptable peut aussi changer un compte de tribu.

## Processus de création d'un compte (sauf le Comptable)

#### Phase 1 : déclaration de sponsoring par le compte sponsor
Le sponsor et le titulaire du compte à créer se concertent pour définir :
- le nom du compte sponsorisé, par exemple `Claude`,
- la phrase de sponsoring, par exemple `les tomates bleues ne rougissent pas`. Une phrase peut être refusée si elle apparaît _trop proche_ d'une déjà enregistrée. Les phrases ne sont pas enregistrées en clair mais _hachées_ : une partie du début de la phrase est également hachée de manière à détecter une possible collision avec une phrase _trop proche_.

Le sponsor enregistre aussi dans son sponsoring :
- un petit mot de bienvenue à destination du sponsorisé.
- les quotas de volumes V1 et V2 à attribuer au compte sponsorisé et prélevés sur les quotas de la tribu.
- l'option pour le sponsorisé d'être lui-même sponsor de sa tribu ou non.

Ce sponsoring a une durée de vie limité : il peut aussi être prolongé et supprimé par le sponsor tant qu'il est _en attente_.

Un compte sponsor de sa tribu peut lister les sponsorings en cours et leur état, _en attente_, _accepté_, _refusé_.

#### Phase 2 : auto-création du compte sponsorisé
Son titulaire donne la phrase de sponsoring convenue :
- elle n'existe pas. Échec de la création: redemander au parrain un nouveau sponsoring avec une phrase corrigée.
- elle existe mais le délai d'utilisation est dépassé: redemander au parrain un nouveau sponsoring.
- elle existe et est valide : la procédure continue.

Un dialogue s'ouvre qui permet au sponsorisé:
- de vérifier que son nom est bien celui défini avec son sponsor et que les quotas attribués par le parrain lui conviennent.
- si oui, la **procédure d'acceptation** continue,
  - par la saisie de la phrase secrète de connexion,
  - l'écriture d'un petit mot de remerciement,
  - enfin de la validation finale : le compte sponsorisé est connecté.
- si non, la **procédure de refus** consiste simplement à donner (ou non) un petit mot de courtoisie expliquant la raison du refus.

##### La phrase secrète de connexion
- Elle a au moins 24 signes.
- Elle est mémorisée _hachée_ par un algorithme complexe rendant impossible de retrouver par _force brute_ la phrase originale depuis son hachage.
- Un _extrait_ du début de la phrase est également hachée : il ne peut pas exister 2 comptes ayant un même _extrait_ de phrase.

A sa déclaration en acceptant le sponsoring, ou plus tard en changeant la phrase, celle-ci est demandée deux fois.

> Le titulaire du compte ne devra jamais l'oublier car elle n'est mémorisée nulle part en clair dans l'application et n'est d'ailleurs fugitivement en clair que le temps de sa saisie dans l'application (elle ne transite jamais sur le réseau, le serveur ne la voit jamais). Personne, ni le Comptable, ni l'administrateur de l'hébergement n'ont les moyens cryptographiques pour la retrouver.

### A l'issue de la création du compte
- le **compte lui-même est créé**.
- sa clé de cryptage principale est générée : elle est invisible, n'est jamais stockée en clair ni ne transite en clair sur le réseau. Le serveur ne les voit jamais en clair.
- son **avatar principal est créé** : on peut _confondre_ le compte et son avatar principal, ils ont le même identifiant.
- le compte peut créer / modifier / supprimer des notes personnelles.

### Autres informations attachées à un compte
**Un mémo**  
C'est un texte libre facultatif de moins de 250 signes où le titulaire du compte peut inscrire ce qu'il veut. Il est le seul à pouvoir le lire.

**La liste des mots-clés du compte**  
Voir la rubrique spécifique relative aux mots clés et leurs usages d'indexation et de filtrage. Un compte peut définir une centaine de mots clés dont il sera le seul à connaître le texte et la signification.

## Les avatars d'un compte
Un compte a toujours un avatar principal et ne peut pas en changer.

Au cours de sa vie un compte peut,
- créer des avatars secondaires en leur donnant un nom.
- les supprimer, ce qui est une opération qui ne se lance pas à la légère.

> L'intérêt d'avoir plusieurs avatars est de compartimenter sa vie : dans le cas de partage de notes dans des groupes, le titulaire du compte choisit de présenter l'un ou l'autre de ses avatars en fonction du thème traité dans le groupe.

La création d'un avatar lui donne les informations immuables suivantes:
- son **numéro identifiant** : c'est un numéro à 16 chiffres.
- la **clé** de cryptage de sa _carte de visite_.
- son **nom** : les homonymes sont possibles.
  - l'application complète à l'affichage le nom par les 4 derniers chiffres de son numéro identifiant,
  - c'est principalement la carte de visite qui permet de lever les ambiguïtés.

### Carte de visite d'un avatar

La **carte de visite** d'un avatar est modifiable par le compte et comporte :
- une photo facultative de petite dimension,
- un court texte en complément du nom de l'avatar: par exemple complétant le nom `Charles` par `Roi des esturgeons et d’Écosse`.

Elle est mémorisée cryptée par la clé de l'avatar et n'est lisible que par les _contacts_ de l'avatar (voir la section suivante).

> Il est impossible pour des raisons cryptographiques d'accéder au contenu d'une _carte de visite_ à moins d'en avoir eu communication explicite.

## Auto destruction d'un compte
Un compte peut s'auto-détruire : tous ses avatars secondaires doivent avoir été détruits, la destruction de l'avatar principal vaut destruction du compte lui-même.
- Ses quotas V1 et V2 sont rendus à sa tribu.
- Ses données sont effacées _mais pas toutes ses notes_ : dans un groupe une note _appartient_ au groupe et reste normalement accessible aux autres membres.

##  Disparition d'un compte

**Un compte qui ne s'est pas connecté pendant 12 mois est déclaré *disparu*** : sa connexion est impossible et ses données seront physiquement détruites afin de ne pas encombrer inutilement l'espace. 

Comme rien ne raccorde un compte au monde réel, ni adresse e-mail, ni numéro de téléphone ... il n'est pas possible d'informer quiconque de la disparition prochaine de son compte.

## Les _contacts_ d'un compte
Un _contact_ est un avatar, principal (un autre compte) ou secondaire (rattaché à un autre compte mais on ne sait pas lequel) connu par son nom et sa carte de visite.

Un compte a pour _contacts_ :
- tous les **avatars principaux** des comptes de sa tribu.
- tous les **membres des groupes** dont l'un de ses avatars est membre.
- des avatars qui ont été contactés par leur phrase de contact et avec qui un _chat_ a été ouvert.

> Remarque : un contact est _symétrique_. Si A est un contact de B, B est un contact de A du moins tant que A et B existent.

### Phrase de contact d'un avatar
Un avatar peut se déclarer une _phrase de contact_, par exemple `Superman n'aime pas les choux fleurs`.
- il peut donner à quelqu'un cette phrase dans le vraie vie ou la communiquer dans un groupe ...
- tout avatar qui connaît cette phrase pour l'utiliser pour ouvrir une ardoise de _chat_ avec l'avatar l'ayant déclaré.
- enfin la phrase peut être détruite afin que personne ne puisse plus l'utiliser pour établir un chat.

> Il se peut qu'en contactant un avatar par sa phrase de contact, on tombe sur un avatar déjà contact, le cas échéant ayant déjà une ardoise de _chat_ ouverte.

## Les ardoises de _chat_
Un avatar A peut ouvrir une _ardoise de chat_ avec n'importe lequel de ses _contacts_.
- une fois ouverte l'ardoise existe pour toujours et a le même contenu pour A et B. Il est crypté par une clé attaché au chat que seuls A et B ont.
- si B disparaît ou s'est auto-détruit, A continue de voir l'ardoise qu'il partageait avec B (en sachant qu'il a disparu).
- les cartes de visites de A et B sont mutuellement vues par l'autre.
- A comme B peuvent attacher des mots clés à une ardoise de chat : l'autre n'en n'a pas connaissance.
- l'ardoise est commune à A et B : elle reflète le dernier texte écrit.

> On ne peut pas _détruire_ un chat ouvert mais rien n'oblige à le lire : il suffit de lui affecter un mot clé _indésirable_ et de mettre un filtre excluant les chats ayant ce mot clé.

# En savoir plus ...
## La cryptographie pour les nuls
### Cryptage symétrique AES-256
Symétrique signifie que la clé de cryptage est la même que celle de décryptage : la longueur des clés est de 256 bits (32 octets).

Personne en 2023 n'a proclamé avoir réussi à casser un cryptage de clé aléatoire AES-256.

Le cryptage / décryptage est rapide et peut concerner des textes de n'importe quelle taille.

### Cryptage asymétrique RSA-2048
Un couple de clés est généré simultanément :
- la **clé publique** est utilisée pour crypter un texte de longueur maximale de 256 octets. Même quand le texte origine est plus court, le texte crypté occupe 256 octets.
- la **clé privée** est utilisée pour décrypter un texte crypté par la clé publique.

Le cryptage / décryptage est lent. On utilise ce cryptage pour produire un texte lisible seulement par le détenteur de la clé privée. De fait la clé publique est comme son nom l'indique disponible à n'importe qui.

Comme la longueur du texte à crypter est courte, on utilise souvent le cryptage asymétrique pour crypter ... une clé de cryptage symétrique.

### Brouillage PBKFD2
Cet algorithme _brouille_ un texte initial pour en restituer un texte court (32 octets) : il est quasi impossible de retrouver le texte initial depuis le texte brouillé en raison du coût élevé de calcul que ça demande et de l'impossibilité d'utiliser des processeurs spécifiques ou graphiques à cet effet.

> L'inconvénient de cet algorithme est le pendant de son avantage : 2 secondes d'attente pour un calcul, ça demande une conception qui en tienne compte et exclut pratiquement un usage sur un serveur.

PBKFD2 est employé pour brouiller les phrases secrètes qui, vu leur longueur, ne peuvent pas être pas être cassées par _force brute_ avant la fin de la planète. L'usage de dictionnaires de mots de passe fréquent a montré son inefficacité dès lors que le texte est long (24 signes c'est beaucoup) et qu'on y alterne majuscules, minuscules, chiffres séparateurs, voir quelques caractères spéciaux.

### Fonction hash
Cette fonction prend en entrée une suite d'octets et en retourne un entier de 53 bits avec peu de _collisions_ : deux textes différents ne donnent le même hash, en gros qu'une fois sur un million de milliards de fois.

## A propos des comptes et leurs avatars

### Clé et identifiant d'un avatar
La **clé** d'un avatar est constituée de 32 octets (256 bits) tirés au sort à la création de l'avatar. Elle crypte sa _carte de visite_.

Son identifiant est basé sur le _hash_ de sa clé.

Par exception, l'identifiant du Comptable est `1000000000000000` pour l'espace `10`.

### Identifiant d'un compte
Un compte et son avatar principal ont le même identifiant.

### Clé K du compte
Cette clé de cryptage AES-256 (32 octets) a été tirée aléatoirement par l'application à la création du compte :
- c'est la clé majeure du compte : elle est immuable et crypte toutes les données cruciales du compte.
- elle ne transite jamais en clair sur le réseau, n'est jamais communiqué au serveur et reste dans la mémoire de l'application durant son exécution.
- elle est conservée dans l'enregistrement du compte cryptée par un brouillage PBKFD2 de la phrase secrète du compte. Le changement de phrase secrète se limite de ce fait à ré-encrypter la clé K.

### Informations détenues sur le compte et ses avatars
Dans son enregistrement maître :
- la **clé K** cryptée par le brouillage de la phrase secrète.
- le **nom et la clé de la tribu** du compte, cryptés par la clé K.
- la **liste des avatars principal et secondaires** du compte, cryptée par la clé K. Pour chaque avatar, le compte détient :
  - son _nom_, sa _clé_ et son _identifiant_.
  - la _clé privée RSA_ attribuée à l'avatar a sa création.
- la **liste des mots-clés** déclarés par le titulaire du compte, cryptée par la clé K. En conséquence seul le titulaire du compte les voit, ils ne sont jamais publics et peuvent ainsi déroger à toutes les règles de civilité en usage.
- le **mémo** privé du compte, crypté aussi par la clé K.
- pour chaque avatar, 
  - **la liste des groupes dont l'avatar est membre** est également cryptée par la clé K. La clé de cryptage d'un groupe est ainsi elle-même enchâssée dans un item crypté.
  - sa **carte de visite**, petite photo et court texte, cryptés par la clé de l'avatar.

## Quelques compteurs statistiques d'usage des volumes d'un compte
Les volumes V1 sont ceux des textes des notes, les volumes V2 sont ceux des fichiers attachés aux notes.

Pour un compte, les compteurs suivants reflètent l'usage de l'espace:
- quotas actuels en volumes V1 et V2 attribués par le Comptable au compte.
- volumes V1 et V2 effectivement utilisés pour les notes.
- volumes moyens V1 et V2 pour le mois en cours.
- volumes V2 des fichiers transférés :
  - cumul de la journée pour chacun des sept derniers jours,
  - cumul sur le mois courant.
- **pour les 12 derniers mois**,
  - les quotas au dernier jour du mois.
  - la moyenne des volumes journaliers du mois,
  - le volume total des transferts de fichiers dans le mois.

> Un compte _non sponsor_ n'a accès qu'à ses propres statistiques. Le Comptable a accès à toutes celles des comptes et un sponsor à celles des comptes de sa tribu. Cette connaissance leutr permet par exemple d'apprécier :
>- quand un sponsor de tribu réclame des quotas supplémentaires, comment le volume est effectivement alloué et utilisé par les comptes,
>- quand un compte se plaint que son sponsor ne lui donne pas de quotas supplémentaires, ce qu'il utilise réellement de ses quotas.

## Unités de volume
Les quotas sont donnés en nombre d'unités ci-dessous :
- pour V1 : 0,25 MB
- pour V2 : 25 MB

Les quotas s'étagent de 1 à 255. Certains quotas ont un code symbolique. L'ordre de grandeur du coût mensuel pour l'hébergeur est donné ci-après pour information en centimes d'euro :
- (1) - XXS - 0,25 MB / 25 MB - 0,09c
- (4) - XS - 1 MB / 100 MB - 0,35c
- (8) - SM - 2 MB / 200 MB - 0,70c
- (16) - MD - 4 MB / 400 MB - 1,40c
- (32) - LG - 8 MB / 0,8GB - 2,80c
- (64) - XL - 16 MB / 1,6GB - 5,60c
- (128) - XXL - 32 MB / 3,2GB - 11,20c
- (255) - MAX - 64 MB / 6,4GB - 22,40c

Le code _numérique_ d'un quota va de 0 à 255 : c'est le facteur multiplicateur du forfait le plus petit (0,25MB / 25MB). Les codes symboliques sont enregistrés dans la configuration de l'hébergement et peuvent être ajoutés / modifiés sans affecter les données déjà enregistrées.
