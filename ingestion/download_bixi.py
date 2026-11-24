"""Download the yearly BIXI open-data ZIP files into data/raw/.

The BIXI download links are not predictable (the folder depends on the upload
date and the file name lists the months covered), so this script reads the
open data page, finds the ZIP link of each requested year, and downloads the
files that are missing or whose size changed. If BIXI republishes a year under
a new file name, the older ZIP of that year is removed after the new one has
been downloaded and checked.

Only the Python standard library is used, so it runs anywhere.

Examples:
    python ingestion/download_bixi.py --dry-run
    python ingestion/download_bixi.py --years 2025 2026
"""
import argparse
import os
import re
import sys
import time
import urllib.error
import urllib.request
import zipfile

PAGE_URL = "https://bixi.com/fr/donnees-ouvertes/"
USER_AGENT = "Mozilla/5.0 (compatible; bixi-data-platform)"
ZIP_LINK = re.compile(r"""https?://[^\s"'<>]+?\.zip""", re.IGNORECASE)
YEAR_IN_NAME = re.compile(r"(?:DonneesOuvertes?|Historique-BIXI-)(20\d{2})", re.IGNORECASE)
ATTEMPTS = 3


def year_of(name):
    """Year in a BIXI file name, or None if the name has no known pattern."""
    match = YEAR_IN_NAME.search(name)
    return int(match.group(1)) if match else None


def find_links(html):
    """Return {year: url} for every BIXI ZIP link found in the page (first link wins)."""
    links = {}
    for url in ZIP_LINK.findall(html):
        year = year_of(os.path.basename(url))
        if year is not None and year not in links:
            links[year] = url
    return links


def open_url(url, method="GET"):
    request = urllib.request.Request(url, method=method, headers={"User-Agent": USER_AGENT})
    return urllib.request.urlopen(request, timeout=60)


def with_retries(action, label):
    for attempt in range(1, ATTEMPTS + 1):
        try:
            return action()
        except (urllib.error.URLError, OSError) as error:
            client_error = isinstance(error, urllib.error.HTTPError) and 400 <= error.code < 500
            if attempt == ATTEMPTS or client_error:
                raise
            print(f"{label}: attempt {attempt} failed ({error}), retrying in {5 * attempt}s")
            time.sleep(5 * attempt)


def remote_size(url):
    """Size in bytes announced by the server, or None if it does not say."""
    try:
        with with_retries(lambda: open_url(url, "HEAD"), "size check") as response:
            length = response.headers.get("Content-Length")
    except urllib.error.HTTPError as error:
        if error.code not in (400, 403, 405, 501):
            raise
        # Some servers refuse HEAD: read the size from the headers of a GET and
        # close the connection without downloading the body.
        with with_retries(lambda: open_url(url), "size check") as response:
            length = response.headers.get("Content-Length")
    return int(length) if length else None


def download(url, destination, expected_size):
    """Download to a temporary file, check it, then move it into place."""
    temporary = destination + ".part"
    try:
        with with_retries(lambda: open_url(url), "download") as response, open(temporary, "wb") as out:
            while True:
                chunk = response.read(1024 * 1024)
                if not chunk:
                    break
                out.write(chunk)
        size = os.path.getsize(temporary)
        if expected_size is not None and size != expected_size:
            raise OSError(f"incomplete download: {size:,} bytes instead of {expected_size:,}")
        with zipfile.ZipFile(temporary) as archive:
            if not any(name.lower().endswith(".csv") for name in archive.namelist()):
                raise OSError("the ZIP file contains no CSV file")
        os.replace(temporary, destination)
    finally:
        if os.path.exists(temporary):
            os.remove(temporary)


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--years", type=int, nargs="+", default=[2025, 2026])
    parser.add_argument("--dest", default="data/raw")
    parser.add_argument("--page-url", default=PAGE_URL)
    parser.add_argument("--dry-run", action="store_true", help="show what would be done, change nothing")
    args = parser.parse_args()

    with with_retries(lambda: open_url(args.page_url), "page") as response:
        html = response.read().decode("utf-8", errors="replace")
    links = find_links(html)

    missing = [year for year in args.years if year not in links]
    if missing:
        print(f"ERROR: no ZIP link found on the page for year(s) {missing}", file=sys.stderr)
        sys.exit(1)

    os.makedirs(args.dest, exist_ok=True)
    changed = 0
    for year in sorted(args.years):
        url = links[year]
        name = os.path.basename(url)
        destination = os.path.join(args.dest, name)
        size = remote_size(url)

        if os.path.exists(destination) and (size is None or os.path.getsize(destination) == size):
            print(f"{year}: {name} is up to date")
            continue

        action = "would download" if args.dry_run else "downloading"
        print(f"{year}: {action} {name} ({size:,} bytes)" if size else f"{year}: {action} {name}")
        if not args.dry_run:
            download(url, destination, size)
        changed += 1

        for other in sorted(os.listdir(args.dest)):
            if other != name and other.lower().endswith(".zip") and year_of(other) == year:
                verb = "would remove" if args.dry_run else "removing"
                print(f"{year}: {verb} the older file {other}")
                if not args.dry_run:
                    os.remove(os.path.join(args.dest, other))

    print(f"Done: {changed} file(s) {'to download' if args.dry_run else 'downloaded'}.")


if __name__ == "__main__":
    main()
