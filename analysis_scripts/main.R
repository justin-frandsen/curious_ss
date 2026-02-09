# Libraries
library(tidyverse)
library(readxl)      # safer for .xls/.xlsx
library(lme4)
library(lmerTest)    # for p-values in lmer
library(emmeans)
library(effectsize)

#for making tables with anova stats in them
library(gt)
library(broom)

# ---- helper: safer filename extractor (adjust regex to your naming) ----
extract_sub_run <- function(fname) {
  # Example expected: subj017_run2.csv or whatever your files look like.
  # This will find sequences of digits for subject and run; adapt regex if needed.
  # Returns list(sub = <num_or_NA>, run = <num_or_NA>)
  m_sub <- str_match(fname, "subj[ _-]?(\\d{1,3})")
  m_run <- str_match(fname, "run[ _-]?(\\d{1,2})")
  list(sub = ifelse(is.na(m_sub[,2]), NA_integer_, as.integer(m_sub[,2])),
       run = ifelse(is.na(m_run[,2]), NA_integer_, as.integer(m_run[,2])))
}

# ---- read_data (robustified) ----
read_data <- function(data_folder, get_subj_info = FALSE) {
  files <- list.files(path = data_folder, full.names = TRUE, pattern = "\\.csv$", ignore.case = TRUE)
  if (length(files) == 0) stop("No CSV files found in folder: ", data_folder)
  data <- purrr::map_dfr(files, function(file) {
    df <- read.csv(file, stringsAsFactors = FALSE)
    if (get_subj_info) {
      fname <- basename(file)
      fname_noext <- tools::file_path_sans_ext(fname)
      ids <- extract_sub_run(fname_noext)
      df$sub_num <- ids$sub
      df$run_num <- ids$run
    }
    df
  })
  # Coerce types in one place
  if ("sub_num" %in% colnames(data)) data$sub_num <- as.factor(data$sub_num)
  if ("run_num" %in% colnames(data)) data$run_num <- as.factor(data$run_num)
  data
}

# ======= IMPORT BEHAVIORAL & EYE DATA =====================
# Define all the strings you want to treat as NA
na_tokens <- c("", ".", "NA", "null", "UNDEFINED", "UNDEFINEDnull")

raw_imported_bx_files <- read_data("../data/exp1/bx_data/", get_subj_info = FALSE)

fixation_report_SEARCH_PERIOD <- read_delim("../data/exp1/eye_data/curious_eye_position_data/Output/fixation_report_SEARCH_PERIOD_11_13.xls", 
                                            delim = "\t",
                                            na = na_tokens)

fixation_report_POST_SEARCH_PERIOD <- read_delim("../data/exp1/eye_data/curious_eye_position_data/Output/fixation_report_POST_SEARCH_PERIOD_11_13.xls", 
                                                 delim = "\t",
                                                 na = na_tokens)

interest_area_report <- read_delim(
  "../data/exp1/eye_data/curious_eye_position_data/Output/interest_area_report_11_13.xls",
  delim = "\t",
  na = na_tokens)#IA_LEFT, IA_RIGHT, IA_TOP, IA_BOTTOM (pixel coordinates on the display)

# Add validity column and convert subject/run to factors
all_imported_bx_files <- raw_imported_bx_files %>%
  mutate(
    valid0invalid1 = ifelse(condition == 0, 0L, 1L), #the L makes it an integer and not a float
    sub_num = as.factor(sub_num),
    run_num = as.factor(run_num),
    phase = factor(phase, levels = c("training", "testing"))
  ) %>%
  # Remove rows past trial 8 on run 1 (you had this)
  filter(!(trial_num > 8 & run_num == 1)) #remove the rows past 8 on run 1 becuase they didn't exist

# ======= RUN SUMMARY & ACCURACY =====================
unique_run_summary <- all_imported_bx_files %>%
  group_by(sub_num) %>%
  summarise(unique_runs = n_distinct(run_num),
            overall_accuracy = mean(accuracy, na.rm = TRUE), .groups = "drop")

all_imported_bx_files <- left_join(all_imported_bx_files, unique_run_summary, by = "sub_num")

