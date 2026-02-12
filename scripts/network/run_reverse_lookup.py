#!/usr/bin/env -S uv run
import argparse
import ipaddress
import socket
import logging
from concurrent import futures


class ReverseLookup:
    """
    This class is designed to perform reverse DNS lookup for all hosts in a specified subnet.
    It uses the thread pool executor from Python's concurrent.futures module, which allows it to parallelize the name resolution process.

    Attributes:
        subnet (str): The IP address of the network.
        mask (int): The netmask for the subnet.

    Methods:
        lookup(host) -> str: This method attempts to resolve an IP address into a hostname using socket.gethostbyaddr() function. If resolution fails, it logs a warning message and returns 'NA'.
        run() -> dict[str, str]: This method generates an IPv4Network object from the subnet and mask provided during initialization of this class instance. It then loops over all hosts in that network (excluding the last octet with value 255 as it is reserved for broadcast purposes), submits each host to a thread pool executor which calls lookup() method, collects all futures into a dictionary where keys are IP addresses and values are futures objects returned by executor.submit() function. Finally, this method returns a new dictionary where keys are the same as in the original one but values are results of the futures obtained through the .result() method.
    """

    def __init__(self, subnet, mask):
        self.subnet = subnet
        self.mask = mask

    def lookup(self, host):
        try:
            fqdn = socket.gethostbyaddr(str(host))[0]
        except Exception:
            logging.warning("Could not resolve IP address for {}".format(host))
            fqdn = "NA"
        return fqdn

    def run(self):
        network = ipaddress.IPv4Network(f"{self.subnet}/{self.mask}", strict=False)
        results = {}

        with futures.ThreadPoolExecutor() as executor:
            for host in network.hosts():
                host_str = str(host)
                # Skip last octet with value 255 as it's reserved for broadcast purposes.
                if int(host_str.split(".")[-1]) == 255:
                    continue
                future = executor.submit(self.lookup, host_str)
                results[host_str] = future
        return {key: value.result() for key, value in results.items()}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--network", required=True, help="Network subnet in CIDR format e.g 192.168.0"
    )
    parser.add_argument("--mask", type=int, required=True, help="Subnet mask e.g 24")
    args = parser.parse_args()

    logging.basicConfig(
        level=logging.INFO
    )  # Set logging level as per requirement (DEBUG/INFO/ERROR)
    result = ReverseLookup(args.network, args.mask)
    for ip, dns_name in result.run().items():
        if dns_name != "NA":
            print(f"{ip}: {dns_name}")


if __name__ == "__main__":
    main()
