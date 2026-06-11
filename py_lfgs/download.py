import logging
import os
import time
from copy import deepcopy
from pathlib import Path
from typing import Annotated, Any

import dotenv
import typer
from pystatis import Table, db, setup_credentials
from ruamel.yaml import YAML, CommentedMap

app = typer.Typer()
log = logging.getLogger("lfgs_download")


@app.command()
def download(
    config_path: Annotated[
        Path,
        typer.Option(
            help="Path to genesis_sources.yml config, defines which tables to download",
            # fill the value from env var, if env var is set and option is not given
            envvar="LFGS_CONFIG_YAML",
            # check input, even applies to the default we give below
            exists=True,
            file_okay=True,
            dir_okay=False,
            readable=True,
            resolve_path=True,
        ),
    ] = Path.cwd() / "config" / "genesis_sources.yml",
    csv_path: Annotated[
        Path,
        typer.Option(
            help="Where to place the downloaded csv files?",
            envvar="LFGS_CSV_PATH",
            exists=True,
            file_okay=False,
            dir_okay=True,
            writable=True,
            resolve_path=True,
        ),
    ] = Path.cwd() / "dbt_lfgs" / "seeds",
    dotenv_path: Annotated[
        Path | None,
        typer.Option(
            "--env",
            help="Path to .env file. When not specified, api credentials are "
            "used from your current shell, or pystatis will prompt you",
            exists=True,
        ),
    ] = None,
    overwrite: Annotated[
        bool,
        typer.Option(help="Overwrite existing csv files?"),
    ] = False,
    verbose: Annotated[
        bool,
        typer.Option(help="Enable debug logging"),
    ] = False,
):
    """Download resources from German Statistiks sources

    Genesis, Zensus and regionalstatistik.de

    To authenticate with the online services via pystatis, you need to set the
    a few env variables (See pystatis docs for other services than genesis)

    PYSTATIS_GENESIS_API_USERNAME
    PYSTATIS_GENESIS_API_PASSWORD
    """

    if verbose:
        logging.basicConfig(
            level="DEBUG", format="%(levelname)-8s %(message)s [%(name)s]"
        )
    else:
        logging.basicConfig(level="WARNING", format="%(message)s")
        log.setLevel("INFO")

    if dotenv_path is not None:
        dotenv.load_dotenv(dotenv_path)

    # check authentication (uses environment variables, or prompts if not found)
    # We do not grab data from zensus, so no account needed there
    setup_credentials("genesis", "regio")

    config = _load_config(config_path)
    tables = {t["id"]: t for t in config.get("tables", [])}

    # check for existing files first, so we dont error after downloading a bunch
    csv_paths = {
        id: csv_path / f"seed__{tables[id]['output']}.csv" for id in tables.keys()
    }
    if not overwrite and any([p.exists() for p in csv_paths.values()]):
        raise ValueError(
            "Some target csv files already exists. Consider passing --overwrite"
        )

    for id in tables.keys():
        try:
            _download_table(
                config=config,
                id=id,
                csv_path=csv_paths[id],
                overwrite=overwrite,
            )
        except Exception as e:
            log.error(f"Failed to download {id=}: {e}")


def _load_config(yaml_path: Path) -> CommentedMap:
    """Load the configuration from YAML file."""

    yaml = YAML()
    yaml_path = yaml_path.absolute()
    log.info(f"Loading configuration from: {yaml_path}")

    config = yaml.load(yaml_path)
    log.debug(
        f"Configuration loaded successfully with {len(config.get('tables', []))} tables"
    )
    return config


def _download_table(
    config: CommentedMap,
    id: str,
    csv_path: Path,
    overwrite: bool,
):
    """
    Download single table from Genesis as csv

    # Arguments
    - config: Complete yaml, loaded, with two keys:
              `defaults` (dict) and `tables` (list[dict])
    - id: Table to download, has to be in `tables`
    - csv_path: Where to save the csv
    """

    defaults: dict[str, Any] = config.get("defaults", {})

    _tables: list[dict[str, Any]] = config.get("tables", [])
    tables = {t["id"]: t for t in _tables}
    table = tables[id]

    if csv_path.exists() and not overwrite:
        log.info(f"File already exists, skipping {id} at {str(csv_path)}")
        return  # no need to download if we wont save, so return early.

    params = deepcopy(defaults)
    params.update(table)
    for key in ["id", "output", "description"]:
        params.pop(key, None)  # strip out custom fields, they dont work in the api

    try:
        db_name = db.select_db_by_credentials(db.identify_db_matches(id))
    except Exception:
        db_name = "unknown"  # only used for logging and header

    log.info(f"Downloading {table['output']} from {db_name}")
    start_time = time.time()
    table_download = Table(name=id)
    table_download.get_data(**params)
    download_duration = time.time() - start_time

    log.debug(
        f"Downloaded {len(table_download.data):,} rows "
        f"× {len(table_download.data.columns)} columns "
        f"in {download_duration:.1f} seconds"
    )

    # column renaming, from api_convention to dict that has everything
    config_columns = {c["api"]: c for c in config.get("columns", [])}

    table_download.data.to_csv(
        csv_path,
        index=False,
        sep="|",
        mode="w",
        header=[
            # list of labels to use, with right length and order
            config_columns.get(c_api, {}).get("dbt", c_api)
            for c_api in table_download.data.columns
        ],
    )
    _write_seeds_yaml(
        config_columns=config_columns,
        table=table,
        table_download=table_download,
        yaml_path=csv_path.with_suffix(".yml"),
        db_name=db_name,
    )


def _write_seeds_yaml(
    config_columns: dict[str, dict[str, str]],
    table: dict[str, Any],
    table_download: Table,
    yaml_path: Path,
    db_name: str,
):
    """
    Zusätzlich zur csv brauchen wir auch eine yml, die für dbt die Spalten Typen
    (und ein paar Metadaten) setzt.
    Oft packt man diese in eine gesammelte `_schema.yml`, aber auch mehrere
    einzelne yml Dateien sind kein Problem.
    """

    yaml = YAML()
    yaml_path = yaml_path.absolute()

    seed_col_types: dict[str, str] = {}
    for c_api in table_download.data.columns:
        label = config_columns.get(c_api, {}).get("dbt", str(c_api))
        dtype = config_columns.get(c_api, {}).get("dtype", "varchar(50)")
        seed_col_types[label] = dtype

    seeds_entry = {
        "version": 2,
        "seeds": [
            {
                "name": f"seed__{table['output']}",
                "description": (
                    f"{db_name} dataset {table['id']}: {table.get('description', '')}"
                ),
                "config": {
                    "delimiter": "|",
                    "column_types": seed_col_types,
                },
            }
        ],
    }

    with yaml_path.open("w") as f:
        yaml.dump(seeds_entry, f)


if __name__ == "__main__":
    app()
