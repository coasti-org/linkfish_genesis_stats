{#

Kennzahl Gebietsfläche

Je Zeile: Kreis, Dimensionen, und Gebietsfläche

Alle Tabellen der Kennzahlen sollen später aneinander gereiht werden (union).
Daher müssen immer die selben Spalten vorhanden sein, aber können Null enthalten.

Hier wird nicht mehr gecastet, das sollte komplett im Staging passieren.

#}


with
    kreis_gebietsflaeche as (select * from {{ ref('stg_pystatis__kreis_gebietsflaeche') }}),

    final as (
        select
            'Gebietsfläche' as code_kennzahl,
            code_kreis,
            code_stichtag,
            null as code_geschlecht,
            null as code_altersgruppe,
            fact_flaeche as fact_kennzahl
        from
            kreis_gebietsflaeche
    )

select *
from final
