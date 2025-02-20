function objectiveValue = RatioConnectedToStrayWords(words, numHybes)
% ------------------------------------------------------------------------
% objectiveValue = NumberAboveBlank(words, wordIDsNonBlank, wordIDBlank)
% This function determines the number of species greater than the largest
% blank. 
%--------------------------------------------------------------------------
% Necessary Inputs
%--------------------------------------------------------------------------
% Outputs
%--------------------------------------------------------------------------
% Variable Inputs (Flag/ data type /(default)):
%--------------------------------------------------------------------------
% Alistair Boettiger, Jeffrey Moffitt
% November 26, 2014
%--------------------------------------------------------------------------
% Creative Commons License CC BY NC SA
%--------------------------------------------------------------------------
binaryWords = de2bi(words, numHybes);

numSingles = sum( sum(binaryWords,2) == 1);
numFours = sum( sum(binaryWords,2) == 4);

objectiveValue = numFours/(numSingles + numFours);