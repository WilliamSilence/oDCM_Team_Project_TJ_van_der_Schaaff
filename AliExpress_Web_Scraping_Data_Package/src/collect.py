# Python Code Script for Web Scraping "Consumer Electronics" Product Data From AliExpress.

# Install the required Python libraries.
# !pip install selenium webdriver_manager google-cloud-logging parsel httpx pandas


# Import the required Python libraries.
import httpx
import json
import os
import pandas as pd
import selenium
import time
from google.cloud import logging
from parsel import Selector
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from typing import Dict
from webdriver_manager.chrome import ChromeDriverManager


# Setup the Chrome WebDriver.
webdriver_service = Service(ChromeDriverManager().install())
chrome_options = webdriver.ChromeOptions()
chrome_options.add_argument('--headless')
chrome_options.add_argument('--no-sandbox')
chrome_options.add_argument('--disable-dev-shm-usage')
driver = webdriver.Chrome(service=webdriver_service, options=chrome_options)


# Set the URL to web scrape and store it in the `url` variable.
url = "https://www.aliexpress.com/category/44/consumer-electronics.html"


# Navigate to the URL webpage address that was stored in the `url` variable.
driver.get(url)


# Wait for the dynamic content to load.
time.sleep(5)


# Define the list to store the product data that will be extracted from the AliExpress Consumer ELectronics product category webpage into.
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
    data = extract_search(response)  # Assuming you have a function called `extract_search`
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

if __name__ == "__main__":

    # Define the total number of pages.
    num_pages = 18

    # Initialise an empty list, named ``all_product_data``, to store the product data.
    all_product_data = []

    # Loop through each page.
    for page_num in range(1, num_pages + 1):
        url = f"https://www.aliexpress.com/category/44/consumer-electronics.html?page={page_num}"
        resp = httpx.get(url, follow_redirects=True)
        product_data = parse_search(resp)
        all_product_data.extend(product_data)

    # Convert the combined data to the ``df_all_product_data`` DataFrame.
    df_all_product_data = pd.json_normalize(all_product_data)

    # Save the ``df_all_product_data`` DataFrame to a CSV file, named ``Resit_AliExpress_Consumer_Electronics_Product_Data``.
    df_all_product_data.to_csv("Resit_AliExpress_Consumer_Electronics_Product_Data.csv", index=False)

    # Print the first few rows of the ``df_all_product_data`` DataFrame.
    print(df_all_product_data.head())




