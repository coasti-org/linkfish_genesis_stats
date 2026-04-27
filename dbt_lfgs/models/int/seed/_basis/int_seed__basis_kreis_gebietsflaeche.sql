{#

Kennzahl Gebietsfläche

Je Zeile: Kreis, Dimensionen, Polygon, und Gebietsfläche

Alle Tabellen der Kennzahlen sollen später aneinander gereiht werden (union).
Daher müssen immer die selben Spalten vorhanden sein, aber können Null enthalten.

Hier wird nicht mehr gecastet, das sollte komplett im Staging passieren.

TODO: @JB Entscheiden ob wir _kennzahl brauchen
#}


with
    kreis_gebietsflaeche as (select * from {{ ref('stg_seed__kreis_gebietsflaeche') }}),

    final as (
        select
            'Gebietsfläche (Kreis)' as code_kennzahl,
            code_kreis,
            code_stichtag,
            null as code_geschlecht,
            null as code_altersgruppe,
            fact_flaeche as Wert
        from
            kreis_gebietsflaeche
    )

select *
from final
