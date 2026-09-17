# Findings Log

---

## Data Exploration

- `01_order` → `02_order_items` is one-to-many
  → order counts must use `COUNT(DISTINCT order_id)`, otherwise inflated
- The vast majority of orders have status `delivered`
  → all analysis filtered with `WHERE order_status = 'delivered'`
- Every column imports from CSV as text; date columns converted to DATETIME
  via `ALTER TABLE`
  → without this, `DATEDIFF()` and monthly grouping break
- Some orders have no delivery date
  → must be excluded from delivery-time analysis, or average lead time
    will look optimistic
- Product price ranges 0.85 – 999.99, mean 120.65
  → max is exactly the `DECIMAL(5,2)` ceiling; worth checking whether
    high-value items were truncated on import

---

## Q1 — GMV by State

| State | GMV | Orders | AOV |
|---|---|---|---|
| SP | 5,769,703 | 40,501 | 142 |
| RJ | 2,055,402 | 12,350 | 166 |
| MG | 1,818,892 | 11,354 | — |

- SP contributes ~**37%** of GMV, 2.8x the second-ranked state
- Top 3 states together account for ~**62%** — highly concentrated
- **But SP's AOV is lower than RJ's** (142 vs 166)
- SP's lead comes from order volume (3.3x RJ), not spending power

→ Follow-up: why is SP's AOV lower?

---

## Q2 — Why SP's AOV Is Lower

**Hypothesis: the two states buy different categories → REJECTED**

Their top 15 categories are nearly identical, differing only in rank.
But within every shared category, SP's AOV is lower than RJ's — no exceptions.
Example: beleza_saude, RJ 169.33 vs SP 137.35.

**Breaking down the gap:**

| | SP | RJ | Difference |
|---|---|---|---|
| Avg product price | 109.10 | 124.42 | -15.32 |
| Avg freight | 15.12 | 20.91 | -5.79 |

- Product price accounts for **73%** of the gap; freight only 27%
- SP freight is **28% cheaper** — consistent with most sellers being
  located in SP, so deliveries are local

**Conclusion:** SP's lower AOV is not weak purchasing power. It reflects
dense seller competition pushing prices down, with cheaper local shipping
reinforcing the effect.

→ Follow-up: how large is freight as a share of order value nationally?
  Are remote states being suppressed by shipping cost?

---

## Q3 — GMV by Category

*To do*

---

## Q4 — Monthly GMV Trend

- Data spans 2016-09 to 2018-08
- First four months are near-zero and **2016-11 is missing entirely**
  → excluded when reading the trend
- 2017: steady climb, ~150k in January to ~1M in December (roughly 7x)
- 2018 Jan–Aug: flat at 1.0–1.2M per month
- Final month dips slightly — most likely data truncation, not a real decline

**Key point:** the story isn't "the platform is growing" — it's that
**growth stalled in early 2018**. For an ops review, a stalled engine
matters more than the headline total.

---

## Q5 — Delivery Delays

| Metric | Value |
|---|---|
| Delivered orders | 96,470 |
| Late orders | 7,826 |
| Late rate | 8.11% |
| Avg vs promised date | 11.9 days **early** |

Those last two numbers are the interesting part. Orders arrive nearly
two weeks ahead of the promised date on average — Olist sets
deliberately conservative estimates. Even against that generous window,
8% still miss it.

**Severity breakdown:**

| Delay | Orders | Share |
|---|---|---|
| 1–7 days | 4,964 | 63% |
| 8–30 days | 2,517 | 32% |
| 30+ days | 345 | 4% |

Most delays are minor. But **2,862 orders are more than a week late**,
and 345 exceed a month — by then the customer has likely already
complained or requested a refund. Those are failed orders, not variance.

**Key point:** the headline 8% understates the problem. Given how much
slack is built into the promise, the tail end represents genuine
fulfilment breakdowns.

→ Follow-up not yet run: which states are worst affected?
  (Join `04_customers`, group by state, `HAVING COUNT(*) >= 500`)

---

## Q6 — Delay vs Review Score

*To do* — reuse the Q5 delay buckets, join `07_order_reviews`, compare
average review score per bucket. This would show whether the delays
found in Q5 actually cost anything.
