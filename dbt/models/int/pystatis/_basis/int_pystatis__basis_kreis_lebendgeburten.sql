{#

Kennzahl Lebendgeburten

Je Zeile: Kreis, Dimensionen, und Anzahl Lebendgeburten.

#}

with
    kreis_lebendgeburten as (select * from {{ ref('stg_pystatis__kreis_lebendgeburten') }}),

    final as (
        select
            'Lebendgeburten' as code_kennzahl,
            code_kreis,
            code_stichtag,
            code_geschlecht,
            null as code_altersgruppe_18_65,
            fact_count_lebendgeborene as fact_kennzahl
        from
            kreis_lebendgeburten
    )

select *
from final
