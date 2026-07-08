{#

System-Helferkennzahlen fuer Durchschnittsalter.
Diese Kennzahlen sind additive Komponenten fuer Frontend-Metriken:

Durchschnittsalter = SUM([sys] Durchschnittsalter (Zähler))
                  / NULLIF(SUM([sys] Durchschnittsalter (Nenner)), 0)

#}

with

    kennz_basis as (select * from {{ ref("int_pystatis__basis_gesammelt") }}),

    einwohner_je_geschlecht as (
        select
            code_kreis,
            code_stichtag,
            code_geschlecht,
            sum(fact_kennzahl) as fact_einwohner,
            sum(fact_kennzahl_vorjahr) as fact_einwohner_vorjahr
        from kennz_basis
        where
            code_kennzahl = 'Anzahl Einwohner:innen'
            and code_altersgruppe is not null
        group by
            code_kreis,
            code_stichtag,
            code_geschlecht
    ),

    durchschnittsalter as (
        select
            code_kreis,
            code_stichtag,
            code_geschlecht,
            fact_kennzahl as fact_durchschnittsalter,
            fact_kennzahl_vorjahr as fact_durchschnittsalter_vorjahr
        from kennz_basis
        where code_kennzahl = 'Durchschnittsalter'
    ),

    helper_Zähler as (
        select
            '[sys] Durchschnittsalter (Zähler)' as code_kennzahl,
            durchschnittsalter.code_kreis,
            durchschnittsalter.code_stichtag,
            durchschnittsalter.code_geschlecht,
            null as code_altersgruppe,
            null as code_altersgruppe_1,
            null as code_altersgruppe_2,
            durchschnittsalter.fact_durchschnittsalter * einwohner_je_geschlecht.fact_einwohner as fact_kennzahl,
            durchschnittsalter.fact_durchschnittsalter_vorjahr * einwohner_je_geschlecht.fact_einwohner_vorjahr as fact_kennzahl_vorjahr
        from durchschnittsalter
        inner join
            einwohner_je_geschlecht
            on durchschnittsalter.code_stichtag = einwohner_je_geschlecht.code_stichtag
            and durchschnittsalter.code_kreis = einwohner_je_geschlecht.code_kreis
            and durchschnittsalter.code_geschlecht = einwohner_je_geschlecht.code_geschlecht
    ),

    helper_nenner as (
        select
            '[sys] Durchschnittsalter (Nenner)' as code_kennzahl,
            code_kreis,
            code_stichtag,
            code_geschlecht,
            null as code_altersgruppe,
            null as code_altersgruppe_1,
            null as code_altersgruppe_2,
            fact_einwohner as fact_kennzahl,
            fact_einwohner_vorjahr as fact_kennzahl_vorjahr
        from einwohner_je_geschlecht
    )

select *
from helper_Zähler
union all
select *
from helper_nenner
