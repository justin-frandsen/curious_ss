function shape_position_checker(scene_type_main0_practice1)
%-----------------------------------------------------------------------
% Script: shape_position_checker.m
% Author: Justin Frandsen
% Date: 10/02/2023
% Description:
% - Takes output from shape_position_finder.m and lets you fix any
%   mislabeling or mistakes in positioning
% Usage:
% - scene_type_main0_practice1 is used to determine if you are going to check
%   over the scenes for the practice trials or the main trials
%-----------------------------------------------------------------------

% settings
scene_folder_practice = 'Stimuli/scenes/practiceScenes';
scene_folder_main = 'Stimuli/scenes/mainScenes';
shapes_folder = 'stimuli/shapes/transparent_black';

% Initilize PTB window
[w, rect] = ../ptb_scripts/pfp_ptb_init;
[width, height] = Screen('WindowSize', 0);

Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); %allows the .png files to be transparent

% Load in images
DrawFormattedText(w, 'Loading Images...', 'center', 'center');
Screen('Flip', w);

if scene_type_main0_practice1 == 0
    shape_location_types = load('trialDataFiles/shape_location_types_main.mat');
    shape_positions = load('trialDataFiles/shape_positions_main.mat');
    [scenes_file_path_matrix, scenes_texture_matrix] = imageStimuliImport(scene_folder_main, '', w);
elseif scene_type_main0_practice1 == 1
    shape_location_types = load('trialDataFiles/shape_location_types_practice.mat');
    shape_positions = load('trialDataFiles/shape_positions_practice.mat');
    [scenes_file_path_matrix, scenes_texture_matrix] = imageStimuliImport(scene_folder_practice, '', w);
else
    error('Input for scene_type_main0_practice1 must be either 1 or 0!')
end

location_types = shape_location_types.locationTypes;
saved_positions = shape_positions.savedPositions;

% Set initial position of the texture
texture_size = [0, 0, 240, 240]; % Adjust the size of the texture as desired

mistakes = [];
mistake_counter = 0;

%load in stimuli
[~, stimuli_texture_matrix] = imageStimuliImport(shapes_folder, '*.png', w);

for scene_num = 1:length(scenes_texture_matrix)
    for position_num = 1:4
        this_shape = stimuli_texture_matrix(randsample(1:22, 1));
        
        % '1 = Wall, 2 = Floor, 3 = Counter'
        this_scene_location_type = location_types(scene_num, position_num);
        this_scene_position = saved_positions{scene_num, position_num};
        texture_mover = this_scene_position;
        
        if this_scene_location_type == 1
            text_for_display = 'Position Type: Wall';
        elseif this_scene_location_type == 2
            text_for_display = 'Position Type: Floor';
        elseif this_scene_location_type == 3
            text_for_display = 'Position Type: Counter';
        end
        
        Screen('DrawTexture', w, scenes_texture_matrix(scene_num), [], rect);
        Screen('DrawTexture', w, this_shape, [], this_scene_position);
        DrawFormattedText(w, text_for_display, 'center', 'center')
        Screen('Flip', w);
        
        loop_var = true;
        while loop_var
            % Wait for a response
            [~, key_code, ~] = KbWait([], 2);
            key_char = KbName(key_code);
            
            % Check if the response is valid (y/n)
            if any(strcmp(key_char, {'y', 'n', 'Y', 'N'}))
                if any(strcmp(key_char, {'n', 'N'}))
                    
                    WaitSecs(0.5);
                    running = true;
                    this_shape = stimuli_texture_matrix(randsample(1:22, 1));
                    while running == true
                        % Check for keyboard events
                        [key_is_down, ~, key_code] = KbCheck;
                        if key_is_down && key_code(KbName('space'))
                            running = false; % Break the loop if spacebar is pressed
                        elseif key_is_down && key_code(KbName('w'))
                            texture_mover(2) = texture_mover(2) - 2;
                            texture_mover(4) = texture_mover(4) - 2;
                        elseif key_is_down && key_code(KbName('s'))
                            texture_mover(2) = texture_mover(2) + 2;
                            texture_mover(4) = texture_mover(4) + 2;
                        elseif key_is_down && key_code(KbName('a'))
                            texture_mover(1) = texture_mover(1) - 2;
                            texture_mover(3) = texture_mover(3) - 2;
                        elseif key_is_down && key_code(KbName('d'))
                            texture_mover(1) = texture_mover(1) + 2;
                            texture_mover(3) = texture_mover(3) + 2;
                        elseif key_is_down && key_code(KbName('ESCAPE'))
                            pfp_ptb_cleanup
                        end
                        
                        % Draw texture at new position
                        position = texture_mover;
                        Screen('DrawTexture', w, scenes_texture_matrix(scene_num), [], rect);
                        Screen('DrawTexture', w, this_shape, [], position);
                        Screen('Flip', w);
                    end
                    
                    saved_positions{scene_num, position_num} = position;
                    DrawFormattedText(w, '1 = Wall, 2 = Floor, 3 = Counter', 'center', 'center')
                    Screen('Flip', w);
                    while true
                        % Wait for a response
                        [~, key_code, ~] = KbWait([], 2);
                        key_char = KbName(key_code);
                        
                        % Check if the response is valid (1, 2, or 3)
                        if strcmp(key_char, '1!')
                            location_types(scene_num, position_num) = 1;
                            break; % Break out of the response loop
                        elseif strcmp(key_char, '2@')
                            location_types(scene_num, position_num) = 2;
                            break; % Break out of the response loop
                        elseif strcmp(key_char, '3#')
                            location_types(scene_num, position_num) = 3;
                            break; % Break out of the response loop
                        end
                    end
                elseif any(strcmp(key_char, {'y', 'Y'}))
                    break; % Break out of the response loop
                end
                break;
            end
        end
    end
end

DrawFormattedText(w, 'Saving Data', 'center', 'center')
Screen('Flip', w);

if scene_type_main0_practice1 == 0
    save trialDataFiles/shape_positions_main_checked.mat saved_positions
    save trialDataFiles/shape_location_types_main_checked.mat location_types
elseif scene_type_main0_practice1 == 1
    save trialDataFiles/shape_positions_practice_checked.mat saved_positions
    save trialDataFiles/shape_location_types_practice_checked.mat location_types
else
    error('Input for scene_type_main0_practice1 must be either 1 or 0!')
end

pfp_ptb_cleanup
end