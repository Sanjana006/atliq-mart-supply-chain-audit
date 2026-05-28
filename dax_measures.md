# DAX Measures — AtliQ Mart Supply Chain Audit

## Core KPIs

OT % = DIVIDE(SUM(fact_orders_aggregate[on_time]), COUNT(fact_orders_aggregate[order_id])) * 100

IF % = DIVIDE(SUM(fact_orders_aggregate[in_full]), COUNT(fact_orders_aggregate[order_id])) * 100

OTIF % = DIVIDE(SUM(fact_orders_aggregate[otif]), COUNT(fact_orders_aggregate[order_id])) * 100

OTIF Target = AVERAGE(dim_targets_orders[otif_target%])

OTIF Gap = [OTIF %] - [OTIF Target]

Total Orders = COUNT(fact_orders_aggregate[order_id])

## Order Split

Orders On Track = COUNTROWS(FILTER(fact_orders_aggregate, fact_orders_aggregate[otif] = 1))

Orders Failed = COUNTROWS(FILTER(fact_orders_aggregate, fact_orders_aggregate[otif] = 0))

## Failure Type Breakdown

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

## Product & Quantity KPIs

Total Undelivered Qty = 
SUM(fact_order_lines[order_qty]) - SUM(fact_order_lines[delivery_qty])

Fill Rate % = 
DIVIDE(SUM(fact_order_lines[delivery_qty]), SUM(fact_order_lines[order_qty])) * 100

Incomplete Rate % = 
DIVIDE(
    COUNTROWS(FILTER(fact_order_lines, fact_order_lines[in_full] = 0)),
    COUNTROWS(fact_order_lines)
) * 100

## Customer Risk

Customers Below Target = 
COUNTROWS(
    FILTER(
        VALUES(dim_customers[customer_id]),
        [OTIF %] < [OTIF Target]
    )
)

Avg OTIF Gap = 
AVERAGEX(
    VALUES(dim_customers[customer_id]),
    [OTIF Gap]
)

Customers Monitored = DISTINCTCOUNT(dim_customers[customer_id])