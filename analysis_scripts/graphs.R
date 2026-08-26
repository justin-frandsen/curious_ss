#make sure the data from main.R is loaded in already.
source("E1.R")

library(ggeffects)
library(gghalves)

# graphing variables
dodge_width = 0.1
lineSize = .71
palatte_num = 7
nudge = .07

nicelimits <- function(x) {
  range(scales::extended_breaks(only.loose = TRUE)(x))
}
# Compute within-subjects summary stats
rt_summary_within <- Rmisc::summarySEwithin(
  data = bx_rt_summary, 
  measurevar = "meanRT", 
  withinvars = c("LocationProb", "phase"), 
  idvar = "sub_num", # your subject column
  na.rm = TRUE
)

ggplot(bx_rt_summary,
       aes(x = phase, y = meanRT)) +
  geom_half_violin(aes(fill = LocationProb),
                   side = "l", 
                   data = subset(bx_rt_summary, LocationProb == "Valid"),
                   alpha = 0.6,
                   position = position_nudge(x = -nudge))+  # move left) +
  geom_half_violin(aes(fill = LocationProb),
                   side = "r", 
                   data = subset(bx_rt_summary, LocationProb == "Invalid"),
                   alpha = 0.6,
                   position = position_nudge(x = nudge))+  # move right) +
  # Means + CIs (from your within-sub summary statistics)
  geom_point(data = rt_summary_within,
             aes(shape = LocationProb, color = LocationProb),
             size = 3, 
             position = position_nudge(x = 0)) +
  geom_errorbar(data = rt_summary_within,
                aes(color = LocationProb,
                    ymin = meanRT - ci,
                    ymax = meanRT + ci),
                width = 0.1,
                position = position_nudge(x = 0)) +
  stat_summary(fun = mean,
               geom = "line",   #graph lines
               na.rm = T,
               position = position_dodge(width = 0),
               aes(group = LocationProb, color = LocationProb))+
  labs(x = "Phase",
       y = "Mean Response Time (ms)",
       fill = "LocationProb",
       color = "LocationProb") +
  theme_classic()+
  scale_y_continuous(breaks = seq(0,4000, by = 100),
                     limits = nicelimits)+
  scale_fill_brewer(type = "qual", palette = palatte_num)+
  scale_color_brewer(type = "qual", palette = palatte_num)
#coord_flip()

fixation_summary_within <- Rmisc::summarySEwithin(
  data = fixation_summary, 
  measurevar = "mean_target_first_fix", 
  withinvars = c("LocationProb", "phase"), 
  idvar = "sub_num", # your subject column
  na.rm = TRUE)


fixation_summary %>% 
  ggplot(aes(x = phase, y = mean_target_first_fix)) +
  # Half violins
  geom_half_violin(aes(fill = LocationProb),
                   side = "l", 
                   data = subset(fixation_summary, LocationProb == "Valid"),
                   alpha = 0.6,
                   position = position_nudge(x = -nudge)) +
  geom_half_violin(aes(fill = LocationProb),
                   side = "r", 
                   data = subset(fixation_summary, LocationProb == "Invalid"),
                   alpha = 0.6,
                   position = position_nudge(x = nudge)) +
  # Means + CIs (from your within-sub summary statistics)
  geom_point(data = fixation_summary_within,
             aes(color = LocationProb, shape = LocationProb),
             size = 3, position = position_nudge(x = 0)) +
  geom_errorbar(data = fixation_summary_within,
                aes(color = LocationProb,
                    ymin = mean_target_first_fix - ci,
                    ymax = mean_target_first_fix + ci),
                width = 0.1,
                position = position_nudge(x = 0)) +
  stat_summary(fun = mean,
               geom = "line",   #graph lines
               na.rm = T,
               position = position_dodge(width = 0),
               aes(group = LocationProb, color = LocationProb))+
  labs(x = "Phase",
       y = "Pecentage of first Fixation",
       fill = "LocationProb",
       color = "LocationProb") +
  scale_y_continuous(labels = scales::percent,
                     breaks = seq(0,1, by = .05),
                     limits = nicelimits)+
  scale_fill_brewer(type = "qual", palette = palatte_num)+
  scale_color_brewer(type = "qual", palette = palatte_num)+
  theme_classic()

response_time_violin <- bx_rt_summary %>% 
  ggplot(aes(y=meanRT, x = LocationProb, fill = phase))+
  geom_violin()+
  stat_summary(fun = mean, 
               geom = "point", 
               shape = 18, 
               size = 4, 
               color = "black")+
  geom_errorbar(data = rt_summary_within,
                aes(ymin = meanRT - ci,
                    ymax = meanRT + ci),
                width = 0.1,
                position = position_nudge(x = 0)) +
  ylab("Response Time (ms)")+
  facet_grid(~phase)+
  scale_fill_brewer(
    type = "qual",
    palette = palatte_num,
    name = "Location Probability",
    labels = c("High", "Low")
  )+
  theme_classic()+
  scale_y_continuous(limits = nicelimits)
