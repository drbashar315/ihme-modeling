#######################################################################################
### Date:     13th May 2019
### Purpose:  Estimate Sex-ratio and crosswalks for GBD2019
#######################################################################################

bundle_id <- 167
acause <-"mental_adhd"
covariates <- c("cv_no_inf_agreement")
uses_csmr <- F
test_sex_by_super_region <- F
crosswalk_pairs <- 'FILEPATH.csv'
age_sex_split_estimates <- "FILEPATH.xlsx"
need_to_age_split <- F
need_save_bundle_version <- 7391 # Set as true to save bundle version, otherwise specify bundle version here
sex_ratio_by_age <- F

library(data.table)
library(openxlsx)
library(msm)
source("FILEPATH")
source("FILEPATH")
source("FILEPATH")
source("FILEPATH")
source("FILEPATH")
source("FILEPATH")
source("FILEPATH")
source("FILEPATH")

## Get latest review sheet ##
if(need_save_bundle_version == T){
  v_id <- save_bundle_version(bundle_id, "step2")$bundle_version_id
} else {
  v_id <- need_save_bundle_version
}
v_id
review_sheet <- get_bundle_version(v_id)

## Flag if age-split by regional pattern estimates exist ##
if(length(review_sheet[(grepl("age-split child", specificity)),unique(nid)]) > 0){
  print(paste0("STOP! The following nid still has age-split estimates by regional pattern in your bundle version: ", review_sheet[(grepl("age-split child", specificity)),unique(nid)]))
}

## Remove excluded estimates ##
review_sheet[is.na(group_review), group_review := 1]
review_sheet <- review_sheet[group_review == 1, ]
review_sheet[, study_covariate := "ref"]

review_sheet[is.na(standard_error) & !is.na(lower), standard_error := (upper - lower) / (qnorm(0.975,0,1)*2)]
review_sheet[is.na(standard_error) & measure == "prevalence", standard_error := sqrt(1/sample_size * mean * (1-mean) + 1/(4*sample_size^2)*qnorm(0.975,0,1)^2)]
review_sheet[is.na(standard_error) & measure %in% c("incidence", "remission"), standard_error :=  ifelse(mean*sample_size <= 5, ((5-mean*sample_size) / sample_size + mean * sample_size * sqrt(5/sample_size^2))/5, ((mean*sample_size)^0.5)/sample_size)]

##### Estimate and apply sex-ratios -----------------------------------------------------------------------

## Create paired dataset where each row is a sex pair ##
match_columns <- c("nid", "age_start", "age_end", "location_id", "site_memo", "year_start", "year_end", "measure", covariates)
males <- review_sheet[sex == "Male" & is_outlier == 0, c(match_columns, "mean", "standard_error"), with = F]
females <- review_sheet[sex == "Female" & is_outlier == 0, c(match_columns, "mean", "standard_error"), with = F]
setnames(males, "mean", "mean_m")
setnames(males, "standard_error", "se_m")
setnames(females, "mean", "mean_f")
setnames(females, "standard_error", "se_f")
sex_ratios <- merge(males, females, by = match_columns)

## Match on regions ##
locations <- get_location_metadata(location_set_id=9)
sex_ratios <- merge(sex_ratios, locations[,.(location_id, region_id, region_name, super_region_id, super_region_name)], by = "location_id")
sex_ratios<- sex_ratios[!(measure %in% c("mtspecific")), ]
sex_ratios[, `:=` (ratio = mean_m / mean_f, se = sqrt(((mean_m^2 / mean_f^2) * ((se_m^2) / (mean_m^2) + (se_f^2) / (mean_f^2)))),
                     mid_age = (age_start + age_end) / 2, mid_year = (year_start + year_end) / 2)]

mean_mid_age <- mean(sex_ratios$mid_age)

sex_ratios[, mc_mid_age := mid_age - mean(mid_age)]

sex_ratios[, log_ratio := log(ratio)]
sex_ratios[, log_ratio_se := deltamethod(~log(x1), ratio, se^2), by = c("ratio", "se")]

