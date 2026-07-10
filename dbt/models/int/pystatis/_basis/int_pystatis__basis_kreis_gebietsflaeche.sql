{#

Kennzahl Gebietsfläche

Je Zeile: Kreis, Dimensionen, und Gebietsfläche

#}


with
    kreis_gebietsflaeche as (select * from {{ ref('stg_pystatis__kreis_gebietsflaeche') }}),

    final as (
        select
            'Gebietsfläche' as code_kennzahl,
            code_kreis,
            code_stichtag,
            null as code_geschlecht,
            null as code_altersgruppe_18_65,
            fact_flaeche as fact_kennzahl
        from
            kreis_gebietsflaeche
    )

select *
from final
