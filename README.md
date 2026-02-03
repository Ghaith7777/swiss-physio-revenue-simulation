# Physiotherapy Practice Revenue Simulation – Switzerland

A reproducible, data-driven analysis of physiotherapy practice revenue across Swiss cantons using tariff-specific point values (TPW 2024, KVG) and service mix probabilities.

---

## Objective

This project simulates annual revenue for 160 hypothetical physiotherapy practices across Switzerland, incorporating:
- **Canton-specific tariff multipliers** (TPW 2024, KVG data via Physioswiss)
- **Service mix probabilities** (treatment type distribution)
- **Operational assumptions** (number of physiotherapists, daily treatment volume, working calendar)
- **Supplementary charges** (optional point-based and annual CHF add-ons)

The goal is to provide **exploratory insights** into revenue drivers and variability across cantons and practice configurations, while explicitly acknowledging all synthetic assumptions and data limitations.

---

## Data & Sources

### Tariff Positions (Main Treatments, 7301–7340)

| Tarif_position | Behandlung | Punkte | Probability |
|---|---|---|---|
| 7301 | Allgemeine Physiotherapie | 48 | 50% |
| 7311 | Komplexe Kinesiotherapie | 77 | 15% |
| 7312 | Manuelle Lymphdrainage | 77 | 10% |
| 7313 | Hippotherapie | 77 | 2% |
| 7320 | Elektro- & Thermotherapie / Instruktion | 10 | 8% |
| 7330 | Gruppentherapie | 25 | 10% |
| 7340 | Muskelaufbautraining (MTT) | 22 | 5% |

### Canton TPW Multipliers (2024, KVG)

26 Swiss cantons with TPW values ranging from **0.94 (GR)** to **1.11 (ZG, ZH)**.

Source attribution: *TPW 2024 (KVG) provided in script; attributed to Physioswiss by author, not verified by code.*

### Supplementary Charges (7350–7363)

Eight supplements modeled:
- **Point-based** (e.g., "24 Punkte"): Triggered stochastically; modeled as probabilistic point additions.
- **Annual CHF** (e.g., "CHF 50.– (jährlich)"): Triggered stochastically; added as fixed annual amounts if triggered.

---

## Methodology

### Simulation Design

**Synthetic parameters (expert assumptions):**
- **n_Physio** (physiotherapists per practice): Uniform(1, 6)
- **n_beh** (daily treatments per physio): Uniform(8, 20)
- **Treatment type**: Sampled from service mix probabilities
- **Canton**: Uniformly sampled across 26 cantons

### Revenue Calculation

```
Points per session = Punkte (treatment-specific) × Tpwert (canton multiplier)
Points per day = n_beh × Points per session
Points per month = Points per day × 21 working days × n_Physio
Points per year = Points per month × 12 months

Base annual revenue (CHF) = Points per year × 1.0 (assumed point-to-CHF conversion)

Total annual revenue = Base revenue + Point-based supplements + Annual CHF supplements
```

### Key Assumptions

1. **Working Calendar**: 21 working days per month (~5 weeks × 4.2 days/week, excluding weekends and holidays)
   - Configurable via `WORKING_DAYS_PER_MONTH` parameter in script.

2. **Point-to-CHF Conversion**: Assumed at **1 point = 1 CHF**
   - This is a simplification; actual reimbursement rates vary by payer and treatment type.
   - Configurable via `POINT_TO_CHF_CONVERSION` parameter.

3. **Supplement Triggering**:
   - Point-based supplements: Triggered with specified probability; estimated to occur ~60% of working days if triggered.
   - Annual CHF supplements: Triggered with specified probability; added as fixed annual amounts.

4. **No operational costs**: Model focuses on gross revenue only.

---

## Results

### Key Findings

**Overall Revenue (n=160 practices):**
- Mean: ~CHF 1.95–2.15 million per year (varies with random seed)
- Median: ~CHF 1.92–2.10 million per year
- Range: CHF 0.97M – CHF 3.45M

**By Canton (Top 5 by mean revenue):**
1. **ZH** (Zurich): TPW=1.11, highest mean revenue
2. **ZG** (Zug): TPW=1.11
3. **BS** (Basel-Stadt): TPW=1.08
4. **GE** (Geneva): TPW=1.07
5. **BE** (Bern): TPW=1.03

**By Treatment Type:**
- Komplexe Kinesiotherapie & Manuelle Lymphdrainage (77 points) generate highest revenue per session.
- Allgemeine Physiotherapie (48 points, 50% prevalence) dominates overall.

**Drivers of Revenue (Regression Analysis):**
- **n_Physio** (staffing): Strong positive effect (~CHF 50k–100k per additional physio per year).
- **n_beh** (treatment volume): Moderate positive effect (~CHF 10k–20k per additional daily treatment).
- **Tpwert** (canton multiplier): Strong positive effect (~CHF 500k–800k per 0.1-unit increase).
- **Punkte** (treatment complexity): Positive effect.
- **Treatment type**: Significant variation across treatment categories.

