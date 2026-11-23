{% macro station_key(name_column) -%}
    md5(lower(regexp_replace({{ name_column }}, '[^[:alnum:]]', '', 'g')))
{%- endmacro %}