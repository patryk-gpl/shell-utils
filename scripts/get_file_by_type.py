#!/usr/bin/env python3
import argparse
import os
from collections import defaultdict


class FileCounter:
    EXCLUDED_FOLDERS = (
        ".venv",
        ".git",
        ".pytest_cache",
        ".ruff_cache",
        ".vscode",
        ".scannerwork",
        "node_modules",
    )

    def __init__(self, folder_path):
        self.folder_path = folder_path

    def count_files_by_extension(self):
        file_count_by_extension = defaultdict(int)

        for root, _, files in os.walk(self.folder_path):
            if any(folder in root for folder in self.EXCLUDED_FOLDERS):
                continue

            for file in files:
                _, file_extension = os.path.splitext(file)
                if file_extension:
                    file_count_by_extension[file_extension.lower()] += 1

        return file_count_by_extension


class SortByCountStrategy:
    def sort(self, results):
        return sorted(results.items(), key=lambda x: x[1], reverse=True)


class SortByExtensionStrategy:
    def sort(self, results):
        return sorted(results.items(), key=lambda x: x[0][1:].lower())


class MainApp:
    def __init__(self, folder_path, sorting_strategy):
        self.file_counter = FileCounter(folder_path)
        self.sorting_strategy = sorting_strategy

    def count_and_sort_files(self):
        results = self.file_counter.count_files_by_extension()
        sorted_results = self.sorting_strategy.sort(results)
        self.print_results(sorted_results)

    @staticmethod
    def print_results(results):
        print("File Type | Count")
        print("-----------------")
        for ext, count in results:
            ext_without_dot = ext[1:] if ext.startswith(".") else ext
            print(f"{ext_without_dot} | {count}")


def main():
    parser = argparse.ArgumentParser(
        description="Count files by extension in a directory."
    )
    parser.add_argument(
        "-d", "--directory", required=True, help="Root folder to count files in"
    )
    group = parser.add_mutually_exclusive_group()
    group.add_argument(
        "-s",
        "--sort",
        action="store_true",
        default=True,
        help="Sort by file count (default if no sorting option is provided)",
    )
    group.add_argument(
        "-e",
        "--sort-extension",
        action="store_true",
        help="Sort by extension name",
    )
    args = parser.parse_args()

    folder_path = args.directory

    if args.sort_extension:
        sorting_strategy = SortByExtensionStrategy()
    else:
        sorting_strategy = SortByCountStrategy()

    file_counter_app = MainApp(folder_path, sorting_strategy)
    file_counter_app.count_and_sort_files()


if __name__ == "__main__":
    main()
