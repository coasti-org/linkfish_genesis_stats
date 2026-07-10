{#

Kombiniere alle Basis-Kennzahlen, und erstelle Vorjahres-Werte.

# Notizen
- Hier vorerst Kennzahlen, die ohne (komplexe) Berechnungen auskommen.
- Kennzahlen sind hier noch sparse und als Dimension geführt.
  Das erlaubt einfaches Kombinieren via `union all`
- Um eine breite Darstellung zu erhalten, wo jede Kennzahl eine eigene Spalte hat,
  wird dann später in der Presentation Layer (plmart) pivotisiert.
- Für die union müssen immer die selben Spalten in den Source-Modellen vorhanden sein,
  aber können Null enthalten.
- Hier und in den anderen Inter-Modellen wird nicht mehr gecastet,
  das passiert komplett im Staging.

#}

{% set models_to_combine = [
    "int_pystatis__basis_kreis_anzahl_einwohner",
    "int_pystatis__basis_kreis_durchschnittsalter",
    "int_pystatis__basis_kreis_gebietsflaeche",
    "int_pystatis__basis_kreis_lebendgeburten",
    "int_pystatis__basis_kreis_medianalter",
    "int_pystatis__basis_kreis_sterbefaelle",
    "int_pystatis__basis_kreis_wanderungen",
] %}


with
    {# Wir haben Duplikate in code_altersgruppe_18_65, aber wollen ab hier unique  #}
    altersgruppen as (
        select
            code_altersgruppe_18_65,
            min(code_altersgruppe_grob) as code_altersgruppe_grob
        from {{ ref("seed__altersgruppen") }}
        group by code_altersgruppe_18_65
    ),

    {# 1. union aller Basis-Kennzahlen #}
    basis_union as (
        {% for model in models_to_combine %}
            select
                code_kennzahl,
                code_kreis,
                code_stichtag,
                code_geschlecht,
                code_altersgruppe_18_65,
                fact_kennzahl
            from
                {{ ref( model ) }}
            {% if not loop.last %}
                union all
            {% endif %}
        {% endfor %}
    ),



    {# 2. Für Superset müssen Zeitvergleiche oft vorberechnet werden.
    Lag-Funktion sollte ausreichen, da wir wissen, dass pro Dimensions-Kombination
    alle Jahre vorhanden sind.
    (Andernfalls kommt es zu Verschiebungen entlang der übrigen Dimensionen)
    Lag ist am linken Rand auch okay, da wird der Vorjahreswert dann null #}
    basis_lag as (
        select *,
            lag(fact_kennzahl) over (
                partition by
                    code_kennzahl,
                    code_kreis,
                    code_geschlecht,
                    code_altersgruppe_18_65
                order by
                    code_stichtag
            ) as fact_kennzahl_vorjahr
        from basis_union
    ),

    {# 3. Altersgruppen ergänzen #}
    base_w_dimensions as (
        select
            basis_lag.*,
            altersgruppen.code_altersgruppe_grob
        from basis_lag
        left join
            altersgruppen
            on basis_lag.code_altersgruppe_18_65 = altersgruppen.code_altersgruppe_18_65
    )

select *
from base_w_dimensions
