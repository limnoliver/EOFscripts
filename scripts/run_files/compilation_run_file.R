

# Work flow for data compilation and cross-site analysis

#load functions
source('scripts/functions/fxns_data_compilation.R')
source('scripts/functions/g_legend.R')

#load all surface water data
#output is a data.frame named "data_df"
source('scripts/data_compliation/1_load_all_data.R')

#summarize water quality data
#Currently makes lots of figures
source('scripts/data_compliation/2_summarize_data.R')

#load soil data
# as of January 2020, this only includes spring 2016 and fall 2017 data

# source('scripts/3_load_soil_data.R')