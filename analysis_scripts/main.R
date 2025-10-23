# Libraries
library(tidyverse)
library(readxl)      # safer for .xls/.xlsx
library(lme4)
library(lmerTest)    # for p-values in lmer
library(emmeans)
library(effectsize)

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

raw_imported_bx_files <- read_data("../data/bx_data/", get_subj_info = FALSE)

eye_position_SEARCH_PERIOD <- read_delim("../data/eye_data/curious_eye_position_data/Output/fixation_report_SEARCH_PERIOD_10_22.xls", 
                                delim = "\t",
                                na = na_tokens)

eye_position_data_POST_SEARCH_PERIOD <- read_delim("../data/eye_data/curious_eye_position_data/Output/fixation_report_POST_SEARCH_PERIOD_10_22.xls", 
                                delim = "\t",
                                na = na_tokens)

eye_position_data_FULL_SEARCH_PERIOD_TRAINING <- read_delim("../data/eye_data/curious_eye_position_data/Output/fixation_report_FULL_SEARCH_PERIOD_TRAINING_10_22.xls", 
                                delim = "\t",
                                na = na_tokens)
                                
eye_position_data_FULL_SEARCH_PERIOD_TRAINING <- read_delim("../data/eye_data/curious_eye_position_data/Output/fixation_report_FULL_SEARCH_PERIOD_TRAINING_10_22.xls", 
                                                            delim = "\t",
                                                            na = na_tokens)

interest_area_report <- read_delim(
  "../data/eye_data/curious_eye_position_data/Output/interest_area_report_10_22.xls",
  delim = "\t",
  na = na_tokens)#IA_LEFT, IA_RIGHT, IA_TOP, IA_BOTTOM (pixel coordinates on the display)

# Add validity column and convert subject/run to factors
all_imported_bx_files <- raw_imported_bx_files %>%
  mutate(
    valid0invalid1 = ifelse(condition == 0, 0L, 1L), #the L makes it an integer and not a float
    sub_num = as.factor(sub_num),
    run_num = as.factor(run_num),
    phase = as.factor(phase)
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
  filter(
    accuracy == 1,
    run_num != 1,
    unique_runs == 7,
    overall_accuracy > 0.80,
    sub_num != 120) %>%
  # --- Group by participant and condition factors for within-subject cleanup ---
  group_by(sub_num, valid0invalid1, phase) %>%
  # --- Remove RT outliers ---
  mutate(
    rt = ifelse(rt <= 200, NA, rt), # Hard lower bound
    mean_rt = mean(rt, na.rm = TRUE), # Compute mean and SD per participant/condition/phase
    sd_rt   = sd(rt, na.rm = TRUE),
    rt = ifelse(rt > mean_rt + 3 * sd_rt | rt < mean_rt - 3 * sd_rt, NA, rt)) %>% # Replace values more than 3 SD from the mean with NA
  ungroup() %>%
  # Optionally remove helper columns
  select(-mean_rt, -sd_rt)

removed_trials <- all_bx_files %>%
  group_by(sub_num) %>%
  summarise(
    total_trials = n(),
    kept_trials = sum(!is.na(rt)),
    removed_trials = sum(is.na(rt))
  )

unique_targets_summary <- all_imported_bx_files %>%
  group_by(sub_num, run_num) %>%
  summarise(
    unique_targets = list(unique(target_shape_idx)),
    unique_distractors = list(unique(critical_distractor_idx)),
    .groups = "drop")

# Pivot wider so runs 2 and 4 are columns
run_comparison <- unique_targets_summary %>%
  filter(run_num %in% c(2, 6)) %>%
  pivot_wider(
    names_from = run_num,
    values_from = c(unique_targets, unique_distractors),
    names_glue = "run{run_num}_{.value}"
  ) %>%
  mutate(
    # Find which targets from run 4 are *not* in distractors from run 2
    missing_target_from_run2 = map2(run6_unique_targets, run2_unique_distractors, ~ setdiff(.x, .y))
  )

#make sure this works right!!!!
all_bx_files <- all_bx_files %>%
  left_join(run_comparison %>% select(sub_num, missing_target_from_run2),
            by = "sub_num") %>%
  rowwise() %>%
  mutate(missing_target_flag = run_num %in% c(6, 7) && target_shape_idx %in% missing_target_from_run2) %>%
  ungroup()


  


# ======= RT SUMMARY & ANOVA ==============
bx_rt_summary <- all_bx_files %>%
  filter(missing_target_flag == 0) %>% 
  group_by(sub_num, valid0invalid1, phase) %>%
  summarise(meanRT = mean(rt, na.rm = TRUE), .groups = "drop") %>%
  mutate(Validity = factor(valid0invalid1, levels = c(0, 1), labels = c("Valid", "Invalid")),
         phase = fct_drop(phase))

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

#single-trial log-RT:
all_bx_files <- all_bx_files %>% mutate(log_rt = log(rt))

# Remove rows with NA log_rt
lmer_data <- all_bx_files %>% filter(!is.na(log_rt))

# Example lmer: fixed effects validity*phase, random intercepts for subject (and optionally run/item)
lmm_rt <- lmer(log_rt ~ valid0invalid1 * phase + (1 | sub_num), data = lmer_data, REML = FALSE)
summary(lmm_rt)
anova(lmm_rt)
emmeans::emmeans(lmm_rt, pairwise ~ valid0invalid1 | phase, type = "response")

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
eye_position_data <- eye_position_data %>% 
  mutate(run_num = as.numeric(str_sub(RECORDING_SESSION_LABEL, -1, -1)),
         sub_num = as.numeric(str_sub(RECORDING_SESSION_LABEL, -5, -3)),
         run_num = as.factor(run_num),
         sub_num = as.factor(sub_num)) %>% 
  group_by(sub_num, run_num) %>%       # Group by subject and run
  arrange(sub_num, run_num, TRIAL_INDEX) %>%        # Ensure proper order
  mutate(trial_num = dense_rank(TRIAL_INDEX)) %>%  # Count trial within each group
  ungroup()

eye_position_data_with_ROIs <- eye_position_data %>% 
  left_join(trial_interest_areas_wide, by = c("sub_num", "run_num", "trial_num"))

roi_names <- c("TargetBox", "NonCritDistBox1", "NonCritDistBox2", "NonCritDistBox3", "CritDistBox")

# Example for a single ROI called "target"
eye_position_data_with_ROIs <- eye_position_data_with_ROIs %>%
  mutate(
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
fixation_summary <- eye_position_data_with_ROIs %>%
  group_by(sub_num, run_num, trial_num) %>%
  summarise(
    total_fixations = n(),
    fixations_on_Target = sum(in_TargetBox, na.rm = TRUE),
    fixations_on_NonCritDist1 = sum(in_NonCritDistBox1, na.rm = TRUE),
    fixations_on_NonCritDist2 = sum(in_NonCritDistBox2, na.rm = TRUE),
    fixations_on_NonCritDist3 = sum(in_NonCritDistBox3, na.rm = TRUE),
    fixations_on_CritDist = sum(in_CritDistBox, na.rm = TRUE),
    prop_Target = mean(in_TargetBox, na.rm = TRUE),
    prop_NonCritDist1 = mean(in_NonCritDistBox1, na.rm = TRUE),
    prop_NonCritDist2 = mean(in_NonCritDistBox2, na.rm = TRUE),
    prop_NonCritDist3 = mean(in_NonCritDistBox3, na.rm = TRUE),
    prop_CritDist = mean(in_CritDistBox, na.rm = TRUE),
    first_fixation_ROI = first(current_roi),
    .groups = "drop"
  )

