{#

Kennzahlen Wanderungen

Je Zeile: Kreis, Dimensionen, und eine Wanderungskennzahl.

#}

with
    kreis_wanderungen as (
        select *
        from {{ ref('stg_pystatis__kreis_wanderungen') }}
        where code_altersgruppe_18_65 = 'Insgesamt'
    ),

    final as (
        select
            'Fortzüge (Kreis)' as code_kennzahl,
            code_kreis,
            code_stichtag,
            code_geschlecht,
            {# code_altersgruppe_18_65 as code_altersgruppe, #}
            null as code_altersgruppe,
            fact_count_fortzuege as fact_kennzahl
        from
            kreis_wanderungen

        union all

        select
            'Zuzüge (Kreis)' as code_kennzahl,
            code_kreis,
            code_stichtag,
            code_geschlecht,
            {# code_altersgruppe_18_65 as code_altersgruppe, #}
            null as code_altersgruppe,
            fact_count_zuzuege as fact_kennzahl
        from
            kreis_wanderungen
    )

select *
from final
