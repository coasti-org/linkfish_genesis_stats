-- Fails if any kreis has an unexpected or missing desc_kreis_art value.
select
    code_kreis,
    desc_kreis,
    desc_kreis_art
from {{ ref('mart__dim_kreis') }}
where desc_kreis_art is null
   or desc_kreis_art not in ('Landkreis', 'kreisfreie Stadt')
