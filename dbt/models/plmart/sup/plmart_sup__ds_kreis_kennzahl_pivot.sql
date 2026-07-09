{#

Pivotisierte Sicht der Kennzahlen.

# Notizen
- Gleiche Transformationen wie `ds_kreis_kennzahl`, aber zusätzlich:
- Pivotisierung der Kennzahlen, sodass jede Kennzahl als eigene Spalte auftaucht.
  Dies ermöglich in Superset Metriken zu erstellen, die pro Zeile Berechnungen anstellen.
  Dies wiederum ermöglicht, dass Filter einfließen, und nicht-additive Metriken trotzdem
  richtig berechnet werden (z.b. Durchschnittsalter)
- Dafür nehmen wir auch Kennzahlen mit, die als Helfern berechnet werden ([sys])

#}

{% set kennzahlen = [
    "Gebietsfläche",
    "Anzahl Einwohner:innen",
    "Sterbefälle",
    "Lebendgeburten",
    "Fortzüge",
    "Zuzüge",
    "Wanderung",
    "[sys] Durchschnittsalter (Zähler)",
    "[sys] Durchschnittsalter (Nenner)",
    "[sys] Altenquotient (Zähler)",
    "[sys] Altenquotient (Nenner)",
] %}
{# we could use dbt_utils.get_column_values(), but this is readable and gives control #}

{{ log_info('Kennzahlen für pivot:\n\t' ~kennzahlen | join('\n\t')) }}


with
    dim_kreis as ( select * from {{ ref("mart__dim_kreis") }} ),
    fact_kennzahl as ( select * from {{ ref("mart__fact_kennzahl") }} ),

    pivot_human_readable as (
        select
            -- Umbenennen, in Superset tauchen Spalten direkt im Frontend auf
            -- Das Casting zu Date erlaubt bessere Formattierung in Superset
            cast(fact_kennzahl.code_stichtag as date)  as "Stichtag",
            fact_kennzahl.code_geschlecht              as "Geschlecht",
            fact_kennzahl.code_altersgruppe_18_65      as "Altersgruppe",
            fact_kennzahl.code_altersgruppe_grob       as "Altersgruppe grob",
            fact_kennzahl.code_kreis                   as "Kreis Code",

            -- Kennzahlen pivot, damit wir berechnete Kennzahlen als Metriken
            -- im Frontend darstellen können
            -- null als else_value ist wichtig, da wir sonst im Frontend Non-Sum
            -- Aggregations-Metriken falsch berechnen.
            {{ dbt_utils.pivot(
                column='code_kennzahl',
                values=kennzahlen,
                agg='sum',
                then_value='fact_kennzahl',
                else_value='null',
                prefix='',
                suffix='',
                alias=True,
                quote_identifiers=True
            ) }},

            {{ dbt_utils.pivot(
                column='code_kennzahl',
                values=kennzahlen,
                agg='sum',
                then_value='fact_kennzahl_vorjahr',
                else_value='null',
                prefix='',
                suffix=' (Vorjahr)',
                alias=True,
                quote_identifiers=True
            ) }}

        from
            fact_kennzahl
        group by
            code_stichtag,
            code_geschlecht,
            code_altersgruppe_18_65,
            code_altersgruppe_grob,
            code_kreis
    ),

    time_cols as (
        select
            *,
            cast(date_part('month', "Stichtag") as integer)  as "Monat",
            cast(date_part('year', "Stichtag") as integer)   as "Jahr"
            -- Wir wollen Jahres- und Monats-Filter in Superset.
            -- Filter können derzeit nicht auf Metriken zugreifen, daher müssen
            -- wir echte Spalten anlegen.
        from pivot_human_readable
    ),

    time_cols_fixed as (
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
                when  9 then '09 September'
                when 10 then '10 Oktober'
                when 11 then '11 November'
                when 12 then '12 Dezember'
            end as "Monat Bezeichnung"
        from time_cols
    ),

    with_kreis as (
        select
            time_cols_fixed.*,
            concat(dim_kreis.code_kreis, ' ', dim_kreis.desc_kreis_name) as "Kreis",
            dim_kreis.desc_kreis_name            as "Kreis Bezeichnung",
            dim_kreis.fact_geojson               as "Kreis GeoJson"
        from
            time_cols_fixed
        left join
            dim_kreis on time_cols_fixed."Kreis Code" = dim_kreis.code_kreis
    )

select *
from with_kreis
