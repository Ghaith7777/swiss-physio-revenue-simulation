#!/usr/bin/env Rscript
# ============================================================================
# PHYSIOTHERAPY PRACTICE REVENUE SIMULATION - SWITZERLAND
# Canton-Specific Analysis (TPW 2024, KVG)
# 
# This is the main executable R script (non-Markdown version).
# It can be sourced with: source("physio_revenue_simulation.R")
# Or run as: Rscript physio_revenue_simulation.R
# ============================================================================

cat("\n=== PHYSIOTHERAPY REVENUE SIMULATION (SWITZERLAND) ===\n\n")

# ============================================================================
# 1. DEPENDENCIES & SESSION SETUP
# ============================================================================

packages_required <- c("tidyverse", "ggplot2", "gridExtra")

for (pkg in packages_required) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("INFO: Installing package:", pkg, "\n")
    install.packages(pkg, repos = "https://cran.r-project.org", quiet = TRUE)
    library(pkg, character.only = TRUE, quietly = TRUE)
  }
}

suppressPackageStartupMessages({
  library(tidyverse, quietly = TRUE)
  library(ggplot2, quietly = TRUE)
  library(gridExtra, quietly = TRUE)
})

# Set seed for reproducibility
set.seed(42)

# Global simulation parameters
WORKING_DAYS_PER_MONTH <- 21  # Excludes weekends (~5 weeks * 4.2 days/week)
POINT_TO_CHF_CONVERSION <- 1  # Assumed conversion: 1 point = 1 CHF (simplification)
N_PRACTICES <- 160  # Number of practices to simulate

cat("Session Info:\n")
cat("  R Version:", R.version$version.string, "\n")
cat("  Working directory:", getwd(), "\n")
cat("  Seed:", 42, "\n")
cat("  Working days/month:", WORKING_DAYS_PER_MONTH, "\n")
cat("  Point-to-CHF conversion:", POINT_TO_CHF_CONVERSION, "\n\n")

# ============================================================================
# 2. DATA SETUP: TARIFFS, CANTONS, SUPPLEMENTS
# ============================================================================

cat("Loading data structures...\n")

# CANTON TARIFF POINT VALUES (TPW 2024 - KVG)
# Source: Physioswiss (as indicated by author; not verified by code)
Ktpw <- data.frame(
  kanton = c("AG","AI","AR","BE","BL","BS","FR","GE","GL","GR",
             "JU","LU","NE","NW","OW","SG","SH","SO","SZ","TG",
             "TI","UR","VD","VS","ZG","ZH"),
  Tpwert = c(1.05, 0.97, 0.99, 1.03, 1.03, 1.08, 0.98, 1.07, 1.01, 0.94,
             0.95, 0.99, 0.96, 1.01, 0.95, 0.98, 1.05, 1.03, 0.99, 1.00,
             0.95, 0.98, 1.00, 0.96, 1.11, 1.11),
  stringsAsFactors = FALSE
)

# MAIN TARIFF POSITIONS (7301-7340)
Pauschal <- data.frame(
  Tarif_position = c("7301", "7311", "7312", "7313", "7320", "7330", "7340"),
  Tarif_prob = c(0.50, 0.15, 0.10, 0.02, 0.08, 0.10, 0.05),
  Behandlung = c(
    "Allgemeine Physiotherapie",
    "Komplexe Kinesiotherapie",
    "Manuelle Lymphdrainage",
    "Hippotherapie",
    "Elektro- & Thermotherapie / Instruktion",
    "Gruppentherapie",
    "Muskelaufbautraining (MTT)"
  ),
  Punkte = c(48, 77, 77, 77, 10, 25, 22),
  stringsAsFactors = FALSE
)

