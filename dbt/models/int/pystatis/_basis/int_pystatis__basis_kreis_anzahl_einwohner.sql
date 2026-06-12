{#

Kennzahl Anzahl Einwohner:innen (Kreis)

Je Zeile: Kreis, Dimensionen, und Anzahl Einwohner:innen.

#}

with
    kreis_einwohner as (select * from {{ ref('stg_pystatis__kreis_anzahl_einwohner') }}),

    final as (
        select
            'Anzahl Einwohner:innen (Kreis)' as code_kennzahl,
            code_kreis,
            code_stichtag,
            code_geschlecht,
            code_altersgruppe_3_75 as code_altersgruppe,
            fact_count_bevoelkerungsstand as fact_kennzahl
        from
            kreis_einwohner
    )

select *
from final
