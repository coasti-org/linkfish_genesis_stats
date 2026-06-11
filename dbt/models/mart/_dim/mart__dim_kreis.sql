
{#

injection of values to plot in superset happens later.
they have to go into the `properties` field of the fact_geojson

SELECT REPLACE(
    fact_geojson,
    'properties: { }',
    'properties: {'
        + CASE
            WHEN foo_col IS NOT NULL
            THEN ' foo: ' + CAST(foo_col AS VARCHAR)
            ELSE ''
          END
    + ' }'
)
FROM your_table;

#}

with
    kreis_gebietsflaeche as (select * from {{ ref("stg_pystatis__kreis_gebietsflaeche") }}),
    kreis_geojson        as (select * from {{ ref("seed__kreis_geojson") }}),

    {# lets make sure descriptions are unique per kreis. if multiple, take latest year #}
    kreis_ranked as (
        select
            code_kreis,
            desc_kreis,
            row_number() over (
                partition by
                    code_kreis
                order by
                    code_stichtag desc,
                    desc_kreis asc
            ) as row_number_kreis
        from
            kreis_gebietsflaeche
    ),

    kreis as (
        select
            code_kreis,
            desc_kreis,
        from
            kreis_ranked
        where
            row_number_kreis = 1
    ),

    {# split the description at the comma #}
    split as (
        select
            code_kreis,
            desc_kreis,
            {# e.g. 'Hamburg, kreisfreie Stadt' #}
            trim(split_part(desc_kreis, ',', 1)) as desc_kreis_name,
            nullif(trim(split_part(desc_kreis, ',', 2)), '') as desc_kreis_art
        from
            kreis

    ),

    {# cleaning and edge cases#}
    clean as (
        select
            code_kreis,
            desc_kreis,
            desc_kreis_name,
            case

                {# Bsp: kreisfreie Stadt (bis 30.06.2021) #}
                when lower(desc_kreis_art) like 'kreisfreie stadt%'
                then 'kreisfreie Stadt'
                when lower(desc_kreis_art) like 'landkreis%'
                then 'Landkreis'

                {# Bsp: Rems-Murr-Kreis #}
                when desc_kreis_art is null and lower(desc_kreis) like '%kreis'
                then 'Landkreis'

                {# Bsp: Rhein-Kreis Neuss #}
                when desc_kreis_art is null and lower(desc_kreis) like '%kreis %'
                then 'Landkreis'

                when desc_kreis_art is null and lower(desc_kreis) like '%kreisfreie stadt%'
                then 'kreisfreie Stadt'


                else desc_kreis_art
            end as desc_kreis_art,
        from
            split
    ),

    {# join geojson and filter #}
    final as (
        select
            clean.*,
            kreis_geojson.fact_geojson
        from
            clean
        inner join
            {# inner join, because Eisenach from 2022 part of Wartburgkreis #}
            kreis_geojson
            on kreis_geojson.code_kreis = clean.code_kreis
    )

select *
from final
