#!/usr/bin/env python3
import subprocess
import collections
import os
import argparse
from typing import List, Dict
from datetime import datetime


class GitRepoAnalyzer:
    """A class to analyze a Git repository and extract various statistics.

    Attributes:
        repo_path (str): The absolute path to the Git repository.

    Methods:
        __init__(repo_path: str):
            Initializes the GitRepoAnalyzer with the given repository path.

        _is_valid_git_repo() -> bool:
            Checks if the given path is a valid Git repository.

        _run_git_command(args: List[str]) -> str:
            Runs a Git command with the specified arguments and returns the output.

        get_commit_data(format_string: str) -> List[str]:
            Retrieves commit data based on the given format string.

        analyze() -> Dict[str, Dict]:
            Analyzes the Git repository and returns various statistics."""

    def __init__(self, repo_path: str):
        self.repo_path = os.path.abspath(repo_path)
        if not self._is_valid_git_repo():
            raise ValueError(f"{self.repo_path} is not a valid Git repository")

    def _is_valid_git_repo(self) -> bool:
        return os.path.isdir(os.path.join(self.repo_path, ".git"))

    def _run_git_command(self, args: List[str]) -> str:
        try:
            return subprocess.check_output(["git", "-C", self.repo_path] + args, stderr=subprocess.DEVNULL).decode("utf-8")
        except subprocess.CalledProcessError:
            raise RuntimeError(f"Error running git command in {self.repo_path}")

    def get_commit_data(self, format_string: str) -> List[str]:
        output = self._run_git_command(["log", f"--pretty=format:{format_string}"])
        return output.split("\n")

    def analyze(self) -> Dict[str, Dict]:
        """
        Analyzes the git repository and returns various statistics.

        Returns:
            Dict[str, Dict]: A dictionary containing the following keys and their corresponding values:
                - "authors": A dictionary with author names as keys and their commit counts as values.
                - "author_emails": A dictionary with author emails as keys and their commit counts as values.
                - "committers": A dictionary with committer names as keys and their commit counts as values.
                - "committer_emails": A dictionary with committer emails as keys and their commit counts as values.
                - "commit_count": The total number of commits.
                - "date_range": A dictionary containing:
                    - "earliest": The date of the earliest commit.
                    - "latest": The date of the latest commit.
                    - "duration": The duration between the earliest and latest commits.
                - "file_changes": A dictionary containing:
                    - "additions": The total number of lines added.
                    - "deletions": The total number of lines deleted.
                    - "files_changed": The number of unique files changed.
                - "branch_count": The number of remote branches.
                - "commits_per_day": The average number of commits per day.
                - "avg_message_length": The average length of commit messages.
        """
        authors = self.get_commit_data("%an")
        author_emails = self.get_commit_data("%ae")
        committers = self.get_commit_data("%cn")
        committer_emails = self.get_commit_data("%ce")
        dates = self.get_commit_data("%ad")
        messages = self.get_commit_data("%s")

        author_counts = collections.Counter(authors)
        committer_counts = collections.Counter(committers)
        author_email_counts = collections.Counter(author_emails)
        committer_email_counts = collections.Counter(committer_emails)

        date_objects = [datetime.strptime(date, "%a %b %d %H:%M:%S %Y %z") for date in dates]
        earliest_commit = min(date_objects)
        latest_commit = max(date_objects)

        file_changes = self._run_git_command(["log", "--numstat", "--format="])
        additions, deletions = 0, 0
        files_changed = set()
        for line in file_changes.split("\n"):
            if line.strip():
                add, delete, filename = line.split("\t")
                if add != "-" and delete != "-":  # Check if the values are numeric
                    additions += int(add)
                    deletions += int(delete)
                files_changed.add(filename)

        branches = self._run_git_command(["branch", "-r"]).split("\n")
        branch_count = len([b for b in branches if b.strip()])

        repo_age = latest_commit - earliest_commit
        commits_per_day = len(authors) / (repo_age.days + 1)

        message_lengths = [len(msg) for msg in messages]
        avg_message_length = sum(message_lengths) / len(message_lengths)

        return {
            "authors": dict(author_counts),
            "author_emails": dict(author_email_counts),
            "committers": dict(committer_counts),
            "committer_emails": dict(committer_email_counts),
            "commit_count": len(authors),
            "date_range": {"earliest": earliest_commit, "latest": latest_commit, "duration": repo_age},
            "file_changes": {"additions": additions, "deletions": deletions, "files_changed": len(files_changed)},
            "branch_count": branch_count,
            "commits_per_day": commits_per_day,
            "avg_message_length": avg_message_length,
        }


