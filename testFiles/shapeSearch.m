%function shapeSearch(subNum, runNum)
subNum = 1; %tk remove and uncomment function call
runNum = 1; %tk remove and uncomment function call
%-----------------------------------------------------------------------
% Script: shapeSearch.m
% Author: Justin Frandsen
% Date: 07/12/2023
% Description: Matlab script that presents experiment exploring how
%              learning influences attention involving scene synatx.
%
% Additional Comments:
% - Must be in the correct folder to run script.
% - Make sure eyetracker is powered on and connected.
% - Make sure shape_location_type.mat & shape_position.mat are saved and
%   ready
%
% Usage:
% - type function name with subject number and run number (seperated by a
%   comma in parentheses).(e.g., shapeSearch(222, 1)).
% - Script will output a .csv file containing behavioral data, a .mat file
%   containing all matlab script variables, and a .edf file containing
%   eyetracking data.
%-----------------------------------------------------------------------

%===================Beginning of real script============================
% Global Variables
bxFileFormat            = 'sceneShapeSearchSub%.3dRun%.2d.csv';
eyeFileFormat           = 'S%.3dR%.1d.edf';
bxOutputFolder          = 'output/bxData';
eyetrackingOutputFolder = 'output/eyeData';
imageFolder             = 'scenes';
nonsidedShapes          = 'Stimuli/transparent_black';
shapesTLeft             = 'Stimuli/Black_Left_T';
shapesTRight            = 'Stimuli/Black_Right_T';

% Task variables
trialsPerRun          = 60;% 72 must be a multiple of 4
totalTargets          = 4;
totalDistractors      = 18;
stimuliSizeRect       = [0, 0, 240, 240]; %This rect contains the size of the shapes that are presented
%stimuliLocationMatrix = [1000, 100, 1000, 100]; %this matrix can be used to move the stimuli. This will be replaced
%stimuliScaler         = .25; %you can multiply the size Rect by this to grow or shrink the size of the stimuli.

% PTB Settings
WinNum = 0;

% Eyelink settings
dummymode = 1; %set 0 if using eyetracking, set 1 if not eyetracking (will use mouse position instead)

% Create output file names
bxFileName = sprintf(bxFileFormat, subNum, runNum);  %name of bx(behavioral) file
edfFileName = sprintf(eyeFileFormat, subNum, runNum); %name of the edf(eyetracking) file

% Test if output file already exists
outputFileList = dir(fullfile(bxOutputFolder, '*.csv'));
for j = 1:length(outputFileList)
    existing_file_name = outputFileList(j).name;
    if existing_file_name == bxFileName
        error('Suject already exists. If you want to run again with the same subject number you will need to delete the corresponding output file.');
    end
end

% Initilize PTB window
[w, rect] = pfp_ptb_init;
[width, height] = Screen('WindowSize', WinNum);
Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); %allows the .png files to be transparent
%set font, size, and style for my_window
old_font = Screen('TextFont', w, 'Arial');
old_size = Screen('TextSize', w, 35);
old_style = Screen('TextStyle', w, 1);

%create central fixation location
winfixsize = 50;
winfix = [-winfixsize -winfixsize, winfixsize, winfixsize];
winfix = CenterRect(winfix, rect);

