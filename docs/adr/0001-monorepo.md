# 1. Monorepo
Contexte : Relais aura plusieurs services, une console et des libs dans d'autres langages.
Décision : un seul dépôt (services/, console/, packages/) et un compose.yaml à la racine.
Conséquences : changements transverses atomiques, CI à découper par dossier plus tard.