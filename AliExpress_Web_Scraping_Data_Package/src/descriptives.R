##### R Code Script for Online Data Collection and Management Research Project.

# Get the current working directory.
getwd()

# Use the `setwd()` function to set the working directory to the desired path, "~/Resit_oDCM_Team_Project".
setwd("~/Resit_oDCM_Team_Project")


# Define a minimalist theme
theme_minimalist <- function() {
  theme_minimal() +
    theme(
      panel.grid.major.x = element_blank(),
      panel.grid.minor.x = element_blank(),
      legend.position = "bottom", 
      legend.title = element_blank()
    )
}


# Install the required R-libraries.
install.packages("corrplot")
install.packages("dplyr")
install.packages("forcats")
install.packages("ggplot2")
install.packages("googleLanguageR")
install.packages("gridExtra")
install.packages("lubridate")
install.packages("readr")
install.packages("readxl")
install.packages("scales")
install.packages("stringr")
install.packages("tidyr")
install.packages("tidyverse")
install.packages("viridis")
install.packages("writexl")


# Load the R-libraries required for data manipulation, visualisation procedures, and statistical analyses.
library(corrplot)
library(dplyr)
library(forcats)
library(ggplot2)
library(googleLanguageR)
library(gridExtra)
library(lubridate)
library(readr)
library(readxl)
library(scales)
library(stringr)
library(tidyr)
library(tidyverse)
library(viridis)
library(writexl)


# Load the ``AliExpress_Consumer_Electronics_Product_Data_15_Pages.csv`` data file as the `product_data` variable.
# product_data <- read_csv("data/AliExpress_Consumer_Electronics_Product_Data_15_Pages.csv")
product_data <- read_xlsx("data/Raw_AliExpress_Consumer_Electronics_Data.xlsx")

# View and summarise the resulting `product_data` data frame.
View(product_data)
summary(product_data)
colnames(product_data)


### Initial Data Exploration
# View the basic structure and content of the dataset to inform subsequent cleaning and analysis steps.
print("First few rows of the dataset:")
head(product_data)

# Display the internal structure of the `product_data` data frame.
print("Structure of the dataset:")
str(product_data)

# Produce summary statistics of all variables comprising the `product_data` data frame. 
print("Summary statistics of all variables in the data frame")
summary(product_data)


# ------------------------------------------------------------------------------
# Data Translation
# ------------------------------------------------------------------------------

## Translate the titles in the dataset using the ``googleLanguageR`` library.
# Set the Google Cloud Translation API key.
googleAuthR::gar_auth_service(json_file = "~/Resit_oDCM_Team_Project/automatic-translation-422014-b226254e9e10.json")

# Function to translate titles.
translate_titles_gl <- function(data) {
  data %>%
    rowwise() %>%
    mutate(
      # Translate title using Google Cloud Translation API
      translated_title = gl_translate(title, target = "en")$translatedText
    ) %>%
    ungroup()
}


# Apply the translation function specified above to the instances comprising the `title`` data column of the ``product_data`` data frame.
translated_product_data <- translate_titles_gl(product_data)

# View the translated data frame.
View(translated_product_data)


# Export the `translated_product_data` data frame and save locally as the `Translated_AliExpress_Consumer_Electronics_Product_Data.csv` CSV file.
write_csv(translated_product_data, "data/Translated_AliExpress_Consumer_Electronics_Product_Data.csv")
write_xlsx(translated_product_data, "data/Translated_AliExpress_Consumer_Electronics_Product_Data.xlsx")

# ------------------------------------------------------------------------------
# RUN ONLY AFTER RESTARTING R KERNEL: Import the saved translated product dataset as translated_product_data.
# translated_product_data <- read_csv("data/Translated_AliExpress_Consumer_Electronics_Product_Data.csv")
# translated_product_data <- read_xlsx("data/Translated_AliExpress_Consumer_Electronics_Product_Data.xlsx")
# View(translated_product_data)
# ------------------------------------------------------------------------------





# ------------------------------------------------------------------------------
# Data Cleaning and Data Preprocessing
# ------------------------------------------------------------------------------

# Address the missing values and transform data types to improve the accuracy and insightfulness of the analysis.
missing_values <- sapply(translated_product_data, function(x) sum(is.na(x)))
print(paste("Missing values per column:"))
print(missing_values)


# Impute missing values with median for numeric columns and mode for categorical columns
numeric_columns <- sapply(translated_product_data, is.numeric)
categorical_columns <- !numeric_columns


# Impute numeric columns with median.
for (column in names(translated_product_data)[numeric_columns]) {
  translated_product_data[[column]][is.na(translated_product_data[[column]])] <- median(translated_product_data[[column]], na.rm = TRUE)
}


# Impute categorical columns with mode.
for (column in names(translated_product_data)[categorical_columns]) {
  translated_product_data[[column]][is.na(translated_product_data[[column]])] <- names(which.max(table(translated_product_data[[column]])))
}


