# Répartition des coûts d'hébergement de l'application

Le coût d'usage de l'application pour une organisation correspond aux coûts d'hébergement des données et de traitement de celles-ci. Selon les techniques et les prestataires choisis, les coûts unitaires varient mais existent dans tous les cas.

Ci-dessous on considère le coût mensuel pour un compte.

#### Abonnement
Il correspond aux coûts récurrents mensuels pour un compte même quand il ne se connecte pas. Par simplification ils ont été résumés ainsi:
- **(V1) Volume des données sur la base de données**. Il est calculé par la multiplication d'un facteur forfaitaire par le nombre de,
  - **(nn) notes** personnelles et notes d'un groupe hébergé par le compte,
  - **(nc) chats** en ligne, 
  - **(ng) participations aux groupes**.
- **(V2) Volume des fichiers attachés aux notes** stockés sur un _Storage_.

Pour obtenir le coût correspondant à ces deux volumes il est pris en compte, non pas _le volume effectivement utilisé à chaque instant_ mais **les _quotas_ Q1 et Q2** choisis par le compte, c'est à dire **l'espace maximal** auquel il s'abonne et qui a été réservé à cet effet.

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
- **(nl) nombre de _lectures_** (en base de données): nombre de notes lues, de chats lus, de contacts lus, de membres de groupes lus, etc. **Lu** signifie _extrait de la base de données_: en utilisant un mode _synchronisé_ la très grande majorité des données étant déjà présentes sur l'appareil du titulaire du compte, les _lectures_ se résument à celles des données ayant changé ou ayant été créés depuis la fin de la session précédente. Pour un même service apparent, le coût des _lectures_ peut différer fortement. En mode _avion_ le nombre de lectures est par principe même nul.
- **(ne) nombre _d'écritures_** (en base de données): outre quelques écritures techniques indispensables, il s'agit principalement des mises à jour des données, notes, chats, cartes de visite, commentaires personnels, etc.
- **(vd) volume _descendant_** (download) de fichiers téléchargés depuis le _Storage_. Chaque acte est explicitement demandé par le titulaire du compte: quand il utilise une _copie locale_ d'un fichier sur son appareil en mode _synchronisé_, le volume téléchargé est nul, sauf si le fichier a changé. De même il est possible de télécharger sur son appareil toutes les notes d'une sélection faite à l'écran (et potentiellement toutes celles accessibles par le compte): en mode _synchronisé_ ça ne coûte rien, SAUF s'il a été demandé de télécharger aussi les fichiers leur étant attachés: dans ce cas le volume téléchargé peut être très important.
- **(vm) volume _montant_** (upload) de fichiers envoyés dans le _Storage_. Chaque création / mise à jour d'un fichier est décompté dans ce volume.

_L'ordre de grandeur_ des prix de marché donne les coûts unitaires suivants en euros:

    1 million de lectures               -> 0,80€  (pour un compte 0,02€ ... 1,0€ / an)
    1 million d'écritures               -> 2,00€  (pour un compte 0,03€ ... 0,2€ / an)
    Transfert d'un GB avec le Stockage  -> 0,15€  (pour un compte 0,02€ ... 0,8€ / an)

> Les estimations d'un coût annuel pour un compte sont arbitraires car très dépendantes d'un type d'usage que chacun peut avoir et en particulier de la fréquence des sessions.

### Coût total
C'est la somme des coûts induits par chacun des 6 compteurs valorisés par leur coût unitaire: `q1*u1 + q2*u2 + nl*cl + ne*ce + vd*cd + vm*cm`
- `q1` = _quota_ maximal de la somme `nn + nc + ng`

Un compte peut consulter à tout instant:
- le détail des coûts _exacts_ cumulés pour le mois en cours et les 11 précédents,
- les nombres _moyens_ de notes / chats / groupes, _effectivement utilisés_ le mois en cours et les 11 précédents.
- le volume _moyen_ des fichiers _effectivement stockés_ le mois en cours et les 11 précédents.

>_L'ordre de grandeur_ d'un coût total par compte varie en gros de **0,5€ à 3€ par an**. Individuellement ça paraît faible. Ce n'est plus du tout négligeable pour une organisation assurant les frais d'hébergement pour un millier de comptes, soit à financer par sponsoring ou par quote-part sur les adhésions ...

