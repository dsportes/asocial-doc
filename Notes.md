
# Secrets
Un secret a toujours un **texte** et possiblement des **fichiers** attachés.

Sauf condition particulière, les secrets peuvent être créés, mis à jour et supprimés.

Il est possible d'attacher des _mots clés_ à un secret : le filtrage à l'affichage des secrets peut se faire par sélection de mots clés selon leurs sujets (thème abordé ...), leurs états (_favori, obsolète, important, à lire_ etc.). Le filtrage peut être affiné selon la présence d'une portion de texte (mot ...) dans le texte.

#### Texte d'un secret
Le texte a une longueur maximale de 5000 caractères. Bien que lisible sous sa forme brute textuelle, il peut aussi être lu plus confortablement grâce à quelques éléments de décoration (_titres, gras, italique, listes ..._) selon la syntaxe MD.

#### Fichiers attachés à un secret
Pour chaque fichier il est enregistré :
- son numéro identifiant aléatoire.
- son **nom** : comme un _nom de fichier_, d'où un certain nombre de caractères _interdits_ dont le `/`. Plusieurs fichiers attachés à un même secret peuvent porter le même nom, ce sont des _versions_ pour un nom donné.
- son **a propos**, texte facultatif d'au plus 250 caractères utile en particulier pour expliciter le nom, donner un _titre_ ou un commentaire qualifiant une _version_ lorsqu'il existe plusieurs fichiers de même nom.
- sa **date-heure d'enregistrement** dans l'application (pas celles de création ou de dernière modification de son fichier d'origine).
- son **type MIME** permettant de savoir si c'est une photo, un clip vidéo, un PDF ... Beaucoup de types de fichiers s'affichent directement dans les navigateurs.
- sa **taille** originale en octets.
- le **digest SHA-256** de son texte d'origine, permettant de s'assurer si nécessaire de sa non déformation entre sa source primitive et ses restitutions.

**Les fichiers sont stockés dans un espace dédié sur un serveur de fichiers**, ils sont compressés si c'est un fichier de type `text/...`, puis cryptés dans l'application avant d'être envoyés sur le réseau, et décryptés dans l'application après téléchargement depuis le serveur de fichier.

>On ne peut **qu'ajouter ou supprimer** des fichiers. Quand on ajoute un fichier, il est proposé de supprimer simultanément un ou plusieurs autres fichiers de même nom : ceci donne l'impression d'une mise à jour qui permettrait de plus d'en gérer les _versions_ tout en évitant l'inflation du volume.

## Secrets personnels, partagés avec un contact, partagés dans un groupe

#### Secret personnel d'un avatar d'un compte
Seul le titulaire du compte le connaît et peut le lire et le mettre à jour. Il est crypté par la clé K du compte.

Les mots clés associés au secret permettent au compte de rechercher / filtrer des secrets: ils sont pris dans ceux propres au compte et dans les quelques mots très neutres prédéfinis sur le réseau. Leur interprétation n'est possible que par le titulaire du compte.

>Absolument personne d'autre ne peut avoir connaissance de son contenu qui n'a à respecter aucune règle.

#### Secret partagé avec un contact entre deux avatars A et B
Si l'un des deux ne souhaite pas partager de secrets, leurs volumes ne lui seront pas défalqués de ses quotas et il ne pourra pas y accéder. S'il souhaite partager des secrets, il déclare des volumes maximum pour les secrets de ce contact afin de protéger ses propres quotas d'une inflation éventuelle provenant de son contact.

La clé de cryptage des secrets est la clé de cryptage du contact, créée par l'un et communiquée à l'autre lors de son acceptation du contact.

Chacun des deux avatars peut attacher ses propres mots clés à un secret, l'autre n'y a pas accès et ne peut pas les interpréter.

**La liste des auteurs d'un secret donne (A, B, A puis B, B puis A ) :** dans l'ordre de modification, le plus récent en tête.

#### Secret partagés dans un groupe
Seuls les membres actifs du groupe y ont accès et peuvent agir dessus : toute mise à jour d'un secret est visible par tous les membres du groupe.

La clé de cryptage des secrets est la clé de cryptage du groupe, créée à la création du groupe puis communiquée aux autres membres invités lors de l'acceptation de leur invitation au groupe.

Un animateur peut attacher des mots clés spécifiques du groupe à un secret.

Tout membre peut attacher de plus les siens propres.

Un membre peut en conséquence rechercher / filtrer ses secrets par les mots clés, soit qu'il a mis personnellement (et inconnus des autres membres), soit par ceux _du groupe_ attachés par un animateur : certains critères de recherche par mots clés peuvent être communs à tous les membres.

**La liste des auteurs d'un secret donne les derniers auteurs :**
- dans l'ordre de modification, le plus récent en tête,
- sans doublon.

>**Remarque :** si le **groupe** a été marqué _protégé contre l'écriture_ personne dans le groupe ne peut le modifier ni le supprimer, il faudrait qu'un animateur lève préalablement cette sécurité au niveau du groupe.

## Mise à jour d'un secret
Il n'est pas toujours pertinent qu'un secret puisse être mis à jour n'importe quand par n'importe qui, même y ayant droit.

#### Protection contre l'écriture
Un secret peut être marqué _protégé contre l'écriture_ afin de se prémunir d'une modification / suppression accidentelle.

#### Exclusivité pour un avatar
Un secret partagé avec un contact et un secret partagé dans un groupe, peuvent avoir un _propriétaire exclusif_ à un moment donné, un des deux contacts ou un membre du groupe, lui seul pouvant mettre à jour le secret tant qu'il en a l'exclusivité :
- possibilité d'éviter les écrasements mutuels de texte en cas de mises à jour multiples,
- possibilité pour un auteur de protéger son texte contre des interventions d'autres auteurs ...

Pour un secret personnel, l'exclusivité est par construction l'avatar lui-même.

Celui ayant l'exclusivité peut décider :
- de protéger le secret contre l'écriture (se l'interdire à lui-même),
- de lever cette protection (se l'autoriser à lui-même),
- de transférer l'exclusivité à un autre membre (pour un groupe) ou à l'autre (pour un contact),
- de supprimer l'exclusivité, le secret pouvant alors être mis à jour / supprimé par n'importe qui dans le groupe ou le contact.

**Un animateur de groupe a ces mêmes droits pour un secret partagé dans un groupe.**

## Secret _temporaire_
Un secret peut être déclaré temporaire : il s'efface automatiquement au bout de quelques semaines, sauf s'il a de nouveau été rendu **permanent**.

Les secrets temporaires sont utiles pour créer un _débat_ et construire une décision collective, sans devoir pour autant penser à supprimer les échanges constructifs intermédaires, questions / réponses, etc.

## Secrets _voisins_
Au début il y a un secret A, banal.

Puis quelqu'un crée un autre secret B en le déclarant _voisin_ de A.

Quelqu'un encore peut créer un secret C _voisin_ de A : s'il l'avait déclaré voisin de B, en fait il aurait été noté voisin de A quand-même (B ayant A pour voisin).

C'est à la création qu'on peut déclarer qu'un secret est _voisin_ d'un autre et ça ne peut plus changer au cours du temps: 

L'intérêt est que si quelqu'un consulte C par exemple, il pourra avoir sous les yeux la liste de ses voisins, A et B en l'occurrence.

Ceci permet de créer des sortes de _bulles_ de secrets autour d'un secret initial et traitant tous de la même chose. 
- si A est un secret d'un groupe par exemple, rien n'empêche de créer des secrets D E F personnels voisins de A. De même pour un secret partagé avec un contact.
- quand il est dit qu'on voit la liste de tous ses voisins quand on affiche un secret, c'est à nuancer : on ne voit que les secrets qu'on a le droit de voir.
- si le secret A est supprimé, ça ne change rien pour les autres qui restent voisins de A ... mais on ne peut plus voir A.

## Téléchargement d'une sélection de secrets

Une opération de téléchargement permet d'écrire en clair sur un disque local une sélection de secrets, **leurs textes et leurs fichiers**. Ceci requiert,
- un PC Linux ou Windows,
- le téléchargement et l'installation d'un petit utilitaire à lancer avant le d'effectuer le téléchargement et à arrêter ensuite par sécurité. En effet un navigateur n'a pas le droit d'écrire sur l'espace de fichiers de l'appareil, ce que l'utilitaire peut faire.

>Les téléchargements peuvent être coûteux en transfert sur le réseau et les hébergeurs du serveur de fichiers peuvent les facturer et / ou les limiter. Ils sont **ralentis** par des temporisations dès que la moyenne des volumes téléchargés sur les 14 derniers jours dépasse le quota V2 d'un compte (d'autant plus que le dépassement est important).

