-- ref to int_pystatis__berechnet_gesammelt
-- mehr dimensionalitäten (als nur pro Kreis)
-- (code_kennzahl, code_kreis, code_stichtag, code_geschlecht, code_altersgruppe) natural key -> test unique
--

select *
from {{ ref("int_pystatis__berechnet_gesammelt") }}
