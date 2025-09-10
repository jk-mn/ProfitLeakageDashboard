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