# ======= BEHAVIORAL DATA CLEANUP & FILTERING =======
all_bx_files <- all_imported_bx_files %>%
  # --- Basic inclusion filters ---
  filter(run_num != 1,
         unique_runs == 7,
         overall_accuracy > 0.80,
         sub_num != 120) %>%
  # --- Group by participant and condition factors for within-subject cleanup ---
  group_by(sub_num, valid0invalid1, phase) %>%
  # --- Remove RT outliers ---
  mutate(
    rt = ifelse(accuracy == 0, NA, rt),
    rt = ifelse(rt <= 200, NA, rt), # Hard lower bound
    mean_rt = mean(rt, na.rm = TRUE), # Compute mean and SD per participant/condition/phase
    sd_rt   = sd(rt, na.rm = TRUE),
    rt = ifelse(rt > mean_rt + 3 * sd_rt | rt < mean_rt - 3 * sd_rt, NA, rt)) %>% # Replace values more than 3 SD from the mean with NA
  ungroup() %>%
  # Optionally remove helper columns
  select(-mean_rt, -sd_rt)

removed_trials <- all_bx_files %>%
  group_by(sub_num) %>%
  summarise(total_trials = n(),
            kept_trials = sum(!is.na(rt)),
            removed_trials = sum(is.na(rt)))

unique_targets_summary <- all_imported_bx_files %>%
  group_by(sub_num, run_num) %>%
  summarise(unique_targets = list(unique(target_shape_idx)),
            unique_distractors = list(unique(critical_distractor_idx)),
            .groups = "drop")

# Pivot wider so runs 2 and 4 are columns
run_comparison <- unique_targets_summary %>%
  filter(run_num %in% c(2, 6)) %>%
  pivot_wider(names_from = run_num, 
              values_from = c(unique_targets, unique_distractors), 
              names_glue = "run{run_num}_{.value}") %>%
  mutate(missing_target_from_run2 = map2(run6_unique_targets, run2_unique_distractors, ~ setdiff(.x, .y)))# Find which targets from run 4 are *not* in distractors from run 2

all_bx_files <- all_bx_files %>%
  left_join(run_comparison %>% select(sub_num, missing_target_from_run2),
            by = "sub_num") %>%
  rowwise() %>%
  mutate(missing_target_flag = run_num %in% c(6, 7) && target_shape_idx %in% missing_target_from_run2) %>%
  ungroup()

# ======= RT SUMMARY & ANOVA ==============
bx_rt_summary <- all_bx_files %>%
  filter(missing_target_flag == FALSE) %>% 
  group_by(sub_num, valid0invalid1, phase) %>%
  summarise(meanRT = mean(rt, na.rm = TRUE), .groups = "drop") %>%
  mutate(Validity = factor(valid0invalid1, levels = c(0, 1), labels = c("Valid", "Invalid")),
         phase = fct_drop(phase))

aov_RT <- aov(meanRT ~ Validity*phase + Error(sub_num/(Validity*phase)), 
              data = bx_rt_summary)

table(bx_rt_summary$phase, bx_rt_summary$Validity) # checks to make sure that we have balanced data (we do)
summary(aov_RT)
effectsize::eta_squared(aov_RT, partial = TRUE, ci = 0.95)
means_tbl <- model.tables(aov_RT, "means")
means_tbl

emmeans(aov_RT, pairwise ~ Validity | phase)
emmeans(aov_RT, pairwise ~ phase | Validity)

#single-trial log-RT:
all_bx_files <- all_bx_files %>% mutate(log_rt = log(rt))

# Remove rows with NA log_rt
lmer_data <- all_bx_files %>% filter(!is.na(log_rt), missing_target_flag == FALSE)

# Example lmer: fixed effects validity*phase, random intercepts for subject (and optionally run/item)
lmm_rt <- lmer(log_rt ~ valid0invalid1 * phase + (1 | sub_num), data = lmer_data, REML = FALSE)
summary(lmm_rt)
anova(lmm_rt)
emmeans::emmeans(lmm_rt, pairwise ~ valid0invalid1 | phase, type = "response")

test_phase_bx_rt_summary <- all_bx_files %>%
  filter(run_num %in% c(6, 7)) %>% 
  group_by(sub_num, valid0invalid1, missing_target_flag) %>%
  summarise(meanRT = mean(rt, na.rm = TRUE), 
            meanLogRT = mean(log_rt, na.rm = TRUE),
            .groups = "drop") %>%
  mutate(Validity = factor(valid0invalid1, levels = c(0, 1), labels = c("Valid", "Invalid")),
         missing_target_flag = as.factor(missing_target_flag))

