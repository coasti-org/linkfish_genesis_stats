{# ------------------------------------------------------------------------------
@Author:        F. Paul Spitzner
@Created:       2025-08-13 16:08:21
@Last Modified: 2025-08-15 13:01:51
------------------------------------------------------------------------------ #}

{# TODO: no tests yet #}

{# macrodocs

**Automatically invoked by dbt**, does not need to be called.
[Check disptach search order](https://docs.getdbt.com/reference/dbt-jinja-functions/dispatch#overriding-global-macros)

This macro prepends the target as a prefix for to the schema of tables and views
that will materialize in the database - for all targets except 'prod'.

In particular, the dev target gets a dev_ prefix, while the prod target is NOT prefixed

endmacrodocs #}

{% macro default__generate_schema_name(custom_schema_name, node) -%}
    {# For the overwrite to work, we _need_ the `default__` prefix.
    For details, see issue #10:
    https://github.com/linkFISH-Consulting/dbt-lf_utils/issues/10
    #}

    {# {{ log("Using lf_utils.generate_schema_name", info=True) }} #}

    {%- set default_schema = target.schema -%}
    {%- if target.name == 'prod' -%}
        {{ custom_schema_name | trim }}

    {%- else -%}
        {%- if custom_schema_name is none -%}

            {{ default_schema }}

        {%- else -%}

            {{ default_schema }}_{{ custom_schema_name | trim }}

        {%- endif -%}
    {%- endif -%}
{%- endmacro %}
