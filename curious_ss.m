%-----------------------------------------------------------------------
% Script: shapeSearch.m
% Author: Justin Frandsen
% Date: 07/15/2025 format: DD/MM/YYYY
% Description: This script runs a visual search experiment where participants
%              search for a target shape among distractor shapes. Participants
%              are given a viewing window after the search duration to see if
%              exploration leads to distractor learning.
%
% Additional Comments:
% - 
% - 
% - 
%
% Usage:
% - 
% - Script will output a .csv file containing behavioral data, a .csv file
%   containing fixation data, a .mat file containing all variables in the
%   matlab enviroment, and a .edf file for usage with eyelink data viewer.
%   containing all matlab script variables, and a .edf file containing
%   eyetracking data.
%-----------------------------------------------------------------------
%% CLEAR VARIABLES
clc;
close all;
sca;
ClockRandSeed; % Resets the random # generator
%% ADD PATHS
addpath(genpath('setup'));

%% PTB SETTINGS
screens = Screen('Screens');
scrID = max(screens);

%% EYETRACKER SETTINGS
mx = 1;
my = 1;

% RECORD PICS/TRACK EYES?
record_pics = 'N';  % change to 'Y' to record pictures of stimuli
computer = 'PC'; % Mac or PC
refresh_rate = 60; % Hz of monitor
eyetracking = 'N'; % Y or N

%% GET SUBJECT NUMBER AND RUN NUMBER AND CHECK IF THEY ARE VALID/EXIST
% Check if sub_num is defined, if not prompt user for input
if ~exist('sub_num', 'var')
    while true
        fprintf('Enter subject number: ');
        sub_num = input('');
        if ~isempty(sub_num) && isnumeric(sub_num) && sub_num > 0
            break;
        else
            disp('Invalid subject number. Please enter a positive integer.');
        end
    end
else
    % If sub_num is already defined, ensure it is a positive integer
    if ~isnumeric(sub_num) || any(sub_num <= 0)
        error('Invalid run number. Please clear the workspace.');
    end
end

% Check if run_num is defined, if not prompt user for input
if ~exist('run_num', 'var')
    while true
        fprintf('Enter run number: ');
        run_num = input('');
        if ~isempty(run_num) && isnumeric(run_num) && run_num > 0
            break;
        else
            disp('Invalid run number. Please enter a positive integer.');
        end
    end
else
    % If run_num is already defined, ensure it is a positive integer
    if ~isnumeric(run_num) || run_num <= 0
        error('Invalid run number. Please clear the workspace.');
    end
end

%% Check if experimenter wants to proceed
fprintf('Proceed with subject number: %d and run number: %d? (Y/N)\n', sub_num, run_num);
proceed_response = input('', 's');
if ~strcmpi(proceed_response, 'Y')
    error('Experiment aborted by user.');
end
%% OUTPUT VARIABLES
% Output folders and file formats for behavioral data, eye-tracking data

% Bx output folder and file format
bx_output_folder_name = 'data/bx_data/';
bx_file_format = 'bx_Subj%.3dRun%.2d.csv';

% Preprocessed eye data output folder and file format
eye_output_folder_name = 'data/eye_data/';
eye_file_format = 'fixation_data_subj_%.3d_run_%.3d.csv';

% EDF output folder and file format
edf_output_folder_name = 'data/edf_data/';
edf_file_format = 'S%.3dR%.1d.edf';

% scene images locations
scene_folder_main         = 'stimuli/scenes/main_scenes';
scene_folder_practice     = 'stimuli/scenes/practice_scenes';

% shapes images locations
nonsided_shapes          = 'stimuli/shapes/transparent_black';
shapes_left             = 'stimuli/shapes/black_left_T';
shapes_right            = 'stimuli/shapes/black_right_T';

%% TEST IF OUTPUT FILES EXIST
% Test if bx output file already exists
bx_file_name = sprintf(bx_file_format, sub_num, run_num);
if exist(fullfile(bx_output_folder_name, bx_file_name), 'file')
    error('Subject bx file already exists. Delete the file to rerun with the same subject number.');
end

% Test if preprocessed eyemovement data file already exists
eye_file_name = sprintf(eye_file_format, sub_num, run_num);
if exist(fullfile(eye_output_folder_name, eye_file_name), 'file')
    error('Subject eye file already exists. Delete the file to rerun with the same subject number.');
end

% Test if .edf file already exists
edf_file_name = sprintf(edf_file_format, sub_num, run_num)
if exist(fullfile(edf_output_folder_name, edf_file_name), 'file')
    error('Subject edf file already exists. Delete the file to rerun with the same subject number.');
end

%% IMPORTANT VARIABLES
expName = 'curious_ss';
fudge = .005; % 5 ms to add before screen flip to ensure we hit the refresh cycle
penalty = 2; % 2000 ms
timeout = 5000; % 2000 ms