## Accès aux fichiers en mode _avion_
Tout fichier attaché à un secret peut être, a) soit affiché directement dans le navigateur si ce dernier sait le faire pour son type, b) soit être téléchargé dans l'espace prévu (en général le répertoire `Téléchargement`). 

Le fichier est demandé directement au serveur de fichiers dédié (sans passer par le serveur central gérant la base de données), ce qui suppose un accès à Internet opérationnel.

En raison de leurs volumes les fichiers attachés aux secrets ne sont pas mémorisés dans les micro bases locales des sessions : ils ne sont donc lisibles qu'en mode _synchronisé_ ou _incognito_ mais pas en mode _avion_.

Toutefois, pour chaque appareil distinctement, le titulaire d'un compte peut **cocher** des fichiers pour accéder à leur contenu en mode _avion_ :
- ceci est à faire fichier par fichier sur chaque appareil souhaité : tous n'ont pas forcément les mêmes fichiers cochés pour accès en mode _avion_.
- un fichier ainsi coché peut aussi être déclaré à maintenir synchronisé **avec le dernier fichier attaché de même nom**, bref en avoir toujours la dernière _version_.
- on peut décocher un fichier coché, il ne sera plus mémorisé localement.
- si le secret disparaît, les fichiers correspondants sont aussi supprimées localement.

