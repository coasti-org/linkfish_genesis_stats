
# Workaround: Superset deck.gl GeoJSON — Set Fill Color Opacity via SQL

In Superset 6.1, the fill color opacity for deck.gl GeoJSON charts cannot be set through the GUI (only stroke color).
This workaround patches the chart's stored parameters directly in the Superset PostgreSQL meta database.

## Steps

### 1. Open a psql session inside the Superset Postgres container

```bash
docker exec -it superset-postgres /bin/bash
psql -U superset -d superset
```

### 2. Set the fill color opacity to 0 (fully transparent) for the target chart

Replace `'test_gj'` with the actual chart name (`slice_name`).
The `a` key in `fill_color_picker` controls the alpha (opacity) channel (range: `0`–`1`).

```sql
UPDATE slices
SET params = jsonb_set(params::jsonb, '{fill_color_picker,a}', '0'::jsonb)::text
WHERE slice_name = 'test_gj';
```

```bash
exit
```

### 3. Flush the Redis cache and restart Superset

Required so the UI picks up the updated chart parameters.

```bash
docker exec -it superset-redis redis-cli -a secure_redis_password FLUSHALL
docker restart superset-app
```
