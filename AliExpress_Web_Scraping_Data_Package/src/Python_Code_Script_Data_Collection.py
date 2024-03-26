
""" Google Colab Python Code Script for Web Scraping Consumer Electronics Product Data From the AliExpress Website.


# Google Colab Python Code Script - Scraping AliExpress: Unveiling Market Trends in Consumer Electronics

## 1. Install Necessary Packages
"""

# Download Google Chrome Linux.
!wget https://storage.googleapis.com/chrome-for-testing-public/122.0.6261.94/linux64/chrome-linux64.zip

# Unzip the downloaded binary file.
!unzip chrome-linux64.zip

# Download the latest Chromedriver
!wget https://storage.googleapis.com/chrome-for-testing-public/122.0.6261.94/linux64/chromedriver-linux64.zip

# Unzip the downloaded chromedriver binary file
!unzip chromedriver-linux64.zip

# Install the Selenium and webdriver_manager Python libraries.
!python3 -m pip install selenium webdriver_manager httpx parsel jmespath pandas

# Remove the archive files
!rm chrome-linux64.zip  chromedriver-linux64.zip


"""## 2. Import Required Python Libraries"""

# Import the required Python libraries for web scraping AliExpress.
import os
import selenium
import json
import httpx
import pandas as pd
import time
from parsel import Selector
from typing import Dict
from selenium import webdriver
from selenium.webdriver.common.by import By
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service

"""## 3. Configure the Selenium WebDriver"""

## Setup the chrome options.
chrome_options = Options()
chrome_options.add_argument("--headless") # Ensure GUI is off
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument("--window-size=1600,900")

# Specify the paths for both Chrome and ChromeDriver.
chrome_binary_path = "/content/chrome-linux64/chrome"
chromedriver_path = "/content/chromedriver-linux64/chromedriver"

# Initialise the `chrome_options` and `webdriver_service` objects.
chrome_options.binary_location = chrome_binary_path
webdriver_service = Service(chromedriver_path)



"""## 4. Initialise the Google Chrome WebDriver"""

# Use the `webdriver_service`.
driver = webdriver.Chrome(service=webdriver_service, options=chrome_options)

"""## 5. Define Target URL"""

# Set/specify the `url` object by assigning the URL webpage address of the consumer electronics webpage on AliExpress.com to the object.
url = "https://www.aliexpress.com/category/44/consumer-electronics.html"

# Navigate to the URL.
driver.get(url)

# Wait for the dynamic content to load
time.sleep(5)

"""## 6. Identify and Extract the Product Data from the URL webpage address as specified above"""

# Define the list in which to store the product data.
products_list = []

# Define the `extract_search(response)` function.
def extract_search(response) -> Dict:
    """extract json data from search page"""
    sel = Selector(response.text)

    # Find the script with result.pagectore data in it._it_t_=
    script_with_data = sel.xpath('//script[contains(.,"_init_data_=")]')

    # Select the page data from javascript variable in script tag using regex.
    data = json.loads(script_with_data.re(r'_init_data_\s*=\s*{\s*data:\s*({.+}) }')[0])
    return data['data']['root']['fields']

# Define the `parse_search` function to include "store" details.
def parse_search(response):
    """Parse the search page response for product preview results"""
    data = extract_search(response)
    parsed = []
    for result in data["mods"]["itemList"]["content"]:
        store = result["store"]
        parsed.append({
            "id": result["productId"],
            "url": f"https://www.aliexpress.com/item/{result['productId']}.html",
            "type": result["productType"],
            "title": result["title"]["displayTitle"],
            "price": result["prices"]["salePrice"]["minPrice"],
            "currency": result["prices"]["salePrice"]["currencyCode"],
            "trade": result.get("trade", {}).get("tradeDesc"),
            "thumbnail": result["image"]["imgUrl"].lstrip("/"),
            "store_url": store["storeUrl"],
            "store_name": store["storeName"],
            "store_id": store["storeId"],
            "store_ali_id": store["aliMemberId"],
        })
    return parsed

# Define the `if __name__ == "__main__"` block to save the parsed data into a variable.
if __name__ == "__main__":
    # For example, this category is for consumer electronics:
    resp = httpx.get("https://www.aliexpress.com/category/44/consumer-electronics.html", follow_redirects = True)
    product_data = parse_search(resp)  # This will store the parsed data into the variable
    print(json.dumps(product_data, indent = 2, ensure_ascii = False))

# Convert the JSON data to a DataFrame and separate store details into columns.
df = pd.json_normalize(product_data)
print(df.head())

# Save the DataFrame to a CSV file.
df.to_csv("AliExpress_Consumer_Electronics_Product_Data.csv", index = False)