response_time_violin

fixation_proportion_violin <- fixation_summary %>% 
  ggplot(aes(y=mean_target_first_fix, x = LocationProb, fill = phase))+
  geom_violin()+
  stat_summary(fun = mean, 
               geom = "point", 
               shape = 18, 
               size = 4, 
               color = "black")+
  geom_errorbar(data = fixation_summary_within,
                aes(ymin = mean_target_first_fix - ci,
                    ymax = mean_target_first_fix + ci),
                width = 0.1,
                position = position_nudge(x = 0)) +
  ylab("Proportion of first fixation")+
  facet_grid(~phase)+
  scale_fill_brewer(type = "qual",
                    palette = palatte_num,
                    name = "Location Probability",
                    labels = c("High", "Low"))+
  theme_classic()+
  scale_y_continuous(labels = scales::percent,
                     breaks = seq(.10,.80, by = .05))

fixation_proportion_violin

#============= Test Phase =======================


# Compute within-subjects summary stats
rt_summary_within_test <- Rmisc::summarySEwithin(
  data = test_phase_bx_rt_summary, 
  measurevar = "meanRT", 
  withinvars = c("LocationProb", "missing_target_flag"), 
  idvar = "sub_num", # your subject column
  na.rm = TRUE
)

response_time_violin_test <- test_phase_bx_rt_summary %>% 
  ggplot(aes(y=meanRT, x = LocationProb, fill = missing_target_flag))+
  geom_violin()+
  stat_summary(fun = mean, 
               geom = "point", 
               shape = 18, 
               size = 4, 
               color = "black")+
  geom_errorbar(data = rt_summary_within_test,
                aes(ymin = meanRT - ci,
                    ymax = meanRT + ci),
                width = 0.1,
                position = position_nudge(x = 0)) +
  ylab("Response Time (ms)")+
  facet_grid(~missing_target_flag)+
  scale_fill_brewer(
    type = "qual",
    palette = palatte_num,
    name = "Location Probability",
    labels = c("High", "Low")
  )+
  theme_classic()
response_time_violin_test

fixation_summary_within_test <- Rmisc::summarySEwithin(
  data = fixation_summary_test_phase, 
  measurevar = "mean_target_first_fix", 
  withinvars = c("LocationProb", "missing_target_flag"), 
  idvar = "sub_num", 
  na.rm = TRUE
)

fixation_proportion_violin_test_phase <- fixation_summary_test_phase %>% 
  ggplot(aes(y = mean_target_first_fix, x = LocationProb, fill = LocationProb)) + 
  geom_violin() +
  stat_summary(fun = mean, geom = "point", shape = 18, size = 4, color = "black") +
  geom_errorbar(
    data = fixation_summary_within_test,
    aes(
      ymin = mean_target_first_fix - ci,
      ymax = mean_target_first_fix + ci
    ),
    width = 0.1
  ) +
  ylab("Proportion of first fixation") +
  facet_grid(~missing_target_flag) +
  scale_fill_brewer(
    type = "qual",
    palette = palatte_num,
    name = "Location Probability",
    labels = c("High", "Low")
  ) +
  theme_classic()+
  scale_y_continuous(labels = scales::percent)

fixation_proportion_violin_test_phase


regression_graph <- fixation_summary_for_regression %>% 
  ggplot(aes(y = mean_target_first_fix, x = total_number_fixation_on_critd)) +
  geom_point()+
  geom_smooth(method = "lm")+
  scale_color_brewer(type = "qual", palette = palatte_num)+
  theme_classic()+
  scale_y_continuous(labels = scales::percent)
regression_graph

ggsave("C:/Users/andersonlabadmin/Documents/Graphs/curious_ss_rt_main_e1.svg", response_time_violin, dpi = 300, width = 10, height = 8, units = "in")
ggsave("C:/Users/andersonlabadmin/Documents/Graphs/curious_ss_ff_maine1.svg", fixation_proportion_violin, dpi = 300, width = 10, height = 8, units = "in")
ggsave("C:/Users/andersonlabadmin/Documents/Graphs/curious_ss_rt_test.svg", response_time_violin_test, dpi = 300, width = 10, height = 8, units = "in")
ggsave("C:/Users/andersonlabadmin/Documents/Graphs/curious_ss_ff_test.svg", fixation_proportion_violin_test_phase, dpi = 300, width = 10, height = 8, units = "in")
ggsave("C:/Users/andersonlabadmin/Documents/Graphs/curious_ss_corr.svg", regression_graph, dpi = 300, width = 10, height = 8, units = "in")

