#!/usr/bin/env python3
import argparse
import re
from pathlib import Path

LINE_DELIMITER_LENGTH = 2
FILE_PATTERN_DEFAULT = (".sh", ".py", ".env", ".yml", ".yaml")


import re
import subprocess
from pathlib import Path


class FileStructureExporter:
    def __init__(self, root_dir, output_file, file_pattern, max_words_per_file):
        self.root_dir = root_dir
        self.output_file = output_file
        self.file_pattern = file_pattern
        self.max_words_per_file = max_words_per_file
        self.current_file_index = 1

    def export_file_structure(self):
        current_words = 0
        current_batch = []
        self.add_tree_header(current_batch)
        self.process_directory(Path(self.root_dir), current_batch, current_words)
        if current_batch:
            self.save_batch(current_batch)

    def add_tree_header(self, current_batch):
        current_batch.append(f"Root directory: {self.root_dir}\n")
        tree_output = subprocess.check_output(["tree", "-n", self.root_dir])
        current_batch.append(tree_output.decode("utf-8"))
        current_batch.append("\n\n")

    def process_directory(self, directory, current_batch, current_words):
        for file_path in directory.rglob("*"):
            if file_path.is_file() and file_path.suffix in self.file_pattern:
                with open(
                    file_path, "r", encoding="utf-8", errors="ignore"
                ) as file_content:
                    self.process_file(
                        file_path, file_content, current_batch, current_words
                    )
            elif file_path.is_dir():
                self.process_directory(file_path, current_batch, current_words)

    def process_file(self, file_path, file_content, current_batch, current_words):
        current_batch.append("#" * LINE_DELIMITER_LENGTH + " ")
        current_batch.append(f"relative path: {file_path.relative_to(self.root_dir)}\n")
        for line in file_content:
            if not line.strip().startswith("#"):
                current_words = self.process_line(line, current_words, current_batch)
                if current_words >= self.max_words_per_file:
                    self.save_batch(current_batch)
                    current_words = 0
                    current_batch = []

    def process_line(self, line, current_words, current_batch):
        words = re.findall(r"\b\w+\b", line)  # Split by word boundaries
        current_words += len(words)
        current_batch.append(line)
        return current_words

    def save_batch(self, batch):
        with open(f"{self.output_file}.{self.current_file_index}.txt", "w") as output:
            output.writelines(batch)
        self.current_file_index += 1

    def calculate_text_stats(self):
        num_words = 0
        for i in range(1, self.current_file_index):
            with open(
                f"{self.output_file}.{i}.txt", "r", encoding="utf-8", errors="ignore"
            ) as output_file:
                content = output_file.read()
                num_words += self.count_words(content)
        return num_words

    def count_words(self, content):
        words = re.findall(r"\b\w+\b", content)  # Split by word boundaries
        return len(words)


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
        help="File patterns to include (default: .sh and .py files).",
    )
    parser.add_argument(
        "--max_words_per_file",
        metavar="MAX_WORDS",
        type=int,
        default=4000,
        help="The maximum number of words per output file (default: 4000).",
    )
    args = parser.parse_args()

    if args.output_file is None:
        # Derive the default output filename based on the basename of the root directory
        root_dir_basename = Path(args.root_dir).name
        default_output_file = f"exported_structure_{root_dir_basename}"
        args.output_file = default_output_file

    exporter = FileStructureExporter(
        args.root_dir, args.output_file, args.file_pattern, args.max_words_per_file
    )
    exporter.export_file_structure()
    print("File structure exported successfully.")

    num_words = exporter.calculate_text_stats()
    print(f"Number of words: {num_words}")


if __name__ == "__main__":
    main()
