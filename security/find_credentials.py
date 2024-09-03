import os
import toml
import configparser
import json
import base64
from abc import ABC, abstractmethod
from pathlib import Path
import argparse
import platform


class CredentialFinder(ABC):
    @abstractmethod
    def find_credential_file(self):
        pass

    @abstractmethod
    def read_credentials(self, file_path, decode_base64=False):
        pass

    def get_credentials(self, decode_base64=False):
        file_path = self.find_credential_file()
        if file_path:
            return self.read_credentials(file_path, decode_base64)
        return None


class CredentialPrinter(ABC):
    @abstractmethod
    def print_credentials(self, credentials):
        pass


class PoetryCredentialFinder(CredentialFinder):
    def find_credential_file(self):
        if platform.system() == "Windows":
            base_path = Path(os.environ.get("APPDATA", "")) / "pypoetry"
        else:  # Linux, macOS, and other Unix-like OS
            base_path = Path.home() / ".config" / "pypoetry"

        auth_file = base_path / "auth.toml"
        return auth_file if auth_file.is_file() else None

    def read_credentials(self, file_path):
        try:
            with open(file_path, "r") as file:
                config = toml.load(file)

            credentials = []
            for key, value in config.get("http-basic", {}).items():
                if "username" in value and "password" in value:
                    credentials.append(
                        {"tool": "Poetry", "repository": key, "username": value["username"], "password": value["password"], "file_path": str(file_path)}
                    )
            return credentials
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            return []


class PipCredentialFinder(CredentialFinder):
    def find_credential_file(self):
        if platform.system() == "Windows":
            possible_locations = [
                Path(os.environ.get("USERPROFILE", "")) / "pip" / "pip.ini",
                Path(os.environ.get("APPDATA", "")) / "pip" / "pip.ini",
            ]
        else:  # Linux, macOS, and other Unix-like OS
            possible_locations = [
                Path.home() / ".pip" / "pip.conf",
                Path("/etc/pip.conf"),
            ]

        for location in possible_locations:
            if location.is_file():
                return location
        return None

    def read_credentials(self, file_path):
        try:
            config = configparser.ConfigParser()
            config.read(file_path)

            credentials = []
            for section in config.sections():
                if "username" in config[section] and "password" in config[section]:
                    credentials.append(
                        {
                            "tool": "pip",
                            "repository": section,
                            "username": config[section]["username"],
                            "password": config[section]["password"],
                            "file_path": str(file_path),
                        }
                    )
            return credentials
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            return []


class AWSCredentialFinder(CredentialFinder):
    def find_credential_file(self):
        if platform.system() == "Windows":
            base_path = Path(os.environ.get("UserProfile", ""))
        else:  # Linux, macOS, and other Unix-like OS
            base_path = Path.home()

        cred_file = base_path / ".aws" / "credentials"
        return cred_file if cred_file.is_file() else None

    def read_credentials(self, file_path, decode_base64=False):
        try:
            config = configparser.ConfigParser()
            config.read(file_path)

            credentials = []
            for section in config.sections():
                if "aws_access_key_id" in config[section] and "aws_secret_access_key" in config[section]:
                    credentials.append(
                        {
                            "tool": "AWS CLI",
                            "profile": section,
                            "aws_access_key_id": config[section]["aws_access_key_id"],
                            "aws_secret_access_key": config[section]["aws_secret_access_key"],
                            "file_path": str(file_path),
                        }
                    )
            return credentials
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            return []


class DockerCredentialFinder(CredentialFinder):
    def find_credential_file(self):
        if platform.system() == "Windows":
            base_path = Path(os.environ.get("UserProfile", ""))
        else:  # Linux, macOS, and other Unix-like OS
            base_path = Path.home()

        config_file = base_path / ".docker" / "config.json"
        return config_file if config_file.is_file() else None

    def read_credentials(self, file_path, decode_base64=False):
        try:
            with open(file_path, "r") as file:
                config = json.load(file)

            credentials = []
            for registry, auth in config.get("auths", {}).items():
                if "auth" in auth:
                    auth_decoded = base64.b64decode(auth["auth"]).decode("utf-8") if decode_base64 else auth["auth"]
                    username, password = auth_decoded.split(":") if decode_base64 else (None, None)
                    credentials.append(
                        {
                            "tool": "Docker",
                            "registry": registry,
                            "auth": auth["auth"],
                            "username": username if decode_base64 else None,
                            "password": password if decode_base64 else None,
                            "file_path": str(file_path),
                        }
                    )
            return credentials
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            return []


