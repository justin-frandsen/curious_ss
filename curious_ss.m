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
%% CLEAR VARIABLES
clc;
close all;
clear all;
sca;
rng('shuffle'); % Resets the random # generator
%% ADD PATHS
addpath(genpath('setup'));

%% COLUMN NAMES FOR SCENE MATRIX
SCENE_INDS = 1;
REP        = 2; % just used to create the randomizor matrix not used in the experiment
RUN        = 3; % col contains the run number
DISTRACTOR = 4;
TARGET     = 5;
CONDITION  = 6;

%% PTB SETTINGS
screens = Screen('Screens');
scrID = max(screens);

%% EYETRACKER SETTINGS
%we initialize this because sometimes if its not set it checks vars that don't exist and throws an error
mx = 1; 
my = 1;
fixationTimeThreshold = 50; % Minimum fixation duration in ms to log

%% SQL SETTINGS
use_SQL = true; % true or false


% RECORD PICS/TRACK EYES?
record_pics = 'N';  % change to 'Y' to record pictures of stimuli
computer = 'PC'; % Mac or PC
refresh_rate = 60; % Hz of monitor
eyetracking = 'N'; % Y or N
dummymode = 1; % 0 for real eyetracking, 1 for dummy mode (no eyetracking)

sub_num = 100;
run_num = 1;
border_line_width = 30;

%% GET SUBJECT NUMBER AND RUN NUMBER AND CHECK IF THEY ARE VALID/EXIST
% Check if sub_num is defined, if not prompt user for input
if ~exist('sub_num', 'var')
    while true
        sub_num = input('Enter subject number: ');
        if ~isempty(sub_num) && isnumeric(sub_num) && sub_num > 0
            break;
        else
            disp('Invalid subject number. Please enter a positive integer.');
        end
    end
else
    % If sub_num is already defined, ensure it is a positive integer
    if ~isnumeric(sub_num) || any(sub_num <= 0)
        error('Invalid subject number. Please clear the workspace.');
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
proceed_response = 'y'; %input('', 's');
if ~strcmpi(proceed_response, 'Y')
    error('Experiment aborted by user.');
end

%% OUTPUT VARIABLES
% Output folders and file formats for behavioral data, eye-tracking data

% Bx output folder and file format
data_folder = 'data';
bx_output_folder_name = fullfile(data_folder, 'bx_data');
bx_file_format = 'bx_Subj%.3dRun%.2d.csv';

% Preprocessed eye data output folder and file format
eye_output_folder_name = fullfile(data_folder, 'eye_data');
eye_file_format = 'fixation_data_subj_%.3d_run_%.3d.csv';

% EDF output folder and file format
edf_output_folder_name = fullfile(data_folder, 'edf_data');
edf_file_format = 'S%.3dR%.1d.edf';

% scene images locations
scene_folder            = 'stimuli/scenes/';

%% MAKE SURE data directory and its subdirectories exist
subdirs = {'bx_data', 'edf_data', 'eye_data', 'log_files'};

if ~exist(data_folder, 'dir')
    [status, msg] = mkdir(data_folder);
    if ~status
        error('Failed to create directory: %s', msg);
    end
end

for i = 1:length(subdirs)
    subdir_path = fullfile(data_folder, subdirs{i});
    if ~exist(subdir_path, 'dir')
        [status, msg] = mkdir(subdir_path);
        if ~status
            error('Failed to create directory: %s', msg);
        end
    end
end

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

key.left = 'z'; %'3#'; % 32
key.right = 'x'; %'4$';% 33
key.yes = '1!'; % top left button on button box
key.no = '2@'; % top right button on button box
key.esc = '0)'; % 39

validKeys = {key.left, key.right};

% colors
col.white = [255 255 255]; 
col.black = [0 0 0];
col.gray = [117 117 117];
col.red = [255 0 0];
col.green = [0 255 0];

col.bg = col.gray; % background color
col.fg = col.white; % foreground color
col.fix = col.black; % fixation color

% Initilize PTB window
[w, rect] = pfp_ptb_init; %call this function which contains all the screen initilization.
[width, height] = Screen('WindowSize', scrID); %get the width and height of the screen
% Enable alpha blending for transparency
Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); %allows the .png files to be transparent

%% LOAD STIMULI!!!
% shapes images locations
% shapes images locations
nonsided_shapes         = 'stimuli/shapes/transparent_black';
shapes_left             = 'stimuli/shapes/black_left_T';
shapes_right            = 'stimuli/shapes/black_right_T';

DrawFormattedText(w, 'Loading Images...', 'center', 'center');
Screen('Flip', w);

