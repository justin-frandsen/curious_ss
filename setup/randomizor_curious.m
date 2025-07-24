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
number_trials = 74; %74 trials per run, 6 runs total
total_trials = total_runs * number_trials; % Total trials across all runs
% Parameters
total_scenes = 111;
total_reps_per_scene = 4;
total_scenes_first_half = 74; % Total scenes in the first half of the experiment
total_scenes_second_half = 37; % Total scenes in the second half of the experiment

% there is a total of 444 trials because we have 4 targets and 3 distractors in the first half so we have to
% have the trials divisible by 12. This also divides nicely into 6 runs of 74 trials each, so that why 6 runs is chosen.
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
distractor_inds = [1 2 3 4]; % Indices of distractor shapes



%% loop through each subject
for sub_num = 1:total_subs
    %creates a struct name for this subject
    sub_struct_name = sprintf('subj%d', sub_num);
    
    % Create the subject struct
    subject_struct = struct();

    first_half_scenes = randsample(scenes_inds, total_scenes_first_half); % Randomly select 74 scenes for the first half
    second_half_scenes = setdiff(scenes_inds, first_half_scenes); % Remaining 37 scenes for the second half

    scene_randomizor_first_half = zeros(length(first_half_scenes)*4, 5);
    scene_randomizor_second_half = zeros(length(second_half_scenes)*4, 5);

    % Generate scenes and repetition labels
    row_index = 1;
    for scene_num = 1:length(first_half_scenes)
        for target = 1:total_reps_per_scene
            scene_randomizor_first_half(row_index, 1) = first_half_scenes(scene_num); % Scene number
            scene_randomizor_first_half(row_index, 2) = target; %target inds
            row_index = row_index + 1;
        end
    end

    row_index = 1;
    for scene_num = 1:length(second_half_scenes)
        for target = 1:total_reps_per_scene
            scene_randomizor_second_half(row_index, 1) = second_half_scenes(scene_num); % Scene number
            scene_randomizor_second_half(row_index, 2) = target; %target inds
            row_index = row_index + 1;
        end
    end
    % so here we make a matrix containing all of the scenes. We then randomize the order that the targets are presented in
    % because when we later add the run we use the same permutation for all runs this insures that there is diff scenes for
    % each run and that which target gets to each run is also random.

    % Initialize scene_randomizor matrix
    % Col 1: Scene number
    % Col 2: Target inds (1 to 4)
    % Col 3: Run number (to be filled)
    % Col 4: Distractor inds (1-3 in first half, none in second half)
    % Col 5: Condition (1 is invalid, 0 is valid in first half, no validity in second half)

    row_index = 1;
    rep_num = length(scene_randomizor_first_half)/4;
    for i = 1:rep_num
        scene_randomizor_first_half(row_index:row_index+3, 3) = randperm(4); % Assign runs 1 to 6
        row_index = row_index + 4; % Move to the next set of rows
    end

    run_set_second_half = [5 6];
    row_index = 1;
    rep_num = length(scene_randomizor_second_half)/2;
    for i = 1:rep_num
        scene_randomizor_second_half(row_index:row_index+1, 3) = run_set_second_half(randperm(numel(run_set_second_half))); % Assign runs 1 to 6
        row_index = row_index + 2; % Move to the next set of rows
    end

    % First half targets
    first_half_targets = randsample(shape_inds, length(target_inds)); % Randomly select 74 scenes for the first half
    first_half_distractors = setdiff(shape_inds, first_half_targets); % Remaining 37 scenes for the second half
    first_half_critical_distractors = randsample(first_half_distractors, length(distractor_inds)); %select 3 critical distractors for the first half
    first_half_distractors = setdiff(first_half_distractors, first_half_critical_distractors); % Remaining distractors for the first half

    %% RUN LOOP
    for run_num = 1:total_runs
        %get run struct name
        run_struct_name = sprintf('run%d', run_num);

        %create run struct
        run_struct = struct();
        
        if run_num <= 4
            % For runs 1-4, use the first half of the scenes
            scene_randomizor = scene_randomizor_first_half(scene_randomizor_first_half(:,3) == run_num, :);

        else
            % For runs 5-6, use the second half of the scenes
            scene_randomizor = scene_randomizor_second_half(scene_randomizor_second_half(:,3) == run_num, :);
        end
        %add variables to save out
        run_struct.('first_half_targets') = first_half_targets;
        run_struct.('first_half_distractors') = first_half_distractors;
        run_struct.('first_half_critical_distractors') = first_half_critical_distractors;
        run_struct.('scene_randomizor') = scene_randomizor;

        % Add the run struct to the subject struct and apply runStructName
        subject_struct.(run_struct_name) = run_struct;
    end
    % Add the subject struct to the main struct and apply subStructName
    randomizor_matrix.(sub_struct_name) = subject_struct;
end

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
