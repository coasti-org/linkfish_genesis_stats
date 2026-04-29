{# testdocs --------------------------------------------------------------------

Prüfe, dass alle basis kennzahlen nach aufspannenden Dimensionen (combined key)
die gesamte Jahres-Reichweite enthalten (2020-2025)

Nötig, da wir eine einfache lag-Funktion nutzen um Vorjahresvergleiche zu berechnen

----------------------------------------------------------------- endtestdocs #}

with
    basis_gesammelt as (select * from {{ ref("int_seed__basis_gesammelt") }}),

    observed as (
        select distinct
            code_kennzahl,
            code_kreis,
            cast(left(code_stichtag, 4) as int) as code_jahr,
            code_geschlecht,
            code_altersgruppe
        from
            basis_gesammelt
    ),

    {# all dimensions, except the years #}
    combos as (
        select distinct
            code_kennzahl,
            code_kreis,
            code_geschlecht,
            code_altersgruppe
        from
            observed
    ),

    years as (
        select 2020 as code_jahr
        union all
        select 2021 as code_jahr
        union all
        select 2022 as code_jahr
        union all
        select 2023 as code_jahr
        union all
        select 2024 as code_jahr
        union all
        select 2025 as code_jahr
    ),

    final as (
        select
            combos.code_kennzahl,
            combos.code_kreis,
            years.code_jahr as code_jahr_requested,
            observed.code_jahr as code_jahr_observed,
            combos.code_geschlecht,
            combos.code_altersgruppe
        from
            combos
            {# cross join to get all combinations of dimensions and years #}
            cross join years

            left join observed
                {# left join so that years not found are null #}
                on years.code_jahr = observed.code_jahr
                {# join on all other dims #}
                and combos.code_kennzahl = observed.code_kennzahl
                and combos.code_kreis = observed.code_kreis
                {# we use `is not distinct from` to also get a match for null=null  #}
                and combos.code_geschlecht is not distinct from observed.code_geschlecht
                and combos.code_altersgruppe is not distinct from observed.code_altersgruppe
        where
            observed.code_jahr is null
    )

select *
from final

