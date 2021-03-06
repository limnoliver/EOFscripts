

# Master file for running all cross-site comparisons

# path_to_data <- "M:/NonPoint Evaluation/GLRI Edge-of-field/R-analysis"
path_to_data <- "P:/0301"
path_to_results <- "C:/Users/lloken/OneDrive - DOI/EOF_SoilHealth"

#load libraries
library(drake)
library(plyr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(grid)
library(ggfortify)
library(ggpubr)
library(RColorBrewer)
library(viridis)
library(gridExtra)
library(lubridate)
library(corrplot)
library(PerformanceAnalytics)



source('scripts/run_files/compilation_run_file.R')
