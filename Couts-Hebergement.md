# Répartition des coûts d'hébergement de l'application

Le coût d'usage de l'application pour une organisation correspond aux coûts d'hébergement des données et de traitement de celles-ci. Selon les techniques et les prestataires choisis, les coûts unitaires varient mais existent dans tous les cas.

Ci-dessous on considère le coût mensuel pour un compte.

#### Abonnement
Il correspond aux coûts récurrents mensuels pour un compte même quand il ne se connecte pas. Par simplification ils ont été résumés ainsi:
- **(V1) Volume des données sur la base de données**. Il est calculé proportionnellement à la somme des nombres de,
  - **(nn) notes** personnelles et notes d'un groupe hébergé par le compte,
  - **(nc) chats** en ligne, 
  - **(ng) participations aux groupes**.
- **(V2) Volume des fichiers attachés aux notes** ci-dessus stockés sur un _Storage_.

Pour obtenir le coût d'abonnement à ces deux volumes, il est pris en compte, non pas _le volume effectivement utilisé à chaque instant_ mais **les _quotas_ Q1 et Q2** choisis par le compte, c'est à dire **l'espace maximal** auquel il s'abonne et qui a été réservé à cet effet.

_L'ordre de grandeur_ des prix du marché, donne les coûts suivants en centimes d'euro annuel:

    'un' Q1 : 250 notes chats / groupes -> 0,45c/an
    'un' Q2 : 100Mo                     -> 0,10c/an

    Pour un compte XXS ( 1 Q1 :   250n /  1 Q2 :  100Mo) ->   1,6 c/an
    Pour un compte MD  ( 8 Q1 :  2000n /  8 Q2 :  800Mo) ->  13,0 c/an
    Pour un compte XXL (64 Q1 : 16000n / 64 Q2 : 6,4Go ) -> 102,0 c/an

> Les volumes V1 apparaissent environ 25 fois plus coûteux au méga-octet que les volumes V2, mais comme les fichiers peuvent être très volumineux, le coût d'utilisation dépend de ce que chacun met en textes des notes et en fichiers attachés.

> Les volumes _effectivement utilisés_ ne peuvent pas dépasser les quotas attribués, sauf dans le cas où les quotas ont été volontairement réduits a posteriori en dessous des volumes actuellement utilisés.

#### Consommation de calcul

Ces coûts de _calcul_ correspondent directement à l'activité d'une session d'un compte, et de la façon dont il se sert de l'application. Le coût de calcul est la somme de 4 facteurs, chacun ayant son propre tarif:
- **(nl) nombre de _lectures_** (en base de données): nombre de notes lues, de chats lus, de contacts lus, de membres de groupes lus, etc. **Lu** signifie _extrait de la base de données_: 
  - en utilisant un mode _synchronisé_ la très grande majorité des données étant déjà présentes sur l'appareil du titulaire du compte, les _lectures_ se résument à celles des données ayant changé ou ayant été créés depuis la fin de la session précédente. 
  - pour un même service apparent, le coût des _lectures_ peut varier, par exemple par rafraîchissement systématique des cartes de visite, ou en gardant un chat en ligne au lieu de raccrocher ...
  - en mode _avion_ le nombre de lectures est par principe nul.
- **(ne) nombre _d'écritures_** (en base de données): outre quelques écritures de gestion du compte, elles correspondent principalement aux _mises à jour des notes, chats, cartes de visite, commentaires personnels, gestion d'un groupe_.
- **(vd) volume _descendant_** (download) de fichiers téléchargés depuis le _Storage_. Chaque acte est explicitement demandé par le titulaire du compte: 
  - quand il utilise une _copie locale_ d'un fichier sur son appareil en mode _synchronisé_, le volume téléchargé est nul, sauf si le fichier a changé. 
  - il est possible de télécharger sur son appareil toutes les notes d'une sélection faite à l'écran (et potentiellement toutes celles accessibles par le compte): en mode _synchronisé_ ça ne coûte rien, SAUF s'il a été demandé de télécharger aussi les fichiers leur étant attachés ce qui occasionne un coût de volume descendant qui peut être très important.
- **(vm) volume _montant_** (upload) de fichiers envoyés dans le _Storage_. Chaque création / mise à jour d'un fichier est décompté dans ce volume montant.

_L'ordre de grandeur_ des prix de marché donne les coûts unitaires suivants en euros:

    1 million de lectures               -> 0,80€  (pour un compte 0,02€ ... 1,0€ / an)
    1 million d'écritures               -> 2,00€  (pour un compte 0,03€ ... 0,2€ / an)
    Transfert d'un GB avec le Stockage  -> 0,15€  (pour un compte 0,02€ ... 0,8€ / an)

