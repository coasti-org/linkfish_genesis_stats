
select
    code_stichtag as Stichtag
    {# TODO: Kreisbezeichnung auch in seed yml gemeinde->kreis? #}
    , code_kreis as KreisCode
    , desc_kreis as KreisBezeichnung
    , '_' as Geschlecht
    , '_' as Altersgruppe
    , try_cast(fact_flaeche as float) as Gebietsfläche__qkm
    {# , RSRC
    , LDTS #}
from 
    {{ ref("seed__11111_0002_gebietsflaeche")}}