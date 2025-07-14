function[filePathMatrix, textureMatrix] = imageStimuliImport(fileDirectory, fileType, PTBwindow, sortLogical)
%-------------------------------------------------------------------------
% Script: imageStimuliImport.m
% Author: Justin Frandsen
% Date: 07/20/2023
% Description: Matlab Script that is used for importing image files and
%              turing them into textures.
%
% Usage:
% - fileDirectory: the the absolute or relative path for the directory 
%   containing the files you wish to input to PTB 
% - fileType: this must be a string with * at beginning (i.e., '*.png')
% - PTBwindow: Psychtoolbox must be initilized before starting this script.
%   PTBwindow is the pointer that represents the screen the images will be
%   displayed on
% - Script will output a matrix containing the file paths for the images
%   and a matrix containing textures which can be displayed using ptb
% - If sort is true then when it will sort the texture and path matrixes 
%   based on numbers in the file names
%-------------------------------------------------------------------------
if nargin < 4
    sortLogical = false;
end

if isempty(fileType)
    % The inputVariable is empty.
    myFiles = dir(fullfile(fileDirectory));
    % Exclude '.' (current directory) and '..' (parent directory)
    myFiles = myFiles(~ismember({myFiles.name}, {'.', '..'}));
elseif fileType == '*.png'
    % The inputVariable is not empty.
    % Proceed with your function logic.
    myFiles = dir(fullfile(fileDirectory, '*.png'));
end

filePathMatrix = string(zeros(length(myFiles), 1)); %matrix that contains all image file paths
textureMatrix = zeros(length(myFiles), 1); %matrix that contains all the textures of the image files

for k = 1:length(myFiles)
    baseFileName = myFiles(k).name;
    fullFilePath = string(fullfile(fileDirectory, baseFileName));
    
    %this if differs for .png files because png files have the ability to
    %be transparent, so they need the alpha variable.
   
    if strcmp(fileType, '*.png')
        [loadedImg, ~, alpha] = imread(fullFilePath);
        loadedImg(:, :, 4) = alpha;
    else
        loadedImg = imread(fullFilePath);
    end
    
    
    textureMatrix(k) = Screen('MakeTexture', PTBwindow, loadedImg);
    filePathMatrix(k, 1) = fullFilePath;
end

%this will sort based on numbers within the name of a given file.
if sortLogical == true
    numbersSort = regexp(filePathMatrix, 'Shape(\d+)', 'tokens');
    numbersSort = cellfun(@(x) str2double(x{1}), numbersSort);
    [~,sortedIndices] = sort(numbersSort);
    newTextureMatrix = textureMatrix(sortedIndices, :);
    newFilePathMatrix = filePathMatrix(sortedIndices);
    
    textureMatrix = newTextureMatrix;
    filePathMatrix = newFilePathMatrix;
end

end