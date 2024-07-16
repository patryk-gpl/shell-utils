#!/usr/bin/env python3
import asyncio
import aiohttp
import argparse
import os
import sys


async def nexus_delete_all_files_from_raw_repo(nexus_url, nexus_repository, nexus_user, nexus_token):
    if not all([nexus_url, nexus_repository, nexus_user, nexus_token]):
        print("Nexus URL, repository name, username or token is not set")
        return

    print(f"Nexus URL: {nexus_url}, Repository name: {nexus_repository}, User: {nexus_user}")

    auth = aiohttp.BasicAuth(nexus_user, nexus_token)
    total = 0
    continuation_token = None

    async with aiohttp.ClientSession(auth=auth) as session:
        while True:
            url = f"{nexus_url}/service/rest/v1/components"
            params = {"repository": nexus_repository}
            if continuation_token:
                params["continuationToken"] = continuation_token

            async with session.get(url, params=params) as response:
                response.raise_for_status()
                data = await response.json()

            items = data.get("items", [])
            total += len(items)

            delete_tasks = []
            for item in items:
                component_id = item["id"]
                print(f"Queuing deletion for component with id: {component_id}")
                delete_url = f"{nexus_url}/service/rest/v1/components/{component_id}"
                delete_tasks.append(session.delete(delete_url))

            # Execute all delete requests concurrently
            await asyncio.gather(*delete_tasks)

            continuation_token = data.get("continuationToken")
            if not continuation_token:
                break

    print(f"Total components deleted: {total}")


def parse_arguments():
    parser = argparse.ArgumentParser(description="Delete all files from a Nexus raw repository.")
    parser.add_argument("--nexus-url", help="Nexus URL (or set NEXUS_URL environment variable)")
    parser.add_argument("--nexus-repository", help="Nexus repository name (or set NEXUS_REPOSITORY environment variable)")
    parser.add_argument("--nexus-user", help="Nexus username (or set NEXUS_USER environment variable)")
    parser.add_argument("--nexus-token", help="Nexus token (or set NEXUS_TOKEN environment variable)")
    return parser


async def main():
    parser = parse_arguments()
    args = parser.parse_args()

    # Use environment variables as fallback
    nexus_url = args.nexus_url or os.environ.get("NEXUS_URL")
    nexus_repository = args.nexus_repository or os.environ.get("NEXUS_REPOSITORY")
    nexus_user = args.nexus_user or os.environ.get("NEXUS_USER")
    nexus_token = args.nexus_token or os.environ.get("NEXUS_TOKEN")

    if not all([nexus_url, nexus_repository, nexus_user, nexus_token]):
        parser.print_help()
        sys.exit(1)

    await nexus_delete_all_files_from_raw_repo(nexus_url, nexus_repository, nexus_user, nexus_token)


if __name__ == "__main__":
    asyncio.run(main())
