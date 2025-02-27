function [filePaths,fileNames] = FindFileInSubFolders(parentFolder,fileName,varargin)
% ----------------------------------------------------------------------- % 
% returns a list of complete file paths to all files matching "fileName"
% (wildcard * characters are allowed). 
% 
% Example 1: filePaths = FindFileInSubFolders('C:\Data\','*.i4d')
% returns all .i4d files in 'C:\Data\' or any of its subfolders
% 
% Example 2: Return just the file names, not the full path
% [~,fileNames] = FindFileInSubFolders('C:\Data\','*.i4d')
% 
% [~,foundSpotTables] = FindFileInSubFolders(saveFolder,'fov*AllFits.csv')
% ----------------------------------------------------------------------- % 
% Alistair Boettiger
% CC BY NC Aug 9 2017
% updated 241219 Sedona Murphy for compatibiliy with linux 

% fileName = '*AllFits.csv'
% fileName = '*.csv'

defaults = cell(0,3);
defaults(end+1,:) = {'depth','nonnegative',inf};
pars = ParseVariableArguments(varargin,defaults,mfilename);

if pars.depth == 0
    dirOutput = dir(fullfile(parentFolder, fileName));
    fileNames = {dirOutput.name}';
    filePaths = fullfile(parentFolder, fileNames);
else
    if ispc
        allFolders = strsplit(genpath(parentFolder), ';');
    else
        allFolders = strsplit(genpath(parentFolder), ':');
    end
    allFolders = allFolders(~cellfun('isempty', allFolders)); % Remove empty entries

    nFolders = length(allFolders);
    fullPaths = cell(nFolders, 1); 
    fileNames = cell(nFolders, 1); 
    for i = 1:nFolders
        dirOutput = dir(fullfile(allFolders{i}, fileName));
        fileNames{i} = {dirOutput.name}';
        fullPaths{i} = fullfile(allFolders{i}, fileNames{i});
    end
    filePaths = vertcat(fullPaths{:});
    fileNames = vertcat(fileNames{:});
    filePaths(cellfun(@isempty, filePaths)) = [];
    fileNames(cellfun(@isempty, fileNames)) = [];
    [~, ~, fileType] = fileparts(fileName);
    keep = contains(filePaths, fileType);
    filePaths = filePaths(keep);
end