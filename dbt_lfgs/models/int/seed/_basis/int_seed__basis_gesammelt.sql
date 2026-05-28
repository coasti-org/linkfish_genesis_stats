-- Hier ermitteln wir die Kennzahlen inklusive ihrer Vorjahreswerte
-- und ergänzen sie um die Stammdaten aus kreis_polygon

{% set models_to_combine = [
    "int_seed__basis_kreis_anzahl_einwohner",
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
            lag(fact_kennzahl) over (
                partition by
                    code_kennzahl,
                    code_kreis,
                    code_geschlecht,
                    code_altersgruppe
                order by
                    code_stichtag
            ) as fact_kennzahl_vorjahr
        from basis_union
    ),

    {# 3. Altersgruppen konsistent schalten #}
    base_w_dimensions as (
        select
            basis_lag.*,
            code_altersgruppe_1,
            code_altersgruppe_2
        from basis_lag
        left join
            {{ ref("stg_seed__altersgruppen") }} altersgruppen
            on basis_lag.code_altersgruppe = altersgruppen.code_altersgruppe_statistik
    )

select *
from base_w_dimensions
