{#


Notiz:
- In der Geschlechts-Spalte können m/w und 'insgesamt' vorkommen.
- Wir filtern 'insgesamt', da dies nur redundante Information ist, und __keine__
  Informationen zu Personen diversen Geschlechts.
  Historisch werden in der Gestatis Datenbank Personen diversen Geschlechts zufällig
  auf m und w umverteilt.
#}

select
    code_stichtag,
    code_ags as code_kreis,
    desc_ags as desc_kreis,
    code_geschlecht as code_geschlecht,
    {# TODO: Falls relevant: Wie verschieden gestaffelte Altersgruppen aufeinander mappen? #}
    code_altersgruppe_3_75 as code_altersgruppe_3_75,
    cast(fact_count_bevoelkerungsstand as {{ dbt.type_int() }}) as fact_count_bevoelkerungsstand,
from 
    {{ ref("seed__kreis_12411_02_03_4_anzahl_einwohner") }}
where
    lower(code_geschlecht) != 'insgesamt'
    {# Standardmäßig ist in allen SQL Backends Collation aus, sodass string-Vergleiche
    case-insensitive sind. Good practice ist aber, sicherzugehen. #}