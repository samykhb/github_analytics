# github_analytics
TP dbt - Data Engineering Foundations

# Justification des stratégies incrémentales

## Commits

Un commit est par nature un événement immuable dans Git : s'il est modifié d'une quelconque manière, son identifiant unique (le sha) change, ce qui en fait techniquement un tout nouveau commit. Par conséquent, les anciennes lignes de notre base ne nécessiteront jamais de mise à jour. Pour le modèle stg_commits.sql, la stratégie la plus pertinente est donc append.

## Issues

Contrairement aux commits, une issue possède un cycle de vie et son état est mutable : elle peut passer de "open" à "closed". Si l'on utilisait une simple stratégie d'ajout (append), on créerait inévitablement des doublons (une ligne pour l'état ouvert, et une nouvelle pour l'état fermé). Pour le modèle stg_issues.sql, il est donc impératif d'utiliser la stratégie merge (ou delete+insert). Cette approche permet de mettre à jour la ligne existante si l'état a changé. Pour fonctionner, dbt exige la définition d'une clé d'unicité (unique_key)  qui permet d'identifier quelle ligne écraser — dans notre cas, il s'agit de la combinaison du dépôt (repo_id) et du numéro de l'issue (issue_number).


## Pourquoi ne pas rendre la couche Gold incrémentale ?

Il est très risqué et techniquement complexe de rendre la couche Gold incrémentale. Cette couche finale est constituée d'agrégations (sommes, moyennes) et de calculs basés sur des fenêtres temporelles (comme l'activité des 30 derniers jours). Si le pipeline se contentait d'ajouter les données du jour, les totaux globaux et les moyennes des fenêtres glissantes ne seraient pas recalculés, rendant les indicateurs métier complètement faux. C'est pourquoi, à moins d'utiliser des architectures très avancées, la couche Gold reste matérialisée en table standard (en Full Refresh), garantissant ainsi que tous les scores et classements sont recalculés de zéro à chaque exécution.