# SUPPLEMENTARY CHARGES (Zuschläge - 7350-7363)
zuschlaege <- data.frame(
  Tarif_position = c("7350", "7351", "7352", "7353", "7354", "7360", "7362", "7363"),
  Tarif_prob = c(0.05, 0.0002, 0.0002, 0.02, 0.10, 0.002, 0.003, 0.00001),
  Leistung = c(
    "Erstbehandlung",
    "Kinder mit chronischer Behinderung (bis 6 J.)",
    "Therapiebad / Gehbecken",
    "Infrastruktur Hippotherapie",
    "Weg-/Zeitentschädigung (Hausbesuch)",
    "Hilfsmittel gemäss Lima",
    "Materialpauschale vaginale Sonde",
    "Materialpauschale anale Sonde"
  ),
  Punkte_oder_Betrag = c(
    "24 Punkte", "30 Punkte", "19 Punkte", "67 Punkte",
    "34 Punkte", "77 Punkte", "CHF 50.– (jährlich)", "CHF 90.– (jährlich)"
  ),
  stringsAsFactors = FALSE
)

# Parse supplement values
zuschlaege$Punkte_value <- as.numeric(gsub("([0-9]+).*", "\\1", zuschlaege$Punkte_oder_Betrag))
zuschlaege$Is_annual_CHF <- grepl("CHF", zuschlaege$Punkte_oder_Betrag)

cat("Data loaded:\n")
cat("  Cantons:", nrow(Ktpw), "\n")
cat("  Main treatments:", nrow(Pauschal), "\n")
cat("  Supplements:", nrow(zuschlaege), "\n\n")

# ============================================================================
# 3. SIMULATION: GENERATE PRACTICE DATA
# ============================================================================

cat("Generating", N_PRACTICES, "simulated practices...\n")

sim_dat <- data.frame(
  Praxis_id = 1:N_PRACTICES,
  n_Physio = round(runif(N_PRACTICES, min = 1, max = 6)),
  n_beh = round(runif(N_PRACTICES, min = 8, max = 20)),
  Tarif_position = sample(Pauschal$Tarif_position, N_PRACTICES, replace = TRUE,
                          prob = Pauschal$Tarif_prob),
  kanton = sample(Ktpw$kanton, N_PRACTICES, replace = TRUE),
  stringsAsFactors = FALSE
)

# Merge treatment details
sim_dat <- sim_dat %>%
  left_join(Pauschal[, c("Tarif_position", "Behandlung", "Punkte")],
            by = "Tarif_position")

# Merge canton tariff multipliers
sim_dat <- sim_dat %>%
  left_join(Ktpw, by = "kanton")

cat("Simulation complete. Sample (first 5 practices):\n")
print(head(sim_dat, 5))

# ============================================================================
# 4. REVENUE CALCULATION (WITH SUPPLEMENTS)
# ============================================================================

cat("\nCalculating annual revenue...\n")

sim_dat <- sim_dat %>%
  mutate(
    # Points per single treatment session (canton-adjusted)
    Punkte_per_session = Punkte * Tpwert,
    
    # Daily total points: n_beh treatments per physio per day
    Punkte_per_day = n_beh * Punkte_per_session,
    
    # Monthly total points: per physio, working WORKING_DAYS_PER_MONTH days
    Punkte_per_month = Punkte_per_day * WORKING_DAYS_PER_MONTH,
    
    # Total monthly for all physios in practice
    Punkte_per_month_practice = Punkte_per_month * n_Physio,
    
    # Annual total points
    Punkte_per_year = Punkte_per_month_practice * 12,
    
    # Base annual revenue (CHF): points converted at POINT_TO_CHF_CONVERSION
    Annual_revenue_base = Punkte_per_year * POINT_TO_CHF_CONVERSION
  )

# Initialize supplement columns
sim_dat$Supplement_points_annual <- 0
sim_dat$Supplement_CHF_annual <- 0

