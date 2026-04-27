-- Superset Dataset for Deck.GL polygon: 
-- This dynamically colours the polygons based on the value of 'wert_anteilig' using predefined thresholds (schwellenwerte).
-- this is the code used in superset datasets - for demonstration purposes only, not to be used in production as is.
{%- set schwellenwerte = [
    {'max': 0.35, 'colour': '#D4DFF4'},
    {'max': 0.7,  'colour': '#CCD4E6'},
    {'max': 1.5,  'colour': '#99A8CC'},
    {'max': 5,    'colour': '#667DB3'},
    {'max': 15,   'colour': '#335199'},
    {'max': none, 'colour': '#002680'}
] %}

with base as(
  select 
    *
  from pl_regio.ds_regio_kennzahl_geojson
  where Kennzahl in(
  'Altenquotient (Excel)', 'Anzahl Einwohner:innen (Excel)', 'Anzahl Fortzüge (Excel)',
  'Anzahl Geborene (Excel)', 'Anzahl Gestorbene (Excel)', 'Anzahl Zuzüge (Excel)',
  'Jugendquotient (Excel)', 'Greying Index (Excel)', 'Anteil Personen ab 65 Jahren (Excel)',
  'Geburtenrate (Excel)', 'Natürliche Bevölkerungsentwicklung (Excel)', 'Wanderungssaldo (Excel)'
  )
),

base_coloured as(
  select
    base.*
  , case
      {%- for schwellenwert in schwellenwerte %}
        {%- if schwellenwert.max is not none %}
        WHEN wert_anteilig <= {{ schwellenwert.max }} THEN REPLACE(polygon, '#CCCCCC', '{{ schwellenwert.colour }}')
        {%- else %}
        WHEN wert_anteilig > 15 THEN REPLACE(polygon, '#CCCCCC', '{{ schwellenwert.colour }}')
        {%- endif %}
      {%- endfor %}
      else REPLACE(polygon, '#CCCCCC', '#F2F2F2')
    end as polygon_coloured
  from base
)

select *
from base_coloured