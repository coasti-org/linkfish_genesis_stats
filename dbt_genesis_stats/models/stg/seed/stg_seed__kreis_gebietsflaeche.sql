select
    code_stichtag,
    code_ags as code_kreis,
    desc_ags as desc_kreis,
    cast(fact_flaeche as {{ dbt.type_float() }}) as fact_flaeche
from 
    {{ ref("seed__kreis_11111_0002_gebietsflaeche") }}


