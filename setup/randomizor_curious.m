%-------------------------------------------------------------------------
% Script: randomizor_curious.m
% Author: Justin Frandsen
% Date: 2025/08/05 yyyy/mm/dd
% Description: Prerandomizor for the curious_ss experiment.
%
% Usage:
% - Set total subs, runs, and trials
% - Outputs a struct with randomized scene/trial parameters
%-------------------------------------------------------------------------

%% SETTINGS
total_subs              = 500;
total_runs              = 6;
number_trials           = 72;                        % Trials per run
total_trials            = total_runs * number_trials;

total_scenes            = 108;
total_reps_per_scene    = 4;
total_scenes_first_half = 72;

% Trial conditions
target_inds             = [1 2 3 4];
distractor_inds         = [1 2 3];
condition_inds          = [1 2 0 0 0 0 0 0];         % 1 = valid, 2 = invalid
condition_inds_second_half = [0 1 2 0 1 2];          % Second half (no validity)

% Generate all permutations of [0 0 1 1] for target direction assignment
t_directions            = [0 0 1 1];
all_t_directions        = unique(perms(t_directions), 'rows');

% Restore RNG
rng('shuffle');

% Get all shape files
all_shapes = dir('../stimuli/shapes/transparent_black/*');
all_shapes = all_shapes(~ismember({all_shapes.name}, {'.','..','.DS_Store'}));
shape_inds = 1:length(all_shapes);

%% MAIN SUBJECT LOOP
randomizor_matrix = struct();

fprintf('[INFO] Starting subject loop for %d subjects...\n', total_subs);