aov_Test_Phase_RT <- aov(meanLogRT ~ Validity*missing_target_flag + Error(sub_num/(Validity*missing_target_flag)), 
                         data = test_phase_bx_rt_summary)
aov_assumptions_Test_Phase_RT <- aov(meanLogRT ~ Validity*missing_target_flag,  data = test_phase_bx_rt_summary)
# Extract residuals
res <- residuals(aov_assumptions_Test_Phase_RT)

# Visual check: Q-Q plot
qqnorm(res); qqline(res)

# Statistical test: Shapiro-Wilk test
shapiro.test(res)

summary(aov_Test_Phase_RT)
effectsize::eta_squared(aov_Test_Phase_RT, partial = TRUE, ci = 0.95)
model.tables(aov_Test_Phase_RT, "means")
emmeans(aov_Test_Phase_RT, pairwise ~ Validity | missing_target_flag)
emmeans(aov_Test_Phase_RT, pairwise ~ missing_target_flag | Validity)

# Remove rows with NA log_rt
Test_Phase_lmer_data <- all_bx_files %>% filter(!is.na(log_rt), run_num %in% c(6, 7))

# Example lmer: fixed effects validity*phase, random intercepts for subject (and optionally run/item)
Test_Phase_lmm_rt <- lmer(log_rt ~ valid0invalid1 * missing_target_flag + (1 | sub_num), data = Test_Phase_lmer_data, REML = FALSE)
summary(Test_Phase_lmm_rt)
anova(Test_Phase_lmm_rt)

emmeans::emmeans(Test_Phase_lmm_rt, pairwise ~ valid0invalid1 | missing_target_flag, type = "response") #pbkrtest.limit = 5000

#======================= EYETRACKING ANALYSIS =========================

## ---- Eye-tracking: AOI / IA import & join (fixed) ----
### Parse recording labels to pull sub/run; adjust regex if your label differs
trial_interest_areas <- interest_area_report %>%
  mutate(run_num = as.numeric(str_sub(RECORDING_SESSION_LABEL, -1, -1)),
         sub_num = as.numeric(str_sub(RECORDING_SESSION_LABEL, -5, -3)),
         run_num = as.factor(run_num),
         sub_num = as.factor(sub_num),
         scene_idx = scene,
         trial_num_origional = trial_num) %>%
  select(RECORDING_SESSION_LABEL, TRIAL_INDEX, IA_LABEL, IA_LEFT, IA_RIGHT, IA_TOP, IA_BOTTOM, scene, sub_num, run_num, scene_idx)

### pivot wider into columns like IA_LEFT_target, IA_RIGHT_target, etc.
trial_interest_areas_wide <- trial_interest_areas %>%
  mutate(IA_LABEL = make.names(IA_LABEL)) %>%   # sanitize labels
  pivot_wider(names_from = IA_LABEL,
              values_from = c(IA_LEFT, IA_RIGHT, IA_TOP, IA_BOTTOM),
              names_sep = "_") %>%
  arrange(sub_num, run_num, TRIAL_INDEX)

# Get row counts to replace the rows where dataviewer wrongly added extra trial
trial_interest_areas_wide <- trial_interest_areas_wide %>%
  group_by(sub_num, run_num) %>%       # Group by subject and run
  arrange(sub_num, run_num, TRIAL_INDEX) %>%        # Ensure proper order
  mutate(trial_num = row_number(),
         misaligned_flag = ifelse(is.na(scene_idx), 1, 0)) %>%  # Count trial within each group
  ungroup() %>% 
  select(sub_num, run_num, TRIAL_INDEX, trial_num, scene_idx, misaligned_flag, everything())

#add scene info which was missing (can add more things here if needed)
trial_interest_areas_wide <- trial_interest_areas_wide %>% 
  left_join(raw_imported_bx_files %>% select(sub_num, run_num, trial_num, scene_idx), by = c("sub_num", "run_num", "trial_num")) %>% 
  mutate(scene_idx_old = scene_idx.x,
         scene_idx = scene_idx.y) %>% 
  select(-scene_idx.x, -scene_idx.y)

