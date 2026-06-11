with casted as (
    select
        cast(code_jahr               as {{ dbt.type_string() }}) as code_jahr,
        cast(code_ags                as {{ dbt.type_string() }}) as code_ags,
        cast(desc_ags                as {{ dbt.type_string() }}) as desc_ags,
        cast(code_geschlecht         as {{ dbt.type_string() }}) as code_geschlecht,
        cast(code_altersgruppe_18_65 as {{ dbt.type_string() }}) as code_altersgruppe_18_65,
        cast(fact_count_fortzuege    as {{ dbt.type_int() }})    as fact_count_fortzuege,
        cast(fact_count_zuzuege      as {{ dbt.type_int() }})    as fact_count_zuzuege
    from
        {{ ref("seed_pystatis__kreis_12711_01_03_4_wanderungen") }}
),

final as (
    select
        code_jahr,
        concat(code_jahr, '-12-31') as code_stichtag,
        code_ags as code_kreis,
        desc_ags as desc_kreis,
        code_geschlecht,
        code_altersgruppe_18_65,
        fact_count_fortzuege,
        fact_count_zuzuege
    from
        casted
    where
        lower(code_geschlecht) != 'insgesamt'
        and len(code_ags) == 5
)

select *
from final
