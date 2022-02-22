%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make         %
%=========================================================================%
% MODEL SCRIPT     =======================================================%
%                  This script generates a single model from a dataset    %
%                  and exports to either R Build folder or MATLAB build.  %
%                  Generally, R datasets are optimized for size & import  %
%                  whereas the MATLAB Build folder is for temporary and   %
%                  larger files.                                          %
%                  Notes:                                                 %
%                        matlab_00_common.m - common include file         %
%                        repmanClass - required class for helper methods  %
%                           included in htp_minimum distribution          %
%                        target_file - primary output tracked by Make     %
%=========================================================================%

%=========================================================================%
% CONFIGURATION    =======================================================%
%                  Define inputs and outputs. Filenames in RepMake stay    %
%                  consistent between the script name & any output files. %
%                  The prefix specifies type of output (i.e., figure_).   %
%                  This code automatically switches between a specific    %
%                  command line output file and if the script is run from %
%                  Matlab. Note: Cap sensitive and no spaces.             %
%=========================================================================%

%=========================================================================%
% Step 1: Load common packages, data, and functions.                      %
% ========================================================================%


eeglab nogui;
% brainstorm nogui;

debug = 1;
if debug == 1
%=========================================================================%
% Step 2: Customize basename and target file for script                   %
%=========================================================================%

basename    = 'makeLcmv'; % Edit
prefix      = ['model_' basename];

output_file_extension = 'MAT'; % CSV, DOCX, MAT

if IsBatchMode, target_file = target_file; else
    target_file = r.outFile(prefix, syspath.BigBuild, output_file_extension);
end

%=========================================================================%
% Step 3: Specify  pre-existing MAT to load into environment when script. %
%         If data will be used for multple tables or figures we recommend %
%         creating a model file with data saved in a MAT. Use missing if  %
%         no data is necessary.                                           %
%=========================================================================%

data_file = 'model_makeMne.mat'; % any MAT/Parquet inputs (or NA)

if ~ismissing(data_file)
    load(fullfile(syspath.BigBuild, data_file))
end

%=========================================================================%
% BRAINSTORM       =======================================================%
% HELPER           Activate Brainstorm in no display (nogui) mode. Checks %
%                  and activates ProtocolName. Retrieves several key BST  %
%                  variables:                                             %
%                  protocol_name  protocol name                           %
%                  sStudy       study structure                           %
%                  sProtocol    protocol structure                        %
%                  sSubjects    subject structure                         %
%                  sStudyList   all assets in study                       %
%                  atlas        cortical atlas structure                  %
%                  sCortex      cortical structure                        %
%                  GlobalData   global brainstorm structure               %
%
[~,project_name,~] = fileparts(syspath.htpdata);
ProtocolName          = project_name; % set protocol name                 %
fx_getBrainstormVars;  % brainstorm include                                %
%                     script will end if wrong protocol                   %
%=========================================================================%

%=========================================================================%
%                            CONSTRUCT MODEL                              %
%=========================================================================%

sFiles = bst_process('CallProcess', 'process_select_files_data', [], []);

% Process: Compute covariance (noise or data)
sFiles = bst_process('CallProcess', 'process_noisecov', sFiles, [], ...
    'baseline',       [-1, -0.002], ...
    'datatimewindow', [], ...
    'sensortypes',    'MEG, EEG, SEEG, ECOG', ...
    'target',         1, ...  % Noise covariance     (covariance over baseline time window)
    'dcoffset',       1, ...  % Block by block, to avoid effects of slow shifts in data
    'identity',       1, ...
    'copycond',       0, ...
    'copysubj',       0, ...
    'copymatch',      0, ...
    'replacefile',    1);  % Replace

% Process: Compute covariance (noise or data) (whole segment)
sFiles = bst_process('CallProcess', 'process_noisecov', sFiles, [], ...
    'baseline',       [], ...
    'datatimewindow', [], ...
    'sensortypes',    'MEG, EEG, SEEG, ECOG', ...
    'target',         2, ...  % Data covariance      (covariance over data time window)
    'dcoffset',       1, ...  % Block by block, to avoid effects of slow shifts in data
    'identity',       0, ...
    'copycond',       0, ...
    'copysubj',       0, ...
    'copymatch',      0, ...
    'replacefile',    1);  % Replace

% Process: Compute sources [2018]
sFiles = bst_process('CallProcess', 'process_inverse_2018', sFiles, [], ...
    'output',  1, ...  % Kernel only: shared
    'inverse', struct(...
         'Comment',        'PNAI: EEG', ...
         'InverseMethod',  'lcmv', ...
         'InverseMeasure', 'nai', ...
         'SourceOrient',   {{'fixed'}}, ...
         'Loose',          0.2, ...
         'UseDepth',       1, ...
         'WeightExp',      0.5, ...
         'WeightLimit',    10, ...
         'NoiseMethod',    'median', ...
         'NoiseReg',       0.1, ...
         'SnrMethod',      'rms', ...
         'SnrRms',         1e-06, ...
         'SnrFixed',       3, ...
         'ComputeKernel',  1, ...
         'DataTypes',      {{'EEG'}}));

sourceDesc = regexprep(sFiles(1).Comment, {'[%(): ]+', '_+$'}, {'_', ''});

% Process: Add Source Model Type Comment to each subject
sourceDesc = regexprep(sFiles(1).Comment, {'[%(): ]+', '_+$'}, {'_', ''});
for isub = 1 : numel(sFiles)
    sFiles(isub).Comment = sourceDesc;
end

db_reload_database('current');

bst_memory('UnloadAll', 'Forced');
bst_progress('stop');

%=========================================================================%
%                          EXPORT ENVIRONMENT                             %
%=========================================================================%
try    
    save(target_file, 'p', 'syspath', 'keyfiles')
    fprintf("Success: Saved %s", target_file);
catch ME
    disp(ME.message);
    fprintf("Error: Save Target File");
end

end
%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %     
%                  Version 8/2021                                         %
%                  cincibrainlab.com                                      %
% ========================================================================%
