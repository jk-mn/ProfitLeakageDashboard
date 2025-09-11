# 📊 Profit Leakage Detection & Revenue Optimization

## 🔍 Project Overview

Companies often lose revenue through **hidden profit leaks**: excessive discounts, frequent returns, and unprofitable customer segments.

This project demonstrates a **real-world analytics pipeline** to:

* Detect and quantify **profit leakage**
* Build **customer profitability models**
* Provide **data-driven recommendations** via Power BI dashboards
* Showcase **SQL + Python + BI integration** in an end-to-end workflow

---

## 🚀 Key Features

✅ **SQL Data Modeling & ETL** – designed a 5-table schema, cleaned & joined datasets, generated KPIs
✅ **Python Analysis & ML** – RFM segmentation, churn risk prediction, discount-return correlation
✅ **Power BI Dashboards** – interactive views for executives (profit leaks, customers, simulations)
✅ **Business Insights** – actionable findings to cut unnecessary losses and optimize revenue

---

## 🛠️ Tech Stack

* **SQL (PostgreSQL)** – schema design, joins, KPIs, ETL
* **Python (Pandas, Scikit-learn, Matplotlib)** – analysis, feature engineering, predictive modeling
* **Power BI** – stakeholder-ready dashboards and what-if simulations

---

## 📂 Repository Structure

```
ProfitLeakageDashboard/
│── data/              # Sample dataset
│── sql/               # SQL schema & queries
│   └── schema.sql
│   └── kpi_queries.sql
│── notebooks/         # Python analysis & ML
│   └── analysis.ipynb
│── dashboards/        # Power BI files & screenshots
│   └── ProfitLeakage.pbix
│   └── screenshots/
│       └── revenue_leakage.png
│       └── customer_segmentation.png
│── README.md          # Project documentation
```

---

## 🧩 Data Model

The dataset was restructured into 5 relational tables:

* **Sales** → transactions with quantity, unit price, invoice date
* **Products** → product descriptions, categories
* **Returns** → return records linked to invoices
* **Customers** → demographics, country, ID
* **Discounts** → discount codes, percentage, validity

---

## 📜 SQL Examples

**Revenue Lost Due to Discounts**

```sql
SELECT 
    d.DiscountCode,
    SUM(s.Quantity * s.UnitPrice * d.DiscountPercent/100) AS discount_loss
FROM Sales s
JOIN Discounts d ON s.DiscountCode = d.DiscountCode
GROUP BY d.DiscountCode
ORDER BY discount_loss DESC;
```

**High-Return Products**

```sql
SELECT 
    p.Description, 
    SUM(r.Quantity) * 1.0 / SUM(s.Quantity) AS return_rate
FROM Sales s
JOIN Returns r ON s.InvoiceNo = r.InvoiceNo AND s.StockCode = r.StockCode
JOIN Products p ON s.StockCode = p.StockCode
GROUP BY p.Description
ORDER BY return_rate DESC
LIMIT 10;
```

---

## 🐍 Python Analysis

**RFM Customer Segmentation**

```python
rfm = sales.groupby('CustomerID').agg({
    'InvoiceDate': lambda x: (sales['InvoiceDate'].max() - x.max()).days,
    'InvoiceNo': 'count',
    'TotalPrice': 'sum'
}).rename(columns={'InvoiceDate':'Recency','InvoiceNo':'Frequency','TotalPrice':'Monetary'})

# Quartile-based scoring
rfm['R'] = pd.qcut(rfm['Recency'], 4, labels=[4,3,2,1])
rfm['F'] = pd.qcut(rfm['Frequency'], 4, labels=[1,2,3,4])
rfm['M'] = pd.qcut(rfm['Monetary'], 4, labels=[1,2,3,4])

rfm['RFM_Score'] = rfm[['R','F','M']].sum(axis=1)
```

---

## 📸 Dashboards

**1. Revenue Leakage Dashboard**

* Revenue lost due to discounts
* Return rates by product category
* Monthly leakage trends

**2. Customer Profitability Dashboard**

* Segmentation by RFM score
* Churn-risk customers highlighted
* CLV distribution

**3. What-If Simulation**

* Slider to adjust discount %
* Forecasted revenue impact shown live

*(Screenshots available in `[/dashboards/screenshots/](https://github.com/jk-mn/ProfitLeakageDashboard/blob/main/SummaryDeck.pdf)`)*

---

## 🧠 Key Insights

* **15% of customers generated \~70% of total profit** → retention of this group is critical.
* **Discounts above 25% increased return rates by 40%** → leading to hidden margin losses.
* **Top 10 products contributed 55% of returns** → inventory & quality control needed.
* **22% of customers were flagged as churn risks** using a predictive model.

---

## 📈 Business Impact

If adopted in a real retail company, this pipeline could:

* Reduce **discount leakage** by \~12% annually
* Improve **retention ROI** by targeting high-value customers
* Save **inventory costs** by early identification of return-prone products
* Enable **real-time decision-making** for executives via BI dashboards

---

## 🧑‍💻 Author

**jk**

* 🎓 Master’s in Finance | ACCA 
* 📊 Portfolio Manager with strong data analytics background
* 🌍 Focus: turning raw data into business impact

---

## 📬 Contact

* GitHub: [jk-mn](https://github.com/jk-mn)


---

👉 This project showcases **end-to-end analytics skills**: data modeling (SQL), statistical & predictive analysis (Python), and storytelling (Power BI).
Perfect for roles in **Data Analytics, Business Intelligence, or Revenue Optimization**.

