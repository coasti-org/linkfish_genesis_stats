{#

Kennzahl Anzahl Einwohner:innen (Kreis)

Je Zeile: Kreis, Dimensionen, und Anzahl Einwohner:innen.

#}

with
    kreis_einwohner as (select * from {{ ref('stg_pystatis__kreis_anzahl_einwohner') }}),
    altersgruppen   as (select * from {{ ref('seed__altersgruppen') }}),

    final as (
        select
            'Anzahl Einwohner:innen' as code_kennzahl,
            kreis_einwohner.code_kreis,
            kreis_einwohner.code_stichtag,
            kreis_einwohner.code_geschlecht,
            altersgruppen.code_altersgruppe_18_65,
            sum(kreis_einwohner.fact_count_bevoelkerungsstand) as fact_kennzahl
        from
            kreis_einwohner
        left join
            altersgruppen
            on kreis_einwohner.code_altersgruppe_3_75 = altersgruppen.code_altersgruppe_3_75
        group by
            kreis_einwohner.code_kreis,
            kreis_einwohner.code_stichtag,
            kreis_einwohner.code_geschlecht,
            altersgruppen.code_altersgruppe_18_65
    )

select *
from final
