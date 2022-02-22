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
% No specific MEA external toolboxes required 11/21/2021

% Overview of paths
% - BIGBUILD
%    - Project1
%       spectralPowerMEA_bandpower.csv
%       spectralPowerMEA_peakfreq.csv
%    - Project2

%- REPMAKE
%    - SOURCE
%       spectralPowerMEA.m
%       - Project1
%            *Project1_runfile.m  % consists of all project specific queue
%            spectralPowerMEA.R  % R scripts
%       - Project2
%            Project2_runfile.m
%      - Project3
%           Project3_runfile.m



% Project_Path variable determines the project title throughout the 
% analysis. 

PROJECT_PATH = 'Proj_MEABase';

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

% folder containing source/raw data 
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
% demographic/group assignment CSV
% groupLookupTable = readtable("fxs_group_list.csv");


%=========================================================================%
%                         OUTPUT CONFIGURATION                            %
%=========================================================================%

% ======================== RESULT OUTPUT =================================%
% all output by default goes to BigBuild (large harddrive)
syspath.BigBuild      = fullfile(ROOT_PATH, 'BIGBUILD/', PROJECT_PATH);

% can also be set to shared/personal folder for selected file
syspath.SelectBuild    = fullfile(REPMAKE_PATH, 'BUILD/', PROJECT_PATH);

% adding both build folders to MATLAB path
cellfun(@(x) addpath(x), {syspath.BigBuild, syspath.projsource, ...
    syspath.rawdata , syspath.SelectBuild}, 'uni',0);

%=========================================================================%
%                      IMPORT DATA INTO HTP FORMAT                        %
%=========================================================================%

RAW_DATA_IMPORT_NEEDED = false;

%=========================================================================%
%                           ANALYSIS PIPELINE                             %
%=========================================================================%

cfg.rest = true; % mark as rest file

%============================= MOUSE MEA =================================%
%============================= Script customized for Mouse MEA data ======%
%============================= Please note specific mouse electrodes =====%
%============================= statistics, and visualizations. ===========%

% Mouse MEA analysis catalog =============================================%
% Import data ============================================================%
%  - model_loadDataset.m  % place data into htpPortableClass object

% Power analysis =========================================================%
% 1. model_spectralMeaPow.m  % electrode -> relative/absolute power bands
%    convert from setfile_relpow_v2_surface
%    input: eegDataClass, output: relative, absolute, peak freq (relative)
%           bandpower and spectral power
% 2. model_spectralMeaPowEpoch.m  % epochs -> relative/absolute power bands   
%    convert from setfile_spectrogram.m.
% 3. Visualizations (toEP_MEA_spectral_analysis.m)
%    - Band Power Ratio Bars (abs_bandpow_ratio-to-WT.png) convert from 140-213
%    - Power Spectrum Ratio (66-137)
%    - MEA Topoplot (254-353)
%    - Gamma spectrum plot (215-251)
%    load('chanfiles/mea_chan_hood-manual.mat') % hollow space between 11&20
% 4. Statistics
%    - Cluster-based permutation test for topoplot (294, 327)
%    - barplot 2-way ANOVA genotype x frequency band X region (not implemented)
%    - permutest for comparing two timeseries or spectrogram

% Connectivity analysis ==================================================%
% all code in the toEP_MEA_connectivity_analysis.m
% 1. Phase DWPLI (line 26) input s, output sub x chan1 x chan2 x freq
%                Symmetric matrix
% 2. Power Power AAC (line 28 set_file_coh)
%    Jun global, cross frequency connect 

% 3. Visualizations (starting line 80)
%    - MEA Map Connectivity (after 80-135)
% 4. Statistics
%    - normality; pairwise comparisions
%    - NBS statistics (TBD) no paired
%    - LME (TBD)

% Event Related (TBD)

% Creates initial dataset structure from CSV file
model_loadDataset;

% Calculate Electrode (Scalp) Spectral Power by Band and Continuous Hz
model_bstElecPow;


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

% Create topographic figures from statistical comparisions of electrode
figure_bstElecPowStats;

% Calculate AAC
model_powpowAAC;
model_junAAC; 

% Create AAC figures
figure_pmtmMneAAC_cfc;

%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %     
%                  Version 8/2021                                         %
%                  cincibrainlab.com                                      %
% ========================================================================%
