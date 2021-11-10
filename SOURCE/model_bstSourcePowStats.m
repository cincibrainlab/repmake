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

basename    = 'bstSourcePowStats'; % Edit
prefix      = ['model_' basename];

%=========================================================================%
% Step 3: Specify  pre-existing MAT to load into environment when script. %
%         If data will be used for multple tables or figures we recommend %
%         creating a model file with data saved in a MAT. Use missing if  %
%         no data is necessary.                                           %
%=========================================================================%

data_file = 'model_bstElecPowStats.mat'; % any MAT/Parquet inputs (or NA)

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

%% =========================================================================%
%  Specify Power Type    Spectral power is calculated via BST Welsch
%                        function. Code for analysis is carried through
%                        analysis making it easier to search for.
%  Available Codes:      scalpAbsPow755   Absolute Power
%                        scalpRelPow765   Relative Power
%                        scalpAbsFFT775   Absolute Power continuous
%                        scalpRelFFT785   Relative Power continuous
%=========================================================================%
powerTypeList = {'sourceAbsPow855','sourceRelPow865'};

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

assert(numel(sFilesTF) == numel(sPow), 'Power Analysis Incomplete.')

%=========================================================================%
% Set up group comparisions; goal is for a pair of index vectors
% i.e. comp #1: group1 index vs. group2 index
%      comp #2: male group1 index vs. male group2 index
% each comparison vector index pair is stored in the cell allComps to 
% loop through during statistics. This is predefined to allow for import
% of additional grouping variables, rather than hard coded within the loop.

allComps = {};
for i = 1 : numel(powerTypeList)
 
     powerType = powerTypeList{i};

end
     
     % 