> Les estimations d'un coût annuel pour un compte sont arbitraires car très dépendantes de l'usage de chacun et en particulier de la fréquence des sessions.

### Coût total
C'est la somme des coûts induits par chacun des 6 compteurs valorisés par leur coût unitaire: `q1*u1 + q2*u2 + nl*cl + ne*ce + vd*cd + vm*cm`
- `q1` = _quota_ maximal de la somme des nombres de notes (`nn`), de chats (_nc_) et de participations aux groupes (`ng`).
- les coûts d'abonnement (quotas q1 / q2) sont calculés au prorata du temps d'existence du compte dans le mois et de la durée elle-même du mois.

Un compte peut consulter à tout instant, en particulier:
- le détail des coûts _exacts_ cumulés pour le mois en cours et les 3 précédents,
- les nombres _moyens_ de notes / chats / groupes, _effectivement utilisés_ le mois en cours et les 3 précédents.
- le volume _moyen_ des fichiers _effectivement stockés_ le mois en cours et les 3 précédents.
- sa moyenne journalière de _consommation_ estimée sur le mois en cours et les 3 précédents.

>_L'ordre de grandeur_ d'un coût total par compte varie en gros de **0,5€ à 3€ par an**. Individuellement ça paraît faible. Ce n'est plus du tout négligeable pour une organisation assurant les frais d'hébergement pour un millier de comptes ...

#### Solde monétaire d'un compte
Chaque compte a un _solde_ qui résulte,
- **en crédit :** 
  - soit de ce qu'il a versé ou fait verser monétairement au comptable de l'organisation,
  - soit de ce que lui a crédité automatiquement l'organisation chaque seconde quand celle-ci prend en charge le coût de fonctionnement du compte.
- **en débit :** les coûts de calcul de chaque opération, PLUS, le coût d'abonnement sur chaque seconde.

**A chaque instant le compte peut consulter son solde** : les variations peuvent être infimes d'une heure à l'autre.

## Le Comptable, les comptes _A_ et _O_

### Le compte du "Comptable"
_Le Comptable_ désigne une personne plus ou moins virtuelle, voire un petit groupe de personnes physiques qui:
- a négocié avec un hébergeur représenté par le terme _administrateur technique_ les conditions et le prix de l'hébergement.
- est en charge de contrôler le mode de création des comptes et le cas échéant l'attribution de _forfaits_ gratuits pour certains comptes.

Le compte **Comptable** ne peut pas être supprimé, a un numéro fixe reconnaissable, a pour nom d'avatar principal `Comptable`, n'a pas de carte de visite mais est connu de tous les comptes.

C'est un compte _presque_ normal en ce sens qu'il peut avoir des notes, des chats, participer à des groupes, créer des avatars secondaires, etc. **Il a le privilège important de gérer les quotas gratuits**.

A l'installation de l'hébergement d'une organisation, l'administrateur technique s'est concerté avec le Comptable de cette organisation qui lui a donné une _phrase secrète provisoire_. Le compte du **Comptable** est créé: ce dernier se connecte et change la phrase secrète pour une nouvelle, qui, elle, sera inconnue de l'administrateur technique.

> Le **Comptable** n'a pas plus que les autres comptes les moyens cryptographiques de s'immiscer dans les notes des avatars des comptes et leurs chats: ce n'est en aucune façon un modérateur et il n'a aucun moyen d'accéder aux contenus, pas plus qu'à l'identité des avatars secondaires des comptes.

### Compte _autonome_ "A"
Un compte _autonome_ **fixe lui-même ses quotas Q1 et Q2** et peut les changer à son gré, mais pas en-dessous des volumes qu'il occupe effectivement. 
- En cas de dépassement ponctuel de Q1 / Q2 par les volumes réels, le compte est _restreint_, les opérations augmentant le volume étant bloquées.

> **Nul ne peut bloquer / résilier un compte _autonome_**, mais le compte peut se bloquer lui-même s'il ne couvre pas les frais d'utilisation de son compte

> Un compte A gère ses crédits et comment il en ajoute. Le principe est qu'un compte A est _bloqué_ si la somme de ses crédits depuis sa création est inférieure à la somme des coûts d'abonnement et de consommation comptabilisés depuis sa création.

#### Gestion des crédits
Les crédits sont exprimés en _unité monétaire_ (signe €).

