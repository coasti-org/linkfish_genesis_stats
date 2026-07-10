# Python Projekt für Coasti Demo-Content-Paket: Statistik


## Relevanz

- Stellt DBT und Python runtime bereit
- Downloader für Statistik-Daten von Genesis
- Erzeugen von Seeds für DBT aus den geladenen Genesis Daten und GeoJSON


## Install

- [ ] Noch zu entscheiden: wo das .venv hinlegen
- PS 2026-07-10: derzeit tendiere ich zu Option 2.
  Die extra env var verkompliziert das Setup und der symlink funktioniert okay.

Option 1: ins project base dir

```bash
UV_PROJECT_ENVIRONMENT=../.venv uv sync --project ./python
# diese env var dann via .env setzen

# activate environment
source ./.venv/bin/activate # (linux)
.\.venv\Scripts\activate # (Windows)
```

Option 2: in den python ordner `python`

```bash
cd python
uv sync
cd ..


source ./python/.venv/bin/activate # (linux)
.\python\.venv\Scripts\activate # (Windows)

#  Um trotzdem automatische Aktivierung z.b. in vscode und Mise zu bekommen:
ln -s ./python/.venv ./.venv
```
