{{
  config(
    enabled=false
  )
}}

with

kennz_basis as(
  select *
  from {{ ref("int_regio__kennz_basis") }}
),

einwohner_18_64 as(
  select *
  from kennz_basis
  where kennzahl = 'Anzahl Einwohner:innen (Excel)'
  and "Altersgruppe2 Code" LIKE '18-64%'
),

einwohner_65plus as(
  select *
  from kennz_basis
  where kennzahl = 'Anzahl Einwohner:innen (Excel)'
  and "Altersgruppe2 Code" LIKE '65+%'
),

kennzahl as(
    select
      sum(einwohner_65plus.Wert)
      /
      nullif(sum(einwohner_18_64.Wert), 0)
    ) * 100 as Wert
     from einwohner_65plus
  inner join einwohner_18_64
    on einwohner_65plus.Stichtag = einwohner_18_64.Stichtag
    and einwohner_65plus."Gemeinde Code" = einwohner_18_64."Gemeinde Code"
    and einwohner_65plus.Geschlecht = einwohner_18_64.Geschlecht
)

select *
from kennzahl
