{#
Notizen:
- In der Geschlechts-Spalte können m/w und 'insgesamt' vorkommen.
- Wir filtern 'insgesamt', da dies nur redundante Information ist, und __keine__
  Informationen zu Personen diversen Geschlechts.
  Historisch werden in der Gestatis Datenbank Personen diversen Geschlechts zufällig
  auf m und w umverteilt.
#}

with casted as (
    select
        cast(code_stichtag                 as {{ dbt.type_string() }}) as code_stichtag,
        cast(code_ags                      as {{ dbt.type_string() }}) as code_ags,
        cast(desc_ags                      as {{ dbt.type_string() }}) as desc_ags,
        cast(code_geschlecht               as {{ dbt.type_string() }}) as code_geschlecht,
        cast(code_altersgruppe_3_75        as {{ dbt.type_string() }}) as code_altersgruppe_3_75,
        cast(fact_count_bevoelkerungsstand as {{ dbt.type_int() }})    as fact_count_bevoelkerungsstand
    from
        {{ ref("seed__kreis_12411_02_03_4_anzahl_einwohner") }}
),

{# Renaming, leiche transformationen und filter erfolgen nach dem Casting #}
final as (
    select
        left(code_stichtag, 4) as code_jahr,
        code_stichtag,
        code_ags as code_kreis,
        desc_ags as desc_kreis,
        code_geschlecht,
        code_altersgruppe_3_75,
        fact_count_bevoelkerungsstand
    from
        casted
    where
        lower(code_geschlecht) != 'insgesamt'
        /* wir haben bereits die einzelnen Altersgruppierungen, daher wird "insgesamt" herausgefiltert: */
        and lower(code_altersgruppe_3_75) != 'insgesamt' 
        {# Standardmäßig ist in allen SQL Backends Collation aus, sodass string-Vergleiche
        case-insensitive sind. Good practice ist aber, sicherzugehen. #}
        and len(code_ags) == 5
        {# Kreise haben 5-stellige AGS codes. (Bundesland: 2-stellig, Gemeinde: ~ 8 #}
)

select *
from final