# ------------------ Eye position data ------------------------------
fixation_report_SEARCH_PERIOD <- fixation_report_SEARCH_PERIOD %>% 
  mutate(run_num = as.numeric(str_sub(RECORDING_SESSION_LABEL, -1, -1)),
         sub_num = as.numeric(str_sub(RECORDING_SESSION_LABEL, -5, -3)),
         run_num = as.factor(run_num),
         sub_num = as.factor(sub_num)) %>% 
  group_by(sub_num, run_num) %>%       # Group by subject and run
  arrange(sub_num, run_num, TRIAL_INDEX) %>%        # Ensure proper order
  mutate(trial_num = dense_rank(TRIAL_INDEX)) %>%  # Count trial within each group
  ungroup()

fixation_report_SEARCH_PERIOD_with_ROIs <- fixation_report_SEARCH_PERIOD %>% 
  left_join(trial_interest_areas_wide, by = c("sub_num", "run_num", "trial_num"))

roi_names <- c("TargetBox", "NonCritDistBox1", "NonCritDistBox2", "NonCritDistBox3", "CritDistBox")

# Example for a single ROI called "target"
fixation_report_SEARCH_PERIOD_with_ROIs <- fixation_report_SEARCH_PERIOD_with_ROIs %>%
  mutate(
    run_num = as.factor(block),
    in_TargetBox = ifelse(
      between(CURRENT_FIX_X, IA_LEFT_TargetBox, IA_RIGHT_TargetBox) &
        between(CURRENT_FIX_Y, IA_TOP_TargetBox, IA_BOTTOM_TargetBox), 1, 0),
    in_NonCritDistBox1 = ifelse(
      between(CURRENT_FIX_X, IA_LEFT_NonCritDistBox1, IA_RIGHT_NonCritDistBox1) &
        between(CURRENT_FIX_Y, IA_TOP_NonCritDistBox1, IA_BOTTOM_NonCritDistBox1), 1, 0),
    in_NonCritDistBox2 = ifelse(
      between(CURRENT_FIX_X, IA_LEFT_NonCritDistBox2, IA_RIGHT_NonCritDistBox2) &
        between(CURRENT_FIX_Y, IA_TOP_NonCritDistBox2, IA_BOTTOM_NonCritDistBox2), 1, 0),
    in_NonCritDistBox3 = ifelse(
      between(CURRENT_FIX_X, IA_LEFT_NonCritDistBox3, IA_RIGHT_NonCritDistBox3) &
        between(CURRENT_FIX_Y, IA_TOP_NonCritDistBox3, IA_BOTTOM_NonCritDistBox3), 1, 0),
    in_CritDistBox = ifelse(
      between(CURRENT_FIX_X, IA_LEFT_CritDistBox, IA_RIGHT_CritDistBox) &
        between(CURRENT_FIX_Y, IA_TOP_CritDistBox, IA_BOTTOM_CritDistBox), 1, 0),
    current_roi = ifelse(in_TargetBox, "TargetBox", 
                         ifelse(in_NonCritDistBox1, "NonCritDistBox1", 
                                ifelse(in_NonCritDistBox2, "NonCritDistBox2", 
                                       ifelse(in_NonCritDistBox3, "NonCritDistBox3", 
                                              ifelse(in_CritDistBox, "CritDistBox", NA))))))

