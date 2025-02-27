function [blastResults, blastData, allHits] = BLAST(sequence, dataBase, varargin)
% ------------------------------------------------------------------------
% [blastResults, blastData, allHits] = BLAST(sequence, dataBase, varargin)
% This function blasts the fastaFile specified by sequence against the
% dataBase.
%--------------------------------------------------------------------------
% Necessary Inputs
% fastaFile: String to a fasta file or a fasta structure
% dataBase: Path to a valid database
%--------------------------------------------------------------------------
% Outputs
%--------------------------------------------------------------------------
% Variable Inputs (Flag/ data type /(default)):
%--------------------------------------------------------------------------
% Creative Commons License CC BY NC SA
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Global variables
%-------------------------------------------------------------------------- 
global scratchPath

%--------------------------------------------------------------------------
% Default Parameters
%-------------------------------------------------------------------------- 
defaults = cell(0, 3);
defaults(end+1, :) = {'blastPath', 'string', ''};
defaults(end+1, :) = {'legacy', 'boolean', false};
defaults(end+1, :) = {'outputFile', 'string', fullfile(scratchPath, 'blastScratch.txt')}; % Use fullfile for paths
defaults(end+1, :) = {'exludeFirstHit', 'boolean', false};
defaults(end+1, :) = {'no3pMatch', 'boolean', false};
defaults(end+1, :) = {'primers', 'struct', []};
defaults(end+1, :) = {'maxhits', 'positive', 100};
defaults(end+1, :) = {'maxResults', 'positive', 100};
defaults(end+1, :) = {'wordSize', 'positive', 15}; 
defaults(end+1, :) = {'showplots', 'boolean', false};
defaults(end+1, :) = {'verbose', 'boolean', true};
defaults(end+1, :) = {'numThreads', 'integer', 1};

% -------------------------------------------------------------------------
% Parse necessary input
% -------------------------------------------------------------------------
if nargin < 2
    error('matlabFunctions:invalidArguments', 'A valid fasta file (or structure) is required and a database');
end

% -------------------------------------------------------------------------
% Parse variable input
% -------------------------------------------------------------------------
parameters = ParseVariableArguments(varargin, defaults, mfilename);

% Handle default blast paths
if isempty(parameters.blastPath)
    if parameters.legacy
        parameters.blastPath = '/path/to/legacy/blast/'; % Update to the correct path
    else
        parameters.blastPath = '~/Documents/NCBI/ncbi-blast-2.16.0+/bin/'; % Update to the correct path
    end
end

% Test Installation
if ~parameters.legacy
    if ~exist(fullfile(parameters.blastPath, 'makeblastdb'), 'file')
        error(['Could not find NCBI blast+. Please update blastPath in ', mfilename]);
    end
else
    if ~exist(fullfile(parameters.blastPath, 'formatdb'), 'file')
        error(['Could not find NCBI blast. Please update legacyBlastPath in ', mfilename]);
    end
end

% Write Fasta file if needed
if ~isstruct(sequence) && ischar(sequence) && exist(sequence, 'file') == 2
    fastafile = sequence; 
    writeFasta = false;
elseif ~isstruct(sequence) && ischar(sequence)  % if a sequence is passed  
    fa.Header = 'InputSequence';
    fa.Sequence = sequence;
    writeFasta = true;
elseif isstruct(sequence) % if a matlab fasta structure is passed
    fa = sequence;
    writeFasta = true;
end

if writeFasta % Write a fasta file if necessary
    fastafile = fullfile(scratchPath, 'tempfasta.fasta');
    if exist(fastafile, 'file') ~= 0
        delete(fastafile); % Use MATLAB delete function
    end
    fastawrite(fastafile, fa);
end

% Overwrite output file if it already exists
if exist(parameters.outputFile, 'file') == 2
    if parameters.verbose
        disp(['deleting ', parameters.outputFile]);
    end
    delete(parameters.outputFile); % Use MATLAB delete function
end

% Run blast
if ~parameters.legacy
    dataBase = regexprep(dataBase, '.fasta', '');
    command = sprintf('%sblastn -query %s -task "blastn-short" -db %s -out %s -num_alignments %d -num_threads %d -word_size %d -outfmt %d', ...
        parameters.blastPath, fastafile, dataBase, parameters.outputFile, parameters.maxResults, parameters.numThreads, parameters.wordSize, 0);
    
    if parameters.verbose
        disp('-----------------------------------------------------------------');
        disp('Issuing:');
        disp(['     ' command]);
        disp('-----------------------------------------------------------------');
    end
    
    system(command); % Execute the command directly

else    
    command = sprintf('%sblastall -i %s -p blastn -d %s -o %s -a %d -K %d', ...
        parameters.blastPath, fastafile, dataBase, parameters.outputFile, parameters.numThreads, parameters.maxResults);
    
    if parameters.verbose
        disp('-----------------------------------------------------------------');
        disp('Issuing:');
        disp(['     ' command]);
        disp('-----------------------------------------------------------------');
    end
    
    system(command);
end

% Load data
if parameters.verbose
    disp('loading data...');
end

blastData = BLASTreadLocal(parameters.outputFile, 0); 

blastResults = ParseBlastData(blastData); 

if parameters.verbose && ~isempty(blastData(1).Hits)
    fprintf('\n'); 
    disp('top BLAST hit per query:')
    disp([blastResults.topHitName, blastResults.topHitSeq]);
end

% Handle hits
numProbes = length(blastResults.numHits);
allHits = zeros(numProbes, 1);
hitLocs = cell(numProbes, 1);
for p = 1:numProbes
    totHits = 0;
    numChrsHit = length(blastData(p).Hits);
    hitLocs{p} = cell(numChrsHit, 1);
    for c = 1:numChrsHit
        totHits = totHits + length(blastData(p).Hits(c).HSPs);
        hitLocs{p}{c} = cat(1, blastData(p).Hits(c).HSPs.SubjectIndices);
    end
    allHits(p) = totHits;
end   

