{# testdocs --------------------------------------------------------------------

Generic Test to confirm that a table has a row count as specified.

One or both of `min` and / or `max` need to be given.
Bounds are inclusive (min = 1 will pass if at least one row is found).

Usage:
```yml
models:

- name: my_model
  data_tests:
  - row_count:
      min: 1
      max: 100
```

Note: the `test_` prefix is needed for our parsing so `dbt docs generate` can finds it.
(in the yaml, the docu for generic tests needs to be placed under `macros`)

----------------------------------------------------------------- endtestdocs #}

{% test row_count(model, min=None, max=None) %}
    {% if min is none and max is none %}
        {{
            exceptions.raise_compiler_error(
                "row_count test requires at least one of 'min' or 'max' arguments"
            )
        }}
    {% endif %}

    with
        no_of_rows as (
            select count(*) as row_count from {{ model }}
        )

    select
        row_count
    from
        no_of_rows
    where
        {# we need inverse logic, because we want _no_ rows if everything is ok. #}
        1 = 2
        {% if min is not none %} or row_count < {{ min }} {% endif %}
        {% if max is not none %} or row_count > {{ max }} {% endif %}
{% endtest %}
