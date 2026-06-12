-- Superset Dataset for Deck.GL polygon:
-- This dynamically colours the polygons based on the value of 'wert_anteilig' using
-- predefined thresholds (schwellenwerte).
-- this is the code used in superset datasets - for demonstration purposes only, not
-- to be used in production as is.
-- TODO: Sind die Schwellenwerte in Prozent?
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
