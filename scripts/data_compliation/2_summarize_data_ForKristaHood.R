
#Summarize storm event load data for all sites

# This is where the data live on Luke's computer.
# You  need to match this to where on your computer the data folder is located
path_to_data <- "P:/0301"

# This is the location on Luke's computer where the figures are made
# Probably should change this to a location where you want your results/figures to go. 
path_to_results <- "C:/Users/lloken/OneDrive - DOI/EOF_SoilHealth"


print(path_to_data)

#load libraries
#not sure which ones are needed for only data summary
library(drake)
library(plyr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(ggfortify)
library(RColorBrewer)
library(viridis)
library(gridExtra)
library(lubridate)
library(corrplot)
library(PerformanceAnalytics)

#custom functions needed

#Calculate water year from posixct or date object
getWY <- function(ts) {
  
  if (class(ts)[1] %in% c('POSIXct', 'POSIXt')) {
    ts <- as.Date(ts, tz=attributes(ts)$tzone)
  } else if (class(ts)[1] %in% c('Date')) {
    
  } else {
    stop("input term is not class Date or POSIXct")
  }
  
  year <- year(ts)
  add_one <- rep(0, length(year))
  add_one[which(month(ts)>=10)] <- 1  
  
  WY <- year +  add_one
  
  return(WY)
  
}


# function to extract legend from gg object
g_legend<-function(a.gplot){
  tmp <- ggplot_gtable(ggplot_build(a.gplot))
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
  legend <- tmp$grobs[[leg]]
  return(legend)}


#Load the rds file from the P drive
#This file was created using the "1_load_all_data.R" script
data_df <- readRDS(file=(file_in(file.path(path_to_data, "compiled_data", "storm_event_loads", "storm_event_loads_allsites.rds" ))))


#Test to make sure data are loaded
if (exists("data_df")){
  print("Object data_df exists. Great job!!! You may proceed")
} else {
  stop ("no data loaded into R environment. Check 1_load_all_data.R script and path_to_data")
}

#Identify load variables
loadvars <- c('suspended_sediment_load_pounds', 
              'chloride_load_pounds',
              'no2_no3n_load_pounds', 
              'ammonium_n_load_pounds',
              'tkn_unfiltered_load_pounds', 
              'orthophosphate_load_pounds',
              'tp_unfiltered_load_pounds',
              'total_nitrogen_load_pounds',
              'organic_nitrogen_load_pounds',
              'toc_load_pounds',
              'doc_load_pounds')

#Identify concentration variables
concvars <- c('suspended_sediment_conc_mgL', 
              'chloride_conc_mgL',
              'no2_no3n_conc_mgL', 
              'ammonium_n_conc_mgL',
              'tkn_unfiltered_conc_mgL', 
              'orthophosphate_conc_mgL',
              'tp_unfiltered_conc_mgL',
              'total_nitrogen_conc_mgL',
              'organic_nitrogen_conc_mgL',
              'toc_conc_mgL',
              'doc_conc_mgL')

#Identify rain variables
rainvars <-c("rain", "duration", "Ievent", "I5", "I10", "I15", "I30", "I60",
             "energy_m1", "erosivity_m1", "energy_m2", "erosivity_m2")

# Calculate storm mid date. 
# Remove other date time objects
data_df2 <- data_df %>%
  mutate(site = as.character(site),
         storm_middate = storm_start + difftime(storm_end, storm_start, units='secs')/2) %>%
  mutate(wateryear = as.factor(getWY (storm_middate))) %>%
  select(-file_id, -unique_storm_number, -sub_storms, -rain_startdate, -rain_enddate, -storm_start, -storm_end, -sample_end, -sample_start, -ant_discharge_date)

# constants for converstions from load (pounds) and volume (cf) to concentration (mg/L)
# 453592 mg per pound
# 28.3168 Liters per cubic foot

#Calculate concentration (mg per L) from load (pounds) and runoff volume (cf)
conc_df <- data.frame(sapply(data_df2[,loadvars], function (x) x/data_df2$runoff_volume*453592/28.3168))
colnames(conc_df) <- concvars

#Bind concentration data frame to bigger data frame
data_df3 <- bind_cols(data_df2, conc_df)

#Create two r objects for frozen and non-frozen periods
data_df4 <-filter(data_df3, frozen==FALSE)

data_df5 <-filter(data_df3, frozen==TRUE)

#Calculate means for all variables by site, wateryear, and period (before/after) treatment
data_wateryear_summary <- data_df2 %>%
  group_by (site, wateryear, period) %>%
  select(-storm_middate) %>%
  filter(frozen == FALSE) %>% 
  summarize_all(mean, na.rm=T)


data_wateryear_summary


#Save RDS file (R file)
# This will save the file within the path_to_results/data_summary folder. 
saveRDS(data_wateryear_summary, file=(file_out(file.path(path_to_results, "data_summary", "annual_loads_allsites.rds" ))))

#Also can save a csv file if you prefer
write.csv(data_wateryear_summary, file=(file_out(file.path(path_to_results, "data_summary", "annual_loads_allsites.csv" ))), row.names = F)




# From here you can change the group_by columns to select how to perform summary
# select is how to include or exclude (-) columns by name
# filter is how to make the data frame shorter by including certain cases (frozen/non frozen)
# summarize(), summarize_all(), summarize_at() can include a variety of additional metrics
# Medians, means, sum, etc. 





#########################################
# playing with plotting
# this will go to its own script later
#########################################


library(ggpubr)

ggplot(data=data_df2, aes_string(x="sum_runoff", y=loadvars[1], group="wateryear", color="wateryear")) +
  geom_point() +
  stat_smooth(method = "lm", se=F) +
  facet_wrap(~site, scales='free') +
  theme_bw()


LoadByRunnoff_plotlist <- list()

var_i <- 11
for (var_i in 1:length(loadvars)){
  
  LoadByRunnoff_plotlist[[var_i]] <- ggplot(data=data_df2, aes_string(x="sum_runoff", y=loadvars[var_i], group="wateryear", color="wateryear", fill="wateryear")) +
  scale_x_log10() +
  scale_y_log10() +
  geom_point(aes(shape=frozen), size=2) +
  scale_shape_manual(values=c(16, 1))+
  stat_smooth(method = "lm", se=T, alpha=.1) +
  facet_wrap(~site, scales='free') +
  theme_bw() +
  theme(legend.position = 'bottom') +
  guides(color = guide_legend(nrow = 1)) +
  labs(x = "Runoff volume (cubic feet per storm)")

print(LoadByRunnoff_plotlist[[var_i]])

ggsave(file_out(file.path(path_to_results, "Figures", "Loads", paste0(loadvars[var_i], "ByRunoff_plot.png"))), LoadByRunnoff_plotlist[[var_i]], height=8, width=12, units = 'in', dpi=320)

}


ConcByRunnoff_plotlist<-list()
var_i <- 1
for (var_i in 1:length(concvars)){
  
  ConcByRunnoff_plotlist[[var_i]] <- ggplot(data=data_df3, aes_string(x="sum_runoff", y=concvars[var_i], group="wateryear", color="wateryear", fill="wateryear")) +
    scale_x_log10() +
    # scale_y_log10() +
    geom_point(aes(shape=frozen), size=2) +
    scale_shape_manual(values=c(16, 1))+
    stat_smooth(method = "lm", se=T, alpha=.1) +
    facet_wrap(~site, scales='free') +
    theme_bw() +
    theme(legend.position = 'bottom') +
    guides(color = guide_legend(nrow = 1)) +
    labs(x = "Runoff volume (cubic feet per storm)")
  
  print(ConcByRunnoff_plotlist[[var_i]])
  
  ggsave(file_out(file.path(path_to_results, "Figures", "Conc", paste0(concvars[var_i], "ByRunoff_plot.png"))), ConcByRunnoff_plotlist[[var_i]], height=8, width=12, units = 'in', dpi=320)
  
}


ConcByRunnoff_log_plotlist<-list()
var_i <- 1
for (var_i in 1:length(concvars)){
  
  ConcByRunnoff_log_plotlist[[var_i]] <- ggplot(data=data_df3, aes_string(x="sum_runoff", y=concvars[var_i], group="wateryear", color="wateryear", fill="wateryear")) +
    scale_x_log10() +
    scale_y_log10() +
    geom_point(aes(shape=frozen), size=2) +
    scale_shape_manual(values=c(16, 1))+
    stat_smooth(method = "lm", se=T, alpha=.1) +
    facet_wrap(~site, scales='free') +
    theme_bw() +
    theme(legend.position = 'bottom') +
    guides(color = guide_legend(nrow = 1)) +
    labs(x = "Runoff volume (cubic feet per storm)")
  
  print(ConcByRunnoff_log_plotlist[[var_i]])
  
  ggsave(file_out(file.path(path_to_results, "Figures", "Conc", paste0(concvars[var_i], "ByRunoff_log_plot.png"))), ConcByRunnoff_log_plotlist[[var_i]], height=8, width=12, units = 'in', dpi=320)
  
}

RainByRunnoff_plotlist <- list()

var_i <- 1
for (var_i in 1:length(rainvars)){
  
  RainByRunnoff_plotlist[[var_i]] <- ggplot(data=data_df2, aes_string(x="sum_runoff", y=rainvars[var_i], group="wateryear", color="wateryear", fill="wateryear")) +
    scale_x_log10() +
    scale_y_log10() +
    geom_point(aes(shape=frozen), size=2) +
    scale_shape_manual(values=c(16, 1))+
    stat_smooth(method = "lm", se=T, alpha=.1) +
    facet_wrap(~site, scales='free') +
    theme_bw() +
    theme(legend.position = 'bottom') +
    guides(color = guide_legend(nrow = 1)) +
    labs(x = "Runoff volume (cubic feet per storm)")
  
  print(RainByRunnoff_plotlist[[var_i]])
  
  ggsave(file_out(file.path(path_to_results, "Figures", "Rain", paste0(rainvars[var_i], "ByRunoff_plot.png"))), RainByRunnoff_plotlist[[var_i]], height=8, width=12, units = 'in', dpi=320)
  
}

#############
# Boxplots
##############



ConcByYear_boxlist<-list()
var_i <- 1
for (var_i in 1:length(concvars)){
  
  ConcByYear_boxlist[[var_i]] <- ggplot(data=data_df3, aes_string(x="wateryear", y=concvars[var_i], group="wateryear", color="wateryear", fill="wateryear")) +
    scale_y_log10() +
    geom_jitter(width = .1, size=1, alpha=.5, shape=16) + 
    geom_boxplot(alpha=0.2, outlier.shape = NA) +
    # scale_shape_manual(values=c(16, 1))+
    # stat_smooth(method = "lm", se=T, alpha=.1) +
    facet_wrap(~site, scales='free_y') +
    theme_bw() +
    theme(legend.position = 'bottom') +
    guides(color = guide_legend(nrow = 1)) +
    labs(x = "Water year") +
    theme(axis.text=element_text(size=8)) +
    ggtitle('All runoff events') +
    theme(plot.title = element_text(hjust = 0.5))
  
  print(ConcByYear_boxlist[[var_i]])
  
  ggsave(file_out(file.path(path_to_results, "Figures", "Boxplots", paste0(concvars[var_i], "ByYear_boxplot.png"))), ConcByYear_boxlist[[var_i]], height=8, width=12, units = 'in', dpi=320)
  
}



ConcByYear_nonFrozen_boxlist<-list()
var_i <- 1
for (var_i in 1:length(concvars)){
  
  ConcByYear_nonFrozen_boxlist[[var_i]] <- ggplot(data=data_df4, aes_string(x="wateryear", y=concvars[var_i], group="wateryear", color="wateryear", fill="wateryear")) +
    scale_y_log10() +
    geom_jitter(width = .1, size=1, alpha=.5, shape=16) + 
    geom_boxplot(alpha=0.2, outlier.shape = NA) +
    # scale_shape_manual(values=c(16, 1))+
    # stat_smooth(method = "lm", se=T, alpha=.1) +
    facet_wrap(~site, scales='free_y') +
    theme_bw() +
    theme(legend.position = 'bottom') +
    guides(color = guide_legend(nrow = 1)) +
    labs(x = "Water year") +
    theme(axis.text=element_text(size=8)) +
    ggtitle('Non-frozen runoff events') +
    theme(plot.title = element_text(hjust = 0.5))
  
  print(ConcByYear_nonFrozen_boxlist[[var_i]])
  
  ggsave(file_out(file.path(path_to_results, "Figures", "Boxplots", paste0(concvars[var_i], "ByYear_nonFrozen_boxplot.png"))), ConcByYear_nonFrozen_boxlist[[var_i]], height=8, width=12, units = 'in', dpi=320)
  
}



ConcByYear_Frozen_boxlist<-list()
var_i <- 1
for (var_i in 1:length(concvars)){
  
  ConcByYear_Frozen_boxlist[[var_i]] <- ggplot(data=data_df5, aes_string(x="wateryear", y=concvars[var_i], group="wateryear", color="wateryear", fill="wateryear")) +
    scale_y_log10() +
    geom_jitter(width = .1, size=1, alpha=.5, shape=16) + 
    geom_boxplot(alpha=0.2, outlier.shape = NA) +
    # scale_shape_manual(values=c(16, 1))+
    # stat_smooth(method = "lm", se=T, alpha=.1) +
    facet_wrap(~site, scales='free_y') +
    theme_bw() +
    theme(legend.position = 'bottom') +
    guides(color = guide_legend(nrow = 1)) +
    labs(x = "Water year") +
    theme(axis.text=element_text(size=8)) +
    ggtitle('Frozen runoff events') +
    theme(plot.title = element_text(hjust = 0.5))
  
  print(ConcByYear_Frozen_boxlist[[var_i]])
  
  ggsave(file_out(file.path(path_to_results, "Figures", "Boxplots", paste0(concvars[var_i], "ByYear_Frozen_boxplot.png"))), ConcByYear_Frozen_boxlist[[var_i]], height=8, width=12, units = 'in', dpi=320)
  
}



#Rain
RainByYear_boxlist<-list()
var_i <- 1
for (var_i in 1:length(rainvars)){
    
  
  RainByYear_boxlist[[var_i]] <- ggplot(data=data_df3, aes_string(x="wateryear", y=rainvars[var_i], group="wateryear", color="wateryear", fill="wateryear")) +
    # scale_y_log10() +
    geom_jitter(width = .1, size=1, alpha=.5, shape=16) + 
    geom_boxplot(alpha=0.2, outlier.shape = NA) +
    # scale_shape_manual(values=c(16, 1))+
    # stat_smooth(method = "lm", se=T, alpha=.1) +
    facet_wrap(~site, scales='free_y') +
    theme_bw() +
    theme(legend.position = 'bottom') +
    guides(color = guide_legend(nrow = 1)) +
    labs(x = "Water year") +
    theme(axis.text=element_text(size=8)) +
    ggtitle('All runoff events') +
    theme(plot.title = element_text(hjust = 0.5))
  
  print(RainByYear_boxlist[[var_i]])
  
  ggsave(file_out(file.path(path_to_results, "Figures", "Rain_Boxplots", paste0(rainvars[var_i], "ByYear_boxplot.png"))), RainByYear_boxlist[[var_i]], height=8, width=12, units = 'in', dpi=320)
  
}


RunoffByYear_box <- ggplot(data=data_df3, aes_string(x="wateryear", y="sum_runoff", group="wateryear", color="wateryear", fill="wateryear")) +
  scale_y_log10() +
  geom_jitter(width = .1, size=1, alpha=.5, shape=16) + 
  geom_boxplot(alpha=0.2, outlier.shape = NA) +
  # scale_shape_manual(values=c(16, 1))+
  # stat_smooth(method = "lm", se=T, alpha=.1) +
  facet_wrap(~site, scales='free_y') +
  theme_bw() +
  theme(legend.position = 'bottom') +
  guides(color = guide_legend(nrow = 1)) +
  labs(x = "Water year") +
  theme(axis.text=element_text(size=8)) +
  ggtitle('All runoff events') +
  theme(plot.title = element_text(hjust = 0.5))

print(RunoffByYear_box)

ggsave(file_out(file.path(path_to_results, "Figures", "Rain_Boxplots", paste0("sum_runoff", "ByYear_boxplot.png"))), RunoffByYear_box, height=8, width=12, units = 'in', dpi=320)


# ggsave(file_out(file.path(path_to_results, "Figures", "TPLoadByRunoff_plot.png")), TPLoadByRunoff_plot, height=8, width=12, units = 'in', dpi=320)


ggplot(data=data_df2, aes_string(x="rain", y=loadvars[7], group="wateryear", color="wateryear")) +
  geom_point(aes(shape=frozen), size=2) +
  scale_shape_manual(values=c(16, 1))+
  stat_smooth(method = "lm", se=T, alpha=.1, aes(fill=wateryear)) +
  facet_wrap(~site, scales='free') +
  theme_bw() +
  theme(legend.position = 'bottom') +
  guides(color = guide_legend(nrow = 1)) +
  labs(x = "rain (inches)")


ggplot(data=data_df2, aes_string(x="rain", y=loadvars[7], group="period", color="period")) +
  geom_point(aes(shape=frozen), size=2) +
  scale_shape_manual(values=c(16, 1))+
  stat_smooth(method = "lm", se=T, alpha=.1, aes(fill=period)) +
  facet_wrap(~site, scales='free') +
  theme_bw() +
  theme(legend.position = 'bottom') +
  guides(color = guide_legend(nrow = 1)) +
  labs(x = "rain (inches)")
