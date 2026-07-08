with

    kennz_basis as (select * from {{ ref("int_pystatis__basis_gesammelt") }}),

    einwohner_18_64 as (
        select *
        from kennz_basis
        where
            code_kennzahl = 'Anzahl Einwohner:innen (Kreis)' and code_altersgruppe_2 = '18-64'
    ),

    einwohner_65plus as (
        select *
        from kennz_basis
        where code_kennzahl = 'Anzahl Einwohner:innen' and code_altersgruppe_2 = '65+'
    ),

    kennzahl as (
        select
            'Altenquotient' as code_kennzahl,
            einwohner_65plus.code_kreis,
            einwohner_65plus.code_stichtag,
            einwohner_65plus.code_geschlecht,
            /* wir betrachten nur die aggregierten Werte für 18-64 und 65+, daher keine AG */
            null as code_altersgruppe,
            null as code_altersgruppe_1,
            null as code_altersgruppe_2,
            sum(einwohner_65plus.fact_kennzahl)
            / nullif(sum(einwohner_18_64.fact_kennzahl), 0)
            * 100 as fact_kennzahl
        from einwohner_65plus
        inner join
            einwohner_18_64
            on einwohner_65plus.code_stichtag = einwohner_18_64.code_stichtag
            and einwohner_65plus.code_kreis = einwohner_18_64.code_kreis
            and einwohner_65plus.code_geschlecht = einwohner_18_64.code_geschlecht
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
