@@Index général de la documentation - [index](./index.md)

# Liste des tables de la base de données centrale

- `versions` (id) : table des prochains numéros de versions et autres singletons (id value)
- `avrsa` (id) : clé publique d'un avatar
- `trec` (id) : transfert de fichier en cours (uploadé mais pas encore enregistré comme fichier d'un secret)
- `gcvol` (id) : GC des volumes des comptes disparus.

**Tables synchronisables**

- `compte` (id) : authentification et liste des avatars d'un compte
- `prefs` (id) : données et préférences d'un compte
- `compta` (id) : ligne comptable d'un avatar
- `cv` (id) : statut d'existence, signature et carte de visite des avatars, contacts et groupes
- `avatar` (id) : données d'un avatar et liste de ses contacts et groupes
- `couple` (id) : données d'un contact entre deux avatars
- `groupe` (id) : données d'un groupe
- `membre` (id, im) : données d'un membre d'un groupe
- `secret` (id, ns) : données d'un secret d'un avatar, d'un couple ou d'un groupe
- `contact` (phch) : parrainage ou rendez-vous de A0 vers un A1 à créer ou inconnu
- `invitgr` (id, ni) : **NON persistante en IDB**. invitation reçue par un avatar à devenir membre d'un groupe
- `invitcp` (id, ni) : **NON persistante en IDB**. invitation reçue par un avatar à devenir membre d'un couple
- `chat` (id, dh) : chat d'un compte avec les comptables.
- `tribu` (id) : données et compteurs d'une tribu.
