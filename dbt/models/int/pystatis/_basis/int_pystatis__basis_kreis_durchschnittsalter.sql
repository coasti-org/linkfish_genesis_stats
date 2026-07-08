{#

Kennzahl Durchschnittsalter

Je Zeile: Kreis, Dimensionen, und Durchschnittsalter.

#}

with
    kreis_durchschnittsalter as (select * from {{ ref('stg_pystatis__kreis_durchschnittsalter') }}),

    final as (
        select
            'Durchschnittsalter' as code_kennzahl,
            code_kreis,
            code_stichtag,
            code_geschlecht,
            null as code_altersgruppe,
            fact_alter_durchschnitt as fact_kennzahl
        from
            kreis_durchschnittsalter
    )

select *
from final
