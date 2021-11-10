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
Proj_RepMake_Startup;

groupLookupTable = readtable("fxs_group_list.csv");

model_loadDataset;
model_makeMne;

model_bstElecPow;
model_bstSourcePow;

listComps = {{'GroupMain', 'group', {'FXS','TDC'}};
             {'GroupMale', 'subgroup', {'FXS_M','TDC_M'}};
             {'GroupFemale', 'subgroup', {'FXS_F','TDC_F'}};
             {'SexFXS', 'subgroup', {'FXS_M','FXS_F'}};
             {'SexControl', 'subgroup', {'TDC_M','TDC_F'}}};

model_bstElecPowStats;
model_bstSourcePowStats;

figure_bstElecPowStats;


%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %     
%                  Version 8/2021                                         %
%                  cincibrainlab.com                                      %
% ========================================================================%
