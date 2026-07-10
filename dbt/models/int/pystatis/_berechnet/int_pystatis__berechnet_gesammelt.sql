{#

Kombiniere alle Kennzahlen, basis und berechnet.

# Notizen
- Kennzahlen sind hier noch sparse und als Dimension geführt.
- Siehe `int_pystatis__basis_gesammelt`

#}


{% set models_to_combine = [
    "int_pystatis__basis_gesammelt",
    "int_pystatis__berechnet_altenquotient",
    "int_pystatis__berechnet_durchschnittsalter",
] %}

with
    basis_union as (
        {% for model in models_to_combine %}
            select
                code_kennzahl,
                code_kreis,
                code_stichtag,
                code_geschlecht,
                code_altersgruppe_18_65,
                code_altersgruppe_grob,
                fact_kennzahl,
                fact_kennzahl_vorjahr,
            from
                {{ ref( model ) }}
            {% if not loop.last %}
                union all
            {% endif %}
        {% endfor %}
    )

select *
from basis_union