class GitRepoReporter:
    """
    GitRepoReporter is a class that provides various methods to analyze and report on a Git repository's statistics.

    Attributes:
        data (Dict[str, Dict]): A dictionary containing various statistics and information about the repository.

    Methods:
        __init__(data: Dict[str, Dict]):
            Initializes the GitRepoReporter with the provided data.

        print_contribution_stats():
            Prints the contribution statistics including total contributors, total commits, and average commits per contributor.

        print_top_contributors(n: int):
            Prints the top n contributors based on the number of commits.

        print_email_domain_stats():
            Prints the statistics of email domains used by contributors.

        print_time_stats():
            Prints the time-related statistics of the repository including repository age, first commit date, latest commit date, and average commits per day.

        print_code_change_stats():
            Prints the statistics related to code changes including total lines added, total lines deleted, total files changed, and average lines per commit.

        print_repo_structure():
            Prints the structure of the repository including the number of branches.

        print_commit_message_stats():
            Prints the statistics of commit messages including the average commit message length.

        print_author_committer_diff():
            Prints the differences between authors and committers, showing individuals with different numbers of authored and committed commits.

        print_summary(top_n: int = 5):
            Prints a summary of the repository analysis including various statistics and information about the repository."""

    def __init__(self, data: Dict[str, Dict]):
        self.data = data

    def print_contribution_stats(self):
        print("\nContribution Statistics:")
        print(f"Total Contributors: {len(self.data['authors'])}")
        print(f"Total Commits: {self.data['commit_count']}")
        print(f"Average Commits per Contributor: {self.data['commit_count'] / len(self.data['authors']):.2f}")

    def print_top_contributors(self, n: int):
        print(f"\nTop {n} Contributors:")
        for author, count in sorted(self.data["authors"].items(), key=lambda x: x[1], reverse=True)[:n]:
            print(f"  {author}: {count} commits")

    def print_email_domain_stats(self):
        print("\nEmail Domain Statistics:")
        email_domains = collections.Counter([email.split("@")[1] for email in self.data["author_emails"]])
        for domain, count in email_domains.most_common(5):
            print(f"  {domain}: {count} commits")

    def print_time_stats(self):
        print("\nTime Statistics:")
        print(f"Repository Age: {self.data['date_range']['duration'].days} days")
        print(f"First Commit: {self.data['date_range']['earliest'].strftime('%Y-%m-%d')}")
        print(f"Latest Commit: {self.data['date_range']['latest'].strftime('%Y-%m-%d')}")
        print(f"Average Commits per Day: {self.data['commits_per_day']:.2f}")

    def print_code_change_stats(self):
        print("\nCode Change Statistics:")
        print(f"Total Lines Added: {self.data['file_changes']['additions']}")
        print(f"Total Lines Deleted: {self.data['file_changes']['deletions']}")
        print(f"Total Files Changed: {self.data['file_changes']['files_changed']}")
        print(f"Average Lines per Commit: {(self.data['file_changes']['additions'] + self.data['file_changes']['deletions']) / self.data['commit_count']:.2f}")

    def print_repo_structure(self):
        print("\nRepository Structure:")
        print(f"Number of Branches: {self.data['branch_count']}")

    def print_commit_message_stats(self):
        print("\nCommit Message Statistics:")
        print(f"Average Commit Message Length: {self.data['avg_message_length']:.2f} characters")

    def print_author_committer_diff(self):
        """
        Print the differences between authors and committers.

        This method compares the number of commits authored and committed by each individual.
        It prints out the names of individuals who have a different number of authored and committed
        commits, along with the respective counts. The output is sorted by the absolute difference
        between the number of authored and committed commits in descending order.

        If there are no differences between authors and committers, it prints a message indicating so.
        """
        print("\nDifferences between Authors and Committers:")
        all_names = set(self.data["authors"].keys()) | set(self.data["committers"].keys())
        differences = [
            (name, self.data["authors"].get(name, 0), self.data["committers"].get(name, 0))
            for name in all_names
            if self.data["authors"].get(name, 0) != self.data["committers"].get(name, 0)
        ]
        if differences:
            for name, author_count, committer_count in sorted(differences, key=lambda x: abs(x[1] - x[2]), reverse=True):
                print(f"  {name}: Authored {author_count}, Committed {committer_count}")
        else:
            print("  No differences found between authors and committers")

    def print_summary(self, top_n: int = 5):
        """
        Prints a summary of the repository analysis.

        This method prints various statistics and information about the repository,
        including contribution stats, top contributors, email domain stats, time stats,
        code change stats, repository structure, commit message stats, and differences
        between authors and committers.

        Args:
            top_n (int, optional): The number of top contributors to display. Defaults to 5.
        """
        print("Repository Analysis Summary")
        print("===========================")
        self.print_contribution_stats()
        self.print_top_contributors(top_n)
        self.print_email_domain_stats()
        self.print_time_stats()
        self.print_code_change_stats()
        self.print_repo_structure()
        self.print_commit_message_stats()
        self.print_author_committer_diff()


def main():
    """
    Main function to analyze a Git repository for detailed contribution statistics.

    This function sets up an argument parser to handle command-line arguments,
    initializes a GitRepoAnalyzer to analyze the repository, and uses a
    GitRepoReporter to print a summary of the analysis.

    Command-line Arguments:
    - repo_path (str): Path to the Git repository (default: current directory).
    - top_contributors (int): Number of top contributors to display (default: 5).

    Raises:
    - ValueError: If there is an issue with the provided arguments.
    - RuntimeError: If there is an issue during the analysis.
    - Exception: For any other unexpected errors.
    """
    parser = argparse.ArgumentParser(description="Analyze Git repository for detailed contribution statistics")
    parser.add_argument("repo_path", nargs="?", default=".", help="Path to the Git repository (default: current directory)")
    parser.add_argument("-n", "--top_contributors", type=int, default=5, help="Number of top contributors to display (default: 5)")
    args = parser.parse_args()

    try:
        analyzer = GitRepoAnalyzer(args.repo_path)
        data = analyzer.analyze()
        reporter = GitRepoReporter(data)
        reporter.print_summary(args.top_contributors)
    except (ValueError, RuntimeError) as e:
        print(f"Error: {str(e)}")
    except Exception as e:
        print(f"An unexpected error occurred: {str(e)}")


if __name__ == "__main__":
    main()
