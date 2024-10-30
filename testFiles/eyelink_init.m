function el = eyelink_init(w, edfFileName, width, height)

% =========================================================================
% =============== Initialize the eyetracker! ==============================
% =========================================================================

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