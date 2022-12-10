@@Index général de la documentation - [index](./index.md)

# Les comptes et leurs avatars

Un compte est toujours parrainé par un autre compte :
- soit un compte _parrain_ de sa tribu : le compte _filleul_ sera de la même tribu et n'en sera pas _parrain_ lui-même.
- soit le _Comptable_ : le compte sera de la tribu fixée par le Comptable et sera ou non _parrain_ de cette tribu selon l'option choisie par le Comptable.

> Le Comptable peut ultérieurement donner ou retirer l'attribut _parrain de sa tribu_ d'un compte. Le Comptable peut aussi changer un compte de tribu.

## Processus de création d'un compte

>**Remarque** : la création du compte Comptable fait l'objet d'une rubrique distincte en raison de ses particularités.

#### Phase 1 : déclaration de parrainage par le compte parrain
Le parrain et le filleul se concertent pour définir :
- le nom du compte filleul, par exemple `Claude`,
- la phrase de parrainage, par exemple `les tomates bleues ne rougissent pas`. Une phrase peut être refusée si elle apparaît _trop proche_ d'une déjà enregistrée. Les phrases ne sont pas enregistrées en clair mais _grossièrement hachée_, un hachage produisant beaucoup de collisions (_trop proche_ signifie avoir même hachage grossier).

Le parrain enregistre aussi dans son parrainage :
- un petit mot de bienvenue à destination de son filleul, mot qui apparaît sur le _contact_ ainsi pré-établi et _en attente_.
- les quotas de volumes V1 et V2 à attribuer au compte filleul et prélevés sur les quotas de la tribu.
- les volumes maximum V1 et V2 qu'il accepte de consacrer aux secrets du contact avec son filleul.
  - le parrain peut ainsi éviter d'avoir ses quotas trop largement impactés par des secrets pas forcément souhaités avec son filleul. 
  - S'il déclare 0, il n'y aura pas de secrets partagés sur le contact : parrain et filleul ne communiqueront que par l'ardoise commune de leur contact.
- il peut cocher sa case _ne pas m'inviter_. Dans ce cas son filleul ne pourra pas le proposer, ni comme membre d'un groupe, ni pour une prise de contact pour un autre de ses avatars.

#### Phase 2 : auto-création du compte filleul
Son titulaire donne la phrase de parrainage convenue :
- elle n'existe pas. Échec de la création: redemander au parrain un nouveau parrainage avec une phrase corrigée.
- elle existe mais le délai d'utilisation est dépassé: demander au parrain de prolonger son parrainage.
- elle existe et est valide : la procédure continue.

Un dialogue s'ouvre qui permet au filleul:
- de vérifier que son nom est bien celui défini avec son parrain et que les quotas attribués par le parrain lui conviennent.
- si oui, la **procédure d'acceptation** continue,
  - par la saisie de la phrase secrète de connexion,
  - la déclaration du volume maximal des secrets partagés sur le contact avec le parrain (0 le cas échéant),
  - l'écriture d'un petit mot de remerciement,
  - la coche éventuelle de la case _ne pas m'inviter_.
  - enfin de la validation finale.
- si non, la **procédure de refus** consiste simplement à donner (ou non) un petit mot de courtoisie expliquant la raison du refus.

Le _contact_ en cours d'établissement (voir la rubrique **Contact** pour plus d'information) entre parrain et filleul va passer successivement par les états suivants :
- _en attente_ après le dépôt du parrainage par le parrain.
- _hors délai_ si le filleul n'a pas essayé de créer son compte parrainé dans le délai imparti (que le parrain peut prolonger).
- _refusé_ si le filleul a explicitement refusé : le cas échéant le parrain devra émettre plus tard une nouvelle proposition de parrainage.
- _actif_, le filleul a accepté, son compte est créé, le contact entre parrain et filleul est opérationnel.

##### La phrase secrète de connexion
- **elle a deux lignes**:
  - une première d'au moins 16 signes : l'application n'accepte pas d'avoir 2 comptes ayant des phrases secrètes ayant une même première ligne.
  - une seconde d'au moins 16 signes.
- elle est demandée 2 fois pour vérification.