table(sex_ratios[!is.na(ratio) & ratio != 0, measure])

# Create measure CVs
if(uses_csmr == T){sex_ratios <- sex_ratios[!(measure %in% c("mtstandard"))]}

measures <- unique(sex_ratios$measure)

for(m in measures){
  sex_ratios[, paste0("cv_", m) := ifelse(measure == m, 1, 0)]
}

table(sex_ratios$super_region_name)

# Create geographic CVs #
sex_locations <- unique(sex_ratios$super_region_id)
for(r in sex_locations){
  sex_ratios[, paste0("cv_", r) := ifelse(super_region_id == r, 1, 0)]
}

# Create covlist
for(c in paste0("cv_", measures)){
  cov <- cov_info(c, "X")
  if(c == paste0("cv_", measures)[1]){
    cov_list <- list(cov)
  } else {
    cov_list <- c(cov_list, list(cov))
  }
}

if(test_sex_by_super_region == T){
  for(c in paste0("cv_", sex_locations[sex_locations != 64])){
    cov <- cov_info(c, "X")
    cov_list <- c(cov_list, list(cov))
  }
}

sex_ratios[, prev_by_mid_age := cv_prevalence * mc_mid_age]
if(sex_ratio_by_age == T){ cov_list <- c(cov_list, list(cov_info("prev_by_mid_age", "X")))}

dir.create(file.path(paste0("/FILEPATH/", acause, "/")), showWarnings = FALSE)

## Run MR-BRT ##
model <- run_mr_brt(
  output_dir = paste0("/FILEPATH/", acause, "/"),
  model_label = "sex",
  data = sex_ratios[!is.na(ratio) & ratio != 0 & ratio != Inf,],
  mean_var = "log_ratio",
  se_var = "log_ratio_se",
  covs = cov_list,
  remove_x_intercept = T,
  method = "trim_maxL",
  trim_pct = 0.1,
  study_id = "nid",
  overwrite_previous = TRUE,
  lasso = F)

sex_coefs  <- data.table(load_mr_brt_outputs(model)$model_coef)
sex_coefs[, `:=` (lower = beta_soln - sqrt(beta_var)*qnorm(0.975, 0, 1), upper = beta_soln + sqrt(beta_var)*qnorm(0.975, 0, 1))]
sex_coefs[, `:=` (sig = ifelse(lower * upper > 0, "Yes", "No"))]
sex_coefs

check_for_outputs(model)

if(sex_ratio_by_age == F){
  eval(parse(text = paste0("sex_ratio <- expand.grid(", paste0(paste0("cv_", measures), "=c(0, 1)", collapse = ", "), ")")))
  sex_ratio <- as.data.table(predict_mr_brt(model, newdata = sex_ratio)["model_summaries"])
  names(sex_ratio) <- gsub("model_summaries.", "", names(sex_ratio))
  names(sex_ratio) <- gsub("X_", "", names(sex_ratio))
} else {
  eval(parse(text = paste0("sex_ratio <- expand.grid(", paste0(paste0("cv_", measures), "=c(0, 1)", collapse = ", "), ", prev_by_mid_age = c((0-mean_mid_age):(100-mean_mid_age), 0))")))
  sex_ratio <- as.data.table(predict_mr_brt(model, newdata = sex_ratio)["model_summaries"])
  names(sex_ratio) <- gsub("model_summaries.", "", names(sex_ratio))
  names(sex_ratio) <- gsub("X_", "", names(sex_ratio))
  sex_ratio <- rbind(sex_ratio[cv_remission == 1 & cv_prevalence == 0 & prev_by_mid_age == 0, ], sex_ratio[cv_remission == 0 & cv_prevalence == 1, ])
}

sex_ratio[, measure := ""]
for(m in names(sex_ratio)[names(sex_ratio) %like% "cv_"]){
  sex_ratio[get(m) == 1, measure := ifelse(measure != "", paste0(measure, ", "), m)]
}
sex_ratio[, measure := gsub("cv_", "", measure)]
sex_ratio <- sex_ratio[measure %in% measures,]

