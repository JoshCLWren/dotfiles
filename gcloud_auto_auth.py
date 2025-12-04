#!/Users/joshwren/dotfiles/.gcloud-auth-venv/bin/python3
"""
Automated gcloud auth login.
Copies Firefox profile to temp dir, uses Playwright to click through OAuth.
"""

import subprocess
import re
import sys
import os
import shutil
import tempfile
from playwright.sync_api import sync_playwright, TimeoutError as PlaywrightTimeout

YOUVERSION_EMAIL = "josh.wren@youversion.com"
FIREFOX_PROFILES_DIR = os.path.expanduser("~/Library/Application Support/Firefox/Profiles")


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


def try_click(page, selectors, timeout=2000):
    """Try clicking any of the selectors, return True if successful."""
    for selector in selectors:
        try:
            page.click(selector, timeout=timeout)
            return True
        except PlaywrightTimeout:
            continue
    return False


def get_auth_code_from_page(page):
    """Try to extract auth code from current page."""
    # Check URL first
    url = page.url
    match = re.search(r'[?&]code=([^&]+)', url)
    if match:
        return match.group(1)

    # Check page content for code pattern
    try:
        text = page.inner_text('body')
        # Look for authorization code patterns
        matches = re.findall(r'4/[0-9A-Za-z_-]{20,}', text)
        if matches:
            return max(matches, key=len)
    except:
        pass

    return None


def main():
    env = os.environ.copy()
    env["BROWSER"] = "false"

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
            page.wait_for_load_state("domcontentloaded")

            page.wait_for_timeout(500)
            try_click(page, [
                f'[data-identifier="{YOUVERSION_EMAIL}"]',
                f'text={YOUVERSION_EMAIL}',
            ], timeout=3000)

            # Step 2: Click through consent screens (may be multiple)
            for attempt in range(5):
                page.wait_for_load_state("domcontentloaded")
                page.wait_for_timeout(500)

                # Check if we got the code
                auth_code = get_auth_code_from_page(page)
                if auth_code:
                    break

                # Try clicking Allow/Continue buttons
                try_click(page, [
                    'button:has-text("Continue")',
                    'button:has-text("Allow")',
                    'div[role="button"]:has-text("Continue")',
                    'div[role="button"]:has-text("Allow")',
                    '#submit_approve_access',
                    'button[type="submit"]',
                ], timeout=1000)

            if not auth_code:
                for _ in range(20):
                    page.wait_for_timeout(500)
                    auth_code = get_auth_code_from_page(page)
                    if auth_code:
                        break

            browser.close()

    finally:
        shutil.rmtree(temp_profile, ignore_errors=True)

    if not auth_code:
        auth_code = input("Paste the code here: ").strip()


    proc.stdin.write(auth_code + "\n")
    proc.stdin.flush()

    out, _ = proc.communicate(timeout=30)
    if out:
        print(out)

    print("Done!")


if __name__ == "__main__":
    main()