L'enregistrement `credit` de son compte est **crypté par la clé du compte**: lui-seul peut y accéder. Il comporte deux propriétés:
- `total` : total de tous les crédits _reçus_ depuis la création du compte.
- `tickets` : liste des _tickets_ des ligne de crédits _en attente_ de réception et d'enregistrement par le Comptable.

**Opérations de crédit:**
- (I) **le titulaire du compte génère un _ticket_** qui est stocké dans la liste de ses _tickets en attente_ dans son enregistrement credits (donc crypté).
- (II) il le cite en référence d'un _paiement_ qu'il effectue lui-même, soit le communique à un tiers qui effectue le _paiement_ en citant le ticket.
- (III) le Comptable reçoit un _paiement_, typiquement un virement d'une banque, mais aussi tout autre procédé accepté par l'organisation. Il enregistre le ticket cité en référence du paiement avec son montant, la date de réception et un commentaire facultatif.
- (IV) le compte se connecte, ou appui sur un bouton ad hoc dans sa session et ceci récupère tous les tickets en attente dans tickets et enregistrés par le Comptable. 
  - dans son enregistrement credit le total est incrémenté et la liste des tickets en attente réduite des tickets reçus.
  - dans la liste des tickets enregistrés par le Comptable, le ticket est effacé (sauf si le Comptable y a laissé un commentaire qu'il pourra d'ailleurs mettre à jour et / ou supprimer).

> Les _tickets_ étant enregistré crypté par la clé des comptes, aucune corrélation ne peut être faite entre la source d'un _paiement_ et le compte qui en bénéficie.

> Au sponsoring d'un compte, le sponsor inscrit un faible montant _cadeau_ qui permet au compte de se connecter et de disposer d'un délai pour alimenter son credit avec une somme réaliste. 

#### Solde crédits - coûts _négatif_: accès _minimal 
A la connexion d'un compte, mais ensuite en session, un _solde_ est calculé : total de son crédit MOINS total de ses coûts d'abonnement et de consommation. 

S'il est négatif, l'accès du compte à l'application est  **minimal** (voir le détail ci-après): en gros il ne peut plus que gérer son crédit, en consulter l'état de consommation et chatter avec le Comptable (mais ne peut ni consulter ses données, ni les modifier).

> Avant de devenir _négatif_ le solde d'un compte a été _faiblement positif_. Le compte en est averti lors de sa connexion avec le nombre de jours _estimé_ avant de devenir négatif si son profil de consommation reste voisin de celui des mois antérieurs.

> A sa création par _sponsoring_ un compte A peut être déclaré _sponsor_ lui-même, c'est à dire avoir le droit de sponsoriser lui-même de nouveaux comptes A.

### Compte _d'organisation_ "O"
**Un compte _d'organisation_ bénéficie _gratuitement_**:
- _d'un _abonnement_ c'est à dire de quotas Q1 / Q2 de notes / chats et de volume de fichiers.
  - En cas de dépassement ponctuel de Q1 / Q2 par les volumes réels, le compte est _restreint_, les opérations augmentant le volume étant bloquées.
- _d'un quota de consommation_ renouvelée à chaque instant et destiné à couvrir les coûts de _lectures / écritures de notes, chats, etc._ et de _transfert_ de fichiers.
  - si la consommation sur le mois courant et le mois antérieur dépasse le quota de consommation sur cette période, le compte est mis en accès **minimal**: il ne peut plus que consulter l'état de sa consommation et chatter avec le Comptable ou ses sponsors (mais ne peut ni consulter ses données, ni les modifier).

> Avant que la consommation dépasse son quota, elle _s'en approche_: le compte en est averti.

> **Un compte O peut être bloqué par l'organisation**, en n'ayant plus qu'un accès _en lecture seulement_, voire un accès _minimal_ (consultation de sa consommation et chats avec l'organisation).

> **Une organisation peut avoir de multiples raisons pour bloquer un compte**: départ de l'organisation, décès, adhésion à une organisation concurrente ou ayant des buts opposés, etc. selon la charte de l'organisation.

Le Comptable est le premier compte O et ne peut, ni être bloqué, ni devenir _autonome_: bref il est garanti toujours vivant.

### Gestion des quotas par _tranche_
Le Comptable dispose de quotas globaux Q1 / Q2 et d'un _quota de consommation_ global pour l'ensemble des comptes _O_. 

**Il découpe ces quotas en _tranches_** et est en charge d'en ajuster la répartition au fil du temps.

Tout compte O _d'organisation_ est créé dépendant d'une tranche de laquelle ses quotas ont été prélevés.

