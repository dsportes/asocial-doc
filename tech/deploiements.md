
# Déploiement l'application Web
L'objectif est d'obtenir une page Web, `index.html` et les ressources associées, dans un folder à distribuer:
- soit sur un CDN, par exemple _github pages_,
- soit dans un serveur Web hébergé,
- soit dans le serveur SRV décrit ci-après quand il héberge les services OP+PUBSUB.

### Configuration
Les paramètres de configuration sont à ajuster dans le fichier `src/config.mjs`. Plusieurs déploiements peuvent avoir exactement la même configuration, typiquement celle par défaut.

Après _build_ on obtient un folder _presque_ prêt à distribuer:
- l'application Web doit disposer des URLs des services OP et PUBSUB.
- celles-ci, qui localisent les services correspondants sur Internet, et donc la base de données et le storage, sont données dans le fichier `etc/urls.json`.
- avec le même _build_ on peut donc distribuer la même version de l'application sur plus d'une distribution, seulement en ajustant les deux lignes de `etc/urls.json`.

Par convention, si les services OP et PUBSUB sont fournis par le **même** serveur que celui distribuant les services OP+PUBSUB les URLs sont simplifiées:

    {
      "opurl" : "https://test.sportes.fr:8443",
      "pubsuburl" : "https://test.sportes.fr:8443"
    }

    Cas où le _serveur_ délivre aussi OP+PUBSUB:
    {
      "opurl": "https",
      "pubsuburl" : "https"
    }
    Si ce serveur est seulement un `http` (en test), `http` remplace `https` ci-dessus.

### Build
La commande est: 

    quasar build -m pwa

Le résultat est dans `dist/pwa` (environ 40 fichiers pour 5Mo):
- y ajouter un folder `dist/pwa/etc`
- y mettre le fichier `urls.json` avec le contenu ci-dessus.

L'application _buildée et configurée_ peut être distribuée depuis `dist/pwa` sur le CDN de son choix, par exemple ci-après dans `githug pages`.

On peut la tester, par exemple, au moyen des commandes suivantes lançant un serveur http/https:

    quasar serve dist/pwa --https --port 8343 --hostname test.sportes.fr --cors --cert ../asocial-srv/keys/fullchain.pem --key ../asocial-srv/keys/privkey.pem 

    quasar serve dist/pwa --http --port 8080

#### browser-list pas à jour
Au cours du _build_ un message apparaît souvent en raison de l'obsolescence de la browser-list.

On la met à jour par la commande:

    npx update-browserslist-db@latest

# Tests externes depuis `localhost` par `ngrok`

`ngrok` permet de créer un _tunnel_ entre _localhost_ et Internet en rendant accessible un serveur HTTP (écoutant le port 8443 par exemple) s'exécutant sur le poste de développement comme s'il était accessible publiquement sur Internet.

Dans sa version gratuite, ngrok demande une inscription et permet d'obtenir un _authtoken_.

Sur son compte dans `ngrok` on demande aussi une URL dédiée: celle-ci est générée par `ngrok` et n'est pas au choix. Par exemple:

    exactly-humble-cod.ngrok-free.app

Il faut enregistrer, une fois, son token sur le poste:

    ngrok config add-authtoken MONTOKEN

    >> Authtoken saved to configuration file: /home/daniel/snap/ngrok/179/.config/ngrok/ngrok.yml

Le token est conservé localement, la localisation s'affiche dans le terminal.

Pour ouvrir un _tunnel_, il faut ouvrir un terminal et lancer: 

    ngrok http --domain=exactly-humble-cod.ngrok-free.app 8443

En retour il apparaît une URL https://... 

Pour fermer le _tunnel_, interrompre la session en cours dans ce terminal.

Cette URL peut être utilisée n'importe où, en particulier depuis un mobile, pour joindre le serveur s'exécutant sur le localhost du poste de développement, grâce à un tunnel établi par Ngrok.

# Typologie des déploiements des services OP et PUBSUB

Selon les configurations choisies, on peut effectuer des _build_ et déployer les services OP et PUBSUB selon plusieurs options. Ci-après la liste des options documentées, et celles a priori non pertinentes avec la raison associée.

### Déploiements pour un site NON géré
Un serveur NON géré est un serveur dont on assure soi-même la configuration et la surveillance d'exploitation. Typiquement:
- un site de production sur une ou des VMs hébergés chez un fournisseur standard.
- un serveur de test _personnel_ pour une exploitation de démonstration ou de test, en ayant un nom de domaine spécifique.

Sur un site non géré, il faut installer:
- éventuellement un `nginx` (ou équivalent) capable d'effectuer un _load balancing_ entre plusieurs instances de serveur HTTP assurant un service OP afin d'accroître la puissance disponible.
- éventuellement une base de données, Sqlite ou Postgresql, locale, et en gérer la sécurité / backup / restore. Mais il est aussi possible d'utiliser un service d'hébergement Firestore (ou par extension DynamoDB -Amazon-, ou CosmoDB -Microsoft Azure-).

Les déploiements documentés sont les suivants:
- **Serveur OP**: serveur assurant le seul service OP.
- **Serveur PUBSUB**: serveur assurant le seul service PUBSUB.
- **Serveur SRV**: serveur assurant les deux services OP+PUBSUB.
  - optionnellement, SRV peut aussi assurer la distribution de l'application Web,
  - optionnellement, SRV peut aussi assurer la distribution d'un site Web purement statique (par exemple documentaire).

### Déploiement pour un site GAE géré
Google App Engine (GAE) est une solution pour déployer un _serveur_  assurant les mêmes fonctionnalités qu'un site NON géré avec les remarques suivantes.

