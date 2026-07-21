# Python Projekt für Coasti Demo-Content-Paket: Statistik

## Relevanz

- Stellt DBT und Python runtime bereit (via uv und lf-py-stack, siehe pyproject.toml)
- Downloader für Statistik-Daten von Genesis
- Erzeugen von Seeds für DBT aus den geladenen Genesis Daten und GeoJSON

## Installation

- Jedes Coasti Content-Paket bekommt sein eigenes venv um Python-Abhängigkeiten zu gruppieren.

```bash
# Mit `uv sync` ein venv anlegen, das unter `./python` lebt
uv --directory ./python sync

# Um trotzdem automatische Aktivierung z.b. in vscode und Mise zu bekommen:
ln -s ./python/.venv ./.venv
```

## Ausführen

Es gibt drei Möglichkeiten:

### One-liner via uv
Wenn ein One-liner gewünscht ist, kann aus dem Repo directory uv verwendet werden um die Orchestrierung zu starten.
Der Befehl nutzt das erzeugte venv, und übergibt Environment-Variblen aus der .env:

```bash
uv run --project ./python ./python/orchestration.py run --env-file ./config/.env --select all
```

### Orchestrierung mit aktiviertem Environment

Anstatt uv zu nutzen, können wir auch manuell das venv aktivieren:

```bash
# venv aktivieren (linux)
source ./python/.venv/bin/activate

python ./python/orchestration.py run --env-file ./config/.env --select all
```

### Full Manual

Wenn wir DBT direkt ausführen wollen, z.b. zum Entwickeln, lohnt es sich das venv zu aktiveren und Environment-Variablen in die Shell zu laden:

```bash
# venv aktivieren (linux)
source ./python/.venv/bin/activate

# Variablen aus .env laden
set -a; source ./config/.env; set +a

# DBT nutzen
dbt debug

# Oder Orchestrierung, jetzt muss die .venv nicht mehr übergeben werden.
python ./python/orchestration.py run --select all
```
