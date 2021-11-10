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

eeglab nogui;

%=========================================================================%
% Step 2: Customize basename for script                                   %
%=========================================================================%

basename    = 'bstElecPowStats'; % Edit
prefix      = ['model_' basename];

%=========================================================================%
% Step 3: Specify  pre-existing MAT to load into environment when script. %
%         If data will be used for multple tables or figures we recommend %
%         creating a model file with data saved in a MAT. Use missing if  %
%         no data is necessary.                                           %
%=========================================================================%

data_file = 'model_bstElecPow.mat'; % any MAT/Parquet inputs (or NA)

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
%                                                                         %
[~,project_name,~] = fileparts(syspath.htpdata);
ProtocolName          = project_name; % set protocol name                     %
fx_getBrainstormVars;  % brainstorm include                                %
%                     script will end if wrong protocol                   %
%=========================================================================%

%=========================================================================%
%  Specify Power Type    Spectral power is calculated via BST Welsch
%                        function. Code for analysis is carried through
%                        analysis making it easier to search for.
%  Available Codes:      scalpAbsPow755   Absolute Power
%                        scalpRelPow765   Relative Power
%                        scalpAbsFFT775   Absolute Power continuous
%                        scalpRelFFT785   Relative Power continuous
%=========================================================================%
powerTypeList = {'scalpAbsPow755','scalpRelPow765', 'scalpAbsFFT775','scalpRelFFT785'};


fx_getBstPowerResults = @( powerType ) bst_process('CallProcess', 'process_select_files_timefreq', [], [], ...
    'subjectname',   'All', ...
    'condition',     '', ...
    'tag',           powerType, ...
    'includebad',    0, ...
    'includeintra',  0, ...
    'includecommon', 0);

% create Arrays of Previous Power Calculations
sFilesTF = {};
isPowAnalysisComplete = {};
for i = 1 : numel(powerTypeList)
    powerType = powerTypeList{i};
    sFilesTF.(powerType) = fx_getBstPowerResults(powerType);
    if isempty(sFilesTF.(powerType))
        isPowAnalysisComplete.(powerType) = false;
    else
        if numel(sFilesTF.(powerType)) == numel(p.sub)
            fprintf('## NOTE ## %s already performed.\n', powerType);
            isPowAnalysisComplete.(powerType) = true;
            sPow.(powerType) = sFilesTF.(powerType);
        else
            isPowAnalysisComplete.(powerType) = false;
        end
    end
end


target_file2 = [];
subnames = []; groupids = [];
selectComparisons = {};
nodePow = [];
% Compute if only not already present

% Compute if only not already present

for i = 1 : numel(powerTypeList)
    powerType = powerTypeList{i};

    % Code to use custom comparisions
    % subjectList is order of subjects in current analysis
    subjectList = {sPow.(powerType).SubjectName}';

    % Can modify subject names if needed to match table in this function
    subjectList = fx_customSubjectListClean(subjectList, project_name);

    % match table to join groups (fieldnames will be used as needed based
    % on listComps in runfile.
    matchedSubjectTable = innerjoin( subjectList, groupLookupTable, 'Keys', {'eegid','eegid'});

    % Generate components with accurate
    allComps = fx_codeGroupComparisons(listComps, matchedSubjectTable  );
    for compi = 1 : size(allComps,1)

        % get subject Ids
        selectComparisonTitle = allComps{compi,1};
        selectComparisonIdx = allComps{compi,2};
        selectComparisonGroupNames = allComps{compi,3};

        if ~(isempty(selectComparisonIdx{1}) || isempty(selectComparisonIdx{2}))

            % get subject Ids
            % [subnames.(powerType), groupids.(powerType)] = fx_customGetSubNames(sPow.(powerType),p,"default");

            % groupLabels = categories(categorical(groupids.(powerType)));
            % disp(numel(groupLabels))
            % only valid for two groups
            %  assert(numel(groupLabels) == 2, 'model_bstElectRelPowStats: Too many groups');

            groupIndex1 = selectComparisonIdx{:,1};
            groupIndex2 = selectComparisonIdx{:,2};

            %groupIndex1 = find(strcmp(groupids.(powerType), groupLabels(1)));
            %groupIndex2 = find(strcmp(groupids.(powerType), groupLabels(2)));

            % Process: Perm t-test equal [0.000s,80.000s 2.5-90Hz]          H0:(A=B), H1:(A<>B)
            sStats.(powerType) = bst_process('CallProcess', 'process_test_permutation2', sPow.(powerType)(groupIndex1), sPow.(powerType)(groupIndex2), ...
                'timewindow',     [0, 80], ...
                'freqrange',      [2.5, 90], ...
                'rows',           '', ...
                'isabs',          0, ...
                'avgtime',        1, ...
                'avgrow',         0, ...
                'avgfreq',        0, ...
                'matchrows',      0, ...
                'iszerobad',      1, ...
                'Comment',        sprintf('per2_%s_%s', powerType, selectComparisonTitle), ...
                'test_type',      'ttest_equal', ...  % Student's t-test   (equal variance) t = (mean(A)-mean(B)) / (Sx * sqrt(1/nA + 1/nB))Sx = sqrt(((nA-1)*var(A) + (nB-1)*var(B)) / (nA+nB-2))
                'randomizations', 1000, ...
                'tail',           'two');  % Two-tailed

            target_file2.(powerType) = r.outFile([prefix '_' powerType], syspath.BigBuild, output_file_extension);

            sStats_save = sStats.(powerType);

            try
                save(target_file2.(powerType), 'sStats_save', '-v6')
                fprintf("Success: Saved %s\n", target_file2.(powerType));
            catch ME
                disp(ME.message);
                fprintf("Error: Save Target File");
            end

        else

            error(sprintf('Error'));

        end
    end
end
%=========================================================================%
%                          EXPORT ENVIRONMENT                             %
%=========================================================================%
try
    save(target_file, 'p', 'syspath', 'keyfiles', 'target_file2', 'sStats')
    fprintf("Success: Saved %s\n", target_file);
catch ME
    disp(ME.message);
    fprintf("Error: Save Target File");
end
%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %
%                  Version 8/2021                                         %
%                  cincibrainlab.com                                      %
% ========================================================================%
