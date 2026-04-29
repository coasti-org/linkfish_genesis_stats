{#

Kennzahl Sterbefaelle

Je Zeile: Kreis, Dimensionen, und Anzahl Sterbefaelle.

#}

with
    kreis_sterbefaelle as (select * from {{ ref('stg_seed__kreis_sterbefaelle') }}),

    final as (
        select
            'Sterbefälle (Kreis)' as code_kennzahl,
            code_kreis,
            code_stichtag,
            code_geschlecht,
            null as code_altersgruppe,
            fact_count_gestorbene as fact_kennzahl
        from
            kreis_sterbefaelle
    )

select *
from final
