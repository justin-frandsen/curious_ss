function [filePathMatrix, textureMatrix] = image_stimuli_import(fileDirectory, fileType, PTBwindow, sortLogical)
%------------------------------------------------------------------------
% Function: image_stimuli_import
% Author:   Justin Frandsen (refactored & commented)
% Date:     07/22/2024 (updated 08/11/2025)
%
% Description:
%   Imports image files from a specified directory and turns them into
%   Psychtoolbox (PTB) textures that can be displayed.
%
% Inputs:
%   fileDirectory - String: Path to the directory containing images
%   fileType      - String: File extension pattern (e.g., '*.png', '*.jpg')
%   PTBwindow     - PTB window pointer (must be created before calling)
%   sortLogical   - Logical: If true, sorts files by numbers in filenames
%
% Outputs:
%   filePathMatrix - String array: full paths to image files
%   textureMatrix  - Numeric array: PTB texture handles
%
% Notes:
%   - PNG files are loaded with transparency if available
%   - Sorting looks for numbers in the format 'Shape##' but can be adapted
%------------------------------------------------------------------------

%% Handle missing sortLogical argument
if nargin < 4
    sortLogical = false;
end

%% Validate & load file list
if isempty(fileType)
    % No file type specified: load all files in folder
    myFiles = dir(fullfile(fileDirectory));
else
    % Make sure to use string comparison instead of "=="
    myFiles = dir(fullfile(fileDirectory, fileType));
end

% Remove hidden/system files
myFiles = myFiles(~ismember({myFiles.name}, {'.', '..', '.DS_Store'}));

%% Preallocate outputs
numFiles = length(myFiles);
filePathMatrix = strings(numFiles, 1);
textureMatrix  = zeros(numFiles, 1);

%% Load images & create textures
for k = 1:numFiles
    baseFileName = myFiles(k).name;
    fullFilePath = string(fullfile(fileDirectory, baseFileName));
    
    fprintf('Loading: %s (%d/%d)\n', baseFileName, k, numFiles);

    % Read image (handle PNG transparency if needed)
    if strcmpi(fileType, '*.png')
        [loadedImg, ~, alpha] = imread(fullFilePath);
        if ~isempty(alpha)
            loadedImg(:, :, 4) = alpha; % Add alpha as 4th channel
        end
    else
        loadedImg = imread(fullFilePath);
    end
    
    % Create PTB texture
    textureMatrix(k) = Screen('MakeTexture', PTBwindow, loadedImg);
    
    % Store file path
    filePathMatrix(k) = fullFilePath;
end

%% Optional sorting by numbers in filename
if sortLogical
    % Extract numbers after "Shape" in filename
    numbersSort = regexp(filePathMatrix, 'Shape(\d+)', 'tokens');
    
    % Convert tokens to numbers, set NaN if no match
    numbersSort = cellfun(@(x) ...
        (isempty(x) * NaN) + (~isempty(x) * str2double(x{1})), ...
        numbersSort);
    
    % Sort by detected numbers
    [~, sortedIndices] = sort(numbersSort, 'ascend', 'MissingPlacement', 'last');
    
    filePathMatrix = filePathMatrix(sortedIndices);
    textureMatrix  = textureMatrix(sortedIndices);
end

end
