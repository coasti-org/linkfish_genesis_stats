with casted as (
    select
        cast(code_jahr                 as {{ dbt.type_string() }}) as code_jahr,
        cast(code_ags                  as {{ dbt.type_string() }}) as code_ags,
        cast(desc_ags                  as {{ dbt.type_string() }}) as desc_ags,
        cast(code_geschlecht           as {{ dbt.type_string() }}) as code_geschlecht,
        cast(fact_count_lebendgeborene as {{ dbt.type_int() }})    as fact_count_lebendgeborene
    from
        {{ ref("seed_pystatis__kreis_12612_01_01_4_lebendgeburten") }}
),

final as (
    select
        code_jahr,
        concat(code_jahr, '-12-31') as code_stichtag,
        code_ags as code_kreis,
        desc_ags as desc_kreis,
        code_geschlecht,
        fact_count_lebendgeborene
    from
        casted
    where
        lower(code_geschlecht) != 'insgesamt'
        and len(code_ags) == 5
)

select *
from final
