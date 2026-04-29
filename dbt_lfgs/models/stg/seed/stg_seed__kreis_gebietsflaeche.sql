with casted as (
    select
        cast(code_stichtag as {{ dbt.type_string() }}) as code_stichtag,
        cast(code_ags      as {{ dbt.type_string() }}) as code_ags,
        cast(desc_ags      as {{ dbt.type_string() }}) as desc_ags,
        cast(fact_flaeche  as {{ dbt.type_float() }})  as fact_flaeche
    from
        {{ ref("seed__kreis_11111_0002_gebietsflaeche") }}
),

final as (
    select
        left(code_stichtag, 4) as code_jahr,
        code_stichtag,
        code_ags as code_kreis,
        desc_ags as desc_kreis,
        fact_flaeche
    from
        casted
    where
        len(code_ags) == 5
)

select *
from final

