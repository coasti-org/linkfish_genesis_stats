{#

Kennzahlen Medianalter und Altenquotient

Je Zeile: Kreis, Dimensionen, und eine Kennzahl.

#}

with
    kreis_medianalter as (select * from {{ ref('stg_pystatis__kreis_medianalter') }}),

    final as (
        select
            'Medianalter' as code_kennzahl,
            code_kreis,
            code_stichtag,
            code_geschlecht,
            null as code_altersgruppe_18_65,
            fact_alter_median as fact_kennzahl
        from
            kreis_medianalter

        union all

        select
            'Altenquotient' as code_kennzahl,
            code_kreis,
            code_stichtag,
            code_geschlecht,
            null as code_altersgruppe_18_65,
            fact_altenquotient as fact_kennzahl
        from
            kreis_medianalter
    )

select *
from final
