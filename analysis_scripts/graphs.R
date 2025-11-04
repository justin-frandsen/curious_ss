#make sure the data from main.R is loaded in already.
source("main.R")

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
  withinvars = c("Validity", "phase"), 
  idvar = "sub_num", # your subject column
  na.rm = TRUE
)

ggplot(bx_rt_summary,
       aes(x = phase, y = meanRT)) +
  geom_half_violin(aes(fill = Validity),
                   side = "l", 
                   data = subset(bx_rt_summary, Validity == "Valid"),
                   alpha = 0.6,
                   position = position_nudge(x = -nudge))+  # move left) +
  geom_half_violin(aes(fill = Validity),
                   side = "r", 
                   data = subset(bx_rt_summary, Validity == "Invalid"),
                   alpha = 0.6,
                   position = position_nudge(x = nudge))+  # move right) +
  # Means + CIs (from your within-sub summary statistics)
  geom_point(data = rt_summary_within,
             aes(shape = Validity, color = Validity),
             size = 3, 
             position = position_nudge(x = 0)) +
  geom_errorbar(data = rt_summary_within,
                aes(color = Validity,
                    ymin = meanRT - ci,
                    ymax = meanRT + ci),
                width = 0.1,
                position = position_nudge(x = 0)) +
  stat_summary(fun = mean,
               geom = "line",   #graph lines
               na.rm = T,
               position = position_dodge(width = 0),
               aes(group = Validity, color = Validity))+
  labs(x = "Phase",
       y = "Mean Response Time (ms)",
       fill = "Validity",
       color = "Validity") +
  theme_classic()+
  scale_y_continuous(breaks = seq(0,4000, by = 100),
                     limits = nicelimits)+
  scale_fill_brewer(type = "qual", palette = palatte_num)+
  scale_color_brewer(type = "qual", palette = palatte_num)
#coord_flip()

fixation_summary_within <- Rmisc::summarySEwithin(
  data = fixation_summary, 
  measurevar = "mean_target_first_fix", 
  withinvars = c("Validity", "phase"), 
  idvar = "sub_num", # your subject column
  na.rm = TRUE)


fixation_summary %>% 
  ggplot(aes(x = phase, y = mean_target_first_fix)) +
  # Half violins
  geom_half_violin(aes(fill = Validity),
                   side = "l", 
                   data = subset(fixation_summary, Validity == "Valid"),
                   alpha = 0.6,
                   position = position_nudge(x = -nudge)) +
  geom_half_violin(aes(fill = Validity),
                   side = "r", 
                   data = subset(fixation_summary, Validity == "Invalid"),
                   alpha = 0.6,
                   position = position_nudge(x = nudge)) +
  # Means + CIs (from your within-sub summary statistics)
  geom_point(data = fixation_summary_within,
             aes(color = Validity, shape = Validity),
             size = 3, position = position_nudge(x = 0)) +
  geom_errorbar(data = fixation_summary_within,
                aes(color = Validity,
                    ymin = mean_target_first_fix - ci,
                    ymax = mean_target_first_fix + ci),
                width = 0.1,
                position = position_nudge(x = 0)) +
  stat_summary(fun = mean,
               geom = "line",   #graph lines
               na.rm = T,
               position = position_dodge(width = 0),
               aes(group = Validity, color = Validity))+
  labs(x = "Phase",
       y = "Pecentage of first Fixation",
       fill = "Validity",
       color = "Validity") +
  scale_y_continuous(labels = scales::percent,
                     breaks = seq(0,1, by = .05),
                     limits = nicelimits)+
  scale_fill_brewer(type = "qual", palette = palatte_num)+
  scale_color_brewer(type = "qual", palette = palatte_num)+
  theme_classic()

anova_summary <- summary(aov_RT)[[1]]  # pick the correct Error/term table

#table with anova stats
anova_tidy <- tidy(aov_RT)

anova_tidy %>%
  rename(
    Term = term,
    `Sum Sq` = sumsq,
    `Mean Sq` = meansq,
    `F value` = statistic,
    `p value` = p.value
  ) %>%
  gt() %>%
  tab_header(title = "ANOVA Summary: meanRT ~ Validity*Phase") %>%
  fmt_number(
    columns = c(`Sum Sq`, `Mean Sq`, `F value`, `p value`),
    decimals = 3
  )

effectsize::eta_squared(aov_RT, partial = TRUE, ci = 0.95)
means_tbl <- model.tables(aov_RT, "means")
means_tbl
valid_tbl <- model.tables(aov_RT, "means")$tables[["Validity"]] %>%
  tibble::enframe(name = "Validity", value = "MeanRT")

phase_tbl <- model.tables(aov_RT, "means")$tables[["phase"]] %>%
  tibble::enframe(name = "Phase", value = "MeanRT")

phase_tbl %>%
  gt() %>%
  tab_header(title = "Main Effect: Phase") %>%
  fmt_number(columns = MeanRT, decimals = 2)

valid_tbl %>%
  gt() %>%
  tab_header(title = "Main Effect: Validity") %>%
  fmt_number(columns = MeanRT, decimals = 2)


means_df <- as.data.frame(means_tbl)

interaction_tbl_raw <- model.tables(aov_RT, "means")$tables[["Validity:phase"]]

# Build a clean tibble
interaction_tbl <- tibble::tibble(
  Validity = rownames(interaction_tbl_raw),
  Training = as.numeric(interaction_tbl_raw[, "training"]),
  Testing  = as.numeric(interaction_tbl_raw[, "testing"])
)

# Format nicely for PowerPoint
interaction_tbl %>%
  gt() %>%
  tab_header(title = "Interaction Means: Validity × Phase") %>%
  fmt_number(
    columns = c(Training, Testing),
    decimals = 0
  )



