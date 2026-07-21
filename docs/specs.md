# Ordnerstruktur

Jedes Coasti Produkt erforderte einige feste Dateien und Ordner.
Die Idee ist, dass diese in allen Coasti-Produkten vorhanden sind, damit sich Nutzer:innen in neuen Produkten schnell zurechtfinden.

|     | Pflicht | Pfad                                  | Kommentar
| --- | ------- | ------------------------------------- | ----------------------------------------------------------------------------------------------------------
| 📁  | ●       | `config/`                             | Ordner für alle Konfigurationen, z.b.
| 📄  | ○       | `config/.env.jinja`                   | Template für eine `.env`-Datei mit Connection-Strings und Secrets
| 📁  | ●       | `data/`                               | Ingestion und temporäre Daten, v.a. ETL-Ergebnisse als DuckDB
| 📁  | ●       | `logs/`                               | Logdateien aus diesem Produkt
| 📄  | ●       | `coasti.yml`                          | Metadaten für dieses Produkt, v.a. Version und Produkt-ID
| 📄  | ●       | `copier.yml`                          | Coasti verwendet unter der Haube Copier, um Content-Pakete bereitzustellen
| 📄  | ●       | `{{ _copier_conf.answers_file }}.jinja` | Wird von Copier für Updates benötigt
| 📄  | ○       | `coasti_install_questions.yml`        | Fragen, die Nutzer:innen während der Installation gestellt werden
| 📁  | ○       | `dbt/`                                | Ordner für DBT-Teilprojekt (ETL-Modelle, Seeds)
| 📁  | ○       | `python/`                             | Ordner für Python-Teilprojekt (Downloader, Skripte, Abhängigkeiten)
| 📁  | ○       | `python/.venv`                        | Installierte Python-Umgebung inklusive DBT-Runtime
| 📁  | ○       | `docs/`                               | Dokumentation
| 📁  | ○       | `superset/`                           | Frontend-Content (Berichtsportal als YAML), deploybar mit [superset-io](https://github.com/coasti-org/superset_io)
| 📁  | ○       | `samples/`                            | Beispiel-Dateien; werden während der Installation oft automatisch von hier kopiert

# Einzigartige Produkt-Identifier

Jedes Produkt benötigt eine einzigartige ID, um es zu erkennen und unterscheidbar zu machen, sowie ein ID-Kürzel, das als Präfix verwendet wird, z.b. für Environment-Variablen.

An unserem Beispiel:

| Identifier in `coasti.yml`  | Gewählter String         |
| --------------------------- | ------------------------ |
| `id`                        | `linkfish_genesis_stats` |
| `id_shorthand`              | `lfgs`                   |


## Produkt-ID

- Die Produkt-ID (`linkfish_genesis_stats`) ist grundlegen ein beliebiger String, hat aber ein paar Auflagen:
  - Sollte dem Muster `company_my_product` folgen
  - IDs sind Strings (Buchstaben und Unterstriche, Kleinbuchstaben empfohlen)
  - Darf keine Sonderzeichen außer Unterstrichen enthalten (`_`)
  - Versionsnummern sind nicht Teil der ID
- Die Produkt-ID taucht an folgenden Stellen auf:
  - `coasti.yml` für die Installation benötigt, und bestimmt u.a. den Installations-Pfad und den Eintrag in `/coasti/config/products.yml`
     Hier ist das `/coasti/products/linkfish_genesis_stats`.
  - `pyproject.toml` Der Download der Quelldaten erfolgt in Python. Daher pflegen wir ein Python Projekt, und nutzen auch dafür die selbe ID (aber passen Sonderzeichen an die python-übliche Konvention an)
  - `dbt_project.yml` ETL-Schritte finden an unserem Bsp in DBT statt, und DBT schreibt eine feste Projekt-Struktur inklusive einer ID vor.
  - Ausgabename für DuckDB-Datei, das Ergebnis der ETL-Schritte:
    - DBT schreibt nach `./data/duckdb/linkfish_genesis_stats.duckdb`
    - Wird kopiert nach `/coasti/data/superset_docker/linkfish_genesis_stats.duckdb` (als minimierte Version, die nur Mart-Schichten enthält, und in Superset genutzt wird)


## ID-Kürzel

- Das ID-Kürzel (`lfgs`) sollte möglichst kurz sein, und nur aus wenigen Buchstaben bestehen.
- Taucht an folgenden Stellen auf:
  - Als Präfix für Environemnt_variablen, z.b. `LFGS_DUCKDB_DATAMART_PATH` in `config/.env`
  - Als Präfix für DBT Profile, z.b. `lfgs_duckdb` in `config/profiles.yml`
  - Im Schema der Seeds `seed_lfgs`
  - Ordnernamen für Software-spezifische Teile, z.b. `dbt` und `python` für unsere DBT und Python Codes. Obwohl diese Ordnername frei gewählt werden können, lohnt es sich diese nicht einfach `dbt` und `python` zu nennen (um Paket-Namenskonventionen zu folgen), und das ID-Kürzel zu nehmen, um die Namen kurz zu halten.


# Für die Coasti-Installation benötigte Metadaten

- Die wichtigsten Metadaten sind in `coasti.yml` abgelegt.
- Diese wird im via git von `coasti install` abgefragt, um vor der Verwendung von Copier die Repo-Verbindung herzustellen und den Repo-Zugriff zu prüfen, bevor weitere Fragen beantwortet werden.
- Standard-Installationsordnername für das Produkt ist die ID.
- Copier-Antworten liegen nach der Installation normalerweise in `./coasti_install_answers.yml`, aber wir lassen Content-Ersteller:innen entscheiden (solange es der Copier-Konvention folgt, funktioniert es).
- Einstiegsounkt ist in der `copier.yml` definiert: Am Ende der Installation wird angezeigt, was nächste Schritte sind.
