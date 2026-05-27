CREATE DATABASE atliq_supply_chain;

CREATE TABLE dim_customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    city VARCHAR(50)
);

-- Products
CREATE TABLE dim_products (
    product_name VARCHAR(100),
    product_id BIGINT PRIMARY KEY,
    category VARCHAR(50)
);

-- Targets
CREATE TABLE dim_targets_orders (
    customer_id INT,
    ontime_target NUMERIC,
    infull_target NUMERIC,
    otif_target NUMERIC
);

-- Date dimension
CREATE TABLE dim_date (
    date DATE,
    mmm_yy VARCHAR(20),
    week_no VARCHAR(10)
);

-- Fact: order aggregate
CREATE TABLE fact_orders_aggregate (
    order_id VARCHAR(20),
    customer_id INT,
    order_placement_date DATE,
    on_time INT,
    in_full INT,
    otif INT
);

-- Fact: order lines
CREATE TABLE fact_order_lines (
    order_id VARCHAR(20),
    order_placement_date DATE,
    customer_id INT,
    product_id BIGINT,
    order_qty INT,
    agreed_delivery_date DATE,
    actual_delivery_date DATE,
    delivery_qty INT,
    in_full INT,
    on_time INT,
    on_time_in_full INT
);