Les fichiers ainsi désignés sont stockés localement à l'occasion d'une session synchronisée : ils sont maintenus à niveau à chaque connexion (début de session) puis pendant que la session est active. On ne retrouve sur un appareil en mode _avion_ que ceux qui étaient désignés lors de la dernière session synchronisée.

> Un excès de fichiers accessibles en mode _avion_ peut entraîner le blocage de sessions, le stockage local tombant en erreur.

## Restrictions liées aux quotas de volume
On suppose ici qu'on n'est pas en mode _avion_ et qu'il n'y a pas de procédure de blocage pesant sur le compte ou sa tribu et interdisant toute mise à jour.

>Une mise à jour en **extension** est une mise à jour d'un texte plus volumineux que le texte précédent ou l'ajout d'un fichier d'un volume supérieur à ceux des fichiers supprimés corrélativement.

#### Les créations et mise à jour en extension sont bloquées dans les cas suivants
- une procédure de blocage en cours sur le compte ou sa tribu l'interdit pour tous les secrets.
- pour un secret personnel **si les quotas de l'avatar** sont **inférieurs** aux volumes V1 / V2 déjà occupés. Les quotas ont été volontairement abaissés a posteriori.
- pour un secret partagé sur un contact,
  - si les quotas de l'un des deux avatars en contact sont **inférieurs** aux volumes V1 / V2 déjà occupés.
  - si les maximum autorisés pour les secrets du contact par l'un des deux avatars en contact sont **inférieurs** aux volumes V1 / V2 déjà occupés.
- pour un secret partagé dans un groupe,
  - si les quotas de l'avatar **hébergeur** du groupe sont **inférieurs** aux volumes V1 / V2 déjà occupés.
  - si les maximum autorisés par l'hébergeur pour les secrets du groupe sont **inférieurs** aux volumes V1 / V2 déjà occupés.

**Rappel :** quand tous ces maximum et quotas sont **supérieurs** aux volumes occupés actuellement, a priori les créations et mise à jour en extension sont possibles, **pour autant** que les volumes résultant restent inférieurs aux quotas et maximum spécifiés.
