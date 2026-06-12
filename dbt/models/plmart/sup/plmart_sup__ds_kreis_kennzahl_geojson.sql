{#
deck.gl GeoJson unterstützt derzeit leider noch keine SQL-Aggregationen bzw. Superset-Metriken.
Daher wird plmart_sup__ds_kennzahl hier voraggregiert.
Was übrig bleibt: Kennzahlen auf Kreis-Ebene (aber ohne Geschlecht und Altersgruppe)
- die fallen zwangsläufig weg.

Wir können detaillierte Werte aber über einen Hover-Effekt in der Karte zeigen
(z.B. Wert je Geschlecht).

#}
{% set dim_cols = [
    '"Kennzahl"',
    '"Stichtag"',
    '"Jahr"',
    '"Monat"',
    '"Monat Bezeichnung"',
    '"Kreis Code"',
    '"Kreis Bezeichnung"',
    '"Kreis"',
    '"Kreis GeoJson"'
] %}

select
    {{ dim_cols | join(', ') }},
    sum("Wert") as "Wert",
    sum(case when lower("Geschlecht") = 'männlich' then 1 else 0 end) as "Wert männlich",
    sum(case when lower("Geschlecht") = 'weiblich' then 1 else 0 end) as "Wert weiblich",
    sum("Wert Vorjahr") as "Wert Vorjahr",

    -- in Superset benötigt für farbl. Darstellung:
    -- Anteilig heißt relativ zur Summe über alle Kreise, pro Zeitschritt (Stichtag)
    -- Und wir vermeiden 0-Divisions durch nullif
    sum("Wert")
    * 100
    / nullif(
        sum(sum("Wert")) over (partition by "Kennzahl", "Stichtag"), 0
    ) as "Wert anteilig"

from {{ ref("plmart_sup__ds_kreis_kennzahl") }}
group by
    {{ dim_cols | join(', ') }},
