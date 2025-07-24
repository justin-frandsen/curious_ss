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

% there is a total of 444 trials because we have 4 targets and 3 distractors in the first half so we have to
% have the trials divisible by 12. This also divides nicely into 6 runs of 74 trials each, so that why 6 runs is chosen.
% In the second half of the experiment we will have the distractors become targets and the targets become distractors.
% so we will be adding a target that was never a distractor before to test the learning of the distractor shapes.

% Restoring default RNG settings
rng('shuffle');

% Initialize the main struct to hold 500 sub-structs (subjects)
randomizor_matrix = struct();

%% GET THE STIMULI INFO FROM THE DIRECTORIES
% get all main scenes
all_scenes = dir('../stimuli/scenes/*');
all_scenes = all_scenes(~ismember({all_scenes.name},{'.','..','.DS_Store'}));


% get all shapes in the shape dir
all_shapes = dir('../stimuli/shapes/transparent_black/*');
all_shapes = all_shapes(~ismember({all_shapes.name},{'.','..', '.DS_Store'}));

%% CREATE INDEXES FOR RANDOMIZATION
% Indices for main and practice scenes
% These will be used to randomize the order of scenes in the trials
scenes_inds = 1:length(all_scenes);
% Indices for all scenes
shape_inds = 1:length(all_shapes);

% target inds we can use these for randomization because we will select target inds for each person later
target_inds = [1 2 3 4]; % Indices of target shapes
distractor_inds = [1 2 3]; % Indices of distractor shapes



%% loop through each subject
for sub_num = 1:total_subs
    %creates a struct name for this subject
    sub_struct_name = sprintf('subj%d', sub_num);
    
    % Create the subject struct
    subject_struct = struct();

    % Parameters
    total_scenes = 111;
    total_reps_per_scene = 4;
    total_runs = 6;

    scene_randomizor = zeros(total_trials, 3);
    % Generate scenes and repetition labels
    row_index = 1;
    for scene_num = 1:num_scenes
        for target = 1:total_reps_per_scene
            scene_randomizor(row_index, 1) = scene_num; % Scene number
            row_index = row_index + 1;
        end
        scene_randomizor(row_index-4:row_index-1, 2) = randperm(total_reps_per_scene);
    end
    % so here we make a matrix containing all of the scenes. We then randomize the order that the targets are presented in
    % because when we later add the run we use the same permutation for all runs this insures that there is diff scenes for
    % each run and that which target gets to each run is also random.

    % Initialize scene_randomizor matrix
    % Col 1: Scene number
    % Col 2: Repetition number (1–4)
    % Col 3: Run number (to be filled)

    % Track scene usage in each run (111 scenes × 6 runs)
    scene_counts = zeros(num_scenes, num_runs);

    run_permutation = randperm(total_runs); % Randomize run order

    rep_num = length(scene_randomizor)/length(run_permutation);
    row_index = 1;
    for rep = 1:rep_num
        scene_randomizor(row_index:row_index+5, 3) = run_permutation'; % Assign run numbers
        row_index = row_index + 6; % Move to the next set of rows
    end
    % Sort by run or scene
    scene_randomizor = sortrows(scene_randomizor, 3); % sort by run


    for run_num = 1:num_runs
        %get run struct name
        run_struct_name = sprintf('run%d', run_num);

        %create run struct
        run_struct = struct();

        run_idx = find(scene_randomizor(:,3) == run_num);
        run_trials = scene_randomizor(run_idx, :);


        % Add the run struct to the subject struct and apply runStructName
        subject_struct.(run_struct_name) = run_struct;
    end
    % Add the subject struct to the main struct and apply subStructName
    randomizor_matrix.(sub_struct_name) = subject_struct;
end

run_counts = histcounts(scene_randomizor(:,3), 0.5:1:6.5); % For runs 1–6

% Display as a table
disp(table((1:6)', run_counts', 'VariableNames', {'Run', 'TrialCount'}));

num_scenes = 111;
num_runs = 6;

% Initialize matrix: rows = scenes, columns = runs
scene_run_counts = zeros(num_scenes, num_runs);

% Fill it
for i = 1:size(scene_randomizor, 1)
    scene = scene_randomizor(i, 1);
    run = scene_randomizor(i, 3);
    scene_run_counts(scene, run) = scene_run_counts(scene, run) + 1;
end

% Display a few rows for verification
disp(array2table(scene_run_counts(1:10,:), ...
    'VariableNames', compose('Run%d', 1:num_runs), ...
    'RowNames', compose('Scene%d', 1:10)));

% Check if any scene appears more than once in a run
if any(scene_run_counts(:) > 1)
    warning('THERE WAS MORE THAN ONE SCENE PER RUN');
else
    disp('All scenes occur at most once per run.');
end


% Save the randomization matrix to a .mat file
%save ../trial_structure_files/randomizor.mat randomizor_matrix
