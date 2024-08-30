
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

# Fichiers de configuration

### Fichier `src/keys.mjs`
Ce fichier contient des autorisations et tokens spécifiques de l'administrateur du site:
- il est exclu de git afin de ne pas exposer ces données au public,
- sa sécurité est gérée par l'administrateur technique par ses propres moyens.

Il comporte les constantes suivantes:
- `app_keys`: voir ci-après.
- `service_account` : pour les déploiements sur Google Cloud Platform. Procédure décrite en annexe.
- `s3_config` : le token d'authentification au service S3 choisi. Procédure décrite en annexe.

    export const app_keys = {
      admin:  ['FCp8...'],
      sites:  {
        A: 'FCp8...',
        B: 'em8+...' 
      },
      vapid_private_key: 'FiR...',
      vapid_public_key: 'BC8...'
    }

    export const service_account = {
      ... obtenu depuis le compte Google
    }

    export const s3_config = {
      ... obtenu depuis le fournisseur d'accès S3
    }

Les _clés_ de l'administrateur technique et des sites A, B ... sont obtenus ainsi:
- lancer l'application Web (n'importe laquelle)
- ouvrir le panneau d'outils: barre du bas, icône _engrenage_,
- onglet _Tester une phrase secrète_
- saisir une phrase secrète et la garder cachée par exemple `les framboises sont bleues cette année`,
- copier le texte qui apparaît dans `SHA256 du PBKFD de la phrase complète`

    ZgHxc7BeHgR7z5HLpidsMd4XmSJmfCCulgu7cfwB9V8=

Ceci donne une clé à mettre dans les propriétés de app_keys:

`admin` : c'est la clé qui permet d'authentifier le login de l'administrateur technique. Dans cet exemple:

    Organisation: `admin`
    Phrase secrète: `les framboises sont bleues cette année`

`sites` : cette rubrique permet d'enregistrer la clé de cryptage des _sites_:
- habituellement un administrateur n'est concerné que par _son_ site, de code `A` typiquement.
- toutefois s'il doit réaliser des exports de base de données pour d'autres sites, il doit disposer de la clé de cryptage du site cible, d'où dans ce cas l'existence d'un site `B`.

`vapid_private_key` et `vapid_public_key` : ce couple de clés permet au service PUBSUB de pousser des notifications vers l'application Web qui DOIT avoir dans sa configuration la `vapid_public_key`.
- génération par l'outil _vapid_: `node src/tools.mjs vapid`

### Folder `keys`
**Ce folder contient le certificat du domaine de l'application** tels que générés par `Lets Encrypt` (https://letsencrypt.org/) par exemple:
- `fullchain.pem`
- `privkey.pem`

Ce folder,
- est exclu de git pour ne pas exposer les clés du domaine au public,
- est **externe** au _build_ afin que sur le site on puisse renouveler ces clés (obsolètes régulièrement) sans refaire un déploiement.

**Ce folder ne sert qu'aux déploiements _serveur_** et est inutile en cas de déploiement GAE et CF (dont les certificats sont gérés par le fournisseur).

### Fichier `src/config.mjs`
- Il est inclus dans git.
- Chaque déploiement a le sien.
- Il comporte,
  - une partie _fonctionnelle_ qui peut avoir une valeur commune pour tous les déploiements du site.
  - une partie _technique_ spécifique de chaque déploiement et détaillée ci-après.

Il comporte des lignes donnant les _configuration_ des _providers_ de DB et de Storage:
- pouvant être cités dans la section run
- pouvant être cité sur les lignes de commande: `node src/tool.mjs ...`

    // Configuation nommées des providers db et storage
    s3_a: { bucket: 'asocial' },
    fs_a: { rootpath: './fsstorage' },
    fs_b: { rootpath: './fsstorageb' },
    gc_a: { bucket: 'asocial-test1.appspot.com', /* fixé pour emulator ? */ },
    sqlite_a: { path: './sqlite/test.db3' },
    sqlite_b: { path: './sqlite/testb.db3' },
    firestore_a: { },

# Déploiements _Serveur_

Les déploiements possibles sont:
- déploiement d'un service OP.
- déploiement d'un service PUBSUB.
- déploiement _SRV_, incluant OP et PUBSUB. Dans ce dernier cas, optionnellement, le _serveur_ peut gérer de plus:
  - le service Web _statique_ de l'application Web,
  - le service _statique_ d'un espace Web pour la documentation typiquement.

Chaque déploiement demande:
- d'ajuster la configuration pour chaque cas à déployer,
- d'effectuer un _build_,
- de distribuer le résultat du _build_ sur le site de production.

