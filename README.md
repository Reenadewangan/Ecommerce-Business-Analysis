# E-commerce Business Analysis | Python & SQL

## Project Overview

An end-to-end E-commerce Business Analysis project using Python and SQL to analyze sales performance, customer purchasing behavior, product category performance, and delivery efficiency.

The project uses the Brazilian E-Commerce Public Dataset by Olist to derive actionable business insights through data analysis and SQL queries.

## Tools & Technologies

- **Programming:** Python
- **Libraries:** Pandas, NumPy, Matplotlib, Seaborn
- **Database:** SQLite
- **Query Language:** SQL
- **Environment:** Google Colab

## Project Workflow

### 1. Data Analysis using Python

- Loaded and explored the Olist e-commerce dataset.
- Performed data cleaning and preprocessing.
- Conducted Exploratory Data Analysis (EDA).
- Analyzed revenue and sales trends.
- Investigated customer purchasing behavior.
- Examined product category performance and delivery patterns.

### 2. SQL Business Analysis

Performed business-focused SQL analysis, including:

- Revenue and order analysis.
- Customer purchasing behavior.
- Top-performing product categories.
- Customer segmentation based on total spending.
- Top customers by revenue contribution.
- Revenue distribution across customer segments.
- Order delivery performance.

## Key Business Insights

### Sales Performance

- Total product revenue: **BRL 13.59 million**.
- Total orders analyzed: **99,441**.
- Successfully delivered orders: **96,478**.
- Average Order Value (AOV): **BRL 136.68**.

### Customer Segmentation

Segmented customers based on total spending:

| Customer Segment | Customers | Revenue Contribution |
|---|---:|---:|
| High Value | 1,149 | 11.80% |
| Medium Value | 12,517 | 34.35% |
| Low Value | 79,691 | 53.85% |

Segmentation criteria:
- High Value: Spending above BRL 1,000.
- Medium Value: Spending between BRL 250 and BRL 1,000.
- Low Value: Spending below BRL 250.

**Key finding:** High-value customers represent approximately 1.23% of segmented customers but contribute 11.80% of total segment revenue.

### Top Product Categories

Top categories by product revenue:

| Product Category | Revenue (BRL) |
|---|---:|
| Beauty & Health | 1,258,681.34 |
| Watches & Gifts | 1,205,005.68 |
| Bed, Bath & Table | 1,036,988.68 |
| Sports & Leisure | 988,048.97 |
| Computers & Accessories | 911,954.32 |

### Delivery Performance

- On-time or early deliveries: **91.89%**.
- Late deliveries: **8.11%**.
- Late deliveries analyzed: **7,826 orders**.

## Repository Structure

```text
Ecommerce-Business-Analysis/
│
├── ecommerce_analysis.ipynb
├── ecommerce_queries.sql
└── README.md
```

## Dataset

Brazilian E-Commerce Public Dataset by Olist.

Source: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

## Author

**Reena Dewangan**

B.Tech, Electrical Engineering  
National Institute of Technology, Raipur

GitHub: https://github.com/Reenadewangan
