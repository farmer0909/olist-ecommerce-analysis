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

| Category | Orders | GMV | AOV |
|---|---|---|---|
| beleza_saude | 8,647 | 1,412,090 | 163.30 |
| relogios_presentes | 5,495 | 1,264,333 | 230.09 |
| cama_mesa_banho | 9,272 | 1,225,209 | 132.14 |
| esporte_lazer | 7,530 | 1,118,257 | 148.51 |
| informatica_acessorios | 6,530 | 1,032,724 | 158.15 |

- Category GMV is **evenly spread** — #1 to #5 differ by less than 40%
- Sharp contrast with the geographic picture, where SP alone takes 37%
  → **concentration risk sits in geography, not in product mix**

Two distinct profiles stand out:

- **relogios_presentes** — fewest orders of the five, yet 2nd highest GMV.
  AOV 230 → high-value, low-frequency
- **cama_mesa_banho** — most orders, yet only 3rd in GMV.
  AOV 132 → high-volume, low-margin

These need different playbooks: the first lives on conversion and basket
value, the second on traffic and repeat purchase.

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

## Q5b — Late Delivery by State

| State | Orders | Late rate |
|---|---|---|
| MA | 717 | 19.67% |
| CE | 1,279 | 15.32% |
| BA | 3,256 | 14.04% |
| **RJ** | **12,350** | **13.47%** |
| PA | 946 | 12.37% |
| ES | 1,995 | 12.23% |

*(National average 8.11%. Filtered to states with ≥500 delivered orders,
so small-sample states don't distort the ranking.)*

Most of the worst performers are remote northern/northeastern states —
expected, given the seller base sits in SP.

**The outlier is RJ.** Brazil's second-largest market, 400km from SP, with
the highest AOV in the country (R$166) — yet its late rate is 1.7x the
national average, close to remote-state levels. Distance doesn't explain
this one.

Volume compounds it: RJ carries 12,350 orders against MA's 717, so RJ
alone produces more late deliveries than the other high-rate states
combined. The platform's most valuable customers are getting second-tier
fulfilment.

→ **Recommendation:** RJ's delay isn't distance-driven and may be fixable.
  Worth investigating carrier performance and last-mile coverage there.

---

## Q6 — Delay vs Review Score

| Delay bucket | Orders | Avg score | 1-star rate |
|---|---|---|---|
| On time | 88,653 | 4.29 | 6.60% |
| 1–7 days late | 4,903 | 3.06 | 32.74% |
| 8–30 days late | 2,466 | 1.65 | 70.56% |
| 30+ days late | 331 | 2.05 | 63.14% |

**The penalty is a cliff, not a slope.** A single day late takes the
1-star rate from 6.6% to 32.7% — a 5x jump.

This **revises the Q5 reading**. There the 63% of delays falling under a
week looked like harmless variance. They aren't — customers don't grade
on a curve. Late is late.

And measured by customers affected, minor delays do far more damage than
extreme ones: the 1–7 day bucket holds 4,903 orders against 331 in the
30+ bucket, 15x as many.

**Anomaly:** 30+ days late scores *higher* (2.05) than 8–30 days (1.65).
Possible explanations — refund or resolution processes kicking in for very
late orders, or pre-order items where slow delivery was expected. Not
resolved; flagged rather than explained away.

**Key point:** delivery *reliability*, not speed, drives satisfaction.
Olist already beats its promised date by 11.9 days on average. It's the
8% that miss which cost the platform its ratings.
