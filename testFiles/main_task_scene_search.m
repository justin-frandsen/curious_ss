%settings
bx_output_file_format = 'scene_shape_search_sub_%.3d_run_%.2d.csv';
bx_output_folder = 'output';
eyetracking_output_folder = 'eyetracking_output';
image_folder = 'images';
stimuli_folder = 'Stimuli/transparent_black';
number_of_trials = 8;
number_of_targets = 4;
number_of_distractors = 20;
WinNum = 0;


%eyelink settings
dummymode=1; %set 0 if using eyetracking, set 1 if not eyetracking (will use mouse position instead)

%shuffle the seed for the random number generator
rng('shuffle')

magic_cleanup = onCleanup(@pfp_ptb_cleanup); % this is supposed to do
%cleanup when the task completes or throws an error but is not working for
%me

%prompt to get subject number

prompt = {'Enter Subject Number:'};
default = {'0'};
title = 'Setup Info';
LineNo = 1;
answer = inputdlg(prompt, title, LineNo, default); % inputdlg = input dialog box pops up, ODD NUM = RED 80% EVEN NUM = BLUE 80%
[subjno_Str, ~] = deal(answer{:});

prompt = {'Enter Run Number:'};
default = {'1'};
answer = inputdlg(prompt, title, LineNo, default); % inputdlg = input dialog box pops up, ODD NUM = RED 80% EVEN NUM = BLUE 80%
[runno_Str, ~] = deal(answer{:});

bx_output_file_name = sprintf(bx_output_file_format, str2num(subjno_Str), str2num(runno_Str));

%create section that checks to see if output exists for that subj yet
output_file_list = dir(fullfile(bx_output_folder, '*.csv'));

edfFileName = sprintf('S%.3dR%.1d.edf', str2num(subjno_Str), str2num(runno_Str)); %name of the edf file that the eye tracker saves

for j = 1:length(output_file_list)
    existing_file_name = output_file_list(j).name;
    if existing_file_name == bx_output_file_name
        error('Suject already exists. If you want to run again with the same subject number you will need to delete the corresponding output file.');
    end
end

[my_window, my_rect] = pfp_ptb_init;
[width, height] = Screen('WindowSize', WinNum);
% Define the position and size variables
stimuli_size_rect = [0, 0, 240, 240];
stimuli_location_matrix = [1000, 100, 1000, 100];
stimuli_size = .25;

