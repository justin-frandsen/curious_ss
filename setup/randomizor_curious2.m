%-------------------------------------------------------------------------
% Script: randomizor_curious.m
% Author: Justin Frandsen
% Date: 22/07/2025
% Description: Prerandomizor for the curious_ss experiment.
%-------------------------------------------------------------------------

%% CONFIGURATION
SAVE_OUTPUT = true;  % Set to true to save .mat file

% Constants for readability
SCENE_ID   = 1;
REP        = 2;
RUN        = 3;
DISTRACTOR = 4;
TARGET     = 5;
CONDITION  = 6;

% Experiment parameters
total_subs              = 500;
total_runs              = 6;
number_trials_per_run   = 72;
total_trials            = total_runs * number_trials_per_run;
total_scenes            = 108;
total_reps_per_scene    = 4;

% Trial condition indexing
target_inds             = [1 2 3 4];
distractor_inds         = [1 2 3];
condition_inds          = [1 2 0 0 0 0 0 0];
condition_inds_second   = [0 1 2 0 1 2];

% Load all shapes
all_shapes = dir('../stimuli/shapes/transparent_black/*');
all_shapes = all_shapes(~ismember({all_shapes.name}, {'.','..','.DS_Store'}));
shape_inds = 1:length(all_shapes);

% Ensure valid setup
assert(mod(total_scenes * total_reps_per_scene, total_runs) == 0, 'Scene repetitions must divide evenly into runs.');
assert(length(condition_inds) == 8, 'Expected 8 conditions per block.');

% Generate all permutations of [0 0 1 1]
t_directions = unique(perms([0 0 1 1]), 'rows');

%% Initialize main output struct
randomizor_matrix = struct();
rng('shuffle');  % Randomize RNG for subject variation

fprintf('[INFO] Beginning randomization for %d subjects...\n', total_subs);

%% Main subject loop
for sub_num = 1:total_subs
    sub_struct_name = sprintf('subj%d', sub_num);
    subject_struct = struct();

    %% Initialize scene matrix: [scene_id, repetition, run, distractor, target, condition]
    scene_randomizor = zeros(total_scenes * total_reps_per_scene, 6);
    row = 1;
    for scene = 1:total_scenes
        for rep = 1:total_reps_per_scene
            scene_randomizor(row, SCENE_ID:REP) = [scene, rep];
            row = row + 1;
        end
    end

    % Assign randomized runs
    scene_randomizor = assign_balanced_runs(scene_randomizor, total_runs);

    %% Define target and distractor shapes
    first_half_targets = randsample(shape_inds, length(target_inds));
    all_distractors = setdiff(shape_inds, first_half_targets);
    first_half_critical_distractors = randsample(all_distractors, 4);
    noncritical_distractors = setdiff(all_distractors, first_half_critical_distractors);

    target_associations = [1 2 3 randi(3)];
    target_associations = target_associations(randperm(4));
    critical_distractor_associations = randperm(3);

    %% Generate distractor pairings (first half)
    pairs = nchoosek(noncritical_distractors, 2);
    flipped = pairs(:, [2 1]);
    all_pairs = [pairs; flipped];
    first_half_distractors = repmat(all_pairs, 2, 1);
    first_half_distractors = shuffle_matrix(first_half_distractors, [1 2], [2 2]);

    % Assign runs to distractor pairs
    row = 1;
    for run = 1:4
        first_half_distractors(row:row+71, 3) = run;
        row = row + 72;
    end

    %% Generate distractor triplets (second half)
    triplets = nchoosek(noncritical_distractors, 3);
    all_triplets = [];
    for i = 1:size(triplets, 1)
        all_triplets = [all_triplets; perms(triplets(i, :))];
    end
    second_half_distractors = shuffle_matrix(all_triplets, [1 2 3], [3 3 3]);

    row = 1;
    for run = 5:6
        second_half_distractors(row:row+71, 3) = run;
        row = row + 72;
    end

    %% Run loop
    current_target = 1;
    for run = 1:total_runs
        run_struct = struct();
        run_name = sprintf('run%d', run);

        % Extract trials for this run
        this_run_scene = scene_randomizor(scene_randomizor(:, RUN) == run, :);

        if run <= 4
            for i = 1:24
                idx = (i-1)*3 + 1;
                this_run_scene(idx:idx+2, DISTRACTOR) = randperm(3);
            end

            this_run_scene = this_run_scene(randperm(size(this_run_scene, 1)), :);

            for i = 1:9
                idx = (i-1)*8 + 1;
                this_run_scene(idx:idx+7, TARGET) = current_target;
                this_run_scene(idx:idx+7, CONDITION) = condition_inds(randperm(8));
                current_target = mod(current_target, 4) + 1;
            end

            this_run_scene = shuffle_matrix(this_run_scene, [SCENE_ID DISTRACTOR TARGET], [1 3 2], 10000);
            run_distractors = first_half_distractors(first_half_distractors(:,3) == run, :);

        else
            this_run_scene = this_run_scene(randperm(size(this_run_scene, 1)), :);
            for i = 1:12
                idx = (i-1)*6 + 1;
                this_run_scene(idx:idx+5, TARGET) = current_target;
                this_run_scene(idx:idx+5, CONDITION) = condition_inds_second(randperm(6));
                current_target = mod(current_target, 4) + 1;
            end

            this_run_scene = shuffle_matrix(this_run_scene, [SCENE_ID TARGET], [1 2]);
            run_distractors = second_half_distractors(second_half_distractors(:,3) == run, :);
        end

        rep_count = length(this_run_scene) / size(t_directions, 1);
        full_directions = repmat(t_directions, rep_count, 1);
        full_directions = full_directions(randperm(size(full_directions, 1)), :);

        run_struct.first_half_targets = first_half_targets;
        run_struct.noncritical_distractors = noncritical_distractors;
        run_struct.first_half_critical_distractors = first_half_critical_distractors;
        run_struct.scene_randomizor = this_run_scene;
        run_struct.t_directions = full_directions;
        run_struct.target_associations = target_associations;
        run_struct.critical_distractors_associations = critical_distractor_associations;
        run_struct.this_run_distractors = run_distractors;

        subject_struct.(run_name) = run_struct;
    end

    randomizor_matrix.(sub_struct_name) = subject_struct;

    if mod(sub_num, 50) == 0
        fprintf('[INFO] Completed subject %d/%d\n', sub_num, total_subs);
    end
end

fprintf('[INFO] Randomization complete.\n');

if SAVE_OUTPUT
    save('../trial_structure_files/randomizor.mat', 'randomizor_matrix');
    fprintf('[INFO] Output saved to ../trial_structure_files/randomizor.mat\n');
end

%% Function definitions (must be at end in MATLAB scripts)
function scene_randomizor = assign_balanced_runs(scene_randomizor, total_runs)
    RUN = 3;
    num_rows = size(scene_randomizor, 1);
    rows_per_block = total_runs;
    assert(mod(num_rows, rows_per_block) == 0, 'Scene rows must divide evenly by total runs.');
    row_index = 1;
    for i = 1:(num_rows / rows_per_block)
        scene_randomizor(row_index:row_index + rows_per_block - 1, RUN) = randperm(total_runs);
        row_index = row_index + rows_per_block;
    end
end
