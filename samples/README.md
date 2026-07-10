Enthält Beispiele für Konfigurationsdateien, die während der Installation an die richtige Stelle kopiert werden können.

Dabei entsprechen die Quell-Dateipfade innerhalb von `samples` den Zielpfaden innerhalb des parent repos.
Siehe `copier.yml`.

# Motivation

- Config Dateien sollen in die Versionskontrolle des Coasti Repos, das alle Produkte umschließt.
- Offensichtlich sollen sie auch von Benutzer:innen des Produkts bearbeitet werden.
- Wenn wir die Sample-Configs direkt am Ziel ablegen würden, wären sie Teil des Produkts, und würden bei Updates automatisch überschrieben.
- Daher separater Ordner, und nur kopieren wenn nicht vorhanden. Bei Updates kann dann ggf manuell kopiert werden, und via git diffs geprüft, was sich geändert hat.