Screen('BlendFunction', my_window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

winfixsize = 50;
winfix = [-winfixsize -winfixsize, winfixsize, winfixsize];
winfix = CenterRect(winfix, my_rect);


% =========================================================================
% =============== Load in images! =========================================
% =========================================================================

%load all .jpg files in the images directory.
[scenes_file_path_matrix, scenes_texture_matrix] = image_stimuli_import(image_folder, '*.jpg', my_window);

%load in stimuli
[stimuli_file_path_matrix, stimuli_texture_matrix] = image_stimuli_import(stimuli_folder, '*.png', my_window);

% =========================================================================
% =============== Initialize the eyetracker! ==============================
% =========================================================================

if dummymode==0 %if you are actually eye tracking (and not using mouse position, which you might do if just testing the script)
    el=EyelinkInitDefaults(my_window); %starts with EyeLink default settings
    
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
    Eyelink('command', 'calibration_type = HV5'); %5-point calibration
    Eyelink('command', 'generate_default_targets = YES'); %use default targets for calibration (you just defined what default is above)
    Eyelink('Command', 'calibration_area_proportion 0.85 0.85'); %calibrate and 85% of the screen extent (the circles/targets only go 85% of the way out from center -- you only need to calibrate the useful extent of the monitor)
    Eyelink('Command', 'validation_area_proportion  0.85 0.85'); %validate at 85% of the screen extend (see above)
    Eyelink('command', 'saccade_velocity_threshold = 35'); %threshold for computing/defining saccades in the EDF file (only effects what the EDF file logs)
    Eyelink('command', 'saccade_acceleration_threshold = 9500'); %threshold for computing/defining saccades in the EDF file (only effects what the EDF file logs)
    
    %some more basic settings
    [v,vs] = Eyelink('GetTrackerVersion');
    fprintf('Running experiment on a ''%s'' tracker.\n', vs );
    vsn = regexp(vs,'\d','match');
    Eyelink('command', 'button_function 5 "accept_target_fixation"');
    
    EyelinkDoTrackerSetup(el); %apply the above settings
end

%create a matrix from 1 through length of texture_matrix that is used to
%randomize the order of image presentation
img_order_matrix = randperm(length(scenes_texture_matrix));
all_targets = randsample(1:length(stimuli_texture_matrix), number_of_targets);
all_distractors = setdiff(1:length(stimuli_texture_matrix), all_targets);

%set font, size, and style for my_window
old_font = Screen('TextFont', my_window, 'Arial');
old_size = Screen('TextSize', my_window, 35);
old_style = Screen('TextStyle', my_window, 1);

%display instruction text
DrawFormattedText(my_window, 'For a <sideways T with bar on left> press z\n and for a <sideways T with bar on right> press /', 'center', 'center')
Screen('Flip', my_window);

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
    
    %this draws the fixation boxes/windows on the EyeLink monitor,
    %which is useful for getting a "feel" for how good calibration is
    Eyelink('command', 'clear_screen %d', 0);
    Eyelink('command', 'draw_box %d %d %d %d 15', winfix(1),winfix(2),winfix(3),winfix(4));
    Eyelink('command', 'draw_box %d %d %d %d 15', cir_top(1),cir_top(2),cir_top(3),cir_top(4));
    Eyelink('command', 'draw_box %d %d %d %d 15', cir_right(1),cir_right(2),cir_right(3),cir_right(4));
    Eyelink('command', 'draw_box %d %d %d %d 15', cir_bottom(1),cir_bottom(2),cir_bottom(3),cir_bottom(4));
    Eyelink('command', 'draw_box %d %d %d %d 15', cir_left(1),cir_left(2),cir_left(3),cir_left(4));
    
    Eyelink('StartRecording'); %start recording eye position in the EDF file
    WaitSecs(0.1);
    
    eye_used = Eyelink('EyeAvailable'); %I think this just determines, for online reading of eye position, which eye to use if you are recording from both at the same time. We only ever record from one at a time so it tends to never be relevant
    if eye_used == 2
        eye_used = 1;
    end
end

if dummymode == 1 %if you are instead not measuring eye position and using the mouse like eye position (usually to test/debug a script)
    ShowCursor(['Arrow']); %show mouse position as an arrowhead (which you'll need to be able to see in order to simulate eye position by moving it with the mouse)
end

% =========================================================================
% =============== Beginning of task! ======================================
% =========================================================================

%variables that will be saved out
RT_matrix = [];
trial_num = 1:length(scenes_texture_matrix);
response_matrix = {};
%accuracy = []; will add this once real stimuli are up and running
file_name = {};
sub_num_for_output(1:length(scenes_texture_matrix)) = str2num(subjno_Str);

% Create a cell array to store eye movement data for each trial
eye_movement_data = cell(1, number_of_trials);

%this loop runs the main task
for trial = 1:number_of_trials
    img_num = img_order_matrix(trial);  % Get the image number for the current trial
    
    this_trial_target = randsample(all_targets, 1);
    
    oldsize = Screen('TextSize', my_window,60); %make the font size a little bigger when drawing the fixation cross
    DrawFormattedText(my_window, '+', 'center', 'center', [255,255,255]); %draws the fixation cross (a plus-sign) at the center of the screen
    Screen('Flip', my_window); %put what you just drew (the fixation cross) on the screen
    Screen('DrawTexture', my_window, stimuli_texture_matrix(this_trial_target));
    
    oldsize = Screen('TextSize', my_window, 40); %change the font size back to 40 after you draw the fixation cross
    
    if dummymode == 0 %if tracking, log when the trial started in the EDF file
        Eyelink('Message', 'TRIALID %d', Trial);
        Eyelink('command', 'record_status_message "TRIAL %d/%d"', Trial, numTrials);
    end
    ReadyToBegin = 0; %set this variable to zero to begin the trial, and it will need to turn to 1 when central fixation is acquired to proceed
    
    while ReadyToBegin == 0
        if dummymode==0 %the following grabs the x and y position of the eye if tracking
            
            %if not recording (because the connection to the tracker
            %was interrupted/broken), break out of the loop
            error=Eyelink('CheckRecording');
            if(error~=0)
                break;
            end
            
            if Eyelink('NewFloatSampleAvailable') > 0 %if a new read on eye position is avaialble
                evt = Eyelink('NewestFloatSample'); %grab the new sample as a variable "evt" This is a structured variable with multiple parts
                evt.gx; %this part of variable evt is the x-position of measured eye position (in pixels)
                evt.gy; %this part of variable evt is the y-position of measured eye position (in pixels)
                if eye_used ~= -1 %if you are actually measusing from the eye
                    x = evt.gx(eye_used+1); %x will now be the measured eye position in the x-dimension
                    y = evt.gy(eye_used+1); %y will now be the measured eye position in the y-dimension
                    if x~=el.MISSING_DATA && y~=el.MISSING_DATA && evt.pa(eye_used+1)>0 %if eyes are not closed (otherwise measured eye position would not be a valid number, which would cause subsequent logical statements using the variable to fail)
                        mx = x; %update variable mx to measured eye position in the x-dimension
                        my = y; %update variable my to measured eye position in the y-dimension
                    end
                end
            end
        else
            [mx, my]=GetMouse(my_window); %if using the mouse position to simulate eye position, define mx and my in terms of the position of the mouse cursor
        end
        % check if the position obtained is in the fixation window
        fix = mx > winfix(1) &&  mx < winfix(3) && ...
            my > winfix(2) && my < winfix(4); %this logical statement will be true (==1) if measured eye position (mx and my) are inside the box you defined around the fixation cross
        if fix == 1 %if measured eye position (mx and my) is inside the central box around fixation
            fixstart = GetSecs; %define the time that the fixation started
            while fix == 1 %while eye position is still inside the central box (since you later update the variable within the while loop, it can become zero and not be true if eye position later falls outside of the central box)
                %this next part here updates measured eye position as
                %you did before you entered into this while loop. You
                %will keep updating eye position until (a) the time in
                %the box reaches a critical threshold or (b) eye
                %position moves outside of the central box
                if dummymode==0
                    error=Eyelink('CheckRecording');
                    if(error~=0)
                        break;
                    end
                    
                    if Eyelink('NewFloatSampleAvailable') > 0
                        evt = Eyelink('NewestFloatSample');
                        evt.gx;
                        evt.gy;
                        if eye_used ~= -1
                            x = evt.gx(eye_used+1);
                            y = evt.gy(eye_used+1);
                            if x~=el.MISSING_DATA && y~=el.MISSING_DATA && evt.pa(eye_used+1)>0
                                mx = x;
                                my = y;
                            end
                        end
                    end
                else
                    [mx, my]=GetMouse(my_window);
                end
                
                fix = mx > winfix(1) &&  mx < winfix(3) && ...
                    my > winfix(2) && my < winfix(4); %updates the fix variable that reflects whether measured eye position is inside the central box. If not, this now becomes 0 and will cause the while loop to end when it next loops around
                fixduration = GetSecs - fixstart; %variable reflecting how long it has been since eye position was first measured inside the central fixation (current clock time minus the time at which eye position was first measured inside the central box) window
                if fixduration >= 0.5 %if eye position has been inside the central fixation box for 0.5 seconds
                    ReadyToBegin = 1; %fixation has been acquired and we're ready to move on and show the stimulus array
                    break
                end
            end
        elseif fix == 0
            continue
        end
    end
    
    Screen('Flip', my_window);
    Screen('DrawTexture', my_window, scenes_texture_matrix(img_num), [], my_rect);
    
    Screen('DrawTexture', my_window, stimuli_texture_matrix(this_trial_target), [], stimuli_size_rect * stimuli_size + stimuli_location_matrix); 
    Screen('DrawTexture', my_window, stimuli_texture_matrix(randsample(all_distractors, 1)), [], stimuli_size_rect * stimuli_size + [120, 400, 120, 400]);
    Screen('DrawTexture', my_window, stimuli_texture_matrix(randsample(all_distractors, 1)), [], stimuli_size_rect * stimuli_size + [780, 900, 780, 900]);
    Screen('DrawTexture', my_window, stimuli_texture_matrix(randsample(all_distractors, 1)), [], stimuli_size_rect * stimuli_size + [400, 650, 400, 650]);
    
    WaitSecs(1.0);

    
    
    % Start recording eye movements for the current trial
    if dummymode == 0
        Eyelink('Message', 'TRIALID %d', trial);
        Eyelink('command', 'record_status_message "TRIAL %d/%d"', trial, number_of_trials);
        Eyelink('StartRecording');
    end
    
    stim_onset_time = Screen('Flip', my_window);
    response = 'nan';
    RT = NaN;
    startTime = GetSecs();
    while GetSecs() - startTime <= 4
        
        [key_is_down, secs, key_code] = KbCheck;
        if key_is_down
            responseKey = KbName(key_code);
            if strcmp(responseKey, 'z') || strcmp(responseKey, '/?')
                response = responseKey;
                RT = round((secs - stim_onset_time) * 1000); 
                break;
            end
        end
    end
        % Stop recording eye movements for the current trial
    if dummymode == 0
        Eyelink('StopRecording');
    end
    
    % Retrieve and store the eye movement data for the current trial
    if dummymode == 0
        eye_movement_data{trial} = Eyelink('GetQueuedData');
    end

    if strcmp(response, 'nan')
        DrawFormattedText(my_window, 'Too slow!', 'center', 'center');
    else
        DrawFormattedText(my_window, '', 'center', 'center')
    end
    
    Screen('Flip', my_window);
    WaitSecs(0.5);
    
    file_name{end+1} = scenes_file_path_matrix(img_num);
    response_matrix{end+1} = response;
    RT_matrix(end+1) = RT;
end

DrawFormattedText(my_window, 'Saving Data...', 'center', 'center');
Screen('Flip', my_window);

% Save the eye movement data to a file
if dummymode == 0
    eye_movement_file = fullfile(eyetracking_output_folder, edfFileName);
    save(eye_movement_file, edfFileName);
end

%this loop puts all data that needs exported into a cell array that will be
%turned into a table and saved as a .csv file (maybe I could have put it
%directly into a table?)
output_data = {'sub_num' 'file_name' 'trial_num' 'response' 'rt';};
for i = 1:number_of_trials
    output_data{i+1, 1} = sub_num_for_output(1, i);
    output_data{i+1, 2} = file_name(1, i);
    output_data{i+1, 3} = trial_num(1, i);
    output_data{i+1, 4} = response_matrix(1, i);
    output_data{i+1, 5} = RT_matrix(1, i);
end

% Convert cell to a table and use first row as variable names
output_table = cell2table(output_data(2:end,:), 'VariableNames', output_data(1,:));

% Write the table to a CSV file
% Output is working but it is commeted out for now so I don't have a bunch
% saved csv files that I have to go and delete
% writetable(output_table, fullfile(bx_output_folder, bx_output_file_name));


%task shut down
DrawFormattedText(my_window, 'Shutting down task...', 'center', 'center');
Screen('Flip', my_window);
WaitSecs(0.5);

pfp_ptb_cleanup;

%     distractorIndex = 1;
%     for col = 1:4
%         if targetPositionValue == 1 && strcmp(shapeLocationTypes.locationTypes{thisTrialScene, col}, '1!')
%             matchingCondition = true;
%         elseif targetPositionValue == 2 && strcmp(shapeLocationTypes.locationTypes{thisTrialScene, col}, '2@')
%             matchingCondition = true;
%         elseif targetPositionValue == 3 && strcmp(shapeLocationTypes.locationTypes{thisTrialScene, col}, '3#')
%             matchingCondition = true;
%         else
%             matchingCondition = false;
%         end
%         
%         if matchingCondition % Draw the target
%             shapeSize = shapePositions.savedPositions{thisTrialScene, col};
%             if directionRandomizor(col) == 1
%                 Screen('DrawTexture', w, sortedLeftShapesTextures(thisTrialTarget), [], shapeSize);
%                 tDirectionTarget{end+1} = 'L'; %tk preallocate before the final version
%             elseif directionRandomizor(col) == 2
%                 Screen('DrawTexture', w, sortedRightShapesTextures(thisTrialTarget), [], shapeSize);
%                 tDirectionTarget{end+1} = 'R'; %tk preallocate before the final version
%             end
%         end
%     end

%  runStructName = sprintf('run%d', run);
%             runStruct = struct();
%             
%             % Add variables to the run struct
%             %set the 4 targets for this participant
%             allTargets = randsample(1:length(shapeTextures), totalTargets);
%             doubleTargetLocation = randi([1, 3]);
%             targetLocationTypeRandomizor = [1, 2, 3, doubleTargetLocation];
%             randomizedOrder = targetLocationTypeRandomizor(randperm(length(targetLocationTypeRandomizor)));
%             allTargets(2, :) = randomizedOrder;
%             
%             allDistractors = setdiff(1:length(shapeTextures), allTargets(1, :), 'stable');
%             
%             %condition radomization
%             %possible conditions:
%             % - 1 = Target in correct location and additionaltarget is present
%             % - 2 = Target is in wrong location with addition target,
%             % - 3 = Target is in correct location with no additional target
%             % - 4 = Target is in wrong location with no additional target
%             %conditions = [1, 2, 3, 4];
%             
%             %determines where the target location will be
%             targetPosition = [1, 2, 3, doubleTargetLocation];
%             
%             %how to choose between if there's two possible locations
%             targetChoice = [1, 1, 2, 2];
%             
%             %index for all scenes
%             SceneList = 1:length(sceneTextures);
%             
%             %radomizor for trial types
%             extraTargetTrials = [0 0 0 1 0 0 0 1];
%             
%             %randomizor for if target is in correct position
%             
            
%             cBExtraTargetTrials = counterBalancer(extraTargetTrials, trialsPerRun);
%             cBIncorrectTargetLocation = counterBalancer(extraTargetTrials, trialsPerRun); %I needed a number divisible by 12 because of the nature of the counterbalancing. 72 is arbetrary
%             cBTargetPosition = counterBalancer(targetPosition, trialsPerRun);
%             cBTargetChoice = counterBalancer(targetChoice, trialsPerRun); %just a variable for choosing if we use the first or second position if for example if it could appear in position 1 or 4
%             cBSceneOrder = counterBalancer(SceneList, trialsPerRun);
%             
%             
%             %deterimines which direction the t faces
%             tDirection = [1, 1, 2, 2];
%             tDirectionAllTrials = zeros(trialsPerRun, 4);
%             for trialNum = 1:trialsPerRun
%                 tDirectionAllTrials(trialNum, :) = tDirection(randperm(length(tDirection)));
%             end
%             
%             cBTargetOrder = [];
%             cBOrigionalTargetPosition = [];
%             choice = 1;
%             for numTargets = 1:length(cBTargetPosition)
%                 inds = find(allTargets(2, :) == cBTargetPosition(numTargets));
%                 if length(inds) > 1
%                     if choice == 1
%                         inds = inds(choice);
%                         choice = 2;
%                     elseif choice == 2
%                         inds = inds(choice);
%                         choice = 1;
%                     end
%                 end
%                 cBTargetOrder(end+1) = allTargets(1, inds);
%                 cBOrigionalTargetPosition(end+1) = allTargets(2, inds);
%             end
%             
%             allDistractorsAllTrials = [];
%             for k = 1:12 % 6 reps in the inner loop go into 72 (the random number I picked for number of trials to test these with, so 12 reps)
%                 tempDistractors = allDistractors;
%                 
%                 if exist('oneTrialDistractors','var')
%                     clear oneTrialDistractors
%                 end
%                 
%                 for i = 1:6 %there are 18 distractors 18/3 = 6, so thats why 6 repitions
%                     if exist('oneTrialDistractors','var')
%                         tempDistractors = setdiff(tempDistractors, oneTrialDistractors);
%                     end
%                     distractorsInds = randsample(1:length(tempDistractors), 3);
%                     oneTrialDistractors = tempDistractors(distractorsInds);
%                     allDistractorsAllTrials(end+1, :) = oneTrialDistractors;
%                 end
%             end
