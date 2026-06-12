{# ------------------------------------------------------------------------------
@Author:        F. Paul Spitzner
@Created:       2025-01-09
@Last Modified: 2025-08-15 13:05:00
------------------------------------------------------------------------------ #}

{# TODO: no tests yet #}

{# macrodocs

**Automatically invoked by dbt**, does not need to be called.
[Check disptach search order](https://docs.getdbt.com/reference/dbt-jinja-functions/dispatch#overriding-global-macros)

Overwrite the default way dbt generates the alias from the model file name.

- The alias is the name that will occur as the table name in the database.
- We remove everything until including the double underscore `__` which we
  use as prefix for model file names to represent the folder structure.
- For example: `int_huh_sup__pos_monat_erg.sql` -> `pos_monat_erg`
- Supports model versions

endmacrodocs #}

{% macro default__generate_alias_name(custom_alias_name=none, node=none) -%}
    {# For the overwrite to work, we _need_ the `default__` prefix.
    For details, see issue #10:
    https://github.com/linkFISH-Consulting/dbt-lf_utils/issues/10
    #}

    {# {{ log("Using lf_utils.generate_alias_name", info=True) }} #}

    {% set custom_node_name = node.name[node.name.find('__') + 2:] if '__' in node.name else node.name %}

    {%- if custom_alias_name -%}
        {{ custom_alias_name | trim }}

    {%- elif node.version -%}

        {{ return(custom_node_name ~ "_v" ~ (node.version | replace(".", "_"))) }}

    {%- else -%}
        {{ custom_node_name }}
    {%- endif -%}
{%- endmacro %}
