@@Index général de la documentation - [index](./index.md)

# Réflexions sur la maîtrise de la consommation des ressources
Les ressources techniques ne sont, ni infinies, ni gratuites. Chaque réseau déployé a besoin de pouvoir _contrôler / maîtriser_ les volumes des secrets et le cas échéant, si c'est sa politique, de redistribuer le coût d'hébergement sur les comptes, ou certains d'entre eux comme les parrains des tribus.

La maîtrise des volumes peut conduire à engager des procédures de blocages telles que décrites dans la _Présentation Générale_ permettant d'inhiber les comptes ayant un comportement non conforme à la politique du réseau, voire ne payant plus son dû lorsque c'est le cas.

## Rappels
### Quotas V1 et V2 attribués aux avatars
Pour chaque avatar deux _quotas_ sont définis :
- V1 : celui du volume maximal occupé par les textes des secrets.
- V2 : celui du volume maximal occupé par les fichiers attachés aux secrets.

### Unités de volume des quotas
- pour v1 : 0,25 MB
- pour v2 : 25 MB

Les quotas des tribus / comptes / avatars et maximum autorisés pour les groupes et contacts sont donnés en nombre d'unités ci-dessus.

Le _prix sur le marché_ du méga-octet de V1 est environ 10 fois supérieur à celui du méga-octet de V2 ... mais le volume V2 peut-être prépondérant selon le profil d'utilisation.

Les quotas typiques s'étagent de 1 à 255 : (coût mensuel en centimes d'euro)
- (1) - XXS - 0,25 MB / 25 MB - 0,09c
- (4) - XS - 1 MB / 100 MB - 0,35c
- (8) - SM - 2 MB / 200 MB - 0,70c
- (16) - MD - 4 MB / 400 MB - 1,40c
- (32) - LG - 8 MB / 0,8GB - 2,80c
- (64) - XL - 16 MB / 1,6GB - 5,60c
- (128) - XXL - 32 MB / 3,2GB - 11,20c
- (255) - MAX - 64 MB / 6,4GB - 22,40c

### Compteurs d'une ligne comptable
Tout avatar dispose d'une _ligne comptable_. Cet enregistrement a les compteurs suivants :
- `j` : **date du dernier calcul enregistré** : par exemple le 17 Mai de l'année A
- **quotas V1 et V2** en cours (codes `f1` et `f2`)
- **pour le mois en cours**, celui de la date ci-dessus :
  - volumes V1 des textes des secrets : 1) moyen depuis le début du mois (`v1m`), 2) actuel (`v1`), 
  - volumes V2 de leurs fichiers : 1) moyen depuis le début du mois (`v2m`), 2) actuel (`v1`), 
  - cumuls journaliers des volumes des téléchargements des fichiers passant par le réseau : 14 compteurs pour les 14 derniers jours (`trm`).
