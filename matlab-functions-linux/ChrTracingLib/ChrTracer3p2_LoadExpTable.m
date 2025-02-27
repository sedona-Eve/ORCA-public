function [fiducialFrames, eTable, rawDataNames, scopePars] = ChrTracer3p2_LoadExpTable(expTableXLS, varargin)
% Load experiment table and max-project data. Return max-project (non-drift
% corrected) fiducial data for registration.

defaults = cell(0,3);
defaults(end+1,:) = {'verbose', 'boolean', true}; 
defaults(end+1,:) = {'veryverbose', 'boolean', false}; 
defaults(end+1,:) = {'dataFolder', 'string', ''}; 
defaults(end+1,:) = {'dataTypes', 'cell', {'any'}}; 
defaults(end+1,:) = {'daxRootDefault', 'string', 'ConvZscan*.dax'}; 
defaults(end+1,:) = {'overwrite', 'boolean', false}; 
defaults(end+1,:) = {'maxProject', 'boolean', true}; 
defaults(end+1,:) = {'saveProject', 'boolean', true}; 
defaults(end+1,:) = {'selectFOVs', 'freeType', inf}; 
defaults(end+1,:) = {'stopOnError', 'boolean', false}; 
pars = ParseVariableArguments(varargin, defaults, mfilename);

tic;

% Load the experiment table
eTable = readtable(expTableXLS);

% Determine data folder
if isempty(pars.dataFolder)
    dataFolder = fileparts(expTableXLS); % Get folder name
else
    dataFolder = pars.dataFolder;
end

% Check OPTIONAL Inputs
% OP1: Load only a subset of data
hybFolderID = false(height(eTable), 1);
if ~any(strcmp(pars.dataTypes, 'any'))
    for i = 1:length(pars.dataTypes)
        hybFolderID = hybFolderID | strcmp(eTable.DataType, pars.dataTypes{i});
    end
else
    hybFolderID = true(height(eTable), 1);
end
numHybes = sum(hybFolderID);
eTable = eTable(hybFolderID, :);
hybFolders = eTable.FolderName;

% OP2: Specify full data path in Excel file
dataInTableFolder = false;
if any(strcmp(eTable.Properties.VariableNames, 'DataFolder'))
    if ~isempty(eTable.DataFolder{1})
        dataFolders = eTable.DataFolder;
    else
        dataInTableFolder = true;
    end
else
    dataInTableFolder = true;
end
if dataInTableFolder
    dataFolders = cellstr(repmat(dataFolder, numHybes, 1));
end

% OP3: Specify daxfile names
daxNameCol = contains(eTable.Properties.VariableNames, 'DaxRoot');
if any(daxNameCol)
    daxRoots = eTable{:, daxNameCol};
else
    daxRoots = repmat({pars.daxRootDefault}, numHybes, 1);
end

% Find total number of FOVs by looking in hyb folder 1
if ~any(pars.selectFOVs) || any(isinf(pars.selectFOVs))
    h = 1;
    currFolder = fullfile(dataFolders{h}, hybFolders{h});
    daxFiles = dir(fullfile(currFolder, daxRoots{h}));
    daxFiles = {daxFiles.name};
    numFOVs = length(daxFiles);
    pars.selectFOVs = 1:numFOVs;
else
    numFOVs = length(pars.selectFOVs);
end

% Initialize output variables
fiducialFrames = cell(numHybes, numFOVs);
rawDataNames = cell(numHybes, numFOVs);
infoFile = '';
selectFOVs = pars.selectFOVs;
skip = numFOVs < 1;

% Load data
if ~skip
    disp('Extracting fiducial data for global drift correction');
    disp(['Processing ', num2str(numHybes), ' hybes containing ', num2str(numFOVs), ' total FOVs']);
    if numFOVs > 5 && numHybes > 5
        disp('This may take some time...');
    end
    for h = 1:numHybes
        isFidChn = GetFidChnFromTable(eTable, 'hyb', h);
        currFolder = fullfile(dataFolders{h}, hybFolders{h});
        daxFiles = dir(fullfile(currFolder, daxRoots{h}));
        daxFiles = {daxFiles.name};
        for f = selectFOVs
            currDax = fullfile(currFolder, daxFiles{f});
            rawDataNames{h, f} = currDax;
            try
                if pars.maxProject
                    maxName = ['fidMax_', daxFiles{f}];
                    maxFile = fullfile(currFolder, maxName);
                    if exist(maxFile, 'file') && ~pars.overwrite
                        dax = ReadDax(maxFile, 'verbose', pars.veryverbose);
                    else
                        [dax, infoFile] = ReadDax(currDax, 'verbose', pars.veryverbose);
                        dax = max(dax(:, :, isFidChn), [], 3);
                        if pars.saveProject % Save max projection
                            infoOut = infoFile;
                            infoOut.number_of_frames = 1;
                            infoOut.localName = regexprep(maxName, '.dax', '.inf');
                            WriteDAXFiles(dax, infoOut, 'verbose', pars.veryverbose, 'confirmOverwrite', false);
                        end
                    end
                else
                    fidFrame = find(isFidChn, 1, 'first');
                    dax = ReadDax(currDax, 'verbose', false, 'startFrame', fidFrame, 'endFrame', fidFrame);
                end
                fiducialFrames{h, f} = dax;
            catch er
                if pars.stopOnError
                    warning(er.message);
                    error(['Failed to load data from hybe ', num2str(h), ' for FOV ', num2str(f)]);
                end
                if pars.verbose
                    warning(er.message);
                    disp(['Failed to load data from hybe ', num2str(h), ' for FOV ', num2str(f)]);
                end
            end
        end
        if pars.verbose
            disp([num2str(h / numHybes * 100, 3), '% complete']);
        end
    end
else
    % Just get filenames
    for h = 1:numHybes
        currFolder = fullfile(dataFolders{h}, hybFolders{h});
        daxFiles = dir(fullfile(currFolder, daxRoots{h}));
        daxFiles = {daxFiles.name};
        for f = selectFOVs
            currDax = fullfile(currFolder, daxFiles{f});
            rawDataNames{h, f} = currDax;
        end
    end
end

% Attempt to load scope parameters
if ~isempty(infoFile)
    scopePars = GetScopeSettings(infoFile);
elseif ~isempty(rawDataNames{1})
    infoFile = ReadInfoFile(rawDataNames{1});
    scopePars = GetScopeSettings(infoFile);
else
    scopePars = [];
    warning('Unable to identify scope! Be sure to check pixel-to-nm conversions!');
end

tt = toc;
if pars.verbose
    disp(['ChrTracer spent ', num2str(tt / 60), ' minutes loading data table and max projections for all fields of view']);
end
