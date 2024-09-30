## Bug / vérifications...

## Dev
Contrôle de volume global d'un espace

Ralentissement des DL ???

Déploiements:
- GAE
- CF OP
- CF PUBSUB

## Doc
- Compteurs de consommation
- Comptable : stats des comptes / tickets

## Conversion de MD en HTML

  yarn add showdown

- le fichier md.css contient le CSS
- le résultat est un HTML de base mais bien formé.

    node md2html.js README
    
    (SANS extension .md)


## Remarques diverses

{
  // Use IntelliSense to learn about possible attributes.
  // Hover to view descriptions of existing attributes.
  // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
  "version": "0.2.0",
  "configurations": [
    {
      "type": "chrome",
      "request": "launch",
      "name": "Quasar App: chrome",
      "url": "https://localhost:8343",
      "webRoot": "${workspaceFolder}/src",
      "sourceMapPathOverrides": {
        "webpack://asocial/./src/*": "${webRoot}/*"
      }
    },
    {
      "type": "firefox",
      "request": "launch",
      "name": "Quasar App: firefox",
      "url": "https://localhost:8343",
      "webRoot": "${workspaceFolder}/src",
      "pathMappings": [
        {
          "url": "webpack://asocial/src",
          "path": "${workspaceFolder}/src"
        }
      ]
    }
  ]
}

# Mise en place de l'aide en ligne
Les ressources correspondantes sont toutes dans `/src/assets/help` :
- `_plan.json` : donne la table des matières des pages de l'aide.
- des images en PNG, JPG, SVG comme `dessin.svg`.
- les pages de texte en md : `codepage_lg-LG.md`
  - `codepage` est le _code_ la page.
  - `lg-LG` est la locale (`fr-FR` `en-EN` ...).
  - le _titre_ de la page est une traduction dans `/src/i18n/fr-FR/index.js`
    - son entrée est: `A_codepage: 'Le beau titre',`


### Plan de l'aide

    [
      { "id": "pa", "lp": ["presentation", "comptes", "coutshebergement", "page2"] },
      { "id": "av", "lp": []},
      { "id": "faq", "lp": ["page3"]},
      { "id": "dev", "lp": ["documents", "crypto"]}
    ]

Il donne la liste ordonné des racines dans l'arbre de l'aide. Chaque racine est décrite par:
- `id`: le _code_ de la page _racine,
- `lp`: la liste ordonnée des codes des pages _fille_.

### Conventions d'écriture des pages en markdown
**La page est découpée en _sections_**, chacune est identifiée par une ligne:

    # Titre de ma section

Avec un unique espace entre `#` et le texte du titre.

La partie **avant** la première ligne `# section...` est _l'introduction_.

Chaque section est présentée avec:
- une _expansion_ dépliable qui permet d'en voir juste le titre, puis le détail une fois dépliée,
- un _menu_ éventuel listant les autres pages de l'aide référencée.

#### Références vers d'autres pages de l'aide
Sauf dans l'introduction des lignes comme celle-ci:

    @@crypto

indique une référence vers une autre page de l'aide:
- `@@` en tête de la ligne,
- puis le code de la page référencée (sans espaces ni au début, ni à la fin).

#### Images
Les _images_ apparaissent sous l'une de ces formes:

    SVG dans img
    
    <img src="dessin.svg" width="64" height="64" style="background-color:white">
    
    PNG dans un img
    
    <img src="logo.png" width="96" height="96" style="background-color:white">
    
    Chargé depuis svg
    
    <img src="logo.svg" width="96" height="96" style="background-color:white">

Ce qui figure dans src est le nom du fichier de l'image dans `/src/assets/help`

Elle sera chargée en tant que ressource en base64 et le tag `<img...` réécrit. En cas d'absence c'est une image par défaut qui est prise.
- na pas oublier le _background_ pour les SVG et PNG.

