#!/usr/bin/env python3

import os
import re
import argparse
import logging
from pathlib import Path
from typing import Dict, List

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")


class ShellScriptScanner:
    def __init__(self, root_dir: str, exclude_patterns: List[str] = None):
        self.root_dir = root_dir
        self.exclude_patterns = exclude_patterns or []
        self.result = {}

    def is_excluded(self, path: Path) -> bool:
        for pattern in self.exclude_patterns:
            if path.match(pattern):
                logging.info(f"Excluding path: {path}")
                return True
        return False

    def scan_file(self, file_path: Path) -> Dict[str, List[str]]:
        functions = []
        aliases = []
        try:
            with open(file_path, "r") as file:
                for line in file:
                    func_match = re.match(r"^\s*function\s+(\w+)", line) or re.match(r"^\s*(\w+)\s*\(\)", line)
                    alias_match = re.match(r"^\s*alias\s+(\w+)=", line)
                    if func_match:
                        functions.append(func_match.group(1))
                    if alias_match:
                        aliases.append(alias_match.group(1))
        except Exception as e:
            logging.error(f"Error reading file {file_path}: {e}")
        return {"functions": functions, "aliases": aliases}

    def scan_directory(self):
        for root, _, files in os.walk(self.root_dir):
            for file_name in files:
                file_path = Path(root) / file_name
                if self.is_excluded(file_path):
                    continue
                if file_path.suffix in [".sh", ".bash"]:
                    self.process_file(file_path)

    def process_file(self, file_path: Path):
        relative_path = file_path.relative_to(self.root_dir)
        dir_name = relative_path.parent.as_posix()
        base_name = file_path.stem
        self.result[f"{dir_name}/{base_name}"] = self.scan_file(file_path)

    def search(self, pattern: str, search_type: str = "all") -> Dict[str, Dict[str, List[str]]]:
        regex = re.compile(pattern)
        filtered_result = {}

        for key, value in self.result.items():
            functions_match = [func for func in value["functions"] if regex.search(func)]
            aliases_match = [alias for alias in value["aliases"] if regex.search(alias)]

            if search_type == "all":
                if functions_match or aliases_match:
                    filtered_result[key] = {"functions": functions_match, "aliases": aliases_match}
            elif search_type == "functions":
                if functions_match:
                    filtered_result[key] = {
                        "functions": functions_match,
                        "aliases": [],  # Empty aliases for functions search
                    }
            elif search_type == "aliases":
                if aliases_match:
                    filtered_result[key] = {
                        "functions": [],  # Empty functions for aliases search
                        "aliases": aliases_match,
                    }
        return filtered_result


def main(args):
    scanner = ShellScriptScanner(root_dir=args.dir, exclude_patterns=args.exclude)
    scanner.scan_directory()

    search_type = "all"
    if args.search_all:
        pattern = args.search_all
    elif args.search_function:
        search_type = "functions"
        pattern = args.search_function
    elif args.search_alias:
        search_type = "aliases"
        pattern = args.search_alias
    else:
        pattern = ""

    result = scanner.search(pattern, search_type)

    all_functions = set()
    all_aliases = set()

    for data in result.values():
        all_functions.update(data["functions"])
        all_aliases.update(data["aliases"])

    if not all_functions and not all_aliases:
        print("No matches found.")
    else:
        sorted_functions = sorted(all_functions)
        sorted_aliases = sorted(all_aliases)

        if sorted_functions:
            print(f"Functions: {', '.join(sorted_functions)}")
        if sorted_aliases:
            print(f"Aliases: {', '.join(sorted_aliases)}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Scan shell scripts for functions and aliases.")
    parser.add_argument("--dir", "-d", required=True, help="The directory to scan recursively.")
    parser.add_argument("--exclude", "-e", nargs="*", help="Patterns to exclude from the scan.")

    # Create a mutually exclusive group for search options
    search_group = parser.add_mutually_exclusive_group()
    search_group.add_argument("--search-all", "-sall", help="Search for a keyword across all functions and aliases.")
    search_group.add_argument("--search-function", "-sf", help="Search for a keyword within function names only.")
    search_group.add_argument("--search-alias", "-sa", help="Search for a keyword within alias names only.")

    args = parser.parse_args()

    main(args)
