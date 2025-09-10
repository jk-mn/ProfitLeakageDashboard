import pandas as pd
import numpy as np
from datetime import datetime
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import classification_report

# Load the dataset
df = pd.read_csv('OnlineRetail.csv', encoding='ISO-8859-1')

# --- Step 1: Initial Data Inspection ---
print("Initial Data Shape:", df.shape)
print("\nMissing Values:\n", df.isnull().sum())
print("\nData Types:\n", df.dtypes)

# --- Step 2: Types & Cleaning ---
df['CustomerID'] = df['CustomerID'].astype(str).str.strip()
df['StockCode'] = df['StockCode'].astype(str).str.strip()
df['InvoiceNo'] = df['InvoiceNo'].astype(str).str.strip()

# Drop rows with missing or 'nan' CustomerID
df = df[df['CustomerID'] != 'nan'].dropna(subset=['CustomerID'])

# Fill missing Description with 'Unknown'
df['Description'] = df['Description'].fillna('Unknown')

# --- Step 3: Remove Duplicates ---
df = df.drop_duplicates()
print("\nShape after removing duplicates:", df.shape)

# --- Step 4: Data Type Corrections ---
df['InvoiceDate'] = pd.to_datetime(df['InvoiceDate'], errors='coerce')
df['Quantity'] = pd.to_numeric(df['Quantity'], errors='coerce')
df['UnitPrice'] = pd.to_numeric(df['UnitPrice'], errors='coerce')
df = df.dropna(subset=['Quantity', 'UnitPrice'])

# --- Step 5: Handle Outliers & Zeroes ---
df = df[df['UnitPrice'] > 0]

# Separate sales and returns
df_sales = df[(df['Quantity'] > 0) & (~df['InvoiceNo'].str.startswith('C'))].copy()
df_returns = df[(df['Quantity'] < 0) | (df['InvoiceNo'].str.startswith('C'))].copy()
print("\nShape after separating sales:", df_sales.shape)
print("Shape after separating returns:", df_returns.shape)

# Remove outliers in UnitPrice using IQR
q1 = df_sales['UnitPrice'].quantile(0.25)
q3 = df_sales['UnitPrice'].quantile(0.75)
iqr = q3 - q1
price_lower = q1 - 1.5 * iqr
price_upper = q3 + 1.5 * iqr
df_sales = df_sales[(df_sales['UnitPrice'] >= price_lower) & (df_sales['UnitPrice'] <= price_upper)]
print("\nShape after outlier removal (sales):", df_sales.shape)

# Deduplicate
df_sales = df_sales.drop_duplicates(subset=['InvoiceNo', 'StockCode']).reset_index(drop=True)
df_returns = df_returns.drop_duplicates(subset=['InvoiceNo', 'StockCode']).reset_index(drop=True)
print("\nShape after deduplicating sales:", df_sales.shape)
print("Shape after deduplicating returns:", df_returns.shape)

# --- Step 6: Discount Assignment ---
np.random.seed(42)
invoices = df_sales['InvoiceNo'].unique()
discount_map = {inv: np.random.uniform(0, 0.2) for inv in invoices}
df_sales['Discount'] = df_sales['InvoiceNo'].map(discount_map)

# --- Step 7: Feature Engineering ---
df_sales['NetRevenue'] = df_sales['UnitPrice'] * (1 - df_sales['Discount']) * df_sales['Quantity']
df_sales['CostPrice'] = df_sales['UnitPrice'] * 0.7
df_sales['Cost'] = df_sales['CostPrice'] * df_sales['Quantity']
df_sales['NetProfit'] = df_sales['NetRevenue'] - df_sales['Cost']

df_returns['TotalPrice'] = df_returns['Quantity'] * df_returns['UnitPrice']
df_returns['ReturnFlag'] = 1

# --- Step 8: Quantity-Weighted Return Rate ---
sales_qty = df_sales.groupby('StockCode')['Quantity'].sum().reset_index(name='SalesQty')
return_qty = df_returns.groupby('StockCode')['Quantity'].sum().abs().reset_index(name='ReturnQty')

return_rate = sales_qty.merge(return_qty, on='StockCode', how='left')
return_rate['ReturnQty'] = return_rate['ReturnQty'].fillna(0).astype(int)
return_rate['SalesQty'] = return_rate['SalesQty'].astype(int)
return_rate['ReturnRate'] = return_rate['ReturnQty'] / (return_rate['SalesQty'] + return_rate['ReturnQty'])
return_rate['ReturnRate'] = return_rate['ReturnRate'].fillna(0)

df_sales = df_sales.merge(return_rate[['StockCode', 'ReturnRate']], on='StockCode', how='left')
df_sales['ReturnRate'] = df_sales['ReturnRate'].fillna(0)

