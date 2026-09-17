# Olist E-Commerce Operations Analysis

Analysis of ~100,000 Brazilian e-commerce orders to locate where revenue comes from
and where operations are leaking value.

**Stack:** MySQL · DataGrip · Power BI (in progress)

---

## Background

Olist is a Brazilian e-commerce marketplace. The dataset covers orders, products,
logistics and reviews from 2016 to 2018.

This project is framed as a **quarterly review for a Head of Operations**, answering
one question:

> Where does the money come from, and where is it leaking?

Full question breakdown in [PROJECT_BRIEF.md](PROJECT_BRIEF.md).

---

## Key Findings

**1. Revenue is highly concentrated — top 3 states account for ~62%**

São Paulo (SP) alone contributes ~37% of GMV, 2.8x the second-ranked state
Rio de Janeiro (RJ).

**2. Yet SP has the *lower* average order value**

SP's AOV is R$142 versus RJ's R$166. SP leads on order volume
(3.3x RJ), not on spending power.

**3. The AOV gap comes from pricing, not category mix**

The initial hypothesis was that the two states buy different categories.
The data rejected it — their top 15 categories are near-identical.

The real difference: SP prices are lower across *every* category.
Breaking the R$21 gap down, product price accounts for 73% and freight for 27%
(SP freight is 28% cheaper, consistent with most sellers being based in SP).

**Conclusion:** SP's lower AOV reflects a mature, competitive market with
abundant supply — not weaker purchasing power.

**4. Growth stalled in early 2018**

GMV climbed roughly 7x through 2017, then flattened at R$1.0–1.2M per
month from January 2018 onward. The headline isn't growth — it's that
the growth engine stopped.

**5. The 8% late-delivery rate understates the problem**

Olist sets deliberately generous delivery estimates: orders arrive
11.9 days ahead of the promised date on average. Even so, 8.11% miss it.
Of those, 2,862 are more than a week late and 345 exceed a month —
failed orders rather than normal variance.

**6. Being late at all is what costs ratings — not how late**

A single day past the promised date takes the 1-star rate from 6.6% to
32.7%. Because minor delays are 15x more common than extreme ones, they
do far more total damage. Reliability, not speed, is the lever.

**7. Rio is the anomaly worth fixing**

Most high-delay states are remote, which is structural. RJ is not: it sits
400km from SP, carries the country's highest AOV, and still runs a 13.47%
late rate — 1.7x the national average. It also carries enough volume that
RJ alone produces more late deliveries than every other high-rate state
combined.

---

## Repository Structure

```
olist-ecommerce-analysis/
├── README.md              Project overview
├── PROJECT_BRIEF.md       Scope and question breakdown
├── sql/
│   ├── 01_exploration.sql Data profiling: structure, grain, quality
│   └── 02_analysis.sql    Analysis queries (Q1–Q6)
└── notes/
    └── findings.md        Running analysis notes
```

---

## Data

Source: [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle).

Raw CSVs are not version-controlled. To reproduce:

1. Download the dataset from the link above
2. Create a MySQL database named `olist_ecommerce`
3. Import the CSVs (**make sure "First row is header" is checked**)
4. Run the scripts in `sql/` in order

### Definitions

- **GMV = price + freight_value** — gross merchandise value, not profit.
  The dataset contains no commission field, so Olist's own revenue cannot be derived.
- All analysis is filtered to `order_status = 'delivered'`
- `01_order` to `02_order_items` is one-to-many, so order counts use
  `COUNT(DISTINCT order_id)`

---

## Next Steps

- [x] Q1 — GMV by state
- [x] Q2 — Why SP's average order value is lower
- [x] Q3 — GMV contribution by product category
- [x] Q4 — Monthly GMV trend
- [x] Q5 — Late delivery rate and severity
- [x] Q5b — Late delivery by state
- [x] Q6 — Relationship between delivery delay and review score
- [ ] Power BI interactive dashboard
