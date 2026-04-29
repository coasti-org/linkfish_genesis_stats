-- Hier ermitteln wir die Kennzahlen inklusive ihrer Vorjahreswerte
-- und ergänzen sie um die Stammdaten aus kreis_polygon

{% set models_to_combine = [
    "int_seed__basis_kreis_durchschnittsalter",
    "int_seed__basis_kreis_gebietsflaeche",
    "int_seed__basis_kreis_lebendgeburten",
    "int_seed__basis_kreis_medianalter",
    "int_seed__basis_kreis_sterbefaelle",
    "int_seed__basis_kreis_wanderungen",
] %}

{# Make 1 - N into CTEs #}

with
    {# 1. union alle basis kennzahlen #}
    basis_union as (
        {% for model in models_to_combine %}
            select
                code_kennzahl,
                code_kreis,
                code_stichtag,
                code_geschlecht,
                code_altersgruppe,
                fact_kennzahl
            from
                {{ ref( model ) }}
            {% if not loop.last %}
                union all
            {% endif %}
        {% endfor %}
    ),



    {# 2. Für Superset müssen Zeitvergleiche vorberechnet werden.
    Lag-Funktion sollte ausreichen, da wir wissen, dass alle jahre vorhanden sind.
    (Andernfalls kommt es zu Verschiebungen entlang der übrigen Dimensionen)
    Lag ist am linken Rand auch okay, da wird der Vorjahreswert dann null #}
    basis_lag as (
        select *,
            lag(fact_wert) over (
                partition by
                    code_kennzahl,
                    code_kreis,
                    code_geschlecht,
                    code_altersgruppe
                order by
                    stichtag
            ) as fact_kennzahl_vorjahr
        from basis_union
    )

    {# 3. join polygon -> PS 2026-04-29 probably not here, lets use kreis dim table #}

    {# left join
        {{ ref("kreis_polygon") }} kreis_polygon #}

    {# 4. Altersgruppen konsistent schalten #}
    {# base_w_dimensions as (
        select
            base.*,
            case
                when altersgruppen.altersgruppe1 is not null
                then concat(altersgruppen.altersgruppe1, {{ trailing_whitespace }})
            end as "Altersgruppe1 Code"
        from base
        left join
            {{ ref("stg_xls__stat_altersgruppen") }} altersgruppen
            on base.altersgruppe = altersgruppen.alterstatistik
    ) #}

select *
from basis_union
