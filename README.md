# Coasti Demo-Content-Paket: Statistik
Beispiel eines Contentpakets für Coasti das Statistikdaten von Genesis nutzt

- Bisher essentiell eine abgespeckte Version von linkFISH Statistik+
- Trennung Kreis als kleinste Einheit vs Gemeinde als kleineste Einheit
    - Dafür konsistentes Model-Prefix an den DBT Modellen, Seeds etc
    - Bisher Fokus nur Kreisebene


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


| Metrik                          | Quelle auf Kreisebene | Quelle                             |
| :------------------------------ | :-------------------- | :--------------------------------- |
|
| **Basis Kennzahlen**            |                       |                                    |
|     Gebietsfläche               | 11111-0002            | Destatis                           |
|     Anz. Einwohner:innen        | 12411-02-03-4         | Regio                              |
|     Zuzüge                      | 12711-01-03-4         | Regio                              |
|     Fortzüge                    | 12711-01-03-4         | Regio                              |
|     Sterbefälle                 | 12613-01-01-4         | Regio                              |
|     Lebendgeburten              | 12612-01-01-4         | Regio                              |
|     Median Alter                | 12411-10-01-4         | Regio                              |
|     Durchschnitts-Alter (Mean)  | 12411-07-01-4         | Regio                              |
|
| **Errechnete Kennzahlen**       |                       |                                    |
|     Wanderung                   | Zuzüge - Fortzüge     | Berechnung                         |
|     Geburtenrate                | Geburten / 1000 EW    | Berechnung                         |
|     Einwohner:innen-Dichte      | EW / km²              | Berechnung                         |
|                                 |                       |                                    |
|     Altenquotient               | (18-64) / (65+)       | Berechnung                         |
|     Anteil 65+                  | 65+ / (<65)           | Berechnung                         |
|     Greying Index               | (80+) / (65-79)       | Berechnung                         |
|     Jugend Quotient             | (0-17) / (18-64)      | Berechnung                         |


## Datasets

Es gibt zwei Use-Cases:
- unpivot Ansicht, wo eine Metrik als Filter ausgewählt werden soll (daher als Spalte vorhanden)
- pivot Ansicht, wo Metriken dann auch als solche in Superset zur Verfügung stehen
- GeoJSON workarounds: In der Karten-Darstellung kann Superset nicht über Dimensionen aggregieren.
  Daher müssen wir die Dimensionalitätsreduktion selbst vornehmen: Es darf pro Polygon (Kreis) und Filter (z.b. Jahr) nur noch einen Wert geben. Alle doppelt auftretenden Zeilen müssen durch Filter entfernt werden, oder bereits voraggregiert sein.

**Spalten**
Die Auswahl dieser Spalten definiert, wonach im Frontend dann gefiltert werden kann.
Alle Metriken müssen auf dieser kleinsten Einheit aufgelöst werden.
Z.b. wenn es eine Dimensions-Spalte "Geschlecht" gibt, müssen alle Metriken für alle auftretenden Werte innerhalb der Geschlecht-Spalte vorhanden sein.
Das erfordert mitunter, dass Metriken wo dies nicht der Fall ist, mit einem Platzhalter für die Dimension gefüllt werden (wir nehmen `Null` wie im Datawarehouse üblich)

**Datasets**
- ds_regio_kennzahl_kreis (unpivot)
    - all metrics from above
    - Kennzahl selbst `code_kennzahl`
    - Weitere Eigenschaften
        - code_kreis
        - desc_kreis
        - code_stichtag (Datenstand des Downlaods)
        - fact_polygon (GeoJSON)
        - code_geschlecht
        - desc_geschlecht
        - code_altersgruppe
        - desc_altersgruppe

- ds_regio_kennzahl_kreis_pivot
    - basierend auf siehe oben
    - pro Kennzahl bekommen wir jetzt eine Spalte (weniger Zeilen)

- ds_regio_kennzahl_kreis_geojson
    - basiert auf unpivot
    - Group by: Kennzahl, Jahr (Stichtag selbe Info, nur besser aufgelöst), Polygon, Kreis
    - Fakt Spalten
        - fact_wert
        - fact_vorjahr
        - fact_wert_anteilig
        - fact_wert_anteilig_vorjahr
    - Extra Spalten für

