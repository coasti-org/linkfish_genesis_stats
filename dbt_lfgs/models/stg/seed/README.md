

# Staging

- An diesem Beispiel sind die Staging Modelle recht redundant (da wir nur Seeds laden) aber dienen der Veranschaulichung.
  In Der Ordnername und das Präfix `seed` entsprechen hier der Datenquelle, und könnte z.b. `lissa` sein falls wir Sozialdaten nutzen, die aus der Lissa-Software stammen.
- Als erstes casten wir in einer eigenen CTE zu erwarten Datentypen.
  In Projekten mit verschiedenen Datenquellen ist dies hilfreich um Fehler zeitig zu erkennen — Vor allem wenn aus heterogenen Quellen geladen wird (Parquet vs MSSQL).
- Das Muster mit `select * from final` macht das Debugging einfacher sobald weitere Zwischenschritte benötigt werden. (Siehe offizieller [DBT Style Guide](https://docs.getdbt.com/best-practices/how-we-style/2-how-we-style-our-sql?version=1.12#example-sql))
- Der Anfang der Staging SQL Files ist ein guter Ort um Kommentare zur Funktionsweise, der Relevanz und dem Inhalt der gestagten Tabelle zu hinterlegen.
