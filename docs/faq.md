# FAQ


## DBT

- why profiles not in the default, next to dbt_project?
- why schema names chosen that strikt (and weird way?)
- why plmart and not pl? (well, superset might require intermediate steps)

- Warum Produkt ID in diesem Format?
  - Es geht nicht um Struktur, daher z.b. keine UTIs. IDs können einfache Strings sein. Wir wollen nur, dass Produkte eindeutig sind.
  - Daher: begrenzen wir uns auf Aspekte die in Python- und dbt-Projekten erlaubt sind, und geben eine Empfehlung.
  - dbt- und Python-Module leiten sich davon ab und ersetzen `_` bei Bedarf durch `-`.