for sub_num = 1:total_subs
    sub_struct_name = sprintf('subj%d', sub_num);
    subject_struct  = struct();
    scene_randomizor = zeros(total_scenes * 4, 6);

    %-------------------------------------------------
    % Fill scene and repetition numbers
    %-------------------------------------------------
    row_index = 1;
    for scene_num = 1:total_scenes
        for scene_rep = 1:total_reps_per_scene
            scene_randomizor(row_index, 1) = scene_num;
            scene_randomizor(row_index, 2) = scene_rep;
            row_index = row_index + 1;
        end
    end

    %-------------------------------------------------
    % Assign run numbers to scene repetitions
    %-------------------------------------------------
    row_index = 1;
    for i = 1:(length(scene_randomizor) / 6)
        scene_randomizor(row_index:row_index+5, 3) = randperm(6);
        row_index = row_index + 6;
    end

    %-------------------------------------------------
    % Target & Distractor Shape Assignment
    %-------------------------------------------------
    first_half_targets              = randsample(shape_inds, length(target_inds));
    first_half_distractors          = setdiff(shape_inds, first_half_targets);
    first_half_critical_distractors = randsample(first_half_distractors, 4);
    noncritical_distractors         = setdiff(first_half_distractors, first_half_critical_distractors);

    target_associations             = [1 2 3 randi(3)];
    target_associations             = target_associations(randperm(4));
    critical_distractors_associations = randperm(3);

    %-------------------------------------------------
    % Distractor Pairs (First Half)
    %-------------------------------------------------
    unique_pairs    = nchoosek(noncritical_distractors, 2);
    flipped_pairs   = unique_pairs(:, [2 1]);
    all_pairs       = [unique_pairs; flipped_pairs];
    all_distractor_pairs = repmat(all_pairs, 2, 1);

    first_half_distractors = shuffle_matrix(all_distractor_pairs, [1 2], [2 2]);

    row_index = 1;
    for t_run = 1:4
        first_half_distractors(row_index:row_index+71, 3) = t_run;
        row_index = row_index + 72;
    end

    %-------------------------------------------------
    % Distractor Triples (Second Half)
    %-------------------------------------------------
    unique_triples = nchoosek(noncritical_distractors, 3);
    all_triples    = [];

    for i = 1:size(unique_triples, 1)
        all_triples = [all_triples; perms(unique_triples(i, :))];
    end

    second_half_distractors = shuffle_matrix(all_triples, [1 2 3], [3 3 3]);

    row_index = 1;
    for t_run = 1:2
        second_half_distractors(row_index:row_index+71, 3) = t_run + 4;  % Run 5 & 6
        row_index = row_index + 72;
    end

    %% RUN LOOP
    this_target_ind = 1;

    for run_num = 1:total_runs
        run_struct_name = sprintf('run%d', run_num);
        run_struct = struct();

        %-----------------------------
        % First Half (Runs 1–4)
        %-----------------------------
        if run_num <= 4
            this_run_scene_randomizor = scene_randomizor(scene_randomizor(:,3) == run_num, :);

            % Distractors (groups of 3)
            row_index = 1;
            for i = 1:(length(this_run_scene_randomizor)/3)
                this_run_scene_randomizor(row_index:row_index+2, 4) = randperm(3);
                row_index = row_index + 3;
            end

            % Shuffle and assign target/condition
            shuffled_this_run_scene_randomizor = this_run_scene_randomizor(randperm(size(this_run_scene_randomizor, 1)), :);

            row_index = 1;
            for i = 1:(length(shuffled_this_run_scene_randomizor)/length(condition_inds))
                shuffled_this_run_scene_randomizor(row_index:row_index+7, 5) = this_target_ind;
                shuffled_this_run_scene_randomizor(row_index:row_index+7, 6) = condition_inds(randperm(length(condition_inds)));
                row_index = row_index + 8;
                this_target_ind = mod(this_target_ind, 4) + 1;
            end

            shuffled_this_run_scene_randomizor = shuffle_matrix(shuffled_this_run_scene_randomizor, [1 4 5], [1 3 2], 10000);
            this_run_distractors = first_half_distractors(first_half_distractors(:,3) == run_num, :);

        %-----------------------------
        % Second Half (Runs 5–6)
        %-----------------------------
        else
            this_run_scene_randomizor = scene_randomizor(scene_randomizor(:,3) == run_num, :);
            shuffled_this_run_scene_randomizor = this_run_scene_randomizor(randperm(size(this_run_scene_randomizor, 1)), :);

            row_index = 1;
            for i = 1:(length(shuffled_this_run_scene_randomizor)/length(condition_inds_second_half))
                shuffled_this_run_scene_randomizor(row_index:row_index+5, 5) = this_target_ind;
                shuffled_this_run_scene_randomizor(row_index:row_index+5, 6) = condition_inds_second_half(randperm(length(condition_inds_second_half)));
                row_index = row_index + 6;
                this_target_ind = mod(this_target_ind, 4) + 1;
            end

            shuffled_this_run_scene_randomizor = shuffle_matrix(shuffled_this_run_scene_randomizor, [1 5], [1 2]);
            this_run_distractors = second_half_distractors(second_half_distractors(:,3) == run_num, :);
        end

        %-----------------------------
        % Target Directions Assignment
        %-----------------------------
        rep_num = length(shuffled_this_run_scene_randomizor) / length(all_t_directions);
        this_run_all_t_directions = repmat(all_t_directions, rep_num, 1);
        this_run_all_t_directions = this_run_all_t_directions(randperm(size(this_run_all_t_directions, 1)), :);

        %-----------------------------
        % Store in run struct
        %-----------------------------
        run_struct.first_half_targets               = first_half_targets;
        run_struct.noncritical_distractors          = noncritical_distractors;
        run_struct.first_half_critical_distractors  = first_half_critical_distractors;
        run_struct.scene_randomizor                 = shuffled_this_run_scene_randomizor;
        run_struct.t_directions                     = this_run_all_t_directions;
        run_struct.target_associations              = target_associations;
        run_struct.critical_distractors_associations = critical_distractors_associations;
        run_struct.this_run_distractors             = this_run_distractors;

        subject_struct.(run_struct_name) = run_struct;
    end

    if mod(sub_num, 50) == 0
        fprintf('[INFO] Subject %d/%d complete\n', sub_num, total_subs);
    end
end

fprintf('[INFO] All subject randomization complete.\n');

if save_output
    save('../trial_structure_files/randomizor.mat', 'randomizor_matrix');
    fprintf('[INFO] Saved to ../trial_structure_files/randomizor.mat\n');
end
