
# RSCRIPT — Libraries vs Deprivation (London)

# ---- Clean session ----
rm(list = ls())
cat("\014")  # clears console in RStudio

# load Packages
# If needed: install.packages("pacman")
pacman::p_load(
  sf, dplyr, ggplot2, viridis, leaflet, gt
)

# Files (check to be in working directory) ----
LSOA_RDS <- "lsoa_london_data.rds"
LIBS_RDS <- "libraries_points_london.rds"

if (!file.exists(LSOA_RDS)) stop("Missing file: ", LSOA_RDS)
if (!file.exists(LIBS_RDS)) stop("Missing file: ", LIBS_RDS)


# 1) LOAD FINAL DATASETS

lsoa_london_data <- readRDS(LSOA_RDS)              # polygons (LSOA) + IMD + library_count
libraries_points_london <- readRDS(LIBS_RDS)       # library points (already London-only)

# Quick checks (safe + helpful)
stopifnot(inherits(lsoa_london_data, "sf"))
stopifnot(inherits(libraries_points_london, "sf"))
stopifnot("LSOA11CD" %in% names(lsoa_london_data))
stopifnot("library_count" %in% names(lsoa_london_data))


# 2) COUNTS (for reporting)

n_lsoa <- nrow(lsoa_london_data)
n_libs <- nrow(libraries_points_london)

cat("LSOAs in dataset:", n_lsoa, "\n")
cat("Libraries in dataset:", n_libs, "\n")


# 3) DATASET SUMMARY TABLE 

dataset_summary <- data.frame(
  Item = c(
    "Number of observations",
    "Unit of analysis",
    "Spatial coverage",
    "Time period",
    "Data sources"
  ),
  Description = c(
    n_lsoa,
    "Lower Super Output Area (LSOA, 2011)",
    "Greater London",
    "IMD 2019; OpenStreetMap (accessed 2024)",
    "OpenStreetMap (libraries), IMD 2019 (ONS)"
  )
)

dataset_summary_gt <- dataset_summary %>%
  gt::gt() %>%
  gt::tab_header(
    title = "Exhaustive dataset overview",
    subtitle = "Final analytical dataset (loaded from .rds)"
  ) %>%
  gt::cols_label(
    Item = "Item",
    Description = "Description"
  )

# Print table
dataset_summary_gt


# 4) VARIABLES TABLE 

# I Picked variables mostly used and referred to
vars <- c("LSOA11CD",
          "library_count",
          "Index of Multiple Deprivation (IMD) Rank",
          "Index of Multiple Deprivation (IMD) Decile",
          "geometry")

present_vars <- vars[vars %in% names(lsoa_london_data)]

variables_table <- data.frame(
  Variable = present_vars,
  Description = c(
    "Unique identifier for each LSOA",
    "Number of libraries in the LSOA",
    "National deprivation rank (lower = more deprived)",
    "Deprivation decile (1 = most deprived, 10 = least deprived)",
    "LSOA boundary polygon geometry"
  )[match(present_vars, vars)],
  Data_type = sapply(present_vars, function(v) class(lsoa_london_data[[v]])[1])
)

variables_table_gt <- variables_table %>%
  gt::gt() %>%
  gt::tab_header(
    title = "Variables used in analysis",
    subtitle = "Key columns in lsoa_london_data"
  ) %>%
  gt::cols_label(
    Variable = "Variable",
    Description = "Description",
    Data_type = "Type"
  )

variables_table_gt


# 5)  PLOTS in shinyapp

CAP <- 10

# Map 1: library_count (capped)
p_libs <- ggplot(lsoa_london_data) +
  geom_sf(aes(fill = pmin(library_count, CAP)), colour = "grey40", linewidth = 0.05) +
  scale_fill_viridis_c(option = "plasma", name = paste0("Libraries\n(capped ", CAP, ")")) +
  labs(
    title = "Public libraries per LSOA (Greater London)",
    subtitle = "Counts are capped for readability"
  ) +
  theme_void()

# Map 2: IMD decile (if available)
if ("imd_decile" %in% names(lsoa_london_data)) {
  lsoa_london_data$imd_decile <- as.factor(lsoa_london_data$imd_decile)
}

p_imd <- ggplot(lsoa_london_data) +
  geom_sf(
    aes(fill = `Index of Multiple Deprivation (IMD) Decile`),
    colour = "grey40", linewidth = 0.05
  ) +
  scale_fill_viridis_d(option = "magma", direction = -1,
                       na.value = "grey90",
                       name = "IMD decile\n(1 = most deprived)") +
  labs(
    title = "Deprivation by LSOA (Greater London)",
    subtitle = "IMD 2019 deciles"
  ) +
  theme_void()

# Plot 3: libraries by IMD decile (boxplot)
p_rel <- lsoa_london_data %>%
  sf::st_drop_geometry() %>%
  dplyr::filter(!is.na(`Index of Multiple Deprivation (IMD) Decile`)) %>%
  ggplot(aes(
    x = as.factor(`Index of Multiple Deprivation (IMD) Decile`),
    y = library_count
  )) +
  geom_boxplot(outlier.alpha = 0.15) +
  stat_summary(fun = mean, geom = "point", colour = "red", size = 2) +
  labs(
    title = "Libraries per LSOA by deprivation level",
    subtitle = "Red dots show the mean",
    x = "IMD decile (1 = most deprived)",
    y = "Libraries per LSOA"
  ) +
  theme_minimal()

# Print plots (comment out any you don’t need)
print(p_libs)
print(p_imd)
print(p_rel)


# 6) LEAFLET MAP (interactive for shinyapp

# Leaflet needs lon/lat
lsoa_leaf <- st_transform(lsoa_london_data, 4326)
libs_leaf <- st_transform(libraries_points_london, 4326)

popup_txt <- paste0(
  "<b>LSOA:</b> ", lsoa_leaf$LSOA11CD,
  "<br><b>IMD decile:</b> ", lsoa_leaf$`Index of Multiple Deprivation (IMD) Decile`,
  "<br><b>Libraries:</b> ", lsoa_leaf$library_count
)

leaflet() %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    data = lsoa_leaf,
    fillColor = ~viridis::viridis(
      10, option = "magma", direction = -1
    )[as.integer(as.factor(`Index of Multiple Deprivation (IMD) Decile`))],
    fillOpacity = 0.65,
    color = "#444444", weight = 0.4,
    popup = popup_txt
  ) %>%
  addCircleMarkers(
    data = libs_leaf,
    radius = 2,
    stroke = FALSE,
    fillOpacity = 0.5,
    clusterOptions = markerClusterOptions()
  )

saveRDS(lsoa_london_data, "lsoa_london_data.rds")
saveRDS(libraries_lsoa_clean, "libraries_points_london.rds")