#### Hyperliens
Un hyperlien est à exprimer par un tag <a>:

    <a href="http://localhost:4000/fr/pagex.html" target="_blank">Manuels</a>

Ne pas oublier target="_blank" sinon la page va s'ouvrir sur celle de l'application.

Toutefois si ce lien correspond à une page de manuel de la documentation de l'application, on utile la convention suivante:

    <a href="$$/pagex.html" target="_blank">Manuels</a>

Si la ligne commence exactement par `<a href="$$/` Le terme `$$` sera remplacé par l'URL de la documentation de l'application afin d'avoir une aide en ligne indépendante d'une localisation _en dur_.

Le fichier /public/etc/urls.json a cette forme:

    {
      "opurl" : "http://localhost:8443",
      "pubsuburl" : "http://localhost:8443",
      "docsurls" : { "fr-FR": "http://localhost:4000/fr", "en-EN": "http://localhost:4000/en"}
    }

Ce fichier est défini au déploiement, après _build_.

# GCP Functions
## Test local / debug
Auto-Attach: With Flag

Lancer en debug: npm run debug

    "debug" : "node --inspect node_modules/.bin/functions-framework --port=8443 --target=asocialGCF"

Lancer SANS debug: npm run start

    "start": "functions-framework --port=8443 --target=asocialGCF --signature-type=http"

.vscode/launch.json - Pas certain que ça serve, à revérifier

    {
      "version": "0.2.0",
      "configurations": [
        {
          "type": "node",
          "request": "attach",
          "name": "debug",
          "address": "localhost",
          "port": 9229
        }
      ]
    }


**Différence importante** pour le POST des opérations dans `cfgexpress.mjs` - `app.use('/op:operation ...)`
- Mode SRV: req.rawBody n'existe pas. On le construit depuis req.on
- Mode GCF: req.rawBody existe mais pas req.on

____________________________________________

## Deux structures possibles des Vue
### Structure _historique_

    <template>
      ...
    </template>

    <script>
      import { ref, computed } from 'vue'
      import BoutonHelp from '../components/BoutonHelp.vue'

    export default {
      name: 'ApercuChat',
      props: { chatc: Object },
      components: {  BoutonHelp ... },
      computed: {
        chat () { return this.aSt.getChat(this.chatc.id, this.chatc.ids) }
      },
      watch: {
        mod (ap) {
          console.log(this.idc2, mod)
        }
      },
      data () { return {
        txt: ''
      }},
      methods: {
        m1 (p) { ... }
      },
        
      setup (props) {
        const ui = stores.ui
        return { ui ... }
      }
    }
    </script>

    <style>
      /* This is where your CSS goes */
    </style>

C'est la structure employée presque partout, parce que historiquement celle préconisée.

### Nouvelle structure _simplifiée_ (API Composition Setup)
Voir `ApercuChat.vue`, `App.vue`

La nouvelle structure suivante est désormais préconisée. Elle est équivalente à la structure _historique_ mais offre des possibilités nouvelles intéressantes (comme la possibilité d'avoir des `await` dans le setup) et quelques simplifications, dont celle de ne plus se poser la question de ce qui se met en setup ou non. 

Toutefois l'inconvénient est que dans les fonctions du setup, les variables locales `myvar` doivent être référencées par `myvar.value` (au lieu de `this.myvar`), d'ailleurs il n'y a plus de `this`.

    <template>
      <my-component .../>
      <component :is="Foo" />
      <component :is="someCondition ? Foo : Bar" />
    </template>

    <script setup>
      import { capitalize } from './helpers'
      import { ref } from 'vue'
      import MyComponent from './MyComponent.vue'
      import Foo from './Foo.vue'
      import Bar from './Bar.vue'

      const props = defineProps({ foo: String }) // accessible par props.foo
      const emit = defineEmits(['change', 'delete'])
    </script>

    <style>
    /* This is where your CSS goes */
    </style>

Voir le détail ici : https://vuejs.org/api/sfc-script-setup.html

## `ref` et `computed` dans une vue

Dans une vue on peut afficher / traiter:
- **des variables de _store_** déclarées et gérées dans un store en tant que a) getters (éventuellement avec des paramètres ce qui est à peu près une _action_), ou b) actions. Ceci correspond à un état _global_ de la session, indépendant de toute vue.
- **des variables _locales_ à la vue** qui peuvent être déclarées, soit au _setup_, soit en _data_.