# Convert the `price` variable to numeric, assuming it contains currency symbols or non-numeric characters.
translated_product_data$price_numeric <- as.numeric(gsub("[^0-9\\.]", "", translated_product_data$price))


# Create a USD conversion column necessary for standardised financial analysis across different currencies.
conversion_rate <- 1
translated_product_data$price_usd <- translated_product_data$price_numeric * conversion_rate


# Extract the numeric values from `trade` and substitute missing values by 0.
translated_product_data$trade_numeric <- as.numeric(gsub("[^0-9\\.]", "", translated_product_data$trade))
translated_product_data$trade_numeric[is.na(translated_product_data$trade_numeric)] <- 0


# Use the interquartile range (IQR) method to identify the outliers in the `price_usd` column of the data.
Q1 <- quantile(translated_product_data$price_usd, 0.25)
Q3 <- quantile(translated_product_data$price_usd, 0.75)
IQR <- Q3 - Q1
outliers <- translated_product_data$price_usd < (Q1 - 1.5 * IQR) | translated_product_data$price_usd > (Q3 + 1.5 * IQR)


# Visualise the outliers using a box plot.
boxplot <- ggplot(translated_product_data, aes(x = "", y = price_usd)) +
  geom_boxplot(fill = "#E9EEEE", color = "gray0") +
  coord_cartesian(ylim = c(0, 70))
  labs(title = "Boxplot of Prices in USD", x = "", y = "Price (USD)") +
  theme_minimalist()
print(boxplot)



# Winsorise outliers to the 5th and 95th percentiles.
translated_product_data$price_winsorized <- ifelse(
  translated_product_data$price_usd < quantile(translated_product_data$price_usd, 0.05, na.rm = TRUE),
  quantile(translated_product_data$price_usd, 0.05, na.rm = TRUE),
  ifelse(
    translated_product_data$price_usd > quantile(translated_product_data$price_usd, 0.95, na.rm = TRUE),
    quantile(translated_product_data$price_usd, 0.95, na.rm = TRUE),
    translated_product_data$price_usd
  )
)


# Price distribution before and after Winsorisation.
p1 <- ggplot(translated_product_data, aes(x = price_usd)) +
  geom_histogram(aes(y = ..density..), bins = 30, fill = "#E9EEEE", color = "gray0") +
  geom_density(alpha = .2, fill = "#E9EEEE") +
  labs(title = "Original Price Distribution", x = "Price (USD)", y = "Density") +
  theme_minimalist()

p2 <- ggplot(translated_product_data, aes(x = price_winsorized)) +
  geom_histogram(aes(y = ..density..), bins = 30, fill = "#E9EEEE", color = "gray0") +
  geom_density(alpha = .2, fill = "#E9EEEE") +
  labs(title = "Winsorised Price Distribution", x = "Price (USD)", y = "Density") +
  theme_minimalist()


# Visualise a side-by-side using the `grid.arrange()` function.
grid.arrange(p1, p2, ncol = 2)


# Render a boxplot to compare price distributions across product types.
ggplot(translated_product_data, aes(x = type, y = price_winsorized)) +
  geom_boxplot(alpha=0.2, fill = "#E9EEEE") +
  labs(title = "Price Distribution by Product Type", x = "Product Type", y = "Price (USD)") +
  theme_minimalist()




# Remove outliers from the `translated_product_data` data frame.
translated_product_data <- translated_product_data[!outliers, ]


# Enhance the data with additional computed columns to facilitate more profound and in-depth analyses.
translated_product_data$thumbnail_url <- paste0("https://www.aliexpress.com/item/", translated_product_data$thumbnail)


# Get some idea of the resulting `translated_product_data` data frame.
View(translated_product_data)
summary(translated_product_data)
colnames(translated_product_data)
str(translated_product_data)



# ------------------------------------------------------------------------------
# Data Analyses
# ------------------------------------------------------------------------------

# Perform a frequency analysis for the types of listings on the AliExpress website.
translated_product_data %>%
  group_by(type) %>%
  summarize(count = n()) %>%
  mutate(percentage = count / nrow(translated_product_data) * 100)

# Perform a correlation analysis on the numeric variables.
numeric_data <- translated_product_data %>%
  select_if(is.numeric)

cor(numeric_data, use = "complete.obs")

# Perform a price range analysis.
summary(translated_product_data$price_usd)


# Perform an analysis of "Sold" information.
translated_product_data <- translated_product_data %>%
  mutate(trade_numeric = as.numeric(gsub("[^0-9]", "", trade)))

summary(translated_product_data$trade_numeric)







# ------------------------------------------------------------------------------
# Advanced Data Analysis and Visualisation
# ------------------------------------------------------------------------------