#### Solde monétaire d'un compte
Chaque compte a un _solde_ qui résulte,
- **en crédit :** 
  - soit de ce qu'il a versé ou fait verser monétairement au comptable de l'organisation,
  - soit de ce que lui a crédité automatiquement l'organisation chaque seconde quand celle-ci prend en charge le coût de fonctionnement du compte.
- **en débit :** les coûts de consommation à chaque consommation effective à chaque opération, PLUS, le coût d'abonnement sur chaque seconde.

**A chaque instant le compte peut consulter son solde** : les variations peuvent être infimes d'une heure à l'autre.

## Le Comptable, les comptes _A_ et _O_

### Le compte du "Comptable"
_Le Comptable_ désigne une personne plus ou moins virtuelle, voire un petit groupe de personnes physiques qui:
- a négocié avec un hébergeur représenté par le terme _administrateur technique_ les conditions et le prix de l'hébergement.
- est en charge de contrôler le mode de création des comptes et le cas échéant l'attribution de _forfaits_ gratuits pour certains comptes.

Le compte **Comptable** ne peut pas être supprimé, a un numéro fixe reconnaissable, a pour nom d'avatar principal `Comptable`, n'a pas de carte de visite mais est connu de tous les comptes.

C'est un compte _presque_ normal en ce sens qu'il peut avoir des notes, des chats, participer à des groupes, créer des avatars secondaires, etc. **Il a le privilège important de gérer les quotas / forfaits gratuits**.

A l'installation de l'hébergement d'une organisation, l'administrateur technique s'est concerté avec le Comptable de cette organisation qui lui a donné une _phrase secrète provisoire_. Le compte du **Comptable** est créé: ce dernier se connecte et change la phrase secrète pour une nouvelle, qui, elle, sera inconnue de l'administrateur technique.

> Le **Comptable** n'a pas plus que les autres comptes les moyens cryptographiques de s'immiscer dans les notes des avatars des comptes et leurs chats: ce n'est en aucune façon un modérateur et il n'a aucun moyen d'accéder aux contenus, pas plus qu'à l'identité des avatars secondaires des comptes.

### Compte _autonome_ "A"
Un compte _autonome_ fixe lui-même ses quotas Q1 et Q2 et peut les changer à son gré, mais pas en-dessous des volumes qu'il occupe effectivement.

> **Nul ne peut bloquer / dissoudre un compte _autonome_**, mais le compte peut se bloquer lui-même s'il ne couvre pas les frais d'utilisation de son compte

**Il gère son solde en _unité monétaire_**, par exemple en euros:
- **le solde est crypté par la clé du compte**: lui-seul le connaît.
- **le solde est débité à chaque instant** des coûts _d'abonnement_ liés aux quotas qu'il a fixé et des coûts de _consommation_, lectures / écritures / transferts faits.
- **le solde est crédité de manière _anonyme_:**
  - le titulaire du compte génère un _ticket_ (stocké crypté dans le compte) et, soit le cite en référence d'un _paiement_ qu'il effectue lui-même, soit le communique à un bienfaiteur qui effectue le _paiement_ en citant le ticket dont on ne peut pas savoir qui l'a généré et donc au profit de qui le paiement est effectué.
  - quand le Comptable reçoit un _paiement_ (typiquement un virement d'une banque, mais aussi tout autre procédé accepté par l'organisation), il enregistre le ticket cité en référence et le montant. Le solde du compte en est crédité automatiquement à la prochaine connexion.
  - le _ticket_ étant enregistré crypté par la clé du compte, aucune corrélation ne peut être faite entre la source d'un _paiement_ et le compte qui en bénéficie.
- **le solde peut aussi être crédité par un don, anonyme, d'un autre compte**, ce qui débite le sien d'autant, et **par des _dons_ du Comptable** (une _subvention ponctuelle_ de l'organisation). 

Quand à la connexion d'un compte son solde est négatif, l'accès du compte à l'application est  **minimal** (voir le détail ci-après): en gros il ne peut plus que gérer son compte, en consulter l'état de consommation et chatter avec le Comptable (mais ne peut ni consulter ses données, ni les modifier).

> Avant de devenir _négatif_ le solde d'un compte a été _faiblement positif_. Le compte en est averti lors de sa connexion avec le nombre de jours _estimé_ avant de devenir négatif si son profil de consommation reste voisin de celui des 2 mois antérieurs.

A sa création par _sponsoring_ un compte A peut être déclaré _sponsor_ lui-même, c'est à dire avoir le droit de sponsoriser lui-même de nouveaux comptes A.

### Compte _d'organisation_ "O"
**Un compte _d'organisation_ bénéficie _gratuitement_**:
- _d'un _abonnement_ c'est à dire de quotas de notes / chats et de volume de fichiers,
- _d'une dotation de fonctionnement_ renouvelée à chaque instant destinée à couvrir les coûts de _lectures / écritures de notes, chats, etc._ et de _transfert_ de fichiers.

> **Un compte O peut être bloqué par l'organisation**, en n'ayant plus qu'un accès _en lecture seulement_, voire un accès _minimal_ (gestion comptable et chats avec l'organisation).