# Déploiements _Serveur_ d'un service OP (sans PUBSUB)

### Fichier `src/keys.mjs`
`export const app_keys = {`
- les clés vapid... sont inutiles (mais ne nuisent pas).

`export const service_account = {`
- uniquement si le _provider_ de base de données est firestore.

`export const s3_config = {`
- uniquement si le _provider_ de Storage est S3.

### Folder `keys`
Le certificat du domaine est requis.

### Fichier `src/config.mjs`

    export const config = {
      // Paramètres fonctionnels
      tarifs: [
        { am: 202201, cu: [0.45, 0.10, 80, 200, 15, 15] },
        { am: 202305, cu: [0.45, 0.10, 80, 200, 15, 15] },
        { am: 202309, cu: [0.45, 0.10, 80, 200, 15, 15] }
      ],
      allocComptable: [8, 2, 8],
      allocPrimitive: [256, 256, 256],
      heuregc: [3, 30], // Heure du jour des tâches GC
      retrytache: 60, // Nombre de minutes avant le retry d'une tâche

      // Configuration du déploiement
      env: { },

      fs_a: { rootpath: './fsstorage' },
      gc_a: { bucket: 'asocial-test1.appspot.com' */ },

      sqlite_a: { path: './sqlite/test.db3' },
      firestore_a: { },

      pathlogs: './logs',
      pathkeys: './keys',

      run: {
        site: 'A',
        origins: new Set(['http://localhost:8080']),
        nom: 'test asocial-sql', // pour le ping
        pubsubURL: 'https://test.sportes.fr/pubsub/',
        mode: 'https',
        port: 8443,
        storage_provider: 'gc_a',
        db_provider: 'sqlite_a',
        projectId: 'asocial-test1',

        rooturl: 'http://test.sportes.fr:8443'
      }
    }

**Commentaires**
- `gc_a:` configuration du provider Google Cloud Storage. Par commodité on peut en décrire plusieurs (gc_a gc_b etc.)
- `sqlite_a:` configuration du provider DB SQLite. Par Par commodité on peut en décrire plusieurs (sqlite_a sqlite_b etc.)
- `firestore_a:` configuration du provider DB Firestore. Par Par commodité on peut en décrire plusieurs (firestore_a firestore_b etc.)
- `run.site: 'A'` indique l'entrée de app_keys.sites qui détient la clé de cryptage du site
- `run.origins:` Set des origin des sites de CDN délivrant l'application Web. Si vide ou que la directive est absente, pas de contrôle sur l'origin.
- `run.nom:` sert uniquement à l'affichage lors d'une requête ping.
- `run.mode:` 'https' (par exception en test 'http').
- `run.port:` numéro de port d'écoute.
- `pubsubURL`: URL où le service OP va trouver le service PUBSUB,
- `run.storage_provider:` identifiant du provider de Storage (référencé au-dessus).
- `run.db_provider:` identifiant du provider de DB (référencé au-dessus).
- `run.projectId:` ID du project Google si l'un des providers storage / db est un service de Google.
- `run.rooturl:` en général absent. URL externe d'appel du serveur qui ne sert qu'à un provider de storage qui doit utiliser le serveur pour délivrer une URL get / put file. Cas storageFS / storageGC en mode _emulator_.

### Build par `webpack`

Fichier `webpack.config.mjs` :

    import path from 'path'
    export default {
      entry: './src/server.js', 
      target: 'node',
      mode: 'production',
      output: {
        filename: 'op.js',
        path: path.resolve('dist/op')
      }
    }

Le _résultat du _build_ par webpack ira dans le folder `dist/op` et son .js principal y sera `op.js`

#### Gestion de `package.json` et `build`
En développement il y a une ligne:

    "type": "module",

Pour effectuer un _build_ **il faut renommer cette directive** "typeX" (ou la supprimer).

Commande dans un terminal (à la racine du projet):
- `npx webpack`
- durée de 30s à 1 minute: être patient, rien ne s'affiche avant la fin.

**Il faut renommer la directive ""typeX" en "type"** sinon le développement ne marche plus.

Dans le folder `dist/op` insérer un fichier package.json ne contenant que `{}`:

    echo "{}" > dist/op/package.json

Si on veut exécuter immédiatement le résultat du _build_ directement dans le folder `dist/op`, `node` va chercher un `package.json`, y compris au niveau de folder supérieur et va trouver le `package.json` du projet qui a une directive `"type"module"` ce qui met l'exécution en erreur car `op.js` utilise un `require`.
La présence du `package.json` _fake_ permet d'éviter ce problème.