# Add supplements for each practice
for (i in 1:nrow(sim_dat)) {
  supplement_points_annual <- 0
  supplement_chf_annual <- 0
  
  for (j in 1:nrow(zuschlaege)) {
    # Trigger supplement with probability
    if (runif(1) < zuschlaege$Tarif_prob[j]) {
      if (!zuschlaege$Is_annual_CHF[j]) {
        # Point-based supplement: triggered ~60% of working days
        triggered_days <- WORKING_DAYS_PER_MONTH * 12 * 0.6
        supplement_points_annual <- supplement_points_annual +
          zuschlaege$Punkte_value[j] * sim_dat$n_beh[i] * triggered_days *
          sim_dat$Tpwert[i]
      } else {
        # Annual CHF supplement: fixed amount once per year
        supplement_chf_annual <- supplement_chf_annual + zuschlaege$Punkte_value[j]
      }
    }
  }
  
  sim_dat$Supplement_points_annual[i] <- supplement_points_annual
  sim_dat$Supplement_CHF_annual[i] <- supplement_chf_annual
}

# Total annual revenue
sim_dat <- sim_dat %>%
  mutate(
    Annual_revenue_total =
      Annual_revenue_base * POINT_TO_CHF_CONVERSION +
      Supplement_points_annual +
      Supplement_CHF_annual
  )

cat("Revenue calculation complete.\n\n")

# ============================================================================
# 5. EXPLORATORY DATA ANALYSIS
# ============================================================================

cat("=== REVENUE SUMMARY STATISTICS ===\n")
cat("Mean annual revenue:", round(mean(sim_dat$Annual_revenue_total), 2), "CHF\n")
cat("Median annual revenue:", round(median(sim_dat$Annual_revenue_total), 2), "CHF\n")
cat("SD annual revenue:", round(sd(sim_dat$Annual_revenue_total), 2), "CHF\n")
cat("Min:", round(min(sim_dat$Annual_revenue_total), 2), "CHF\n")
cat("Max:", round(max(sim_dat$Annual_revenue_total), 2), "CHF\n\n")

cat("=== ANNUAL REVENUE BY CANTON ===\n")
canton_summary <- sim_dat %>%
  group_by(kanton, Tpwert) %>%
  summarize(
    n_practices = n(),
    mean_revenue = round(mean(Annual_revenue_total), 0),
    median_revenue = round(median(Annual_revenue_total), 0),
    sd_revenue = round(sd(Annual_revenue_total), 0),
    .groups = 'drop'
  ) %>%
  arrange(desc(mean_revenue))
print(canton_summary)

cat("\n=== ANNUAL REVENUE BY TREATMENT TYPE ===\n")
treatment_summary <- sim_dat %>%
  group_by(Behandlung) %>%
  summarize(
    n_practices = n(),
    mean_revenue = round(mean(Annual_revenue_total), 0),
    median_revenue = round(median(Annual_revenue_total), 0),
    .groups = 'drop'
  ) %>%
  arrange(desc(mean_revenue))
print(treatment_summary)

cat("\n=== ANNUAL REVENUE BY NUMBER OF PHYSIOTHERAPISTS ===\n")
physio_summary <- sim_dat %>%
  group_by(n_Physio) %>%
  summarize(
    n_practices = n(),
    mean_revenue = round(mean(Annual_revenue_total), 0),
    median_revenue = round(median(Annual_revenue_total), 0),
    .groups = 'drop'
  )
print(physio_summary)

# ============================================================================
# 6. REGRESSION ANALYSIS
# ============================================================================

cat("\n=== REGRESSION: ANNUAL REVENUE DRIVERS ===\n")

regression_model <- lm(
  Annual_revenue_total ~ n_Physio + n_beh + Tpwert + Punkte + Behandlung,
  data = sim_dat
)

print(summary(regression_model))

cat("\n=== MODEL INTERPRETATION ===\n")
cat("Each additional physiotherapist increases annual revenue by ~",
    round(coef(regression_model)["n_Physio"], 0), "CHF\n")
cat("Each additional daily treatment increases annual revenue by ~",
    round(coef(regression_model)["n_beh"], 0), "CHF\n")
