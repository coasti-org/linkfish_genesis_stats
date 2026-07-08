{# Falls möglich, alle berechnungen hier, ansonsten mit Ordner in verscheidene Modelle aufteilen. #}
-- alle basis-kennzahlen
-- plus alle errechneten Kennzahlen
-- Hier ermitteln wir die Kennzahlen inklusive ihrer Vorjahreswerte
-- und ergänzen sie um die Stammdaten aus kreis_polygon

{% set models_to_combine = [
    "int_pystatis__basis_gesammelt",
    "int_pystatis__berechnet_altenquotient",
    "int_pystatis__berechnet_wanderungen",
    "int_pystatis__sys_durchschnittsalter_helfer",
] %}

{# Make 1 - N into CTEs #}

with
    {# 1. union aller Kennzahlen (Basis + berechnet) #}
    basis_union as (
        {% for model in models_to_combine %}
            select
                code_kennzahl,
                code_kreis,
                code_stichtag,
                code_geschlecht,
                code_altersgruppe,
                code_altersgruppe_1,
                code_altersgruppe_2,
                fact_kennzahl,
                fact_kennzahl_vorjahr,
            from
                {{ ref( model ) }}
            {% if not loop.last %}
                union all
            {% endif %}
        {% endfor %}
    )

{# 2. Ableiten weiterer Kennzahlen (TBD) #}
select *
from basis_union
