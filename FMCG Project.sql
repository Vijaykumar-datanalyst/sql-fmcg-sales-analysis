CREATE DATABASE fmcg;
USE fmcg;

CREATE TABLE Products_Master (
Product_id INT,
Product_name VARCHAR(100),
Category  VARCHAR(100),
Sub_category  VARCHAR(100),
Brand  VARCHAR(100),
Pack_size  VARCHAR(100),
Mrp INT,
Cost_Price INT,
Launch_date  VARCHAR(100),
Sku  VARCHAR(100),
GST_pct DECIMAL(8,2),
 PRIMARY KEY (product_id),
  INDEX idx_products_category (category),
  INDEX idx_products_sku (sku)
); 

-- fact table
CREATE TABLE Sales_Transactions (
sale_id INT NOT NULL,
sale_date VARCHAR(100),
product_id INT,
store_id INT,
quantity INT,
unit_price DECIMAL(8,2),
discount_pct DECIMAL(8,6),
total_amount DECIMAL(8,2),
invoice_no VARCHAR(50),
payment_type VARCHAR(10),
customer_id INT,
sale_timestamp VARCHAR(50),
promo_id INT,
gst_pct DECIMAL(5,2),
gst_amount DECIMAL(8,2),
unit_cost DECIMAL(9,6),
cost_total DECIMAL(9,6),
profit DECIMAL(8,2),
distributor_id INT,
batch_no VARCHAR(20),
mfg_date VARCHAR(50),
exp_date VARCHAR(50),
sales_rep_id INT,
return_flag VARCHAR(10),
channel_type VARCHAR(50),
PRIMARY KEY (sale_id),
  INDEX idx_sales_date (sale_date),
  INDEX idx_sales_product (product_id),
  INDEX idx_sales_store_date (store_id, sale_date),
  INDEX idx_sales_invoice (invoice_no),
  INDEX idx_sales_rep (sales_rep_id)
);


CREATE TABLE Supplier_Management (
supplier_id INT NOT NULL,
supplier_name VARCHAR(100),
contact_person VARCHAR(100),
phone VARCHAR(50),
email VARCHAR(255),
country VARCHAR(20),
lead_time_days INT,
on_time_delivery_pct DECIMAL(8,2),
quality_rating DECIMAL(8,2),
last_delivery_date VARCHAR(100),
preferred VARCHAR(20),
 PRIMARY KEY (supplier_id),
  INDEX idx_supplier_country (country)
);


CREATE TABLE Store_Master (
store_id INT NOT NULL,
store_name VARCHAR(100),
city VARCHAR(100),
state VARCHAR(100),
store_type VARCHAR(100),
area_sqft INT,
opening_date VARCHAR(100),
owner VARCHAR(200),
channel VARCHAR(50),
latitude decimal(9,6),
longitude DECIMAL(9,6),
PRIMARY KEY (store_id),
  INDEX idx_store_city (city),
  INDEX idx_store_region (channel)
);

CREATE TABLE Customer_Master (
customer_id INT NOT NULL,
customer_name VARCHAR(100),
city VARCHAR(100),
age INT,
gender CHAR(2),
membership_type VARCHAR(50),
join_date VARCHAR(100),
total_purchases INT,
email VARCHAR(100),
phone VARCHAR(50),
loyalty_points INT,
PRIMARY KEY (customer_id),
  INDEX idx_customer_city (city),
  INDEX idx_customer_membership (membership_type)
);


CREATE TABLE Promotions (
promo_id INT NOT NULL,
promo_name VARCHAR(100),
product_id INT,
start_date VARCHAR(100),
end_date VARCHAR(100),
discount_pct DECIMAL(5,2),
promo_cost DECIMAL(12,6),
incremental_sales INT,
channel VARCHAR(100),
target_segment VARCHAR(100),
PRIMARY KEY (promo_id),
  INDEX idx_promo_product (product_id),
  INDEX idx_promo_dates (start_date, end_date)
);


CREATE TABLE Sales_Reps (
sales_rep_id INT NOT NULL,
rep_name VARCHAR(100),
region VARCHAR(20),
phone VARCHAR(20),
email VARCHAR(200),
PRIMARY KEY (sales_rep_id),
  INDEX idx_rep_region (region)
);

-- 1. Total Sales Revenue
SELECT SUM(total_amount) AS total_sales_revenue
FROM sales_transactions;

-- 2. Total Quantity Sold ?
SELECT SUM(quantity) AS total_quantity_sold
FROM sales_transactions;

