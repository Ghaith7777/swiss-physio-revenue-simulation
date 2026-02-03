# Code Structure & Validation Guide

## File Organization

```
physio-revenue-simulation/
├── physio_revenue_simulation.R              # MAIN: Pure R script (executable)
├── physio_revenue_simulation.Rmd            # MAIN: R Markdown (generates HTML report)
├── README.md                                # Project documentation & overview
├── SETUP_INSTRUCTIONS.md                    # Setup & installation guide
├── CODE_STRUCTURE.md                        # This file
├── .gitignore                               # Git ignore rules
└── outputs/                                 # Generated outputs
    ├── plots/
    │   ├── 01_revenue_distribution.png
    │   ├── 02_revenue_by_canton.png
    │   ├── 03_physios_vs_revenue.png
    │   ├── 04_treatments_vs_revenue.png
    │   ├── 05_revenue_by_treatment.png
    │   └── 06_sensitivity_analysis.png
    ├── results_overall.csv
    ├── results_by_canton.csv
    ├── results_by_treatment.csv
    └── results_by_physio.csv
```

## Main Script Files

### 1. `physio_revenue_simulation.R` (Recommended for execution)

**Purpose**: Standalone, pure R script that executes end-to-end without external dependencies (other than tidyverse/ggplot2).

**Execution**:
```bash
# Option A: Run as script
Rscript physio_revenue_simulation.R

# Option B: Source in R console
setwd("path/to/project")
source("physio_revenue_simulation.R")
```

**Sections** (in order):
1. **Setup** (lines 1-50)
   - Load packages (tidyverse, ggplot2, gridExtra)
   - Set seed
   - Define global parameters
   - Print session info

2. **Data Setup** (lines 51-130)
   - Load canton TPW multipliers
   - Load main tariff positions (7301-7340)
   - Load supplements (7350-7363)
   - Parse supplement values (points vs. CHF)

3. **Simulation** (lines 131-160)
   - Generate n=160 practice records
   - Merge in treatment details
   - Merge in canton multipliers
   - Output summary

4. **Revenue Calculation** (lines 161-200)
   - Compute Punkte_per_session (treatment × canton TPW)
   - Compute Punkte_per_day (n_beh × points/session)
   - Compute Punkte_per_month (points/day × 21 × n_Physio)
   - Compute Punkte_per_year (points/month × 12)
   - Compute Annual_revenue_base (points × 1.0 CHF/point)
   - Add point-based and CHF supplements

5. **EDA** (lines 201-260)
   - Summary statistics overall
   - By canton (with TPW values)
   - By treatment type
   - By number of physiotherapists

6. **Regression** (lines 261-290)
   - Multivariate LM: Annual_revenue_total ~ n_Physio + n_beh + Tpwert + Punkte + Behandlung
   - Print summary
   - Interpret coefficients

7. **Visualizations** (lines 291-400)
   - 6 ggplot2 plots (distribution, canton boxplots, scatter + regression, sensitivity)
   - Save as PNG files to outputs/plots/

8. **Results Export** (lines 401-450)
   - Save summary tables to CSV (overall, by canton, by treatment, by physios)

9. **Final Summary** (lines 451-end)
   - Print completion message
   - List all generated files

**Key Variables**:
- `WORKING_DAYS_PER_MONTH` (default: 21) – Configurable working calendar
- `POINT_TO_CHF_CONVERSION` (default: 1.0) – Point-to-currency conversion
- `N_PRACTICES` (default: 160) – Number of practices to simulate
- `sim_dat` – Main data frame with all practice & revenue data

### 2. `physio_revenue_simulation.Rmd` (Alternative: generates HTML report)

**Purpose**: R Markdown document that generates a polished HTML report with embedded code, output, and plots.

**Execution**:
```r
rmarkdown::render("physio_revenue_simulation.Rmd", output_format = "html_document")
```

**Sections** (same logic as .R file, but with better formatting and narrative):
- Setup & dependencies
- Data setup
- Simulation
- Revenue calculation
- EDA with prose explanations
- Regression analysis with interpretation
- Visualizations (6 plots)
- Results summary tables
- Session info & reproducibility notes

**Advantages**:
- Single-file HTML report with all code, output, and plots embedded
- Better for sharing and documentation
- Self-contained (no need to reference separate PNG files)

