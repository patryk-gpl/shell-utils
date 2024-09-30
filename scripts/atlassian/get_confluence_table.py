#!/usr/bin/env python3
"""
This script extracts tables from a Confluence page and saves them as CSV or JSON files.

It was tested on Confluence cloud.
"""

import argparse
import sys
import io
from abc import ABC, abstractmethod
from atlassian import Confluence
from bs4 import BeautifulSoup
import pandas as pd
from urllib.parse import urlparse, parse_qs


class OutputStrategy(ABC):
    @abstractmethod
    def save(self, df, output_file):
        pass


class CSVOutputStrategy(OutputStrategy):
    def save(self, df, output_file):
        df.to_csv(output_file, index=False)
        return "csv"


class JSONOutputStrategy(OutputStrategy):
    def save(self, df, output_file):
        df.to_json(output_file, orient="records")
        return "json"


class ConfluenceTableExtractor:
    def __init__(self, base_url, username, api_token, is_cloud):
        self.base_url = base_url
        self.confluence = Confluence(url=base_url, username=username, password=api_token, cloud=is_cloud)
        self.output_strategy = None

    def set_output_strategy(self, strategy):
        self.output_strategy = strategy

    def get_page_content(self, page_id=None, space_key=None, title=None):
        try:
            if page_id:
                return self.confluence.get_page_by_id(page_id, expand="body.storage")["body"]["storage"]["value"]
            elif space_key and title:
                page = self.confluence.get_page_by_title(space_key, title, expand="body.storage")
                if page is None:
                    raise ValueError(f"Page not found: space_key={space_key}, title={title}")
                return page["body"]["storage"]["value"]
            else:
                raise ValueError("Either page_id or both space_key and title must be provided")
        except Exception as e:
            raise ValueError(f"Error fetching page content: {str(e)}")

    def extract_tables(self, page_id=None, space_key=None, title=None):
        content = self.get_page_content(page_id, space_key, title)
        soup = BeautifulSoup(content, "html.parser")
        tables = soup.find_all("table")
        return tables

    def table_to_dataframe(self, table):
        table_html = io.StringIO(str(table))
        try:
            return pd.read_html(table_html)[0]
        except ImportError:
            print("Error: Missing required dependency. Please install lxml using: pip install lxml")
            raise

    def save_table(self, df, output_file):
        if self.output_strategy is None:
            raise ValueError("Output strategy not set")
        format_used = self.output_strategy.save(df, output_file)
        print(f"Table saved to {output_file} in {format_used} format")

    def get_page_info_from_url(self, page_url):
        parsed_url = urlparse(page_url)
        path_segments = parsed_url.path.split("/")

        # Extract space key and title from the URL
        if len(path_segments) >= 5 and path_segments[1] == "wiki" and path_segments[2] == "spaces":
            space_key = path_segments[3]
            title = path_segments[-1].replace("+", " ")
            return None, space_key, title

        # If we can't extract space key and title, try to get the page ID
        query_params = parse_qs(parsed_url.query)
        if "pageId" in query_params:
            return query_params["pageId"][0], None, None

        raise ValueError("Unable to extract page information from the URL")


def main():
    parser = argparse.ArgumentParser(description="Extract tables from Confluence page")
    parser.add_argument("--url", required=True, help="Full Confluence page URL")
    parser.add_argument("--username", required=True, help="Confluence username")
    parser.add_argument("--token", required=True, help="Confluence API token")
    parser.add_argument("--cloud", action="store_true", help="Use this flag if using Confluence Cloud")
    parser.add_argument("--table-index", type=int, default=0, help="Index of the table to extract (0-based)")
    parser.add_argument("--output", default="output", help="Output file name without extension")
    parser.add_argument("--format", choices=["csv", "json"], default="csv", help="Output format (csv or json)")

    args = parser.parse_args()
    parsed_url = urlparse(args.url)
    base_url = f"{parsed_url.scheme}://{parsed_url.netloc}"

    extractor = ConfluenceTableExtractor(base_url, args.username, args.token, args.cloud)

    if args.format == "csv":
        extractor.set_output_strategy(CSVOutputStrategy())
        output_file = f"{args.output}.csv"
    elif args.format == "json":
        extractor.set_output_strategy(JSONOutputStrategy())
        output_file = f"{args.output}.json"

    try:
        page_id, space_key, title = extractor.get_page_info_from_url(args.url)
        if page_id:
            print(f"Extracted Page ID: {page_id}")
            tables = extractor.extract_tables(page_id=page_id)
        elif space_key and title:
            print(f"Extracted Space Key: {space_key}, Title: {title}")
            tables = extractor.extract_tables(space_key=space_key, title=title)
        else:
            raise ValueError("Unable to extract page information from the URL")

        if not tables:
            print("No tables found on the page.")
            return

        if args.table_index >= len(tables):
            print(f"Table index {args.table_index} is out of range. There are {len(tables)} tables on the page.")
            return

        selected_table = tables[args.table_index]
        df = extractor.table_to_dataframe(selected_table)
        extractor.save_table(df, output_file)

    except Exception as e:
        print(f"An error occurred: {str(e)}")
        print("Please check the following:")
        print("1. Your Confluence URL is correct")
        print("2. Your username and API token are valid")
        print("3. You have the necessary permissions to access the page")
        print("4. If using Confluence Cloud, make sure to use the --cloud flag")
        sys.exit(1)


if __name__ == "__main__":
    main()