> **Une organisation peut avoir de multiples raisons pour bloquer un compte**: départ de l'organisation, décès, adhésion à une organisation concurrente ou ayant des buts opposés, etc. selon la charte de l'organisation.

Le Comptable est le premier compte O et ne peut, ni être bloqué, ni devenir _autonome_: bref il est garanti toujours vivant.

### Gestion des quotas / dotations par _tranche_
Le Comptable dispose de quotas globaux Q1 / Q2 et d'une _dotation_ globale de consommation pour l'ensemble de l'organisation. 

**Il découpe ces quotas / dotations en _tranches_** et est en charge d'en ajuster la répartition au fil du temps.

Tout compte O _d'organisation_ est créé dépendant d'une tranche de laquelle ses quotas ont été prélevés et sa dotation attribuée.

#### Sponsor d'une tranche
Le Comptable peut attribuer / enlever le rôle de **_sponsor de sa tranche_** à un compte O:
- un _sponsor_ peut sponsoriser un nouveau compte en lui attribuant des quotas et une dotation prélevés sur la tranche qu'il gère: il peut aussi déclarer à ce moment le nouveau compte lui-même _sponsor_ de cette tranche.
- un `sponsor` peut augmenter / réduire les quotas et la dotation des comptes liés à la tranche qu'il gère.
- le Comptable peut déclarer plus d'un compte _sponsor_ pour une tranche donnée.
- le Comptable peut aussi passer un compte _d'organisation_ d'une tranche à une autre.

> La gestion des quotas et des dotations des comptes 0 _d'organisation_ s'effectue à deux niveaux en déléguant la maîtrise fine de ceux-ci aux sponsors de chaque tranche.