> Le titulaire du compte ne devra jamais l'oublier car elle n'est mémorisée nulle part en clair dans l'application et n'est d'ailleurs fugitivement en clair que le temps de sa saisie dans l'application (elle ne transite jamais sur le réseau, le serveur ne la voit jamais). Personne, ni le Comptable, ni l'administrateur de l'hébergement n'ont les moyens cryptographiques pour la retrouver.

### A l'issue de la création du compte
- le **compte lui-même est créé**.
- son **avatar principal est créé**.
- le compte peut créer / modifier / supprimer des secrets personnels.
- son avatar principal a un **contact mutuel établi** avec son parrain : si parrain et filleul ont accordé des volumes V1 et V2 pour partager leurs secrets, ils peuvent le faire. Dans tous les cas a minima ils peuvent échanger un texte court sur leur ardoise.

### Autres informations attachées à un compte
**Un mémo**  
C'est un texte libre facultatif de moins de 250 signes où le titulaire du compte peut inscrire ce qu'il veut. Il est le seul à pouvoir le lire.

**La liste des mots-clés du compte**  
Voir la rubrique spécifique relative aux mots clés et leurs usages d'indexation et de filtrage. Un compte peut définir une centaine de mots clés dont il sera le seul à connaître le texte et la signification.

## Les avatars d'un compte
Un compte a toujours un avatar principal et ne peut pas en changer.

Au cours de sa vie un compte peut,
- se créer un nouvel avatar secondaire en lui donnant un nom et en lui attribuant une partie de ses quotas d'espace.
- les supprimer, ce qui est une opération qui ne se lance pas à la légère.

> L'intérêt d'avoir plusieurs avatars est de compartimenter sa vie et dans le cas de partage de secrets, typiquement dans des groupes, de présenter l'un ou l'autre de ses avatars en fonction du thème traité dans le groupe.

La création d'un avatar lui donne les informations immuables suivantes:
- son **numéro identifiant**,
- sa **clé** de cryptage de sa _carte de visite_,
- son **nom** : les homonymes sont possibles.
  - l'application complète à l'affichage le nom par les derniers chiffres de son numéro identifiant,
  - c'est principalement la carte de visite qui permet de lever les ambiguïtés.

### Carte de visite d'un avatar

La **carte de visite** d'un avatar est modifiable par le compte et comporte :
- une photo facultative de petite dimension,
- un court texte en complément du nom de l'avatar: par exemple complétant le nom `Charles` par `Roi des esturgeons et d’Écosse`.

Elle est mémorisée cryptée par la clé de l'avatar et n'est lisible que pour certains autres avatars :
- tout membre d'un groupe dont l'avatar est membre,
- tous ses contacts,
- le Comptable, uniquement durant le temps d'une session de _chat_ ouverte par l'avatar lui-même.

> Il est impossible pour des raisons cryptographiques d'accéder au contenu d'une _carte de visite_ à moins d'en avoir eu communication explicite dans les cas ci-dessus.


## Auto destruction d'un compte
Un compte peut s'auto-détruire. Ses données sont effacées *mais pas tous ses secrets* : 
- pour un secret partagé avec un _contact_ : le secret reste disponible pour l'autre avec qui il était en contact.
- pour un secret partagé avec un _groupe_, le secret _appartient_ au groupe et reste normalement accessible aux autres membres.

##  Disparition d'un compte

**Un compte qui ne s'est pas connecté pendant 12 mois est déclaré *disparu*** : sa connexion est impossible et ses données finiront par être physiquement détruites afin de ne pas encombrer inutilement l'espace. 

Comme rien ne raccorde un compte au monde réel, ni adresse e-mail, ni numéro de téléphone ... il n'est pas possible d'informer quiconque de la disparition prochaine de son compte.

# En savoir plus ...
## La cryptographie pour les nuls
### Cryptage symétrique AES-256
Symétrique signifie que la clé de cryptage est la même que celle de décryptage : la longueur des clés est de 256 bits (32 octets).

Personne en 2022 n'a proclamé avoir réussi à casser un cryptage de clé aléatoire AES-256.

Le cryptage / décryptage est rapide et peut concerner des textes de n'importe quelle taille.

