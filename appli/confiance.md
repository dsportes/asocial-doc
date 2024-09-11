# Analyse de la confiance

Aucune clé de cryptage n'est transmise au serveur

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
Les _meta-liens_ sont ceux qui établissent des relations entre les entités:
- liste des avatars d'un compte,
- liste des groupes accédés par un avatar / compte,
- liste des invitations aux groupes d'un avatar / compte,
- liste des comptes sponsorisés par un compte A en attente de réponse,
- liste des _contacts_ d'un avatar / compte,
- liste des tickets de crédits d'un compte.

Ces informations sont bien entendu présentes dans la base de données, mais il ne faut pas qu'elles soient lisibles par quiconque se serait procuré une copie de la base.

Ce serait problématique que les relation entre un compte et ses avatars ou ses groupes puissent être connues par simple analyse de la base.

Toutes ces _meta-données_ sont cryptés par les clés K des comptes: en d'autres termes elles ne sont connues que dans une session en cours d'un compte dans son browser.

> La base de données n'a pas de _meta-données_ en clair.
