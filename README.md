# London Libraries & Deprivation

**Spatial analysis of public library access and socioeconomic deprivation across Greater London**

This project investigates whether public library provision is equitably distributed across London neighbourhoods, using open data on library locations and the Index of Multiple Deprivation (IMD). The analysis operates at Lower Super Output Area (LSOA) level — covering 4,835 neighbourhoods across Greater London — and combines static choropleth mapping with an interactive Leaflet dashboard.

---

## 🔗 Live Interactive Dashboard

**[→ Explore the dashboard here](https://samiirayusuf.shinyapps.io/London-libraries-IMD-SHINYAPP/)**

Click through London's neighbourhoods to explore library provision and deprivation levels interactively — filter by IMD decile, click LSOAs for details, and toggle library locations across the map.

---

## Key Findings

- Library provision is **uneven across London**, with some LSOAs containing multiple libraries while many — particularly in outer boroughs — have none.
- There is **no simple relationship** between deprivation and library count: some highly deprived LSOAs are well-served, while others are not — suggesting that provision reflects historical placement rather than current need.
- The interactive dashboard allows exploration of this pattern across deprivation deciles, supporting more nuanced, area-specific conclusions than borough-level averages allow.

---

## Data Sources

| Dataset | Source | Year |
|---|---|---|
| Public library locations | OpenStreetMap (via Overpass API) | Accessed 2024 |
| LSOA boundary polygons | Office for National Statistics (ONS) | 2011 |
| Index of Multiple Deprivation (IMD) | Ministry of Housing, Communities & Local Government | 2019 |

> **Note:** Raw boundary files (.geojson) are not included in this repository due to file size. LSOA boundaries can be downloaded from the [ONS Open Geography Portal](https://geoportal.statistics.gov.uk/). The processed analytical datasets are included and can be loaded directly to reproduce all outputs.

---

## Repository Structure
