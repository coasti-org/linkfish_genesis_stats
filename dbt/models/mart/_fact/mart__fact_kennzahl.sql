-- ref to int_pystatis__berechnet_gesammelt
-- mehr dimensionalitäten (als nur pro Kreis)
-- (code_kennzahl, code_kreis, code_stichtag, code_geschlecht, code_altersgruppe)
-- natural key -> test unique
--
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
    log_debug(
        "Daten für "
        ~ (kreis_in_dim | length)
        ~ " Kreise übernommen. "
        ~ "Ignoriert Kreise, da nicht in Dimensionstabelle: "
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
