%-----------------------------------------------------------------------
% Script: shapeSearch.m
% Author: Justin Frandsen
% Date: 22/07/2025 %dd/mm/yyyy
% Description: This script runs a visual search experiment where participants
%              search for a target shape among distractor shapes. Participants
%              are given a viewing window after the search duration to see if
%              exploration leads to distractor learning.
%
% Additional Comments:
% - This script is designed to be run after the setup scripts have been executed.
% - It requires the Psychtoolbox to be initialized and the necessary image files to be imported.
%
% Usage:
% - Ensure that the Psychtoolbox is initialized and the image files are imported using
%   the `imageStimuliImport` function.
% - The script will prompt for subject and run numbers, and check if the output files already
%   exist to prevent overwriting.
% - The experiment will run through a series of trials where participants search for target shapes.
% - At the end of the experiment, it will save the behavioral data, eye movement data,
%   and EDF files if eye tracking is enabled.
% - Script will output a .csv file containing behavioral data, a .csv file
%   containing fixation data, a .mat file containing all variables in the
%   matlab enviroment, and a .edf file for usage with eyelink data viewer.
%   containing all matlab script variables, and a .edf file containing
%   eyetracking data.
%-----------------------------------------------------------------------
%{
Example of a trial for the data structure:
trialData(trial).subjectID       = 101;
trialData(trial).run             = 2;
trialData(trial).sceneID         = 73;
trialData(trial).targetShape     = 2;
trialData(trial).distractorShape = [1 3];
trialData(trial).condition       = 'invalid';
trialData(trial).RT              = 583;   % in ms
trialData(trial).accuracy        = 1;
trialData(trial).stimOnsetTime   = GetSecs;
trialData(trial).responseTime    = responseTime;
trialData(trial).responseKey     = 'f';
%}



%% CLEAR VARIABLES
clc;
close all;
clear all;
sca;
rng('shuffle'); % Resets the random # generator
%% ADD PATHS
addpath(genpath('setup'));

%% PTB SETTINGS
screens = Screen('Screens');
scrID = max(screens);

%% EYETRACKER SETTINGS
%we initialize this because sometimes if its not set it checks vars that don't exist and throws an error
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
scene_folder            = 'stimuli/scenes/';

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
edf_file_name = sprintf(edf_file_format, sub_num, run_num);
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
main_runs = 6;
practice_runs = 0;
total_runs = main_runs + practice_runs;

total_trials = 72;

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

%% LOAD STIMULI!!!
% shapes images locations
% shapes images locations
nonsided_shapes          = 'stimuli/shapes/transparent_black';
shapes_left             = 'stimuli/shapes/black_left_T';
shapes_right            = 'stimuli/shapes/black_right_T';

DrawFormattedText(w, 'Loading Images...', 'center', 'center');
Screen('Flip', w);

[scene_file_paths, scene_textures] = image_stimuli_import(scene_folder, '', w);
total_scenes = length(scene_file_paths);

% Load in shape stimuli
[sorted_nonsided_shapes_file_paths, sorted_nonsided_shapes_textures] = image_stimuli_import(nonsided_shapes, '*.png', w, true);
[sorted_left_shapes_file_paths, sorted_left_shapes_textures] = image_stimuli_import(shapes_left, '*.png', w, true);
[sorted_right_shapes_file_paths, sorted_right_shapes_textures] = image_stimuli_import(shapes_right, '*.png', w, true);

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

% draw targets textures
% load randomizor for target shapes
randomizor = load('trial_structure_files/randomizor.mat'); % load the pre-randomized data
all_targets = randomizor.randomizor.(sprintf('subj%d', sub_num)).(sprintf('run%d', 1)).allTargets; %method of getting into the struct

target1 = Screen('OpenOffscreenWindow', scrID, col.bg, rect);
Screen('DrawTexture', target1, sorted_nonsided_shapes_textures(all_targets(1, 1)));

target2 = Screen('OpenOffscreenWindow', scrID, col.bg, rect);
Screen('DrawTexture', target2, sorted_nonsided_shapes_textures(all_targets(1, 2)));

target3 = Screen('OpenOffscreenWindow', scrID, col.bg, rect);
Screen('DrawTexture', target3, sorted_nonsided_shapes_textures(all_targets(1, 3)));

