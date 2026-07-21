# Coasti Demo-Content-Paket: Statistik

[![Documentation](https://app.readthedocs.org/projects/coasti/badge/?version=latest&style=flat)](https://coasti.readthedocs.io/en/latest/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Copier](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/copier-org/copier/master/img/badge/badge-grayscale-inverted-border-orange.json)](https://github.com/copier-org/copier)

Beispiel eines Contentpakets für Coasti das Statistikdaten von Genesis nutzt

- Bisher essentiell eine abgespeckte Version von linkFISH Statistik+
- Trennung Kreis als kleinste Einheit vs Gemeinde als kleineste Einheit
    - Dafür konsistentes Model-Prefix an den DBT Modellen, Seeds etc
    - Bisher Fokus nur Kreisebene


## Installation

- Requirements:
    - [uv](https://docs.astral.sh/uv/)
    - [coasti installer](https://github.com/coasti-org/coasti_installer)
    - [superset_docker](https://github.com/coasti-org/superset_docker) (oder andere Superset Installation)
- Installation via `coasti product add ...`
    - Läd das Repo runter
    - Erstellt Python `.venv` mit uv und läd Python Abhängigkeiten
    - Erstellt Config Beispiele
- Ausrollen der Frontend-Assets via `superset-io`
    - Läd die grafischen Elemente (z.b. Berichte) in die Superset-Instanz hoch


```bash
# uv installieren (macOS, Linux)
curl -LsSf https://astral.sh/uv/install.sh | sh
# Windows
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"

# coasti installieren
uv tool install coasti

# Neues coasti Projekt initialisieren
coasti init /coasti
cd /coasti

# Superset und Content Paket hinzufügen
coasti product add https://github.com/coasti-org/superset_docker.git
coasti product add https://github.com/coasti-org/linkfish_genesis_stats.git

# Frontend hochladen
coasti superset-io upload /coasti/products/linkfish_genesis_stats/superset/frontend
```

## Ausführen

One-liner, via uv:
```bash
uv run --project python ./python/orchestration.py run --env-file ./config/.env --omit download_seeds --select all
```

Oder manuell, mit aktiviertem Environment:
```bash
# activate environment
source ./python/.venv/bin/activate # (linux)
.\python\.venv\Scripts\activate # (Windows)

# run everything in orchestration
python ./python/orchestration.py run --env-file ./config/.env -s all

# or selected steps
python ./python/orchestration.py run --env-file ./config/.env -s dbt_seed

# or get help
python ./python/orchestration.py --help
python ./python/orchestration.py run --help
```

## Datenquellen

- Download Statistik Data from Destatis und Regionalanalyse
    - Nutzt Pystatis
    - Benötigt Login für Destatis und Regionaldatenbank als Environment variablen
    - konfiguriert in `config/genesis_sources.yml`
- GeoJSON nicht automatisch, sind manuell bereitgestellt
    - Vorerst nur Kreisebene


## Metriken

- Eine Komplikation stellen die Altersgruppen bei der Normierung dar. Viele Metriken beziehen sich auf eine gewählte (Sub-) Population, und könnten auch nach Altersgruppe berechnet werden.
- In verschiedenen Quellen sind verscheidene Altersgruppen-Definitionen zu finden (v.a. auf Gemeinde-Ebene), diese müssen ggf. konsistent gemacht werden.


| Metrik                          | Quelle auf Kreisebene | Quelle                             | Fertig |
| :------------------------------ | :-------------------- | :--------------------------------- | :----- |
||||
| **Basis Kennzahlen**            |                       |                                    ||
|     Gebietsfläche               | 11111-0002            | Destatis                           | ✅ |
|     Anz. Einwohner:innen        | 12411-02-03-4         | Regio                              | ✅ |
|     Zuzüge                      | 12711-01-03-4         | Regio                              | ✅ |
|     Fortzüge                    | 12711-01-03-4         | Regio                              | ✅ |
|     Sterbefälle                 | 12613-01-01-4         | Regio                              | ✅ |
|     Lebendgeburten              | 12612-01-01-4         | Regio                              | ✅ |
|     Median Alter                | 12411-10-01-4         | Regio                              | ✅ |
|     Durchschnitts-Alter (Mean)  | 12411-07-01-4         | Regio                              | ✅ |
|||||
| **Errechnete Kennzahlen**       |                       |                                    ||
|     Wanderung                   | Zuzüge - Fortzüge     | Berechnung                         | ✅ |
|     Geburtenrate                | Geburten / 1000 EW    | Berechnung                         ||
|     Einwohner:innen-Dichte      | EW / km²              | Berechnung                         ||
|     Altenquotient               | (18-64) / (65+)       | Berechnung                         | ✅ |
|     Anteil 65+                  | 65+ / (<65)           | Berechnung                         ||
|     Greying Index               | (80+) / (65-79)       | Berechnung                         ||
|     Jugend Quotient             | (0-17) / (18-64)      | Berechnung                         ||


## Datasets

Es gibt derzeit zwei Use-Cases, mit je eigenem Dataset:
- Unpivot Ansicht, wo eine Kennzahl als Filter ausgewählt werden kann (daher als Spalte vorhanden)
- Pivot Ansicht, wo Kennzahlen als einzelne Spalten vorhanden vorliegen.
  Diese werden v.a. für die korrekte Berechnung von nicht-additiven Kennzahlen benötigt.
  Hier kommen Supersets Metriken zum Einsatz.
