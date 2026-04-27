-- Hier ermitteln wir die Kennzahlen inklusive ihrer Vorjahreswerte
-- und ergänzen sie um die Stammdaten aus kreis_polygon

{% set kennzahlen = [
    "int_seed__kreis_gebietsflaeche",
] %}

{# Make 1 - N into CTEs #}

with
    base as (
        select
        {# 1. union #}
        {% for kennzahl in kennzahlen %}
                {{ kennzahl }}.code_kennzahl,
                {{ kennzahl }}.code_kreis,
                {{ kennzahl }}.code_stichtag,
                {{ kennzahl }}.code_geschlecht,
                {{ kennzahl }}.code_altersgruppe,
                {{ kennzahl }}.fact_wert,
                {# 2. time lag, wir wissen, dass alle jahre vorhanden sind, daher können wir einfach lag nehmen. -> TODO: das müssen wir testen!
                lag is am linken Rand auch okay, da wird der Vorjahreswert einfach null #}
                lag(wert) over (
                    partition by
                        "{{ kennzahl }}"."code_kennzahl",
                        "{{ kennzahl }}"."code_kreis",
                        "{{ kennzahl }}"."code_geschlecht",
                        "{{ kennzahl }}"."code_altersgruppe"
                    order by "{{ kennzahl }}".stichtag
                ) as wert_vorjahr
            from
                {{ ref(kennzahl) }} as {{ kennzahl }}
            {% if not loop.last %}
                union all
            {% endif %}
        {% endfor %}
    ),

    {# 3. join polygon #}

    {# left join
        {{ ref("kreis_polygon") }} kreis_polygon #}

    {# 4. Altersgruppen konsistent schalten #}
    base_w_dimensions as (
        select
            base.*,
            case
                when altersgruppen.altersgruppe1 is not null
                then concat(altersgruppen.altersgruppe1, {{ trailing_whitespace }})
            end as "Altersgruppe1 Code"
        from base
        left join
            {{ ref("stg_xls__stat_altersgruppen") }} altersgruppen
            on base.altersgruppe = altersgruppen.alterstatistik
    )

select *
from base_w_dimensions
