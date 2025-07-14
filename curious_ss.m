%-----------------------------------------------------------------------
% Script: shapeSearch.m
% Author: Justin Frandsen
% Date: 10/12/2023
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
clearvars -except sub_num run_num
sca;
ClockRandSeed; % Resets the random # generator

%% PTB Settings
WinNum = 0; % 0 means only one monitor.

%% Eyetracker Settings
eyedummymode = 0; % If equal to 0 eyetracker will run. If not it will use mouse simulation
mx = 1;
my = 1;
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
    run_num = run_num + 1; % Increment run_num by 1 if it already exists so that experimenter doesn't have to constantly change run_num
end

fprintf('Proceed with subject number: %d and run number: %d? (Y/N)\n', sub_num, run_num);
proceed_response = input('');

if ~strcmpi(proceed_response, 'Y') 
%% OUTPUT VARIABLES
% Output folders and file formats for behavioral data, eye-tracking data

% Bx output folder and file format
bx_output_folder_name = 'data/bx_data/';
bx_file_format = 'bx_Subj%.3dRun%.2d.csv';

% Preprocessed eye data output folder and file format
eye_output_folder_name = 'data/eye_data/';
eye_output_file_format = 'fixation_data_subj_%.3d_run_%.3d.csv';

% EDF output folder and file format
edf_output_folder_name = 'data/edf_data/';
edf_file_format = 'S%.3dR%.1d.edf';

% scene images locations
scene_folder_main         = 'stimuli/scenes/main_scenes';
scene_folder_practice     = 'stimuli/scenes/practice_scenes';

% shapes images locations
nonsidedShapes          = 'stimuli/shapes/transparent_black';
shapesTLeft             = 'stimuli/shapes/black_left_T';
shapesTRight            = 'stimuli/shapes/black_right_T';

%% RECORD PICS/TRACK EYES?
record_pics = 'N';  % change to 'Y' to record pictures of stimuli
computer = 'PC'; % Mac or PC
refresh_rate = 60; % Hz of monitor
eyetracking = 'Y'; % Y or N

%% IMPORTANT VARIABLES
expName = 'curious_ss';
fudge = .005; % 5 ms to add before screen flip to ensure we hit the refresh cycle
penalty = 2; % 2000 ms
timeout = 5000; % 2000 ms

% Fixation variables
fix.Radius = 90;
fix.Timeout = 5000;
fix.reqDur = 500;

%Fonts
myfont = 'Arial'; % for any text
myfsize = 56;

% Beeper
tone = 200; % 200 Hz
loudness = 0.5; % 25% amplitude default (.5)
duration = 0.3; % 300 ms default

% Response Keys
KbName('UnifyKeyNames');

key.left = '3#'; % 32
key.right = '4$';% 33
key.yes = '1!'; % top left button on button box
key.no = '2@'; % top right button on button box
key.esc = '0)'; % 39
