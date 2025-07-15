function [] = centralFixation(expWin, scrH, scrW, fixScreen, reqDur, timeout, radius, t, el, eye, search)
% CENTRALFIXATION This function checks for a central fixation in an
% eyetracking experiment. The subject has to look at a central portion of 
% the screen for a certain amount of time to initiate a trial.
%   fixScreen = the fixation screen in PTB
%   reqDur = required duration of the central fixation (typically 100 ms)
%   timeout = how long to check before jumping back to calibration screen
%   radius = the radius around the center of the screen which counts as
%   fixation; 32 pixels = 1�
%   t = trial count
%   el = eyelink data stuff (from ELConnect)

    ctrX = scrW/2;
    ctrY = scrH/2;

    fix.finished = 0;
    while fix.finished == 0
        fix.Dur = 0;
        fix.Timer = 0;
        fix.held = 0;

        % Start Eyetracker
        Eyelink('StartRecording');
        WaitSecs(0.3);
        Eyelink('Message', 'TRIALID %i ', t);
        Eyelink('Command', 'record_status_message %i', t);
        Eyelink('Message', 'fixCross');

        % Show fixScreen
        Screen('DrawTexture', expWin, fixScreen);
        Screen('flip', expWin);
        Screen('DrawTexture', expWin, search);

        % While not met reqDur && not timed out && eyelink connected
        timerBegin = GetSecs();
        while fix.Dur < reqDur && fix.Timer < timeout && Eyelink('IsConnected')
            samp = Eyelink('NewestFloatSample');
            fix.Timer = (GetSecs() - timerBegin)*1000;
            [keyIsDown,~,keyCode] = KbCheck(-1);
            % if looking at circle around fixScreenxc
            if sqrt((samp.gx(eye)-ctrX)^2 + (samp.gy(eye)-ctrY)^2) < radius && ~(isempty(samp))
                % if 1st fixScreen, start timer
                if fix.held == 0
                    startTime = samp.time;
                    fix.held = 1;
                % else, increment the time    
                else
                    stopTime = samp.time;
                    fix.Dur = (stopTime - startTime);
                end
                % reset fixScreen holder
                if keyIsDown && keyCode(KbName('c'))
                    break;
                end
            else
                fix.held = 0;
            end
        end
        % break out of calibration loop if fixScreen held
        if fix.Dur >= reqDur
            fix.finished = 1;
            % otherwise, you have a timeout and need to restart the trial
        else
            Eyelink('StopRecording');
            WaitSecs(.5);
            EyelinkDoTrackerSetup(el);
            Screen('DrawTexture', expWin, fixScreen);
        end
    end
    
    %% drift correction
    %Eyelink('Command','online_dcorr_trigger');

end