-- 3. Gross Profit
SELECT SUM(profit) AS total_gross_profit
FROM sales_transactions;

-- 4. Gross Margin %
SELECT 
    (SUM(profit) / SUM(total_amount)) * 100 AS gross_margin_percentage
FROM sales_transactions;

-- 5. Average Selling Price (ASP)

SELECT 
    (SUM(total_amount) / SUM(quantity)) AS average_selling_price
FROM sales_transactions;

-- 6.Average Unit Cost
SELECT 
    SUM(unit_cost * quantity) / SUM(quantity) AS average_unit_cost
FROM sales_transactions;

-- 7. SKU Contribution %
SELECT 
    product_id,
    SUM(total_amount) AS sku_revenue,
    (SUM(total_amount) / (SELECT SUM(total_amount) FROM sales_transactions)) * 100 
        AS sku_contribution_pct
FROM sales_transactions
GROUP BY product_id
ORDER BY sku_contribution_pct DESC;


-- 8.Category Contribution to Sales
SELECT 
    p.category,
    SUM(s.total_amount) AS category_sales,
    (SUM(s.total_amount) / (SELECT SUM(total_amount) FROM sales_transactions)) * 100 
        AS category_contribution_pct
FROM sales_transactions s
JOIN products_master p
    ON s.product_id = p.product_id
GROUP BY p.category
ORDER BY category_sales DESC;

-- 9. Store-Level Sales Performance
SELECT 
    s.store_id,
    st.store_name,
    st.city,
    st.state,
    SUM(s.total_amount) AS total_sales,
    SUM(s.quantity) AS total_quantity,
    COUNT(DISTINCT s.invoice_no) AS total_invoices
FROM sales_transactions s
JOIN store_master st 
    ON s.store_id = st.store_id
GROUP BY s.store_id, st.store_name, st.city, st.state
ORDER BY total_sales DESC;


-- 10. Customer Basket Size
SELECT 
    SUM(quantity) / COUNT(DISTINCT invoice_no) AS customer_basket_size
FROM sales_transactions;

-- 11.Customer Average Ticket Size
SELECT 
    SUM(total_amount) / COUNT(DISTINCT invoice_no) AS average_ticket_size
FROM sales_transactions;


-- 12.Repeat Customer %
SELECT 
    (COUNT(*) / (SELECT COUNT(DISTINCT customer_id) FROM sales_transactions)) * 100 
        AS repeat_customer_percentage
FROM (
    SELECT customer_id
    FROM sales_transactions
    GROUP BY customer_id
    HAVING COUNT(DISTINCT invoice_no) > 1
) AS repeat_customers;


-- 13.New vs Returning Customers
WITH first_purchase AS (
    SELECT 
        customer_id,
        MIN(sale_date) AS first_sale
    FROM sales_transactions
    GROUP BY customer_id
),
tagged AS (
    SELECT 
        s.customer_id,
        CASE 
            WHEN s.sale_date = f.first_sale THEN 'New Customer'
            ELSE 'Returning Customer'
        END AS customer_type
    FROM sales_transactions s
    JOIN first_purchase f 
        ON s.customer_id = f.customer_id
)
SELECT 
    customer_type,
    COUNT(DISTINCT customer_id) AS customer_count
FROM tagged
GROUP BY customer_type;

-- 14. Top 10 Products by Revenue
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    SUM(s.total_amount) AS total_revenue
FROM sales_transactions s
JOIN products_master p 
    ON s.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC
LIMIT 10;

-- 15.Top 10 Fast-Moving Items (By Quantity)
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    SUM(s.quantity) AS total_units_sold
FROM sales_transactions s
JOIN products_master p
    ON s.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_units_sold DESC
LIMIT 10;

-- 16. Inventory Stock Coverage (Days of Stock)

CREATE TABLE inventory_master (
    product_id INT PRIMARY KEY,
    opening_stock INT,
    current_stock INT,
    last_updated DATE
);

ALTER TABLE inventory_master
ADD CONSTRAINT fk_inventory_product
FOREIGN KEY (product_id) REFERENCES products_master(product_id);

INSERT INTO inventory_master (product_id, opening_stock, current_stock, last_updated) VALUES
(101, 1000, 350, '2024-01-31'),
(102, 800, 120, '2024-01-31'),
(103, 500, 75, '2024-01-31'),
(104, 1200, 600, '2024-01-31');

select * from inventory_master;

