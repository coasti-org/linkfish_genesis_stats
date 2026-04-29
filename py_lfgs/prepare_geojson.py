import json
import logging
from dataclasses import dataclass
from pathlib import Path
from typing import Annotated, Any

import typer
from shapely.geometry import LineString

app = typer.Typer()
log = logging.getLogger("lfgs_download")


@app.command()
def geosjon_to_superset_csv(
    input_geojson: Annotated[
        Path,
        typer.Option(
            "--input-geojson",
            "-i",
            help="Path to the input GeoJSON FeatureCollection file.",
            exists=True,
            file_okay=True,
            dir_okay=False,
        ),
    ],
    output_csv: Annotated[
        Path,
        typer.Option(
            "--output-csv",
            "-o",
            help="Path to the output CSV file for Superset.",
            file_okay=True,
            dir_okay=False,
        ),
    ],
    tolerance: Annotated[
        int,
        typer.Option(
            "--tolerance",
            "-t",
            help="Geometry simplification tolerance; higher means simpler shapes.",
            show_default=True,
        ),
    ] = 100,
) -> None:
    """Convert a GeoJSON into a CSV for Superset (pipe-delimited)."""

    data = json.loads(input_geojson.read_text(encoding="utf-8"))
    data = simplify_geojson(data, tolerance=tolerance)

    # one collection (with one feature) per landkreis, for one row in the csv
    collections = split_feature_collection(data)

    with output_csv.open("w", encoding="utf-8") as f:
        f.write("code_kreis|desc_kreis|fact_geojson\n")

        for collection in collections:
            # the properties are specific to our particular GeoJSON for landkreise
            properties = collection["features"][0]["properties"].copy()
            code_kreis = properties["schluessel"]
            desc_kreis = properties["gen"]
            log.debug(f"Writing {code_kreis} {desc_kreis} with stripper properties")

            # specific workaround for kreise - in the geojson downloaded from
            # https://regionalatlas.statistikportal.de on 2026-04-30
            # codes for e.g. hamburg '02000' was incorrectly saved to '02'
            code_kreis = f"{code_kreis:05}"

            # strip properties, we want to set them later in DBT via SQL
            collection["features"][0]["properties"] = {}
            collection["features"][0].pop("id", None)

            f.write(f'{code_kreis}|{desc_kreis}|{json.dumps(collection)}\n')


def split_feature_collection(geojson: dict[str, Any]) -> list[dict[str, Any]]:
    """
    Convert the FeatureCollection of a GeoJSON object into individual Features.

    We need this to get an individual shape per row of data in superset,
    whereas GeoJSON typically has many shapes in a single Collection.

    Returns a list of dictionaries, where each dictionary corresponds to a feature.

    Example:
    ```
    before = {
        "type": "FeatureCollection",
        "features": [
            {
                "type": "Feature",
                "id": 523354,
                "geometry": {
                    "type": "Polygon",
                    "coordinates": [
                        [
                            [511892.592, 5892281.709],
                            [512193.162, 5892646.915],
                            [526513.753, 6075133.412]
                        ]
                    ]
                },
                "properties": {
                    "id": 523311,
                    "schluessel": "01001",
                    "gen": "Flensburg",
                    "jahr": 2024,
                    "ai2001": 13.7
                }
            },
            {
                "type": "Feature",
                "id": 523312,
                "geometry": {
                    "type": "Polygon",
                    "coordinates": [
                        [
                            [575841.57, 6032148.032],
                            [576646.888, 6030568.196],
                            [575841.57, 6032148.032]
                        ]
                    ]
                },
                "properties": {
                    "id": 523312,
                    "schluessel": "01002",
                    "gen": "Kiel",
                    "jahr": 2024,
                    "ai2001": 14.2
                }
            }
        ]
    }

    after = [
        {
            "type": "FeatureCollection",
            "features": [
                {
                    "type": "Feature",
                    "id": 523354,
                    "geometry": {
                        "type": "Polygon",
                        "coordinates": [
                            [
                                [511892.592, 5892281.709],
                                [512193.162, 5892646.915],
                                [526513.753, 6075133.412]
                            ]
                        ]
                    },
                    "properties": {
                        "id": 523311,
                        "schluessel": "01001",
                        "gen": "Flensburg",
                        "jahr": 2024,
                        "ai2001": 13.7
                    }
                }
            ]
        },

        {
            "type": "FeatureCollection",
            "features": [
                {
                    "type": "Feature",
                    "id": 523312,
                    "geometry": {
                        "type": "Polygon",
                        "coordinates": [
                            [
                                [575841.57, 6032148.032],
                                [576646.888, 6030568.196],
                                [575841.57, 6032148.032]
                            ]
                        ]
                    },
                    "properties": {
                        "id": 523312,
                        "schluessel": "01002",
                        "gen": "Kiel",
                        "jahr": 2024,
                        "ai2001": 14.2
                    }
                }
            ]
        }
    ]
    ```
    """
    return [
        {"type": "FeatureCollection", "features": [feature]}
        for feature in geojson["features"]
    ]


def simplify_geojson(geojson: dict[str, Any], tolerance=0.009):
    """
    Reduce the complexity of geometries in a GeoJSON object using shapely.

    This speeds up rendering and reduces file size.

    Arguments:
    - `data`: A GeoJSON object as a Python dictionary.
    - `tolerance`: For `shapely.simplify`. Higher values result in simpler shapes.

    Example:
    ```
    with open(input_file, 'r') as f:
        data = load(f)

    simplified_data = simplify_geojson(data, tolerance=100)

    with open(output_file, 'w') as f:
        dump(simplified_data, f)
    ```

    Credit: https://github.com/anishdhakal15/geojson-simplifyer
    """
    if "features" not in geojson:
        return geojson

    geojson = geojson.copy()
    simplified_features = []
    for feature in geojson["features"]:
        geometry = feature["geometry"]
        if geometry["type"] == "LineString":
            feature["geometry"]["coordinates"] = (
                LineString(geometry["coordinates"])
                .simplify(tolerance, preserve_topology=True)
                .coords[:]
            )
        elif geometry["type"] == "Point":
            pass
        elif geometry["type"] == "Polygon":
            simplified_exterior = LineString(geometry["coordinates"][0]).simplify(
                tolerance, preserve_topology=True
            )
            simplified_interiors = [
                LineString(interior).simplify(tolerance, preserve_topology=True)
                for interior in geometry["coordinates"][1:]
            ]
            feature["geometry"]["coordinates"] = [simplified_exterior.coords[:]] + [
                i.coords[:] for i in simplified_interiors
            ]
        elif geometry["type"] == "MultiPolygon":
            simplified_polygons = []
            for polygon in geometry["coordinates"]:
                simplified_exterior = LineString(polygon[0]).simplify(
                    tolerance, preserve_topology=True
                )
                simplified_interiors = [
                    LineString(interior).simplify(tolerance, preserve_topology=True)
                    for interior in polygon[1:]
                ]
                simplified_polygons.append(
                    [simplified_exterior.coords[:]]
                    + [i.coords[:] for i in simplified_interiors]
                )
            feature["geometry"]["coordinates"] = simplified_polygons
        else:
            print(f'Warning: Unsupported geometry type "{geometry["type"]}"')
        simplified_features.append(feature)
    geojson["features"] = simplified_features

    return geojson


if __name__ == "__main__":
    app()
