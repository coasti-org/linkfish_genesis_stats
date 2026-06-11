{# testdocs --------------------------------------------------------------------

Prüfe, dass für jede Dimensonskombination die vorhandenen Jahre lückenlos
aufsteigend sind (keine Lücken innerhalb des beobachteten Jahresbereichs).

Nötig, da wir eine einfache lag-Funktion nutzen um Vorjahresvergleiche zu berechnen

Beispiel: [2022, 2023, 2025] → FEHLER (2024 fehlt)
          [2020, 2021, 2022] → OK (auch wenn 2023-2025 fehlen)

----------------------------------------------------------------- endtestdocs #}

with
    basis_gesammelt as (select * from {{ ref("int_pystatis__basis_gesammelt") }}),

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

    {# min/max year and distinct count per dimension combo #}
    year_stats as (
        select
            code_kennzahl,
            code_kreis,
            code_geschlecht,
            code_altersgruppe,
            min(code_jahr) as min_jahr,
            max(code_jahr) as max_jahr,
            count(distinct code_jahr) as distinct_count
        from observed
        group by
            code_kennzahl,
            code_kreis,
            code_geschlecht,
            code_altersgruppe
    ),

    {# gaps: where observed distinct count < expected consecutive range #}
    gaps as (
        select
            code_kennzahl,
            code_kreis,
            code_geschlecht,
            code_altersgruppe,
            min_jahr,
            max_jahr,
            distinct_count,
            (max_jahr - min_jahr + 1) as expected_count
        from year_stats
        where distinct_count != (max_jahr - min_jahr + 1)
    )

select *
from gaps
