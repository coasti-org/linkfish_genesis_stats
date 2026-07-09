{#

Erzeuge Helfer Kennzahlen für Altenquotient ([sys])

Der Altenquotient ist: (65+ Bevölkerung / 18-64 Bevölkerung) * 100

Zum Erzeugen der Metriken müssen wir die addierbaren Teile als eigene Spalten
mitnehmen, damit Filter in Superset berücksichtigt werden können.
(Für den Altenquotient bisher nur Geschlecht)

Als Frontend-Metrik ergibt sich dann:
```sql
Altenquotient = sum("[sys] Altenquotient (Zähler)")
       / nullif(sum("[sys] Altenquotient (Nenner)"), 0)
       * 100
```
#}

with

    kennz_basis as (select * from {{ ref("int_pystatis__basis_gesammelt") }}),

    einwohner_65plus as (
        select
            '[sys] Altenquotient (Zähler)' as code_kennzahl,
            code_kreis,
            code_stichtag,
            code_geschlecht,
            null as code_altersgruppe_18_65,
            null as code_altersgruppe_grob,
            sum(fact_kennzahl) as fact_kennzahl,
            sum(fact_kennzahl_vorjahr) as fact_kennzahl_vorjahr
        from kennz_basis
        where
            code_kennzahl = 'Anzahl Einwohner:innen'
            and code_altersgruppe_grob = '65+'
        group by code_kreis, code_stichtag, code_geschlecht
    ),

    einwohner_18_64 as (
        select
            '[sys] Altenquotient (Nenner)' as code_kennzahl,
            code_kreis,
            code_stichtag,
            code_geschlecht,
            null as code_altersgruppe_18_65,
            null as code_altersgruppe_grob,
            sum(fact_kennzahl) as fact_kennzahl,
            sum(fact_kennzahl_vorjahr) as fact_kennzahl_vorjahr
        from kennz_basis
        where
            code_kennzahl = 'Anzahl Einwohner:innen'
            and code_altersgruppe_grob = '18-64'
        group by code_kreis, code_stichtag, code_geschlecht
    )

select *
from einwohner_65plus

union all

select *
from einwohner_18_64