**Quelques règles :**
- un compte _non sponsor_ de sa tanche en connaît les sponsors, leurs carte de visite, et peut chatter avec eux (et avec le Comptable).
- un compte _sponsor_ de sa tranche :
  - connaît tous les autres comptes dont les quotas et dotation sont imputés à sa tranche, mais pas forcément leur _carte de visite_ (à la limite, il n'en connaît que le numéro).
  - peut en lire les compteurs d'abonnement et de consommation ainsi que le _solde_.
- aucun compte, pas même le Comptable, ne peut connaître les avatars secondaires des comptes et n'a aucun moyen d'accéder à leurs notes et chats.

Le Comptable dispose de la liste des tranches (puisqu'il les as créées) et pour chacune dispose des mêmes possibilités qu'un sponsor de la tranche.

### Compte A ou O ?
**A sa création une organisation **n'accepte pas** de comptes _autonomes_. 
- Le Comptable peut lever cette interdiction et en autoriser la création,
  - soit réservé à lui-même,
  - soit la déléguer aux sponsors.
- Il peut aussi supprimer cette autorisation: cela n'a aucun effet sur les comptes _autonomes_ existants et ne vaut que pour les créations ultérieures.

> Si un compte A paie lui-même son activité, en contre-partie il ne peut pas être bloqué par l'organisation: ceci dépend vraiment du profil de chaque organisation.

Le Comptable peut obtenir un état statistique des comptes A, mais:
- cet état est _anonyme_, seuls les numéros des comptes apparaissent,
- cet état reprend les compteurs d'abonnement et de consommation **mais pas les soldes**.

Le Comptable, et le cas échéant les sponsors, peut _sponsoriser_ un compte A (à sa demande), c'est à dire lui proposer de devenir compte O, d'être attaché à une tranche donnée et d'avoir des quotas et une dotation gratuite. Si le compte A accepte ce _sponsoring_,
- il devient compte O, ne paye plus son abonnement ni sa consommation,
- mais accepte de pouvoir être bloqué par l'organisation.

Le Comptable, et le cas échéant les sponsors, peut rendre _autonome_ un compte d'organisation qui,
- devra désormais payer son abonnement et sa consommation,
- mais ne pourra plus être bloqué par l'organisation.

## Notifications et restrictions d'usage des comptes
Une _notification_ est un message important dont la présence est signalée par une icône dans la barre d'entête de l'écran et parfois par l'affichage lors de la connexion d'un compte, voire d'une _pop up_ en cours de session quand elle est liée à une restriction d'accès du compte.

Une _notification_ peut être porteuse d'une restriction d'accès: les actions du compte ne sont plus totalement libres, voire sévèrement limitées.

### Notification de l'administrateur technique: accès _figés_ et _clos_
L'administrateur peut émettre une notification, le cas échéant porteuse d'une restriction déclarant un espace _figé_ ou _clos_:
- le texte informatif est soit simplement informatif, soit explicite les raisons de la restriction.
- **espace figé** : l'espace est en lecture seule, sans mise à jour possible. Toutefois, 
    - l'enregistrement des décomptes de lectures / écritures / transferts de fichiers continue afin de maintenir un contrôle des _consommations_.
    - la gestion des crédits (génération de tickets de paiement pour les comptes A et l'enregistrement des paiements) reste ouverte.
- **espace clos** : il n'y a plus de données, du moins accessibles par les comptes. Le texte indique à quelle URL / code d'organisation les comptes vont trouver l'espace transféré (s'il y en a un).

L'administrateur technique a ainsi les moyens:
- de figer temporairement un espace, par exemple:
  - pendant la durée technique nécessaire à son transfert sur un autre hébergeur,
  - en le laissant en ligne et permettant aux comptes de consulter une image archivée pendant que l'opération technique se poursuit.
- de clôturer un espace en laissant une explication, voire une solution, aux comptes (où l'espace a-t-il été transféré).

### Notification pour les comptes O: accès _lecture seule_ et _minimal_ 
Ces notifications peuvent être émise par le Comptable et des sponsors. Ce peut être une simple information ponctuelle et ciblée plus ou moins large, ne soumettant pas les comptes à des restrictions d'accès.

Ces notifications peuvent avoir deux portées:
- _tous_ les comptes O d'une tranche,
- _un_ compte O spécifique.

**Restriction d'accès en _lecture seulement_**
- les données ne peuvent être que lues, pas mises à jour, avec les exceptions suivantes:
  - les chats sont possibles avec le Comptable et les sponsors,
  - les opérations de gestion du solde restent autorisées.

**Restriction d'accès _minimal_**
- les données ne peuvent ni être lues, ni être écrites avec les exceptions suivantes:
  - les chats sont possibles avec le Comptable et les sponsors,
  - les opérations de gestion du solde restent autorisées.
  - les connexions du compte ne le maintiennent plus en vie: au plus tard dans un an, si cette restriction n'est pas levée, le compte disparaîtra.

### Notification automatique par surveillance du solde
Cette notification s'applique aux comptes O et A.

**Notification sans restriction d'accès quand le solde est _faiblement positif_**
- le nombre de jours ou le solde devrait rester positif en cas de poursuite de la tendance récente de consommation est inférieur à un seuil d'alerte (60 jours par exemple).
- pas de restrictions d'accès, mais une pop-up à la connexion et une icône _d'attention_ en barre d'entête.

**Notification avec accès _minimal_ quand le solde est _négatif_**
- les données ne peuvent ni être lues, ni être écrites avec les exceptions suivantes:
  - les chats sont possibles avec le Comptable (et les sponsors pour un compte O),
  - les opérations de gestion du solde restent autorisées.
  - les connexions du compte ne le maintiennent plus en vie: au plus tard dans un an, si cette restriction n'est pas levée, le compte disparaîtra.
- pop-up à la connexion et une icône _d'alerte_ en barre d'entête.

### Notification automatique par surveillance des dépassements des quotas
Cette notification s'applique aux comptes O et A.

**Notification sans restriction d'accès quand les quotas sont _approchés_**
- Le nombre de notes et chats effectivement existantes est à moins de 10% du quota Q1.
- Le volume des fichiers existant effectivement est à moins de 10% du quota Q2.
- pas de restrictions d'accès, mais une pop-up à la connexion et une icône _d'attention_ en barre d'entête.

**Notification avec restriction aux opérations _décroissantes_ quand les quotas sont dépassée**
- Les opérations _diminuant_ le nombre de notes, chats, participation aux groupes sont libres.
- Les opérations _augmentant_ le volume des fichiers (création / mise à jour en extension) sont bloquées.

### Synthèse des restrictions d'accès
- F : _figé_ : par l'administrateur technique
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
