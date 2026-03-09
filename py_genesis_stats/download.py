from copy import deepcopy
import logging
import os
from pathlib import Path
import time
from typing import Annotated, Any
import dotenv
import pystatis

import typer

from ruamel.yaml import YAML, CommentedMap

app = typer.Typer()
log = logging.getLogger("genesis_stats_download")
logging.basicConfig(level="INFO", format="%(levelname)s: %(message)s")


@app.command()
def download(
    config_path: Annotated[
        Path,
        typer.Option(
            help="Path to genesis_sources.yml config, defines which tables to download",
            # fill the value from env var, if env var is set and option is not given
            envvar="GS_CONFIG_YAML",
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
            envvar="GS_CSV_PATH",
            exists=True,
            file_okay=False,
            dir_okay=True,
            writable=True,
            resolve_path=True,
        ),
    ] = Path.cwd() / "dbt_genesis_stats" / "seeds",
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
        log.setLevel("DEBUG")

    if dotenv_path is not None:
        dotenv.load_dotenv(dotenv_path)

    # check authentication (uses environment variables, or prompts if not found)
    pystatis.setup_credentials()

    config = _load_config(config_path)
    _tables: list[dict[str, Any]] = config.get("tables", [])
    tables = {t["id"]: t for t in _tables}

    # check for existing files first, so we dont error after downloading a bunch
    csv_paths = {id: csv_path / f"{tables[id]['output']}.csv" for id in tables.keys()}
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
            raise e

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

    if csv_path.exists() and not overwrite:
        log.info(f"File already exists, skipping {id} at {str(csv_path)}")
        return  # no need to download if we wont save, so return early.

    params = deepcopy(defaults)
    params.update(tables[id])
    for key in ["id", "output", "description"]:
        params.pop(key, None)  # strip out custom fields, they dont work in the api

    # Main Download
    log.info(f"Downloading {tables[id]['output']}")
    start_time = time.time()
    table_download = pystatis.Table(name=id)
    table_download.get_data(**params)
    download_duration = time.time() - start_time

    log.debug(
        f"Downloaded {len(table_download.data):,} rows "
        f"× {len(table_download.data.columns)} columns "
        f"in {download_duration:.2f} seconds"
    )

    table_download.data.to_csv(
        csv_path,
        index=False,
        sep="|",
        mode="w",
        header=tables[id].get("description", "No description provided"),
    )


if __name__ == "__main__":
    app()
