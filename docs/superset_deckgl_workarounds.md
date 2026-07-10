
# Learnings and Workarounds to get Maps via GeoJson working in Superset 6.1


## Deck.gl geojson polygon type

- Desired chart type, but currently has bugs.
- Advantages:
    - Configure tooltips easily via Handlebar template ("Customize tooltips template")
    - See https://docs.preset.io/docs/deckgl-chart
    - Can set coloars automatically based on data and a chose colormap
    - Has a legend
    - We can aggregate in the chart
        - note however: when aggregating, the column we want to aggregate (like "Wert") **must not** appear in the tooltip or superset adds it to the `group by` in the background, which breaks the aggregation. This is likely a bug.
        - [Related issue](https://github.com/apache/superset/issues/38913)
        - As of 6.1.0 we also cannot add Metrics or custom SQL to the handle bars tooltip — which is annoying: Coupled with the bug above, we therefore cannot show in the tooltip the key metric that causes the colorcoding.
            - Trying to add them into javascript tooltip, raises: _Binder Error: GROUP BY clause cannot contain aggregates! LINE 24: SUM("Wert")_
            - However, we _can_ add the aggregated metric name to the tooltip _without_ adding it as extra info to tooltip content: e.g. `{{my_metric_name}}`.
- Bugs (as of 6.1.0):
    - Does not render multi-polygons, or holes inside closed loops. but fixed in [PR 40100](https://github.com/apache/superset/pull/40100)
    - Color of legend broken, depending on the browser, because the color markers are just glyphs (so that the color can be hard-coded depending on the font used for rendering)

## Deck.gl geojson chart type (not polygon)

In Superset 6.1, the fill color opacity for deck.gl GeoJSON charts cannot be set through the GUI (only stroke color).
This workaround patches the chart's stored parameters directly in the Superset PostgreSQL meta database.

- Colors cannot be inferred based on a metric, but have to be hardcoded into the properties of the geojson (or injected into the dataset via jinja)
- Chart settings (GeoJson Settings):
    - Enable Filled
    - Stroked can be enabled or disabled.
- Configure Tooltip via Javascript ("Customize tooltips template" which uses handlebars does not work for this chart type)

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
WHERE slice_name = 'gl_geojson_with_tooltip';
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



---

## Dosu Resources about the grouping issue in polygon chart:

**Columns being added to the group by is by design in the legacy deck.gl implementation**, not an explicitly reported bug. In `BaseDeckGLViz.query_obj()`, tooltip columns (`js_columns` / "extra data for tooltip") are intentionally appended to the GROUP BY list [[1]](https://github.com/apache/superset/blob/829e4d92d91ceae4b43b1ed3b063ffe45377799c/superset/viz.py#L1692-L1693):

```python
if self.form_data.get("js_columns"):
    group_by += self.form_data.get("js_columns") or []
```

So any column you place in "extra data for tooltip" becomes a dimension, which is why adding "Wert" there caused it to appear in GROUP BY and broke your `Sum(Wert)` aggregation.

**This was actually fixed in 2025** for charts that have been migrated to the newer plugin architecture — [PR #34276](https://github.com/apache/superset/pull/34276) and [PR #34859](https://github.com/apache/superset/pull/34859) changed the behavior so tooltip columns are added to the query's `columns` array instead of `groupby`. However, the deck.gl Polygon chart still uses the legacy `viz.py` path (`useLegacyApi: true`) [[2]](https://github.com/apache/superset/blob/829e4d92d91ceae4b43b1ed3b063ffe45377799c/superset-frontend/plugins/legacy-preset-chart-deckgl/src/layers/Polygon/index.ts#L34), so it hasn't benefited from that fix yet.

**I did not find an existing issue that specifically reports this tooltip-breaks-aggregation problem.** The closest tracking item is [issue #41047](https://github.com/apache/superset/issues/41047) (created June 15, 2026), which tracks migrating deck.gl charts to the V1 plugin architecture — completing that migration would bring in the tooltip fix.


---

## Dosu on Polygon Chart metric not available

Paul:
When using the deck.gl geojson polygon chart type, I want to show the metric that I use for color coding also as a tooltip on hover. however, i cannot drag the metrict into the "Tooltip contents" section (or select it there). Thus, there is currently no way to show the main metric, except putting a custom tooltip html code (handlebar) into the "Customize tooltips template". The problem is, that this requires insecure talisman settings, as far as i can tell? Is this a reported bug?

Dosu:
This appears to be a **design limitation** rather than a previously reported bug. From what I can find, the deck.gl polygon chart in Superset does not have a fully functional "Tooltip Contents" drag-and-drop panel that accepts metrics — the main metric used for color coding isn't available for selection in that UI control [[1]](https://github.com/apache/superset/issues/36779).

I was unable to find a specific GitHub issue tracking this exact problem. It may not have been formally reported yet.

Regarding your concern about the Handlebars tooltip template and Talisman/CSP settings: the **Handlebars template** itself shouldn't require `unsafe-eval` or `unsafe-inline` CSP directives — it's the **JavaScript-based** tooltip customization (in the "Advanced" section) that requires relaxing CSP to allow `'unsafe-eval'`. However, note that Superset 6.0 introduced stricter HTML sanitization in tooltips, so even basic HTML in Handlebars templates may get escaped [[1]](https://github.com/apache/superset/issues/36779).

**In summary:**

- The inability to select the color-coding metric in "Tooltip contents" is a known limitation, but I couldn't confirm it's been filed as a bug.
- If the Handlebars approach is triggering CSP violations for you, it may be related to how your deployment's Talisman settings interact with the template rendering, but this isn't a widely documented issue.

If you'd like, I could search the codebase for how the tooltip_contents control is configured for deck.gl charts to better understand what's happening technically — or you may want to consider filing a GitHub issue to get this on the maintainers' radar.

Paul:
Please be more specific. I want to use the handlebar based template for tooltips. no javascript. if i place a custom template the, i get on hover call to Function() blocked by CS and in the console: Content-Security-Policy: The page’s settings blocked a JavaScript eval (script-src) from being executed because it violates the following directive: “script-src 'self' 'strict-dynamic' 'nonce-x-IhzVSVKGFe6VavGjDuflVM8aBw5H6q'” (Missing 'unsafe-eval')`

this does not happen when:
- the template is empty (then we get a default styled of the added metrics / columns)
- we have not added metics / columns (then we get an ugly default hover, that contrains centroid of long / lat but it also contains the metric that is used for color-coding)

Dosu:
Thanks for the clarification — this makes sense now. Here's what's happening:

The deck.gl charts in Superset **do not actually use Handlebars** for their tooltip template field. Despite what the UI label might suggest, the "Customize tooltips template" field is processed as **JavaScript** using a sandboxed `vm.runInNewContext()` execution environment [[1]](https://github.com/apache/superset/blob/829e4d92d91ceae4b43b1ed3b063ffe45377799c/superset-frontend/plugins/legacy-preset-chart-deckgl/src/utils/sandbox.ts#L45-L65). Internally, this calls `sandboxedEval()` which uses dynamic code evaluation — and that's exactly what triggers the CSP `'unsafe-eval'` violation you're seeing [[2]](https://github.com/apache/superset/blob/829e4d92d91ceae4b43b1ed3b063ffe45377799c/superset-frontend/plugins/legacy-preset-chart-deckgl/src/layers/common.tsx#L44-L46).

So the behavior you're observing is:

- **Empty template** → Superset uses a built-in default tooltip renderer (pure React components, no eval), which shows the metric/columns you've configured. No CSP issue.
- **No metrics/columns added** → A different default kicks in that shows raw feature properties (centroid, metric used for color). Also no CSP issue.
- **Any custom template provided** → Superset tries to evaluate it as JavaScript via `sandboxedEval()`, which requires `'unsafe-eval'` in your CSP policy. This is the violation you're hitting.

**This is effectively a bug/limitation**: there's no CSP-safe way to customize the tooltip content in deck.gl charts. The only options are:

1. Use the default tooltip (leave the template empty) and accept that you can't customize formatting
2. Add `'unsafe-eval'` to your CSP `script-src` directive (security tradeoff)

The fact that the main color-coding metric isn't available in the "Tooltip contents" drag-and-drop section AND the only customization path requires `'unsafe-eval'` creates a gap where you can't display that metric in a tooltip without relaxing security.

I wasn't able to find a specific GitHub issue tracking this combination of problems. This seems worth reporting — the core issues being: (1) the color-coding metric should be selectable in tooltip contents, and (2) the tooltip template system should ideally use a CSP-safe rendering approach (actual Handlebars with precompilation, or a template engine that doesn't need `eval`).
