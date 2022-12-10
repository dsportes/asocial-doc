@@Index général de la documentation - [index](./index.md)

# Mots clés : index, nom et catégorie

Un mot clé a un **index** et un **nom** :
- **l'index** identifie le mot clé et qui l'a défini :
  - un index de 1 à 99 est un mot clé personnel d'un compte.
  - un index de 100 à 199 est un mot clé défini pour **un** groupe.
  - un index de 200 à 255 est un mot clé défini par l'application et enregistré dans sa configuration (donc _peu_ modifiable).
- **le nom** est un texte unique dans l'ensemble des mots clés du définissant : deux mots clés d'un compte, d'un groupe ou de l'organisation ne peuvent pas avoir un même nom. 
  - le nom est court et peut contenir des caractères émojis en particulier comme premier caractère.
  - l'affichage _réduit_ ne montre que le premier caractère si c'est un émoji, sinon les deux premiers.

>Ce sont les noms qui confèrent une signification au mot clé : 49 par exemple ne signifie rien, son nom _Rock_ a un sens. Les noms sont toujours cryptés, soit par la clé K d'un compte pour les mots clés personnels, soit par la clé d'un groupe. Les significations réelles des mots clés sont donc cryptées (sauf pour ceux de l'application).

## Les mots clés s'appliquent ...
#### A un secret
Chaque avatar accédant à un secret peut lui attacher les mots clés de son choix :
- ceux personnels,
- ceux de l'application,
- si c'est un secret partagé dans un groupe, ceux du groupe du secret.

Pour un secret partagé dans un groupe, l'animateur peut attacher des mots clés au secret:
- ceux de l'application,
- si c'est un secret partagé dans un groupe, ceux du groupe du secret.

#### Aux groupes
Chaque avatar membre d'un groupe peut attacher au groupe des mots clés  de son choix :
- ceux personnels,
- ceux de l'application,

Il peut ainsi obtenir des listes de groupes ayant ou n'ayant pas dans sa liste de mots clés, ceux qu'il choisit (par exemple tous ceux ayant _Rock_ ou _Jazz_ MAIS PAS _Poubelle_).

#### Aux contacts
Chaque avatar peut attacher à un contact des mots clés  de son choix :
- ceux personnels,
- ceux de l'application,

#### Aux membres des groupes
Chaque membre d'un groupe peut attacher au groupe des mots clés  de son choix :
- ceux personnels,
- ceux de l'application,

Il peut ainsi obtenir des listes de contacts ayant ou n'ayant pas dans sa liste de mots clés, ceux qu'il choisit (par exemple tous ceux ayant _Musicien_ MAIS PAS _Liste noire_).

## Catégories de mots clés
Afin de faciliter le choix des mots clés d'un critère de sélection, ceux-ci sont présentés à l'écran **regroupés par _catégorie_**. Chaque mot clé a une _catégorie_ donnée avec son nom :
- la catégorie est un mot court : par exemple _Statut_, _Thème_, _Projet_, _Section_
- la catégorie ne fait pas partie du nom : elle est donnée à la définition / mise à jour du mot clé mais reste externe.
- il n'y a pas de catégories prédéfinies : toutefois les mots clés de l'application ont une catégorie (rien n'empêche un compte d'utiliser ces mots).

#### Mots clés _obsolètes_
Un mot clé _obsolète_ est un mot clé sans catégorie :
- son attribution est interdite.
- la suppression d'un mot clé ne s'opère que sur un mot clé obsolète. Opération à n'effectuer qu'avec prudence, surtout si on réutilise le numéro qui peut figurer dans des listes attachées aux secrets, groupes et contacts.

## Mots clé de l'application

  "motscles_fr-FR": { 
    "255": "Statut/Nouveau",
    "254": "Visibilité/Liste noire",
    "253": "Compte/Parrain",
    "252": "Compte/Filleul",
    "251": "Visibilité/Favori",
    "250": "Visibilité/Important",
    "249": "Visibilité/Obsolète",
    "248": "Visibilité/A lire",
    "247": "Visibilité/A traiter",
    "246": "Visibilité/Poubelle"
  }

Ceci est la liste _en français_ mais la même liste est configurée dans la ou les autres langues déployées.

#### Liste de mots clés
C'est la liste de leurs index, pas de leurs noms : il est ainsi possible de corriger le nom d'un mot clé et toutes ses références s'afficheront avec le nouveau nom rectifié.
- un index n'est présent qu'une fois.
- l'ordre n'a pas d'importance.
- les mots clés d'index 1 à 99 sont toujours ceux du compte qui les regardent. 
- ceux d'index de 200 à 255 sont toujours ceux de l'organisation.
- ceux d'index de 100 à 199 ne peuvent être attachés qu'à un secret de groupe, leur signification est interprétée vis à vis du groupe détenteur du secret.

> **Remarque** : deux mots clé d'un compte et d'un groupe peuvent porter le même nom (voire d'ailleurs un mot clé de l'organisation). L'origine du mot clé est distinguée à l'affichage en lisant son code.