%     matchTable = readtable("fxs_group_list.csv");
%     keyTable = cell2table({sPow.(powerType).SubjectName}', "VariableNames", {'eegid'});
%     grpList = innerjoin( keyTable, ...
%         matchTable(:, {'eegid', 'subgroup', 'group'}), 'Keys', {'eegid','eegid'});
% 
%     smatch = @(key,list) find(strcmp(key, list));
% 
%     % Comparison Name
%     % Identify Indexes
%     % Label Groups
% 
%     allComps{1,1,i} = 'GroupMain';
%     allComps{1,2,i} = {smatch('FXS', grpList.group), smatch('TDC', grpList.group)};
%     allComps{1,3,i} = {'FXS','TDC'};
% 
%     allComps{2,1,i} = 'GroupMale';
%     allComps{2,2,i} = {smatch('FXS_M', grpList.subgroup), smatch('TDC_M', grpList.subgroup)};
%     allComps{2,3,i} = {'FXS_M','TDC_M'};
% 
%     allComps{3,1,i} = 'GroupFemale';
%     allComps{3,2,i} = {smatch('FXS_F', grpList.subgroup), smatch('TDC_F', grpList.subgroup)};
%     allComps{3,3,i} = {'FXS_F','TDC_F'};
% 
%     allComps{4,1,i} = 'SexFXS';
%     allComps{4,2,i} = {smatch('FXS_M', grpList.subgroup), smatch('FXS_F', grpList.subgroup)};
%     allComps{4,3,i} = {'FXS_M','FXS_F'};
% 
%     allComps{5,1,i} = 'SexControl';
%     allComps{5,2,i} = {smatch('TDC_M', grpList.subgroup), smatch('TDC_F', grpList.subgroup)};
%     allComps{5,3,i} = {'TDC_M','TDC_F'};
% end

%=========================================================================%

target_file2 = [];
subnames = []; groupids = [];
selectComparisons = {};
nodePow = [];
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
    allComps = fx_codeGroupComparisons(listComps, matchedSubjectTable );
    
    for compi = 1 : size(allComps,1)
        
        % get subject Ids
        selectComparisonTitle = allComps{compi,1};
        selectComparisonIdx = allComps{compi,2};
        selectComparisonGroupNames = allComps{compi,3};

        groupIndex1 = selectComparisonIdx{:,1};
        groupIndex2 = selectComparisonIdx{:,2};

        sStats.(powerType) = bst_process('CallProcess', ...
            'process_test_permutation2', sPow.(powerType)(groupIndex1), sPow.(powerType)(groupIndex2), ...
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

        % retreive stat result structure
        sStatsValues.(powerType) = in_bst(sStats.(powerType).FileName);
        sStatsFields = {sStats.(powerType).Comment}';

        % create table of sig. thresholds for each comparision
        sStatsSigThreshold = fx_getBstSigThresholds(sStatsValues.(powerType));
        VariableNames = {'Comparison', 'Correction', 'alpha', 'pthreshold'};

        sStats_save = sStatsValues.(powerType);
        sStats_save.sublist   = {sPow.(powerType).SubjectName}';
        sStats_save.compIndex = selectComparisonIdx;
        sStats_save.compTitle = selectComparisonTitle;
        sStats_save.compGroups =selectComparisonGroupNames;
        sStats_save.sigTable = cell2table(sStatsSigThreshold, 'VariableNames', VariableNames);

        target_file2.(powerType) = ...
            r.outFile([prefix '_' powerType '_' selectComparisonTitle], syspath.BigBuild, output_file_extension);
        
        % Save Statistical Model
        try
            save(target_file2.(powerType), 'sStats_save', '-v6')
            fprintf("Success: Saved %s\n", target_file2.(powerType));
        catch ME
            disp(ME.message);
            fprintf("Error: Save Target File");
        end

        target_file3.(powerType) = ...
            r.outFile([prefix '_' powerType '_' ...
            selectComparisonTitle '_sigonly'], syspath.BigBuild, 'CSV');

        resultTable = fx_customStatReportSigPowerPerSubject( ...
            p, sStatsValues.(powerType), ...
            sPow.(powerType) );
        VariableNames = {'statCompare','eegid', 'group','bandname','tail1', 'tail2'};

        fx_customSaveResultsCSV(target_file3.(powerType) , resultTable, VariableNames);

        % Get Individual Values
        % export subject level values


        % extract all values at each vertex
        % Process: Extract values: [-1.000s,80.000s] 2-140Hz
        sSubPow = bst_process('CallProcess', ...
            'process_extract_values',  sPow.(powerType) , [], ...
            'timewindow', [-1, 80], ...
            'freqrange',  [2, 90], ...
            'rows',       '', ...
            'isabs',      0, ...
            'avgtime',    1, ...
            'avgrow',     0, ...
            'avgfreq',    0, ...
            'matchrows',  0, ...
            'dim',        2, ...  % Concatenate time (dimension 2)
            'Comment',    '');


        % get time frequency values variable
       sSubPowValues = in_bst(sSubPow.FileName); % Freqs: {8�3 cell} TF: [15002�141�8 double] Time: [1�141 double]
       sSubPowSave = [];
       sSubPowSave.sublist = sStats_save.sublist;
       sSubPowSave.TF = sSubPowValues.TF;
       sSubPowSave.freqbands = sSubPowValues.Freqs(:,1);
       nodePow = [];
       for bandi = 1 : numel(sSubPowSave.freqbands)
           for scouti = 1 : numel(atlas.Scouts)
               selScout = atlas.Scouts(scouti);
               selScoutIndex = selScout.Vertices;
               bandTF = sSubPowSave.TF(selScoutIndex,:,bandi);

               nodePow(scouti,1:numel(p.sub),bandi) = mean(bandTF,1);
           end
       end

       target_file4.(powerType) = ...
           r.outFile([prefix '_' powerType '_' ...
           selectComparisonTitle '_nodeSubject'], syspath.BigBuild, 'MAT');

        % Save Statistical Model
        try
            save(target_file4.(powerType), 'nodePow', '-v6')
            fprintf("Success: Saved %s\n", target_file2.(powerType));
        catch ME
            disp(ME.message);
            fprintf("Error: Save Target File");
        end

    end
end
%=========================================================================%
%                          EXPORT ENVIRONMENT                             %
%=========================================================================%
try    
    save(target_file, 'p', 'syspath', 'keyfiles', 'target_file2')
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