**Disadvantages**:
- Requires rmarkdown package
- Longer to render (must execute all code)

---

## Data Structures

### Canton TPW Multipliers (`Ktpw`)

```r
  kanton Tpwert
  "AG"   1.05
  "AI"   0.97
  ...
  "ZH"   1.11
```
- 26 rows (one per canton)
- Used to adjust point values across regions
- Source: Attributed to Physioswiss; not independently verified

### Main Tariff Positions (`Pauschal`)

```r
  Tarif_position Tarif_prob Behandlung                   Punkte
  "7301"         0.50       "Allgemeine Physiotherapie"  48
  "7311"         0.15       "Komplexe Kinesiotherapie"   77
  ...
```
- 7 rows (main treatment types)
- Probabilities sum to 1.0
- Points represent treatment complexity/reimbursement value

### Supplements (`zuschlaege`)

```r
  Tarif_position Tarif_prob Leistung                    Punkte_oder_Betrag
  "7350"         0.05       "Erstbehandlung"            "24 Punkte"
  "7362"         0.003      "Materialpauschale..."      "CHF 50.– (jährlich)"
  ...
```
- 8 rows (optional add-ons)
- Two types: point-based ("X Punkte") and annual CHF ("CHF X.–")
- Parsed into numeric columns: Punkte_value, Is_annual_CHF

### Simulated Practice Data (`sim_dat`)

**Key columns**:
- `Praxis_id` – Unique practice identifier
- `n_Physio` – Number of physiotherapists (1-6)
- `n_beh` – Daily treatments per physio (8-20)
- `kanton` – Canton of operation
- `Behandlung` – Treatment type
- `Punkte` – Points per single treatment
- `Tpwert` – Canton multiplier
- `Punkte_per_session` – Treatment points × canton multiplier
- `Punkte_per_year` – Annual total points
- `Annual_revenue_base` – CHF revenue from core treatments
- `Supplement_points_annual` – CHF from point-based supplements
- `Supplement_CHF_annual` – CHF from annual-amount supplements
- `Annual_revenue_total` – Total annual revenue (all sources)

---

## Key Formulas

### Revenue Calculation

```
Points per single treatment:
  Punkte_per_session = Punkte × Tpwert

Points per day (all treatments by one physio):
  Punkte_per_day = n_beh × Punkte_per_session

Points per month (one physio, 21 working days):
  Punkte_per_month = Punkte_per_day × WORKING_DAYS_PER_MONTH

Points per month (all physios):
  Punkte_per_month_practice = Punkte_per_month × n_Physio

Annual points:
  Punkte_per_year = Punkte_per_month_practice × 12

Annual revenue (base):
  Annual_revenue_base = Punkte_per_year × POINT_TO_CHF_CONVERSION

Total annual revenue:
  Annual_revenue_total = Annual_revenue_base 
                       + Supplement_points_annual 
                       + Supplement_CHF_annual
```

### Regression Model

```r
lm(Annual_revenue_total ~ n_Physio + n_beh + Tpwert + Punkte + Behandlung,
   data = sim_dat)
```

**Interpretation**:
- Each coefficient represents marginal effect on annual revenue (CHF)
- Baseline: treatment type "Allgemeine Physiotherapie" (most common)
- Other treatment types included as dummy variables

---

## Bug Fixes from Original Script

### 1. Variable Naming Error
**Original**:
```r
sim_dat$E.Tag <- sim_dat$Totale_Punkte * 1
sim_dat$E.Monat <- sim_dat$E.Tag * 21
sim_dat$E.Jahr <- sim_dat$E.Monat * 12
# Later: plot(sim_dat$n_Physio, sim_dat$Einkommen)  # ERROR: "Einkommen" doesn't exist!
```

**Fixed**:
```r
# Use clear, descriptive names: Punkte_per_session, Punkte_per_year, etc.
# Reference correct variable name: Annual_revenue_total
plot(sim_dat$n_Physio, sim_dat$Annual_revenue_total)
```

### 2. Merge Duplicates
**Original**:
```r
sim_dat = merge(sim_dat, Pauschal[, c(...)], by = "Tarif_position")
sim_dat = merge(sim_dat, Ktpw, by = "kanton")
# Risk of duplicate columns if merging introduces overlaps
```