WITH avg_daily_sales AS (
    SELECT 
        product_id,
        SUM(quantity) / COUNT(DISTINCT sale_date) AS avg_daily_usage
    FROM sales_transactions
    GROUP BY product_id
)
SELECT 
    p.product_id,
    p.product_name,
    i.current_stock,
    a.avg_daily_usage,
    ROUND(i.current_stock / a.avg_daily_usage, 2) AS days_of_stock
FROM inventory_master i
JOIN avg_daily_sales a ON i.product_id = a.product_id
JOIN products_master p ON p.product_id = i.product_id
ORDER BY days_of_stock ASC;


-- 17.Stockout Risk Flag

ALTER TABLE inventory_master
ADD COLUMN avg_daily_usage DECIMAL(12,4) DEFAULT NULL,
ADD COLUMN days_of_stock DECIMAL(12,2) DEFAULT NULL,
ADD COLUMN stockout_risk ENUM('High','Medium','Low') DEFAULT 'Low',
ADD COLUMN risk_score INT DEFAULT 0; 

-- Tune these thresholds if you want
SET @high_threshold := 7;    -- days -> High risk if < 7
SET @medium_threshold := 14; -- days -> Medium if >=7 and <14

WITH daily_stats AS (
  SELECT
    product_id,
    SUM(quantity) AS total_qty,
    COUNT(DISTINCT sale_date) AS active_days,
    -- use number of days in range if you prefer full-period average
    CASE WHEN COUNT(DISTINCT sale_date) = 0 THEN 0
         ELSE SUM(quantity) / COUNT(DISTINCT sale_date)
    END AS avg_daily_usage
  FROM sales_transactions
  GROUP BY product_id
)

UPDATE inventory_master i
LEFT JOIN daily_stats d ON i.product_id = d.product_id
SET
  i.avg_daily_usage = COALESCE(d.avg_daily_usage, 0),
  i.days_of_stock = CASE
      WHEN COALESCE(d.avg_daily_usage,0) = 0 THEN 99999
      ELSE ROUND(i.current_stock / d.avg_daily_usage, 2)
    END,
  i.stockout_risk = CASE
      WHEN COALESCE(d.avg_daily_usage,0) = 0 THEN 'Low' 
      WHEN (i.current_stock / d.avg_daily_usage) < @high_threshold THEN 'High'
      WHEN (i.current_stock / d.avg_daily_usage) < @medium_threshold THEN 'Medium'
      ELSE 'Low'
    END,
  i.risk_score = CASE
      WHEN COALESCE(d.avg_daily_usage,0) = 0 THEN 0
      ELSE GREATEST(0, CEIL((@medium_threshold - (i.current_stock / d.avg_daily_usage)) * 10))
    END;

CREATE OR REPLACE VIEW stockout_risk_view AS
SELECT
  i.product_id,
  p.product_name,
  p.category,
  i.current_stock,
  i.avg_daily_usage,
  i.days_of_stock,
  i.stockout_risk,
  i.risk_score,
  p.sku,
  COALESCE(s.supplier_name,'-') AS supplier_name,
  i.last_updated
FROM inventory_master i
LEFT JOIN products_master p ON i.product_id = p.product_id
LEFT JOIN supplier_management s ON p.supplier_id = s.supplier_id;



SELECT product_id, product_name, current_stock, days_of_stock, stockout_risk
FROM stockout_risk_view
WHERE stockout_risk = 'High'
ORDER BY days_of_stock ASC
LIMIT 100;


-- Preview sample to make sure it looks right
SELECT Product_id, Mrp, Cost_Price, Launch_date FROM Products_Master LIMIT 10;


SELECT COUNT(*) FROM Products_Master;
SELECT product_id, launch_date FROM products_master LIMIT 10;
SELECT Product_id, Mrp, Cost_Price, Launch_date FROM Products_Master LIMIT 10;


-- ORDER & SALES KPIs
SELECT COUNT(DISTINCT invoice_no) AS total_orders
FROM Sales_Transactions;

-- 2. INVENTORY & STOCK KPIs
SELECT SUM(current_stock) AS stock_on_hand
FROM inventory_master;

-- . Procurement & Cost KPIs
SELECT SUM(unit_cost * quantity) AS procurement_cost
FROM sales_transactions;

-- Average Order Value (AOV)
SELECT 
    SUM(unit_price * quantity) / COUNT(DISTINCT invoice_no) AS avg_order_value
FROM sales_transactions;

 
 

SET GLOBAL LOCAL_INFILE = ON;
 
LOAD DATA LOCAL INFILE 'D://Sales_Reps.csv'
INTO TABLE Sales_Reps
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;



