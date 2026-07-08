{# macrodocs -------------------------------------------------------------------

Helper um bequem zu loggen, im Format "[level][model]: Nachricht"

Um das log level für einen dbt run zu setzen, env variable setzen:
LFGS_LOG_LEVEL=DEBUG dbt run

# Argumente
- text: str
    Log Nachricht
- from: str, optional
    Name der aufrufenden Entität. Per default, nimmt nur das DBT Modell.
    Optional, kann z.b. der Macro Name gegeben werden um `[level][model][from]` zu loggen

# Untestützte Level
- debug
- info
- warning
- error

# Example
```sql

{{ log_debug("foo") }}             --> "[DEBUG][this_model]: foo"
{{ log_warning("bar", "mymacro")}} --> "[WARNING][this_model][mymacro]: bar"
```

---------------------------------------------------------------- endmacrodocs #}


{% macro log_debug(text, from="") %}
    {{ __custom_log(10, text, from) }}
{% endmacro %}

{% macro log_info(text, from="") %}
    {{ __custom_log(20, text, from) }}
{% endmacro %}

{% macro log_warning(text, from="") %}
    {{ __custom_log(30, text, from) }}
{% endmacro %}

{% macro log_error(text, from="") %}
    {{ __custom_log(40, text, from) }}
{% endmacro %}



{# helper to keep things DRY and add some logic like the name of the calling model. #}
{% macro __custom_log(level, text, from="", wo_execute=false) %}
    {%- if execute or wo_execute %}

        {% set prefix = __should_log_get_prefix(level) %}
        {% if prefix is none %}
            {# dont log #}
        {% else %}
            {% set msg = prefix ~ __parse_from(from) ~ text %}

            {% if level >= 30 %}
                {{ exceptions.warn(msg) }}
            {% else %}
                {{ log(msg, info=true) }}
            {% endif %}

        {% endif %}
    {% endif %}
{% endmacro %}


{# when from is set to none, we prevent logging the calling model #}
{% macro __parse_from(from="") %}
    {%- set model_name = "[" ~ this.name ~ "]" if this is defined else "" -%}
    {%- if from is none -%}
        {{ ": " }}
    {%- elif from == "" -%}
        {{ model_name ~ ": " }}
    {%- else -%}
        {{ model_name ~ "[" ~ from ~ "]: " }}
    {%- endif -%}
{% endmacro %}


{# get a prefix if we should log, else None #}
{% macro __should_log_get_prefix(lvl) %}

    {# check the user-configured log level #}
    {%- set raw = env_var('LFGS_LOG_LEVEL', 'info') | lower | trim -%}

    {# Use python logging levels #}
    {%- set levels = {
        'notset': 0,
        'debug': 10,
        'info': 20,
        'warn': 30,
        'warning': 30,
        'error': 40,
        'critical': 50,
    } -%}

    {# resolve raw -> numeric level #}
    {%- if raw.isdigit() -%}
        {%- set raw_lvl = raw | int -%}
    {%- elif raw in levels -%}
        {%- set raw_lvl = levels[raw] -%}
    {%- else -%}
        {# default INFO #}
        {%- set raw_lvl = 20 -%}
    {%- endif -%}

    {# decide whether to log #}
    {%- if lvl < raw_lvl -%}
        {{ return(none) }}
    {%- endif -%}

    {# labels from floor mapping #}
    {%- if lvl >= 50 -%}
        {{ return("[CRITICAL]") }}
    {%- elif lvl >= 40 -%}
        {{ return("[ERROR]") }}
    {%- elif lvl >= 30 -%}
        {{ return("[WARNING]") }}
    {%- elif lvl >= 20 -%}
        {{ return("[INFO]") }}
    {%- elif lvl >= 10 -%}
        {{ return("[DEBUG]") }}
    {%- else -%}
        {{ return("[NOTSET]") }}
    {%- endif -%}


{% endmacro %}
