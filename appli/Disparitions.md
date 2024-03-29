@@Index général de la documentation - [index](./index.md)

# Détection et gestion des disparitions

Des ressources, _espace en base de données centrale ou fichiers dans le serveur de fichiers_ sont utilisées par les comptes : l'application doit les libérer quand les comptes sont _présumés disparus_, c'est à dire sans s'être connecté depuis plus d'un an.
- pour préserver la confidentialité, toutes les ressources liées à un compte ne sont pas reliées au compte par des données lisibles dans la base de données mais cryptées et seulement lisibles en session.
- pour marquer que des ressources sont encore utiles, un compte dépose à l'ouverture d'une nouvelle session synchronisée ou incognito, des **jetons datés** ("approximativement" pour éviter des corrélations entre avatars / membres des groupes) dans chacun de ses avatars et chacun des membres des groupes auxquels il participe.
- la présence d'un jeton, par exemple sur un avatar, garantit que ses données ne seront pas détruites dans les 365 jours qui suivent la date du jeton.

Un traitement _ramasse miettes_ tourne chaque jour, détecte les avatars / membres des groupes dont le jeton est trop vieux et efface les données correspondantes jugées comme inutiles: 
- les avatars ayant _disparu par inactivité_.
- les groupes dont tous les membres _actifs_ sont des avatars ayant _disparu par inactivité_.

> Remarque: le jeton de l'avatar primaire d'un compte apparaît toujours comme plus ancien afin que ceux de ses avatars secondaires afin que le compte soit déjà _fermé_ lors de la détection d'inactivité des avatars secondaires.

> Comme aucune référence d'identification dans le monde réel n'est enregistrée pour préserver la confidentialité du système, aucune alerte du type mail ou SMS ne peut informer un compte de sa prochaine disparition s'il ne se connecte pas.