### Exécution de test dans dist/op
- si le _provider_ de storage était par exemple `sqlite_a: { path: './sqlite/test.db3' },` vérifier qu'il y a bien une base `dist/op/sqlite/test.db3`.
- si le _provider_ de storage était par exemple `fs_a: { rootpath: './fsstorage' },` dans config.mjs, vérifier qu'il existe bien un folder `dist/op/fsstorage`.

Exécution:

    cd dist/op
    node op.js

> **Attention:** `op.js` est le _vrai_ exécutable et écrit vraiment dans la _vraie_ base et le _vrai_ storage.

# Déploiements _Serveur_ d'un service PUBSUB (sans OP)

### Fichier `src/keys.mjs`
`export const app_keys = {`
- les clés vapid... SONT REQUISES.

`export const service_account = {`
- inutile (mais ne nuit pas).

`export const s3_config = {`
- inutile (mais ne nuit pas).

### Folder `keys`
Le certificat du domaine est requis.

### Fichier `src/config.mjs`

    export const config = {
      // Paramètres fonctionnels inutiles mais ne nuisent

      // Configuration du déploiement
      env: { },

      pathlogs: './logs',
      pathkeys: './keys',

      run: {
        site: 'A',
        origins: new Set(['http://localhost:8080']),
        nom: 'test asocial-pubsub', // pour le ping
        mode: 'https',
        port: 8444
      }
    }

**Commentaires**
- `run.site: 'A'` indique l'entrée de app_keys.sites qui détient la clé de cryptage du site
- `run.origins:` Set des origin des sites de CDN délivrant l'application Web. et des sites OP. Si vide ou que la directive est absente, pas de contrôle sur l'origin.
- `run.nom:` sert uniquement à l'affichage lors d'une requête ping.
- `run.mode:` 'https' (par exception en test 'http').
- `run.port:` numéro de port d'écoute. Attention à ne pas donner le même numéro de port que celui du service OP si c'est un serveur sur le même host.

### Build par `webpack`

Fichier `webpack.config.mjs` :

    import path from 'path'
    export default {
      entry: './src/pubsub.js', 
      target: 'node',
      mode: 'production',
      output: {
        filename: 'pubsub.js',
        path: path.resolve('dist/pubsub')
      }
    }

Le _résultat du _build_ par webpack ira dans le folder `dist/pubsub` et son .js principal y sera `pubsub.js`

#### Gestion de `package.json` et `build`
En développement il y a une ligne:

    "type": "module",

Pour effectuer un _build_ **il faut renommer cette directive** "typeX" (ou la supprimer).

Commande dans un terminal (à la racine du projet):
- `npx webpack`
- durée de 30s à 1 minute: être patient, rien ne s'"affiche avant la fin.

**Il faut renommer la directive ""typeX" en "type"** sinon le développement ne marche plus.

Dans le folder `dist/pubsub` insérer un fichier package.json ne contenant que `{}`:

    echo "{}" > dist/pubsub/package.json

Si on veut exécuter immédiatement le résultat du _build_ directement dans le folder `dist/pusub`, `node` va chercher un `package.json`, y compris au niveau de folder supérieur et va trouver le `package.json` du projet qui a une directive `"type"module"` ce qui met l'exécution en erreur car `pubsub.js` utilise un `require`.
La présence du `package.json` _fake_ permet d'éviter ce problème.

### Exécution de test dans dist/srv

Exécution:

    cd dist/pubsub
    node pusub.js

> **Attention:** `pubsub.js` est le _vrai_ exécutable et pousse de _vraies_ notifications.

# Déploiements _Serveur_ d'un service OP+PUBSUB

### Fichier `src/keys.mjs`
`export const app_keys = {`
- les clés vapid... sont REQUISES.

`export const service_account = {`
- uniquement si le _provider_ de base de données est firestore.

`export const s3_config = {`
- uniquement si le _provider_ de Storage est S3.

### Folder `keys`
Le certificat du domaine est requis.

