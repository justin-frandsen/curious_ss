%-------------------------------------------------------------------------
% Script: randomizor_curious_balanced.m
% Author: Justin Frandsen
% Date: 25/07/2025
% Description: Generates a balanced trial structure for the curious_ss
% experiment.
%-------------------------------------------------------------------------

%% SETTINGS
clear;
total_subs = 2;
total_runs = 6;
trials_per_run = 74;
total_trials = total_runs * trials_per_run; % 444 trials total
check = 1;

num_targets = 4;
num_distractors = 3;
target_inds = 1:num_targets;
distractor_inds = 1:num_distractors;
total_combinations = num_targets * num_distractors;
trials_per_combination = total_trials / total_combinations; % = 37

num_scenes = 111;
reps_per_scene = 4;

validity_first_half = [1 1 1 1 1 1 1 2 3]; % Mostly valid trials
condition_inds = repmat(validity_first_half, 1, ceil(total_trials/length(validity_first_half)));
condition_inds = condition_inds(1:total_trials);
condition_inds = condition_inds(randperm(total_trials));

% Get all shapes
all_shapes = dir('../stimuli/shapes/transparent_black/*');
all_shapes = all_shapes(~ismember({all_shapes.name},{'.','..','.DS_Store'}));
shape_inds = 1:length(all_shapes);

%% LOOP THROUGH SUBJECTS
randomizor_matrix = struct();
for sub_num = 1:total_subs
    sub_struct_name = sprintf('subj%d', sub_num);
    subject_struct = struct();

    %% STEP 1: CREATE FULL TRIAL TABLE (444 trials)
    trial_list = [];
    for t = 1:num_targets
        for d = 1:num_distractors
            for rep = 1:trials_per_combination
                trial_list = [trial_list; t, d];
            end
        end
    end

    % Shuffle trial order
    trial_list = trial_list(randperm(size(trial_list, 1)), :);

    % Assign scenes (each scene 4 times)
    all_scene_ids = repmat(1:num_scenes, 1, reps_per_scene);
    all_scene_ids = all_scene_ids(randperm(length(all_scene_ids))); % 111 x 4 = 444

    % Construct base trial matrix
    % Col 1: Scene ID
    % Col 2: Target Index
    % Col 3: Distractor Index
    % Col 4: Validity (1=valid, 2=invalid, 3=neutral)
    % Col 5: Run Number
    trial_matrix = [all_scene_ids(:), trial_list, condition_inds(:), zeros(total_trials,1)];
    lookie = trial_matrix;
    %% STEP 2: ASSIGN TRIALS TO RUNS WITH BALANCED TARGETS AND UNIQUE SCENES
    assigned = false;
    while ~assigned
        trial_matrix(:,5) = 0; % Reset run assignments
        scene_used_in_run = cell(total_runs, 1);
        run_counts = zeros(total_runs, num_targets);
        success = true;

        % Random trial order
        trial_order = randperm(total_trials);

        for i = 1:total_trials
            scene_id = trial_matrix(trial_order(i), 1);
            target_id = trial_matrix(trial_order(i), 2);

            % Try assigning to a run
            assigned_this = false;
            run_pool = randperm(total_runs);
            for run = run_pool
                if run_counts(run, target_id) < floor(trials_per_run / num_targets) + 1 && ...
                   ~ismember(scene_id, scene_used_in_run{run}) && ...
                   sum(trial_matrix(:,5)==run) < trials_per_run
                    
                    trial_matrix(trial_order(i),5) = run;
                    run_counts(run, target_id) = run_counts(run, target_id) + 1;
                    scene_used_in_run{run}(end+1) = scene_id;
                    assigned_this = true;
                    break;
                end
            end

            if ~assigned_this
                success = false;
                break;
            end
        end

        if success
            assigned = true;
        end
    end

    %% STEP 3: BUILD RUN STRUCTS
    for run_num = 1:total_runs
        run_struct_name = sprintf('run%d', run_num);
        run_struct = struct();

        run_trials = trial_matrix(trial_matrix(:,5)==run_num, :);

        run_struct.scene_ids = run_trials(:,1);
        run_struct.target_inds = run_trials(:,2);
        run_struct.distractor_inds = run_trials(:,3);
        run_struct.conditions = run_trials(:,4);

        % Use the same distractor set for all runs
        run_struct.distractor_shapes = distractor_inds;
        run_struct.target_shapes = randsample(shape_inds, num_targets);

        subject_struct.(run_struct_name) = run_struct;
    end
    %% STEP 4: PRINT TARGET COUNTS AND SCENE REUSE CHECK
    if check == 1
        fprintf('Subject %d\n', sub_num);
        target_counts = zeros(total_runs, num_targets);
        scene_check = true;
        for run = 1:total_runs
            run_trials = trial_matrix(trial_matrix(:,5)==run, :);
            target_counts(run,:) = histcounts(run_trials(:,2), 0.5:1:4.5);
            unique_scenes = unique(run_trials(:,1));
            if length(unique_scenes) < size(run_trials,1)
                fprintf('Scene repeated in run %d!\n', run);
                scene_check = false;
            end
        end
        target_table = array2table(target_counts, 'VariableNames', {'Target1','Target2','Target3','Target4'}, 'RowNames', compose('Run%d', 1:total_runs));
        disp(target_table);
        if scene_check
            fprintf('No scenes repeated within runs.\n\n');
        end
    end

    randomizor_matrix.(sub_struct_name) = subject_struct;
end

% Optional: Save
% save('../trial_structure_files/randomizor_balanced.mat', 'randomizor_matrix');