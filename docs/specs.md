
# Mandatory folders

the idea is that these are present in all coasti products, so that users feel at home quickly in new products.

- `config` (place for any configuration files)
- `data` (input, temporary, but mainly output as duckdb)
- `logs` (redirect log files to be placed here)

# Mandatory files

- `coasti.yml` Metadata for this product.
- `copier.yml` Coasti uses copier under the hood to deploy content packages.
- `{{ _copier_conf.answers_file }}.jinja` Needed by copier.
- `config/.env.jinja` template for a .env file, which should hold configuration details.
- `config/activate` logic to load .env, and source venv in an os-dependant manner
- [x] @FD+MB: `activate` -> in `config`?
- [x] orchestration where? .sample and then have copier place a file in root?


# Product Id
- Ids are just strings (letters and underscores, lowercase encouraged)
- Recommended `company_my_product`
    - SM+PS: its not about structure here, ids can be plain strings. we just want products to be unique.
    - Therefore: only limit them to whats allowed in python and dbt proejcts, and give a suggestion
    - dbt and python modules go from there, replacing `_` with `-` as needed.
- used by coasti entry in `/coasti/config/products.yml`
- used by coasti as folder name for product in `/coasti/products` (do not ask, just do it)
- used for internal subfolders like `py_my_product` and `dbt_my_product`
- used as id in `dbt_project.yml` -> underscore becomes hyphen
- used as id in `pyproject.toml` -> underscore becomes hyphen

## Short id (prefix)
- suggest a __short_id__ for prefixing, alphanumeric acronym (no symbols, no char limit but keep it short. here: `gstat`)
    - use in dbt `profiles.yml`?
    - env var prefixes
- [x] do we want to prefix these things? yes, good for env vars, and for profiles it does not hurt.

# Metadata needed for coasti install
- placed in `coasti.yml`
- fetched by git step to connect to repo before using copier, to check repo access before answering any further questions
- default install folder name for the product is the id.
- copier answers are normally placed in `config/install_answers.yml`, but we let content creators decide (as long as it follows copiers convention, it will work)
- `cosati.yml` should answer where is the entrypoint
- `cosati.yml` should answer where is the activation script

# Design Choices

- [ ] Which python dependencies on the coasti host?
    - to run orchestrate.py, we need _some_ python on the host
    - currently, that is the whole `lf_py_stack` (because the cli_app is integrated there)
    - for now: just use `lf_py_stack` on ubuntu host @PS: check if `uv tool install` works
- [x] output name for duckdb file
    - `data/duckdb/company_my_product.duckdb`
    - link in `/coasti/data/company_my_product/duckdb/company_my_product.duckdb`
    - good because, we want to copy into `/coasti/data/linkfish_superset/company_my_product.duckdb` (this is the minimzed, mart-only version)
- [x] Platzhalter für Missing Dimensions in One-big-Table für Superset:
    - Null im Backend, und falls im Frontend nötig, ganz am Ende ersetzen, via Variable
- [x] fact als prefix und Ordner name, nicht fakt (mit MB und JH entschieden)
- [x] seed schema -> angenommen wir haben eigene database, dann trotzem seed_our_shorthand, da seeds ja von uns sind, und wir das von anderen Vorsystemen abgreznen wollen.

# Schema-Problematik

- Konvention von MB+PS hat Starke Annahme: One Database per product
- Database -> Schema -> Table, daher muss `my_product` id nicht im schema auftauchen.
- [ ] Kriegen wir das von jetzt an bei allen Kunden durch?
- [ ] Wenn nicht, dann was? Harte Kommunikation: Content hat Anforderungen, wenn nicht erfüllt, dann geht halt der Content nicht.



# Coasti
- What's the entrypoint of content paket?
    - Does not have to be a singel entrypoint, but one example for bare metal installations

- Copier: Post-Install Step um (dbt/python) runtime zu erzeugen.

## Python needs
- DBT runtime (lf_py_stack)
- Extra-Python Kram für dieses Content Paket


## Discussion mit SM
- Dependency Groups:
    - dbt pure
    - extras here pystatis
    - all for both