### Fichier `src/config.mjs`

    export const config = {
      // Paramètres fonctionnels
      tarifs: [
        { am: 202201, cu: [0.45, 0.10, 80, 200, 15, 15] },
        { am: 202305, cu: [0.45, 0.10, 80, 200, 15, 15] },
        { am: 202309, cu: [0.45, 0.10, 80, 200, 15, 15] }
      ],
      allocComptable: [8, 2, 8],
      allocPrimitive: [256, 256, 256],
      heuregc: [3, 30], // Heure du jour des tâches GC
      retrytache: 60, // Nombre de minutes avant le retry d'une tâche

      // Configuration du déploiement
      env: { },

      fs_a: { rootpath: './fsstorage' },
      gc_a: { bucket: 'asocial-test1.appspot.com' */ },

      sqlite_a: { path: './sqlite/test.db3' },
      firestore_a: { },

      prefixapp: '/app',
      pathapp: './app',

      // Seulement si SRV sert de web statique documentaire
      prefixwww: '/www',
      pathwww: './www',

      pathlogs: './logs',
      pathkeys: './keys',

      run: {
        site: 'A',
        origins: new Set(['http://localhost:8080']),
        nom: 'test asocial-sql', // pour le ping
        pubsubURL: null,
        mode: 'https',
        port: 8443,
        storage_provider: 'gc_a',
        db_provider: 'sqlite_a',
        projectId: 'asocial-test1',

        rooturl: 'http://test.sportes.fr:8443'
      }
    }

**Commentaires**
- `prefixapp: pathapp:` Seulement si SRV sert de CDN pour l'application.
- `prefixwww: pathwww:` seulement si SRV sert de web statique documentaire

- `gc_a:` configuration du provider Google Cloud Storage. Par commodité on peut en décrire plusieurs (gc_a gc_b etc.)
- `sqlite_a:` configuration du provider DB SQLite. Par Par commodité on peut en décrire plusieurs (sqlite_a sqlite_b etc.)
- `firestore_a:` configuration du provider DB Firestore. Par Par commodité on peut en décrire plusieurs (firestore_a firestore_b etc.)
- `run.site: 'A'` indique l'entrée de app_keys.sites qui détient la clé de cryptage du site
- `run.origins:` Set des origin des sites de CDN délivrant l'application Web. Si vide ou que la directive est absente, pas de contrôle sur l'origin.
- `run.nom:` sert uniquement à l'affichage lors d'une requête ping.
- `pubsubURL`: null, le serveur assure localement ce service aussi.
- `run.mode:` 'https' (par exception en test 'http').
- `run.port:` numéro de port d'écoute.
- `run.storage_provider:` identifiant du provider de Storage (référencé au-dessus).
- `run.db_provider:` identifiant du provider de DB (référencé au-dessus).
- `run.projectId:` ID du project Google si l'un des providers storage / db est un service de Google.
- `run.rooturl:` en général absent. URL externe d'appel du serveur qui ne sert qu'à un provider de storage qui doit utiliser le serveur pour délivrer une URL get / put file. Cas storageFS / storageGC en mode _emulator_.

### Build par `webpack`

Fichier `webpack.config.mjs` :

    import path from 'path'
    export default {
      entry: './src/server.js', 
      target: 'node',
      mode: 'production',
      output: {
        filename: 'srv.js',
        path: path.resolve('dist/srv')
      }
    }

Le _résultat du _build_ par webpack ira dans le folder `dist/srv` et son .js principal y sera `srv.js`

#### Gestion de `package.json` et `build`
En développement il y a une ligne:

    "type": "module",

Pour effectuer un _build_ **il faut renommer cette directive** "typeX" (ou la supprimer).

Commande dans un terminal (à la racine du projet):
- `npx webpack`
- durée de 30s à 1 minute: être patient, rien ne s'affiche avant la fin.

**Il faut renommer la directive ""typeX" en "type"** sinon le développement ne marche plus.

Dans le folder `dist/srv` insérer un fichier package.json ne contenant que `{}`:

    echo "{}" > dist/srv/package.json

Si on veut exécuter immédiatement le résultat du _build_ directement dans le folder `dist/srv`, `node` va chercher un `package.json`, y compris au niveau de folder supérieur et va trouver le `package.json` du projet qui a une directive `"type"module"` ce qui met l'exécution en erreur car `srv.js` utilise des `require`.
La présence du `package.json` _fake_ permet d'éviter ce problème.

### Exécution de test dans `dist/srv`
- si le _provider_ de storage était par exemple `sqlite_a: { path: './sqlite/test.db3' },` vérifier qu'il y a bien une base `dist/op/sqlite/test.db3`.
- si le _provider_ de storage était par exemple `fs_a: { rootpath: './fsstorage' },` dans config.mjs, vérifier qu'il existe bien un folder `dist/op/fsstorage`.

Exécution:

    cd dist/srv
    node srv.js

> **Attention:** `srv.js` est le _vrai_ exécutable et écrit vraiment dans la _vraie_ base et le _vrai_ storage.

# Déploiement _GAE_

# Déploiements _Cloud Function_ des services OP et PUBSUB

## Déploiement du service OP

## Déploiement du service PUBSUB