class PoetryCredentialPrinter(CredentialPrinter):
    def print_credentials(self, credentials):
        for cred in credentials:
            print(f"Tool: {cred['tool']}")
            print(f"Repository: {cred['repository']}")
            print(f"Username: {cred['username']}")
            print(f"Password: {'*' * len(cred['password'])}")
            print(f"File Path: {cred['file_path']}")
            print()


class PipCredentialPrinter(CredentialPrinter):
    def print_credentials(self, credentials):
        for cred in credentials:
            print(f"Tool: {cred['tool']}")
            print(f"Repository: {cred['repository']}")
            print(f"Username: {cred['username']}")
            print(f"Password: {'*' * len(cred['password'])}")
            print(f"File Path: {cred['file_path']}")
            print()


class AWSCredentialPrinter(CredentialPrinter):
    def print_credentials(self, credentials):
        for cred in credentials:
            print(f"Tool: {cred['tool']}")
            print(f"Profile: {cred['profile']}")
            print(f"AWS Access Key ID: {cred['aws_access_key_id']}")
            print(f"AWS Secret Access Key: {'*' * len(cred['aws_secret_access_key'])}")
            print(f"File Path: {cred['file_path']}")
            print()


class DockerCredentialPrinter(CredentialPrinter):
    def print_credentials(self, credentials):
        for cred in credentials:
            print(f"Tool: {cred['tool']}")
            print(f"Registry: {cred['registry']}")
            print(f"Auth: {cred['auth']}")
            if cred["username"]:
                print(f"Username: {cred['username']}")
            if cred["password"]:
                print(f"Password: {'*' * len(cred['password'])}")
            print(f"File Path: {cred['file_path']}")
            print()


class CredentialManager:
    def __init__(self):
        self.finders = {
            "poetry": (PoetryCredentialFinder(), PoetryCredentialPrinter()),
            "pip": (PipCredentialFinder(), PipCredentialPrinter()),
            "aws": (AWSCredentialFinder(), AWSCredentialPrinter()),
            "docker": (DockerCredentialFinder(), DockerCredentialPrinter()),
        }

    def get_all_credentials(self, decode_base64=False):
        all_credentials = []
        for finder, printer in self.finders.values():
            credentials = finder.get_credentials(decode_base64)
            if credentials:
                all_credentials.append((credentials, printer))
        return all_credentials

    def get_tool_credentials(self, tool_name, decode_base64=False):
        if tool_name in self.finders:
            finder, printer = self.finders[tool_name]
            credentials = finder.get_credentials(decode_base64)
            if credentials:
                return [(credentials, printer)]
        return None


def print_credentials(credential_printer_pairs):
    if credential_printer_pairs:
        print("\nFound credentials:")
        for credentials, printer in credential_printer_pairs:
            printer.print_credentials(credentials)
    else:
        print("No credentials found.")


def main():
    parser = argparse.ArgumentParser(description="Check for Python package manager and other tool credentials.")
    parser.add_argument("--tool", choices=["poetry", "pip", "aws", "docker"], help="Specify the tool to check")
    parser.add_argument("-a", "--all", action="store_true", help="Check all supported tools")
    parser.add_argument("--decode-base64", action="store_true", help="Decode base64-encoded credentials")
    args = parser.parse_args()

    manager = CredentialManager()

    if args.all:
        credential_printer_pairs = manager.get_all_credentials(args.decode_base64)
    elif args.tool:
        credential_printer_pairs = manager.get_tool_credentials(args.tool, args.decode_base64)
    else:
        parser.print_help()
        return

    print_credentials(credential_printer_pairs)


if __name__ == "__main__":
    main()
