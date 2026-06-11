# Ordnerstruktur


Jedes Coasti Produkt erwartet folgende Ordner.
Die Idee ist, dass diese in allen Coasti-Produkten vorhanden sind, damit sich Nutzer:innen in neuen Produkten schnell zurechtfinden.

- `config` (Ort für alle Konfigurationsdateien)
- `data` (Ingestion, temporäre Daten, v.a. ETL-Ergebnisse als DuckDB)
- `logs` (Logdateien aus diesem Produkt)

# Benötigte Dateien

Beim erstellen eines neuen Coasti Produkts werden mindestens folgenden Dateien benötigt:

- `coasti.yml` Metadaten für dieses Produkt, v.a. Version und Produkt-ID.
- `copier.yml` Coasti verwendet unter der Haube Copier, um Content-Pakete bereitzustellen.
- `{{ _copier_conf.answers_file }}.jinja` Wird von Copier benötigt.
- `config/.env.jinja` Template für eine `.env`-Datei, die Konfigurationsdetails enthalten soll.
- `config/activate` Logik zum Laden von `.env` und zum Sourcen der venv, betriebssystemabhängig.
- [x] @FD+MB: `activate` -> in `config`?
- [x] Orchestrierung wo? `.sample` und dann soll Copier eine Datei im Root platzieren?

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
  - IDs sind einfach Strings (Buchstaben und Unterstriche, Kleinbuchstaben empfohlen)
  - Darf keine Sonderzeichen außer Unterstrichen enthalten (`_`)
  - Versionsnummern sind nicht Teil der ID
- Die Produkt-ID taucht an folgenden Stellen auf:
  - `coasti.yml` für die Installation benötigt, und bestimmt u.a. den Installations-Pfad und den Eintrag in `/coasti/config/products.yml`
     Hier ist das `/coasti/products/linkfish_genesis_stats`.
  - `pyproject.toml` Der Download der Quelldaten erfolgt in Python. Daher pflegen wir ein Python Projekt, und nutzen auch dafür die selbe ID (aber passen Sonderzeichen an die python-übliche Konvention mit Bindestrichen an)
  - `dbt_project.yml` ETL-Schritte finden an unserem Bsp in DBT statt, und DBT schreibt eine feste Projekt-Struktur inklusive einer ID vor.
  - Ausgabename für DuckDB-Datei, das Ergebnis der ETL-Schritte:
    - DBT schreibt nach `data/duckdb/linkfish_genesis_stats.duckdb`
    - Link in `/coasti/data/linkfish_genesis_stats/duckdb/linkfish_genesis_stats.duckdb` um zentral an Daten aller Produkte zu kommen
    - Wird kopiert nach `/coasti/data/linkfish_superset/linkfish_genesis_stats.duckdb` (das ist eine minimierte, Version, die nur Mart-Schichten enthält, und in Superset genutzt wird)


## ID-Kürzel

- Das ID-Kürzel (`lfgs`) sollte möglichst kurz sein, und nur aus wenigen Buchstaben bestehen.
- Taucht an folgenden Stellen auf:
  - Als Präfix für Environemnt_variablen, z.b. `LFGS_DUCKDB_DATAMART_PATH` in `config/.env`
  - Als Präfix für DBT Profile, z.b. `lfgs_duckdb` in `config/profiles.yml`
  - Im Schema der Seeds `seed_lfgs`
  - Ordnernamen für Software-spezifische Teile, z.b. `dbt` und `python` für unsere DBT und Python Codes. Obwohl diese Ordnername frei gewählt werden können, lohnt es sich diese nicht einfach `dbt` und `python` zu nennen (um Paket-Namenskonventionen zu folgen), und das ID-Kürzel zu nehmen, um die Namen kurz zu halten.

## Kurze ID (Präfix)
- eine __short_id__ als Präfix vorschlagen, alphanumerisches Akronym (keine Symbole, keine Zeichenbegrenzung, aber kurz halten. hier: `gstat`)
    - Verwendung in dbt `profiles.yml`?
    - Präfixe für Umgebungsvariablen
- [x] Wollen wir diese Dinge präfixen? Ja, gut für Umgebungsvariablen, und bei Profiles schadet es nicht.


# Für die Coasti-Installation benötigte Metadaten
- in `coasti.yml` abgelegt
- wird im Git-Schritt abgefragt, um vor der Verwendung von Copier die Repo-Verbindung herzustellen und den Repo-Zugriff zu prüfen, bevor weitere Fragen beantwortet werden
- Standard-Installationsordnername für das Produkt ist die ID.
- Copier-Antworten liegen normalerweise in `config/install_answers.yml`, aber wir lassen Content-Ersteller:innen entscheiden (solange es der Copier-Konvention folgt, funktioniert es)
- `cosati.yml` muss beantworten, wo der Einstiegspunkt ist