- ratio de la moyenne de ces cumuls journaliers / quota de V2 (`rtr` : `somme des trm[i] / f2`)
- **pour les 12 mois antérieurs** (dans l'exemple ci-dessus Mai de A-1 à Avril de A),
  - les quotas V1 et V2 appliqués au dernier jour du mois (`f1 f2`).
  - pourcentage des volumes moyens V1 et V2 occupés dans le mois par rapport à leur quota (`r1 r2`).
  - pourcentage du cumul des téléchargements dans le mois par rapport au quota V2 du mois (`r3`).

Pour un avatar primaire seulement :
- totaux des quotas V1 et V2 alloués à ses avatars secondaires (`s1 s2`).
- totaux des volumes V1 et V2 réellement occupés par les avatars du compte au moment de la dernière connexion (`v1c v2c`).

## Règles générales

### Décomptes des volumes des secrets
**Les secrets personnels** sont décomptés sur la ligne comptable de l'avatar qui les détient.

**Les secrets d'un contact** sont décomptés sur chacune des lignes comptables des avatars ayant déclaré accéder aux secrets du contact.

**Pour les secrets de groupe :**
- un avatar membre du groupe est _hébergeur_ du groupe : il peut fixer deux limites v1 / v2 de volume maximal pour les secrets du groupe.
- les secrets sont décomptés sur la ligne comptable de l'avatar hébergeur du groupe.
- l'hébergeur peut changer : les volumes occupés sont transférés de l'avatar antérieur à l'avatar repreneur.
- si l'hébergeur décide d'arrêter son hébergement, la mise à jour des secrets est suspendue tant qu'un repreneur ne s'est pas manifesté. Si la situation perdure au delà d'un an le groupe est déclaré disparu, les secrets sont effacés.

>**Règle 1** : à tout instant une augmentation des volumes effectivement occupés par les secrets **ne peut pas faire dépasser les quotas** attribués à leurs avatars et dans le cas d'un secret de groupe ou de contact, le maximum autorisé pour ce groupe ou ce contact.

>**Règle 2** : la redéfinition d'un quota ou d'un maximum inférieur au volume actuellement occupé, contraint les secrets correspondants à ne pouvoir évoluer qu'en réduction : suppression, réduction de la taille du texte et pour un fichier attaché à un secret impossibilité d'un déclarer un nouveau sans supprimer corrélativement un fichier de taille supérieure.

>**Règle 3** : le téléchargement (download) d'un fichier à un secret **est ralenti** dès que lolume total des téléchargement du compte s'approche ou dépasse sur les 14 derniers jours le niveau de son quota V2 : la temporisation est d'autant plus forte que cet écart l'est.

## Tribus et leurs parrains
C'est le Comptable qui peut déclarer des **tribus**, les doter en ressources et les bloquer, le cas échéant jusqu'à disparition.

Une tribu rassemble un ensemble de comptes dont on souhaite maîtriser le volume global :
- tout compte n'appartient qu'à une seule tribu à un instant donné,
- le **Comptable** peut, au cas par cas, passer un compte d'une tribu à une autre (fermeture d'une tribu, changement d'affectation dans l'organisation ...). 
- quand il existe un système de facturation, c'est l'échelon _tribu_ qui paye.

**Informations attachées à une tribu**  
_Identifiant_ : `[nom, cle, numéro identifiant]` de la tribu.
- La clé est tirée aléatoirement à la création,
- Le numéro identifiant est le _hash_ de la clé (entier sur 53 bits multiple de 4) + 3.

#### Pour information: détail des cryptages
La référence d'une tribu `[nom, clé]` est transmise cryptée par la clé de leur `contact`,
- par le comptable lors de la création d'un compte parrain de la tribu,
- par un compte parrain lors du parrainage d'un compte de la tribu.
- par le comptable dans le cas où il change un compte de tribu.

La référence de sa tribu `[nom, clé]` de sa tribu est présente dans l'enregistrement maître d'un compte,
- (1) _cryptée par la clé publique du comptable_ : le Comptable peut déterminer à quelle tribu est rattachée le compte,
- (2) _cryptée_ par la clé K du compte de façon à ce que le compte lui-même puisse connaître sa tribu. Quand le Comptable change un compte de tribu, ce cryptage est temporairement fait par la clé publique de l'avatar primaire du compte (qu'il est seul à détenir) et qu'il ré-encrypte par sa clé K à la prochaine connexion qui suit.

C'est un calcul long mais le comptable _peut_ finir par associer à une tribu la liste de tous les comptes (leurs avatars principaux) en faisant partie et obtenir les valeurs de leurs lignes comptables (donc leurs forfaits).
- **mais cette liste ne référence, par tribu, que des _numéros de compte_, complètement anonymes.** Le Comptable ne connaît par leur nom qu'une faible partie de ceux-ci. Un Comptable en discussion avec le parrain d'une tribu a donc le moyen de connaître l'utilisation _effective_ des comptes de sa tribu par rapport en particulier aux forfaits alloués, -sans être capable d'y identifier qui que se soit- (mais le ou les parrains de la tribu devraient eux être en mesure de le faire).
- pour chaque compte (avatar primaire) le Comptable ne peut connaître l'occupation réelle que telle que connue lors de la dernière connexion du compte : depuis ses contacts et autres membres de ses groupes ont pu agir. Le chiffre exact est connu par le titulaire du compte à tout instant d'une' session, pas seulement à la connexion.

