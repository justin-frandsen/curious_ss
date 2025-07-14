function shape_position_finder(scene_type_main0_practice1, scene_choice)
% First change the to the file structures we utilize

%-----------------------------------------------------------------------
% Script: shape_position_finder.m
% Author: Justin Frandsen
% Date: 12/07/2024 %dd/mm/yyyy
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

try
    % Check if scene_choice is a string
    if ~ismember(scene_choice, ['k', 'K', 'b', 'B'])
        error('scene_choice must be one of these: k, K, b, or B');
    end

    % Check if scene_type_main0_practice1 is 0 or 1
    if ~ismember(scene_type_main0_practice1, [0, 1])
        error('scene_type_main0_practice1 must be 0 or 1');
    end
catch ME
    % Handle the error and stop execution
    disp(['Error: ', ME.message]);
    rethrow(ME);
end

% settings
scene_folder_practice_bathroom = 'Stimuli/scenes/practiceScenes/bathroom';
scene_folder_practice_kitchen = 'Stimuli/scenes/practiceScenes/kitchen';
scenes_folder_bathroom = 'Stimuli/scenes/mainScenes/bathroom';
scenes_folder_kitchen = 'Stimuli/scenes/mainScenes/kitchen';
shapes_folder = 'stimuli/shapes/transparent_black';

scr_w = 1920;
scr_h = 1080;
scr_hz = 60;

% Initilize PTB window
[w, rect, scr_id] = ptb_setup_brad(scr_w, scr_h, scr_hz);
[width, height] = Screen('WindowSize', 0);

Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); %allows the .png files to be transparent

%load all .jpg files in the images directory.
if scene_type_main0_practice1 == 0
    if scene_choice == 'k' || scene_choice == 'K'
        [~, scenes_texture_matrix] = image_stimuli_import(scenes_folder_kitchen, '', w);
    elseif scene_choice == 'b' || scene_choice == 'B'
        [~, scenes_texture_matrix] = image_stimuli_import(scenes_folder_bathroom, '', w);
    end
elseif scene_type_main0_practice1 == 1
    if scene_choice == 'k' || scene_choice == 'K'
        [~, scenes_texture_matrix] = image_stimuli_import(scene_folder_practice_kitchen, '', w);
    elseif scene_choice == 'b' || scene_choice == 'B'
        [~, scenes_texture_matrix] = image_stimuli_import(scene_folder_practice_bathroom, '', w);
    end
else
    error('Input for scene_type_main0_practice1 must be either 1 or 0!')
end

%load in stimuli
[~, stimuli_texture_matrix] = image_stimuli_import(shapes_folder, '*.png', w);

% Set initial position of the texture
texture_size = [0, 0, 106, 106]; % In this version I am maintaining the same size as the previos experiment at 106 pixels tall and wide

saved_positions = cell(length(scenes_texture_matrix), 3); %tk change first for to length(scenes_texture_matrix)

KbName('UnifyKeyNames');

%loop for presenting scenes and their
for scene_num = 1:length(scenes_texture_matrix)
    for position_num = 1:3
        WaitSecs(0.5);
        running = true;
        this_shape = stimuli_texture_matrix(randsample(1:22, 1));
        while running == true

            % Check for keyboard events
            [key_is_down, ~, key_code] = KbCheck;
            
            if key_is_down && key_code(KbName('ESCAPE'))
                pfp_ptb_cleanup
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
            Screen('DrawTexture', w, scenes_texture_matrix(scene_num), [], rect);
            Screen('DrawTexture', w, this_shape, [], position);
            Screen('Flip', w);
            
            WaitSecs(0.01);
        end
        saved_positions{scene_num, position_num} = position;
    end
end


pfp_ptb_cleanup;

if scene_type_main0_practice1 == 0
    if scene_choice == 'k' || scene_choice == 'K'
        save ../../trial_structure_files/shape_positions_main_kitchen.mat saved_positions
    elseif scene_choice == 'b' || scene_choice == 'B'
        save trialDataFiles/shape_positions_main_bathroom.mat saved_positions
    end
elseif scene_type_main0_practice1 == 1
    if scene_choice == 'k' || scene_choice == 'K'
        save trialDataFiles/shape_positions_practice_kitchen.mat saved_positions
    elseif scene_choice == 'b' || scene_choice == 'B'
        save trialDataFiles/shape_positions_practice_bathroom.mat saved_positions
    end
end
end