[scene_file_paths, scene_textures] = image_stimuli_import(scene_folder, '', w);
total_scenes = length(scene_file_paths);

% Load in shape stimuli
[sorted_nonsided_shapes_file_paths, sorted_nonsided_shapes_textures] = image_stimuli_import(nonsided_shapes, '*.png', w, true);
[sorted_left_shapes_file_paths, sorted_left_shapes_textures]         = image_stimuli_import(shapes_left, '*.png', w, true);
[sorted_right_shapes_file_paths, sorted_right_shapes_textures]       = image_stimuli_import(shapes_right, '*.png', w, true);

% Load in the shape positions
shape_positions = load('trial_structure_files/shape_positions.mat'); % Load the shape positions
saved_positions = shape_positions.saved_positions; % Assign saved_positions for later use

%% Background Screens

% Screens
Screen('TextSize', w, my_font_size);
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
randomizor = randomizor.randomizor_matrix; % get the matrix from the struct

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
    % LOG FILE SETTINGS
    logFile = sprintf('data/log_files/subj%d_run%dlog.txt', sub_num, run_looper);
    sessionStart = now;

    if run_looper <= 4
        phase = 'training';
    elseif run_looper > 4
        phase = 'testing';
    end

    %% INITIALIZE BX STRUCT
    bx_trial_info(1:72) = struct( ...
        'sub_num', sub_num, ...
        'run_num', run_looper, ...
        'phase', phase, ... % training or testing
        'trial_num', [], ...
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
        'timestamp', datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF') ...
    );

    for t = 1:total_trials
        trials(t).trial_num = t;
    end

    %% INITIALIZE FIXATION STRUCT
    fixationTemplate = struct( ...
        'sub_num', [], ...
        'run_num', [], ...
        'trial_num', [], ...
        'fixation_onset', [], ...
        'fixation_offset', [], ...
        'fixation_num', [], ...
        'duration_ms', [], ...
        'fixated_rect', [], ...
        'incorrect_target_location', [], ...
        'target_shape_idx', [], ...
        'target_position_idx', [] ...
    );

    %reset fixation struct and important variables
    fixationStruct = repmat(fixationTemplate, 0, 1); % empty array with correct fields
    
    fixationCounter = 0;
    currentFixationRect = 0;
    previousFixationRect = 0;

    %% LOAD DATA FOR THIS SUBJECT AND RUN
    this_subj_this_run = randomizor.(sprintf('subj%d', sub_num)).(sprintf('run%d', run_looper)); %method of getting into the struct

    scene_randomizor = this_subj_this_run.scene_randomizor; % Get the scene randomizor for this subject and run
    target_inds = this_subj_this_run.first_half_targets;
    target_associations = this_subj_this_run.target_associations;
    critical_distractor_inds = this_subj_this_run.first_half_critical_distractors;
    critical_distractor_associations = this_subj_this_run.critical_distractors_associations;
    noncritical_distractors = this_subj_this_run.noncritical_distractors;


    % This is where we will show instructions do this at the end!!!
    %instruct_curious_ss(sub_num, run_looper, w, scrID, rect, col); % show instructions will need to change this to a function later

    % eyelink calibration
    if strcmpi(eyetracking, 'Y')
        % Enter tracker setup/calibration
        EyelinkDoTrackerSetup(el);
    end
    

    %% Loop through trials
    for trial_looper = 1:total_trials
        % Example run info
        run_id = 'run_01';
        sub_num = 1;
        start_time = datestr(now, 'yyyy-mm-dd HH:MM:SS');

        % Insert a new run row
        exec(conn, sprintf(['INSERT INTO runs (run_id, sub_num, start_time) ' ...
                            'VALUES (''%s'', %d, ''%s'');'], run_id, sub_num, start_time));


        response = -1;

        fprintf("Trial %d/%d for subject %d, run %d, %.1f%% complete\n", ...
            trial_looper, total_trials, sub_num, run_looper, ...
            trial_looper/total_trials*100);
        
        scene_inds = scene_randomizor(trial_looper, SCENE_INDS); % Get the scene index for this trial

        possible_positions = this_subj_this_run.all_possible_locations(trial_looper, :); % Get the possible positions for this trial

        t_directions = this_subj_this_run.t_directions(trial_looper, :); % Get the target directions for this trial

        target_index1 = scene_randomizor(trial_looper, TARGET);
        target_texture_index = target_inds(target_index1);

        target_association = target_associations(target_index1); %1 = wall 2 = counter, 3 = floor.

        trial_condition = scene_randomizor(trial_looper, CONDITION);

        if run_looper <= 4
            critical_distractor_index1 = scene_randomizor(trial_looper, DISTRACTOR);
            cd_texture_index = critical_distractor_inds(critical_distractor_index1);
            critical_distractor_association = critical_distractor_associations(critical_distractor_index1);
        end

        noncritical_distractors = this_subj_this_run.this_run_distractors(trial_looper, :);
        length_noncritical_distractors = length(noncritical_distractors);
        noncritical_distractors = noncritical_distractors(1:length_noncritical_distractors-1); % remove the last one which is just the run number
        
        %% DRAW SCENE   
        search = Screen('OpenOffscreenWindow', scrID, col.bg, rect, 32);
        post_search = Screen('OpenOffscreenWindow', scrID, col.bg, rect, 32);
        % Draw the scene texture
        Screen('DrawTexture', search, scene_textures(scene_inds), [], rect);
        Screen('DrawTexture', post_search, scene_textures(scene_inds), [], rect);

        % Enable blending for transparency inside this offscreen window
        Screen('BlendFunction', search, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        % Enable blending for transparency inside this offscreen window
        Screen('BlendFunction', post_search, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        types     = [1 2 3];      % semantic categories: wall/counter/floor
        positions = [1 2 3 4];    % physical rect indices

        % ---- choose the target TYPE for this trial
        if run_looper <= 4
            % training: trial_condition chooses whether target uses its associated
            % location or one of the other two
            switch trial_condition
                case 0
                    target_type = target_association;  % use its associated type
                case 1
                    tmp = setdiff(types, target_association);
                    target_type = tmp(1);
                case 2
                    tmp = setdiff(types, target_association);
                    target_type = tmp(2);
                otherwise
                    error('Unexpected trial_condition value.');
            end
        else
            % testing: target goes to the formerly critical association (if that’s your design)
            target_type = critical_distractor_association;
        end

        % ---- map TYPE → POSITION and draw TARGET
        target_position = possible_positions(target_type);                 % e.g., 1..4
        target_rect     = saved_positions{scene_inds, target_position};    % use POSITION!

        if t_directions(1) == 0
            % left target
            Screen('DrawTexture', search, sorted_left_shapes_textures(target_texture_index), [], target_rect);
        elseif t_directions(1) == 1
            % right target  
            Screen('DrawTexture', search, sorted_right_shapes_textures(target_texture_index), [], target_rect);
        end

        crit_dist_position = []; 
        
        % ---- draw CRITICAL DISTRACTOR only in training
        if run_looper <= 4
            crit_pos  = possible_positions(4);                              % 4th entry encodes CD position
            crit_rect = saved_positions{scene_inds, crit_pos};
            if t_directions(4) == 0
                % left critical distractor
                Screen('DrawTexture', search, sorted_left_shapes_textures(cd_texture_index), [], crit_rect);
                Screen('DrawTexture', post_search, sorted_left_shapes_textures(cd_texture_index), [], crit_rect);

            elseif t_directions(4) == 1
                % right critical distractor
                Screen('DrawTexture', search, sorted_right_shapes_textures(cd_texture_index), [], crit_rect);
                Screen('DrawTexture', post_search, sorted_right_shapes_textures(cd_texture_index), [], crit_rect);
            end
        end
    
        % ---- draw NON-CRITICAL DISTRACTORS at the remaining TYPEs (not positions)
        remaining_types = setdiff(types, target_type);  % remove the *type* used by target

        for k = 1:numel(remaining_types)
            this_type = remaining_types(k);                  % one of the two leftover types
            this_pos  = possible_positions(this_type);       % map TYPE → POSITION
            this_rect = saved_positions{scene_inds, this_pos};
            distractor_texture_index = noncritical_distractors(k);
            if t_directions(1+k) == 0
                % left non-critical distractor
                Screen('DrawTexture', search, sorted_left_shapes_textures(distractor_texture_index), [], this_rect);
                Screen('DrawTexture', post_search, sorted_left_shapes_textures(distractor_texture_index), [], this_rect);
            elseif t_directions(1+k) == 1
                % right non-critical distractor
                Screen('DrawTexture', search, sorted_right_shapes_textures(distractor_texture_index), [], this_rect);
                Screen('DrawTexture', post_search, sorted_right_shapes_textures(distractor_texture_index), [], this_rect);
            end
        end

        %% DRAW CUE DISPLAY
        % Open an offscreen window with alpha channel (32-bit RGBA)
        cue_display = Screen('OpenOffscreenWindow', scrID, col.bg, rect, 32);

        % Enable blending for transparency inside this offscreen window
        Screen('BlendFunction', cue_display, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        % Draw your texture into the offscreen window
        Screen('DrawTexture', cue_display, sorted_nonsided_shapes_textures(target_texture_index));

        % Later: draw the offscreen window onto your main window (w)
        Screen('DrawTexture', w, cue_display);

        %HideCursor(scrID);         % Hide mouse cursor before the next trial
        %SetMouse(10, 10, scrID);   % Move the mouse to the corner -- in case some jerk has unhidden it
        
        % Blank ISI
        Screen('DrawTexture', w, fixation);
        Screen('flip', w);

        if strcmp(eyetracking, 'Y')
            centralFixation(w, height, width, fixation, fix.reqDur, fix.Timeout, fix.Radius, t, el, eye, search)
        end
        
        % CUE DISPLAY
        Screen('DrawTexture', w, cue_display);
        Screen('flip', w);
        WaitSecs(1); % 1 second cue

        % Draw fixation cross
        Screen('DrawTexture', w, fixation);
        Screen('flip', w);
        WaitSecs(1); % 1 second central fixation

        %% SEARCH DISPLAY
        Screen('DrawTexture', w, search);
        stimOnsetTime = Screen('Flip', w); %this flip displays the scene with all four shapes

        if strcmp(eyetracking, 'Y')
            Eyelink('Message', 'SYNCTIME');
            Eyelink('Message', 'Scene Presentation:')  
        end

        trialActive = true;  % Flag to keep the trial going
        responseMade = false;

        startTime = GetSecs(); % Initialize startTime for each trial
        while trialActive && (GetSecs() - startTime <= 15)
            %-----------------------------------------------------
            % CHECK FOR RESPONSE KEY PRESS
            %-----------------------------------------------------
            [key_is_down, secs, key_code] = KbCheck;
            if key_is_down && ~responseMade
                responseKey = KbName(key_code);
                if iscell(responseKey)
                    responseKey = responseKey{1};
                end
                if ismember(responseKey, validKeys)
                    response = responseKey;
                    RT = round((secs - stimOnsetTime) * 1000);
                    responseMade = true;
                
                    if dummymode == 0
                        Eyelink('Message', 'Key pressed');
                    end
                
                    % Flag to end the trial after logging last fixation
                    trialActive = false;
                end
            end
        
            %-----------------------------------------------------
            % TRACK GAZE OR MOUSE
            %-----------------------------------------------------
            if dummymode == 0
                eyelinkError = Eyelink('CheckRecording');
                if eyelinkError ~= 0
                    fprintf('Eyelink error: %d\n', eyelinkError);
                    break;
                end
                if Eyelink('NewFloatSampleAvailable') > 0
                    evt = Eyelink('NewestFloatSample');
                    if eye_used ~= -1
                        x = evt.gx(eye_used+1);
                        y = evt.gy(eye_used+1);
                        if x ~= el.MISSING_DATA && y ~= el.MISSING_DATA && evt.pa(eye_used+1) > 0
                            mx = x;
                            my = y;
                        end
                    end
                end
            else
                [mx, my] = GetMouse(w);
            end
        
            %-----------------------------------------------------
            % CHECK IF GAZE IS IN SHAPE AND LOG FIXATION
            %-----------------------------------------------------
            isInInterestArea = false;
            for interestArea = 1:4
                if IsInRect(mx, my, saved_positions{scene_inds, interestArea})
                    isInInterestArea = true;
                    currentFixationRect = interestArea;
                    break;
                end
            end
        
            if ~isInInterestArea
                currentFixationRect = 0;
            end
        
            % Fixation transition
            if previousFixationRect ~= currentFixationRect
                if currentFixationRect ~= 0
                    fixationStartTime = GetSecs();
                elseif previousFixationRect ~= 0
                    fixationEndTime = GetSecs();
                    fixationDuration = (fixationEndTime - fixationStartTime) * 1000;
                    if fixationDuration > fixationTimeThreshold
                        fixationCounter = fixationCounter + 1;
                        fixationStruct(fixationCounter) = struct( ...
                            'sub_num', sub_num, ...
                            'run_num', run_looper, ...
                            'trial_num', trial_looper, ...
                            'fixation_onset', fixationStartTime - stimOnsetTime, ...
                            'fixation_offset', fixationEndTime - stimOnsetTime, ...
                            'fixation_num', fixationCounter, ...
                            'duration_ms', fixationDuration, ...
                            'fixated_rect', previousFixationRect, ...
                            'incorrect_target_location', trial_condition, ...
                            'target_shape_idx', target_texture_index, ...
                            'target_position_idx', target_position ...
                        );
                    end
                end
            end
            previousFixationRect = currentFixationRect;
        end

        % Logging the last fixation if it's ongoing at the end of the loop
        if previousFixationRect ~= 0
            fixationEndTime = GetSecs();
            fixationDuration = (fixationEndTime - fixationStartTime) * 1000;
            % Logging last fixation data
            if fixationDuration > fixationTimeThreshold
                fixationCounter = fixationCounter + 1;
                fixationStruct(fixationCounter) = struct( ...
                    'sub_num', sub_num, ...
                    'run_num', run_looper, ...
                    'trial_num', trial_looper, ...
                    'fixation_onset', fixationStartTime - stimOnsetTime, ...
                    'fixation_offset', fixationEndTime - stimOnsetTime, ...
                    'fixation_num', fixationCounter, ...
                    'duration_ms', fixationDuration, ...
                    'fixated_rect', previousFixationRect, ...
                    'incorrect_target_location', trial_condition, ...
                    'target_shape_idx', target_texture_index, ...
                    'target_position_idx', target_position ...
                );   
            end
        end

        if t_directions(1) == 0 && response == key.left
            trial_accuracy = 1;
        elseif t_directions(1) == 1 && response == key.right
            trial_accuracy = 1;
        else
            trial_accuracy = 0;
        end

        %% LOG OUTPUT VARIABLES
        bx_trial_info(trial_looper).trial_num                        = trial_looper;
        bx_trial_info(trial_looper).trial_onset                     = stimOnsetTime;
        bx_trial_info(trial_looper).trial_offset                    = GetSecs();
        bx_trial_info(trial_looper).response_clock_time             = secs;
        bx_trial_info(trial_looper).scene_idx                       = scene_inds;
        bx_trial_info(trial_looper).target_shape_idx                = target_texture_index;
        bx_trial_info(trial_looper).target_shape_association        = target_association;
        if run_looper <= 4
            bx_trial_info(trial_looper).critical_distractor_idx         = cd_texture_index;
            bx_trial_info(trial_looper).critical_distractor_association = critical_distractor_association;
        elseif run_looper > 4
            bx_trial_info(trial_looper).critical_distractor_idx         = NaN;
            bx_trial_info(trial_looper).critical_distractor_association = NaN;
        end
        bx_trial_info(trial_looper).noncritical_distractor_idx      = noncritical_distractors;
        bx_trial_info(trial_looper).condition                       = trial_condition;
        bx_trial_info(trial_looper).t_direction                     = t_directions;
        if responseMade
            bx_trial_info(trial_looper).response_key                = response;
            bx_trial_info(trial_looper).rt                          = RT;
            bx_trial_info(trial_looper).accuracy                    = trial_accuracy; % You may want to set this based on correctness
        elseif responseMade == false
            bx_trial_info(trial_looper).response_key                = '';
            bx_trial_info(trial_looper).rt                          = NaN;
            bx_trial_info(trial_looper).accuracy                    = -1; % -1 for no response
        end

        post_search_duration = 5; % seconds
        feedback_duration = 0.2; % seconds

        % if incorrect give feedback (red border) for 200 ms then show post search screen for remaining time
        % if correct show post search screen for full duration
        if trial_accuracy == 0
            resp_color = col.red;
            Screen('DrawTexture', w, post_search);
            Screen('FrameRect', w, resp_color, rect, border_line_width);
            Screen('flip', w);
            WaitSecs(feedback_duration); % 200 ms
            Screen('DrawTexture', w, post_search);
            Screen('flip', w);
            WaitSecs(post_search_duration-feedback_duration)
        elseif trial_accuracy == 1
            resp_color = col.green;
            Screen('DrawTexture', w, post_search);
            Screen('flip', w);
            WaitSecs(post_search_duration)
        end

        %draw blank ITI
        Screen('flip', w);
        WaitSecs(.5); % 500 ms ITI
    end

    %% END OF RUN
    text = sprintf('Run %d/%d complete!', run_looper, total_runs);
    DrawFormattedText(w, text, 'center', 'center');
    Screen('Flip', w);
    WaitSecs(2);

    % log session info
    sessionEnd = now;
    log_session_info(sub_num, run_looper, total_trials, sessionStart, sessionEnd, logFile);

    % save trial data to CSV
    %trialTable = struct2table(trials);
    %filename = sprintf('data/bx_data/%d_run%d.csv', subjectID, runNumber);
    %writetable(trialTable, filename);

end
%% END EXPERIMENT
% Show end of experiment message
DrawFormattedText(w, 'Experiment Complete! Thank you for participating.', 'center', 'center', col.fg);
Screen('Flip', w);
WaitSecs(2); % Wait for 2 seconds before closing
DrawFormattedText(w, 'Saving Data...', 'center', 'center');
Screen('Flip', w);

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