# Summarize fixations per trial
SEARCH_PERIOD_fixation_summary <- fixation_report_SEARCH_PERIOD_with_ROIs %>%
  filter(RT > 200,
         RT >= mean(RT, na.rm = TRUE) - 3 * sd(RT, na.rm = TRUE),
         RT <= mean(RT, na.rm = TRUE) + 3 * sd(RT, na.rm = TRUE)) %>% 
  group_by(sub_num, run_num, trial_num) %>%
  arrange(CURRENT_FIX_INDEX, .by_group = TRUE) %>%
  summarise(
    # ---- Basic fixation counts ----
    total_fixations = n(),
    fixations_on_Target = sum(in_TargetBox, na.rm = TRUE),
    fixations_on_NonCritDist1 = sum(in_NonCritDistBox1, na.rm = TRUE),
    fixations_on_NonCritDist2 = sum(in_NonCritDistBox2, na.rm = TRUE),
    fixations_on_NonCritDist3 = sum(in_NonCritDistBox3, na.rm = TRUE),
    fixations_on_CritDist = sum(in_CritDistBox, na.rm = TRUE),
    # ---- Proportion of fixations ----
    prop_Target = mean(in_TargetBox, na.rm = TRUE),
    prop_NonCritDist1 = mean(in_NonCritDistBox1, na.rm = TRUE),
    prop_NonCritDist2 = mean(in_NonCritDistBox2, na.rm = TRUE),
    prop_NonCritDist3 = mean(in_NonCritDistBox3, na.rm = TRUE),
    prop_CritDist = mean(in_CritDistBox, na.rm = TRUE),
    # ---- Total fixation duration per ROI (in ms) ----
    dur_Target = sum(CURRENT_FIX_DURATION[in_TargetBox == 1], na.rm = TRUE),
    dur_NonCritDist1 = sum(CURRENT_FIX_DURATION[in_NonCritDistBox1 == 1], na.rm = TRUE),
    dur_NonCritDist2 = sum(CURRENT_FIX_DURATION[in_NonCritDistBox2 == 1], na.rm = TRUE),
    dur_NonCritDist3 = sum(CURRENT_FIX_DURATION[in_NonCritDistBox3 == 1], na.rm = TRUE),
    dur_CritDist = sum(CURRENT_FIX_DURATION[in_CritDistBox == 1], na.rm = TRUE),
    # ---- First fixation ROI (in time order) ----
    first_fixation_ROI = current_roi[which(!is.na(current_roi))[1]],
    
    # ---- Fixation number when target was first fixated ----
    Target_fixation_number = CURRENT_FIX_INDEX[which(in_TargetBox == 1)[1]],
    .groups = "drop")

# ------------------ Post-Search Eye position data ------------------------------
fixation_report_POST_SEARCH_PERIOD <- fixation_report_POST_SEARCH_PERIOD %>% 
  mutate(run_num = as.numeric(str_sub(RECORDING_SESSION_LABEL, -1, -1)),
         sub_num = as.numeric(str_sub(RECORDING_SESSION_LABEL, -5, -3)),
         run_num = as.factor(run_num),
         sub_num = as.factor(sub_num)) %>% 
  group_by(sub_num, run_num) %>%       # Group by subject and run
  arrange(sub_num, run_num, TRIAL_INDEX) %>%        # Ensure proper order
  mutate(trial_num = dense_rank(TRIAL_INDEX)) %>%  # Count trial within each group
  ungroup()

fixation_report_POST_SEARCH_PERIOD_with_ROIs <- fixation_report_POST_SEARCH_PERIOD %>% 
  left_join(trial_interest_areas_wide, by = c("sub_num", "run_num", "trial_num"))

roi_names <- c("TargetBox", "NonCritDistBox1", "NonCritDistBox2", "NonCritDistBox3", "CritDistBox")

# Example for a single ROI called "target"
fixation_report_POST_SEARCH_PERIOD_with_ROIs <- fixation_report_POST_SEARCH_PERIOD_with_ROIs %>%
  mutate(
    run_num = as.factor(block),
    in_TargetBox = ifelse(
      between(CURRENT_FIX_X, IA_LEFT_TargetBox, IA_RIGHT_TargetBox) &
        between(CURRENT_FIX_Y, IA_TOP_TargetBox, IA_BOTTOM_TargetBox), 1, 0),
    in_NonCritDistBox1 = ifelse(
      between(CURRENT_FIX_X, IA_LEFT_NonCritDistBox1, IA_RIGHT_NonCritDistBox1) &
        between(CURRENT_FIX_Y, IA_TOP_NonCritDistBox1, IA_BOTTOM_NonCritDistBox1), 1, 0),
    in_NonCritDistBox2 = ifelse(
      between(CURRENT_FIX_X, IA_LEFT_NonCritDistBox2, IA_RIGHT_NonCritDistBox2) &
        between(CURRENT_FIX_Y, IA_TOP_NonCritDistBox2, IA_BOTTOM_NonCritDistBox2), 1, 0),
    in_NonCritDistBox3 = ifelse(
      between(CURRENT_FIX_X, IA_LEFT_NonCritDistBox3, IA_RIGHT_NonCritDistBox3) &
        between(CURRENT_FIX_Y, IA_TOP_NonCritDistBox3, IA_BOTTOM_NonCritDistBox3), 1, 0),
    in_CritDistBox = ifelse(
      between(CURRENT_FIX_X, IA_LEFT_CritDistBox, IA_RIGHT_CritDistBox) &
        between(CURRENT_FIX_Y, IA_TOP_CritDistBox, IA_BOTTOM_CritDistBox), 1, 0),
    current_roi = ifelse(in_TargetBox, "TargetBox", 
                         ifelse(in_NonCritDistBox1, "NonCritDistBox1", 
                                ifelse(in_NonCritDistBox2, "NonCritDistBox2", 
                                       ifelse(in_NonCritDistBox3, "NonCritDistBox3", 
                                              ifelse(in_CritDistBox, "CritDistBox", NA))))))

