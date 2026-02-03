# Recommended Repository Structure

```
physio-revenue-simulation/
│
├── README.md                                   # Main documentation (this file)
├── .gitignore                                  # Git ignore rules
│
├── physio_revenue_simulation.Rmd               # Main analysis script (R Markdown)
│                                               # Single file; self-contained, end-to-end executable
│
├── outputs/                                    # Generated outputs (created by script)
│   ├── plots/                                  # Visualization outputs
│   │   ├── 01_revenue_distribution.png        # Distribution of annual revenue
│   │   ├── 02_revenue_by_canton.png           # Box plots by canton
│   │   ├── 03_physios_vs_revenue.png          # Scatter + regression (staffing)
│   │   ├── 04_treatments_vs_revenue.png       # Scatter + regression (volume)
│   │   ├── 05_revenue_by_treatment.png        # Box plots by treatment type
│   │   └── 06_sensitivity_analysis.png        # Staffing scenario analysis
│   │
│   ├── results_overall.csv                    # Summary stats (all practices)
│   ├── results_by_canton.csv                  # Summary stats by canton
│   ├── results_by_treatment.csv               # Summary stats by treatment type
│   └── results_by_physio.csv                  # Summary stats by # physios
│
└── docs/                                       # (Optional) Additional documentation
    └── ASSUMPTIONS.md                          # Detailed list of all synthetic assumptions
```

## Setup Instructions

### 1. Clone / Download Repository

```bash
git clone https://github.com/yourusername/physio-revenue-simulation.git
cd physio-revenue-simulation
```

### 2. Install R & Dependencies

Ensure R >= 4.0 is installed. Then, in R:

```r
# Install required packages
install.packages(c(
  "tidyverse",      # Data manipulation & visualization
  "ggplot2",        # Advanced plotting
  "gridExtra",      # Multi-plot layouts
  "rmarkdown"       # Knitting R Markdown to HTML
))
```

### 3. Run the Simulation

#### Option A: Knit R Markdown to HTML (Recommended)

```r
setwd("path/to/physio-revenue-simulation")
rmarkdown::render("physio_revenue_simulation.Rmd", 
                  output_format = "html_document")
```

Output: `physio_revenue_simulation.html` (interactive report with all plots & tables)

#### Option B: Source Script Directly (For quick testing)

```r
setwd("path/to/physio-revenue-simulation")
source("physio_revenue_simulation.Rmd")
```

**Note**: Direct sourcing will execute code and save plots/CSVs but won't generate HTML report.

### 4. View Outputs

After running the script:
- **Plots**: Check `outputs/plots/` for 6 high-quality PNG visualizations
- **Tables**: Check `outputs/` for CSV files with summary statistics
- **Report** (if knitted): Open `physio_revenue_simulation.html` in browser

---

## Key Files Description

### `physio_revenue_simulation.Rmd`

**R Markdown document** containing:
1. **Setup & Dependencies**: Package loading, seed setting, global parameters
2. **Data Setup**: Canton TPW multipliers, treatment tariffs, supplements
3. **Simulation**: Generate 160 practices with random characteristics
4. **Revenue Calculation**: Core formula with supplement handling
5. **EDA**: Descriptive statistics by canton, treatment type, staffing
6. **Regression**: Multivariate model of revenue drivers
7. **Visualization**: 6 publication-quality plots (ggplot2)
8. **Results Tables**: Summary statistics exported to CSV
9. **Session Info**: Reproducibility metadata

**Key Parameters** (configurable at top):
- `WORKING_DAYS_PER_MONTH <- 21`
- `POINT_TO_CHF_CONVERSION <- 1`
- `n <- 160` (number of practices)
- `set.seed(42)`

### `README.md`

Complete documentation including:
- **Objective** & project context
- **Data sources** & tariff tables
- **Methodology** & assumptions
- **Results** & key findings
- **Reproducibility** instructions
- **Limitations** (explicitly stated)
- **Future enhancements** roadmap

---

## Data Transparency

### Synthetic Assumptions (Not from Real Data)

- ✅ Number of physiotherapists (1–6): Expert assumption
- ✅ Daily treatment volume (8–20): Expert assumption
- ✅ Service mix probabilities: Illustrative (not validated)
- ✅ Working days per month (21): Standard assumption
- ✅ Point-to-CHF conversion (1:1): Simplified assumption
- ✅ Supplement trigger frequencies: Stochastic estimates

### Data Sources (Provided in Script)

- ✅ Canton TPW multipliers (2024, KVG): Attributed to Physioswiss
  - **Note**: Source not independently verified by code
- ✅ Tariff position definitions: From Swiss tariff framework
  - **Note**: Accurate as of 2024 (subject to change)

### Limitations Acknowledged

- No cost side (profit ≠ revenue)
- No payer mix variation
- No demand constraints or capacity limits
- No temporal dynamics (growth, seasonality)
- Synthetic probabilities require real-world validation

---

## Reproducibility Checklist

- [x] Code is self-contained (single `.Rmd` file)
- [x] Seed is set (`set.seed(42)`)
- [x] All parameters are documented inline
- [x] Dependencies are listed and version info saved
- [x] No external API calls (all data included in script)
- [x] Output directories are created automatically
- [x] Results are saved to CSV for further analysis
- [x] Plots are saved as PNG files

---

## GitHub Repository Best Practices

### Recommended `.gitignore` Entries

```
# Don't commit large outputs (regenerate when needed)
outputs/plots/*.png
outputs/*.csv

# R artifacts
.Rhistory
.RData
.Rproj.user/
*_cache/
*_files/
```

### Commit Message Examples

```
Initial commit: Complete refactor & bug fixes
- Fixed "Einkommen" reference bug (E.Jahr renamed to Annual_revenue_total)
- Added supplement handling (points vs. annual CHF)
- Improved regression with treatment type as predictor
- Added 6 publication-quality plots
- Created comprehensive README with assumptions explicitly stated
```

---

## Quick Reference: Running the Project

```bash
# Clone repo
git clone <repo-url>
cd physio-revenue-simulation

# R Console: Install packages (one-time)
Rscript -e "install.packages(c('tidyverse', 'ggplot2', 'gridExtra', 'rmarkdown'))"

# Knit R Markdown to HTML
Rscript -e "rmarkdown::render('physio_revenue_simulation.Rmd')"

# Output files will appear in:
# - physio_revenue_simulation.html (main report)
# - outputs/plots/*.png (6 visualizations)
# - outputs/results_*.csv (summary tables)
```

---

## Troubleshooting

### Issue: "Package not found"
**Solution**: Run `install.packages("package_name")` in R console.

### Issue: "Working directory error"
**Solution**: Set working directory to repo root:
```r
setwd("/path/to/physio-revenue-simulation")
```

### Issue: "outputs/ directory not created"
**Solution**: Script creates `outputs/plots/` automatically; ensure R has write permissions.

### Issue: "Plots not appearing"
**Solution**: Check that ggplot2 is installed and X11/graphics device is available.

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Feb 2026 | Initial release; refactored from buggy prototype |

---

## Contact & Support

For issues or improvements:
1. Review inline comments in `physio_revenue_simulation.Rmd`
2. Check "Limitations" section in README.md
3. Verify all assumptions match your use case
4. Test with real data before production use

---
