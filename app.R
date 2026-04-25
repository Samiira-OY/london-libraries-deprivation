# ============================================================
# app.R — Libraries & Deprivation (Greater London)



# 1) PACKAGES

library(shiny)
library(sf)
library(dplyr)
library(leaflet)
library(ggplot2)
library(htmltools)
library(viridisLite)


# 2) LOAD DATA (FROM .RDS)
# ---------------------------
lsoa <- readRDS("lsoa_london_data.rds")              # polygons (LSOAs)
libs <- readRDS("libraries_points_london.rds")       # points (libraries)



# 3) PREP DATA 

# Leaflet needs lon/lat
lsoa <- st_transform(lsoa, 4326)
libs <- st_transform(libs, 4326)

# Make sure key variables available
lsoa <- lsoa %>%
  mutate(
    imd_decile = as.integer(`Index of Multiple Deprivation (IMD) Decile`),
    library_count = as.integer(library_count)
  )

# Join IMD onto library points so points can be filtered by IMD slider
libs <- libs %>%
  left_join(
    lsoa %>% st_drop_geometry() %>% select(LSOA11CD, imd_decile),
    by = "LSOA11CD"
  )

# Colour palettes (global)
pal_imd <- colorFactor(palette = rev(magma(10)), domain = 1:10, na.color = "#BDBDBD")
pal_lib <- colorNumeric(palette = plasma(256), domain = c(0, 10), na.color = "#BDBDBD")


# 4) UI

ui <- fluidPage(
  titlePanel("Public Libraries and Deprivation in Greater London"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput(
        "map_var", "Select variable to map:",
        choices = c("Library count per LSOA" = "library_count",
                    "IMD decile" = "imd_decile")
      ),
      
      sliderInput(
        "imd_range", "Select IMD decile range:",
        min = 1, max = 10, value = c(1, 10), step = 1
      ),
      
      checkboxInput("show_libs", "Show library locations", TRUE),
      checkboxInput("cluster", "Cluster library points", TRUE)
    ),
    
    mainPanel(
      leafletOutput("map", height = 600),
      br(),
      fluidRow(
        column(6, plotOutput("boxplot", height = 300)),
        column(6, plotOutput("barchart", height = 300))
      )
    )
  )
)

# 5) SERVER 

server <- function(input, output, session) {
  
  # A) Filter polygons by IMD slider
  lsoa_filtered <- reactive({
    lsoa %>%
      filter(!is.na(imd_decile)) %>%
      filter(imd_decile >= input$imd_range[1],
             imd_decile <= input$imd_range[2])
  })
  
  # B) Filter library points by IMD slider
  libs_filtered <- reactive({
    libs %>%
      filter(!is.na(imd_decile)) %>%
      filter(imd_decile >= input$imd_range[1],
             imd_decile <= input$imd_range[2])
  })
  
  # MAP

  output$map <- renderLeaflet({
    poly <- lsoa_filtered()
    
    # Popup for polygons (simple & readable)
    popup_txt <- paste0(
      "<b>LSOA:</b> ", poly$LSOA11NM, "<br/>",
      "<b>IMD decile:</b> ", poly$imd_decile, "<br/>",
      "<b>Libraries:</b> ", ifelse(is.na(poly$library_count), 0, poly$library_count)
    ) %>% lapply(HTML)
    
    # Decide colouring depending on dropdown choice
    if (input$map_var == "imd_decile") {
      fill_col <- pal_imd(poly$imd_decile)
      legend_title <- "IMD decile (1=most deprived)"
    } else {
      # cap at 10 for colour only (stops legend being dominated by outliers)
      fill_col <- pal_lib(pmin(poly$library_count, 10))
      legend_title <- "Libraries (capped at 10)"
    }
    
    m <- leaflet(poly) %>%
      addProviderTiles("CartoDB.Positron") %>%
      addPolygons(
        fillColor = fill_col,
        fillOpacity = 0.6,
        color = "#FFFFFF", weight = 0.35, opacity = 0.7,
        popup = popup_txt
      )
    
    # Add library points (high-contrast)
    if (input$show_libs) {
      pts <- libs_filtered()
      cluster_opts <- if (input$cluster) markerClusterOptions() else NULL
      
      m <- m %>%
        addCircleMarkers(
          data = pts,
          radius = 4,
          stroke = TRUE, color = "black", weight = 1,
          fillColor = "#00AEEF", fillOpacity = 0.95,
          clusterOptions = cluster_opts
        )
    }
    
    # Add legend
    if (input$map_var == "imd_decile") {
      m %>% addLegend("topright", pal = pal_imd, values = 1:10, title = legend_title)
    } else {
      m %>% addLegend("topright", pal = pal_lib, values = c(0, 10), title = legend_title)
    }
  })
  

  # PLOT 1: BOXPLOT

  output$boxplot <- renderPlot({
    df <- lsoa_filtered() %>% st_drop_geometry()
    
    ggplot(df, aes(x = factor(imd_decile), y = library_count)) +
      geom_boxplot(outlier.alpha = 0.15) +
      stat_summary(fun = mean, geom = "point", color = "red", size = 2) +
      labs(
        title = "Libraries per LSOA by IMD decile",
        x = "IMD decile (1 = most deprived)",
        y = "Libraries per LSOA"
      ) +
      theme_minimal()
  })
  

  # PLOT 2: MEAN BAR CHART

  output$barchart <- renderPlot({
    df <- lsoa_filtered() %>%
      st_drop_geometry() %>%
      group_by(imd_decile) %>%
      summarise(mean_libs = mean(library_count, na.rm = TRUE), .groups = "drop")
    
    ggplot(df, aes(x = factor(imd_decile), y = mean_libs)) +
      geom_col(alpha = 0.85) +
      labs(
        title = "Average libraries per LSOA (by IMD decile)",
        x = "IMD decile (1 = most deprived)",
        y = "Mean libraries per LSOA"
      ) +
      theme_minimal()
  })
}

shinyApp(ui, server)