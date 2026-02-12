#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "pyyaml>=6.0.3",
# ]
# ///
import argparse
import subprocess
from typing import Optional

import yaml


class ServiceSelectorChecker:
    def __init__(self, root_dir: str) -> None:
        self.root_dir = root_dir
        self.service_data = []
        self.vs_data = []

    def check_service_selector_vs_virtualservice_host(self) -> bool:
        mismatch = False

        for vs in self.vs_data:
            vs_service_name = vs["spec"]["http"][0]["route"][0]["destination"]["host"]
            service_selector_label = self.get_service_selector(vs_service_name)

            if not service_selector_label:
                raise ValueError(
                    f"No service selector found for Service: {vs_service_name}"
                )

            if vs_service_name != service_selector_label:
                mismatch = True
                print("Mismatch detected:")
                print(f"VirtualService Host: {vs_service_name}")
                print(f"Service Selector:    {service_selector_label}")
                print("---")
            else:
                print(f"Match found: {service_selector_label}")

        return mismatch

    def get_service_selector(self, service_name: str) -> Optional[str]:
        selector_label = "app"

        for service in self.service_data:
            if (
                service["metadata"]["name"] == service_name
                and "spec" in service
                and "selector" in service["spec"]
            ):
                return service["spec"]["selector"].get(selector_label)

        return None

    def load_kustomize_data(self) -> None:
        kustomize_output = subprocess.run(
            ["kustomize", "build", self.root_dir],
            capture_output=True,
            check=True,
            text=True,
        ).stdout
        kustomize_data = yaml.safe_load_all(kustomize_output)

        for data in kustomize_data:
            if data["kind"] == "Service":
                self.service_data.append(data)
            if data["kind"] == "VirtualService":
                self.vs_data.append(data)

    def run(self) -> None:
        self.load_kustomize_data()

        if not self.service_data:
            print("No Service resources found.")
            return
        if not self.vs_data:
            print("No VirtualService resources found.")
            return
        else:
            mismatch_found = self.check_service_selector_vs_virtualservice_host()
            if mismatch_found:
                exit(1)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Check Service selectors against VirtualService hosts"
    )
    parser.add_argument(
        "-d", "--dir", dest="root_dir", help="Root directory to start the search"
    )
    args = parser.parse_args()

    if not args.root_dir:
        parser.print_help()
        parser.exit(status=1, message="Error: No root directory provided.\n")

    checker = ServiceSelectorChecker(args.root_dir)
    checker.run()
