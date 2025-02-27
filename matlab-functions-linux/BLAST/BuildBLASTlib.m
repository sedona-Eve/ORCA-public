function dataBaseOut = BuildBLASTlib(fastaFile,varargin)
% ------------------------------------------------------------------------
% dataBaseOut = BuildBLASTlib(fastaFile,varargin)
% This function builds a blast library using the specified fasta file
%--------------------------------------------------------------------------
% Necessary Inputs
% fastaFile: String to a fasta file
%--------------------------------------------------------------------------
% Outputs
% dataBaseOut: Path to the created dataBase 
%--------------------------------------------------------------------------
% Variable Inputs (Flag/ data type /(default)):
%--------------------------------------------------------------------------
% Creative Commons License CC BY NC SA
%--------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Default variables
% -------------------------------------------------------------------------
defaults = cell(0,3);

% BLAST version and path options
defaults(end+1,:) = {'blastPath', 'string', ''}; % Base tag for all images
defaults(end+1,:) = {'legacy', 'boolean', false};

% -------------------------------------------------------------------------
% Parse necessary input
% -------------------------------------------------------------------------
if nargin < 1 || ~exist(fastaFile)
    error('matlabFunctions:invalidArguments', 'A valid fasta path is required.');
end

% -------------------------------------------------------------------------
% Parse variable input
% -------------------------------------------------------------------------
parameters = ParseVariableArguments(varargin, defaults, mfilename);

%-------------------------------------------------------------------------
% Handle default blast paths
%-------------------------------------------------------------------------
if isempty(parameters.blastPath)
    if parameters.legacy
        parameters.blastPath = 'C:\Software\NCBI\LegacyBLAST\bin\';
    else
        parameters.blastPath = '~/Documents/NCBI/ncbi-blast-2.16.0+/bin/';
    end
end

%--------------------------------------------------------------------------
% Test Installation
%--------------------------------------------------------------------------
% Test BLAST installations
if ~parameters.legacy
    if ~exist(fullfile(parameters.blastPath, 'makeblastdb'), 'file')
        error(['Could not find NCBI blast+. Please update blastPlusPath in ', mfilename]);
    end
else
    if ~exist(fullfile(parameters.blastPath, 'formatdb'), 'file')
        error(['Could not find NCBI blast. Please update legacyBlastPath in ', mfilename]);
    end
end


%--------------------------------------------------------------------------
% Build database
%--------------------------------------------------------------------------
if parameters.legacy
    dataBaseOut = regexprep(fastaFile, '.fasta', '');  % Set dataBaseOut for legacy
    
    % Generate BLAST database
    command = [parameters.blastPath 'formatdb' ...
        ' -i ' fastaFile ...
        ' -o T' ...  % -o T sets parse SeqID to true
        ' -p F'];    % -p F sets protein to false
else
    dataBaseOut = regexprep(fastaFile, '.fasta', '');  % Set dataBaseOut for BLAST+

    % Build BLAST+ library
    command = [parameters.blastPath 'makeblastdb' ...
        ' -dbtype "nucl"' ...
        ' -in ' fastaFile ...
        ' -parse_seqids' ...
        ' -out ' dataBaseOut];
end

% Display the command being issued
display('-----------------------------------------------------------------');
display('Issuing:')
display(['     ' command]);
display('-----------------------------------------------------------------');

% Run the command
system(command);