# Analyse the dataset more advanced and sophisticatedly, thereby rendering visualisations and performing more advanced statistical analyses to uncover new insights.

# Examine the product type distribution to understand the range of offerings.
product_type_distribution <- translated_product_data %>% 
  mutate(type = fct_infreq(type)) %>% 
  ggplot(aes(x = type)) + 
  geom_bar(fill = "#E9EEEE", color = "#383535") +
  labs(title = "Product Type Distribution", x = "Product Type", y = "Frequency") +
  theme_minimalist()
product_type_distribution


# Analyse the price distribution to identify pricing strategies and ranges.
price_distribution_plot <- ggplot(translated_product_data, aes(x = price_usd)) +
  geom_histogram(bins = 30, fill = "#E9EEEE", color = "#383535") +
  scale_x_continuous(labels = scales::dollar_format()) +
  labs(title = "Distribution of Prices in USD", x = "Price (USD)", y = "Number of Products") +
  theme_minimalist()
price_distribution_plot


# Explore the relationship between `trade_numeric` and `price_usd` to see if higher trade correlates with pricing.
trade_price_correlation <- ggplot(translated_product_data, aes(x = trade_numeric, y = price_usd)) +
  geom_point(aes(color = type), alpha = 0.6) +
  geom_smooth(method = "lm", se = FALSE, color = "gray30") +
  labs(title = "The Correlation Between Trade Volume and Price", x = "Trade Volume", y = "Price (USD)") +
  theme_minimal() +
  scale_color_manual(values = c("#E9EEEE", "#383535", "#73787C"))
trade_price_correlation


# Identify the top 10 stores by product count to pinpoint major sellers and their average pricing.
top_stores_by_product_count <- translated_product_data %>%
  group_by(store_name) %>%
  summarise(Total_Products = n(), Average_Price_USD = mean(price_usd, na.rm = TRUE)) %>%
  top_n(10, Total_Products) %>%
  arrange(desc(Total_Products))
print("Top 10 Stores by Product Count")
print(top_stores_by_product_count)


# Render the Store Performance Visualisation.
# Visualise the store performance to highlight top performers and their pricing strategies.
top_stores_visualisation <- ggplot(top_stores_by_product_count, aes(x = reorder(store_name, Total_Products), y = Total_Products, fill = Average_Price_USD)) +
  geom_col(color = "gray0") +
  scale_fill_gradient(low = "#E9EEEE", high = "#383535") +
  coord_flip() +
  labs(title = "Top 10 Stores by Product Count and Average Pricing", x = "Store Name", y = "Total Products") +
  theme_minimalist()
top_stores_visualisation


# Plot the Price Distribution by Product Type.
translated_product_data %>%
  ggplot(aes(x = price_usd, fill = type)) +
  geom_histogram(bins = 30, alpha = 0.8, color = "#383535", fill = "#E9EEEE") +
  scale_x_continuous(labels = scales::dollar_format()) +
  scale_fill_grey(start = 0.95, end = 0.75) +
  labs(title = "Distribution of Prices by Product Type", x = "Price (USD)", y = "Number of Products") +
  theme_minimalist()


# Render a scatter plot contrasting the `price_usd` data column with the `trade` data column.
translated_product_data %>%
  ggplot(aes(x = trade_numeric, y = price_usd)) +
  geom_point(alpha = 0.6, fill = "#E9EEEE") +
  labs(title = "Price vs. Trade Volume", x = "Trade Volume", y = "Price (USD)") +
  theme_minimalist()


# Box Plots of Price by Store (Top 10).
top_stores <- translated_product_data %>%
  group_by(store_name) %>%
  summarize(count = n()) %>%
  arrange(desc(count)) %>%
  head(10)

translated_product_data %>%
  filter(store_name %in% top_stores$store_name) %>%
  ggplot(aes(x = store_name, y = price_usd, fill = store_name)) +
  geom_boxplot(fill = "#E9EEEE", color = "#383535") +
  coord_flip() +
  labs(title = "Price Distribution by Top 10 Stores", x = "Store Name", y = "Price (USD)") +
  theme_minimalist() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


# Bar Chart of Product Counts by Store (Top 10)
translated_product_data %>%
  group_by(store_name) %>%
  summarize(count = n()) %>%
  arrange(desc(count)) %>%
  head(10) %>%
  ggplot(aes(x = reorder(store_name, count), y = count)) +
  geom_col(fill = "#E9EEEE", color = "#383535") +
  labs(title = "Top 10 Stores by Product Count", x = "Store Name", y = "Number of Products") +
  theme_minimalist() +
  coord_flip()





# ------------------------------------------------------------------------------

# Save the cleaned dataset.
write_csv(translated_product_data, "data/Cleaned_AliExpress_Consumer_Electronics_Data.csv")
write_xlsx(translated_product_data, "data/Cleaned_AliExpress_Consumer_Electronics_Data.xlsx")