% =========================================================================
% =============== Initialize the eyetracker! ==============================
% =========================================================================
if dummymode == 0
    el=EyelinkInitDefaults(w); %starts with EyeLink default settings
    
    el.backgroundcolour = BlackIndex(el.window); %background color of calibration display
    el.msgfontcolour  = WhiteIndex(el.window); %font color for calibration display
    el.imgtitlecolour = WhiteIndex(el.window); %tile color for calibration display
    el.targetbeep = 0; %doesn't beep after each target when calibrating
    el.calibrationtargetcolour = WhiteIndex(el.window); %color of circle/target used in calibration display
    
    %determines the size of the circle/target used for calibration
    el.calibrationtargetsize = 2;
    el.calibrationtargetwidth = 0.75;
    
    EyelinkUpdateDefaults(el); %update EyeLink settings based on what you just defined above
    
    %the following does some checks and aborts if something isn't right
    %with the EyeLink-computer connection
    if ~EyelinkInit(dummymode)
        fprintf('Eyelink Init aborted.\n');
        Eyelink('Shutdown');
        Screen('CloseAll')
        return;
    end
    
    i = Eyelink('Openfile', edfFileName);
    if i~=0
        fprintf('Cannot create EDF file ''%s'' ', edfFileName);
        Eyelink('Shutdown');
        Screen('CloseAll')
        return;
    end
    
    if Eyelink('IsConnected')~=1 && ~dummymode
        Eyelink('Shutdown');
        Screen('CloseAll')
        return;
    end
    
    %these add some info for logging in the EDF file
    Eyelink('command', 'add_file_preamble_text ''Recorded by EyelinkToolbox demo-experiment'''); %this is old and probably doesn't need to be here :-)
    Eyelink('command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, width-1, height-1);
    Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, width-1, height-1);
    
    %sets up some more EyeLink settings
    Eyelink('command', 'calibration_type = HV9'); %9-point calibration
    Eyelink('command', 'generate_default_targets = YES'); %use default targets for calibration (you just defined what default is above)
    Eyelink('Command', 'calibration_area_proportion 1.00 1.00'); %calibrate and 85% of the screen extent (the circles/targets only go 85% of the way out from center -- you only need to calibrate the useful extent of the monitor)
    Eyelink('Command', 'validation_area_proportion  1.00 1.00'); %validate at 85% of the screen extend (see above)
    Eyelink('command', 'saccade_velocity_threshold = 35'); %threshold for computing/defining saccades in the EDF file (only effects what the EDF file logs)
    Eyelink('command', 'saccade_acceleration_threshold = 9500'); %threshold for computing/defining saccades in the EDF file (only effects what the EDF file logs)
    
    %some more basic settings
    [v,vs] = Eyelink('GetTrackerVersion');
    fprintf('Running experiment on a ''%s'' tracker.\n', vs );
    vsn = regexp(vs,'\d','match');
    Eyelink('command', 'button_function 5 "accept_target_fixation"');
    
    EyelinkDoTrackerSetup(el); %apply the above settings
end

% Load in images
DrawFormattedText(w, 'Loading Images...', 'center', 'center');
Screen('Flip', w);

% Load all .jpg files in the scenes folder.
[allScenesFilePaths, allScenesTextures] = imageStimuliImport(imageFolder, '*.jpg', w);

% Load in shape stimuli
[sortedNonsidedShapesFilePaths, sortedNonsidedShapesTextures] = imageStimuliImport(nonsidedShapes, '*.png', w, true);
[sortedLeftShapesFilePaths, sortedLeftShapesTextures] = imageStimuliImport(shapesTLeft, '*.png', w, true);
[sortedRightShapesFilePaths, sortedRightShapesTextures] = imageStimuliImport(shapesTRight, '*.png', w, true);

% %randomize presentation order
% trialOrder = 1:4; %tk change to 1:length(allScenesTextures);
% trialOrderFull = repmat(trialOrder, 1, 2); % Repeat the trialOrder vector twice
% trialOrderFull = trialOrderFull(randperm(length(trialOrderFull))); % Shuffle the elements randomly

%load
shapeLocationTypes = load('shape_location_types.mat');
shapePositions = load('shape_positions.mat');

%load variables for where the shapes are located and what postion theyre in
randomizor = fullRandomizor(trialsPerRun, allScenesTextures, sortedNonsidedShapesTextures, totalTargets);
this_subj_this_run = randomizor.(sprintf('subj%d', subNum)).(sprintf('run%d', runNum)); %method of getting into the struct
%==============================Beginning of task========================
%variables that will be saved out
rtAll = [];
responses = {};
tDirectionTarget = {};
accuracy = [];
fileName = {};
thisRunTrialNumbers = 1:trialsPerRun;
subNumForOutput(1:trialsPerRun) = subNum;

