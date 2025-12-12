#!/Users/joshwren/dotfiles/.gcloud-auth-venv/bin/python3
"""
Automated gcloud auth login.
Copies Firefox profile to temp dir, uses Playwright to click through OAuth.
Caches working selectors for faster subsequent runs.
"""

import subprocess
import re
import sys
import os
import shutil
import tempfile
import json
import select
from pathlib import Path
from playwright.sync_api import sync_playwright, TimeoutError as PlaywrightTimeout, Error as PlaywrightError

YOUVERSION_EMAIL = "josh.wren@youversion.com"
FIREFOX_PROFILES_DIR = os.path.expanduser("~/Library/Application Support/Firefox/Profiles")
SELECTOR_CACHE_FILE = Path.home() / ".gcloud_auth_selectors.json"

# Default selectors to try
DEFAULT_CONSENT_SELECTORS = [
    'button:has-text("Continue")',
    'button:has-text("Allow")',
    'div[role="button"]:has-text("Continue")',
    'div[role="button"]:has-text("Allow")',
]


def load_selector_cache() -> dict:
    """Load cached selectors from disk."""
    if SELECTOR_CACHE_FILE.exists():
        try:
            with open(SELECTOR_CACHE_FILE) as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            pass
    return {"consent_selectors": [], "last_working": []}


def save_selector_cache(cache: dict):
    """Save working selectors to disk for future runs."""
    try:
        with open(SELECTOR_CACHE_FILE, "w") as f:
            json.dump(cache, f, indent=2)
    except IOError as e:
        print(f"Warning: Could not save selector cache: {e}")


def get_prioritized_selectors(cache: dict) -> list[str]:
    """Return selectors with last-working ones first."""
    last_working = cache.get("last_working", [])
    # Put last working selectors first, then defaults (without duplicates)
    seen = set()
    result = []
    for sel in last_working + DEFAULT_CONSENT_SELECTORS:
        if sel not in seen:
            seen.add(sel)
            result.append(sel)
    return result


def get_default_firefox_profile():
    """Find the default Firefox profile directory."""
    for entry in os.listdir(FIREFOX_PROFILES_DIR):
        if entry.endswith(".default-release"):
            return os.path.join(FIREFOX_PROFILES_DIR, entry)
    for entry in os.listdir(FIREFOX_PROFILES_DIR):
        if entry.endswith(".default"):
            return os.path.join(FIREFOX_PROFILES_DIR, entry)
    for entry in os.listdir(FIREFOX_PROFILES_DIR):
        full_path = os.path.join(FIREFOX_PROFILES_DIR, entry)
        if os.path.isdir(full_path) and not entry.startswith("."):
            return full_path
    return None


def copy_firefox_profile(src_profile: str) -> str:
    """Copy Firefox profile to temp directory."""
    temp_dir = tempfile.mkdtemp(prefix="gcloud_auth_firefox_")
    essential_files = [
        "cookies.sqlite",
        "cookies.sqlite-wal",
        "cookies.sqlite-shm",
        "prefs.js",
    ]
    for item in essential_files:
        src = os.path.join(src_profile, item)
        dst = os.path.join(temp_dir, item)
        if os.path.exists(src):
            shutil.copy2(src, dst)
    return temp_dir


def get_auth_code_from_url(url: str) -> str | None:
    """Extract auth code from URL if present."""
    match = re.search(r'[?&]code=([^&]+)', url)
    return match.group(1) if match else None


