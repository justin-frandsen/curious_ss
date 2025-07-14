%% Global Salience
%  Brad T. Stilwell, Ph.D., Justin Frandsen, & Brian A. Anderson, Ph.D.
%  Texas A&M University
%  Address correspondence to Brad T. Stilwell at brad.t.stilwell@gmail.com

% Uses the same design as Adams & Gaspelin (2024, AP&P)
% A set of dynamic (e.g., rotation, jitter) and static (e.g., color,
% size) singleton distractors
% Within-subject design, on any given trial the singleton could be any one
% of the singleton stimuli

%% CLEAR VARIABLES
clc;
clear all;
close all;
ClockRandSeed; % Resets the random # generator 
warning('off', 'MATLAB:colon:nonIntegerIndex') % a warning for the jitter motion (line 22 of getResp) that is useless and annoying

%% RECORD PICS/TRACK EYES?
recordPics = 'N';  % change to 'Y' to record pictures of stimuli
computer = 'PC'; % Mac or PC
refresh_rate = 60; % Hz of monitor
eyetracking = 'Y'; % Y or N

%% IMPORTANT VARIABLES

expName = 'GS'; 
setsize = 6; % search array set size
fudge = .005; % 5 ms to add before screen flip to ensure we hit the refresh cycle
penalty = 2; % 2000 ms
timeout = 5000; % 2000 ms

% Fixation variables
fix.Radius = 90;
fix.Timeout = 5000;
fix.reqDur = 500;

% Blocks & Trials
pBlocks = 1;  % # practice blocks
rBlocks = 10; % # regular blocks
trialsBlock = 60; % 60 trials in each block 
pTotal = trialsBlock * pBlocks; % total practice trials
experimentalBlocks = rBlocks/2; % 5, 120 trial chunks
totalBlocks = pBlocks + rBlocks; % total number of blocks (practice + experimental)
total = (rBlocks * trialsBlock) + (pBlocks * trialsBlock); % Total number of trials in the experimental session

%Fonts
myfont = 'Arial'; % for any text
myfsize = 56;

% Shape Size
shapesize = 54; % size of the search array shapes

eccent = 270;
shapeThick = 4;
shapematrix =  [-shapesize -shapesize shapesize shapesize]; % size of each shape

% Scaling factors for each shape
shape_scaling = struct;

shape_scaling.circle = 1;
shape_scaling.square = 1.15;
shape_scaling.hexagon = 1;
shape_scaling.triangle = 1;
nudge = 20;
    
shape_scaling.oval = .2; % used to be .25

% Shape scaler (function to apply scaling factors to generate shape sizes)

[circSize, sqSize, triSize, hex_parameters, oval_parameters, ovalSize] = ...
    shape_scaler(shape_scaling, shapesize);

diamSize =   shapesize * 1.15;

% Response Line Segment
lineLen = 16;
lineWid = 4;
lineAngle = 45;
lineRect =  [-lineWid/2 -lineLen/2 lineWid/2 lineLen/2];

%Colors and Fonts

numColors = 4;

col.red = [255 41 41]; % 20.02
col.red2 = [255 0 0]; % warning message
col.green = [0 139 1]; % 20.01

col.white = [255 255 255]; 
col.black = [0 0 0]; 
col.yellow = [255 200 15];

col.gray = [117 117 117]; % 20.07

col.bg = col.black;
col.fg = col.white;

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

%% SUBJECT INFORMATION
[subjInfo, outFilename, col] = controlgui_EyeTrack_GS(expName, col);

%% SHUFFLE TRIALS
fprintf('Shuffling variables...\n');
[trial, config] = shuffletrials_EyeTrack_GS(subjInfo, setsize, experimentalBlocks);
fprintf('Done.\n');

%% SETUP PSYCHTOOLBOX
% Do NOT change the name of these global variables
global expWin;
global rect;
global scrW;
global scrH;
global scrHz;
global scrID;
scrW = 1920;
scrH = 1080;
scrHz = refresh_rate;
ctrX = scrW/2;
ctrY = scrH/2;

