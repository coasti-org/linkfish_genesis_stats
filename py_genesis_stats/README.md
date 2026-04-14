# Python Projekt für Coasti Demo-Content-Paket: Statistik


## Relevanz

- Stellt DBT und Python runtime bereit
- Downloader für Statistik-Daten von Genesis
- Erzeugen von Seeds für DBT aus den geladenen Genesis Daten


## Install

```bash
UV_PROJECT_ENVIRONMENT=../.venv uv sync --project ./py_genesis_stats

# for full dev setup
UV_PROJECT_ENVIRONMENT=../.venv uv sync --project ./py_genesis_stats --all-groups --all-extras

# activate environment
source ./py_genesis_stats/.venv/bin/activate # (linux)
.\py_genesis_stats\.venv\Scripts\activate # (Windows)
```
