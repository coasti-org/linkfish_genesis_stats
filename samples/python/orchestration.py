"""
Entrypoint to run the whole Content Package after installation


Typical command:
```
uv run --project python ./python/orchestration.py run --env-file ./config/.env --omit download_seeds --select all
```

For help, see
```
uv run --project python ./python/orchestration.py --help
```

This example uses the following environment variables:

LFGS_DUCKDB_DATAMART_PATH
LFGS_DUCKDB_FRONTEND_PATH

LFPY_LOG_LEVEL
LFPY_LOG_FILE

PYSTATIS_* (if downloading seeds from Gestatis)
"""

import os
import shutil
import sys
from pathlib import Path

from lf_py_stack.orchestration import (
    StepResult,
    cli_app,
    config,
    get_logger,
    log_dbt_versions,
    run_cli_command,
    shrink_duckdb,
    truncate,
)


def dbt_deps() -> StepResult:
    """(Re-) install dbt packages"""

    code, msg = run_cli_command("dbt deps", log=get_logger())
    return StepResult("PASS" if code == 0 else "FAIL", truncate(msg, 1, 1))


def list_versions(dbt_deps: StepResult) -> StepResult:
    """List versions of installed dependencies"""

    msg = log_dbt_versions(print_to_stdout=False)
    try:
        import pystatis

        msg += f"\npystatis {pystatis.__version__}"
    except Exception as e:
        msg += "\npystatis not found"

    log = get_logger()
    log.info(msg)
    return StepResult("PASS", msg)


def download_seeds(list_versions: StepResult) -> StepResult:
    """Use pystatis to (re-) download seeds"""
    # Does not download fresh GeoJSON, this has to be done manually
    # (but maps dont change often :P )

    # we want to use the same python runtime and launch a script that sits next to this
    python = sys.executable
    script = Path(__file__).parent / "download.py"
    args = config.get_step_args()
    code, msg = run_cli_command(f"{python} {script} {args}", log=get_logger())
    return StepResult("PASS" if code == 0 else "FAIL", truncate(msg, 5, 5))


def dbt_seed(download_seeds: StepResult) -> StepResult:
    """Load prepared seeds from csv into dbt"""

    if download_seeds.status == "FAIL":
        return StepResult("FAIL", "Aborting due to error in previous step.")

    args = config.get_step_args()
    code, msg = run_cli_command(f"dbt seed --full-refresh {args}", log=get_logger())
    return StepResult("PASS" if code == 0 else "FAIL", truncate(msg, 2, 1))


def dbt_run(dbt_seed: StepResult) -> StepResult:
    """Run dbt models"""

    log = get_logger()
    args = config.get_step_args()
    code, msg = run_cli_command(f"dbt run {args}", log=log)
    return StepResult("PASS" if code == 0 else "FAIL", truncate(msg, 2, 1))


def dbt_test(dbt_run: StepResult) -> StepResult:
    """Run dbt tests"""

    log = get_logger()
    args = config.get_step_args()
    code, msg = run_cli_command(f"dbt test {args}", log=log)
    return StepResult("PASS" if code == 0 else "FAIL", truncate(msg, 2, 1))


def minimize_duckdb(dbt_run: StepResult, dbt_test: StepResult) -> StepResult:
    """Reduce the duckdb by limiting to mart schemata"""

    log = get_logger()

    if dbt_run.status == "FAIL" or dbt_test.status == "FAIL":
        # This is effectively the step that deploys to the frontend.
        # If tests or the run fail, we **do not** want to update the frontend.
        # In real deployments, you would likely add another step to copy
        # the database, and do the check there.
        # log.warning("Aborting due to error in previous step.")
        # return StepResult("FAIL", "Aborting due to error in previous step.")
        pass

    try:
        input = Path(os.environ["LFGS_DUCKDB_DATAMART_PATH"])
        output = input.parent / f"{input.stem}_mini.db"
        shrink_duckdb(
            input_file=input,
            output_file=output,
            schemas=["plmart_sup"],
        )
        return StepResult(
            "PASS",
            f"Reduced size of {str(input)}, saved to {str(output)}",
        )
    except Exception as e:
        log.error(e)

        return StepResult("FAIL", str(e))


def deploy_to_frontend(minimize_duckdb: StepResult) -> StepResult:
    """Copy the duckdb into supersets data folder"""

    input = Path(os.environ["LFGS_DUCKDB_DATAMART_PATH"])
    mini = input.parent / f"{input.stem}_mini.db"

    _output = os.getenv("LFGS_DUCKDB_FRONTEND_PATH")
    if _output is None:
        return StepResult(
            "SKIP",
            "Skipped copying. Set the env var LFGS_DUCKDB_FRONTEND_PATH to the "
            "file path needed by superset. "
            "Likely /coasti/products/superset_docker/data/linkfish_genesis_stats.duckdb",
        )
    output = Path(_output)

    # if you want to auotmatically reload superset after copying the data:
    # run_cli_command(
    #     "cd /path/to/superset_docker/; "
    #     "/path/to/superset_docker/scripts/reset_cache.sh"
    # )

    try:
        shutil.copy(mini, output)
        return StepResult("PASS", f"Copied duckdb to {str(output)}")
    except Exception as e:
        return StepResult("FAIL", str(e))


if __name__ == "__main__":
    # the app handles the cli interface and log file setup for us
    cli_app()
