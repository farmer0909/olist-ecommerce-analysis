# Project Brief

## Scenario

Olist is one of Brazil's largest e-commerce marketplaces. This project is framed as a
**quarterly business review for a Head of Operations**, answering one core question:

> **Where does the money come from, and where is it leaking?**

## Sub-questions

### Where the money comes from
- **Q1** — How is GMV distributed across states? How concentrated is it?
- **Q2** — Does average order value differ by state? Where does the difference come from?
- **Q3** — Which product categories contribute the most?
- **Q4** — What does the monthly GMV trend look like?

### Where it leaks
- **Q5** — What is the late delivery rate? Which states are worst affected?
- **Q6** — Is delivery delay correlated with review scores?

## Data Feasibility

| Question | Tables required | Feasible |
|---|---|---|
| Q1 | 01_order + 04_customers + 02_order_items | Yes |
| Q2 | above + 05_products | Yes |
| Q3 | 02_order_items + 05_products | Yes |
| Q4 | 01_order + 02_order_items | Yes |
| Q5 | 01_order (delivered vs estimated date) | Yes — must exclude orders missing a delivery date |
| Q6 | 01_order + 07_order_reviews | Yes |

## Definitions

- **GMV = price + freight_value** — gross merchandise value, not profit.
  The dataset has no commission or service-fee field, so Olist's own revenue
  cannot be calculated.
- All analysis is filtered to `order_status = 'delivered'`.
- `01_order` and `02_order_items` have a one-to-many relationship, so order counts
  must use `COUNT(DISTINCT order_id)`.

## Deliverables

- SQL analysis scripts (`sql/`)
- Running findings log (`notes/findings.md`)
- Power BI dashboard (planned)
