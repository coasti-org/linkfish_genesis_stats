

# Metadata needed for install

- fetched by git step to connect to repo before using copier
- holds product id as [UTI](https://en.wikipedia.org/wiki/Uniform_Type_Identifier),
  ie `region.company.product`
- [ ] default install folder name for the product is `company.product`
- [ ] where to place copier answers? currently in `config/install_answers.yml` -> let content decide.


# Mandatory folders

the idea is that these are present in all coasti products, so that users feel at home quickly in new products.

- `config` (place for any configuration files)
- `data` (input, temporary, but mainly output as duckdb)
- `logs` (redirect log files to be placed here)


# Mandatory files

- `coasti.yml` Metadata for this product
- `copier.yml` Coasti uses copier under the hood to deploy content packages.
- `{{ _copier_conf.answers_file }}.jinja` Needed by copier.
- `config/.env.jinja` template for a .env file, which should hold configuration details.


# Decisions
- Id Usage:
    - [ ] Ids are UTI (reverse DNS)
    - [ ] same id for python package name?
    - [ ] same id for dbt project?
    - [ ] profile naming: do we need the id?
    - [ ] maybe a prefix / **short_id** that we set in coasti.yml? 3 - 4 alphanumeric acronym (no symbols, no char limit but keep it short. here: `gstat`)
    - [ ] env var prefixes
    - [ ] output name for duckdb file
    - [ ] seed schema, currently use vorsystem (huh seeds have a source, but i feel they are more attached to _our_ software, so should use our id shorthand. but, in the demo: import seeds in staging?)

- fact or fakt
