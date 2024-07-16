#!/usr/bin/env python3
import argparse
import re
from pathlib import Path
import subprocess

LINE_DELIMITER_LENGTH = 80
FILE_PATTERN_DEFAULT = (".sh", ".py", ".env", ".yml", ".yaml")


class FileStructureExporter:
    def __init__(self, root_dir, output_file, file_pattern, max_words_per_file):
        self.root_dir = Path(root_dir)
        self.output_file = output_file
        self.file_pattern = file_pattern
        self.max_words_per_file = max_words_per_file
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
        tree_output = subprocess.check_output(["tree", "-n", str(self.root_dir)])
        current_batch.append(tree_output.decode("utf-8"))
        current_batch.append("\n" + "=" * LINE_DELIMITER_LENGTH + "\n\n")

    def process_directory(self, directory, current_batch, current_words):
        for file_path in directory.rglob("*"):
            if file_path.is_file() and file_path.suffix in self.file_pattern:
                current_words = self.process_file(
                    file_path, current_batch, current_words
                )

    def process_file(self, file_path, current_batch, current_words):
        relative_path = file_path.relative_to(self.root_dir)
        current_batch.append(f"File: {relative_path}\n")
        current_batch.append("-" * LINE_DELIMITER_LENGTH + "\n")

        try:
            with open(
                file_path, "r", encoding="utf-8", errors="ignore"
            ) as file_content:
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
        with open(
            f"{self.output_file}.{self.current_file_index}.txt", "w", encoding="utf-8"
        ) as output:
            output.writelines(batch)
        self.current_file_index += 1

    def calculate_text_stats(self):
        total_words = 0
        total_files = 0
        for i in range(1, self.current_file_index):
            with open(
                f"{self.output_file}.{i}.txt", "r", encoding="utf-8", errors="ignore"
            ) as output_file:
                content = output_file.read()
                words = re.findall(r"\b\w+\b", content)
                total_words += len(words)
                total_files += content.count("File: ")
        return total_words, total_files


def main():
    parser = argparse.ArgumentParser(
        description="Export the file structure of a directory."
    )
    parser.add_argument(
        "root_dir", metavar="ROOT_DIR", type=str, help="The root directory to export."
    )
    parser.add_argument(
        "--output_file",
        metavar="OUTPUT_FILE",
        type=str,
        default=None,
        help="The output file prefix to write the structure to (default: exported_structure_<root_dir_basename>).",
    )
    parser.add_argument(
        "--file_pattern",
        metavar="FILE_PATTERN",
        type=str,
        default=FILE_PATTERN_DEFAULT,
        nargs="*",
        help="File patterns to include (default: .sh, .py, .env, .yml, and .yaml files).",
    )
    parser.add_argument(
        "--max_words_per_file",
        metavar="MAX_WORDS",
        type=int,
        default=150000,
        help="The maximum number of words per output file (default: 150000).",
    )
    args = parser.parse_args()

    if args.output_file is None:
        root_dir_basename = Path(args.root_dir).name
        default_output_file = f"exported_structure_{root_dir_basename}"
        args.output_file = default_output_file

    exporter = FileStructureExporter(
        args.root_dir, args.output_file, args.file_pattern, args.max_words_per_file
    )
    exporter.export_file_structure()

    total_words, total_files = exporter.calculate_text_stats()
    print("File structure exported successfully.")
    print(f"Total number of words: {total_words}")
    print(f"Total number of files processed: {total_files}")
    print(f"Number of output files created: {exporter.current_file_index - 1}")


if __name__ == "__main__":
    main()
