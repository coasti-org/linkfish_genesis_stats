"""Rollout helpers invoked from Copier tasks."""

import shutil
from pathlib import Path

SAMPLE_CONFIG_FILES = [
    "config/*",
    "python/orchestration.py",
]

# TODO: we should check and use the data dir configured via copier
DATA_DIRS = [
    "data",
    "logs",
]


def copy_missing_sample_configs():
    """Copy sample config files only when the destination file does not exist."""

    print_fence("Copying sample files")

    src_dir = Path("./samples/")
    dst_dir = Path("./")

    for file_name in SAMPLE_CONFIG_FILES:
        for src_file in sorted(src_dir.glob(file_name)):
            dst_file = dst_dir / src_file.relative_to(src_dir)

            try:
                if dst_file.exists():
                    print(f"Skipping sample: {str(dst_file)} already exists")
                    continue

                shutil.copy2(src_file, dst_file)
                print(f"Copied sample: {str(dst_file)}")
            except Exception as e:
                print(f"Failed to copy: {str(dst_file)}\n{e}")


def create_data_directories():
    """Create required runtime folders if they are missing."""

    print_fence("Creating required directories")

    for dir in DATA_DIRS:
        try:
            Path(dir).mkdir(parents=True, exist_ok=True)
            print(f"Checked data directory: {dir}")
        except Exception as e:
            print(f"Failed to create directory: {dir}\n{e}")


def print_fence(message: str):
    fence_width = max(40, len(message) + 4)
    fence_line = "=" * fence_width
    print(f"\n{fence_line}")
    print(f"  {message}")
    print(f"{fence_line}\n")


def main():
    create_data_directories()
    copy_missing_sample_configs()


if __name__ == "__main__":
    main()