#### Sponsor d'une tranche
Le Comptable peut attribuer / enlever le rôle de **_sponsor de sa tranche_** à un compte O:
- un _sponsor_ peut sponsoriser un nouveau compte en lui attribuant des quotas prélevés sur la tranche qu'il gère: il peut aussi déclarer à ce moment le nouveau compte lui-même _sponsor_ de cette tranche.
- un `sponsor` peut augmenter / réduire les quotas des comptes liés à la tranche qu'il gère.
- le Comptable peut déclarer plus d'un compte _sponsor_ pour une tranche donnée.
- le Comptable peut aussi passer un compte _d'organisation_ d'une tranche à une autre.

> La gestion des quotas des comptes 0 _d'organisation_ s'effectue à deux niveaux en déléguant la maîtrise fine de ceux-ci aux sponsors de chaque tranche.

**Quelques règles :**
- un compte _non sponsor_ de sa tranche en connaît les sponsors, leurs carte de visite, et peut chatter avec eux (et avec le Comptable).
- un compte _sponsor_ de sa tranche :
  - connaît tous les autres comptes dont les quotas sont imputés à sa tranche, mais n'en connaît la _carte de visite_ que si son avatar principal est un de ses _contacts_ (il l'a sponsorisé, a ouvert un chat avec lui, ou participe à un même groupe). Sinon il n'en connaît que le numéro.
  - peut en lire les compteurs d'abonnement et de consommation.
- aucun compte, pas même le Comptable, ne peut connaître les avatars secondaires des comptes et n'a aucun moyen d'accéder à leurs notes et chats.

Le Comptable dispose de la liste des tranches (puisqu'il les as créées) et pour chacune dispose des mêmes possibilités qu'un sponsor de la tranche.

### Compte A ou O ?
**A sa création une organisation **n'accepte pas** de comptes _autonomes_. 
- Le Comptable peut lever cette interdiction et en autoriser la création,
  - soit réservé à lui-même,
  - soit la déléguer aux sponsors.
  - spécifie s'il faut l'accord d'un compte O pour le rendre _autonome_ ou si la décision peut s'imposer à lui.
- Il peut aussi supprimer cette autorisation: cela n'a aucun effet sur les comptes _autonomes_ existants et ne vaut que pour les créations ultérieures.

> Il faut TOUJOURS l'accord explicite d'un compte A pour le rendre O: un compte A peut parfaitement refuser le risque de se faire bloquer par l'organisation et continuer à payer ses coûts d'hébergement.

> L'accord explicite d'un compte O pour être rendu A n'est requis que si c'est spécifié dans la configuration de l'espace par le Comptable. L'organisation peut, si sa charte le lui permet, ne plus supporter les coûts d'un compte sans son accord en sachant qu'après cela elle ne peut plus le _bloquer_.

> Si un compte A paie lui-même son activité, en contre-partie il ne peut pas être bloqué par l'organisation: ceci dépend vraiment du profil de chaque organisation.

Le Comptable peut obtenir un état statistique des comptes A, mais:
- cet état est _anonyme_, seuls les numéros des comptes apparaissent,
- cet état reprend les compteurs d'abonnement et de consommation **mais pas les crédits**.

## Notifications et restrictions d'usage des comptes
Une _notification_ est un message important dont la présence est signalée par une icône dans la barre d'entête de l'écran, parfois par l'affichage lors de la connexion d'un compte, voire d'une _pop up_ en cours de session quand elle est liée à une restriction d'accès du compte.

Une _notification_ peut être porteuse d'une restriction d'accès: les actions du compte ne sont plus totalement libres, voire sévèrement limitées.

### Notification de l'administrateur technique: espace _figé_ et _clos_
L'administrateur peut émettre une notification, le cas échéant porteuse d'une restriction déclarant un espace _figé_ ou _clos_:
- le texte, soit est simplement informatif, soit explicite les raisons de la restriction.
- **espace figé** : l'espace est en lecture seule, sans mise à jour possible. Toutefois, 
  - l'enregistrement des consommations (lectures / écritures / transferts de fichiers) continue afin de maintenir un contrôle des _consommations_.
  - la gestion des crédits (génération de tickets de paiement pour les comptes A et l'enregistrement des paiements) reste ouverte.
- **espace clos** : il n'y a plus de données, du moins accessibles par les comptes. Le texte indique à quelle URL / code d'organisation les comptes vont trouver l'espace transféré (s'il y en a un).

L'administrateur technique a ainsi les moyens:
- de figer temporairement un espace, par exemple:
  - pendant la durée technique nécessaire à son transfert chez un autre hébergeur,
  - en le laissant en ligne et permettant aux comptes de consulter une image archivée pendant que l'opération technique se poursuit.
- de clôturer un espace en laissant une explication, voire une solution, aux comptes (où l'espace a-t-il été transféré).

### Notification pour les comptes O: accès _lecture seule_ et _minimal_ 
Ces notifications peuvent être émises par le Comptable et des sponsors. Ce peut être une simple information ponctuelle et ciblée plus ou moins large, ne soumettant pas les comptes à des restrictions d'accès.

Ces notifications peuvent avoir deux portées:
- _tous_ les comptes O d'une tranche,
- _un_ compte O spécifique.

**Restriction d'accès en _lecture seulement_**
- les données ne peuvent être que lues, pas mises à jour, avec les exceptions suivantes:
  - les chats sont possibles avec le Comptable et les sponsors,
  - les opérations de crédit / gestion des quotas pour un compte A restent autorisées.

**Restriction d'accès _minimal_**
- les données ne peuvent ni être lues, ni être écrites avec les exceptions suivantes:
  - les chats sont possibles avec le Comptable et les sponsors,
  - les opérations de crédit / gestion des quotas pour un compte A restent autorisées.
  - **les connexions du compte ne le maintiennent plus en vie**: au plus tard dans un an, si cette restriction n'est pas levée, le compte disparaîtra.

### Notification automatique par surveillance de la consommation
- pour un compte A: solde (crédits - coûts).
- pour un compte O: comparaison entre `consoj` la _consommation journalière_ moyenne sur le mois en cours et le précédent, et le quota de consommation `qcj` (ramené à la journée).

**Notification sans restriction d'accès quand,** 
- **compte A) le solde est _faiblement positif_**: le nombre de jours ou le solde devrait rester positif en cas de poursuite de la tendance récente de consommation est inférieur à un seuil d'alerte (60 jours).
- **compte O) la consommation journalière moyenne est _importante_**, dépasse 80% du quota de consommation.

