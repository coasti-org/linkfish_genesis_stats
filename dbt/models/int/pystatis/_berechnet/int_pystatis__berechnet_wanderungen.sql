{#

Berechnete Wanderungskennzahl (Nettowanderung)

Je Zeile: Kreis, Dimensionen, und eine Nettowanderung.
Nettowanderung = Zuzüge − Fortzüge

#}

with

    kennz_basis as (select * from {{ ref("int_pystatis__basis_gesammelt") }}),

    zuzuege as (
        select *
        from kennz_basis
        where code_kennzahl = 'Zuzüge'
    ),

    fortzuege as (
        select *
        from kennz_basis
        where code_kennzahl = 'Fortzüge'
    ),

    kennzahl as (
        select
            'Wanderung' as code_kennzahl,
            zuzuege.code_kreis,
            zuzuege.code_stichtag,
            zuzuege.code_geschlecht,
            null as code_altersgruppe,
            null as code_altersgruppe_1,
            null as code_altersgruppe_2,
            sum(zuzuege.fact_kennzahl) - sum(fortzuege.fact_kennzahl) as fact_kennzahl
        from zuzuege
        inner join
            fortzuege
            on zuzuege.code_stichtag = fortzuege.code_stichtag
            and zuzuege.code_kreis = fortzuege.code_kreis
            and zuzuege.code_geschlecht = fortzuege.code_geschlecht
        group by all
    ),

    kennzahl_lag as (
        select
            *,
            lag(fact_kennzahl) over (
                partition by
                    code_kennzahl, code_kreis, code_geschlecht, code_altersgruppe
                order by code_stichtag
            ) as fact_kennzahl_vorjahr
        from kennzahl
    )

select *
from kennzahl_lag
