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
%                  Define inputs and outputs. Filenames in RepMake stay   %
%                  consistent between the script name & any output files. %
%                  The prefix specifies type of output (i.e., figure_).   %
%                  This code automatically switches between a specific    %
%                  command line output file and if the script is run from %
%                  Matlab. Note: Cap sensitive and no spaces.             %
%=========================================================================%

%=========================================================================%
% Step 1: Load common packages, data, and functions.                      %
% ========================================================================%

% Make sure correct project runfile is loaded

eeglab nogui;

%=========================================================================%
% Step 2: Customize basename for script                                   %
%=========================================================================%

basename    = 'bstSourcePow'; % Edit
prefix      = ['model_' basename];

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
% Step 4: Specify target for interactive Matlab (no modification needed)  %
%=========================================================================%

output_file_extension = 'MAT'; % CSV, DOCX, MAT

if IsBatchMode, target_file = target_file; else
    target_file = r.outFile(prefix, syspath.BigBuild, output_file_extension);
end

%=========================================================================%
%                            CONSTRUCT MODEL                              %
%=========================================================================%

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

cfg.predefinedBands = {...
    'delta', '2.5, 4', 'mean'; ...
    'theta', '4.5, 7.5', 'mean';....
    'alpha1', '8, 12', 'mean'; ...
    'alpha2', '10, 12.5', 'mean'; ...
    'beta', '15, 29', 'mean'; ...
    'gamma1', '30, 55', 'mean'; ...
    'gamma2', '65, 90', 'mean'};
cfg.timewindow = [0 80];
cfg.win_length = 2;
cfg.win_overlap = 50;

%=========================================================================%
%  Specify Power Type    Spectral power is calculated via BST Welsch
%                        function. Code for analysis is carried through
%                        analysis making it easier to search for.
%  Available Codes:      sourceAbsPow855   Absolute Power
%                        sourceRelPow865   Relative Power
%=========================================================================%

powerTypeList = {'sourceAbsPow855','sourceRelPow865'};

fx_getBstPowerResults = @( powerType ) bst_process('CallProcess', 'process_select_files_timefreq', [], [], ...
    'subjectname',   'All', ...
    'condition',     '', ...
    'tag',           powerType, ...
    'includebad',    0, ...
    'includeintra',  0, ...
    'includecommon', 0);

% Gather what source models are available
sFilesRecordings = bst_process('CallProcess', 'process_select_files_results', [], []);
availableSourceModels = unique({sFilesRecordings(:).Comment});
cleanSourceType = @(irregularName) regexprep(irregularName, {'[%(): ]+', '_+$'}, {'_', ''});

% Create fieldnames of all possible combinations of power / source
% calculations
count = 0;
powerCombos = {};
for i = 1 : numel(availableSourceModels)
    sourceType = availableSourceModels{i};
    for j = 1 : numel(powerTypeList)
        count = count + 1;
        powerType = [cleanSourceType(sourceType) '_' powerTypeList{j}];
        powerCombos{count,1} = powerType;
        powerCombos{count,2} = sourceType;
        powerCombos{count,3} = powerTypeList{j};
    end
end


%% Perform Power Analysis
% see fx_getBstPowerResults for parameters and functions for both
% electrode and source power calculations
sPow = {};
sValues = {};
sMatrix = {};
for i = 1 : size(powerCombos,1)
    powerType = powerCombos{i,1};
    sourceType = powerCombos{i,2};
    powerCalculation = powerCombos{1,3};

    fprintf("%s: (Calculation %d of %d)\n", powerType, i, size(powerCombos,1));

    checkTF = fx_getBstPowerResults(powerType);

    if isempty(checkTF)
        isPowAnalysisComplete = false;
    else
        if numel(checkTF) == numel(p.sub)
            fprintf('## NOTE ## %s already performed.\n', powerType);
            isPowAnalysisComplete = true;
            sPow.(powerType) = checkTF;
        else
            % clean if not exactly equal to number of subjects and start
            % over
            bst_process('CallProcess', 'process_delete', checkTF, [], ...
                'target', 1);  % Delete selected files
            isPowAnalysisComplete = false;
            sPow.(powerType) = [];
        end
    end

    if ~isPowAnalysisComplete

        sFilesRecordings = bst_process('CallProcess', 'process_select_files_results', [], [], ...
            'tag', sourceType);

        sPow.(powerType) = fx_BstElecPow(sFilesRecordings, cfg, powerCalculation);
        % Process: Set name: Not defined
        sPow.(powerType) = bst_process('CallProcess', ...
            'process_set_comment', sPow.(powerType), [], ...
            'tag',           powerType, ...
            'isindex',       1);

    end

    % save output
    [subnames.(powerType), groupids.(powerType)] = fx_customGetSubNames(sPow.(powerType),p,"default");


    % get group-level table
    sValues.(powerType) = bst_process('CallProcess', 'process_extract_values', sPow.(powerType), [], ...
        'timewindow',  [], ...
        'sensortypes', [], ...
        'isabs',       0, ...
        'avgtime',     0, ...
        'avgrow',      0, ...
        'dim',         2, ...  % Concatenate time (dimension 2)
        'Comment',     '');

    % Process: Set name: Not defined
    sValues.(powerType) = bst_process('CallProcess', 'process_set_comment', sValues.(powerType), [], ...
        'tag',           ['group_' powerType], ...
        'isindex',       1);

    [sMatrix.(powerType), matName.(powerType)] = in_bst(sValues.(powerType).FileName);

    timefreq.(powerType) = sMatrix.(powerType).TF;
    channels.(powerType) = sMatrix.(powerType).RowNames;

    if size(sMatrix.(powerType)) > 1  % frequency bands
        freqbands.(powerType) = sMatrix.(powerType).Freqs(:,1)';
    else
        freqbands.(powerType) = sMatrix.(powerType).Freqs'; % frequency FFT
    end

    target_file2.(powerType) = r.outFile([prefix '_' powerType], syspath.BigBuild, output_file_extension);

    subnames_save   = subnames.(powerType);
    freqbands_save  = freqbands.(powerType);
    timefreq_save   = timefreq.(powerType);
    channels_save   = channels.(powerType);

    try
        save(target_file2.(powerType), 'subnames_save', 'freqbands_save','timefreq_save', 'channels_save','-v6')
        fprintf("Success: Saved %s", target_file2.(powerType));
    catch ME
        disp(ME.message);
        fprintf("Error: Save Target File (%s)", target_file2.(powerType));
    end

end

% reload database
db_reload_database(iProtocol);

%% =========================================================================%
%                          EXPORT ENVIRONMENT                             %
%=========================================================================%
try
    save(target_file, 'p', 'syspath', 'keyfiles', 'target_file2')
    fprintf("Success: Saved %s", target_file);
catch ME
    disp(ME.message);
    fprintf("Error: Save Target File");
end
%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %
%                  Version 8/2021                                         %
%                  cincibrainlab.com                                      %
% ========================================================================%
