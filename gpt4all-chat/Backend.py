import os
import json
import time
import argparse
import threading
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from concurrent.futures import ThreadPoolExecutor
# from selenium.common.exceptions import NoSuchElementException
# from selenium.common.exceptions import TimeoutException
# from selenium.webdriver.common.action_chains import ActionChains


# Paths to Chrome binary and ChromeDriver
chrome_binary_path = "/usr/bin/google-chrome"
chromedriver_path = "/usr/bin/chromedriver"
chrome_profile_path = "/mnt/c/Users/franc/AppData/Local/Google/Chrome/User Data"

# Load cookies from the exported JSON file
with open("/mnt/c/Users/franc/Github/head_start/Headstart/my_cookies.json", "r") as file:
    cookies = json.load(file)

# Add cookies
for cookie in cookies:
    # Fix the `sameSite` attribute if it has an invalid value
    if "sameSite" in cookie and cookie["sameSite"] not in ["Strict", "Lax", "None"]:
        cookie["sameSite"] = "Lax"  # Default to "Lax" if the value is invalid



# Set Chrome options
options = webdriver.ChromeOptions()
options.binary_location = chrome_binary_path
options.add_argument("--save-page-as-mhtml")  # Enable MHTML saving
# options.add_argument("--incognito")
# options.add_argument("--headless")  # Optional: Run in headless mode for efficiency
options.add_argument(f"user-data-dir={chrome_profile_path}")  # Use the mounted profile path
options.add_argument("--disable-blink-features=AutomationControlled")  # Evade detection
options.add_argument("--disable-extensions")  # Disable extensions for simplicity
options.add_experimental_option("excludeSwitches", ["enable-automation"])
options.add_experimental_option("useAutomationExtension", False)


# Lock to ensure thread-safe interaction with the shared WebDriver instance
webdriver_lock = threading.Lock()

def process_link(driver, lock, index, link, output_folder, total_links, failed_links):
    try:
        with lock:
            driver.get(link)
            WebDriverWait(driver, 25).until(EC.presence_of_element_located((By.TAG_NAME, "body")))
            # Scroll to the bottom to load dynamic content
            driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
            time.sleep(5)  # Allow extra time for content to load

            # Save page as MHTML
            file_path = os.path.join(output_folder, f"page_{index + 1}.mhtml")
            with open(file_path, 'wb') as file:
                mhtml_data = driver.execute_cdp_cmd("Page.captureSnapshot", {"format": "mhtml"})
                file.write(mhtml_data["data"].encode('utf-8'))


            # Emit progress
            progress = int(((index + 1) / total_links) * 100)
            print(json.dumps({"progress": progress, "status": f"Saved MHTML for link {index + 1} at {file_path}"}), flush=True)

    except Exception as e:
        failed_links.append(link)  # Add failed link to the list
        progress = int(((index + 1) / total_links) * 100)
        print(json.dumps({"progress": progress, "status": f"Failed to process link {index + 1}: {str(e)}"}), flush=True)


# Fetch links from Google Scholar
def fetch_links(driver, max_links=20):
    links = []
    page = 0

    while len(links) < max_links:
        # Find all links on the current page
        new_links = [link.get_attribute("href") for link in driver.find_elements(By.XPATH, "//h3[@class='gs_rt']/a")]
        links.extend(new_links)

        # Check if we have collected enough links
        if len(links) >= max_links:
            break

        # Try to navigate to the next page
        try:
            next_button = driver.find_element(By.XPATH, "//button[@aria-label='Next']")
            next_button.click()
            WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.XPATH, "//h3[@class='gs_rt']")))
            page += 1
            print(f"Navigated to page {page}")
        except Exception as e:
            print("No more pages or navigation failed:", e)
            break

    # Return the top `max_links` links
    return links[:max_links]

# Main function
def main(output_dir, query, dateLow='', dateHigh=''):
    service = Service(executable_path=chromedriver_path)
    driver = webdriver.Chrome(service=service, options=options)

    query = query.replace(" ", "+")
    url = f"https://scholar.google.com/scholar?hl=en&as_sdt=0%2C5&q={query}&as_ylo={dateLow}&as_yhi={dateHigh}"
    driver.get(url)

    # Add cookies
    for cookie in cookies:
        driver.add_cookie(cookie)

    # Refresh the page to apply cookies
    driver.refresh()

    time.sleep(10)  # Wait for the page to load

    links = fetch_links(driver, max_links=5)  # Fetch links from Google Scholar
    failed_links = []

    print(json.dumps({"progress": 0, "status": f"Found {len(links)} links to process"}), flush=True)

    # print("Number of links found:", len(links))
    # print(links)

    # Ensure save path directory exists
    os.makedirs(output_dir, exist_ok=True)

    # Use a thread-safe lock for WebDriver reuse
    with ThreadPoolExecutor(max_workers=min(10, len(links))) as executor:
        futures = [
            executor.submit(process_link, driver, webdriver_lock, index, link, output_dir, len(links), failed_links)
            for index, link in enumerate(links)
        ]
        # Wait for all threads to complete
        for future in futures:
            future.result()

    driver.quit()

    failed_count = len(failed_links)
    failed_percentage = int((failed_count / len(links)) * 100) if links else 0
    print(json.dumps({
        "progress": 100,
        "status": "All links processed",
        "failed_links": failed_links,
        "failed_percentage": failed_percentage
    }), flush=True)

if __name__ == "__main__":

    parser = argparse.ArgumentParser(description="Save webpage as MHTML using Selenium.")
    parser.add_argument("--output", required=True, help="Output directory to save MHTML files.")
    parser.add_argument("--query", required=True, help="Your query to search on Google Scholar.")
    parser.add_argument("--dateLow", default="", help="The lower bound of the publication date.")
    parser.add_argument("--dateHigh", default="", help="The upper bound of the publication date.")
    args = parser.parse_args()

    main(args.output, args.query, args.dateLow, args.dateHigh)









