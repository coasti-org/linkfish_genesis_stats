with casted as (
    select
        cast(code_stichtag          as {{ dbt.type_string() }}) as code_stichtag,
        cast(code_ags               as {{ dbt.type_string() }}) as code_ags,
        cast(desc_ags               as {{ dbt.type_string() }}) as desc_ags,
        cast(code_geschlecht        as {{ dbt.type_string() }}) as code_geschlecht,
        cast(fact_alter_durchschnit as {{ dbt.type_float() }})  as fact_alter_durchschnitt
    from
        {{ ref("seed_pystatis__kreis_12411_07_01_4_durchschnittsalter") }}
),

final as (
    select
        left(code_stichtag, 4) as code_jahr,
        code_stichtag,
        code_ags as code_kreis,
        desc_ags as desc_kreis,
        code_geschlecht,
        fact_alter_durchschnitt
    from
        casted
    where
        lower(code_geschlecht) != 'insgesamt'
        and len(code_ags) == 5
)

select *
from final