% Fixation variables
fix.Radius = 90;
fix.Timeout = 5000;
fix.reqDur = 500;

% Run information
main_runs = 6
practice_runs = 1;
total_runs = main_runs + practice_runs;

%Fonts
my_font = 'Arial'; % for any text
my_font_size = 60;

% Beeper
beeper.tone = 200; % 200 Hz
beeper.loudness = 0.5; % 25% amplitude default (.5)
beeper.duration = 0.3; % 300 ms default

% Response Keys
KbName('UnifyKeyNames');

key.left = '3#'; % 32
key.right = '4$';% 33
key.yes = '1!'; % top left button on button box
key.no = '2@'; % top right button on button box
key.esc = '0)'; % 39

% colors
col.white = [255 255 255]; 
col.black = [0 0 0];
col.gray = [117 117 117];

col.bg = col.gray; % background color
col.fg = col.white; % foreground color
col.fix = col.black; % fixation color

% Initilize PTB window
[w, rect] = pfp_ptb_init; %call this function which contains all the screen initilization.
[width, height] = Screen('WindowSize', scrID); %get the width and height of the screen
Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); %allows the .png files to be transparent

%% Background Screens

% Screens
Screen('textSize', w, my_font_size);
Screen('TextFont', w, my_font);

bufimg =  Screen('OpenOffscreenWindow',scrID, col.bg, rect);
Screen('TextFont', bufimg, my_font);
Screen('TextSize', bufimg, my_font_size);

blank =  Screen('OpenOffscreenWindow', scrID, col.bg, rect);

% fixation cross
fixsize = 16;
fixthick = 4;
[fixationX, fixationY] = RectCenter(rect);
fixation =  Screen('OpenOffscreenWindow', scrID, col.bg, rect);

% Draw horizontal line
Screen('FillRect', fixation, col.fix, ...
    CenterRectOnPoint([-fixsize -fixthick fixsize fixthick], fixationX, fixationY));

% Draw vertical line
Screen('FillRect', fixation, col.fix, ...
    CenterRectOnPoint([-fixthick -fixsize fixthick fixsize], fixationX, fixationY));

% Draw feedback messages
feedback_slow = Screen('OpenOffscreenWindow', scrID, col.bg, rect);
Screen('textSize', feedback_slow, my_font_size);
Screen('TextFont', feedback_slow, my_font);
DrawFormattedText(feedback_slow, 'Too slow!', 'center', 'center', col.fg);


feedback_correct = Screen('OpenOffscreenWindow', scrID, col.bg, rect);
Screen('textSize', feedback_correct, my_font_size);
Screen('TextFont', feedback_correct, my_font);
DrawFormattedText(feedback_correct, 'Correct!', 'center', 'center', col.fg);

feedback_incorrect = Screen('OpenOffscreenWindow', scrID, col.bg, rect);
Screen('textSize', feedback_incorrect, my_font_size);
Screen('TextFont', feedback_incorrect, my_font);
DrawFormattedText(feedback_incorrect, 'Incorrect!', 'center', 'center', col.fg);
%% LOAD STIMULI!!!
% shapes images locations
% shapes images locations
nonsided_shapes          = 'stimuli/shapes/transparent_black';
shapes_left             = 'stimuli/shapes/black_left_T';
shapes_right            = 'stimuli/shapes/black_right_T';

DrawFormattedText(w, 'Loading Images...', 'center', 'center');
Screen('Flip', w);

% Load all .jpg files in the scenes folder.
if run_num == 1
    [scene_file_paths, scene_textures] = imageStimuliImport(scene_folder_practice, '', w);
elseif run_num > 1
    [scene_file_paths, scene_textures] = imageStimuliImport(scene_folder_main, '', w);
end

total_scenes = length(scene_file_paths);

% Load in shape stimuli
[sorted_nonsided_shapes_file_paths, sorted_nonsided_shapes_textures] = imageStimuliImport(nonsided_shapes, '*.png', w, true);
[sorted_left_shapes_file_paths, sorted_left_shapes_textures] = imageStimuliImport(shapes_left, '*.png', w, true);
[sorted_right_shapes_file_paths, sorted_right_shapes_textures] = imageStimuliImport(shapes_right, '*.png', w, true);

%% INITIALIZE EYETRACKER
if eyetracking == 'Y'
    % Initialize Eyelink
    if ~exist(edf_output_folder_name, 'dir')
        mkdir(edf_output_folder_name);
    end
    
    el = setup_eyelink(w, edf_file_name);
end

%% Start Experiment
t = 0;
ACCcount = 0;
trialcounter = 0;

%% EXPERIMENT START
for run_num = 1:total_runs
    instruct_curious_ss(sub_num, run_num, w, scrID, rect, col); % show instructions will need to change this to a function later

    if strcmpi(eyetracking, 'Y')
        % Enter tracker setup/calibration
        EyelinkDoTrackerSetup(el);
    end
    
end
sca;