# Summarize fixations per trial
POST_SEARCH_PERIOD_fixation_summary <- fixation_report_POST_SEARCH_PERIOD_with_ROIs %>%
  filter(RT > 200,
         RT >= mean(RT, na.rm = TRUE) - 3 * sd(RT, na.rm = TRUE),
         RT <= mean(RT, na.rm = TRUE) + 3 * sd(RT, na.rm = TRUE)) %>% 
  group_by(sub_num, run_num, trial_num) %>%
  arrange(CURRENT_FIX_INDEX, .by_group = TRUE) %>%
  summarise(
    
    # ---- Basic fixation counts ----
    total_fixations = n(),
    fixations_on_Target = sum(in_TargetBox, na.rm = TRUE),
    fixations_on_NonCritDist1 = sum(in_NonCritDistBox1, na.rm = TRUE),
    fixations_on_NonCritDist2 = sum(in_NonCritDistBox2, na.rm = TRUE),
    fixations_on_NonCritDist3 = sum(in_NonCritDistBox3, na.rm = TRUE),
    fixations_on_CritDist = sum(in_CritDistBox, na.rm = TRUE),
    # ---- Proportion of fixations ----
    prop_Target = mean(in_TargetBox, na.rm = TRUE),
    prop_NonCritDist1 = mean(in_NonCritDistBox1, na.rm = TRUE),
    prop_NonCritDist2 = mean(in_NonCritDistBox2, na.rm = TRUE),
    prop_NonCritDist3 = mean(in_NonCritDistBox3, na.rm = TRUE),
    prop_CritDist = mean(in_CritDistBox, na.rm = TRUE),
    # ---- Total fixation duration per ROI (in ms) ----
    dur_Target = sum(CURRENT_FIX_DURATION[in_TargetBox == 1], na.rm = TRUE),
    dur_NonCritDist1 = sum(CURRENT_FIX_DURATION[in_NonCritDistBox1 == 1], na.rm = TRUE),
    dur_NonCritDist2 = sum(CURRENT_FIX_DURATION[in_NonCritDistBox2 == 1], na.rm = TRUE),
    dur_NonCritDist3 = sum(CURRENT_FIX_DURATION[in_NonCritDistBox3 == 1], na.rm = TRUE),
    dur_CritDist = sum(CURRENT_FIX_DURATION[in_CritDistBox == 1], na.rm = TRUE),
    # ---- First fixation ROI (in time order) ----
    first_fixation_ROI = current_roi[which(!is.na(current_roi))[1]],
    .groups = "drop")

#join the search period and post_search_period 
FULL_SEARCH_PERIOD_fixation_summary <- SEARCH_PERIOD_fixation_summary %>% 
  left_join(POST_SEARCH_PERIOD_fixation_summary, by = c("sub_num", "run_num", "trial_num")) %>%
  rename_with(~ str_replace(.x, "(.*)\\.x$", "SEARCH_PERIOD_\\1"), ends_with(".x")) %>%
  rename_with(~ str_replace(.x, "(.*)\\.y$", "POST_SEARCH_PERIOD_\\1"), ends_with(".y"))