**GAE est un _faux_ serveur:** une ou plusieurs instances peuvent s'exécuter en parallèle, le nombre pouvant est borné à 1 instance. Au bout d'un certain temps sans réception de requête, l'instance est arrêtée et sera relancé à l'arrivée d'une nouvelle requête:
- c'est exactement le même comportement qu'un Cloud Function, si ce n'est que la durée de vie en l'absence de requête est plus long (une heure au lieu de 5 minutes pour fixer les idées).

**Déployer le service OP seul sur GAE n'a pas d'intérêt a priori:** plutôt utiliser un Cloud Function.

**Déployer le service PUSUB seul sur GAE n'a pas d'intérêt a priori:** plutôt utiliser un Cloud Function.

**Déployer les deux services OP+PUBSUB sur GAE à un intérêt** de simplification d'administration:
- la comparaison des coûts avec un mix de Cloud Functions n'a pas été faite.
- il faut borner le nombre d'instances à 1, PUBSUB ne peut pas être multi-instances: en conséquence c'est **une option de _faible_ puissance**.
- le mot _faible_ est flou: le débit potentiel peut cependant être suffisant dans les cas d'usager par des organisations de taille modeste ou moyenne.
- dans les cas de faible trafic, le coût tombe facilement en dessous du minimum facturable, l'hébergement devenant gratuit.

GAE _pourrait_ assurer la distribution de l'application Web (et du site documentaire statique) mais **ce n'est pas une bonne idée**:
- ça oblige à refaire un déploiement de l'ensemble même quand seule l'application Web a changé en provoquant une interruption certes faible de disponibilité.
- ça présente aux utilisateurs une URL d'accès (celle de l'application Web) assez abscons et où Google apparaît.

**Il reste préférable d'assurer séparément la distribution de l'application par `github pages` (ou autre)**. Ceci permet aussi de changer le déploiement des services OP et PUBSUB pour des solutions différentes meilleures en termes de coûts / performances de manière transparente pour les utilisateurs, ce qui est souhaitable.

### Déploiement par des Cloud Functions (CF)
**Le service OP peut être déployé par CF**, sans contrainte sur le nombre d'instances en parallèle.

**Le service PUBSUB peut être déployé par CF**, avec contrainte d'une instance au plus.

Il n'est documenté ici que l'usage de Google Cloud Functions: les deux autres options chez Amazon et Azure sont à tester et documenter, même si en théorie les adaptations de code à effectuer semblent marginales.

# Choix de la _base de données_

### Autogestion de la base de données
C'est possible pour les _providers_ SQLite et PostgreSQL.

C'est une gestion lourde et humainement contraignante pour une organisation.

### Service hébergé de la _base de données_
#### Firestore
Service géré par Google. Si le débit est faible on peut tomber sous le seuil de facturation.

En pratique ceci impose _naturellement_ à opter pour Google Storage.

### PostgreSQL
Il ya plusieurs offres sur le marché avec un coût d'entrée minimal d'une vingtaine d'euros mensuels: certes le débit va être important, mais c'est une solution à réserver si le coût de Firestore devient prohibitif.

### DynamoDB CosmoDB
Les classes _providers_ n'ont pas été écrites:
- sur le papier il n'y a pas d contradictions avec les contraintes à respecter pour l'interface _provider_.
- les autres _providers_ ont environ 500 lignes de code: le temps à psser en compréhension / test des API, puis en création des comptes Amazon ou Azure, puis en tests, est plus important que l'effort d'écriture à proprement parlé du code.

# Choix du _storage_

### Autogestion
Réservé à un site de test avec le provider _file system_.

### Google Storage
A choisir si les options GAE et CF chez Google sont prises.

### Amazon S3
S3 est un _interface_, le _provider_ a été testé avec `minio`.
- S3 est bien entendu disponible chez Amazon.
- d'autres fournisseurs existent sur le marché, la comparaions des coûts n'a pas été faite.
- gérer soi-même S3 avec `minio` n'est pas réaliste en production.

Le Storage de Azure serait à écrire: environ 500 lignes de code.

- **Serveur OP**: serveur assurant le seul service OP.
- **Serveur PUBSUB**: serveur assurant le seul service PUBSUB.
- **Serveur SRV**: serveur assurant les deux services OP+PUBSUB.

# Déploiements _Serveur_

L'objectif est de pouvoir exécuter les services OP et PUBSUB sur un host _non géré_, typiquement dans une VM, par opposition aux dépliements _gérés_ (Cloud functions, Google App Engine, etc.).

Les déploiements possibles sont:
- déploiement d'un service OP.
- déploiement d'un service PUBSUB.
- déploiement _SRV_, incluant OP et PUBSUB. Dans ce dernier cas, optionnellement, le _serveur_ peut gérer de plus:
  - le service Web _statique_ de l'application Web,
  - le service _statique_ d'un espace Web pour la documentation typiquement.

Les déploiements demandent:
- d'ajuster la configuration pour chaque cas à déployer,
- d'effectuer un _build_,
- de distribuer le résultat du _build_ sur le site de production.


Build webpack:
- package.json
  "typeX": "module",
- commande: npx webpack
  Environ 40s. Patience.

Run:
- vérifier qu'il y a bien une base dans dist/sqlite/test.db3 et un folder dist/fsstorage
- dans dist: node app.js

package.json vide ({ }) est nécessaire: sinon node va en chercher un dans la hiérarchie (possiblement au-dessus) et s'il en trouve un avec "type": "module", il va refuser de charger les require qui existent dans le .js généré.

## Déploiement _Serveur OP_

## Déploiement _Serveur PUBSUB_

## Déploiement _Serveur SRV_

# Déploiement _GAE_

# Déploiements _Cloud Function_ des services OP et PUBSUB

## Déploiement du service OP

## Déploiement du service PUBSUB
