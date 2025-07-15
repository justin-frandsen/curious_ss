%-------------------------------------------------------------------------
% Script: randomizor_curious.m
% Author: Justin Frandsen
% Date: 07/15/2025 format: DD/MM/YYYY
% Description: Prerandomizor for the curious_ss experiment.
%
% Usage:
% - fileDirectory: Set total subs, run, and trials, and it will randomize 
%   the order of presentation of the various scenes and trial variables.
% - Script will output a struct containing this information.
%-------------------------------------------------------------------------
%% SETTINGS
total_subs = 500;
total_runs = 8;
number_trials = 72; % 72 trials in each block

% Restoring default RNG settings
rng('shuffle');

% Initialize the main struct to hold 500 sub-structs (subjects)
randomizor_matrix = struct();

%% GET THE STIMULI INFO FROM THE DIRECTORIES
% get all main scenes
all_main_scenes = dir('../stimuli/scenes/main_scenes/*');
all_main_scenes = all_main_scenes(~ismember({all_main_scenes.name},{'.','..','.DS_Store'}));


% get all shapes in the shape dir
all_shapes = dir('../stimuli/shapes/transparent_black/*');
all_shapes = all_shapes(~ismember({all_shapes.name},{'.','..', '.DS_Store'}));

%% CREATE INDEXES FOR RANDOMIZATION
% Indices for main and practice scenes
% These will be used to randomize the order of scenes in the trials
main_scenes_inds = 1:length(all_main_scenes);
% Indices for all scenes
shape_inds = 1:length(all_shapes);

% target inds we can use these for randomization because we will select target inds for each person later
target_inds = [1 2 3 4]; % Indices of target shapes
distractor_inds = [1 2 3 4]; % Indices of distractor shapes

%% CREATE RANDOMIZATION MATRIX
scene_randomizor = zeros(length(main_scenes_inds) * length(target_inds), 2); % create a matrix to hold the randomization
% Fill the scene_randomizor matrix with combinations of main scenes and target shapes
% This will create a matrix where each row corresponds to a unique combination of scene and target shape
% The first column will hold the scene index and the second column will hold the target shape index
% This is done to ensure that each scene is paired with each target shape

row_index = 1;
for scenes_num = 1:length(main_scenes_inds)
    for target_num = 1:length(target_inds)
        % Fill the scene_randomizor matrix with the current combination
        scene_randomizor(row_index, :) = [scenes_num target_num];
        row_index = row_index + 1;
    end
end

