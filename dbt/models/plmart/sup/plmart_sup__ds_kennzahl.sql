{# baut auf fact_kennzahl auf und macht nur leichte renames der spalten namen und enthaltenen werte #}
-- und joint die dim_kreis mit polygonen zu one-big-table

with 
dim_kreis as (
  -- TODO: pl_cte_col_naming macro?
    select *,
    -- column aliasing for Superset:
    code_kreis as "Kreis Code",
    desc_kreis_name as "Kreis Beschreibung",
    concat(code_kreis, ' ', desc_kreis_name) as "Kreis",
    fact_geojson as "Kreis GeoJson"
    from {{ ref("mart__dim_kreis") }}
),

fact_kennzahl as (
    select *,
    -- column aliasing for Superset:
    code_kennzahl as "Kennzahl",
    code_stichtag as "Stichtag",
    code_geschlecht as "Geschlecht",
    code_altersgruppe as "Altersgruppe",
    code_altersgruppe_1 as "Altersgruppe 1",
    code_altersgruppe_2 as "Altersgruppe 2",
    fact_kennzahl as "Wert",
    fact_kennzahl_vorjahr as "Wert Vorjahr"
    from {{ ref("mart__fact_kennzahl") }}
)
select 
  fact_kennzahl."Kennzahl",
  fact_kennzahl."Stichtag",
  fact_kennzahl."Geschlecht",
  fact_kennzahl."Altersgruppe",
  fact_kennzahl."Altersgruppe 1",
  fact_kennzahl."Altersgruppe 2",
  dim_kreis."Kreis Code",
  dim_kreis."Kreis Beschreibung",
  dim_kreis."Kreis",
  dim_kreis."Kreis GeoJson",
  fact_kennzahl."Wert",
  fact_kennzahl."Wert Vorjahr",
from fact_kennzahl
left join dim_kreis
    on fact_kennzahl.code_kreis = dim_kreis.code_kreis