% Create a cell array to store eye movement data for each trial
eyeMovementData = cell(1, trialsPerRun);

%-------------------Instructions----------------------------------------
DrawFormattedText(w, 'For a <sideways T with bar on left> press z\n and for a <sideways T with bar on right> press /', 'center', 'center')
Screen('Flip', w);

%this look waits until the spacebar is pressed to continue
start = 0;
while start==0
    [key_time,key_code]=KbWait([], 2);
    resp = find(key_code);
    if resp(1) == KbName('SPACE') || resp(1) == KbName('space')
        start = 1;
    end
end

if dummymode==0 %if you are actually eye tracking (and not using mouse position, which you might do if just testing the script)
    Eyelink('Command', 'set_idle_mode'); %eye tracker will go idle and wait
    WaitSecs(0.1);
    
    Eyelink('Command', 'driftcorrect_cr_disable = OFF'); %allow online drift correction on tracker computer
    Eyelink('Command', 'normal_click_dcorr = ON'); %use the normal click method to activate and apply drift correction
    Eyelink('Command', 'online_dcorr_maxangle = 5.0'); %only allow drift correction when the different between measured and corrected eye position is 5 degrees visual angle or less
    
    % tk I commented this out. I am not sure this would help me given that
    % these are appearing where the items for the loc shock experiment were
    % appearing which is not important for me.
    %this draws the fixation boxes/windows on the EyeLink monitor,
    %which is useful for getting a "feel" for how good calibration is
    %     Eyelink('command', 'clear_screen %d', 0);
    %     Eyelink('command', 'draw_box %d %d %d %d 15', winfix(1),winfix(2),winfix(3),winfix(4));
    %     Eyelink('command', 'draw_box %d %d %d %d 15', cir_top(1),cir_top(2),cir_top(3),cir_top(4));
    %     Eyelink('command', 'draw_box %d %d %d %d 15', cir_right(1),cir_right(2),cir_right(3),cir_right(4));
    %     Eyelink('command', 'draw_box %d %d %d %d 15', cir_bottom(1),cir_bottom(2),cir_bottom(3),cir_bottom(4));
    %     Eyelink('command', 'draw_box %d %d %d %d 15', cir_left(1),cir_left(2),cir_left(3),cir_left(4));
    %
    
    eye_used = Eyelink('EyeAvailable'); %I think this just determines, for online reading of eye position, which eye to use if you are recording from both at the same time. We only ever record from one at a time so it tends to never be relevant
    if eye_used == 2
        eye_used = 1;
    end
end