### Cryptage asymétrique RSA-2048
Un couple de clés est généré simultanément :
- la **clé publique** est utilisée pour crypter un texte de longueur maximale de 256 octets. Même quand le texte origine est plus court, le texte crypté occupe 256 octets.
- la **clé privée** est utilisée pour décrypter un texte crypté par la clé publique.

Le cryptage / décryptage est lent. On utilise ce cryptage pour produire un texte lisible seulement par le détenteur de la clé privée. De fait la clé publique est comme son nom l'indique disponible à n'importe qui.

### Brouillage PBKFD2
quasiCet algorithme _brouille_ un texte initial pour en restituer un texte court (32 octets) : il est quasi impossible de retrouver le texte initial depuis le texte brouillé en raison du coût élevé de calcul que ça demande et de l'impossibilité d'utiliser des processeurs spécifiques à cet effet.

PBKFD2 est employé pour brouiller les phrases secrètes qui, vu leur longueur, ne peuvent pas être pas être cassées par force brute avant la fin de la planète.

### Fonction hash
Cette fonction prend en entrée une suite d'octets et en retourne un entier de 53 bits multiple de 4 (avec peu de _collisions_ deux textes différents donnant le même hash, en gros une chance sur un million de milliards de fois)

## A propos des comptes et leurs avatars

### Clé et identifiant d'un avatar
La **clé** d'un avatar est constituée de 32 octets (256 bits) tirés au sort à la création de l'avatar. Elle crypte sa _carte de visite_.

L'identifiant d'un avatar est le _hash_ de sa clé (un multiple de 4).

Par exception, l'identifiant du Comptable est `9007199254740988` (le plus grand entier sur 53 bits multiple de 4).

### Identifiant d'un compte
Un compte et son avatar principal ont le même identifiant.

### Clé K du compte
Cette clé de cryptage AES-256 (32 octets) a été tirée aléatoirement par l'application à la création du compte :
- c'est la clé majeure du compte : elle est immuable et crypte toutes les données cruciales du compte.
- elle ne transite jamais en clair sur le réseau, n'est jamais communiqué au serveur et reste dans la mémoire de l'application durant son exécution.
- elle est conservée dans l'enregistrement du compte cryptée par un brouillage PBKFD2 de la phrase secrète du compte. Le changement de phrase secrète se limite de ce fait à ré-encrypter la clé K.

### Informations détenues sur le compte
Dans son enregistrement maître :
- la **clé K** cryptée par le brouillage de la phrase secrète.
- le **nom et la clé de la tribu** du compte, cryptés par la clé K.
- la **liste des avatars principal et secondaires** du compte, cryptée par la clé K. Pour chaque avatar, le compte détient :
  - son _nom_, sa _clé_ et son _identifiant_.
  - la _clé privée RSA_ attribuée à l'avatar a sa création.

Dans un enregistrement annexe susceptible de changer plus souvent :
- la **liste des mots-clés** déclarés par le titulaire du compte, cryptée par la clé K. En conséquence seul le titulaire du compte les voit, ils ne sont jamais publics et peuvent ainsi déroger à toutes les règles de civilité en usage.
- le **mémo** privé du compte, crypté aussi par la clé K.

Dans l'enregistrement _ligne de comptabilité_ de son avatar principal quand **le compte fait l'objet d'une procédure de blocage** :
- raison majeure du blocage : 0 à 4.
- si la procédure est pilotée par le Comptable.
- libellé explicatif du blocage.
- jour initial de la procédure de blocage
- nombre de jours de passage des niveaux de 1 à 2, 2 à 3, 3 à 4. Ceci permet de connaître le niveau actuel de blocage et les dates des niveaux futurs.
- date-heure de dernier changement du statut de blocage.

Ces données sont cryptées par la clé de la tribu et elles sont de fait lisibles:
- par les comptes de la tribu (chacun a la clé de _sa_ tribu).
- par le Comptable (il a les clés de toutes les tribus).

> Il est impossible d'obtenir la liste des avatars d'un compte sauf dans l'application au cours d'une session ouverte par le compte lui-même et qui de ce fait dispose de la clé K pour décrypter la liste de ses avatars. Cette sécurité complique, en particulier, la gestion de la disparition des comptes.

### Informations détenues par avatar
Dans son enregistrement maître :
- la liste de ses contacts cryptée par la clé K du compte.
- la liste des groupes dont il est membre cryptée par la clé K du compte.

