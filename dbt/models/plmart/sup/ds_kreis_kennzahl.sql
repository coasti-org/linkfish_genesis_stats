{# baut auf fact_kennzahl auf und macht nur leichte renames der spalten namen und enthaltenen werte #}


with
    berechnet_gesammelt as (select * from {{ ref("int_pystatis__berechnet_gesammelt") }}
        where code_kennzahl = 'Durchschnittsalter (Kreis)'),
    dim_kreis           as (select * from {{ ref("mart__dim_kreis") }} ),


    injected as (
        select
            berechnet_gesammelt.*,
            replace(
                coalesce(dim_kreis.fact_geojson, ''),
                '"properties": {}',
                '"properties": {'

                {# we are creating json, where missing values are expressed as null #}
                || '"Stichtag": "'
                || coalesce(cast(berechnet_gesammelt.code_stichtag as varchar), 'null')
                || '" ,'

                || '"Durchschnittsalter (Kreis)": '
                || coalesce(cast(berechnet_gesammelt.fact_kennzahl as varchar), 'null')
                || ' ,'

                || '"fillColor": "#CCCCCC"'
                || ' }'
            ) as fact_geojson
        from
            berechnet_gesammelt
        left join
            dim_kreis
            on dim_kreis.code_kreis = berechnet_gesammelt.code_kreis
    )

select * from injected
