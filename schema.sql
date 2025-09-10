-- Customers table
CREATE TABLE Customers (
    CustomerID TEXT PRIMARY KEY,
    Country TEXT NOT NULL,
    FakeCity TEXT,
    Segment TEXT
);

-- Products table
CREATE TABLE Products (
    StockCode TEXT PRIMARY KEY,
    Description TEXT,
    UnitPrice NUMERIC(10, 2),
    Category TEXT
);

-- Discounts table
CREATE TABLE Discounts (
    InvoiceNo TEXT,
    StockCode TEXT,
    Discount NUMERIC(5, 4),
    PRIMARY KEY (InvoiceNo, StockCode),
    FOREIGN KEY (StockCode) REFERENCES Products(StockCode)
);

-- Sales table
CREATE TABLE Sales (
    InvoiceNo TEXT,
    StockCode TEXT,
    Description TEXT,
    Quantity INTEGER NOT NULL,
    InvoiceDate TIMESTAMP,
    UnitPrice NUMERIC(10, 2),
    CustomerID TEXT,
    Country TEXT,
    Discount NUMERIC(5, 4),
    NetRevenue NUMERIC(12, 2),
    CostPrice NUMERIC(10, 2),
    Cost NUMERIC(12, 2),
    NetProfit NUMERIC(12, 2),
    ReturnRate NUMERIC(5, 4),
    PRIMARY KEY (InvoiceNo, StockCode),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (StockCode) REFERENCES Products(StockCode)
);

-- Returns table
CREATE TABLE Returns (
    InvoiceNo TEXT,
    StockCode TEXT,
    Description TEXT,
    Quantity INTEGER NOT NULL,
    InvoiceDate TIMESTAMP,
    UnitPrice NUMERIC(10, 2),
    CustomerID TEXT,
    Country TEXT,
    TotalPrice NUMERIC(12, 2),
    ReturnFlag INTEGER CHECK (ReturnFlag = 1),
    PRIMARY KEY (InvoiceNo, StockCode),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (StockCode) REFERENCES Products(StockCode)
);

-- ReturnRate table
CREATE TABLE ReturnRate (
    StockCode TEXT PRIMARY KEY,
    SalesQty INTEGER,
    ReturnQty INTEGER,
    ReturnRate NUMERIC(5, 4),
    FOREIGN KEY (StockCode) REFERENCES Products(StockCode)
);

-- NetView table
CREATE TABLE NetView (
    InvoiceNo TEXT,
    StockCode TEXT,
    Quantity INTEGER NOT NULL,
    NetRevenue NUMERIC(12, 2),
    NetProfit NUMERIC(12, 2),
    ReturnRate NUMERIC(5, 4),
    Source TEXT NOT NULL CHECK (Source IN ('Sales', 'Returns')),
    PRIMARY KEY (InvoiceNo, StockCode, Source),
    FOREIGN KEY (StockCode) REFERENCES Products(StockCode)
);

-- SKUReturnRisk table
CREATE TABLE SKUReturnRisk (
    StockCode TEXT PRIMARY KEY,
    Discount NUMERIC(5, 4),
    ReturnRate NUMERIC(5, 4),
    Quantity INTEGER,
    NetProfit NUMERIC(12, 2),
    NetRevenue NUMERIC(12, 2),
    HighReturnRisk INTEGER CHECK (HighReturnRisk IN (0, 1)),
    FOREIGN KEY (StockCode) REFERENCES Products(StockCode)
);

-- SKUReturnProbs table
CREATE TABLE SKUReturnProbs (
    StockCode TEXT PRIMARY KEY,
    ReturnRate NUMERIC(5, 4),
    ReturnRiskProbability NUMERIC(5, 4),
    FOREIGN KEY (StockCode) REFERENCES Products(StockCode)
);


COPY (
    SELECT 
        s.StockCode,
        p.Description,
        p.Category,
        SUM(s.NetProfit) AS TotalNetProfit,
        SUM(s.NetRevenue) AS TotalNetRevenue,
        AVG(s.ReturnRate) AS AvgReturnRate,
        AVG(s.Discount) AS AvgDiscount,
        SUM(s.NetProfit) * AVG(s.ReturnRate) AS ProfitLeakage
    FROM Sales s
    JOIN Products p ON s.StockCode = p.StockCode
    GROUP BY s.StockCode, p.Description, p.Category
    ORDER BY ProfitLeakage DESC
    LIMIT 10
) TO 'D:\JK\Beast\DA\project two - DA\pythonProject\profit_leakage_skus.csv' DELIMITER ',' CSV HEADER;