### Informations enregistrées pour une tribu
- identification cryptée par la clé K du Comptable:
  - nom et clé,
  - commentaire du comptable.
- nombre de comptes actifs dans la tribu.
- sommes des quotas V1 et V2 déjà attribués aux comptes de la tribu.
- quotas V1 et V2 en réserve pour attribution aux comptes actuels et futurs de la tribu.
- liste des parrains de la tribu.
  - pour chacun le couple `[nom, clé]` est crypté par la clé de la tribu : tous les comptes d'une tribu connaissent donc l'identification complète des parrains de leur tribu (leur avatar principal) et donc leur carte de visite.
  - la liste est maintenue à jour par le comptable sur parrainage d'un parrain et détection d'un parrain disparu.
- procédure de blocage en cours, cryptée par la clé de la tribu :
  - raison majeure du blocage : 0 à 4.
  - si la procédure est pilotée par le Comptable (dans une tribu toujours)
  - libellé explicatif du blocage.
  - jour initial de la procédure de blocage
  - nombre de jours de passage des niveaux de 1 à 2, 2 à 3, 3 à 4. Ceci permet de connaître le niveau actuel de blocage et les dates des niveaux futurs.
  - date-heure de dernier changement du statut de blocage.

### Parrains d'une tribu
Les **parrains** d'une tribu sont des comptes habilités par le comptable à créer par parrainage d'autres comptes de leur tribu.
- le pouvoir de parrainage d'un compte d'une tribu lui est conféré / retiré par le _comptable_.
- une tribu peut avoir plusieurs parrains à un instant donné, voire aucun dans des cas particuliers.
- quand un compte parrain parraine un autre compte, un _contact_ est toujours établi entre eux (leurs avatars principaux).
- un parrain d'une tribu a le pouvoir d'attribuer (et de retirer) des ressources à un compte de sa tribu en les prélevant sur la **réserve** de sa tribu.

> **Le Comptable a dans ses _contacts_ les parrains actuels, passés et pressentis des tribus.** Un parrain pressenti est un contact établi avec l'avatar principal d'un compte pour discussion avant éventuelle attribution du statut de parrain par le Comptable.

> Un parrain a pour contact _certains_ comptes de sa tribu, mais pas forcément tous.

Un compte peut accéder à la liste des parrains de sa tribu : il peut ainsi proposer à un autre parrain que le sien de devenir contact mutuel, typiquement pour obtenir l'ajustement de ses quotas ou en cas de départ du parrain qui lui a parrainé la création de son compte.

> Les comptes _parrains_ sont responsables de la consommation d'espace de leur tribu:
>- ils peuvent en contraindre l'expansion et l'accueil de nouveaux comptes,
>- si le réseau a prévu une forme de facturation, c'est la tribu qui est l'échelon normal de facturation. En cas de non paiement, les comptes de la tribu sont susceptibles d'être bloqués à la connexion et in fine de disparaître.

### Attribution / restitution des ressources
Le comptable peut attribuer des _réserves_ aux tribus et les diminuer.

Un compte parrain peut augmenter / réduire les quotas V1 et V2 des comptes de sa tribu.

Lorsqu'un compte s'auto-détruit, les ressources sont rendues à la tribu.

**Lorsqu'un compte disparaît**, ni la clé ni l'identifiant de la tribu n'étant accessible par le traitement quotidien qui détecte la disparition (elles ne sont décodées qu'en session), ce dernier inscrit dans une table d'attente les volumes rendus et _la clé de la tribu cryptée par la clé publique du comptable_. Lors d'une session du Comptable, ce dernier peut décrypter ces restitutions et en créditer les tribus : ce n'est donc pas immédiat.