FULL_SEARCH_PERIOD_fixation_summary <- FULL_SEARCH_PERIOD_fixation_summary %>%
  mutate(
    # Fixation counts
    FULL_total_fixations =
      SEARCH_PERIOD_total_fixations + POST_SEARCH_PERIOD_total_fixations,
    FULL_fix_Target =
      SEARCH_PERIOD_fixations_on_Target + POST_SEARCH_PERIOD_fixations_on_Target,
    FULL_fix_NonCritDist1 =
      SEARCH_PERIOD_fixations_on_NonCritDist1 + POST_SEARCH_PERIOD_fixations_on_NonCritDist1,
    FULL_fix_NonCritDist2 =
      SEARCH_PERIOD_fixations_on_NonCritDist2 + POST_SEARCH_PERIOD_fixations_on_NonCritDist2,
    FULL_fix_NonCritDist3 =
      SEARCH_PERIOD_fixations_on_NonCritDist3 + POST_SEARCH_PERIOD_fixations_on_NonCritDist3,
    FULL_fix_CritDist =
      SEARCH_PERIOD_fixations_on_CritDist + POST_SEARCH_PERIOD_fixations_on_CritDist,
    
    # Durations
    FULL_dur_Target =
      SEARCH_PERIOD_dur_Target + POST_SEARCH_PERIOD_dur_Target,
    FULL_dur_NonCritDist1 =
      SEARCH_PERIOD_dur_NonCritDist1 + POST_SEARCH_PERIOD_dur_NonCritDist1,
    FULL_dur_NonCritDist2 =
      SEARCH_PERIOD_dur_NonCritDist2 + POST_SEARCH_PERIOD_dur_NonCritDist2,
    FULL_dur_NonCritDist3 =
      SEARCH_PERIOD_dur_NonCritDist3 + POST_SEARCH_PERIOD_dur_NonCritDist3,
    FULL_dur_CritDist =
      SEARCH_PERIOD_dur_CritDist + POST_SEARCH_PERIOD_dur_CritDist
  ) %>%
  mutate(
    # Proportions must be weighted by fixation count
    FULL_prop_Target = FULL_fix_Target / FULL_total_fixations,
    FULL_prop_NonCritDist1 = FULL_fix_NonCritDist1 / FULL_total_fixations,
    FULL_prop_NonCritDist2 = FULL_fix_NonCritDist2 / FULL_total_fixations,
    FULL_prop_NonCritDist3 = FULL_fix_NonCritDist3 / FULL_total_fixations,
    FULL_prop_CritDist = FULL_fix_CritDist / FULL_total_fixations,
    
    target_first_fix = ifelse(SEARCH_PERIOD_first_fixation_ROI == "TargetBox", 1, 0))

#add condition info
FULL_SEARCH_PERIOD_fixation_summary <- FULL_SEARCH_PERIOD_fixation_summary %>% 
  left_join(all_bx_files %>% select(sub_num, run_num, trial_num, missing_target_flag, phase, valid0invalid1), 
            by = c("sub_num", "run_num", "trial_num"))

fixation_summary <- FULL_SEARCH_PERIOD_fixation_summary %>%
  filter(missing_target_flag == FALSE,
         run_num != 1) %>% 
  group_by(sub_num, valid0invalid1, phase) %>%
  summarise(mean_target_first_fix = mean(target_first_fix, na.rm = TRUE),
            mean_Target_fixation_number = mean(Target_fixation_number, na.rm = TRUE),
            .groups = "drop") %>%
  mutate(Validity = factor(valid0invalid1, levels = c(0, 1), labels = c("Valid", "Invalid")),
         phase = fct_drop(phase))

#summarise how long participants looked at the critical distractor.
critd_training <- FULL_SEARCH_PERIOD_fixation_summary %>%
  filter(phase == 'training', 
         run_num != 1) %>%
  group_by(sub_num) %>%
  summarise(
    total_CritDist_time = sum(FULL_dur_CritDist, na.rm = TRUE),
    .groups = "drop"
  ) 

#join how long the critical distractor was looked at with the fixation summary (add RT so we can compare to both behavioral and eyemovement info)
fixation_summary_for_regression <- fixation_summary %>% 
  left_join(critd_training, by = c("sub_num")) %>% 
  left_join(bx_rt_summary, by = c("sub_num", "phase", "valid0invalid1")) %>% 
  mutate(total_CritDist_sec = total_CritDist_time / 1000,
         total_CritDist_centered = scale(total_CritDist_sec, center = TRUE, scale = FALSE),
         total_CritDist_z = scale(total_CritDist_sec))

aov_First_fix <- aov(mean_target_first_fix ~ valid0invalid1*phase + Error(sub_num/(valid0invalid1*phase)), 
                     data = fixation_summary)

summary(aov_First_fix)
effectsize::eta_squared(aov_First_fix, partial = TRUE, ci = 0.95)
model.tables(aov_First_fix, "means")
emmeans(aov_First_fix, pairwise ~ valid0invalid1 | phase)
emmeans(aov_First_fix, pairwise ~ phase | valid0invalid1)

