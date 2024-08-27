# Service PUBSUB

Ce service est constitué:
- d'une mémoire non persistante de l'état des sessions actives,
- de requêtes POST déclenchant ses opérations et des fonctions correspondantes pour les appels en structure SRV depuis le service OP.

### Objet `perimetre`
Cet objet décrit le périmètre d'un compte et est construit depuis un _compte_ (`get perimetre ()` des classes `Compte` dans APP et `Comptes` dans OP).
- `id`: ID du compte
- `vpe`: version du périmètre. C'est la version du compte à laquelle le périmètre a été changé pour la dernière fois, un compte pouvant changer sans que son _périmètre_ ne change.
- `lavgr`: liste des IDs des avatars du compte et des groupes accédés par le compte, triée par IDs croissantes.

`function equal(p1, p2)`
- retourne `true` si `p1` et `p2` (du même compte) ont même liste `lavgr`.

#### Méthode / requête `login`
Elle est invoquée par un requête HTTP ayant un objet argument ou paramètre crypté par la clé du site:
- `sessionId`: `rnd.nc` identifiant de la connexion dans la session appelante.
- `subscription`: token de suscription généré à l'initialisation de la session (en base 64).
- `perimetre`: liste les IDs des objets du périmètre du compte.

En déploiement OP distinct de PUBSUB, OP effectue une requête HTTP: si cette requête échoue (le service PUBSUB n'étant pas disponible) la requête `cnx` retourne un statut indiquant que la session n'est pas _notifiée_.

En déploiement SRV, la méthode est directement invoquée, sans avoir besoin de passer par une requête HTTP.

#### Requête `heartbeat`
Elle est invoquée en session toutes les deux minutes pour informer PUBSUB que la session est toujours active:
- `sessionId`: `rnd.nc` identifiant de la connexion dans la session appelante.
- `nhb`: numéro séquentiel du heartbeat.
  - 1..N: numéro d'appel successif. émis par la session.
  - 0: par convention, indique une déconnexion de la session émise par la session.

Retour: `KO`
- détection d'un heartbeat manquant, le précédent enregistré n'est pas `nhb - 1` (ou n'existe pas). La session n'est plus _notifiée_, elle est supprimée (si elle existait). 

Ces deux opérations:
- mettent à jour l'état mémoire de PUBSUB immédiatement et de manière atomique (non interruptible).
- n'émettent pas de message de _notification_.

#### Fin d'opération de mise à jour de OP `notif`
Lorsqu'une opération de mise à jour s'exécute dans OP, un certain nombre de documents sont mis à jour, leur version a changé: un objet `trlog` est créé.
- cet objet a une forme _longue_ qui est transmise à PUBSUB sur la méthode / requête `notif`.
  - le traitement par PUBSUB a une première phase _synchrone_ qui,
    - met à jour l'état mémoire des sessions,
    - prépare la liste des messages de notifications à envoyer: chaque message a pour structure un `trlog` de forme raccourcie.
  - la second phase est asynchrone et consiste à émettre tous les messages de notification préparés en phase 1.
  - la méthode / requête `notif` est courte vu du côté de l'appelant OP et ne diffère que de peu le retour de l'opération de mise à jour.
- l'objet `trlog` a une forme raccourcie quand il parvient dans les sessions:
  - la session appelante de l'opération: les mises à jour ayant concerné au moins un document du périmètre du compte (sauf exception ?).
  - les autres sessions enregistrées par PUBSUB _impactées_ c'est à dire ayant au moins un des documents de leur périmètre mis à jour par l'opération (possiblement aucune session). Chaque session recevra en message de notification un `trlog` raccourci.

En session on peut ainsi recevoir des `trlog` depuis deux sources:
- en résultat d'une opération de mise à jour soumise par la session elle-même,
- par suite d'une opération de mise à jour déclenchée par une autre session et parvenue en _notification_.

Le traitement ensuite est identique: une opération `Sync` sera émise vers OP afin d'obtenir les mises à jour des documents modifiés / créés / supprimés. 

### Objet `trlog`
- `sessionId`: `rnd.nc`. Permet de s'assurer que ce n'est pas une notification obsolète d'une connexion antérieure.
- `partId`: ID de la partition si c'est un compte "0", sinon ''.
- `vpa`: version de cette partition ou 0 si inchangée ou absente.
- `vce`: version du compte. (utile ?)
- `vci`: version du document `compti` s'il a changé, sinon 0.
- `lavgr`: liste `[ [idi, vi], ...]` des Couples des IDs des avatars et groupes ayant été impactés avec leur version.
- `lper`: **format long seulement**. `liste [ {...}, ...]` des `perimetre` des comptes ayant été impactés par l'opération (sauf celui de l'opération initiatrice).

### Mémoire de PUBSUB
Map `sessions`: clé: `rnd` de `sessionID`
- `nc`: nc de sessionID.
- `cid`: ID du compte.
- `nhb`: numéro d'ordre du dernier heartbeat.
- `dhhb`: date-heure du dernier heartbeat. Permet de purger les sessions inactives n'ayant pas émises de déconnexion explicite.
- `subscription`: token de subscription de la session.

Map `comptes`: clé: ID du compte
- `cid` : ID du compte
- `perimetre`: plus récent périmètre connu.
- `sessions`: set des `rnd` identifiant les sessions ayant pour `cid` celui de ce compte.

Map `xref`: clé : ID d'un avatar / groupe / partition
- `comptes`: set des IDs des comptes référençant cette ID.

Règles de gestion:
- les `comptes` dont le set des sessions est vide sont supprimés.
- les `xref` dont le set des comptes est vide sont supprimés.
- les `sessions` dont le `dhhb` + 2 minutes est dépassé sont supprimés (et en cascade potentiellement leur entrée dans comptes et les `xref` associés).

