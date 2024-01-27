## Mots clés de la configuration : traductions

## Traductions
- components

## Couple et groupe
- détection de la disparition d'un membre / conjoint : opération de MAJ du serveur.
- vérifier extension / réduction du volume max

## Contact
- suppression : à réviser (cv.x à 1)
- vérifier que A et C ne peuvent pas valider deux contacts symétriques.
- maj du contact quotas contact et compte, ardoise, ne pas m'inviter en état attente / hors délai (avec prolongation) ???

## Rencontre / parrainage
- vérifier suppression, prolongation, refus
- vérifier refus parrainage
- rencontre : A1 découvre que A0 est déjà contact ? chelou, le nom de A1 peut être détecté par A0 au moment de la demande de rencontre. Refus de A1 (ou non)
- vérifier la pertinence du booléen - `parrain` : vrai si parrain dans un `contact`

## Suppression d'un avatar (volontairement) : 
- groupes hébergés : terminer l'hébergement.
- récupérer l'espace pour le compte.
- panel de progression : retrait des couples, retrait des groupes, suppression des secrets
- suppression sauf primitif
- suppression primitif = suppression compte

## Affichage compta avatar(s)
- à compléter (historique)

## Ralentissement de download

## Textes et pièces jointes en attente en mode avion

## Démons serveur
- quotidiens
  - détection des disparus
  - détection des groupes sans hébergement, disparition
  - gestion des suppressions
- scan des fichiers orphelins

## Documentation
- rubriques techniques: signatures et gestion des disparitions

## Conversion de MD en HTML

  yarn add showdown

- le fichier md.css contient le CSS
- le résultat est un HTML de base mais bien formé.

    node md2html.js README
    
    (SANS extension .md)