aov_ordinal_fix <- aov(mean_Target_fixation_number ~ valid0invalid1*phase + Error(sub_num/(valid0invalid1*phase)), 
                       data = fixation_summary)

summary(aov_ordinal_fix)
effectsize::eta_squared(aov_ordinal_fix, partial = TRUE, ci = 0.95)
model.tables(aov_ordinal_fix, "means")
emmeans(aov_ordinal_fix, pairwise ~ valid0invalid1 | phase)
emmeans(aov_ordinal_fix, pairwise ~ phase | valid0invalid1)

# ensure factors match what you used in ANOVAs
lmer_data_et <- FULL_SEARCH_PERIOD_fixation_summary %>%
  filter(missing_target_flag == FALSE,
         run_num != 1) %>%
  mutate(Validity = factor(valid0invalid1, levels = c(0,1), labels = c("Valid","Invalid")),
         phase = droplevels(phase))

lmm_fix_number <- lmer(
  Target_fixation_number ~ Validity * phase + (1 | sub_num),
  data = lmer_data_et,
  REML = FALSE
)

summary(lmm_fix_number)
anova(lmm_fix_number)
emmeans(lmm_fix_number, pairwise ~ Validity | phase)
emmeans(lmm_fix_number, pairwise ~ phase | Validity)

#Next analysis is kind of difficult I need to predict the speed of looking at a target in its valid or invalid
#location based on the total duration they looked at the distractor in the task. Do this for total fixations
#and stuff like that

# Full model
model1 <- glm(mean_target_first_fix ~ valid0invalid1,
             data = fixation_summary_for_regression %>% filter(phase == "testing"))
model2 <- glm(mean_target_first_fix ~ total_CritDist_z,
              data = fixation_summary_for_regression %>% filter(phase == "testing"))
model3 <- glm(mean_target_first_fix ~ total_CritDist_z + valid0invalid1,
             data = fixation_summary_for_regression %>% filter(phase == "testing"))
model4 <- glm(mean_target_first_fix ~ total_CritDist_z * valid0invalid1,
              data = fixation_summary_for_regression %>% filter(phase == "testing"))

par(mfrow = c(2, 2))
plot(model3)


summary(model1)
summary(model2)
summary(model3)
summary(model4)

anova(model1, model3, test = "F")
anova(model2, model3, test = "F")
anova(model3, model4, test = "F")

hist(fixation_summary_for_regression %>% 
       filter(phase == "testing") %>% 
       pull(total_CritDist_z),
     breaks = 100)


# Step 1: Fit linear models for each facet and extract coefficients
coef_df <- fixation_summary_for_regression %>%
  filter(phase == "testing") %>%
  group_by(valid0invalid1) %>%
  do(tidy(lm(mean_target_first_fix ~ total_CritDist_z, data = .))) %>%
  select(valid0invalid1, term, estimate) %>%
  tidyr::pivot_wider(names_from = term, values_from = estimate) %>%
  rename(intercept = `(Intercept)`, slope = total_CritDist_z) %>%
  # Create a label with the formula for each facet
  mutate(label = paste0("y = ", round(intercept, 3), 
                        ifelse(slope < 0, " - ", " + "),
                        abs(round(slope, 3)), "*x"),
         x = min(fixation_summary_for_regression$total_CritDist_z, na.rm = TRUE),
         y = max(fixation_summary_for_regression$mean_target_first_fix, na.rm = TRUE))

# Step 2: Plot points, regression lines, and formulas on each facet
ggplot(
  fixation_summary_for_regression %>% filter(phase == "testing"),
  aes(x = total_CritDist_z, y = mean_target_first_fix)
) +
  geom_point(alpha = 0.7, color = "steelblue") +
  geom_smooth(method = "lm", se = TRUE, color = "darkred") +
  geom_text(
    data = coef_df,
    aes(x = x, y = y, label = label),
    inherit.aes = FALSE,
    hjust = 0,
    size = 5
  ) +
  labs(
    x = "Z-scored Total Critical Distractor Time",
    y = "Probability of First Fixation on Target",
    title = "Relationship Between Distractor Viewing Time and Target Fixation"
  ) +
  theme_minimal(base_size = 14) +
  facet_grid(~valid0invalid1)


