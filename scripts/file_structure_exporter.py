#!/usr/bin/env python3
import argparse
import re
from pathlib import Path
import subprocess

LINE_DELIMITER_LENGTH = 5
DEFAULT_INCLUDE_FILES = (".sh", ".py", ".env", ".yml", ".yaml")
DEFAULT_EXCLUDE_PATTERNS = (".venv", ".direnv", ".git", "__pycache__", "*.pyc", "*.pyo", "*.pyd", "*.so", "*.dll", "*.dylib", "*.exe", "*.o", "*.a")


class FileStructureExporter:
    def __init__(self, root_dir, output_file, include, max_words_per_file, exclude_patterns):
        self.root_dir = Path(root_dir)
        self.output_file = output_file
        self.include = set(DEFAULT_INCLUDE_FILES) | set(include)
        self.max_words_per_file = max_words_per_file
        self.exclude_patterns = set(exclude_patterns)
        self.current_file_index = 1

    def export_file_structure(self):
        current_words = 0
        current_batch = []
        self.add_tree_header(current_batch)
        self.process_directory(self.root_dir, current_batch, current_words)
        if current_batch:
            self.save_batch(current_batch)

    def add_tree_header(self, current_batch):
        current_batch.append(f"Root directory: {self.root_dir}\n")
        tree_command = ["tree", "-n", "--charset", "ascii"]
        for pattern in self.exclude_patterns:
            tree_command.extend(["-I", pattern])
        include_patterns = [f"*{ext}" if ext.startswith(".") else ext for ext in self.include]
        tree_command.extend(["-P", "|".join(include_patterns)])
        tree_command.append(str(self.root_dir))
        tree_output = subprocess.check_output(tree_command)
        current_batch.append(tree_output.decode("utf-8"))
        current_batch.append("\n" + "=" * LINE_DELIMITER_LENGTH + "\n\n")

    def process_directory(self, directory, current_batch, current_words):
        for file_path in directory.rglob("*"):
            if self.should_exclude(file_path):
                continue
            if file_path.is_file() and self.should_include(file_path):
                current_words = self.process_file(file_path, current_batch, current_words)

    def should_exclude(self, path):
        return any(
            path.match(pattern) or pattern in path.parts or (path.is_file() and (path.name == pattern or path.suffix == pattern))
            for pattern in self.exclude_patterns
        )

    def should_include(self, file_path):
        return (
            file_path.suffix in self.include
            or file_path.name in self.include
            or any(not pattern.startswith(".") and file_path.match(f"*{pattern}") for pattern in self.include)
        )

    def process_file(self, file_path, current_batch, current_words):
        relative_path = file_path.relative_to(self.root_dir)
        current_batch.append(f"File: {relative_path}\n")
        current_batch.append("-" * LINE_DELIMITER_LENGTH + "\n")

        try:
            with open(file_path, "r", encoding="utf-8", errors="ignore") as file_content:
                content = file_content.read().strip()
                if content:
                    current_batch.append(content)
                    current_batch.append("\n")
                    words = re.findall(r"\b\w+\b", content)
                    current_words += len(words)
                else:
                    current_batch.append("[This file is empty]\n")
        except Exception as e:
            current_batch.append(f"[Error reading file: {str(e)}]\n")

        current_batch.append("\n" + "=" * LINE_DELIMITER_LENGTH + "\n\n")

        if current_words >= self.max_words_per_file:
            self.save_batch(current_batch)
            current_words = 0
            current_batch.clear()

        return current_words

    def save_batch(self, batch):
        with open(f"{self.output_file}.{self.current_file_index}.txt", "w", encoding="utf-8") as output:
            output.writelines(batch)
        self.current_file_index += 1

    def calculate_text_stats(self):
        total_words = 0
        total_files = 0
        for i in range(1, self.current_file_index):
            with open(f"{self.output_file}.{i}.txt", "r", encoding="utf-8", errors="ignore") as output_file:
                content = output_file.read()
                words = re.findall(r"\b\w+\b", content)
                total_words += len(words)
                total_files += content.count("File: ")
        return total_words, total_files


def main():
    parser = argparse.ArgumentParser(description="Export the file structure of a directory.")
    parser.add_argument("root_dir", metavar="ROOT_DIR", type=str, help="The root directory to export.")
    parser.add_argument(
        "--output_file",
        metavar="OUTPUT_FILE",
        type=str,
        default=None,
        help="The output file prefix to write the structure to (default: exported_structure_<root_dir_basename>).",
    )
    parser.add_argument("--include", metavar="INCLUDE", type=str, nargs="*", default=[], help="Additional file extensions, names, or patterns to include.")
    parser.add_argument(
        "--max_words_per_file", metavar="MAX_WORDS", type=int, default=150000, help="The maximum number of words per output file (default: 150000)."
    )
    parser.add_argument(
        "--exclude",
        metavar="EXCLUDE_PATTERN",
        type=str,
        nargs="*",
        default=[],
        help="Patterns for folders or files to exclude (in addition to default .venv, .direnv, and .git)",
    )
    args = parser.parse_args()

    if args.output_file is None:
        root_dir_basename = Path(args.root_dir).name
        default_output_file = f"exported_structure_{root_dir_basename}"
        args.output_file = default_output_file

    # Merge default exclusions with user-provided exclusions
    exclude_patterns = set(DEFAULT_EXCLUDE_PATTERNS) | set(args.exclude)

    exporter = FileStructureExporter(args.root_dir, args.output_file, args.include, args.max_words_per_file, exclude_patterns)
    exporter.export_file_structure()

    total_words, total_files = exporter.calculate_text_stats()
    print("File structure exported successfully.")
    print(f"Total number of words: {total_words}")
    print(f"Total number of files processed: {total_files}")
    print(f"Number of output files created: {exporter.current_file_index - 1}")


if __name__ == "__main__":
    main()