Dans son enregistrement _carte de visite_ :
- la photo et le texte de la carte, cryptés par la clé de l'avatar.

Dans son enregistrement _ligne de comptabilité_, une série de compteurs statistiques et de décompte des volumes autorisés et utilisés. L'enregistrement n'est pas crypté mais n'est effectivement lisible que :
- par le titulaire du compte pour tous ses avatars.
-  pour la seule ligne de l'avatar principal du compte :
  - par les parrains de la tribu du compte qui connaissent leurs filleuls.
  - par le Comptable dans certaines conditions spécifiées ci-dessous.

Données enregistrées :
- **quotas V1 et V2**.
- **pour le mois en cours** :
  - volume V1 total occupé par les textes des secrets : 1) moyenne depuis le début du mois, 2) actuel, 
  - volume V2 total occupé par leurs fichiers attachés : 1) moyenne depuis le début du mois, 2) actuel. 
  - cumul des volumes des téléchargements des fichiers attachés : 14 compteurs pour les 14 derniers jours.
- **pour les 12 mois antérieurs** :
  - les quotas V1 et V2 appliqués au dernier jour du mois.
  - le pourcentage du volume moyen utilisé dans le mois par rapport au quota: 1) pour V1, 2) pour V2.
  - le pourcentage du cumul des téléchargements des fichiers dans le mois par rapport au quota de V2 du mois.
- **_pour un avatar primaire seulement :_**
  - quotas totaux V1 et V2 actuellement attribués aux avatars secondaires.
  - volumes totaux V1 et V2 effectivement utilisés pour tous les avatars du compte constaté lors de la dernière connexion de celui-ci. Ces chiffres ne donnent qu'une indication : a) ils peuvent être _vieux_, le compte a pu ne pas se connecter depuis longtemps, b) après cette dernière connexion les actions des contacts et autres membres des groupes auxquels le compte participe, ont pu modifier très sensiblement les volumes effectivement occupés par les avatars.

#### Unités de volume
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

## Qu'est-ce que le Comptable peut obtenir comme données statistiques sur les volumes utilisées ?
Le Comptable peut obtenir une totalisation des lignes comptables de tous les avatars confondus : en effet de chaque avatar individuellement il n'a que le numéro ce qui ne permet aucun regroupent, ni par compte ni par tribu.

Mais le Comptable peut obtenir la liste des lignes comptables des **avatars principaux** des comptes par tribu.

Au niveau d'un avatar principal,
- les totaux des **quotas** actuels pour l'avatar principal et les secondaires sont précis et actuels.
- le **total des volumes effectivement utilisés** par tous les avatars du compte **lors de la dernière connexion du compte**, possiblement il y a longtemps. L'information donne une idée mais est imprécise.

_Remarque_ : our un compte précis, si celui-ci a une session de chat ouverte, sa dernière connexion n'est pas si ancienne que ça.

Mais cette information _ligne comptable_ est généralement anonyme, le Comptable n'en connaît qu'un numéri identifiant abscons, sauf dans les cas suivants où il peut savoir à qui elle se rapporte:
- pour les lignes relatives aux comptes qu'il a parrainés, il dispose de la carte de visite du compte.
- pour les lignes relatives aux comptes dont l'avatar principal et lui-même se sont déclarés _contact mutuel_.
- enfin pour les lignes relatives aux comptes ayant une session de _chat_ en cours.

Dans ces cas le Comptable va avoir pour le compte en question, la même information qu'un parrain vis à vis de son filleul : sa ligne comptable qui va donner le total des quotas distribués aux avatars du compte et le total des volumes effectivement utilisés par tous ces avatars lors de la dernière connexion du compte, possiblement il y a longtemps.

>Le Comptable, confidentialité oblige, ne peut pas accéder à toutes les données statistiques d'usage des volumes. Toutefois il peut en savoir assez pour déterminer:
>- quand un parrain de tribu réclame des quotas supplémentaires, comment le volume est effectivement utilisé par rapport aux quotas actuels,
>- quand un compte se plaint que son parrain ne lui donne pas de quotas supplémentaires, ce qu'il utilise réellement de ses quotas.

