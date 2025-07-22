%-----------------------------------------------------------------------
% Script: shape_position_finder.m
% Author: Justin Frandsen
% Date: 22/07/2025 %dd/mm/yyyy
% Description:
% - Matlab script used to place images on their correct locations in scenes
%   and output rects for placing them in the main experiment.
% Usage:
% - Use the mouse to move the image across the screen. Use - & + to increase
%   or decrease the size of the shapes, and use space to save that position
%   and size. After saved it will ask if the shape was on the wall, floor,
%   or counter.
% - This function saves the rects for each image in a rect containing
%   the location and size of each object. Each row represents each scene.
% - A second .mat file will be saved containing the responses to if the
%   shape was on the floor, counter, or wall.
%-----------------------------------------------------------------------
%% CLEAR VARIABLES
clc;
close all;
clear all;
sca;

%% ADD PATHS
addpath(genpath('../'));

%% settings
scene_folder = '../../stimuli/scenes/';
shapes_folder = '../../stimuli/shapes/transparent_black';

scr_w = 1920;
scr_h = 1080;
scr_hz = 60;

% colors
col.white = [255 255 255]; 
col.black = [0 0 0];
col.gray = [117 117 117];

col.bg = col.gray; % background color
col.fg = col.white; % foreground color
col.fix = col.black; % fixation color

screens = Screen('Screens'); % Get the list of screens
scrID = max(screens); % Get the maximum screen ID (this should usually be the external monitor if using multiple screens)

% Initilize PTB window
[w, rect] = pfp_ptb_init; %call this function which contains all the screen initilization.
[width, height] = Screen('WindowSize', scrID); %get the width and height of the screen
Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); %allows the .png files to be transparent

%load all scenes images in the stimuli/scenes/ directory.
[~, scenes_texture_matrix] = image_stimuli_import(scene_folder, '', w);

%load in shape stimuli from the stimuli/shapes/transparent_black directory.
[~, stimuli_texture_matrix] = image_stimuli_import(shapes_folder, '*.png', w);

% Set initial position of the texture
texture_size = [0, 0, 106, 106]; % In this version I am maintaining the same size as the previos experiment at 106 pixels tall and wide
number_of_positions = 6; % Number of positions to save for each scene

saved_positions = cell(length(scenes_texture_matrix), number_of_positions); % Initialize cell array to store positions

KbName('UnifyKeyNames');

%loop for presenting scenes and their
for scene_num = 1:length(scenes_texture_matrix)
    %% DRAW SCENE   
    scene = Screen('OpenOffscreenWindow', scrID, col.bg, rect);
    % Draw the scene texture
    Screen('DrawTexture', scene, scenes_texture_matrix(scene_num), [], rect);

    for position_num = 1:number_of_positions
        WaitSecs(0.5);
        running = true;
        this_shape = stimuli_texture_matrix(randsample(1:22, 1));
        while running == true

            % Check for keyboard events
            [key_is_down, ~, key_code] = KbCheck;
            
            if key_is_down && key_code(KbName('ESCAPE'))
                pfp_ptb_cleanup
            elseif key_is_down && key_code(KbName('M'))
                position = NaN;
                running = false;            
            end

            % Update mouse position
            [x, y, buttons] = GetMouse(w);
            texture_mover = [x y x y];

            % check if left mouse button is pressed. If it is exit loop
            if buttons(1)
                running = false;
            end

            % Draw texture at new position
            position = texture_size + texture_mover;
            Screen('DrawTexture', w, scene);

            % Draw the previously placed positions for this scene
            for prev_position = 1:position_num-1 %loop through all previous positions
                if ~isempty(saved_positions{scene_num, prev_position})
                    % Draw previous positions
                    Screen('DrawTexture', w, this_shape, [], saved_positions{scene_num, prev_position}); % draw the current shape. This saves resource usage relative to drawing all diff ones that arent already loaded in.
                end
            end

            Screen('DrawTexture', w, this_shape, [], position); % draw the current shape at the new position determined by the mouse position
            Screen('Flip', w);
            
            WaitSecs(0.01); % small delay to prevent excessive CPU usage
        end
        saved_positions{scene_num, position_num} = position; % Save the position of the shape
    end
end

save ../../trial_structure_files/shape_positions.mat saved_positions

pfp_ptb_cleanup;