target4 = Screen('OpenOffscreenWindow', scrID, col.bg, rect);
Screen('DrawTexture', target4, sorted_nonsided_shapes_textures(all_targets(1, 4)));

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
for run_looper = run_num:total_runs
    if run_looper <= 4
        phase = 'training';
    elseif run_looper > 4
        phase = 'testing';
    end

    %% INITIALIZE TRIAL STRUCT
    trials(1:72) = struct( ...
        'sub_num', sub_num, ...
        'run_num', run_looper, ...
        'phase', phase, ... % training or testing
        'trial_num', 1:total_trials, ...
        'scene_idx', [], ...
        'target_shape_idx', [], ...
        'target_shape_association', [], ...
        'critical_distractor_idx', [], ...
        'critical_distractor_association', [], ...
        'noncritical_distractor_idx', [], ...
        'condition', [], ...
        't_direction', [], ...
        'response_key', '', ...
        'rt', [], ...
        'accuracy', [], ...
        'timestamp', '' ...
    );

    for t = 1:total_trials
        trials(t).trial_num = t;
    end


    % LOG FILE SETTINGS
    logFile = sprintf('data/log_files/subj%d_run%dlog.txt', sub_num, run_looper);
    sessionStart = now;

    % This is where we will show instructions do this at the end!!!
    %instruct_curious_ss(sub_num, run_looper, w, scrID, rect, col); % show instructions will need to change this to a function later

    % eyelink calibration
    if strcmpi(eyetracking, 'Y')
        % Enter tracker setup/calibration
        EyelinkDoTrackerSetup(el);
    end
    
    % Load randomization data
    randomizor = load('trial_structure_files/randomizor.mat'); % load the pre-randomized data
    this_subj_this_run = randomizor.randomizor.(sprintf('subj%d', sub_num)).(sprintf('run%d', run_looper)); %method of getting into the struct

    %% Loop through trials
    for trial_looper = 1:1 %total_trials
        %% DRAW SCENE   
        search = Screen('OpenOffscreenWindow', scrID, col.bg, rect);
        % Draw the scene texture
        Screen('DrawTexture', search, scene_textures(this_subj_this_run.cBSceneOrder(trial_looper)));
        
        % ScreenShot Search
        if strcmpi(record_pics, 'Y')
            % Search
            screenshot(search, 'Search' , trial_looper)
        end

        HideCursor(scrID);         % Hide mouse cursor before the next trial
        SetMouse(10, 10, scrID);   % Move the mouse to the corner -- in case some jerk has unhidden it
        
        % Blank ISI
        Screen('DrawTexture', w, fixation);
        Screen('flip', w);
        WaitSecs(.5); % 500 ms ISI
        
        % Central Fixation
        Screen('DrawTexture', w, target1);
        WaitSecs(.5); 
        if strcmp(eyetracking, 'Y')
            centralFixation(w, height, width, fixation, fix.reqDur, fix.Timeout, fix.Radius, t, el, eye, search)
        end

        Screen('DrawTexture', w, fixation);
        Screen('flip', w);
        WaitSecs(.5); % 500 ms ISI

        Screen('DrawTexture', w, search);
        Screen('flip', w);
        WaitSecs(.5); % 500 ms ISI

        Screen('DrawTexture', w, feedback_correct);
        Screen('flip', w);
        WaitSecs(.5); % 500 ms ITI
    end

    %% END OF RUN
    % Show end of run message
    %% ENTER CODE HERE

    % log session info
    sessionEnd = now;
    log_session_info(sub_num, run_looper, total_trials, sessionStart, sessionEnd, logFile);

    % 
    trialTable = struct2table(trials);


end
%% END EXPERIMENT
% Show end of experiment message
DrawFormattedText(w, 'Experiment Complete! Thank you for participating.', 'center', 'center', col.fg);
Screen('Flip', w);
WaitSecs(2); % Wait for 2 seconds before closing
DrawFormattedText(w, 'Saving Data...', 'center', 'center');
Screen('Flip', w);

%% SAVE DATA
% Save behavioral data

% Save eye movement data

%% SAVE EDF FILE
if eyetracking == 'Y'
    WaitSecs(1.0);
    Eyelink('StopReccording')
    Eyelink('Command', 'set_idle_mode'); %set tracking to idle
    WaitSecs(0.5);
    Eyelink('CloseFile'); %close the EDF file
    
    % grab the EDF file from the EyeLink computer (shows text messages
    % in command window based on whether file retrieval was successful
    % or not)
    cd data/edf_data/
    try
        fprintf('Receiving data file ''%s''\n', edfFileName);
        status=Eyelink('ReceiveFile');
        if status > 0
            fprintf('ReceiveFile status %d\n', status);
        end
        if 2 == exist(edfFileName, 'file')
            fprintf('Data file ''%s'' can be found in ''%s''\n', edfFileName, pwd);
        end
    catch
        fprintf('Problem receiving data file ''%s''\n', edfFileName);
    end
    cd ../../
    
    Eyelink('Shutdown'); %shutdown Matlab connection to EyeLink
end

pfp_ptb_cleanup; % cleanup PTB
close all; % close all windows
clear all; % clear all variables
sca; % close PTB