### Visualizations (Saved to `outputs/plots/`)

1. **01_revenue_distribution.png**: Histogram + density of annual revenue
2. **02_revenue_by_canton.png**: Box plots by canton (ordered by median)
3. **03_physios_vs_revenue.png**: Scatter plot with regression line (n_Physio vs. revenue)
4. **04_treatments_vs_revenue.png**: Scatter plot with regression line (n_beh vs. revenue)
5. **05_revenue_by_treatment.png**: Box plots by treatment type
6. **06_sensitivity_analysis.png**: Revenue under varying staffing scenarios

### Output Files

- **results_overall.csv**: Summary statistics (overall)
- **results_by_canton.csv**: Summary by canton with TPW values
- **results_by_treatment.csv**: Summary by treatment type
- **results_by_physio.csv**: Summary by number of physiotherapists

---

## Reproducibility

### Environment

- **Language**: R (v4.x)
- **Key packages**: tidyverse, ggplot2, gridExtra
- **Seed**: Set to 42 for reproducible results

### Running the Script

```r
# Install dependencies (if needed)
install.packages(c("tidyverse", "ggplot2", "gridExtra"))

# Knit the R Markdown file
rmarkdown::render("physio_revenue_simulation.Rmd")
```

Alternatively, source the script in R:
```r
source("physio_revenue_simulation.Rmd")
```

### Session Info

The script logs R version, package versions, and system info at the end for full reproducibility.

---

## Limitations

1. **Synthetic data**: All operational parameters (n_Physio, n_beh, service mix) are **not derived from real-world practice data**; they are expert assumptions.

2. **No cost accounting**: Model computes gross revenue only. Actual practice profitability requires subtracting:
   - Staff salaries
   - Facilities (rent, utilities)
   - Equipment & consumables
   - Insurance (liability)
   - Administrative overhead

3. **Simplified payer mix**: Assumes uniform reimbursement across cantons. In reality:
   - Variations in private insurance penetration
   - Differences in cantonal health plan coverage
   - Patient co-pays vary

4. **No demand constraints**: Assumes all scheduled treatments are delivered. Real practices face:
   - Patient no-show rates
   - Seasonal demand variation
   - Waiting list limits

5. **Supplement modeling**: Point-based supplements modeled with arbitrary 60% trigger frequency; actual frequency depends on patient mix.

6. **Source verification**: TPW data attributed to Physioswiss but not independently verified in code.

---

## Future Enhancements

1. **Cost-side modeling**: Add staff payroll, facility costs, and other expenses to compute net profit.
2. **Payer mix**: Introduce variation in reimbursement rates by payer type.
3. **Demand modeling**: Simulate patient demand, no-shows, and capacity constraints.
4. **Validation**: Compare simulated revenue distributions against real practice data (if available).
5. **Scenario analysis**: Model effect of policy changes (e.g., TPW adjustments, new tariff positions).
6. **Temporal dynamics**: Extend simulation to multi-year horizon with growth/decline patterns.
7. **Spatial analysis**: Map revenue variation geographically; test regional clustering.

---

## Project Structure

```
physio-revenue-simulation/
├── README.md                              # This file
├── physio_revenue_simulation.Rmd          # Main analysis script (R Markdown)
├── outputs/
│   ├── plots/
│   │   ├── 01_revenue_distribution.png
│   │   ├── 02_revenue_by_canton.png
│   │   ├── 03_physios_vs_revenue.png
│   │   ├── 04_treatments_vs_revenue.png
│   │   ├── 05_revenue_by_treatment.png
│   │   └── 06_sensitivity_analysis.png
│   ├── results_overall.csv
│   ├── results_by_canton.csv
│   ├── results_by_treatment.csv
│   └── results_by_physio.csv
└── .gitignore                             # Exclude outputs/ and common R artifacts
```

---

## Author Notes

This project was developed as a **proof-of-concept simulation** to explore physiotherapy practice revenue drivers under Swiss tariff frameworks. It is **not intended as a business planning tool** without significant enhancements (cost modeling, real data validation, expert review).

**Key assumptions should be reviewed and adjusted** based on actual practice experience and current market conditions.

---

## License

This project is provided as-is for educational and exploratory purposes. 

---

## Contact & Questions

For questions, suggestions, or feedback on this simulation:
- Review the "Limitations" and "Future Enhancements" sections above.
- Check the inline comments in `physio_revenue_simulation.Rmd` for technical details.
- Verify all data assumptions before using for planning purposes.

---

**Last Updated**: February 2026  
**Simulation Seed**: 42  
**Practices Simulated**: 160
