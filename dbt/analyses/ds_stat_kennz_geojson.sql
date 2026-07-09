{#

Legacy-Beispiel, um SQL-seitig Colormaps zu erstellen, und so GeoJSON Objekte
zu erzeugen, die bereits backend-seitig eingefärbt sind.
Funktioniert mit dem deck.gl GeoJSON Chart Type (nicht Polygon) und
in Superset Versionen < 6.1.

In Superset 6.2 wird es einige Patches geben, die den deck.gl Polygon Chart Type
besser nutzbar machen, sodass Colormaps idR direkt im Frontend konfiguriert werden
können.

#}

{%- set schwellenwerte = [
    {"max": 0.35, "colour": "#D4DFF4"},
    {"max": 0.7, "colour": "#CCD4E6"},
    {"max": 1.5, "colour": "#99A8CC"},
    {"max": 5, "colour": "#667DB3"},
    {"max": 15, "colour": "#335199"},
    {"max": none, "colour": "#002680"},
] %}

with
    base as (
        select *
        from plmart_sup.ds_kreis_kennzahl_geojson
        where
            kennzahl in (
                'Altenquotient (Kreis)',
                'Anzahl Einwohner:innen (Kreis)',
                'Durchschnittsalter (Kreis)',
                'Gebietsfläche (Kreis)',
                'Lebendgeburten (Kreis)',
                'Medianalter (Kreis)',
                'Sterbefälle (Kreis)',
                'Fortzüge (Kreis)',
                'Zuzüge (Kreis)'
            )
    ),

    colored as (
        select
            base.*,
            case
                {%- for schwellenwert in schwellenwerte %}
                    {%- if schwellenwert.max is not none %}
                        when "Wert anteilig" <= {{ schwellenwert.max }}
                        then
                            replace(
                                "Kreis GeoJson",
                                '#REPLACE_ME',
                                '{{ schwellenwert.colour }}'
                            )
                    {%- else %}
                        when "Wert anteilig" > 15
                        then
                            replace(
                                "Kreis GeoJson",
                                '#REPLACE_ME',
                                '{{ schwellenwert.colour }}'
                            )
                    {%- endif %}
                {%- endfor %}
                else replace("Kreis GeoJson", '#REPLACE_ME', '#F2F2F2')
            end as "Kreis GeoJson colored"
        from base
    )

select *
from colored
