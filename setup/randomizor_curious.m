%-------------------------------------------------------------------------
% Script: randomizor_curious.m
% Author: Justin Frandsen
% Date: 22/07/2025 %dd/mm/yyyy
% Description: Prerandomizor for the curious_ss experiment.
%
% Usage:
% - fileDirectory: Set total subs, run, and trials, and it will randomize 
%   the order of presentation of the various scenes and trial variables.
% - Script will output a struct containing this information.
%-------------------------------------------------------------------------
%% SETTINGS
total_subs = 500;
total_runs = 6;
number_trials = 72; %72 trials per run, 6 runs total
total_trials = total_runs * number_trials; % Total trials across all runs
% Parameters
total_scenes = 108;
total_reps_per_scene = 4;
total_scenes_first_half = 72; % Total scenes in the first half of the experiment

% there is a total of 432 trials because we have 4 targets and 3 distractors in the first half so we have to
% have the trials divisible by 12. This also divides nicely into 6 runs of 72 trials each, so that why 6 runs is chosen.
% In the second half of the experiment we will have the distractors become targets and the targets become distractors.
% so we will be adding a target that was never a distractor before to test the learning of the distractor shapes.

% Restoring default RNG settings
rng('shuffle');

% Initialize the main struct to hold 500 sub-structs (subjects)
randomizor_matrix = struct();

% get all shapes in the shape dir
all_shapes = dir('../stimuli/shapes/transparent_black/*');
all_shapes = all_shapes(~ismember({all_shapes.name},{'.','..', '.DS_Store'}));

%% CREATE INDEXES FOR RANDOMIZATION
% Indices for main and practice scenes
% These will be used to randomize the order of scenes in the trials
scenes_inds = 1:total_scenes;
% Indices for all scenes
shape_inds = 1:length(all_shapes);

% target inds we can use these for randomization because we will select target inds for each person later
target_inds = [1 2 3 4]; % Indices of target shapes
distractor_inds = [1 2 3]; % Indices of distractor shapes
condition_inds = [1 2 0 0 0 0 0 0]; % Valid==1 and Invalid==2 or 3
condition_inds_second_half = [0 1 2 0 1 2]; % No validity in second half

