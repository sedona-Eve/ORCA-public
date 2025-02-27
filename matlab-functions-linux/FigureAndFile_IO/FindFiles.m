function foundFiles = FindFiles(strIn, varargin)
% FindFiles: A replacement for cellstr(ls(strIn)) with additional features:
% - Returns an empty cell if no files are found.
% - Can filter for folders only or files only.
% - Removes "." and ".." entries by default.
% - Supports returning full file paths.
%
% Usage:
%   foundFiles = FindFiles('*.csv', 'fullPath', true, 'onlyFolders', false);

% Default parameters
defaults = cell(0, 3);
defaults(end+1, :) = {'fullPath', 'boolean', true};     % Return full paths
defaults(end+1, :) = {'removeDot', 'boolean', true};    % Remove "." and ".."
defaults(end+1, :) = {'onlyFolders', 'boolean', false}; % Return folders only
defaults(end+1, :) = {'onlyFiles', 'boolean', false};   % Return files only
pars = ParseVariableArguments(varargin, defaults, mfilename);

% Split input path for folder and file pattern
[folder, fname, ftype] = fileparts(strIn);
if isempty(folder)
    folder = '.'; % Current directory if no folder specified
end

% Get directory contents
dirOut = dir(strIn);

% Filter for folders only, if specified
if pars.onlyFolders
    dirOut = dirOut([dirOut.isdir]); % Keep only directories
    foundFiles = {dirOut.name}; % Extract names
    foundFiles = appendFilesep(foundFiles); % Append filesep to folders
else
    % Filter for files only, if specified
    if pars.onlyFiles
        dirOut = dirOut(~[dirOut.isdir]); % Keep only files
    end
    foundFiles = {dirOut.name}; % Extract names
end

% Prepend folder path if fullPath is true
if pars.fullPath && ~isempty(foundFiles)
    foundFiles = fullfile(folder, foundFiles);
end

% Remove "." and ".." if requested
if pars.removeDot
    foundFiles = foundFiles(~ismember(foundFiles, {'.', '..', './', '../'}));
end

% Ensure output is a column cell array
foundFiles = foundFiles(:);

% Helper function to append filesep to folder names
function names = appendFilesep(names)
    names = strcat(names, filesep); % Add filesep to each name
end

end
