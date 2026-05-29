# DAX Measures — AtliQ Mart Supply Chain Audit

---

## 📦 Core Delivery KPIs

```dax
OT % = 
DIVIDE(SUM(fact_orders_aggregate[on_time]), COUNT(fact_orders_aggregate[order_id])) * 100

IF % = 
DIVIDE(SUM(fact_orders_aggregate[in_full]), COUNT(fact_orders_aggregate[order_id])) * 100

OTIF % Customer = 
DIVIDE(SUM(fact_orders_aggregate[otif]), COUNTROWS(fact_orders_aggregate)) * 100

OTIF % Product Aware = 
DIVIDE(SUM(fact_order_lines[On Time In Full]), COUNTROWS(fact_order_lines)) * 100

Fill Rate % = 
DIVIDE(SUM(fact_order_lines[delivery_qty]), SUM(fact_order_lines[order_qty])) * 100

Incomplete Rate % = 
DIVIDE(
    COUNTROWS(FILTER(fact_order_lines, fact_order_lines[In Full] = 0)),
    COUNTROWS(fact_order_lines)
) * 100
```

---

## 🎯 Target & Gap Analysis

```dax
OTIF Target = 
AVERAGE(dim_targets_orders[otif_target%])

OTIF Gap = 
[OTIF % Product Aware] - [OTIF Target]

Avg OTIF Gap = 
AVERAGEX(ALL(dim_customers[customer_name]), [OTIF Gap])

Avg OTIF Product = 
AVERAGEX(VALUES(dim_customers[customer_name]), [OTIF % Product Aware])
```

---

## 🔢 Order Volume

```dax
Total Orders = 
COUNT(fact_orders_aggregate[order_id])

Avg Orders = 
AVERAGEX(VALUES(dim_customers[customer_name]), [Total Orders])

Total Undelivered Qty = 
SUM(fact_order_lines[order_qty]) - SUM(fact_order_lines[delivery_qty])
```

---

## ❌ Failure Classification

```dax
Orders On Track = 
COUNTROWS(FILTER(fact_orders_aggregate, fact_orders_aggregate[otif] = 1))

Orders Failed = 
COUNTROWS(FILTER(fact_orders_aggregate, fact_orders_aggregate[otif] = 0))

Only Late = 
COUNTROWS(
    FILTER(fact_orders_aggregate,
        fact_orders_aggregate[on_time] = 0 &&
        fact_orders_aggregate[in_full] = 1
    )
)

Only Incomplete = 
COUNTROWS(
    FILTER(fact_orders_aggregate,
        fact_orders_aggregate[on_time] = 1 &&
        fact_orders_aggregate[in_full] = 0
    )
)

Both Failed = 
COUNTROWS(
    FILTER(fact_orders_aggregate,
        fact_orders_aggregate[on_time] = 0 &&
        fact_orders_aggregate[in_full] = 0
    )
)
```

---

## 🚨 Customer Risk Segmentation

```dax
Customers Below Target = 
COUNTROWS(
    FILTER(VALUES(dim_customers[customer_id]), [OTIF % Product Aware] < [OTIF Target])
)

Customers Below 20% OTIF = 
COUNTROWS(
    FILTER(VALUES(dim_customers[customer_id]), [OTIF % Customer] < 20)
)

Customers Critical Risk = 
CALCULATE(
    DISTINCTCOUNT(dim_customers[customer_name]),
    FILTER(ALL(dim_customers), [OTIF % Product Aware] < [OTIF Target] - 20)
)

Customer Count by Risk = 
VAR RiskSelected = SELECTEDVALUE('Risk Category'[Risk])
RETURN
SWITCH(
    RiskSelected,
    "Healthy",   COUNTROWS(FILTER(VALUES(dim_customers[customer_id]), [OTIF % Customer] >= 30)),
    "High Risk", COUNTROWS(FILTER(VALUES(dim_customers[customer_id]), [OTIF % Customer] < 30))
)
```

---

## 🏷️ Dynamic Labels

```dax
Worst Category = 
CONCATENATEX(
    TOPN(1, VALUES(dim_products[category]), [Total Undelivered Qty], DESC),
    dim_products[category],
    ", "
)
```