### R Code Script for Online Data Collection and Management Research Project
#### Scraping AliExpress: Unveiling Market Trends in Consumer Electronics.


# Load the R-libraries required for data manipulation, visualisation procedures, and statistical analyses.
library(forcats)
library(ggplot2)
library(lubridate)
library(readr)
library(scales)
library(stringr)
library(tidyverse)


# Load the ``AliExpress_Consumer_Electronics_Product_Data.csv`` data file.
product_data <- read_csv("Data/AliExpress_Consumer_Electronics_Product_Data.csv")

# View and summarise the resulting `product_data` data frame.
View(product_data)
summary(product_data)
colnames(product_data)


# Initial Data Exploration
# View the basic structure and content of the dataset to inform subsequent cleaning and analysis steps.
print("First few rows of the dataset:")
head(product_data)

print("Structure of the dataset:")
str(product_data)


# Data Cleaning
# Address the missing values and transform data types to improve the accuracy and insightfulness of the analysis.
missing_values <- sapply(product_data, function(x) sum(is.na(x)))
print(missing_values)


# Convert the `price` variable to numeric, assuming it contains currency symbols or non-numeric characters.
product_data$price_numeric <- as.numeric(gsub("[^0-9\\.]", "", product_data$price))


# Extract the numeric values from `trade` and substitute missing values by 0.
product_data$trade_numeric <- as.numeric(gsub("[^0-9\\.]", "", product_data$trade))
product_data$trade_numeric[is.na(product_data$trade_numeric)] <- 0


# Create a USD conversion column necessary for standardised financial analysis across different currencies.
conversion_rate <- 1
product_data$price_usd <- product_data$price_numeric * conversion_rate


# Data Analyses
# Enhancing data with additional computed columns facilitates more profound and in-depth analyses.
product_data$thumbnail_url <- paste0("https://www.aliexpress.com/item/", product_data$thumbnail)


# Advanced Data Analysis and Visualisation
# Analyse the the dataset in a more advanced and sophisticated manner, thereby rendering visualisations and performing more advanced statistical analyses to uncover new insights.


# Examine the product type distribution to understand the range of offerings.
product_type_distribution <- product_data %>% 
  mutate(type = fct_infreq(type)) %>% 
  ggplot(aes(x = type)) + 
  geom_bar(fill = "steelblue") +
  coord_flip() +
  labs(title = "Product Type Distribution", x = "Product Type", y = "Frequency") +
  theme_minimal()
product_type_distribution


# Analyse the price distribution to identify pricing strategies and ranges.
price_distribution_plot <- ggplot(product_data, aes(x = price_usd)) +
  geom_histogram(bins = 30, fill = "coral", color = "black") +
  scale_x_continuous(labels = scales::dollar_format()) +
  labs(title = "Distribution of Prices in USD", x = "Price (USD)", y = "Number of Products") +
  theme_minimal()
price_distribution_plot


# Explore the relationship between `trade_numeric` and `price_usd` to see if higher trade correlates with pricing.
trade_price_correlation <- ggplot(product_data, aes(x = trade_numeric, y = price_usd)) +
  geom_point(aes(color = type), alpha = 0.6) +
  geom_smooth(method = "lm", se = FALSE, color = "blue") +
  labs(title = "The Correlation Between Trade Volume and Price", x = "Trade Volume", y = "Price (USD)") +
  theme_minimal()
trade_price_correlation


# Identify the top 10 stores by product count to pinpoint major sellers and their average pricing.
top_stores_by_product_count <- product_data %>%
  group_by(store_name) %>%
  summarise(Total_Products = n(), Average_Price_USD = mean(price_usd, na.rm = TRUE)) %>%
  top_n(10, Total_Products) %>%
  arrange(desc(Total_Products))
print("Top 10 Stores by Product Count")
print(top_stores_by_product_count)


# Render the Store Performance Visualisation.
# Visualise the store performance to highlight top performers and their pricing strategies.
top_stores_visualisation <- ggplot(top_stores_by_product_count, aes(x = reorder(store_name, Total_Products), y = Total_Products, fill = Average_Price_USD)) +
  geom_col() +
  scale_fill_viridis_c() +
  coord_flip() +
  labs(title = "Top 10 Stores by Product Count and Average Pricing", x = "Store Name", y = "Total Products") +
  theme_minimal()
top_stores_visualisation


# Save the cleaned dataset.
write.csv(product_data, "Cleaned_AliExpress_Consumer_Electronics_Data.csv", row.names = FALSE)