cat("A 0.1-point increase in TPW increases annual revenue by ~",
    round(coef(regression_model)["Tpwert"] * 0.1, 0), "CHF\n")
cat("R-squared:", round(summary(regression_model)$r.squared, 4), "\n\n")

# ============================================================================
# 7. CREATE OUTPUT DIRECTORY & SAVE RESULTS
# ============================================================================

cat("Creating output directory and saving results...\n")

dir.create("outputs", showWarnings = FALSE)
dir.create("outputs/plots", showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 8. VISUALIZATIONS
# ============================================================================

cat("Generating plots...\n")

# Plot 1: Distribution of Annual Revenue
p1 <- ggplot(sim_dat, aes(x = Annual_revenue_total)) +
  geom_histogram(bins = 30, fill = "#2E86AB", alpha = 0.7, color = "black") +
  geom_density(aes(y = after_stat(count)), color = "darkred", size = 1.2) +
  labs(
    title = "Distribution of Annual Revenue",
    subtitle = "Swiss Physiotherapy Practices (n=160)",
    x = "Annual Revenue (CHF)",
    y = "Frequency"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold"))

ggsave("outputs/plots/01_revenue_distribution.png", p1, width = 10, height = 6, dpi = 100)

# Plot 2: Annual Revenue by Canton
p2 <- ggplot(sim_dat, aes(x = reorder(kanton, -Annual_revenue_total, FUN = median),
                          y = Annual_revenue_total, fill = Tpwert)) +
  geom_boxplot(alpha = 0.7) +
  scale_fill_gradient(low = "#FF6B6B", high = "#4ECDC4") +
  labs(
    title = "Annual Revenue by Canton",
    x = "Canton",
    y = "Annual Revenue (CHF)",
    fill = "TPW"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(size = 14, face = "bold")
  )

ggsave("outputs/plots/02_revenue_by_canton.png", p2, width = 12, height = 6, dpi = 100)

# Plot 3: Number of Physios vs. Revenue
p3 <- ggplot(sim_dat, aes(x = n_Physio, y = Annual_revenue_total, color = Tpwert)) +
  geom_point(alpha = 0.6, size = 3) +
  geom_smooth(method = "lm", se = TRUE, color = "darkblue", size = 1.2) +
  scale_color_gradient(low = "#FF6B6B", high = "#4ECDC4") +
  labs(
    title = "Number of Physiotherapists vs. Annual Revenue",
    x = "Number of Physiotherapists",
    y = "Annual Revenue (CHF)",
    color = "TPW"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold"))

ggsave("outputs/plots/03_physios_vs_revenue.png", p3, width = 10, height = 6, dpi = 100)

# Plot 4: Daily Treatments vs. Revenue
p4 <- ggplot(sim_dat, aes(x = n_beh, y = Annual_revenue_total, color = Tpwert)) +
  geom_point(alpha = 0.6, size = 3) +
  geom_smooth(method = "lm", se = TRUE, color = "darkred", size = 1.2) +
  scale_color_gradient(low = "#FF6B6B", high = "#4ECDC4") +
  labs(
    title = "Daily Treatments per Physio vs. Annual Revenue",
    x = "Number of Treatments per Physio per Day",
    y = "Annual Revenue (CHF)",
    color = "TPW"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold"))

ggsave("outputs/plots/04_treatments_vs_revenue.png", p4, width = 10, height = 6, dpi = 100)

# Plot 5: Revenue by Treatment Type
p5 <- ggplot(sim_dat, aes(x = reorder(Behandlung, Annual_revenue_total, FUN = median),
                          y = Annual_revenue_total, fill = Behandlung)) +
  geom_boxplot(alpha = 0.7, show.legend = FALSE) +
  coord_flip() +
  labs(
    title = "Annual Revenue by Treatment Type",
    x = "Treatment Type",
    y = "Annual Revenue (CHF)"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold"))

ggsave("outputs/plots/05_revenue_by_treatment.png", p5, width = 11, height = 6, dpi = 100)

# Plot 6: Sensitivity Analysis
sensitivity_grid <- expand.grid(
  n_Physio = seq(1, 6, by = 1),
  n_beh = seq(8, 20, by = 2)
)

sensitivity_grid$Expected_revenue <- with(sensitivity_grid, {
  Punkte_per_session <- 48 * 1.11
  Punkte_per_day <- n_beh * Punkte_per_session
  Punkte_per_month <- Punkte_per_day * WORKING_DAYS_PER_MONTH
  Punkte_per_month_practice <- Punkte_per_month * n_Physio
  Punkte_per_year <- Punkte_per_month_practice * 12
  Punkte_per_year * POINT_TO_CHF_CONVERSION
})

p6 <- ggplot(sensitivity_grid, aes(x = n_Physio, y = Expected_revenue, color = factor(n_beh))) +
  geom_line(size = 1.2) +
  geom_point(size = 3) +
  labs(
    title = "Sensitivity Analysis: Revenue Under Different Staffing Scenarios",
    x = "Number of Physiotherapists",
    y = "Expected Annual Revenue (CHF)",
    color = "Treatments/Day"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold"))

ggsave("outputs/plots/06_sensitivity_analysis.png", p6, width = 11, height = 6, dpi = 100)

cat("Plots saved to outputs/plots/\n\n")

# ============================================================================
# 9. SAVE RESULTS TO CSV
# ============================================================================

cat("Saving results to CSV files...\n")

# Overall results
overall_results <- data.frame(
  Metric = "Overall",
  n_practices = nrow(sim_dat),
  Mean_annual_revenue = round(mean(sim_dat$Annual_revenue_total), 2),
  Median_annual_revenue = round(median(sim_dat$Annual_revenue_total), 2),
  SD_annual_revenue = round(sd(sim_dat$Annual_revenue_total), 2),
  Min_revenue = round(min(sim_dat$Annual_revenue_total), 2),
  Max_revenue = round(max(sim_dat$Annual_revenue_total), 2),
  stringsAsFactors = FALSE
)
write.csv(overall_results, "outputs/results_overall.csv", row.names = FALSE)

# By canton
canton_results <- canton_summary %>%
  rename(Mean_annual_revenue = mean_revenue, Median_annual_revenue = median_revenue,
         SD_annual_revenue = sd_revenue)
write.csv(canton_results, "outputs/results_by_canton.csv", row.names = FALSE)

# By treatment
treatment_results <- treatment_summary %>%
  rename(Mean_annual_revenue = mean_revenue, Median_annual_revenue = median_revenue)
write.csv(treatment_results, "outputs/results_by_treatment.csv", row.names = FALSE)

# By physios
physio_results <- physio_summary %>%
  rename(Mean_annual_revenue = mean_revenue, Median_annual_revenue = median_revenue)
write.csv(physio_results, "outputs/results_by_physio.csv", row.names = FALSE)

cat("CSV files saved to outputs/\n\n")

# ============================================================================
# 10. FINAL SUMMARY
# ============================================================================

cat("=== SIMULATION COMPLETE ===\n")
cat("Timestamp:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("Practices simulated:", N_PRACTICES, "\n")
cat("Seed:", 42, "\n")
cat("Output directory: ./outputs/\n\n")

cat("FILES GENERATED:\n")
cat("  Plots (6):\n")
cat("    - 01_revenue_distribution.png\n")
cat("    - 02_revenue_by_canton.png\n")
cat("    - 03_physios_vs_revenue.png\n")
cat("    - 04_treatments_vs_revenue.png\n")
cat("    - 05_revenue_by_treatment.png\n")
cat("    - 06_sensitivity_analysis.png\n")
cat("  Results (4 CSV files):\n")
cat("    - results_overall.csv\n")
cat("    - results_by_canton.csv\n")
cat("    - results_by_treatment.csv\n")
cat("    - results_by_physio.csv\n\n")

cat("For detailed analysis and interpretation, see README.md\n\n")
