
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


Sur le site de DEV, un serveur HTTP peut être lancé et écouter le port 8443 par exemple.

Préalablement dans un terminal ou aura lancé les commandes:

    ngrok config add-authtoken MONTOKEN
    ngrok http http://localhost:8443
    ngrok http --domain=exactly-humble-cod.ngrok-free.app 8443

En retour il apparaît une URL https://...

Cette URL peut être utilisée n'importe où, en particulier depuis un mobile, pour joindre le serveur sur le localhost du site de DEV, grâce à un tunnel établi par Ngrok.

### Token d'authentification
Il a été généré à l'inscription sur le site Ngrok:
- login:
- pwd:

Le token est disponible sur le site.

De plus il est sauvé dans un fichier local lors de l'authentification.

Authtoken saved to configuration file: /home/daniel/snap/ngrok/179/.config/ngrok/ngrok.yml



# Déploiements _stand alone_ des services OP et PUBSUB

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
