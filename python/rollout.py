"""Rollout helpers invoked from Copier tasks."""
# TODO: decide where to place files needed only for rollout, copier meta, etc
# TODO: make `dpt deps` part of this, and remove from orchestration.

from __future__ import annotations

import shutil
from pathlib import Path

SAMPLE_CONFIG_FILES = [
    "config/linkfish_genesis_stats.code-workspace",
    "config/profiles.yml",
    "config/genesis_sources.yml",
    "python/orchestration.py"
]


def print_fence(message: str) -> None:
    fence_width = max(40, len(message) + 4)
    fence_line = "=" * fence_width
    print(f"\n{fence_line}")
    print(f"  {message}")
    print(f"{fence_line}")


def copy_missing_sample_configs() -> None:
    """Copy sample config files only when the destination file does not exist."""

    print_fence("Copying sample files")

    src_dir = Path("./samples/")
    dst_dir = Path("./")

    for file_name in SAMPLE_CONFIG_FILES:
        src_file = src_dir / file_name
        dst_file = dst_dir / file_name

        try:
            if dst_file.exists():
                print(f"Skipping sample: {str(dst_file)} already exists")
                continue

            shutil.copy2(src_file, dst_file)
            print(f"Copied sample: {str(dst_file)}")
        except Exception as e:
            print(f"Failed to copy: {str(dst_file)}\n{e}")


def main() -> None:
    copy_missing_sample_configs()


if __name__ == "__main__":
    main()