PTB_Setup_Brad(scrW, scrH, scrHz)   % Custom function to setup
HideCursor(scrID);             % Hide mouse cursor
ListenChar(2);                 % Stop listening to keyboard

%% SCREENS & STIMULI
% Search Locations (clockwise)
loc(setsize) = struct;
loc(1).x = ctrX;
loc(1).y = ctrY - eccent;
for i = 2:setsize
    [loc(i).x, loc(i).y] = xyrotate(loc(1).x, loc(1).y, ctrX, ctrY,...
        (i-1)*(360/setsize));
end

%% Background Screens

% Screens
bufimg =  Screen('OpenOffscreenWindow',scrID, col.bg, rect);
Screen('TextFont', bufimg, myfont);
Screen('TextSize', bufimg, myfsize);

blank =  Screen('OpenOffscreenWindow',scrID, col.bg, rect);

fixsize = 16;
fixthick = 4;
fixation =  Screen('OpenOffscreenWindow', scrID, col.bg, rect);
Screen('FillOval', fixation, col.gray,...
    CenterRectOnPoint([-fixsize -fixsize fixsize fixsize], ctrX, ctrY));
Screen('FillRect', fixation, col.bg,...
    CenterRectOnPoint([-fixsize -fixthick fixsize fixthick], ctrX, ctrY));
Screen('FillRect', fixation, col.bg,...
    CenterRectOnPoint([-fixthick -fixsize fixthick fixsize], ctrX, ctrY));
Screen('FillOval', fixation, col.gray,...
    CenterRectOnPoint([-fixthick -fixthick fixthick fixthick], ctrX, ctrY));

search  =   Screen('OpenOffscreenWindow', scrID, col.bg, rect);

tooslow =   Screen('OpenOffscreenWindow', scrID, col.bg, rect);
Screen('TextFont',tooslow, myfont);
Screen('TextSize',tooslow, myfsize);
txt = 'Too Slow!';
DrawFormattedText(tooslow, txt, 'center', 'center', col.fg);

incorrect =   Screen('OpenOffscreenWindow', scrID, col.bg, rect);
Screen('TextFont',incorrect, myfont);
Screen('TextSize',incorrect, myfsize);
txt = 'Incorrect!';
DrawFormattedText(incorrect, txt, 'center', 'center', col.fg);

% Search with motion
search_motion =  Screen('OpenOffscreenWindow', scrID, col.bg, rect);


%% Setup Eyetracker
%  Do not change these variables

if strcmpi(eyetracking, 'Y')
    
    % Set Up Eyetracker
    eye = 2;  %1 = LEFT  2 = RIGHT
    edfName = [expName subjInfo.subjnum '.edf'];
    el = ELconnect(edfName, scrHz);
    
    
    % Set Up Eyetracker Monitor
    fprintf('Drawing items to eyetracker screen...')
    Eyelink('Command', 'clear_screen 0'); %clear screen
    for a = 1:360 % draw fixation lines on screen
       [x, y] = xyrotate(fix.Radius+ctrX, ctrY, ctrX, ctrY, a);
       Eyelink('Command', 'draw_line %i %i %i %i 3', ctrX, ctrY, round(x), round(y));
    end
    for i = 1:setsize  % draw fixation items on screen
        for a = 1:360
           [x, y] = xyrotate(loc(i).x+shapesize, loc(i).y, loc(i).x, loc(i).y, a);
           Eyelink('Command', 'draw_line %i %i %i %i 5', round(loc(i).x), round(loc(i).y), round(x), round(y));
        end
    end
    fprintf('done!\n');
    
end

%% Start Experiment
t = 0;
ACCcount = 0;
trialcounter = 0;

