library(tidyverse)
library(emmeans)
library(car)

# Reads all files in a folder and optionally adds subject/run info from filenames
read <- function(data_folder, get_subj_info = FALSE){
  full <- data.frame()
  for (file in data_folder) {
    # Read in each CSV file
    individual <- read.csv(file = file)
    if (get_subj_info == TRUE){
      # Extract run and subject numbers from filename using string positions
      run_num = str_sub(file,-6, -4)
      sub_num = str_sub(file,-8, -6)
      individual$run_num <- run_num
      individual$sub_num <- sub_num
    }
    full <- dplyr::bind_rows(full, individual)
  }
  return(full)
}

# ======= IMPORT BEHAVIORAL & EYE DATA =====================
bx_files <- dir(path = "../data/bx_data/", full.names = TRUE)

raw_imported_bx_files <- read(bx_files)

eye_position_data <- read.delim("../data/eye_data/curious_eye_position_data/Output/eye_position_data.xls", 
                                na.strings=".")
interest_area_report <- read.delim("../data/eye_data/curious_eye_position_data/Output/interest_area_report.xls", 
                                na.strings=".") #IA_LEFT, IA_RIGHT, IA_TOP, IA_BOTTOM (pixel coordinates on the display)

# Add validity column and convert subject/run to factors
all_imported_bx_files <- raw_imported_bx_files %>% 
  mutate(valid0invalid1 = ifelse(condition==0, 0, 1),
         sub_num = as.factor(sub_num),
         run_num = as.factor(run_num),
         phase = as.factor(phase)) %>% 
  filter(!(trial_num > 8 & run_num == 1)) #remove the rows past 8 on run 1 becuase they didn't exist

# ======= RUN SUMMARY & ACCURACY =====================
unique_run_summary <- all_imported_bx_files  %>% 
  group_by(sub_num) %>% 
  summarise(unique_runs = n_distinct(run_num),
            overall_accuracy = mean(accuracy, na.rm = TRUE))

all_imported_bx_files <- left_join(all_imported_bx_files, unique_run_summary, by = "sub_num") 

# ======= BEHAVIORAL DATA CLEANUP & FILTERING =======
all_bx_files <- all_imported_bx_files %>%
  filter(accuracy == 1,
         run_num != 1,
         unique_runs == 7,
         overall_accuracy > 0.80) %>%
  group_by(sub_num, 
           valid0invalid1,
           phase) %>% 
  # Remove outlier RTs and too-fast RTs
  mutate(rt = ifelse(rt <= 200, NA, rt),
         rt = ifelse(rt > mean(rt, na.rm=TRUE)+3*sd(rt, na.rm = TRUE), NA, rt),
         rt = ifelse(rt < mean(rt, na.rm=TRUE)-3*sd(rt, na.rm = TRUE), NA, rt)) %>% 
  ungroup()

# ======= RT SUMMARY & ANOVA ==============
bx_rt_summary <- all_bx_files  %>%
  group_by(sub_num, valid0invalid1, phase) %>% 
  summarise(meanRT = mean(rt, na.rm = TRUE)) %>% 
  mutate(Validity = factor(valid0invalid1, levels = c(0, 1), labels = c("Valid", "Invalid")),
         phase = fct_drop(phase)) #keeps only levels that remain

aov_RT <- aov(meanRT ~ Validity*phase + Error(sub_num/(Validity*phase)), 
              data = bx_rt_summary)

summary(aov_RT)
effectsize::eta_squared(aov_RT, partial = TRUE, ci = 0.95)
model.tables(aov_RT, "means")
emmeans(aov_RT, pairwise ~ Validity | phase)
emmeans(aov_RT, pairwise ~ phase | Validity)


# RT summary stats by condition
bx_rt_summary %>%
  group_by(Validity, phase) %>%
  summarise(
    mean_RT = mean(meanRT),
    sd_RT = sd(meanRT),
    n = n() / 2,
    se = sd_RT / sqrt(n)
  )

# By scene association
bx_rt_summary %>%
  group_by(phase) %>%
  summarise(
    mean_RT = mean(meanRT),
    sd_RT = sd(meanRT),
    n = n() / 2,
    se = sd_RT / sqrt(n)
  )

# By validity
bx_rt_summary %>%
  group_by(Validity) %>%
  summarise(
    mean_RT = mean(meanRT),
    sd_RT = sd(meanRT),
    n = n() / 2,
    se = sd_RT / sqrt(n)
  )

#======================= EYETRACKING ANALYSIS =========================
trial_info <- all_imported_bx_files %>% 
  select(scene_idx, trial_num, run_num, sub_num)


eye_position_data <- eye_position_data %>% 
  mutate(run_num = as.numeric(str_sub(RECORDING_SESSION_LABEL, -1, -1)),
         sub_num = as.numeric(str_sub(RECORDING_SESSION_LABEL, -5, -3)))

scene_info <- eye_position_data %>% 
  select(sub_num, run_num, TRIAL_INDEX, scene)

trial_interest_areas <- interest_area_report %>% 
  select(RECORDING_SESSION_LABEL, TRIAL_INDEX, IA_LABEL, IA_LEFT, IA_RIGHT, IA_TOP, IA_BOTTOM, scene) %>% 
  mutate(run_num = as.numeric(str_sub(RECORDING_SESSION_LABEL, -1, -1)),
         sub_num = as.numeric(str_sub(RECORDING_SESSION_LABEL, -5, -3)),
         scene_idx = scene) %>% 
  pivot_wider(names_from = IA_LABEL, values_from = c(IA_LEFT, IA_RIGHT, IA_TOP, IA_BOTTOM)) %>% 
  filter(run_num != 1,
         sub_num == 17)

trial_counts <- eye_position_data %>%
  group_by(sub_num) %>%
  summarise(n_trials = n_distinct(TRIAL_INDEX))

trial_counts <- eye_position_data %>%
  distinct(sub_num, run_num, TRIAL_INDEX) %>%   # drop duplicates if trial has multiple rows (e.g., ROIs, fixations)
  count(sub_num, run_num, name = "n_trials")

joined <- trial_interest_areas %>% 
  left_join(trial_interest_areas, trial_info, by = c("sub_num", "run_num", "scene_idx"))

trial_interest_areas %>%
  count(sub_num, run_num, scene_idx) %>% summary()