sex_ratio[, `:=` (ratio = exp(Y_mean), ratio_se = (exp(Y_mean_hi) - exp(Y_mean_lo))/(2*qnorm(0.975,0,1)))]
sex_ratio[, (c(paste0("cv_", measures), "Y_mean", "Z_intercept", "Y_negp", "Y_mean_lo", "Y_mean_hi", "Y_mean_fe", "Y_negp_fe", "Y_mean_lo_fe", "Y_mean_hi_fe")) := NULL]

if(sex_ratio_by_age == T){
  sex_ratio[, `:=` (mid_age = prev_by_mid_age+mean_mid_age, prev_by_mid_age = NULL)]
  sex_ratio[, mid_age := round(mid_age)]
  sex_ratio <- unique(sex_ratio, by = c("measure", "mid_age"))

  sex_ratio <- rbind(sex_ratio[measure == "prevalence", ], data.table(measure = "remission", ratio = sex_ratio[measure == "remission", ratio],
             ratio_se = sex_ratio[measure == "remission", ratio_se], mid_age = c(0:100)))
}

write.csv(sex_ratio, paste0("/FILEPATH/", acause, "/FILEPATH.csv"),row.names=F)

## Load in estimates that are age-sex split using the study sex-ratio
age_sex_split <- data.table(read.xlsx(age_sex_split_estimates))
sex_parents <- age_sex_split[age_sex_split == -1 & sex != "Both", seq]
age_parents <- age_sex_split[age_sex_split == -1 & sex == "Both", seq]
review_sheet[seq %in% c(sex_parents, age_parents) & group_review == 0,] 
outlier_agesexsplit <- review_sheet[seq %in% c(sex_parents, age_parents) & is_outlier == 1, seq] 

age_sex_split <- age_sex_split[age_sex_split == 1, ]
age_sex_split[age_parent %in% outlier_agesexsplit, is_outlier := 1]
age_sex_split[sex_parent %in% outlier_agesexsplit, is_outlier := 1]
age_sex_split[, seq := NA]

## Crosswalk both-sex data ##
review_sheet_both <- review_sheet[sex == "Both" & !(seq %in% age_parents), ]
review_sheet_both[, `:=` (crosswalk_parent_seq = NA)]

review_sheet_both[, mid_age := round((age_start + age_end) / 2)]

population <- get_population(location_id = unique(review_sheet_both$location_id), decomp_step = 'step2', age_group_id = c(1, 6:20, 30:32, 235), sex_id = c(1, 2), year_id = seq(min(review_sheet_both$year_start), max(review_sheet_both$year_end)))
age_ids <- get_ids('age_group')[age_group_id %in% c(1, 6:20, 30:32, 235),]
suppressWarnings(age_ids[, `:=` (age_start = as.numeric(unlist(strsplit(age_group_name, " "))[1]), age_end = as.numeric(unlist(strsplit(age_group_name, " "))[3])), by = "age_group_id"])
age_ids[age_group_id == 1, `:=` (age_start = 0, age_end = 4)]
age_ids[age_group_id == 235, `:=` (age_end = 99)]
population <- merge(population, age_ids, by = "age_group_id")


if(sex_ratio_by_age == T){
  review_sheet_both <- merge(review_sheet_both, sex_ratio, by = c("measure", "mid_age"))
} else {
  review_sheet_both <- merge(review_sheet_both, sex_ratio, by = "measure")
}

review_sheet_both[, `:=` (mid_age = (age_start + age_end) / 2, age_start_r = round(age_start/5)*5, age_end_r = round(age_end/5)*5)]
review_sheet_both[age_start_r == age_end_r & mid_age < age_start_r, age_start_r := age_start_r - 5]
review_sheet_both[age_start_r == age_end_r & mid_age >= age_start_r, age_end_r := age_end_r + 5]
review_sheet_both[, age_end_r := age_end_r - 1]

pop_agg <- function(l, a_s, a_e, y_s, y_e, s){
  a_ids <- age_ids[age_start %in% c(a_s:a_e-4) & age_end %in% c(a_s+4:a_e), age_group_id]
  pop <- population[location_id == l & age_group_id %in% a_ids & sex_id == s & year_id %in% c(y_s:y_e),sum(population)]
  return(pop)
}

