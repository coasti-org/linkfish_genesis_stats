{#

Erzeuge Helfer Kennzahlen für Durchschnittsalter ([sys])

Die meisten Frontend-Charts nehmen addierbare Kennzahlen an (Euros).
Wenn diese Summen gewichtet oder normiert werden sollen, müssen wir eigens eine
Metrik anlegen, damit Filter berückstichtigt werden können.

Zum Erzeugen der Metriken müssen wir die addierbaren Teile als eigene Spalten mitnehmen.

Als Frontend-Metrik ergibt sich dann:
```sql
Durchschnittsalter = sum("[sys] Durchschnittsalter (Zähler)")
            / nullif(sum("[sys] Durchschnittsalter (Nenner)"), 0)
```
#}

with

    kennz_basis as (select * from {{ ref("int_pystatis__basis_gesammelt") }}),

    einwohner_je_geschlecht as (
        select
            code_kreis,
            code_stichtag,
            code_geschlecht,
            sum(fact_kennzahl) as fact_ew,
            sum(fact_kennzahl_vorjahr) as fact_ew_vorjahr
        from kennz_basis
        where
            code_kennzahl = 'Anzahl Einwohner:innen'
            and code_altersgruppe_18_65 is not null
        group by code_kreis, code_stichtag, code_geschlecht
    ),

    durchschnittsalter as (
        select
            code_kreis,
            code_stichtag,
            code_geschlecht,
            fact_kennzahl as fact_da,
            fact_kennzahl_vorjahr as fact_da_vorjahr
        from kennz_basis
        where code_kennzahl = 'Durchschnittsalter'
    ),

    zaehler as (
        select
            '[sys] Durchschnittsalter (Zähler)' as code_kennzahl,
            durchschnittsalter.code_kreis,
            durchschnittsalter.code_stichtag,
            durchschnittsalter.code_geschlecht,
            null as code_altersgruppe_18_65,
            null as code_altersgruppe_grob,
            durchschnittsalter.fact_da
            * einwohner_je_geschlecht.fact_ew as fact_kennzahl,
            durchschnittsalter.fact_da_vorjahr
            * einwohner_je_geschlecht.fact_ew_vorjahr as fact_kennzahl_vorjahr
        from durchschnittsalter
        inner join
            einwohner_je_geschlecht
            on durchschnittsalter.code_stichtag = einwohner_je_geschlecht.code_stichtag
            and durchschnittsalter.code_kreis = einwohner_je_geschlecht.code_kreis
            and durchschnittsalter.code_geschlecht = einwohner_je_geschlecht.code_geschlecht
    ),

    nenner as (
        select
            '[sys] Durchschnittsalter (Nenner)' as code_kennzahl,
            code_kreis,
            code_stichtag,
            code_geschlecht,
            null as code_altersgruppe_18_65,
            null as code_altersgruppe_grob,
            fact_ew as fact_kennzahl,
            fact_ew_vorjahr as fact_kennzahl_vorjahr
        from einwohner_je_geschlecht
    )

select *
from zaehler

union all

select *
from nenner
