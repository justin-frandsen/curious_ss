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

distractor_inds = [1 2 3 4]; % Indices of distractor shapes

%% CREATE RANDOMIZATION MATRIX
scene_randomizor = zeros(length(scenes_inds) * length(target_inds), 2); % create a matrix to hold the randomization
% Fill the scene_randomizor matrix with combinations of main scenes and target shapes
% This will create a matrix where each row corresponds to a unique combination of scene and target shape
% The first column will hold the scene index and the second column will hold the target shape index
% This is done to ensure that each scene is paired with each target shape

row_index = 1;
for scenes_num = 1:length(scenes_inds)
    for target_num = 1:length(target_inds)
        % Fill the scene_randomizor matrix with the current combination
        scene_randomizor(row_index, :) = [scenes_num target_num];
        row_index = row_index + 1;
    end
end