def main():
    env = os.environ.copy()
    env["BROWSER"] = "false"

    # Load cached selectors
    selector_cache = load_selector_cache()
    working_selectors = []  # Track which selectors worked this run

    print("Starting gcloud auth...")
    proc = subprocess.Popen(
        ["gcloud", "auth", "login", "--no-launch-browser"],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        stdin=subprocess.PIPE,
        text=True,
        env=env,
    )

    # Find the auth URL
    url = None
    while True:
        line = proc.stdout.readline()
        if not line:
            break
        print(line, end="")
        match = re.search(r'(https://accounts\.google\.com/o/oauth2/[^\s]+)', line)
        if match:
            url = match.group(1)
            break

    if not url:
        print("ERROR: Could not find auth URL")
        sys.exit(1)

    src_profile = get_default_firefox_profile()
    if not src_profile:
        print("ERROR: Could not find Firefox profile")
        sys.exit(1)

    temp_profile = copy_firefox_profile(src_profile)
    auth_code = None

    try:
        with sync_playwright() as p:
            browser = p.firefox.launch_persistent_context(
                temp_profile,
                headless=False,
                color_scheme="dark",
            )

            page = browser.pages[0] if browser.pages else browser.new_page()
            page.goto(url)

            # Wait for and click account
            account_selector = f'[data-identifier="{YOUVERSION_EMAIL}"]'
            try:
                page.wait_for_selector(account_selector, timeout=10000)
                page.click(account_selector)
                print(f"Clicked account: {YOUVERSION_EMAIL}")
            except PlaywrightTimeout:
                pass

            # Get prioritized selectors (cached working ones first)
            consent_selectors = get_prioritized_selectors(selector_cache)
            print(f"Using {len(consent_selectors)} selectors (cached: {len(selector_cache.get('last_working', []))})")

            # Keep clicking buttons and checking for code until we get it
            max_iterations = 20  # Prevent infinite loops
            iteration = 0
            while not auth_code and iteration < max_iterations:
                iteration += 1

                # Check if we got redirected to code page via URL
                try:
                    current_url = page.url
                    auth_code = get_auth_code_from_url(current_url)
                    if auth_code:
                        print("Got auth code from URL")
                        break
                    # Also check for sdk.cloud.google.com (code display page)
                    if "sdk.cloud.google.com" in current_url:
                        auth_code = get_auth_code_from_url(current_url)
                        if auth_code:
                            print("Got auth code from URL")
                            break
                except PlaywrightError:
                    pass

                # Try to click any visible consent button (prioritized order)
                clicked = False
                for selector in consent_selectors:
                    try:
                        btn = page.locator(selector).first
                        if btn.is_visible(timeout=500):  # Short timeout for visibility check
                            btn.click()
                            print(f"Clicked: {selector}")
                            working_selectors.append(selector)
                            clicked = True
                            page.wait_for_timeout(500)  # Brief pause after click
                            break
                    except (PlaywrightTimeout, PlaywrightError):
                        continue

                # If no button was clicked, wait for either a button or navigation
                if not clicked:
                    try:
                        page.wait_for_selector(
                            ', '.join(consent_selectors[:4]),  # Only wait on first few
                            timeout=30000  # 30 sec wait between clicks
                        )
                    except (PlaywrightTimeout, PlaywrightError):
                        # Check URL one more time before giving up
                        auth_code = get_auth_code_from_url(page.url)
                        break

            browser.close()

    finally:
        shutil.rmtree(temp_profile, ignore_errors=True)

    # Save working selectors for next time
    if working_selectors:
        # Deduplicate while preserving order
        seen = set()
        unique_working = []
        for s in working_selectors:
            if s not in seen:
                seen.add(s)
                unique_working.append(s)
        selector_cache["last_working"] = unique_working
        save_selector_cache(selector_cache)
        print(f"Cached {len(unique_working)} working selectors for next run")

    if not auth_code:
        auth_code = input("Paste the code here: ").strip()

    proc.stdin.write(auth_code + "\n")
    proc.stdin.flush()

    # Read any immediate output (2s timeout), then finish
    while select.select([proc.stdout], [], [], 2)[0]:
        line = proc.stdout.readline()
        if not line:
            break
        print(line, end="")

    proc.wait(timeout=3)
    print("Done!")


if __name__ == "__main__":
    main()