%% EXPERIMENT START
for b = 1:totalBlocks
    
    % Instructions
        if b == 1
            instruct_GS(subjInfo, key);
            % Calibration instructions
            instruct_calibrate(key, col);
        end
        
        %% Calibrate Eyetracker %%
        if strcmpi(eyetracking, 'Y')
            % Setup the eyetracker
            EyelinkDoTrackerSetup(el);
            if b == 1
                % Trackable?
                [track] = trackable(myfont, myfsize, key, col);

                % NOT TRACKABLE (CLOSE DOWN)
                if strcmpi(track, 'N')
                    clear Screen;
                    Screen('CloseAll');
                    ShowCursor();
                    ListenChar(0);
                    Eyelink('StopRecording');
                    Eyelink('CloseFile');
                    WaitSecs(1);
                    Eyelink('ShutDown');
                end
            end
        end

    
    % Block Intro
    blockintro_EyeTrack(b, totalBlocks, col, col.bg, subjInfo, key);
    
    %% TRIAL LOOP
    for tt = 1:trialsBlock

        t = t + 1;
        trial(t).trial = t;
        
        %% Draw Stimuli
        % Search
        Screen('DrawTexture', search, fixation);
        Screen('DrawTexture', search_motion, fixation);
        
        for i = 1:setsize

            if strcmpi(trial(t).singCond, 'size')
                if i == trial(t).singLoc
                    shapesize = 81; % size singleton
                else
                    shapesize = 54; % normal size
                end
            else % non size singleton trial
                shapesize = 54; % normal size
            end
            %Shapes
            if strcmpi(trial(t).(sprintf('L%i_shape', i)), 'diamond')
                diamond = [ loc(i).x-diamSize  loc(i).y;...
                    loc(i).x            loc(i).y-diamSize;...
                    loc(i).x+diamSize  loc(i).y;...
                    loc(i).x            loc(i).y+diamSize];
                Screen('FillPoly', search, col.(trial(t).(sprintf('L%i_col', i))), diamond, shapeThick);
                
            elseif strcmpi(trial(t).(sprintf('L%i_shape', i)), 'triangle')
                nudge = 20;
                triangle = [  loc(i).x         loc(i).y-shapesize-nudge;...
                    loc(i).x-shapesize     loc(i).y+shapesize-nudge;...
                    loc(i).x+shapesize     loc(i).y+shapesize-nudge];
                Screen('FillPoly', search, col.(trial(t).(sprintf('L%i_col', i))), triangle, shapeThick);
                
            elseif strcmpi(trial(t).(sprintf('L%i_shape', i)), 'hexagon')
                hexagon = [  loc(i).x         loc(i).y-(shapesize/.88);...
                    loc(i).x+(shapesize)        loc(i).y-(shapesize/2);...
                    loc(i).x+(shapesize)        loc(i).y+(shapesize/2);...
                    loc(i).x                  loc(i).y+(shapesize/.88);...
                    loc(i).x-(shapesize)        loc(i).y+(shapesize/2);...
                    loc(i).x-(shapesize)        loc(i).y-(shapesize/2)];
                Screen('FillPoly', search, col.(trial(t).(sprintf('L%i_col', i))), hexagon, shapeThick);
                
            end

            %Lines
            lineAngle = abs(lineAngle);
            if strcmpi(trial(t).(sprintf('L%i_Line',i)), 'L')
                lineAngle = -lineAngle;
            else
                lineAngle = lineAngle; %#ok<*ASGSL>
            end
            [x1,y1] = xyrotate(loc(i).x, loc(i).y + lineLen/2, loc(i).x, loc(i).y, lineAngle);
            [x2,y2] = xyrotate(loc(i).x, loc(i).y - lineLen/2, loc(i).x, loc(i).y, lineAngle);

            % Draw the line at each location
            Screen('DrawLine', search, col.black, x1, y1, x2, y2, lineWid);

        end

        Screen('DrawTexture', search_motion, search);
        
        % ScreenShot Search
        if strcmpi(recordPics, 'Y')
            % Search
            screenshot(search,'Search', t)
        end

        
        %% Present Stimuli %%
        if strcmp(computer, 'Mac')
            Priority(9);
        end
        
        HideCursor(scrID);         % Hide mouse cursor before the next trial
        SetMouse(10, 10, scrID);   % Move the mouse to the corner -- in case some jerk has unhidden it
        
        % Blank ISI
        Screen('DrawTexture', expWin, fixation);
        Screen('flip', expWin);
        WaitSecs(.5); % 500 ms ITI
        
        % Central Fixation
        Screen('DrawTexture', expWin, search);
        if strcmp(eyetracking, 'Y')
            centralFixation(fixation, fix.reqDur, fix.Timeout, fix.Radius, t, el, eye, search)
        end

        % Search Trial %
        % Search
        Screen('DrawTexture', expWin, search);
        [startTime, ~, ~, missed_search] = Screen('flip', expWin);
        if strcmpi(eyetracking, 'Y')
            Eyelink('Message', 'ImageStart');
        end

        % Collect Response
        trial = getResp_GS(trial, eyetracking, key, t, startTime, timeout, ...
            search, search_motion, loc, setsize, diamSize, shapesize, col, lineLen, lineWid, edfName);

        % Fixation
        Screen('DrawTexture', expWin, fixation);
        Screen('flip', expWin);
        
        % Feedback
        if trial(t).ACC == 0
            if strcmp(trial(t).Resp, 'timeout')
                % Show timeout screen
                Beeper(tone, loudness, duration);                
                Screen('DrawTexture', expWin, tooslow);
                [flipStart, ~, flipEnd] = Screen('flip', expWin);
                WaitSecs(penalty);
                Screen('DrawTexture', expWin, fixation);
                Screen('flip', expWin);
            else
                % Error beep, no timeout screen
                Beeper(tone, loudness, duration);
                Screen('DrawTexture', expWin, incorrect);
                [flipStart, ~, flipEnd] = Screen('flip', expWin);
                WaitSecs(penalty);
                Screen('DrawTexture', expWin, fixation);
                Screen('flip', expWin); 
            end
        end


        % Missed screen flip for the search array?
        if missed_search < 0
            trial(t).flipError_search = 0;
        elseif missed_search > 0
            trial(t).flipError_search = 1;
        end
        
        % Lower Priority
        if strcmp(computer, 'Mac')
            Priority(0);
        end
        
        %% Write Data
        date_time = datestr(now);
        trial(t).date = date_time(1:11);
        trial(t).time = date_time(13:20);
        trial(t).block = b;
        fprintf('Block: %i \t Trial: %i \t ACC: %i \t SingletonType: %s  \n', trial(t).block, trial(t).trial, trial(t).ACC, char(trial(t).singCond));
        % Write TXT for behavioral
        trialwrite(trial, outFilename, t);
        % Write TXT for eye tracking
        if strcmpi(eyetracking, 'Y')
            trialwriteET(trial, t);
        end
        
        % Check for ESC
        [~,~,keyCode] = KbCheck(-1);
        if keyCode(key.esc)
            trial(t).Resp = '<ESC>';
            closeShop_Eye(eyetracking, col, edfName);
        end
        
    end
    
    %% Block Feedback
    blockACC = mean([trial(t-trialsBlock+1:t).ACC]);
    blockRT  = mean([trial(t-trialsBlock+1:t).RT]);
    blockfeedback_EyeTrack(blockACC, blockRT, key);
    
end

%% DEBRIEFING
debriefing(key, col.bg, col.fg);

%% SEND EDF FILE AND CLOSE EYETRACKER
if strcmpi(eyetracking, 'Y')
    
    DrawFormattedText(expWin, 'Transferring data file..', 'center', 'center', col.white);
    Screen('flip', expWin);
    
    Eyelink('StopRecording');
    Eyelink('CloseFile');
    fprintf('\n*****\nSending %s to stimulus computer...\n', edfName);
    if Eyelink('ReceiveFile', edfName)
       fprintf('\t>>Success!\n');
       DrawFormattedText(expWin, 'Success!', 'center', 'center', col.white);
       Screen('flip', expWin);
    else
       DrawFormattedText(expWin, 'Error! File transfer failed. Email the experimenter.', 'center', 'center', col.white);
       Screen('flip', expWin);
       fprintf('\t>>ERROR: File not sent!\n'); 
    end  
    WaitSecs(1);
    Eyelink('ShutDown');
end

%% STOP PTB

clear Screen;
Screen('CloseAll');
ShowCursor();
ListenChar(0);