Pas de restrictions d'accès, mais une pop-up à la connexion et une icône _d'attention_ en barre d'entête.

**Notification avec accès _minimal_ quand,**
- **compte A) le solde est _négatif_**, 
- **compte O) la consommation journalière moyenne est _excessive_**, dépasse 100% du quota de consommation.

**Les connexions du compte ne le maintiennent plus en vie**: au plus tard dans un an, si cette restriction n'est pas levée, le compte disparaîtra.

Une pop-up apparaît à la connexion et une icône _d'alerte_ figure en barre d'entête.

### Notification automatique par surveillance des dépassements des quotas Q1 et Q2
Cette notification s'applique aux comptes O et A.

**Notification sans restriction d'accès quand les quotas Q1 / Q2 sont _approchés_**
- Le nombre de notes et chats effectivement existantes est à moins de 10% du quota Q1.
- Le volume des fichiers existant effectivement est à moins de 10% du quota Q2.
- pas de restrictions d'accès, mais une pop-up à la connexion et une icône _d'attention_ en barre d'entête.

**Notification avec restriction aux opérations _décroissantes_ quand les quotas sont dépassée**
- Les opérations _diminuant_ le nombre de notes, chats, participation aux groupes sont libres.
- Les opérations _augmentant_ le volume des fichiers (création / mise à jour en extension) sont bloquées.

### Synthèse des restrictions d'accès
- F : _espace figé_ : par l'administrateur technique
- L : _lecture seulement_ : pour les seuls comptes O, par le Comptable ou un sponsor
- M : _minimal_ :
  - pour les seuls comptes O, par le Comptable ou un sponsor,
  - pour tous les comptes, du fait d'un solde négatif,
- D : _décroissant_ par dépassement des quotas

    F L M D
    O O O O   gestion du solde
    N O O O   chats avec le Comptable et les sponsors
    O O N O   lecture des données
    N N N -   mises à jour
          O     - n'augmentant pas les volumes
          N     - augmentant les volumes

Source des notifications pour un compte:
- une de l'administrateur technique
- une par tranche du Comptable ou d'un des sponsors de la tranche
- une par compte du Comptable ou d'un des sponsors de la tranche
- une de surveillance du niveau du solde
- une de surveillance de non dépassement des quotas

> Le compte le plus _notifié_ peut avoir jusqu'à 5 notifications à un instant donné, l'amenant au pire à cumuler plusieurs restrictions.