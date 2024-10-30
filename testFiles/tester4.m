shapeLocationTypes = load('shape_location_types.mat');
shapePositions = load('shape_positions.mat');

mx = 118.0000;
my= 296.0000;

trialNum = 1;
targetInds = 3;
startTime = GetSecs(); % Gets the time when this line was run
fixationMatrix = [];  % Initialize an empty fixation matrix
fixationStartTime = 0; % Initialize the start time of the current fixation
isFixating = false;  % Initialize isFixating here
previousFixationRect = NaN; % Initialize the previously fixated rectangle
currentFixationRect = NaN; % Initialize the currently fixated rectangle
currentFixationStart = NaN;

% Check if gaze is within any of the fixation rectangles
isWithinFixationArea = false;  % Initialize the flag
for j = 1:4
    if IsInRect(mx, my, shapePositions.savedPositions{12, j})
        currentFixationRect = j;  % Update the currently fixated rectangle
        break;  % Exit the loop since we found a valid fixation area
    else
        currentFixationRect = NaN;
    end
end

if isnumeric(currentFixationRect)
    isFixating = True;
else
    isFixating = False;
end

if isFixating
end


if previousFixationRect ~= currentFixationRect
    
end





% if currentFixationRect ~= previousFixationRect && ~isnan(currentFixationRect)
%     if ~isnan(currentFixationStart)
%         previousFixationStart = currentFixationStart;
%     else
%         previousFixationStart = startTime;
%     end
%     currentFixationStart = GetSecs();
%     duration = previousFixationStart - GetSecs();
%     fixationMatrix = [fixationMatrix; currentFixationRect, duration, trialNum, targetInds, startTime, GetSecs()];
% end

previousFixationRect = currentFixationRect;

        % Check if gaze is within any of the fixation rectangles
        isWithinFixationArea = false;
        for j = 1:4
            if IsInRect(mx, my, shapePositions.savedPositions{sceneInds, j})
                isWithinFixationArea = true;
                currentFixationRect = j;
                break;
            end
        end
        
        % Fixation duration tracking and matrix population
        if isWithinFixationArea
            if ~isFixating || currentFixationRect ~= previousFixationRect
                % If not already fixating or fixating on a different rectangle, start a new fixation
                fixationStartTime = secs;
                isFixating = true;
            end
        else
            if isFixating
                % If fixating and gaze moves out of a fixation area, end the fixation
                fixationDuration = round((secs - fixationStartTime) * 1000);
                fixationMatrix = [fixationMatrix; currentFixationRect, fixationStartTime, fixationDuration];
                isFixating = false;
            end
        end
        
        previousFixationRect = currentFixationRect;