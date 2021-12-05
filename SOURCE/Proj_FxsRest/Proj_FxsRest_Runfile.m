%=========================================================================%
% MATLAB RUNFILE  ========================================================%
%                 This runfile template is project specific and will use  %
%                 common scripts in the Source directory.
%                 Datafiles are stored as htpPortableClass objects which  %
%                 contain eegDataClass objects. Objects contain paths to  %
%                 datafiles and analysis methods.                         %
%=========================================================================%

% *** Note: In general, analysis files should remain generic. However, if
% needed, the PROJECT_PATH variable can be used for project specific 
% conditional statements. This design ultimately requires the maintainance 
% of one analysis code base rather than a duplicate for each project or 
% subanalysis. The runfile and the called scripts run in the base workspace
% rather than subfunctions. Workspace variables should be cleared prior to 
% run. All paths can also be reset.

clear all;

%=========================================================================%
%                            PROJECT SETUP                                %
%=========================================================================%
%  SetupMatlabPaths includes system/platform specific configuration. It
%  should specify the location of toolboxes, paths to source files, and
%  must be successfully run prior to the remainder of the runfile. On first
%  run the file may have to be manually run from the source folder as all
%  matlab paths are reset.

SetupMatlabPaths;   % assign system paths including root_dir

% Project_Path variable determines the project title throughout the 
% analysis. 

PROJECT_PATH = 'Proj_FxsRest';

% Brainstorm analysis varies drastically if epochs are needed such as in 
% event data. If isRestData is true, continuous data will be importrd to
% Brainstorm. If false, epochs contained within the data can be custom
% imported into Brainstorm.

isRestData = true; 

%=========================================================================%
%                            INPUT CONFIGURATION                          %
%=========================================================================%

% ======================= INPUT DATA =====================================%
syspath.projsource = fullfile(SOURCE_PATH, PROJECT_PATH);
syspath.rawdata = fullfile(ROOT_PATH, 'RAWDATA', PROJECT_PATH);

% ======================= INPUT DATA =====================================%
% HTP Data structure can be created from HTP Preprocessing Pipeline OR
% directly importing cleaned data in SET format using htpDirectImport GUI.

csvfile = 'A1911071145_subjTable_P1Stage4.csv';

syspath.htpdata  = fullfile(ROOT_PATH, 'RAWDATA', PROJECT_PATH);

keyfiles.datacsv = fullfile(syspath.htpdata, 'A00_ANALYSIS/', csvfile);
keyfiles.datamat = strrep(keyfiles.datacsv,'.csv','.mat');

syspath.htpdata  = fullfile(ROOT_PATH, 'RAWDATA', PROJECT_PATH);

% ======================== GROUP LISTS ===================================%
% === CSV: col1 eegid, col2+ group labels (e.g. sex, group) ==============%
groupLookupTable = readtable("fxs_group_list.csv");

chanLookupTable = readtable("atlas_dk_networks_mni.csv");

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

RAW_DATA_IMPORT_NEEDED = false;

cfg.rest = true; % mark as rest file

% Creates initial dataset structure from CSV file
model_loadDataset;

%=========================================================================%
%                           ANALYSIS PIPELINE                             %
%=========================================================================%
%%

% Creates MNE source model in Brainstorm
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

% Calculate AAC
model_powpowAAC;

% Create list of interesting statistical comparision groups
% col 1: label of comparision, 2 column name in group list, 3 variables to
% compare
listComps = {{'GroupMain', 'group', {'FXS','TDC'}};
             {'GroupMale', 'subgroup', {'FXS_M','TDC_M'}};
             {'GroupFemale', 'subgroup', {'FXS_F','TDC_F'}};
             {'SexFXS', 'subgroup', {'FXS_M','FXS_F'}};
             {'SexControl', 'subgroup', {'TDC_M','TDC_F'}}};

% Perform electrode level mean comparision (uses listComps)
model_bstElecPowStats;

% Perform source level mean comparision (uses listComps)
model_bstSourcePowStats;

% Create topographic figures from statistical comparisions of electrode
figure_bstElecPowStats;

% Create cortical maps figures from statistical comparisions of sources
figure_bstSourcePowStats;

% Create AAC figures
figure_pmtmMneAAC_cfc;


%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %     
%                  Version 8/2021                                         %
%                  cincibrainlab.com                                      %
% ========================================================================%