review_sheet_both[, pop_m := pop_agg(location_id, age_start_r, age_end_r, year_start, year_end, s = 1), by = "seq"]
review_sheet_both[, pop_f := pop_agg(location_id, age_start_r, age_end_r, year_start, year_end, s = 2), by = "seq"]
review_sheet_both[, pop_b := pop_m + pop_f]

review_sheet_female <- copy(review_sheet_both)
review_sheet_female[, `:=` (sex = "Female", mean_n = mean * (pop_b), mean_d =(pop_f + ratio * pop_m),
                            var_n = (standard_error^2 * pop_b^2), var_d = ratio_se^2 * pop_m^2)]
review_sheet_female[, `:=` (mean = mean_n / mean_d, standard_error = sqrt(((mean_n^2) / (mean_d^2)) * (var_n / (mean_n^2) + var_d / (mean_d^2))))]
review_sheet_female[, `:=` (study_covariate = "sex", crosswalk_parent_seq = seq, seq = NA)]

review_sheet_male <- copy(review_sheet_both)
review_sheet_male[, `:=` (sex = "Male", mean_n = mean * (pop_b), mean_d =(pop_m + (1/ratio) * pop_f),
                            var_n = (standard_error^2 * pop_b^2), var_d = ratio_se^2 * pop_f^2)]
review_sheet_male[, `:=` (mean = mean_n / mean_d, standard_error = sqrt(((mean_n^2) / (mean_d^2)) * (var_n / (mean_n^2) + var_d / (mean_d^2))))]
review_sheet_male[, `:=` (study_covariate = "sex", crosswalk_parent_seq = seq, seq = NA)]

review_sheet_final <- rbind(review_sheet_male, review_sheet_female, review_sheet[sex != "Both",], fill = T)
col_remove <- c("mid_age", "age_start_r", "age_end_r", "pop_m", "pop_f", "pop_b", "mean_n", "mean_d", "var_n", "var_d", "ratio", "ratio_se")
review_sheet_final[, (col_remove) := NULL]

## Re-add estimates that are age-sex split using the study sex-ratio

setnames(age_sex_split, "age_parent", "crosswalk_parent_seq")
age_sex_split[, `:=` (study_covariate = "sex", sex_parent = NULL, seq = NULL)] 
age_sex_split[, `:=` (seq = NA)] #
review_sheet_final <- review_sheet_final[!(seq %in% c(sex_parents, age_parents)),] 
review_sheet_final <- rbind(review_sheet_final, age_sex_split, fill = T) 

review_sheet_final[is.na(standard_error), standard_error := (upper-lower) / 3.92]

review_sheet_backup <- copy(review_sheet_final) 

##### Estimate and apply study-level covariates -----------------------------------------------------------------------

# ---------- No crosswalks for this cause so removed code ------------

# For upload validation #
review_sheet_final[study_covariate != "ref", `:=` (lower = NA, upper = NA, cases = NA, sample_size = NA)]
review_sheet_final[is.na(lower), uncertainty_type_value := NA]

review_sheet_final <- review_sheet_final[group_review == 1, ] 

review_sheet_final[is.na(group), group := nid]
review_sheet_final[specificity == "", specificity := "Unspecified"]
review_sheet_final[nid == 272807, step2_location_year := "Correction to study years"]

crosswalk_save_folder <- paste0("/FILEPATH/", acause, "/", bundle_id, "/FILEPATH/")
dir.create(file.path(crosswalk_save_folder), showWarnings = FALSE)
crosswalk_save_file <- paste0(crosswalk_save_folder, "crosswalk_", Sys.Date(), "_", paste(covariates), ".xlsx")
write.xlsx(review_sheet_final, crosswalk_save_file, sheetName = "extraction")

##### Upload crosswalked dataset to database -----------------------------------------------------------------------

save_crosswalk_version(v_id, crosswalk_save_file, description = paste0("MR-BRT sex ratio applied.", covariates))