if dummymode == 1 %if you are instead not measuring eye position and using the mouse like eye position (usually to test/debug a script)
    ShowCursor(['Arrow']); %show mouse position as an arrowhead (which you'll need to be able to see in order to simulate eye position by moving it with the mouse)
end

%eyetracking code will go here
possibleLocations = [1 2 3 4];
allTargets = this_subj_this_run.allTargets;
% =============== Task for loop ===========================================
for trialNum = 1:trialsPerRun
    if dummymode==0
        % Send trial identification message to Eyelink
        Eyelink('Message', 'TRIALID %d', trialNum);
        
        % Send trial status message to Eyelink
        Eyelink('command', 'record_status_message "TRIAL %d/%d"', trialNum, trialsPerRun);
    end
    sceneInds = this_subj_this_run.cBSceneOrder(trialNum);
    targetInds = this_subj_this_run.cBTargetOrder(trialNum);
    thisTrialIncorrectTargetLocation = this_subj_this_run.cBIncorrectTargetLocation(trialNum);
    thisTrialExtraTarget = this_subj_this_run.cBExtraTargetTrials(trialNum);
    targetPosition = this_subj_this_run.cBOrigionalTargetPosition(trialNum);
    targetChoice = this_subj_this_run.cBTargetChoice(trialNum);
    tDirectionThisTrial = this_subj_this_run.tDirectionAllTrials(trialNum, :);
    thisTrialDistractors = this_subj_this_run.allDistractorsAllTrials(trialNum, :);
    
    oldsize = Screen('TextSize', w,60); %make the font size a little bigger when drawing the fixation cross
    DrawFormattedText(w, '+', 'center', 'center', [255,255,255]); %draws the fixation cross (a plus-sign) at the center of the screen
    Screen('Flip', w);
    
    
    %     if thisTrialExtraTarget == 1 && thisTrialIncorrectTargetLocation == 1
    %         textToDisplay = 'Extra target present and Incorrect location';
    %     elseif thisTrialExtraTarget == 1 && thisTrialIncorrectTargetLocation == 0
    %         textToDisplay = 'Extra target present';
    %     elseif thisTrialExtraTarget == 0 && thisTrialIncorrectTargetLocation == 1
    %         textToDisplay = 'Incorrect location';
    %     elseif thisTrialExtraTarget == 0 && thisTrialIncorrectTargetLocation == 0
    %         textToDisplay = 'Normal Trial';
    %     end
    %
    %     DrawFormattedText(w, textToDisplay, 50, 200, [255,255,255]); %tk remove this later
    
    Screen('DrawTexture', w, sortedNonsidedShapesTextures(targetInds)); %tk change the size later to reflect the true size on the trial
    WaitSecs(1)
    Screen('Flip', w);
    
    
    %start = 0;
    %     WaitSecs(1); %TK change to check if they're fixated
    %
    %     Screen('Flip', w);
    %     while start==0 % tk delete this entire loop later
    %         [key_time,key_code]=KbWait([], 2);
    %         resp = find(key_code);
    %         if resp(1) == KbName('SPACE') || resp(1) == KbName('space')
    %             start = 1;
    %         end
    %     end
    % tk uncomment out for full experiment
    DrawFormattedText(w, '+', 'center', 'center', [255,255,255]); %draws the fixation cross (a plus-sign) at the center of the screen
    WaitSecs(1);
    Screen('Flip', w);
    
    % Draw background scene
    Screen('DrawTexture', w, allScenesTextures(sceneInds), [], rect);
    WaitSecs(1.0);
    
    if targetPosition == 1
        positionInds = find(shapeLocationTypes.locationTypes(sceneInds, :) == 1);
    elseif targetPosition == 2
        positionInds = find(shapeLocationTypes.locationTypes(sceneInds, :) == 2);
    elseif targetPosition == 3
        positionInds = find(shapeLocationTypes.locationTypes(sceneInds, :) == 3);
    end
    
    if length(positionInds) > 1
        if targetChoice == 1
            positionInds = positionInds(1);
        else
            positionInds = positionInds(2);
        end
    end
    
    if thisTrialIncorrectTargetLocation == 1
        incorrectLocations = setdiff(possibleLocations, positionInds);
        positionInds = randsample(incorrectLocations, 1);
    end
    
    tDirection = tDirectionThisTrial(positionInds);
    shapeSizeAndPosition = shapePositions.savedPositions{sceneInds, positionInds};
    if tDirection == 1
        Screen('DrawTexture', w, sortedRightShapesTextures(targetInds), [], shapeSizeAndPosition);
        tDirectionTarget{end+1} = 'R';
    elseif tDirection == 2
        Screen('DrawTexture', w, sortedLeftShapesTextures(targetInds), [], shapeSizeAndPosition);
        tDirectionTarget{end+1} = 'L';
    end
    
    if thisTrialExtraTarget == 1
        trialInd = randsample(1:3, 1);
        targetInd = randsample(1:3, 1);
        possibleDistractorTargets = setdiff(allTargets(1, :), targetInds);
        distractorTarget = possibleDistractorTargets(targetInd);
        thisTrialDistractors(trialInd) = distractorTarget;
    end
    
    distractorPositions = setdiff(possibleLocations, positionInds);
    for position = 1:length(distractorPositions)
        distractorTDirection = tDirectionThisTrial(distractorPositions(position));
        shapeSizeAndPosition = shapePositions.savedPositions{sceneInds, distractorPositions(position)};
        thisDistractor = thisTrialDistractors(position);
        if distractorTDirection == 1
            Screen('DrawTexture', w, sortedRightShapesTextures(thisDistractor), [], shapeSizeAndPosition);
        elseif distractorTDirection == 2
            Screen('DrawTexture', w, sortedLeftShapesTextures(thisDistractor), [], shapeSizeAndPosition);
        end
    end
    
    WaitSecs(1);
    if dummymode == 0
        Eyelink('StartRecording'); % Start recording eye data
        WaitSecs(0.05); % Allow a brief moment for the tracker to start recording
    end
    
    stimOnsetTime = Screen('Flip', w);
    
    %response
    response = 'nan';
    RT = NaN;
    startTime = GetSecs();
    while GetSecs() - startTime <= 15
        [key_is_down, secs, key_code] = KbCheck;
        if key_is_down
            responseKey = KbName(key_code);
            if strcmp(responseKey, 'z') || strcmp(responseKey, '/?')
                response = responseKey;
                RT = round((secs - stimOnsetTime) * 1000);
                break;
            end
        end
    end
    
    if strcmp(response, 'nan')
        textToShow = 'Too slow!';
        accuracy(end+1) = 2;
    elseif strcmp(response, '/?') && strcmp(tDirectionTarget{trialNum}, 'R')
        textToShow = 'Correct!';
        accuracy(end+1) = 1;
    elseif strcmp(response, 'z') && strcmp(tDirectionTarget{trialNum}, 'L')
        textToShow = 'Correct!';
        accuracy(end+1) = 1;
    else
        textToShow = 'Incorrect!';
        accuracy(end+1) = 0;
    end
    
    DrawFormattedText(w, textToShow, 'center', 'center');
    Screen('Flip', w);
    WaitSecs(0.5);
    
    fileName{end+1} = allScenesFilePaths(sceneInds); %tk preallocate before final version
    responses{end+1} = response; %tk preallocate before final version
    rtAll(end+1) = RT; %tk preallocate before final version
end

DrawFormattedText(w, 'Saving Data...', 'center', 'center');
Screen('Flip', w);

if dummymode==0
    Eyelink('Command', 'set_idle_mode'); %set tracking to idle
    WaitSecs(0.5);
    Eyelink('CloseFile'); %close the EDF file
    
    % grab the EDF file from the EyeLink computer (shows text messages
    % in command window based on whether file retrieval was successful
    % or not)
    cd output/eyeData
    try
        fprintf('Receiving data file ''%s''\n', edfFileName);
        status=Eyelink('ReceiveFile');
        if status > 0
            fprintf('ReceiveFile status %d\n', status);
        end
        if 2==exist(edfFileName, 'file')
            fprintf('Data file ''%s'' can be found in ''%s''\n', edfFileName, pwd);
        end
    catch
        fprintf('Problem receiving data file ''%s''\n', edfFileName);
    end
    cd ../..
    
    Eyelink('Shutdown'); %shutdown Matlab connection to EyeLink
end

outputData = {'sub_num' 'file_name' 'trial_num'  'rt' 'response' 't_direction' 'accuracy';};
for col = 1:trialsPerRun
    outputData{col+1, 1} = subNumForOutput(1, col);
    outputData{col+1, 2} = fileName(1, col);
    outputData{col+1, 3} = thisRunTrialNumbers(1, col);
    outputData{col+1, 4} = rtAll(1, col);
    outputData{col+1, 5} = responses(1, col);
    outputData{col+1, 6} = tDirectionTarget{1, col};
    outputData{col+1, 7} = accuracy(1, col);
end

% Convert cell to a table and use first row as variable names
outputTable = cell2table(outputData(2:end,:), 'VariableNames', outputData(1,:));

% Write the table to a CSV file
% Output is working but it is commeted out for now so I don't have a bunch
% saved csv files that I have to go and delete
% writetable(outputTable, fullfile(bxOutputFolder, bxFileName));

pfp_ptb_cleanup
%end