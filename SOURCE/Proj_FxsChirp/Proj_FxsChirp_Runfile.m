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

PROJECT_PATH = 'Proj_FxsChirp';

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
	'A00_ANALYSIS/A2111120111_subjTable_Default_Stage4.csv');
keyfiles.datamat = fullfile(syspath.htpdata, ...
	'A00_ANALYSIS/A2111120111_subjTable_Default_Stage4.mat');

% ======================== GROUP LISTS ===================================%
% === CSV: col1 eegid, col2+ group labels (e.g. sex, group) ==============%
groupLookupTable = readtable("fxs_group_list.csv");

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

if RAW_DATA_IMPORT_NEEDED == true

    htpdi = htpDirectImportClass;  % htpdirectimport object

    htpdi.configHandler('basePath', {syspath.htpdata; PROJECT_PATH});
    htpdi.configHandler('chanInfo', 1); % 128
    htpdi.configHandler('filterInfo', 10);

    cfg.condition = 'Chirp';
    cfg.comments = 'EEGSET Pre-MNE';
    cfg.study_title = 'MNECHIRP';
    cfg.points_per_trial = 1626;
    cfg.srate = 500;
    cfg.xmin  = -.5;
    cfg.eventepoch = [-.5 2.75];
    cfg.number_channels = 129;
    cfg.chanlocs_file = 'chanfiles/GSN-HydroCel-129_new.sfp';   
    htpdi.setImportParameters(cfg);
    htpdi.preprocess_direct()

end

%=========================================================================%
%                           ANALYSIS PIPELINE                             %
%=========================================================================%

% Creates initial dataset structure from CSV file
model_loadDataset;

% Creates MNE source model in Brainstorm
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

%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %     
%                  Version 8/2021                                         %
%                  cincibrainlab.com                                      %
% ========================================================================%