CREATE MATERIALIZED VIEW TopProfitLeakSKUs AS
SELECT 
    s.StockCode,
    p.Description,
    p.Category,
    SUM(s.NetProfit) AS TotalNetProfit,
    SUM(s.NetRevenue) AS TotalNetRevenue,
    AVG(s.ReturnRate) AS AvgReturnRate,
    AVG(s.Discount) AS AvgDiscount,
    SUM(s.NetProfit) * AVG(s.ReturnRate) AS ProfitLeakage
FROM Sales s
JOIN Products p ON s.StockCode = p.StockCode
GROUP BY s.StockCode, p.Description, p.Category
ORDER BY ProfitLeakage DESC
LIMIT 10;

COPY (
    SELECT 
        c.Country,
        COUNT(DISTINCT s.InvoiceNo) AS TransactionCount,
        AVG(s.Discount) AS AvgDiscount,
        SUM(s.NetProfit) / SUM(s.NetRevenue) AS ProfitMargin,
        SUM(s.NetRevenue) AS TotalRevenue
    FROM Sales s
    JOIN Customers c ON s.CustomerID = c.CustomerID
    GROUP BY c.Country
    ORDER BY AvgDiscount DESC
) TO 'D:\JK\Beast\DA\project two - DA\pythonProject\country_discount_trends.csv' DELIMITER ',' CSV HEADER;


CREATE MATERIALIZED VIEW CountryDiscountTrends AS
SELECT 
    c.Country,
    COUNT(DISTINCT s.InvoiceNo) AS TransactionCount,
    AVG(s.Discount) AS AvgDiscount,
    SUM(s.NetProfit) / SUM(s.NetRevenue) AS ProfitMargin,
    SUM(s.NetRevenue) AS TotalRevenue
FROM Sales s
JOIN Customers c ON s.CustomerID = c.CustomerID
GROUP BY c.Country
ORDER BY AvgDiscount DESC;

SELECT 
    EXTRACT(QUARTER FROM r.InvoiceDate) AS Quarter,
    p.Category,
    COUNT(r.InvoiceNo) AS ReturnCount,
    SUM(ABS(r.Quantity)) AS TotalReturnQty,
    AVG(s.ReturnRate) AS AvgReturnRate
FROM Returns r
JOIN Products p ON r.StockCode = p.StockCode
LEFT JOIN ReturnRate s ON r.StockCode = s.StockCode
GROUP BY EXTRACT(QUARTER FROM r.InvoiceDate), p.Category
ORDER BY Quarter, AvgReturnRate DESC;

COPY (
    SELECT 
        EXTRACT(QUARTER FROM r.InvoiceDate) AS Quarter,
        p.Category,
        COUNT(r.InvoiceNo) AS ReturnCount,
        SUM(ABS(r.Quantity)) AS TotalReturnQty,
        AVG(s.ReturnRate) AS AvgReturnRate
    FROM Returns r
    JOIN Products p ON r.StockCode = p.StockCode
    LEFT JOIN ReturnRate s ON r.StockCode = s.StockCode
    GROUP BY EXTRACT(QUARTER FROM r.InvoiceDate), p.Category
    ORDER BY Quarter, AvgReturnRate DESC
) TO 'D:\JK\Beast\DA\project two - DA\pythonProject\seasonal_return_spikes.csv' DELIMITER ',' CSV HEADER;

CREATE MATERIALIZED VIEW SeasonalReturnSpikes AS
SELECT 
    EXTRACT(QUARTER FROM r.InvoiceDate) AS Quarter,
    p.Category,
    COUNT(r.InvoiceNo) AS ReturnCount,
    SUM(ABS(r.Quantity)) AS TotalReturnQty,
    AVG(s.ReturnRate) AS AvgReturnRate
FROM Returns r
JOIN Products p ON r.StockCode = p.StockCode
LEFT JOIN ReturnRate s ON r.StockCode = s.StockCode
GROUP BY EXTRACT(QUARTER FROM r.InvoiceDate), p.Category
ORDER BY Quarter, AvgReturnRate DESC;