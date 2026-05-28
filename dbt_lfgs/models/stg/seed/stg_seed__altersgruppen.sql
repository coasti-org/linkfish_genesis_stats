with casted as (
    select
        cast(code_altersgruppe_statistik as {{ dbt.type_string() }}) as code_altersgruppe_statistik,
        cast(code_altersgruppe_1         as {{ dbt.type_string() }}) as code_altersgruppe_1,
        cast(code_altersgruppe_2         as {{ dbt.type_string() }}) as code_altersgruppe_2
    from
        {{ ref("seed_altersgruppen") }}
),

final as (
    select
        code_altersgruppe_statistik,
        code_altersgruppe_1,
        code_altersgruppe_2
    from
        casted
)

select *
from final