# --- Step 9: Customers & Products ---
customers = df_sales[['CustomerID', 'Country']].drop_duplicates(subset=['CustomerID']).reset_index(drop=True)
customers['FakeCity'] = np.random.choice(['CityA', 'CityB', 'CityC'], size=len(customers))
customers['Segment'] = np.random.choice(['Small', 'Medium', 'Large'], size=len(customers))
print("\nShape of customers table:", customers.shape)

products = df_sales[['StockCode', 'Description', 'UnitPrice']].drop_duplicates(subset=['StockCode']).reset_index(drop=True)
products['Category'] = np.random.choice(['Electronics', 'Clothing', 'Home', 'Other'], size=len(products))
print("Shape of products table:", products.shape)

df_returns = df_returns[df_returns['StockCode'].isin(products['StockCode']) & df_returns['CustomerID'].isin(customers['CustomerID'])].reset_index(drop=True)
print("Shape of returns after filtering:", df_returns.shape)

discounts = df_sales[['InvoiceNo', 'StockCode', 'Discount']].drop_duplicates(subset=['InvoiceNo', 'StockCode']).reset_index(drop=True)
discounts = discounts[discounts['StockCode'].isin(products['StockCode'])]
print("Shape of discounts table:", discounts.shape)

# --- Step 10: Aggregate ML Features ---
ml_data = df_sales.groupby('StockCode').agg({
    'Discount': 'mean',
    'ReturnRate': 'mean',
    'Quantity': 'sum',
    'NetProfit': 'sum',
    'NetRevenue': 'sum'
}).reset_index()

ml_data = ml_data[ml_data['StockCode'].isin(products['StockCode'])]
ml_data['HighReturnRisk'] = (ml_data['ReturnRate'] > 0.5).astype(int)
ml_data.to_csv('sku_return_risk.csv', index=False)
print("Shape of sku_return_risk table:", ml_data.shape)

# --- Step 11: Net View ---
net_view_sales = df_sales[['InvoiceNo', 'StockCode', 'Quantity', 'NetRevenue', 'NetProfit', 'ReturnRate']].copy()
net_view_sales['Source'] = 'Sales'
net_view_sales['ReturnRate'] = net_view_sales['ReturnRate'].astype(float)

net_view_returns = df_returns[['InvoiceNo', 'StockCode', 'Quantity', 'TotalPrice', 'ReturnFlag']].copy()
net_view_returns['NetRevenue'] = net_view_returns['TotalPrice']
net_view_returns['NetProfit'] = net_view_returns['TotalPrice']
net_view_returns['ReturnRate'] = net_view_returns['ReturnFlag'].astype(float)
net_view_returns['Source'] = 'Returns'
net_view_returns = net_view_returns[['InvoiceNo', 'StockCode', 'Quantity', 'NetRevenue', 'NetProfit', 'ReturnRate', 'Source']]

net_view_sales = net_view_sales.drop_duplicates(subset=['InvoiceNo', 'StockCode', 'Source']).reset_index(drop=True)
net_view_returns = net_view_returns.drop_duplicates(subset=['InvoiceNo', 'StockCode', 'Source']).reset_index(drop=True)

net_view = pd.concat([net_view_sales, net_view_returns], ignore_index=True)
net_view.to_csv('net_view.csv', index=False)
print("Shape of net_view table:", net_view.shape)

# Save tables
df_sales.to_csv('cleaned_sales.csv', index=False)
df_returns.to_csv('cleaned_returns.csv', index=False)
customers.to_csv('customers.csv', index=False)
products.to_csv('products.csv', index=False)
discounts.to_csv('discounts.csv', index=False)
return_rate.to_csv('return_rate.csv', index=False)

# --- Step 12: ML Model for Return Risk ---
sku_data = pd.read_csv('sku_return_risk.csv')
X = sku_data[['Discount', 'Quantity', 'NetProfit', 'NetRevenue']]
y = sku_data['HighReturnRisk']

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

model = LogisticRegression(random_state=42, class_weight='balanced')
model.fit(X_train_scaled, y_train)

probs = model.predict_proba(X_test_scaled)[:, 1]

test_indices = X_test.index
output = sku_data.loc[test_indices, ['StockCode', 'ReturnRate']].copy()
output['ReturnRiskProbability'] = probs
output = output[output['StockCode'].isin(products['StockCode'])]
output = output.sort_values(by='ReturnRiskProbability', ascending=False)
output.to_csv('sku_return_probs.csv', index=False)
print("\nShape of sku_return_probs table:", output.shape)

print("\nClassification Report:")
print(classification_report(y_test, model.predict(X_test_scaled)))

print("\nData cleaning complete! Files saved:")
print("- cleaned_sales.csv")
print("- cleaned_returns.csv")
print("- customers.csv")
print("- products.csv")
print("- discounts.csv")
print("- return_rate.csv")
print("- net_view.csv")
print("- sku_return_risk.csv")
print("- sku_return_probs.csv")
