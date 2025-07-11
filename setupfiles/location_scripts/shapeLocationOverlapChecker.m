function shapeLocationOverlapChecker(sceneTypeMain0Practice1, unchecked0checked1)
%-----------------------------------------------------------------------
% Script: shapeLocationOverlapChecker.m
% Author: Justin Frandsen
% Date: 10/02/2023
% Description:
% - This script takes the output of shapePositionFinder.m and checks what
%   locations are overlaping.
% Usage:
% - For main scenes use sceneTypeMain0Practice1 = 0 and for practice scenes
%   use sceneTypeMain0Practice1 = 1. 
% - To use output from shapePositionChecker.m instead use
%   unchecked0checked1 = 1
%-----------------------------------------------------------------------

if sceneTypeMain0Practice1 == 0 && unchecked0checked1 == 0
    shapeLocationTypes = load('trialDataFiles/shape_location_types_main.mat');
    shapePositions = load('trialDataFiles/shape_positions_main.mat');
elseif sceneTypeMain0Practice1 == 1 && unchecked0checked1 == 0
    shapeLocationTypes = load('trialDataFiles/shape_location_types_practice.mat');
    shapePositions = load('trialDataFiles/shape_positions_practice.mat');
elseif sceneTypeMain0Practice1 == 0 && unchecked0checked1 == 1
    shapeLocationTypes = load('trialDataFiles/shape_location_types_main_checked.mat');
    shapePositions = load('trialDataFiles/shape_positions_main_checked.mat');
elseif sceneTypeMain0Practice1 == 1 && unchecked0checked1 == 1
    shapeLocationTypes = load('trialDataFiles/shape_location_types_practice_checked.mat');
    shapePositions = load('trialDataFiles/shape_positions_practice_checked.mat');
end

savedPositions = shapePositions.savedPositions;
numScenes = length(savedPositions);
numRects = 4;

totalDifferentMatchedScenes = 0;
floorWithWall = 0;
floorWithCounter = 0;
counterWithWall = 0;

overlapMatrix = cell(numScenes, numRects);
%sceneMatchPairs
for thisSceneNum = 1:numScenes
    thisSceneOverlapMatrix = zeros(numScenes, numRects);
    for k = 1:numRects
        
        thisPosition = savedPositions(thisSceneNum, k);
        totalMatchesCounter = 0;
        differentTypeMatchesCounter = 0;
        for sceneNum = 1:numScenes
            for i = 1:numRects
                rect2 = savedPositions(sceneNum, i); % Exclude the type column
                
                % Check for overlap
                if rectOverlap(thisPosition{1}, rect2{1})
                    % Store the type in the overlapMatrix
                    primarySceneType = shapeLocationTypes.locationTypes(thisSceneNum, k);
                    secondarySceneType = shapeLocationTypes.locationTypes(sceneNum, i);
                    thisSceneOverlapMatrix(sceneNum, i) = secondarySceneType;
                    
                    totalMatchesCounter = totalMatchesCounter +1;
                    if primarySceneType ~= secondarySceneType
                        fprintf("Primary Scene(%d, %d), Type: %d -- SecondaryScene(%d, %d) Type: %d\n",thisSceneNum, k, primarySceneType,sceneNum, i, secondarySceneType)
                        differentTypeMatchesCounter = differentTypeMatchesCounter+1;
                        
                        if primarySceneType == 1 && secondarySceneType == 3 || primarySceneType == 3 && secondarySceneType == 1
                            counterWithWall = counterWithWall + 1;
                        elseif primarySceneType == 1 && secondarySceneType == 2 || primarySceneType == 2 && secondarySceneType == 1
                            floorWithWall = floorWithWall + 1;
                        elseif primarySceneType == 2 && secondarySceneType == 3 || primarySceneType == 3 && secondarySceneType == 2
                            floorWithCounter = floorWithCounter + 1;
                        end
                    end
                end
            end
        end
        fprintf("Scene(%d, %d) total matches = %d, different matches = %d\n", thisSceneNum, k, totalMatchesCounter, differentTypeMatchesCounter);
        if differentTypeMatchesCounter > 0
            totalDifferentMatchedScenes = totalDifferentMatchedScenes +1;
        end
        overlapMatrix{thisSceneNum, k} = thisSceneOverlapMatrix;
        
    end
    
end

fprintf("Scenes Positions w/ different matches = %d/%d\n", totalDifferentMatchedScenes, numScenes*4)
fprintf("Floor with Wall Match Count = %d\n", floorWithWall/2) %divide by 2 because it checks each position twice
fprintf("Floor with Counter Match Count = %d\n", floorWithCounter/2) 
fprintf("Counter with Wall Match Count = %d\n", counterWithWall/2)

for sceneNum = 1:numScenes
    if sum(find(shapeLocationTypes.locationTypes(2, :) == 1)) >= 1 && sum(find(shapeLocationTypes.locationTypes(2, :) == 2)) >= 1 && sum(find(shapeLocationTypes.locationTypes(2, :) == 3)) >= 1
        fprintf("SceneNum: %d, is good\n", sceneNum);
    else
        fprintf("SceneNum: %d, is bad\n", sceneNum);
    end
end
end

function overlap = rectOverlap(rect1, rect2)
    x1 = rect1(1);
    y1 = rect1(2);
    w1 = rect1(3) - x1;
    h1 = rect1(4) - y1;
    
    x2 = rect2(1);
    y2 = rect2(2);
    w2 = rect2(3) - x2;
    h2 = rect2(4) - y2;
    
    % Calculate the right and bottom edges of the rectangles
    right1 = x1 + w1;
    bottom1 = y1 + h1;
    
    right2 = x2 + w2;
    bottom2 = y2 + h2;
    
    % Check for overlap
    overlap = (x1 < right2) && (x2 < right1) && (y1 < bottom2) && (y2 < bottom1);   
end