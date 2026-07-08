{#

Kennzahlen Wanderungen

Je Zeile: Kreis, Dimensionen, und eine Wanderungskennzahl.

#}

with
    kreis_wanderungen as (select * from {{ ref('stg_pystatis__kreis_wanderungen') }}),

    final as (
        select
            'Fortzüge' as code_kennzahl,
            code_kreis,
            code_stichtag,
            code_geschlecht,
            code_altersgruppe_18_65,
            fact_count_fortzuege as fact_kennzahl
        from
            kreis_wanderungen

        union all

        select
            'Zuzüge' as code_kennzahl,
            code_kreis,
            code_stichtag,
            code_geschlecht,
            code_altersgruppe_18_65,
            fact_count_zuzuege as fact_kennzahl
        from
            kreis_wanderungen

        union all

        select
            'Wanderung' as code_kennzahl,
            code_kreis,
            code_stichtag,
            code_geschlecht,
            code_altersgruppe_18_65,
            fact_count_zuzuege - fact_count_fortzuege as fact_kennzahl
        from
            kreis_wanderungen
    )

select *
from final
