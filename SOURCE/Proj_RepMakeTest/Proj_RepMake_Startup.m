%=========================================================================%
% MATLAB STARTUP  ========================================================%
%                 RepMake: GNU Make for Matlab: Reproducible Manuscripts  %
%                 Critical file for MATLAB standalone scripts defining    %
%                 constants, paths, and data files.                       %
%                 Datafiles are stored as htpPortableClass objects which  %
%                 contain eegDataClass objects. Objects contain paths to  %
%                 datafiles and analysis methods.                         %
%=========================================================================%

% PROJECT SPECIFIC STARTUP - Project Name should be identical to directory

SetupMatlabPaths;   % assign system paths including root_dir

PROJECT_PATH = 'Proj_RepMakeTest';

%=========================================================================%
%                        DIRECTORY CONFIGURATION                          %
%=========================================================================%

syspath.projsource = fullfile(SOURCE_PATH, PROJECT_PATH);
syspath.rawdata = fullfile(ROOT_PATH, 'RAWDATA', PROJECT_PATH);
% ======================= INPUT DATA =====================================%
% HTP Data structure can be created from HTP Preprocessing Pipeline OR
% directly importing cleaned data in SET format using htpDirectImport GUI.

syspath.htpdata  = fullfile(ROOT_PATH, 'RAWDATA', PROJECT_PATH);

keyfiles.datacsv = fullfile(syspath.htpdata, ...
	'A00_ANALYSIS/A2111081422_subjTable_Default_Stage4.csv');
keyfiles.datamat = fullfile(syspath.htpdata, ...
	'A00_ANALYSIS/A2111081422_subjTable_Default_Stage4.mat');

% ======================= OUTPUT =========================================%
syspath.BigBuild      = fullfile(ROOT_PATH, 'BIGBUILD/', PROJECT_PATH);
syspath.SelectBuild    = fullfile(REPMAKE_PATH, 'BUILD/', PROJECT_PATH);

% adding both build folders to MATLAB path
cellfun(@(x) addpath(x), {syspath.BigBuild, syspath.projsource, syspath.rawdata , syspath.SelectBuild}, 'uni',0)

%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %     
%                  Version 8/2021                                         %
%                  cincibrainlab.com                                      %
% ========================================================================%