%% loop through each subject
for sub_num = 1:total_subs
    %creates a struct name for this subject
    sub_struct_name = sprintf('subj%d', sub_num);
    
    % Create the subject struct
    subject_struct = struct();

    scene_randomizor= zeros(total_scenes*4, 6); % Initialize scene randomizor matrix

    % Generate scenes and repetition labels
    row_index = 1;
    for scene_num = 1:total_scenes
        for scene_rep = 1:total_reps_per_scene
            scene_randomizor(row_index, 1) = scene_num; % Scene number
            scene_randomizor(row_index, 2) = scene_rep;
            row_index = row_index + 1;
        end
    end

    % so here we make a matrix containing all of the scenes. We then randomize the order that the targets are presented in
    % because when we later add the run we use the same permutation for all runs this insures that there is diff scenes for
    % each run and that which target gets to each run is also random.

    % Initialize scene_randomizor matrix
    % Col 1: Scene number
    % Col 2: Scene rep number (1 to 4)
    % Col 3: Run number (to be filled)
    % Col 4: Distractor inds (1-3 in first half, none in second half)
    % Col 5: Target inds (1-4, to be filled later)
    % Col 6: Condition (1 is invalid, 0 is valid in first half, no validity in second half)

    row_index = 1;
    rep_num = length(scene_randomizor)/6;
    for i = 1:rep_num
        scene_randomizor(row_index:row_index+5, 3) = randperm(6); % Assign runs 1 to 6
        row_index = row_index + 6; % Move to the next set of rows
    end

    % First half targets
    first_half_targets = randsample(shape_inds, length(target_inds)); % Randomly select 74 scenes for the first half
    first_half_distractors = setdiff(shape_inds, first_half_targets); % Remaining 37 scenes for the second half
    first_half_critical_distractors = randsample(first_half_distractors, 4); %select 3 critical distractors for the first half
    first_half_distractors = setdiff(first_half_distractors, first_half_critical_distractors); % Remaining distractors for the first half

    this_target_ind = 1;
    %% RUN LOOP
    for run_num = 1:total_runs
        % Get run struct name
        run_struct_name = sprintf('run%d', run_num);

        % Create run struct
        run_struct = struct();

        if run_num <= 4
            % First half: get corresponding trials
            this_run_scene_randomizor = scene_randomizor(scene_randomizor(:,3) == run_num, :);

            % Assign distractor indices (1–3) and validity (0 or 1) in groups of 3
            rep_num = length(this_run_scene_randomizor)/3;
            row_index = 1;
            for i = 1:rep_num
                % Distractor indices (1–3)
                this_run_scene_randomizor(row_index:row_index+2, 4) = randperm(3);
                row_index = row_index + 3;
            end

            %shuffle the matrix containing this runs information
            shuffled_this_run_scene_randomizor = this_run_scene_randomizor(randperm(size(this_run_scene_randomizor, 1)), :);

            rep_num = length(shuffled_this_run_scene_randomizor)/length(condition_inds);
            row_index = 1;
            for i = 1:rep_num
                % Assign target indices (1–4)
                shuffled_this_run_scene_randomizor(row_index:row_index+7, 5) = this_target_ind;
                shuffled_this_run_scene_randomizor(row_index:row_index+7, 6) = condition_inds(randperm(length(condition_inds)));

                row_index = row_index + 8; % Move to the next set of rows
                this_target_ind = this_target_ind + 1; % Increment target index
                if this_target_ind > length(target_inds)
                    this_target_ind = 1; % Reset to 1 if exceeds number of targets
                end
            end

            %shuffle the matrix containing this runs information
            %shuffled_this_run_scene_randomizor = shuffled_this_run_scene_randomizor(randperm(size(shuffled_this_run_scene_randomizor, 1)), :);

            %if not mixed enough it just keeps remixing until it is remixed to the correct format
            %while true
            %    shuffled_this_run_scene_randomizor = shuffled_this_run_scene_randomizor(randperm(length(shuffled_this_run_scene_randomizor)), :);
            %    
            %    if ~any(diff(shuffled_this_run_scene_randomizor(:, 1)) > 2)
            %        break;
            %    end
            %end
        elseif run_num > 4
            % Second half (runs 5–6): no distractors and random conditions
            this_run_scene_randomizor = scene_randomizor(scene_randomizor(:,3) == run_num, :);

            %shuffle the matrix containing this runs information
            shuffled_this_run_scene_randomizor = this_run_scene_randomizor(randperm(size(this_run_scene_randomizor, 1)), :);

            rep_num = length(shuffled_this_run_scene_randomizor)/length(condition_inds_second_half);
            row_index = 1;
            for i = 1:rep_num
                % Assign target indices (1–4)
                shuffled_this_run_scene_randomizor(row_index:row_index+5, 5) = this_target_ind;
                shuffled_this_run_scene_randomizor(row_index:row_index+5, 6) = condition_inds_second_half(randperm(length(condition_inds_second_half)));

                row_index = row_index + 6; % Move to the next set of rows
                this_target_ind = this_target_ind + 1; % Increment target index
                if this_target_ind > length(target_inds)
                    this_target_ind = 1; % Reset to 1 if exceeds number of targets
                end
            end
        end

        % Store values into run struct
        run_struct.('first_half_targets') = first_half_targets;
        run_struct.('first_half_distractors') = first_half_distractors;
        run_struct.('first_half_critical_distractors') = first_half_critical_distractors;
        run_struct.('scene_randomizor') = shuffled_this_run_scene_randomizor;

        % Add to subject struct
        subject_struct.(run_struct_name) = run_struct;
    end

    % Add the subject struct to the main struct and apply subStructName
    randomizor_matrix.(sub_struct_name) = subject_struct;
end

%% check the randomization
num_runs = 6;
target_types = 1:4;
target_counts_per_run = zeros(num_runs, numel(target_types));

for run = 1:num_runs
    % Get all rows for this run
    this_run = scene_randomizor(scene_randomizor(:,3) == run, :);

    % Count how many of each target (column 2) in this run
    target_counts_per_run(run, :) = histcounts(this_run(:,2), 0.5:1:4.5);
end

% Convert to table for nicer display
target_table = array2table(target_counts_per_run, ...
    'VariableNames', {'Target1','Target2','Target3','Target4'}, ...
    'RowNames', compose('Run%d', 1:num_runs));

disp(target_table);


% Save the randomization matrix to a .mat file
%save ../trial_structure_files/randomizor.mat randomizor_matrix