### Structure historique - Variable de _store_
Elle peut être déclarée à deux endroits:

    // Soit dans computed()
    computed: {
      chatX () { return this.aSt.getChat(this.chatc.id, this.chatc.ids) }
    }

    // Soit dans setup ()
    setup (props) {
      const chatc = toRef(props, 'chatc')
      const ui = stores.ui
      const aSt = stores.avatar
      const chatX = computed(() => aSt.getChat(chatc.value.id, chatc.value.ids))
      return { ui, aSt, chatX }

Les deux formulations sont équivalentes jusqu'à présent et fonctionnent: si des items sont ajoutés au _store_ depuis une action externe à la vue, ils sont bien répercutés à l'écran.

#### ref() NE RÉPERCUTE PAS la réactivité
Dans l'exemple précédent si on écrit:

    setup (props) {
      const chatc = toRef(props, 'chatc')
      const ui = stores.ui
      const aSt = stores.avatar
      const chatX = ref(aSt.getChat(chatc.value.id, chatc.value.ids))
      return { ui, aSt, chatX }

`chatX` n'est PAS réactif: quand le _store_ évolue, chatX reste inchangé.

**`ref()` rend réactive une variable locale mais ne transmet pas la réactivité de l'expression qui l'a initialisée.**

### Structure historique - Variables locales réactives
Elles peuvent être déclarées:

    // Soit dans data ()
    data () { return {
      vloc: 'toto'
    }}

    // Soit dans setup ()
    setup () {
      const vloc = ref('toto')
      return { vloc }
    }

Dans le premier cas, l'expression d'évaluation de `vloc` est limitée et ne peut utiliser que des constantes ou des variables déclarées dans setup.

Dans le second cas,
- l'expression peut utiliser tout ce qui est visible / déclaré dans `setup()`,
- la valeur peut être changée dans le code qui suit,
- dans le bloc `setup` la valeur est accédée par `vloc.value`.

### Variables locales initialisées depuis des variables de _store_
On peut vouloir créer une variable comme `vloc` qui aura sa propre vie MAIS dont la valeur initiale dépend d'une variable de _store_ **au moment de l'initialisation**. Typiquement on en a besoin pour pré-positionner une variable sur un élément initial du _store_ mais dont ensuite c'est le comportement de la vue qui la fait changer.

    setup () {
      const ui = stores.ui
      const aSt = stores.avatar
      const chatX = computed(() => aSt.getChat(ui.chatc.id, ui.chatc.ids))
      const nbci = ref(chatX.value.items.length)
      return { ui, aSt, chatX, nbci }

Ici `nbci` est le nombre d'items du chat à l'ouverture de la vue:
- quand le chat a des items en plus dans le store, `nbci` ne change pas,
- si dans la vue on change la valeur de `nbci`, ça se répercute à l'écran puisque c'est une variable reactive.

Dans ce cas, il FAUT que `chatX` soit déclarée par `computed` **dans le setup**, PAS dans la section computed: de la vue.

Si on avait voulu que `nbci` représente le nombre courant d'items on l'aurait déclaré:

    const nbci = computed(() => chatX.value.items.length)

mais sa valeur ne serait plus _affectable_ (c'est le résultat d'un calcul).

### Nouvelle structure
Les variables de store se déclarent par `computed()`

    const avatar = computed(() => aSt.getAvatar(props.id)) 

Les variables locales se déclarent par `ref()`

    const myVar = ref(3)
