function shapePositionChecker(sceneTypeMain0Practice1)
%-----------------------------------------------------------------------
% Script: ShapePositionChecker.m
% Author: Justin Frandsen
% Date: 10/02/2023
% Description:
% - Takes output from shapePositionFinder.m and lets you Fix any
%   mislabeling or mistakes in positioning
% Usage:
% - sceneTypeMain0Practice1 is used to determine if you are going to check
%   over the scenes for the practice trials or the main trials
%-----------------------------------------------------------------------

% settings
sceneFolderPractice = 'Stimuli/scenes/practiceScenes';
scenesFolderMain = 'Stimuli/scenes/mainScenes';
shapesFolder = 'stimuli/shapes/transparent_black';

% Initilize PTB window
[w, rect] = pfp_ptb_init;
[width, height] = Screen('WindowSize', 0);

Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); %allows the .png files to be transparent

% Load in images
DrawFormattedText(w, 'Loading Images...', 'center', 'center');
Screen('Flip', w);

if sceneTypeMain0Practice1 == 0
    shapeLocationTypes = load('trialDataFiles/shape_location_types_main.mat');
    shapePositions = load('trialDataFiles/shape_positions_main.mat');
    %mistakes = load('trialDataFiles/mistakes_main.mat');
    [scenes_file_path_matrix, scenes_texture_matrix] = imageStimuliImport(scenesFolderMain, '', w);
elseif sceneTypeMain0Practice1 == 1
    shapeLocationTypes = load('trialDataFiles/shape_location_types_practice.mat');
    shapePositions = load('trialDataFiles/shape_positions_practice.mat');
    %mistakes = load('trialDataFiles/mistakes_practice.mat');
    [scenes_file_path_matrix, scenes_texture_matrix] = imageStimuliImport(sceneFolderPractice, '', w);
else
    error('Input for sceneTypeMain0Practice1 must be either 1 or 0!')
end

locationTypes = shapeLocationTypes.locationTypes;
savedPositions = shapePositions.savedPositions;

% Set initial position of the texture
textureSize = [0, 0, 240, 240]; % Adjust the size of the texture as desired

mistakes = [];
mistakeCounter = 0;

%load in stimuli
[~, stimuli_texture_matrix] = imageStimuliImport(shapesFolder, '*.png', w);

for scene_num = 1:length(scenes_texture_matrix)
    for positionNum = 1:4
        this_shape = stimuli_texture_matrix(randsample(1:22, 1));
        
        
        % '1 = Wall, 2 = Floor, 3 = Counter'
        thisSceneLocationType = locationTypes(scene_num, positionNum);
        thisScenePosition = savedPositions{scene_num, positionNum};
        textureMover = thisScenePosition;
        
        
        if thisSceneLocationType == 1
            textForDisplay = 'Posisition Type: Wall';
        elseif thisSceneLocationType == 2
            textForDisplay = 'Posisition Type: Floor';
        elseif thisSceneLocationType == 3
            textForDisplay = 'Posisition Type: Counter';
        end
        
        Screen('DrawTexture', w, scenes_texture_matrix(scene_num), [], rect);
        Screen('DrawTexture', w, this_shape, [], thisScenePosition);
        DrawFormattedText(w, textForDisplay, 'center', 'center')
        Screen('Flip', w);
        
         loopVar = true;
         while loopVar
            % Wait for a response
            [~, keyCode, ~] = KbWait([], 2);
            keyChar = KbName(keyCode);
            
            % Check if the response is valid (1, 2, or 3)
            if any(strcmp(keyChar, {'y', 'n', 'Y', 'N'}))
                if any(strcmp(keyChar, {'n', 'N'}))
                    
                    WaitSecs(0.5);
                    running = true;
                    this_shape = stimuli_texture_matrix(randsample(1:22, 1));
                    while running == true
                        % Check for keyboard events
                        [keyIsDown, ~, keyCode] = KbCheck;
                        if keyIsDown && keyCode(KbName('space'))
                            running = false; % Break the loop if spacebar is pressed
                        elseif keyIsDown && keyCode(KbName('w'))
                            textureMover(2) = textureMover(2) - 2;
                            textureMover(4) = textureMover(4) - 2;
                        elseif keyIsDown && keyCode(KbName('s'))
                            textureMover(2) = textureMover(2) + 2;
                            textureMover(4) = textureMover(4) + 2;
                        elseif keyIsDown && keyCode(KbName('a'))
                            textureMover(1) = textureMover(1) - 2;
                            textureMover(3) = textureMover(3) - 2;
                        elseif keyIsDown && keyCode(KbName('d'))
                            textureMover(1) = textureMover(1)+2;
                            textureMover(3) = textureMover(3)+2;
                        elseif keyIsDown && keyCode(KbName('ESCAPE'))
                            pfp_ptb_cleanup
                        end
                        
                        % Draw texture at new position
                        position = textureMover;
                        Screen('DrawTexture', w, scenes_texture_matrix(scene_num), [], rect);
                        Screen('DrawTexture', w, this_shape, [], position);
                        Screen('Flip', w);
                    end
                    
                    savedPositions{scene_num, positionNum} = position;
                    DrawFormattedText(w, '1 = Wall, 2 = Floor, 3 = Counter', 'center', 'center')
                    Screen('Flip', w);
                    while true
                        % Wait for a response
                        [~, keyCode, ~] = KbWait([], 2);
                        keyChar = KbName(keyCode);
                        
                        % Check if the response is valid (1, 2, or 3)
                        
                        if strcmp(keyChar, '1!')
                            locationTypes(scene_num, positionNum) = 1;
                            break; % Break out of the response loop
                        elseif strcmp(keyChar, '2@')
                            locationTypes(scene_num, positionNum) = 2;
                            break; % Break out of the response loop
                        elseif strcmp(keyChar, '3#')
                            locationTypes(scene_num, positionNum) = 3;
                            break; % Break out of the response loop
                        end
                        
                    end
                elseif any(strcmp(keyChar, {'y', 'Y'}))
                    break; % Break out of the response loop
                end
                break;
            end
        end
    end
end

DrawFormattedText(w, 'Saving Data', 'center', 'center')
Screen('Flip', w);


if sceneTypeMain0Practice1 == 0
    save trialDataFiles/shape_positions_main_checked.mat savedPositions
    save trialDataFiles/shape_location_types_main_checked.mat locationTypes
elseif sceneTypeMain0Practice1 == 1
    save trialDataFiles/shape_positions_practice_checked.mat savedPositions
    save trialDataFiles/shape_location_types_practice_checked.mat locationTypes
else
    error('Input for sceneTypeMain0Practice1 must be either 1 or 0!')
end

pfp_ptb_cleanup
end