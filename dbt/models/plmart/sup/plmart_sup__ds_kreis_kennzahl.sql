{#

Nicht-pivotisierte Sicht der Kennzahlen.

# Notizen
- Baut sehr nah auf `fact_kennzahl` auf.
- Kennzahlen werden als Dimension geführt (unpivotisiert, mit zweiter Spalte `Wert`)
- Es werden nur Kennzahlen mitgenommen, die direkt summiert werden können
  (siehe benachbartes Modell `kennzahl_pivot`)
- Ergänzt GeoJSON Polygone aus `dim_kreis` um Karten-Ansichten zu ermöglichen
- Benennt Spalten um, von technischer Sicht (dbt) zu user-facing und lesbar (Superset)
- Bereitet weitere Datums-Formate aus der Stichtag-Spalte auf

#}

{% set kennzahlen = [
    "Gebietsfläche",
    "Anzahl Einwohner:innen",
    "Sterbefälle",
    "Lebendgeburten",
    "Fortzüge",
    "Zuzüge",
    "Wanderung",
] %}
{# we could use dbt_utils.get_column_values(), but this is readable and gives control #}

{{ log_info('Kennzahlen für non-pivot:\n\t' ~kennzahlen | join('\n\t')) }}

with
    dim_kreis     as ( select * from {{ ref("mart__dim_kreis") }} ),
    fact_kennzahl as ( select * from {{ ref("mart__fact_kennzahl") }} ),

    casted as (
        select
            fact_kennzahl.code_kennzahl                as "Kennzahl",
            cast(fact_kennzahl.code_stichtag as date)  as "Stichtag",
            -- Das casting zu Date erlaubt bessere Formattierung in Superset
            fact_kennzahl.code_geschlecht              as "Geschlecht",
            fact_kennzahl.code_altersgruppe_18_65      as "Altersgruppe",
            fact_kennzahl.code_altersgruppe_grob       as "Altersgruppe grob",
            dim_kreis.code_kreis                       as "Kreis Code",
            dim_kreis.desc_kreis_name                  as "Kreis Bezeichnung",
            concat(dim_kreis.code_kreis, ' ', dim_kreis.desc_kreis_name) as "Kreis",
            dim_kreis.fact_geojson                     as "Kreis GeoJson",
            -- TODO: deck.gl polygon Chart type might have issues with null as GeoJson
            fact_kennzahl.fact_kennzahl                as "Wert",
            fact_kennzahl.fact_kennzahl_vorjahr        as "Wert Vorjahr",
        from
            fact_kennzahl
        left join
            dim_kreis on fact_kennzahl.code_kreis = dim_kreis.code_kreis
        where
            code_kennzahl  in ({{ "'" ~ (kennzahlen | join("', '")) ~ "'" }})
    ),

    time_cols as (
        select
            *,
            -- Wir wollen Jahres- und Monats-Filter in Superset.
            -- Filter können derzeit nicht auf Metriken zugreifen, daher müssen
            -- wir echte Spalten anlegen.
            cast(date_part('month', "Stichtag") as integer) as "Monat",
            cast(date_part('year', "Stichtag") as integer) as "Jahr",

        from casted

    ),

    final as (
        select
            *,
            case "Monat"
                when  1 then '01 Januar'
                when  2 then '02 Februar'
                when  3 then '03 März'
                when  4 then '04 April'
                when  5 then '05 Mai'
                when  6 then '06 Juni'
                when  7 then '07 Juli'
                when  8 then '08 August'
                when  9 then '09 Sepember'
                when 10 then '10 Oktober'
                when 11 then '11 November'
                when 12 then '12 Dezember'
            end as "Monat Bezeichnung"
        from time_cols
    )

select *
from final
