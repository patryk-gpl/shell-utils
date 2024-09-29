import argparse
import json
import os
from datetime import datetime, timedelta
from typing import List, Dict, Any

import requests
from dotenv import load_dotenv


class ConfigurationError(Exception):
    pass


class BitbucketAPI:
    def __init__(self, base_url: str, username: str, password: str):
        self.base_url = base_url
        self.auth = (username, password)

    def get_repositories(self, start: int = 0, limit: int = 100) -> Dict[str, Any]:
        url = f"{self.base_url}/rest/api/1.0/projects/PROJ/repos"
        params = {"start": start, "limit": limit}
        response = requests.get(url, auth=self.auth, params=params)
        response.raise_for_status()
        return response.json()


class RepositoryManager:
    def __init__(self, api: BitbucketAPI):
        self.api = api

    def get_all_repositories(self) -> List[Dict[str, Any]]:
        repositories = []
        start = 0
        while True:
            response = self.api.get_repositories(start=start)
            repositories.extend(response["values"])
            if response["isLastPage"]:
                break
            start = response["nextPageStart"]
        return repositories


class FileHandler:
    def save_json(self, data: Any, filename: str) -> None:
        os.makedirs(os.path.dirname(filename), exist_ok=True)
        with open(filename, "w") as f:
            json.dump(data, f, indent=2)

    def load_json(self, filename: str) -> Any:
        with open(filename, "r") as f:
            return json.load(f)

    def is_file_older_than_24h(self, filename: str) -> bool:
        if not os.path.exists(filename):
            return True
        file_time = datetime.fromtimestamp(os.path.getmtime(filename))
        return datetime.now() - file_time > timedelta(hours=24)


class DataProcessor:
    def filter_data(self, data: List[Dict[str, Any]], attributes: List[str]) -> List[Dict[str, Any]]:
        return [{k: v for k, v in repo.items() if k in attributes} for repo in data]

    def filter_by_date(self, data: List[Dict[str, Any]], target_date: str) -> List[Dict[str, Any]]:
        target_date = datetime.strptime(target_date, "%Y-%m")
        return [
            repo
            for repo in data
            if "createdDate" in repo and datetime.fromtimestamp(repo["createdDate"] / 1000).strftime("%Y-%m") == target_date.strftime("%Y-%m")
        ]

    def generate_statistics(self, data: List[Dict[str, Any]]) -> Dict[str, Any]:
        return {
            "total_repositories": len(data),
            "oldest_repository": min(data, key=lambda x: x.get("createdDate", float("inf")))["name"],
            "newest_repository": max(data, key=lambda x: x.get("createdDate", 0))["name"],
        }


class CLI:
    def __init__(self):
        self.parser = argparse.ArgumentParser(description="Bitbucket Server REST API CLI Tool")
        self.parser.add_argument("--filter", nargs="+", help="List of attributes to filter")
        self.parser.add_argument("--created-date", help="Filter repositories by creation date (YYYY-MM)")
        self.parser.add_argument("--base-url", help="Bitbucket Server base URL")
        self.parser.add_argument("--username", help="Bitbucket Server username")
        self.parser.add_argument("--password", help="Bitbucket Server password")
        self.file_handler = FileHandler()
        self.data_processor = DataProcessor()

    def get_config(self, args: argparse.Namespace) -> Dict[str, str]:
        config = {
            "base_url": args.base_url or os.getenv("BITBUCKET_BASE_URL"),
            "username": args.username or os.getenv("BITBUCKET_USERNAME"),
            "password": args.password or os.getenv("BITBUCKET_PASSWORD"),
        }

        missing_params = [k for k, v in config.items() if v is None]
        if missing_params:
            raise ConfigurationError(f"Missing required parameters: {', '.join(missing_params)}")

        return config

    def run(self) -> None:
        load_dotenv()
        args = self.parser.parse_args()

        try:
            config = self.get_config(args)
            api = BitbucketAPI(**config)
            repo_manager = RepositoryManager(api)

            raw_data_file = "json/data-raw.json"

            if self.file_handler.is_file_older_than_24h(raw_data_file):
                repositories = repo_manager.get_all_repositories()
                self.file_handler.save_json(repositories, raw_data_file)
            else:
                repositories = self.file_handler.load_json(raw_data_file)

            if args.filter:
                filtered_data = self.data_processor.filter_data(repositories, args.filter)
                self.file_handler.save_json(filtered_data, "json/data-filtered.json")

            if args.created_date:
                date_filtered_data = self.data_processor.filter_by_date(repositories, args.created_date)
                self.file_handler.save_json(date_filtered_data, f"json/data-{args.created_date}.json")

            statistics = self.data_processor.generate_statistics(repositories)
            print(json.dumps(statistics, indent=2))

        except ConfigurationError as e:
            print(f"Configuration error: {e}")
            print("Please set the required environment variables or provide them as command-line arguments.")
            exit(1)
        except requests.RequestException as e:
            print(f"API request error: {e}")
            exit(1)
        except json.JSONDecodeError as e:
            print(f"JSON parsing error: {e}")
            exit(1)
        except Exception as e:
            print(f"An unexpected error occurred: {e}")
            exit(1)


if __name__ == "__main__":
    cli = CLI()
    cli.run()
