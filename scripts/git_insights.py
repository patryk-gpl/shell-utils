#!/usr/bin/env python3

import argparse
import subprocess
import os

class GitInsights:
    def __init__(self, repo_path):
        self.repo_path = repo_path
        self.author_stats = {}

    def git_author_stats(self, sort_by):
        os.chdir(self.repo_path)
        git_log_command = "git log --shortstat --no-merges --pretty=format:'%aN <%aE>'"
        git_log_output = subprocess.check_output(git_log_command, shell=True).decode("utf-8")

        current_author = None

        for line in git_log_output.splitlines():
            if line.startswith(" "):
                parts = line.strip().split(", ")
                for part in parts:
                    if "insertion" in part:
                        self.author_stats[current_author]["insertions"] += int(part.split()[0])
                    elif "deletion" in part:
                        self.author_stats[current_author]["deletions"] += int(part.split()[0])
                    elif "changed" in part:
                        self.author_stats[current_author]["changes"] += int(part.split()[0])
            else:
                current_author = line
                if current_author not in self.author_stats:
                    self.author_stats[current_author] = {"commits": 0, "insertions": 0, "deletions": 0, "changes": 0}
                self.author_stats[current_author]["commits"] += 1

        if sort_by == "name":
            self.author_stats = dict(sorted(self.author_stats.items(), key=lambda x: x[0]))
        elif sort_by == "commits":
            self.author_stats = dict(sorted(self.author_stats.items(), key=lambda x: x[1]["commits"], reverse=True))
        elif sort_by == "insertions":
            self.author_stats = dict(sorted(self.author_stats.items(), key=lambda x: x[1]["insertions"], reverse=True))
        elif sort_by == "deletions":
            self.author_stats = dict(sorted(self.author_stats.items(), key=lambda x: x[1]["deletions"], reverse=True))

    def print_stats(self):
        print("Git Author Contributions Summary:")
        for author, stats in self.author_stats.items():
            print(f"Author: {author}, Commits: {stats['commits']}, Insertions: {stats['insertions']}, Deletions: {stats['deletions']}, Changes: {stats['changes']}")

    def save_to_file(self, output_file):
        with open(output_file, "w") as f:
            f.write("Git Author Contributions Summary:\n")
            for author, stats in self.author_stats.items():
                f.write(f"Author: {author}, Commits: {stats['commits']}, Insertions: {stats['insertions']}, Deletions: {stats['deletions']}, Changes: {stats['changes']}\n")

def main():
    parser = argparse.ArgumentParser(description="Summarize Git authors contributions.")
    parser.add_argument("-r", "--repo_path", metavar="REPO_PATH", type=str, help="Path to the local Git repository.")
    parser.add_argument("-o", "--output", metavar="OUTPUT_FILE", type=str, help="Save output to a file.")
    parser.add_argument("-s", "--sort_by", metavar="SORT_BY", type=str, choices=["name", "commits", "insertions", "deletions"], default="name", help="Sort by user name, number of commits, number of total inserts, or number of total deletions.")

    args = parser.parse_args()

    if not args.repo_path or not os.path.isdir(os.path.join(args.repo_path, ".git")):
        args.repo_path = os.getcwd()
        if not os.path.isdir(os.path.join(args.repo_path, ".git")):
            print("Error: Current directory is not a Git repository.")
            return

    git_insights = GitInsights(args.repo_path)
    git_insights.git_author_stats(args.sort_by)
    git_insights.print_stats()

    if args.output:
        git_insights.save_to_file(args.output)
        print(f"Author contributions summary saved to {args.output}")

if __name__ == "__main__":
    main()
