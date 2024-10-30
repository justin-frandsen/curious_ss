% PTB Settings
WinNum                  = 0; % 0 means only one monitor. 

[w, rect] = pfp_ptb_init; %call this function which contains all the screen initilization.
[width, height] = Screen('WindowSize', WinNum); %get the width and height of the screen
Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); %allows the .png files to be transparent

%load in shapes for instructions
instructionShapes       = 'Stimuli/shapes/instructions';
[sortedInstructionShapesFilePaths, sortedInstructionShapesTextures] = imageStimuliImport(instructionShapes, '*.png', w, true);

% Define your instruction text as an array of strings, splitting it into parts.
instructionText = {
    'In this experiment, each trial you will be presented a target shape. You ',
    'will be asked to search for this shape in a following scene. All shapes ', 
    'will appear with a sideways T in them. Each scene will have multiple ',
    'shapes in it, but you will be asked to only report the direction of the ', 
    'T in the target shape.', 
    'If the target shape appears with the T in this orientation press /',
    '',
    '',
    '',
    '',
    'If the target shape appears with the T in this orientation press z'
    '',
    '',
    '',
    '',
};

% Initialize variables for text display.
instructionTextStart = 1;
instructionTextEnd = 1;
textChunkSize = 5;  % Number of lines to display at a time.

leftMargin = 450;
presCount = 1;

% Loop to display text in chunks.
while instructionTextStart <= numel(instructionText)
    % Determine the end of the text chunk.
    instructionTextEnd = instructionTextStart + textChunkSize - 1;
    if instructionTextEnd > numel(instructionText)
        instructionTextEnd = numel(instructionText);
    end
    
   
    
    % Display the current chunk of text.
    DrawFormattedText(w, strjoin(instructionText(instructionTextStart:instructionTextEnd), '\n'), leftMargin, 'center');
    
    if presCount == 2
        Screen('DrawTexture', w, sortedInstructionShapesTextures(1), [], [910, 490, 1010, 590]);
    elseif presCount == 3
        Screen('DrawTexture', w, sortedInstructionShapesTextures(2), [], [910, 490, 1010, 590]);
    end
    
    Screen('Flip', w);
    
    presCount = presCount+1;
    % Wait for a key press (spacebar) to continue.
    KbWait([], 2);
    
    % Update the starting point for the next chunk.
    instructionTextStart = instructionTextEnd + 1;
end

% Close the window or perform other actions as needed.

pfp_ptb_cleanup