@@Index général de la documentation [index](https://raw.githack.com/dsportes/asocial-doc/master/index.md)

# L'usage de la cryptographie dans a-social

Plusieurs principes ont été mis en œuvre:
- tous les textes humainement intelligibles et les images sont cryptées.
- toutes les clés de cryptage pour chaque compte sont cryptées par la clé majeure K du compte, elle-même cryptée par la phrase secrète du compte.
- aucune clé de cryptage n'est transmise au serveur.
- la quasi totalité des _meta-liens_ entre documents sont cryptés.

# Technologies de cryptage / hash employées
## Hash: SHA256
Ce hash d'une suite de bytes à une longueur de 32 bytes.

Il n'a pas été publié de cas où deux entrées différentes produisaient le même SHA256 (ce qui mathématiquement est possible).

SHA256 a un avantage qui est aussi un inconvénient: il est rapide à calculer et l'usage de processeurs graphiques accélèrent son calcul.
- tout est relatif: une attaque par force brute (essai de toutes les combinaisons possibles) pour tenter de retrouver le texte source depuis son SHA256 devient impraticable pour des sources d'une longueur De 20 bytes et au-delà, l'énergie consommée en calcul devenant inaccessible.
- il n'en reste pas mois que SHA256 n'est pas approprié pour hacher des mots de passe / phrase secrète.

## Hash : PBKFD
Ce hash d'une suite de bytes à une longueur de 32 bytes.

Il n'a pas été publié de cas où deux entrées différentes produisaient le même PBKFD (ce qui mathématiquement est possible).

Le PBKFD est _long_, volontairement, et son algorithme n'est pas accéléré par l'usage de processeurs graphiques.

PBKFD est utilisé pour hacher les phrases secrètes et de rencontre:
- avec une source imposée à 24 signes au minimum, l'attaque par force brute est impossible.
- mais casser un mot de passe se pratique aussi en utilisant des _dictionnaires_ de mots usuels. 

Une phrase secrète de 24 signes qui évite les répétitions d'un code court, qui parsème le texte de séparateurs en chiffres, etc. ne sera pas trouvée par usage de dictionnaires.

## Hash court
Il est fréquemment utilisé un _hash court_ qui tient sur un entier _safe_ en Javascript:
- bien entendu en terme cryptographique ce hash est épouvantable avec un nombre important de collisions.
- mais la probabilité de collision reste humainement très faible (2 ** 53 est un **très** grand nombre).
- il est employé en _complément / filtre_: si le hash court d'un code déjà n'est pas bon, on a évité un test avec un PBKFD ou SHA256.

## Cryptage symétrique AES256
La même clé de 32 bytes est employée pour crypter et décrypter un texte.
- une autre clé dite _SALT_ est employée pour compliquer le piratage: il faut avoir la clé et le _SALT_ pour décrypter un texte.
- les _SALT_ sont usuellement dans le code.
- le cryptage est rapide et les texte crypté peut avoir n'importe quel longueur.

Il n'a pas été rendu public qu'un texte source (long) ait pu être retrouvé par application de force brute sur sa clé de cryptage.

Le premier byte d'une chaîne cryptée est le numéro du _SALT_ employé au cryptage:
- il suffit donc que les logiciels cryptant / décryptant utilisent la même liste de _SALT_.
- en tirant au hasard ce premier byte, une même source cryptées deux fois aura des cryptages différents 255 fois sur 256: ainsi la comparaison entre deux chaînes cryptées n'indiquent pas si la source est la même ou non.
- toutefois quand une chaîne cryptée sert d'identifiant externe, il faut à l'inverse que la même source donne toujours le même rsultat crypté: ceci s'obtient en forçant le cryptage à utiliser le _SALT_ premier de la liste plutôt qu'un aléatoire.

## Cryptage asymétrique RSA2048
Le cryptage nécessite une paire de clés générées ensemble:
- la clé publique sert à crypter un texte qui ne pourra être décrypté qu'en utilisant la clé privéE. Les deux clé sont longues.
- le texte _source_ a une longueur maximale de 256 bytes.
- le cryptage est lent.
- deux cryptages successifs d'un même texte source donne deux cryptages différents.

> 2048, c'est 256 bytes. Attaquer par force brute une telle clé semble irréaliste.

L'objectif est que le _public_ puisse librement crypter un texte à destination d'un seul destinataire.

Quand le texte à crypter peut être plus long que 256 bytes, on génère une clé symétrique aléatoire qui crypte le long texte et on crypte cette clé par la clé RSA.

Chaque avatar a un couple de clés RSA:
- tout un chacun ayant accès à la la clé publique peut crypter un texte que seul l'avatar cible peut décoder.

# Les clés d'un compte

## Phrase secrète
Quand un compte définit sa phrase secrète on s'assure que celle-ci n'a pas déjà été employée en utilisant son PBKFD. 

MAIS, si on donne à quelqu'un l'information que la phrase a déjà été employée, c'est lui donner l'assurance qu'il peut accéder à un autre compte.

Pour chaque phrase on calcule deux PBKFD,
- celui de phrase complète,
- celui d'une phrase réduite en ne prenant que certains signes de la phrase complète.
- on exclut la possibilité de choisir une phrase secrète dont le PBKFD de la phrase raccourcie a déjà été employée.

Certes le compte sait ainsi qu'un autres compte a une phrase secrète dont certains signes à des positions données (lisibles dans le code) lui sont connus. Mais ses tentatives pour trouver les autres sont d'un coût rédhibitoire, d'autant plus qu'il n'en connaît pas la longueur.

## Clé "K" d'un compte
C'est une clé de 32 bytes tirée au hasard: il est impensable d'essayer de la retrouver par force brute.

Elle est stockée dans le document majeur du compte cryptée par le PBKFD de la phrase secrète:
- toutes les autres clés générées sont stockées cryptées par cette clé.
- on peut changer de _phrase secrète_ facilement: le changement re-crypte la clé K mais ne la change pas.

> La clé K n'est jamais communiquée en dehors d'une session. Elle figure en clair dans la session du compte puisqu'elle sert en permanence à obtenir d'autres clés. Mais le compte connaît SA _phrase secrète_ ... fouiller la mémoire pour trouver la clé K n'a aucun intérêt.

La base locale d'un compte sur un poste est une base de type _clé / valeur_.
Les clés comme les valeurs sont cryptées par la clé K:
- celle-ci est rangée dans cette base cryptée par le PBKFD de la phrase secrète.
- pirater une base locale ne sert à rien: soit on n'a pas la clé et on ne la trouvera pas, soit on l'a ... et on a pas besoin de pirater des données auxquelles on peut accéder en clair par l'application.

La clé K crypte toutes les notes des avatars du compte.

## Clé "CV" d'un avatar
Quand un avatar est créé, il est générée une clé dite CV qui crypte sa carte de visite. La clé CV est mémorisé dans le document maître de l'avatar cryptée par la clé K du compte.

Cette clé est aussi incassable que les autres sauf qu'elle va être donnée à tous les autres avatars _en contact_, ceux qui justement on a accordé le droit de lire son nom et sa carte de visite.

> La **fragilité** n'est pas dans le procédé cryptographique mais dans le nombre de _contacts_ à qui on a attribué sa confiance.

Cela dit le risque se limite à ce que des contacts pas forcément désirables un jour puissent lire votre nom et votre carte de visite. Les autres données sont définitivement inaccessibles aux autres avatars.

## Clé d'un chat entre deux avatars
Elle est générée aléatoirement à la création du chat et est cryptée par les clés K respectives des deux comptes. A la création, le créateur du chat crypte cette clé par la clé publique RSA de l'autre: il n'y a que lui qui puisse la décoder et ré-encrypter la clé du chat par sa propre clé K (ce qui sera fait à sa prochaine ouverture de session).

## Clé d'un groupe
Elle est générée aléatoirement à la création du groupe.
- chaque membre du groupe la reçoit lors de son invitation cryptée par sa clé RSA publique.
- il ré-encrypte cette clé par sa clé K plus tard dans une session ouverte.

La clé d'un groupe crypte aussi son nom et sa carte de visite.

La clé du groupe crypte toutes les notes du groupe.

> La **fragilité** n'est pas dans le procédé cryptographique mais dans le nombre de _membres_ à qui le groupe a attribué sa confiance.

## Clé d'un sponsoring
Un sponsoring est créé par un avatar pour être lu par ... une personne qui n'a pas de compte. Il est donc impossible d'utiliser une clé RSA qu'il na pas encore.

On utilise le PBKFD de la phrase de sponsoring comme clé de cryptage:
- seul le destinataire la connaît (du moins c'est plus poli),
- le document de sponsoring ne vis pas longtemps et il est inutilisable une fois qu'il a servi à créer un compte sponsorisé.

## Données NON cryptées
Certaines données ne sont pas cryptées tout le temps. Par exemple un Ticket de crédit:
- son identifiant est généré aléatoirement.
- pour le Comptable il accède à ces tickets _en clair_ mais est incapable de savoir qui a généré ce ticket.
- pour le compte émetteur les tickets sont stockés cryptés par sa clé K.

# Aucune clé de cryptage n'est transmise au serveur
En quel logiciel peut-on avoir confiance ?

L'application UI comme le serveur sont en _open source_: la confiance vient du fait que n'importe qui peut s'assurer que les principes exposés ici sont bien écrits en les respectant.

> **Mais sait que logiciel s'exécute réellement ?**

## L'application UI
De facto elle est lisible dans le navigateur où elle s'exécute. Lisible est un bien grand mot car entre les sources initiales et les quelques fichiers distribués, le logiciel webpack s'est ingénié à le rendre abscons.

### Avec un packaging déterministe
- le procédé de _packaging_ n'est pas confidentiel et est normalement _déterministe_: avec exactement les mêmes sources, dont le paramétrage de webpack, dans un même studio de développement, les quelques fichiers distribuables générés sont reproduits à l'identique à chaque génération.
- pour simplifier disons qu'il y a deux fichiers `.js` qui constituent l'application.
- n'importe qui peut télécharger très simplement ces deux fichiers depuis un site de production et en tirer un SHA-256.
- si une équipe de vérification a vérifié le code et généré l'application distribuable, elle aura aussi ces deux fichiers.
- on peut donc vérifier que les fichiers obtenus en production sont bien ceux générés depuis le code source vérifié.

### SANS packaging déterministe
Il faut passer par **un tiers de confiance** qui va,
- vérifier le code par relecture,
- générer les fichiers distribuables,
- les mettre en ligne avec leur SHA-256.

L'administrateur technique est tenu de déployer ce code comme application UI.

N'importe qui, avec un petit minimum d'agilité technique, peut ainsi s'assurer que l'application UI qui s'exécute dans son browser est bien celui _certifié_ par le tiers de confiance.

## L'application serveur
Aucun procédé ne permet de s'assurer que ce qu'un administrateur technique a déployé et mis en service comme logiciel serveur est conforme au code q'un tiers de confiance a déclaré conforme.

> Pour le serveur tout se ramène à la _confiance_ qu'on accorde à l'administrateur technique qui a déployé le code serveur, aucun procédé technique ne permet de s'en assurer de l'extérieur.

> Si on est soi-m^me son propre administrateur, ou celui de société, on peut avoir confiance en soi-même ou en sa société. Mais les autres ne sont pas obligés de partager cette confiance.

> On peut aussi utiliser des sociétés imperméables à toute pression, y compris juridiques / étatistes.

## Fuite des clés, _backdoors_
Les serveurs peuvent installer des _backdoors_ des procédés qui tracent les clés de cryptages q'ils voient passer.

C'est simple de rendre ce procédé impraticable : il suffit de **NE JAMAIS** transférer une clé sur le serveur, TOUTES les _encryptions / décryptions_ s'exécutant sur l'application UI dont il a été possible de s'assurer qu'elle est conforme aux sources et n'a pas de _backdoors_.

> C'est ce qui a été fait: aucune clé de cryptage de l'application n'est sur le serveur et aucune encryption ne s'y effectue.

## Exception: la clé symétrique du site
Cette clé figure dans la configuration déployée: l'administrateur technique par principe même y a accès, d'autant plus que c'est lui qui la fixe.

L'administrateur a aussi d'autres informations protégées, qui par principe ne sont pas visibles publiquement (ne sont pas dans git):
- certificats SLL du serveur,
- clés / tokens d'accès aux divers providers,
- et donc sa _clé de cryptage du site_.

Cette clé a quelques usages restreints:
- les données du document comptas sont cryptées par cette: le piratage de la base est inopérant pour les lire si la clé du site n'est pas connue.
- deux statistiques, des compteurs non nominatifs en CSV, sont générées sur le serveur. Elles sont cryptés de manière à être lisibles par le Comptable de l'espace qu'elles concernent et par l'administrateur technique. Elles lui permettent en particulier de voir les taux d'occupation des ressources et les coûts calculs (donc d'ajuster ses tarifs).

> Cette clé ne crypte aucune autre donnée; les notes et fichiers par exemple sont cryptés par des clés de l'application qu'aucun administrateur ne connaît, pas par la clé du site.

La clé d'un site est spécifique à **un** site (du moins **un** administrateur). Quand un export de données a lieu entre un site-administrateur A et un B, ils se mettent d'accord sur la clé d'un site intermédiaire  T (export vers T et B exporte T vers lui-même).

# La quasi totalité des _meta-liens_ entre documents sont cryptés
