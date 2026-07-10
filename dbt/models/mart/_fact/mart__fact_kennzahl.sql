{#

Fakten-Tabelle aller Kennzahlen auf Kreisebene

# Notizen
- Dimensionen sind:
    - code_kreis
    - code_stichtag (derzeit nur mit Jahres-Präzision)
    - code_geschlecht
    - code_altersgruppe_18_65 (Standard Abstufungen, genutzt in Frontend Filtern)
    - code_altersgruppe_grob (nur drei Abstufungen, genutzt für Altenquotient)
    - code_kennzahl (pivot erfolgt in plmart, dann hat jede Kennzahl eine eigene Spalte)

#}

{% set kreis_in_dim = dbt_utils.get_column_values(
    table=ref("mart__dim_kreis"),
    column="code_kreis",
) %}

{% set kreis_dropped = dbt_utils.get_column_values(
    table=ref("int_pystatis__berechnet_gesammelt"),
    column="code_kreis",
    where="code_kreis not in (select code_kreis from "
    ~ ref("mart__dim_kreis")
    ~ ")",
) %}

{{
    log_info(
        "Daten für "
        ~ (kreis_in_dim | length)
        ~ " Kreise übernommen. "
        ~ "Ignorierte Kreise, da nicht in Dimensionstabelle: "
        ~ (kreis_dropped | join(", "))
    )
}}

select *
from {{ ref("int_pystatis__berechnet_gesammelt") }}
{% if kreis_dropped | length > 0 %}
    where
        code_kreis not in (
            {{ "'" ~ (kreis_dropped | join("', '")) ~ "'" }}
        )
{% endif %}
