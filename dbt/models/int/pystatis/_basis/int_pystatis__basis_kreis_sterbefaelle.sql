{#

Kennzahl Sterbefaelle

Je Zeile: Kreis, Dimensionen, und Anzahl Sterbefaelle.

#}

with
    kreis_sterbefaelle as (select * from {{ ref('stg_pystatis__kreis_sterbefaelle') }}),

    final as (
        select
            'Sterbefälle' as code_kennzahl,
            code_kreis,
            code_stichtag,
            code_geschlecht,
            null as code_altersgruppe_18_65,
            fact_count_gestorbene as fact_kennzahl
        from
            kreis_sterbefaelle
    )

select *
from final
