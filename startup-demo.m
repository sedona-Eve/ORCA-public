
% copy this file to the your matlab statup directory (typically 'C:\Users\UserName\Documents\MATLAB\')
% rename this file 'startup.m'  
% If you already use a startup script, append the commands below to your script 
% You should see a notification that ORCA-public has been added to filepath 
% 
global matlabFunctionsPath
matlabFunctionsPath='/home/sedona/Documents/matlab-functions-linux';
addpath(genpath(matlabFunctionsPath));
global scratchPath;
scratchPath = '/home/sedona/Documents/scratchPath';
addpath(genpath(scratchPath));

global pyPath;
pyPath = '/home/sedona/miniconda3/';  % Path to Anaconda installation

% Define conda activation commands for different environments
global condaPrompt_storm;
condaPrompt_storm = [pyPath, 'bin/conda run --no-capture-output -n storm-analysis-clean '];

global condaPrompt_cellpose;
condaPrompt_cellpose = [pyPath, 'bin/conda run --no-capture-output -n cellpose '];

% DaoSTORM execution using storm-analysis environment
global daoSTORMexe;
daoSTORMexe = [condaPrompt_storm, 'python /home/sedona/Documents/storm-analysis/storm_analysis/daostorm_3d/mufit_analysis.py'];

% Default XML file for DaoFit
global defaultXmlFile;
defaultXmlFile = '/home/sedona/Documents/matlab-functions-linux/ChrTracingLib/fitPars_test.xml';

% Cellpose execution using cellpose environment
global cellpose_env;
cellpose_env = [condaPrompt_cellpose, 'python -m cellpose'];


