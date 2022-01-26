%=========================================================================%
% MATLAB RUNFILE  ========================================================%
%                 RepMake: GNU Make for Matlab: Reproducible Manuscripts  %
%                 Critical file for MATLAB standalone scripts defining    %
%                 constants, paths, and data files.                       %
%                 Datafiles are stored as htpPortableClass objects which  %
%                 contain eegDataClass objects. Objects contain paths to  %
%                 datafiles and analysis methods.                         %
%=========================================================================%

% PROJECT SPECIFIC STARTUP - Project Name should be identical to directory

SetupMatlabPaths;   % assign system paths including root_dir

PROJECT_PATH = 'Proj_BioPsychSe';

%=========================================================================%
%                            INPUT CONFIGURATION                          %
%=========================================================================%

% ======================= INPUT DATA =====================================%

syspath.projsource = fullfile(SOURCE_PATH, PROJECT_PATH);
syspath.rawdata = fullfile(ROOT_PATH, 'RAWDATA', PROJECT_PATH);

% ======================= INPUT DATA =====================================%
% HTP Data structure can be created from HTP Preprocessing Pipeline OR
% directly importing cleaned data in SET format using htpDirectImport GUI.
syspath.htpdata  = fullfile(ROOT_PATH, 'RAWDATA', PROJECT_PATH);

keyfiles.datacsv = fullfile(syspath.htpdata, ...
	'A00_ANALYSIS/A2111300145_subjTable_Default_Stage4.csv');
keyfiles.datamat = fullfile(syspath.htpdata, ...
	'A00_ANALYSIS/A2111300145_subjTable_Default_Stage4.mat');

% ======================== GROUP LISTS ===================================%
% === CSV: col1 eegid, col2+ group labels (e.g. sex, group) ==============%
% groupLookupTable = readtable("fxs_group_list.csv");

%=========================================================================%
%                         OUTPUT CONFIGURATION                            %
%=========================================================================%

% ======================== RESULT OUTPUT =================================%
syspath.BigBuild      = fullfile(ROOT_PATH, 'BIGBUILD/', PROJECT_PATH);
syspath.SelectBuild    = fullfile(REPMAKE_PATH, 'BUILD/', PROJECT_PATH);

% adding both build folders to MATLAB path
cellfun(@(x) addpath(x), {syspath.BigBuild, syspath.projsource, ...
    syspath.rawdata , syspath.SelectBuild}, 'uni',0);

%=========================================================================%
%                      IMPORT DATA INTO HTP FORMAT                        %
%=========================================================================%

% NA 

%=========================================================================%
%                           ANALYSIS PIPELINE                             %
%=========================================================================%

% Creates initial dataset structure from CSV file
model_loadDataset;

%% Creates MNE source model in Brainstorm
isRestData = true;
ProtocolChannelSelection = 2;
model_makeMne;

% Creates Beamformer source model in Brainstorm
model_makeLcmv;

% Create EEGSET files representing 68-DK Atlas for MNE Forward Model
model_bstExtractSourceTimeSeries;

% Create EEGSET files representing 68-DK Atlas for Beamformer Forward Model
alternateSourceTypeComment = 'PNAI: EEG(Constr) 2018';
model_bstExtractSourceTimeSeries;

% Calculate Electrode (Scalp) Spectral Power by Band and Continuous Hz
model_bstElecPow;

% Calculate Source Power by Band
model_bstSourcePow;


% % Create list of interesting statistical comparision groups
% % col 1: label of comparision, 2 column name in group list, 3 variables to
% % compare
% listComps = {{'GroupMain', 'group', {'FXS','TDC'}};
%              {'GroupMale', 'subgroup', {'FXS_M','TDC_M'}};
%              {'GroupFemale', 'subgroup', {'FXS_F','TDC_F'}};
%              {'SexFXS', 'subgroup', {'FXS_M','FXS_F'}};
%              {'SexControl', 'subgroup', {'TDC_M','TDC_F'}}};
% 
% % Perform electrode level mean comparision (uses listComps)
% model_bstElecPowStats;
% 
% % Perform source level mean comparision (uses listComps)
% model_bstSourcePowStats;
% 
% % Create topographic figures from statistical comparisions of electrode
% figure_bstElecPowStats;
% 
% % Create cortical maps figures from statistical comparisions of sources
% figure_bstSourcePowStats;

% Spectral Events


%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %     
%                  Version 8/2021                                         %
%                  cincibrainlab.com                                      %
% ========================================================================%