**Fixed**:
```r
sim_dat <- sim_dat %>%
  left_join(Pauschal[, c("Tarif_position", "Behandlung", "Punkte")],
            by = "Tarif_position")
sim_dat <- sim_dat %>%
  left_join(Ktpw, by = "kanton")
# Explicit column selection avoids duplicates
```

### 3. Working Days Assumption
**Original comment** (incorrect):
```r
# "21 days per month"  # Misleading; doesn't explain the logic
```

**Fixed comment** (clear):
```r
WORKING_DAYS_PER_MONTH <- 21  # Excludes weekends (~5 weeks * 4.2 days/week)
```

### 4. Supplement Handling
**Original**: No supplement modeling

**Fixed**:
- Parse point-based vs. annual CHF supplements separately
- Stochastically trigger each supplement based on probability
- Accumulate points or CHF contributions by practice
- Add to total annual revenue correctly

### 5. Regression Reference
**Original**:
```r
regression <- lm(Einkommen ~ n_Physio, data = sim_dat)  # ERROR: "Einkommen" undefined!
```

**Fixed**:
```r
regression_model <- lm(Annual_revenue_total ~ n_Physio + n_beh + Tpwert + Punkte + Behandlung,
                       data = sim_dat)
# Multivariate model with correct variable names
```

---

## Testing Checklist

- [x] Script runs without errors
- [x] No undefined variable references
- [x] Merges don't create duplicate columns
- [x] Working days assumption is configurable and well-documented
- [x] Supplements are properly parsed and applied
- [x] Revenue calculations match expected formulas
- [x] Regression summary is interpretable
- [x] Plots render and save correctly
- [x] CSV outputs contain expected columns
- [x] All assumptions are explicitly documented
- [x] Session info is reproducible (seed, packages, etc.)

---

## Validation Strategy

### 1. Manual Calculation (First 3 Practices)

Verify revenue calculation by hand:

**Example: Practice 1**
- n_Physio = 2
- n_beh = 15
- Behandlung = "Allgemeine Physiotherapie" (48 points)
- kanton = "ZH" (TPW = 1.11)

Expected:
```
Points/session = 48 × 1.11 = 53.28
Points/day = 15 × 53.28 = 799.2
Points/month = 799.2 × 21 = 16,783.2
Points/month (all) = 16,783.2 × 2 = 33,566.4
Points/year = 33,566.4 × 12 = 402,796.8
Revenue (base) = 402,796.8 × 1.0 = 402,796.8 CHF
(+ supplements, if triggered)
```

Cross-check against `sim_dat$Annual_revenue_total[1]` in output.

### 2. Aggregate Checks

- Sum of treatment probabilities in Pauschal: 0.5 + 0.15 + ... + 0.05 = 1.0 ✓
- All 26 cantons represented in simulation ✓
- Revenue variance increases with n_Physio ✓
- Canton TPW correlates with mean revenue ✓

### 3. Statistical Validity

- Regression R-squared > 0.7 (model explains most revenue variation)
- Coefficients have expected signs (positive for n_Physio, n_beh, Tpwert, Punkte)
- No multicollinearity warnings

---

## Reproducibility Verification

**To verify reproducibility**:

1. Run script twice with same seed:
   ```r
   source("physio_revenue_simulation.R")
   # Compare outputs with previous run
   ```

2. Check that first 5 rows of `sim_dat` are identical across runs

3. Verify all plot dimensions and axis labels match expected output

4. Confirm CSV file content matches in-memory summaries

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| "Package not found" | tidyverse/ggplot2 not installed | Run `install.packages("package_name")` |
| "File not found" | Working directory incorrect | Run `setwd()` to correct directory |
| "Plots not rendering" | Graphics device issue | Check X11/RStudio graphics device |
| "CSV not created" | Permissions issue | Verify write access to outputs/ directory |
| "Different results on re-run" | Seed not set | Ensure `set.seed(42)` is executed first |

---

## Documentation Cross-References

- **README.md**: Objective, assumptions, limitations, future work
- **SETUP_INSTRUCTIONS.md**: Installation, execution, quick reference
- **CODE_STRUCTURE.md** (this file): Technical details, validation, troubleshooting
- **Inline comments** in .R/.Rmd files: Code-level documentation

